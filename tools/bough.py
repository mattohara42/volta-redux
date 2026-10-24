#!/usr/bin/env python3
"""Make a bough a given number of cells long from the keyed branch painting.

ART.md, The forest's trees. A bough is solid: you stand on it, and a low one
roofs a scorpion's tunnel. So its thick part is warped to exactly the bough's
rows (every column's span stretched to `--rows` cells), and what you see is
what you stand on and what you hit your head on. Past the solid end the
painting's twiggy tip carries on unwarped, shifted to meet it, as decoration.

Output: an image whose solid band is `--rows` cells tall starting one cell
down (so a twig may rise a cell above the bough and hang a cell below), and
`--cells` cells wide from x 0, the thick end at the left: the trunk's side.
A bough growing left is this, mirrored, which the game does.

`--like TRUNK.png` recolours the wood to that trunk's bark, keeping each
pixel's value and leaving the moss alone. The branch was painted warm umber,
which says a sword bites here (`ART_DIRECTION.md`); a bough of bark it does
not bite must not say so.

The source is never modified. An existing output needs --overwrite (CLAUDE.md:
the destructive mode is the flag).

Usage:
    tools/bough.py BRANCH.png OUT.png --cells N [--rows 2] [--thick-end 200]
        [--cell 16] [--colors 16] [--like TRUNK.png] [--overwrite]

`--thick-end` is where the painting's solid part ends, in its own pixels:
200, just before the fork.
Requires pillow and numpy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


# Columns of painting each edge is averaged over.
_SMOOTH = 41


def bough(painting: Image.Image, cells: int, rows: int, thick_end: int, cell: int, colors: int) -> Image.Image:
    src = np.asarray(painting.convert("RGBA"))
    h, w = src.shape[:2]
    factor = cells * cell / thick_end
    band = round(rows * cell / factor)
    top = round(cell / factor)
    out = np.zeros((band + 2 * top, w, 4), np.uint8)
    # The edges smoothed along the bough, so neighbouring columns stretch
    # alike and the warp does not streak.
    tops = np.zeros(thick_end)
    bottoms = np.zeros(thick_end)
    for x in range(thick_end):
        ys = np.nonzero(src[:, x, 3])[0]
        tops[x], bottoms[x] = (ys.min(), ys.max()) if len(ys) else (np.nan, np.nan)
    kernel = np.ones(_SMOOTH) / _SMOOTH
    pad = _SMOOTH // 2
    tops = np.convolve(np.pad(tops, pad, mode="edge"), kernel, mode="valid")
    bottoms = np.convolve(np.pad(bottoms, pad, mode="edge"), kernel, mode="valid")
    last_shift = 0
    for x in range(w):
        ys = np.nonzero(src[:, x, 3])[0]
        if len(ys) == 0:
            continue
        if x < thick_end:
            t, b = int(round(tops[x])), int(round(bottoms[x]))
            span = Image.fromarray(src[t : b + 1, x : x + 1]).resize((1, band), Image.BOX)
            out[top : top + band, x] = np.asarray(span)[:, 0]
            last_shift = top - t
        else:
            for y in ys:
                to = y + last_shift
                if 0 <= to < out.shape[0]:
                    out[to, x] = src[y, x]
    big = Image.fromarray(out)
    size = (round(w * factor), (rows + 2) * cell)
    small = big.convert("RGBa").resize(size, Image.BOX).convert("RGBA")
    alpha = small.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    rgb = small.convert("RGB")
    opaque = np.asarray(rgb)[np.asarray(alpha) > 0]
    if len(opaque):
        fill = Image.new("RGB", rgb.size, tuple(int(c) for c in opaque[len(opaque) // 2]))
        rgb = Image.composite(rgb, fill, alpha)
    result = rgb.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    # The solid part is solid all through, so the art never shows air where
    # the hero cannot go.
    a = np.asarray(alpha).copy()
    a[cell : cell + rows * cell, : cells * cell] = 255
    result.putalpha(Image.fromarray(a))
    return result


# The wood's hues, degrees: anything in here is bark to recolour, not moss.
_WOOD_HUES = (0.0, 55.0)


def like(image: Image.Image, trunk: Image.Image) -> Image.Image:
    """`image`'s wood in `trunk`'s median hue and saturation, value kept."""
    t = np.asarray(trunk.convert("RGBA"))
    t_hsv = np.asarray(trunk.convert("RGB").convert("HSV")).astype(float)[t[..., 3] > 0]
    hue, sat = np.median(t_hsv[:, 0]), np.median(t_hsv[:, 1])
    rgba = np.asarray(image.convert("RGBA"))
    hsv = np.asarray(image.convert("RGB").convert("HSV")).astype(float)
    degrees = hsv[..., 0] * 360.0 / 255.0
    wood = (rgba[..., 3] > 0) & (degrees >= _WOOD_HUES[0]) & (degrees <= _WOOD_HUES[1])
    hsv[..., 0] = np.where(wood, hue, hsv[..., 0])
    hsv[..., 1] = np.where(wood, sat, hsv[..., 1])
    rgb = Image.fromarray(hsv.astype(np.uint8), mode="HSV").convert("RGB")
    out = rgb.convert("RGBA")
    out.putalpha(Image.fromarray(rgba[..., 3]))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("branch", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--cells", type=int, required=True)
    parser.add_argument("--rows", type=int, default=2)
    parser.add_argument("--thick-end", type=int, default=200)
    parser.add_argument("--cell", type=int, default=16)
    parser.add_argument("--colors", type=int, default=16)
    parser.add_argument("--like", type=Path, help="a trunk whose bark the wood is recoloured to")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    if args.out.exists() and not args.overwrite:
        sys.exit(f"bough.py: {args.out} exists. Pass --overwrite to replace it.")
    result = bough(Image.open(args.branch), args.cells, args.rows, args.thick_end, args.cell, args.colors)
    if args.like:
        result = like(result, Image.open(args.like))
    result.save(args.out)
    print(f"wrote {args.out}, {result.width}x{result.height}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
