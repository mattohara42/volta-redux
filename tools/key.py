#!/usr/bin/env python3
"""Flood the backdrop out of a Gemini delivery and write a transparent PNG.

ART.md, pipeline step 2. The generator does not return the exact backdrop
colour it was asked for (GEMINI_NOTES.md), so this samples the delivery's own
border pixels for the backdrop colour instead of assuming one, then floods
inward from the border. Pixels the flood reaches become transparent.

The antialiased seam around a cut subject carries real backdrop colour
blended in, not just a faint tint: measured on a real delivery, a magenta
backdrop bled visibly 6 to 7px into the kept pixels. A partial pull only
softens that; it does not remove it, and GEMINI_NOTES.md is explicit that a
noisy backdrop bled into the subject is the one thing that isn't fixable
downstream. So every kept pixel within --ring of the cut is replaced outright
with its nearest clean neighbour's colour (the same "unmix" idea
GEMINI_NOTES.md names, implemented here as a nearest-neighbour fill via
scipy's distance transform), rather than partially corrected. It trades a
few pixels of texture detail right at the silhouette edge for a hard
guarantee of zero backdrop bleed.

CLAUDE.md: the destructive mode is the flag. Writing over an existing OUT
needs --overwrite; the default refuses.

Usage:
    tools/key.py DELIVERY.png OUT.png [--tolerance N] [--ring N] [--overwrite]

Requires pillow, numpy and scipy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

# A colour the delivered art is asked never to use, so it is safe as a flood
# marker: floodfill.py paints matched backdrop pixels this colour internally,
# then the mask below is wherever the working copy equals it.
_SENTINEL = (0, 255, 0)


def _detect_backdrop(rgb: np.ndarray) -> tuple[int, int, int]:
    border = np.concatenate([rgb[0, :, :], rgb[-1, :, :], rgb[:, 0, :], rgb[:, -1, :]])
    values, counts = np.unique(border.reshape(-1, 3), axis=0, return_counts=True)
    return tuple(int(c) for c in values[counts.argmax()])


def _flood_backdrop_mask(image: Image.Image, backdrop: tuple[int, int, int], tolerance: int) -> np.ndarray:
    width, height = image.size
    working = image.convert("RGB").copy()
    original = np.asarray(working)
    matches_backdrop = np.all(np.abs(original.astype(int) - np.array(backdrop)) <= tolerance, axis=-1)

    seeds: set[tuple[int, int]] = set()
    for x in range(width):
        seeds.add((x, 0))
        seeds.add((x, height - 1))
    for y in range(height):
        seeds.add((0, y))
        seeds.add((width - 1, y))

    filled = np.zeros((height, width), dtype=bool)
    for x, y in seeds:
        if filled[y, x] or not matches_backdrop[y, x]:
            continue
        ImageDraw.floodfill(working, (x, y), _SENTINEL, thresh=tolerance)
        filled = np.all(np.asarray(working) == np.array(_SENTINEL), axis=-1)
    return filled


def _dilate(mask: np.ndarray, iterations: int) -> np.ndarray:
    out = mask.copy()
    for _ in range(iterations):
        out = (
            out
            | np.roll(out, 1, axis=0)
            | np.roll(out, -1, axis=0)
            | np.roll(out, 1, axis=1)
            | np.roll(out, -1, axis=1)
        )
    return out


def _decontaminate(rgb: np.ndarray, mask: np.ndarray, ring_px: int) -> np.ndarray:
    """Every kept pixel within `ring_px` of the backdrop is replaced with its
    nearest clean neighbour's colour (nearest kept pixel outside the ring),
    via scipy's distance transform. Kept pixels further from the cut than
    that are untouched."""
    ring = _dilate(mask, ring_px) & ~mask
    clean = ~mask & ~ring
    if not clean.any():
        return rgb.copy()
    _, indices = ndimage.distance_transform_edt(~clean, return_indices=True)
    nearest = rgb[indices[0], indices[1]]
    out = rgb.copy()
    out[ring] = nearest[ring]
    return out


def key(delivery: Path, out: Path, tolerance: int, ring_px: int, overwrite: bool) -> None:
    if out.exists() and not overwrite:
        raise SystemExit(f"{out} already exists; pass --overwrite to replace it.")

    image = Image.open(delivery).convert("RGB")
    rgb = np.asarray(image)
    backdrop = _detect_backdrop(rgb)
    mask = _flood_backdrop_mask(image, backdrop, tolerance)
    clean_rgb = _decontaminate(rgb, mask, ring_px)

    rgba = np.dstack([clean_rgb, np.full(rgb.shape[:2], 255, dtype=np.uint8)])
    rgba[..., 3] = np.where(mask, 0, 255)

    out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba.astype(np.uint8), mode="RGBA").save(out)
    kept_pct = 100.0 * (~mask).sum() / mask.size
    print(f"{delivery} -> {out}: backdrop detected as rgb{backdrop}, {kept_pct:.1f}% of pixels kept opaque")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("delivery", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument(
        "--tolerance", type=int, default=24,
        help="Per-channel match tolerance against the detected backdrop (default 24).",
    )
    parser.add_argument(
        "--ring", type=int, default=10,
        help="Width in px of the contamination band to decontaminate around the cut (default 10).",
    )
    parser.add_argument("--overwrite", action="store_true", help="Replace OUT if it already exists.")
    args = parser.parse_args(argv)
    key(args.delivery, args.out, args.tolerance, args.ring, args.overwrite)
    return 0


if __name__ == "__main__":
    sys.exit(main())
