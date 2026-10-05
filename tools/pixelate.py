#!/usr/bin/env python3
"""Turn a painted background into a 1x pixel-art one.

ART.md, the far-background layer. Sprite Fusion cannot make anything larger
than 64 px, so a background is painted (Gemini, as M5 did) and converted
here: a box downscale to the room's height at one art pixel per design pixel,
then a reduction to a small palette with no dithering. The softness that
leaves behind is wanted, not a defect: ART_DIRECTION.md says backgrounds
lose, and a crisp outlined sprite reads clearly in front of it.

The reduction is octree, not Pillow's default median cut. Median cut picks
colours by area, so a window's small bright core loses to the wall around it
and the lit slit comes out dark, even at 64 colours. Octree keeps it at 24
and leaves the wall muted. Max coverage also keeps it, but turns the stone
blotchy and loud, which a background must not be. Measured on Act 1's wall.

Aspect ratio is kept, because a room draws its background at the room's
height and lets the width follow (room_m5_wall.gd's BG_SCALE).

It works best on a painting made of large, simple shapes. Busy detail turns
to mush at a couple of dozen colours, so ask for big forms in the prompt.

A room tiles its background with every other copy mirrored, so the two
edges are where the painting meets itself. `--crop X0,X1` keeps only that
horizontal span of the painting (in the painting's own pixels) before
anything else, so the edges can be put on something that mirrors well: a
rock column mirrors into a column, a recess into a face. The raw delivery
stays untouched.

Run tools/palette-check.py on the result: reducing colours can merge a
coloured dark into a neutral one.

CLAUDE.md: the destructive mode is the flag. Writing over an existing OUT
needs --overwrite; the default refuses.

Usage:
    tools/pixelate.py PAINTING.png OUT.png [--height 360] [--colors 24] [--crop X0,X1] [--overwrite]

Requires pillow (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def pixelate(painting: Image.Image, height: int, colors: int) -> Image.Image:
    rgb = painting.convert("RGB")
    width = round(rgb.width * height / rgb.height)
    small = rgb.resize((width, height), Image.BOX)
    return small.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGB")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("painting", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--height", type=int, default=360, help="output height in design px (default: the room's 360)")
    parser.add_argument("--colors", type=int, default=24, help="palette size (default 24)")
    parser.add_argument("--crop", help="X0,X1: keep only this horizontal span of the painting, in its own pixels")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    if args.out.exists() and not args.overwrite:
        sys.exit(f"pixelate.py: {args.out} exists. Pass --overwrite to replace it.")
    if not 2 <= args.colors <= 256:
        sys.exit("pixelate.py: --colors must be 2 to 256")

    painting = Image.open(args.painting)
    if args.crop:
        x0, x1 = (int(v) for v in args.crop.split(","))
        if not 0 <= x0 < x1 <= painting.width:
            sys.exit(f"pixelate.py: --crop must lie within 0,{painting.width}")
        painting = painting.crop((x0, 0, x1, painting.height))
    result = pixelate(painting, args.height, args.colors)
    result.save(args.out)
    print(f"wrote {args.out}, {result.width}x{result.height}, {args.colors} colours")


if __name__ == "__main__":
    main()
