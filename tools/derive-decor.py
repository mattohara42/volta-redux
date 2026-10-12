#!/usr/bin/env python3
"""Derive the forest's decoration (N2) from its own floor tile: grass tufts
that stand on the lip, and roots that hang under earth.

ART.md: don't generate a piece you could derive. Every colour is read from the
source tile (the grass's blade, body, shadow and outline; the soil's roots), so
a tuft is the lip's own grass grown a little taller and a root is the soil's
own root let out into the air. Seeded, so the same command gives the same
pixels, and a variant is a different seed of the same rule.

The source is never modified. Existing outputs need --overwrite (CLAUDE.md:
the destructive mode is the flag).

Usage:
    tools/derive-decor.py FLOOR_TILE.png OUT_DIR [--count 3] [--seed 7] [--overwrite]
writes OUT_DIR/tuft_<n>.png and OUT_DIR/root_<n>.png

Requires pillow (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

from PIL import Image

# Where in the forest's floor tile each colour is read from, (x, y): picked
# off the tile by eye and named for what it is, so a repainted tile is re-read
# rather than recoloured by hand.
GRASS_TIP = (11, 3)       # the brightest blade
GRASS_BODY = (4, 5)       # a blade in shade
GRASS_DEEP = (2, 5)       # the grass's shadow side
GRASS_LINE = (6, 0)       # the coloured dark the grass is outlined in
ROOT_LIT = (9, 8)         # a root where light catches it
ROOT_MID = (11, 12)       # a root
ROOT_DARK = (3, 13)       # a root's shadow side

TUFT_SIZE = (12, 7)
ROOT_SIZE = (14, 12)


def _pick(tile: Image.Image, at: tuple[int, int]) -> tuple[int, int, int, int]:
    r, g, b, a = tile.getpixel(at)
    if a == 0:
        sys.exit(f"derive-decor: the source pixel at {at} is transparent; re-read the tile")
    return (r, g, b, 255)


def tuft(tile: Image.Image, rng: random.Random) -> Image.Image:
    tip, body, deep, line = (_pick(tile, p) for p in (GRASS_TIP, GRASS_BODY, GRASS_DEEP, GRASS_LINE))
    w, h = TUFT_SIZE
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    centre = (w - 1) / 2
    blades = rng.randint(4, 6)
    for i in range(blades):
        x = round(centre + (i - (blades - 1) / 2) * 1.6 + rng.uniform(-0.6, 0.6))
        # Tallest in the middle, as a clump grows.
        tall = max(2, round((h - 1) * (1 - abs(x - centre) / (w / 2)) + rng.uniform(-1, 1)))
        lean = rng.choice([-1, 0, 0, 1])
        for k in range(tall):
            y = h - 1 - k
            px = x + (lean if k >= tall - 2 else 0)
            if not 0 <= px < w:
                continue
            colour = tip if k >= tall - 2 else body if k > 0 else deep
            out.putpixel((px, y), colour)
            # An outline on the shadow side, as the lip's own grass has.
            if k < tall - 1 and 0 <= px + 1 < w and out.getpixel((px + 1, y))[3] == 0:
                out.putpixel((px + 1, y), line)
    return out


def root(tile: Image.Image, rng: random.Random) -> Image.Image:
    lit, mid, dark = (_pick(tile, p) for p in (ROOT_LIT, ROOT_MID, ROOT_DARK))
    w, h = ROOT_SIZE
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for _ in range(rng.randint(3, 4)):
        x = rng.randint(2, w - 3)
        length = rng.randint(h // 2, h)
        for y in range(length):
            if y > 0 and y % 3 == 0:
                x = min(w - 2, max(1, x + rng.choice([-1, 0, 1])))
            # Thick and lit at the earth, thin and dark at the tip.
            colour = lit if y < length // 3 else mid if y < length * 2 // 3 else dark
            out.putpixel((x, y), colour)
            if y < 2 and out.getpixel((x + 1, y))[3] == 0:
                out.putpixel((x + 1, y), dark)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("tile", type=Path)
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--count", type=int, default=3)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    tile = Image.open(args.tile).convert("RGBA")
    outputs = []
    for n in range(args.count):
        outputs.append((args.out_dir / f"tuft_{n}.png", tuft(tile, random.Random(args.seed * 100 + n))))
        outputs.append((args.out_dir / f"root_{n}.png", root(tile, random.Random(args.seed * 100 + 50 + n))))
    existing = [str(p) for p, _ in outputs if p.exists()]
    if existing and not args.overwrite:
        print(f"derive-decor: would overwrite {', '.join(existing)}; pass --overwrite", file=sys.stderr)
        return 1
    args.out_dir.mkdir(parents=True, exist_ok=True)
    for path, image in outputs:
        image.save(path)
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
