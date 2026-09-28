#!/usr/bin/env python3
"""Derive N variants of a masonry tile, so a wall of it is not wallpaper.

ART.md: don't generate a piece you could derive. Each brick (a connected
region of non-mortar pixels, joined across the tile's edges so a brick that
wraps stays one brick) gets its own small shift in brightness, and a few get
a damp green cast or a chipped corner. The mortar is never touched, so every
variant joins every other one seamlessly, exactly as the source tile does.

Variant 0 is the source, unchanged. Rows above --lock-top are left alone,
which is how a floor tile keeps its walkable lip identical in every variant.

The source is never modified. Existing outputs need --overwrite (CLAUDE.md:
the destructive mode is the flag).

Usage:
    tools/tile-variants.py TILE.png OUT_STEM --count 4 [--lock-top 4]
        [--mortar-below 0.2] [--seed 1] [--overwrite]
writes OUT_STEM_0.png .. OUT_STEM_<count-1>.png

Requires pillow and numpy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import colorsys
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# How far one brick's brightness may move, as a fraction of its value.
_VALUE_JITTER = 0.10
# Chance a brick is damp (a green cast) or chipped (one corner pixel lost).
_DAMP_CHANCE = 0.12
_CHIP_CHANCE = 0.15
# The damp cast: hue pulled this far toward green, as ART_DIRECTION.md's
# "damp and slightly green in the moat".
_DAMP_HUE = 150.0 / 360.0
_DAMP_PULL = 0.25


def _luminance(rgb: np.ndarray) -> np.ndarray:
    return 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]


def label_bricks(brick: np.ndarray) -> np.ndarray:
    """4-connected labels of `brick`, with the tile's edges wrapping, so a
    brick cut by the tile boundary is one label. Mortar is -1."""
    h, w = brick.shape
    parent = list(range(h * w))

    def find(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for y in range(h):
        for x in range(w):
            if not brick[y, x]:
                continue
            for ny, nx in ((y, (x + 1) % w), ((y + 1) % h, x)):
                if brick[ny, nx]:
                    parent[find(y * w + x)] = find(ny * w + nx)
    labels = np.full((h, w), -1, dtype=int)
    for y in range(h):
        for x in range(w):
            if brick[y, x]:
                labels[y, x] = find(y * w + x)
    return labels


def _mortar_sides(labels: np.ndarray, y: int, x: int) -> int:
    h, w = labels.shape
    return sum(labels[(y + dy) % h, (x + dx) % w] < 0 for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)))


def make_variant(rgba: np.ndarray, labels: np.ndarray, rng: random.Random) -> np.ndarray:
    out = rgba.astype(np.float64) / 255.0
    for label in np.unique(labels[labels >= 0]):
        cells = np.argwhere(labels == label)
        scale = 1.0 + rng.uniform(-_VALUE_JITTER, _VALUE_JITTER)
        damp = rng.random() < _DAMP_CHANCE
        for y, x in cells:
            h, s, v = colorsys.rgb_to_hsv(*out[y, x, :3])
            if damp:
                h = h + (_DAMP_HUE - h) * _DAMP_PULL
            out[y, x, :3] = colorsys.hsv_to_rgb(h, s, min(1.0, v * scale))
        if rng.random() < _CHIP_CHANCE:
            corners = [(y, x) for y, x in cells if _mortar_sides(labels, y, x) >= 2]
            mortar = np.argwhere(labels < 0)
            if corners and len(mortar):
                y, x = corners[rng.randrange(len(corners))]
                my, mx = mortar[0]
                out[y, x] = rgba[my, mx].astype(np.float64) / 255.0
    return np.round(out * 255.0).astype(np.uint8)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("tile", type=Path)
    parser.add_argument("out_stem", type=Path)
    parser.add_argument("--count", type=int, default=4)
    parser.add_argument("--lock-top", type=int, default=0, help="Rows at the top left untouched.")
    parser.add_argument("--mortar-below", type=float, default=0.2, help="Luminance under which a pixel is mortar.")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args(argv)

    outs = [args.out_stem.with_name(f"{args.out_stem.name}_{i}.png") for i in range(args.count)]
    if any(o.resolve() == args.tile.resolve() for o in outs):
        raise SystemExit("tile-variants.py: an output would overwrite the source tile.")
    existing = [o for o in outs if o.exists()]
    if existing and not args.overwrite:
        raise SystemExit(f"tile-variants.py: {existing[0]} already exists; pass --overwrite to replace.")

    rgba = np.asarray(Image.open(args.tile).convert("RGBA"))
    rgb = rgba[..., :3].astype(np.float64) / 255.0
    brick = (_luminance(rgb) >= args.mortar_below) & (rgba[..., 3] > 127)
    brick[: args.lock_top] = False
    labels = label_bricks(brick)
    rng = random.Random(args.seed)

    outs[0].parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, mode="RGBA").save(outs[0])
    for out in outs[1:]:
        Image.fromarray(make_variant(rgba, labels, rng), mode="RGBA").save(out)
    print(f"{args.tile} -> {len(outs)} variants, {len(np.unique(labels[labels >= 0]))} bricks each")
    return 0


if __name__ == "__main__":
    sys.exit(main())
