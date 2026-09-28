#!/usr/bin/env python3
"""Recolour a delivery's neutral darks into ART_DIRECTION.md's coloured darks.

Sprite Fusion has no palette parameter on generate, and its outlines often
land just inside palette-check.py's neutral-dark band. Every pixel that
palette-check.py would flag is given the hue of one of the two named dark
families, at its own brightness: warm umber when its nearest clean neighbour
is warm (leather, skin, hair), cold violet-blue otherwise (steel, stone, or a
neighbour too grey to call). That is the selective outline ART_DIRECTION.md
asks for, falling out of the neighbourhood rather than painted by hand.

Pixels palette-check.py does not flag are left untouched, so the result
passes the check and nothing else about the sprite moves.

The input is never modified. OUT must differ from IMAGE, and an existing OUT
needs --overwrite (CLAUDE.md: the destructive mode is the flag).

Usage:
    tools/recolour-darks.py IMAGE.png OUT.png [--overwrite]

Requires pillow, numpy and scipy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import colorsys
import importlib.util
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

_spec = importlib.util.spec_from_file_location("palette_check", Path(__file__).with_name("palette-check.py"))
palette_check = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(palette_check)

# Hue in degrees for each dark family: umber matches the firelight falloff,
# violet matches the cold stone's deep value (ART_DIRECTION.md, Palette).
_UMBER_HUE = 25.0
_VIOLET_HUE = 250.0
_FAMILY_SATURATION = 0.45
_MIN_VALUE = 0.06


def _is_warm(rgb: np.ndarray) -> np.ndarray:
    """Warm means saturated enough to call and hued red to yellow."""
    hsv = np.array([colorsys.rgb_to_hsv(*px) for px in rgb.reshape(-1, 3)]).reshape(rgb.shape)
    hue_deg = hsv[..., 0] * 360.0
    saturated = hsv[..., 1] >= palette_check._SATURATION_THRESHOLD
    return saturated & ((hue_deg < 90.0) | (hue_deg >= 300.0))


def recolour(rgba: np.ndarray) -> tuple[np.ndarray, int]:
    arr = rgba.astype(np.float64) / 255.0
    rgb, alpha = arr[..., :3], arr[..., 3]
    opaque = alpha > 0.5
    violating = (
        opaque
        & (palette_check._luminance(rgb) < palette_check._LUMINANCE_THRESHOLD)
        & (palette_check._saturation(rgb) < palette_check._SATURATION_THRESHOLD)
    )
    source = opaque & ~violating
    if not violating.any():
        return rgba.copy(), 0

    if source.any():
        _, idx = ndimage.distance_transform_edt(~source, return_indices=True)
        warm = _is_warm(rgb[idx[0], idx[1]])
    else:
        warm = np.zeros(violating.shape, dtype=bool)

    out = rgba.copy()
    value = np.maximum(rgb.max(axis=-1), _MIN_VALUE)
    for y, x in zip(*np.nonzero(violating)):
        hue = _UMBER_HUE if warm[y, x] else _VIOLET_HUE
        r, g, b = colorsys.hsv_to_rgb(hue / 360.0, _FAMILY_SATURATION, value[y, x])
        out[y, x, :3] = np.round(np.array([r, g, b]) * 255.0).astype(np.uint8)
    return out, int(violating.sum())


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("image", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--overwrite", action="store_true", help="Replace OUT if it already exists.")
    args = parser.parse_args(argv)

    if args.out.resolve() == args.image.resolve():
        raise SystemExit("recolour-darks.py: OUT must differ from IMAGE; the delivery is never modified.")
    if args.out.exists() and not args.overwrite:
        raise SystemExit(f"recolour-darks.py: {args.out} already exists; pass --overwrite to replace it.")

    rgba = np.asarray(Image.open(args.image).convert("RGBA"))
    out, changed = recolour(rgba)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out, mode="RGBA").save(args.out)
    print(f"{args.image} -> {args.out}: {changed} neutral-dark pixels recoloured")
    return 0


if __name__ == "__main__":
    sys.exit(main())
