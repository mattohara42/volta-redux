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

`--dim F` scales every pixel's brightness by F before the palette is chosen,
for a painting that came back brighter than the playfield. The raw delivery
stays untouched, so the dimmed copy can always be remade from it. The forest's
moonlight shafts needed it: undimmed, they outshone the platforms.

A painting with transparency (a keyed and cut prop, `key.py` then
`cut-sheet.py`) keeps it: the downscale weighs colour by coverage so the
backdrop's dark does not creep into the edge, then every pixel is either
fully opaque or fully clear, as pixel art is, at half coverage.

Run tools/palette-check.py on the result: reducing colours can merge a
coloured dark into a neutral one.

CLAUDE.md: the destructive mode is the flag. Writing over an existing OUT
needs --overwrite; the default refuses.

Usage:
    tools/pixelate.py PAINTING.png OUT.png [--height 360] [--colors 24] [--crop X0,X1] [--dim F] [--overwrite]

Requires pillow and numpy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def dim(image: Image.Image, factor: float) -> Image.Image:
    """Scale every pixel's brightness (HSV value) by factor, keeping hue and saturation."""
    h, s, v = image.convert("HSV").split()
    v = v.point(lambda value: round(value * factor))
    return Image.merge("HSV", (h, s, v)).convert("RGB")


def pixelate(painting: Image.Image, height: int, colors: int, dim_factor: float = 1.0) -> Image.Image:
    width = round(painting.width * height / painting.height)
    if painting.mode not in ("RGBA", "LA", "PA") and "transparency" not in painting.info:
        small = painting.convert("RGB").resize((width, height), Image.BOX)
        if dim_factor != 1.0:
            small = dim(small, dim_factor)
        return small.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGB")
    small = painting.convert("RGBA").convert("RGBa").resize((width, height), Image.BOX).convert("RGBA")
    alpha = small.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    rgb = small.convert("RGB")
    if dim_factor != 1.0:
        rgb = dim(rgb, dim_factor)
    # The clear pixels' colour is noise: fill them with an opaque one, so the
    # palette is chosen from the prop alone.
    opaque = np.asarray(rgb)[np.asarray(alpha) > 0]
    if len(opaque):
        fill = Image.new("RGB", rgb.size, tuple(int(c) for c in opaque[len(opaque) // 2]))
        rgb = Image.composite(rgb, fill, alpha)
    out = rgb.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    out.putalpha(alpha)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("painting", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--height", type=int, default=360, help="output height in design px (default: the room's 360)")
    parser.add_argument("--colors", type=int, default=24, help="palette size (default 24)")
    parser.add_argument("--crop", help="X0,X1: keep only this horizontal span of the painting, in its own pixels")
    parser.add_argument("--dim", type=float, default=1.0, help="scale brightness by this, 0 to 1, before the palette is chosen (default 1, untouched)")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    if args.out.exists() and not args.overwrite:
        sys.exit(f"pixelate.py: {args.out} exists. Pass --overwrite to replace it.")
    if not 2 <= args.colors <= 256:
        sys.exit("pixelate.py: --colors must be 2 to 256")
    if not 0 < args.dim <= 1:
        sys.exit("pixelate.py: --dim must be above 0 and at most 1")

    painting = Image.open(args.painting)
    if args.crop:
        x0, x1 = (int(v) for v in args.crop.split(","))
        if not 0 <= x0 < x1 <= painting.width:
            sys.exit(f"pixelate.py: --crop must lie within 0,{painting.width}")
        painting = painting.crop((x0, 0, x1, painting.height))
    result = pixelate(painting, args.height, args.colors, args.dim)
    result.save(args.out)
    print(f"wrote {args.out}, {result.width}x{result.height}, {args.colors} colours")


if __name__ == "__main__":
    main()
