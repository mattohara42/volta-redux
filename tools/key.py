#!/usr/bin/env python3
"""Flood the backdrop out of a Gemini delivery and write a transparent PNG.

ART.md, pipeline step 2. The generator does not return the exact backdrop
colour it was asked for (GEMINI_NOTES.md), so this samples the delivery's own
border pixels for the backdrop colour instead of assuming one, then floods
inward from the border. Pixels the flood reaches become transparent;
everything else is despilled near the cut edge, so a soft antialiased border
does not carry a fringe of backdrop colour into the game.

CLAUDE.md: the destructive mode is the flag. Writing over an existing OUT
needs --overwrite; the default refuses.

Usage:
    tools/key.py DELIVERY.png OUT.png [--tolerance N] [--overwrite]

Requires pillow and numpy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

# A colour the delivered art is asked never to use, so it is safe as a flood
# marker: floodfill.py paints matched backdrop pixels this colour internally,
# then the mask below is wherever the working copy equals it.
_SENTINEL = (0, 255, 0)
_DESPILL_RING_PX = 3
_DESPILL_STRENGTH = 0.6


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


def _despill(rgba: np.ndarray, backdrop: tuple[int, int, int], ring: np.ndarray) -> None:
    """Mutates rgba in place: pulls each channel's lean toward the backdrop
    hue back out, only within `ring` (the kept pixels nearest the cut)."""
    backdrop_arr = np.array(backdrop, dtype=np.float64)
    for i in range(3):
        others = [j for j in range(3) if j != i]
        lean = backdrop_arr[i] - rgba[..., others].mean(axis=-1)
        pull = np.clip(lean, 0, None) * _DESPILL_STRENGTH
        pull = np.where(ring, pull, 0.0)
        rgba[..., i] = np.clip(rgba[..., i] - pull, 0, 255)


def key(delivery: Path, out: Path, tolerance: int, overwrite: bool) -> None:
    if out.exists() and not overwrite:
        raise SystemExit(f"{out} already exists; pass --overwrite to replace it.")

    image = Image.open(delivery).convert("RGB")
    rgb = np.asarray(image)
    backdrop = _detect_backdrop(rgb)
    mask = _flood_backdrop_mask(image, backdrop, tolerance)
    ring = _dilate(mask, _DESPILL_RING_PX) & ~mask

    rgba = np.dstack([rgb, np.full(rgb.shape[:2], 255, dtype=np.uint8)]).astype(np.float64)
    rgba[..., 3] = np.where(mask, 0, 255)
    _despill(rgba, backdrop, ring)

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
    parser.add_argument("--overwrite", action="store_true", help="Replace OUT if it already exists.")
    args = parser.parse_args(argv)
    key(args.delivery, args.out, args.tolerance, args.overwrite)
    return 0


if __name__ == "__main__":
    sys.exit(main())
