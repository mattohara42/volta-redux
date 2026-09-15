#!/usr/bin/env python3
"""Cut a keyed sheet's modules apart into individual tight crops.

ART.md, pipeline step 3. Takes a sheet that has already been through
key.py (alpha=0 backdrop), finds each connected region of opaque pixels,
crops it tight to its own bounding box, and writes one numbered file per
region, in reading order (top row left to right, then the next row).

CLAUDE.md: the destructive mode is the flag. Writing over existing numbered
outputs needs --overwrite; the default refuses.

Usage:
    tools/cut-sheet.py SHEET.png OUT_DIR [--prefix NAME] [--min-area N] [--overwrite]

Requires pillow, numpy and scipy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

Box = tuple[slice, slice]


def _components(alpha: np.ndarray, min_area: int) -> list[Box]:
    opaque = alpha > 127
    labels, count = ndimage.label(opaque, structure=np.ones((3, 3), dtype=int))
    boxes: list[Box] = []
    for i in range(1, count + 1):
        ys, xs = np.where(labels == i)
        if ys.size < min_area:
            continue
        boxes.append((slice(int(ys.min()), int(ys.max()) + 1), slice(int(xs.min()), int(xs.max()) + 1)))
    return boxes


def _reading_order(boxes: list[Box]) -> list[Box]:
    """Top row left to right, then the next row: a box joins the first
    existing row whose vertical span it overlaps by more than half its own
    height, otherwise it starts a new row. Works for any grid spacing,
    unlike bucketing by a fixed pixel tolerance."""
    rows: list[list[Box]] = []
    spans: list[tuple[int, int]] = []
    for box in sorted(boxes, key=lambda b: b[0].start):
        y, x = box
        for i, (top, bottom) in enumerate(spans):
            overlap = min(y.stop, bottom) - max(y.start, top)
            if overlap > 0.5 * (y.stop - y.start):
                rows[i].append(box)
                spans[i] = (min(top, y.start), max(bottom, y.stop))
                break
        else:
            rows.append([box])
            spans.append((y.start, y.stop))
    ordered: list[Box] = []
    for row in rows:
        row.sort(key=lambda b: b[1].start)
        ordered.extend(row)
    return ordered


def cut(sheet: Path, out_dir: Path, prefix: str, min_area: int, overwrite: bool) -> None:
    image = Image.open(sheet)
    if image.mode != "RGBA":
        raise SystemExit(f"{sheet} has no alpha channel; run key.py on it first.")
    alpha = np.asarray(image)[..., 3]
    boxes = _reading_order(_components(alpha, min_area))
    if not boxes:
        raise SystemExit(f"{sheet}: no opaque regions found above --min-area {min_area}.")

    out_dir.mkdir(parents=True, exist_ok=True)
    digits = len(str(len(boxes)))
    for i, (ys, xs) in enumerate(boxes, start=1):
        out_path = out_dir / f"{prefix}_{i:0{digits}d}.png"
        if out_path.exists() and not overwrite:
            raise SystemExit(f"{out_path} already exists; pass --overwrite to replace it.")
        crop = image.crop((xs.start, ys.start, xs.stop, ys.stop))
        crop.save(out_path)
        print(f"{out_path}: {xs.stop - xs.start}x{ys.stop - ys.start}")
    print(f"{len(boxes)} module(s) cut from {sheet}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("sheet", type=Path)
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--prefix", default="tile", help="Output filename prefix (default 'tile').")
    parser.add_argument(
        "--min-area", type=int, default=200,
        help="Discard connected regions smaller than this many pixels, noise left over from keying (default 200).",
    )
    parser.add_argument("--overwrite", action="store_true", help="Replace existing numbered outputs.")
    args = parser.parse_args(argv)
    cut(args.sheet, args.out_dir, args.prefix, args.min_area, args.overwrite)
    return 0


if __name__ == "__main__":
    sys.exit(main())
