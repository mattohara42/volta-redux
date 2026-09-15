#!/usr/bin/env python3
"""Cut one character painting into named rig parts.

ART.md, pipeline step 4, the step before the manual one: parts become a
Skeleton2D scene by hand in Godot after this. Unlike a sheet, a character
painting is one continuous, connected shape: there is no backdrop between
an arm and a torso for connected-components to find, so a part is a named
rectangle a person reads off the painting, not something this tool detects.

This means parts are cut as overlapping rectangles, not pixel-exact
silhouettes: an upper arm's box and the torso's box both contain a few of
the same pixels where they meet at the shoulder. That is fine and expected.
Draw the parts back to front in Godot in the same order they were layered
in the source painting (torso first, then the near arm and leg on top of
it, in whatever order the painting actually stacks them) and the
overlapping pixels never show, because only the topmost part's pixels are
visible at any point where two boxes cover the same spot. A pixel-exact
mask is not needed for a roughly tube-shaped limb; it would be for a part
whose silhouette isn't well approximated by a rectangle.

CLAUDE.md's Godot import note applies to every part this cuts: keep the
part's offset from the source canvas rather than trimming it to its own
content, or it will not register with its neighbours once it is parented to
a bone at the source position. This tool crops but never trims, so that
offset is exactly the box's own (x1, y1).

Usage:
    tools/cut-rig.py SHEET.png OUT_DIR --box name:x1,y1,x2,y2 [--box ...] [--overwrite]

Boxes are source-image pixel coordinates. A grid overlay over the source
painting makes them easy to read off by eye; see ART.md for the hero's.

Requires pillow (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

Box = tuple[str, int, int, int, int]


def cut(sheet: Path, out_dir: Path, boxes: list[Box], overwrite: bool) -> None:
    image = Image.open(sheet)
    if image.mode != "RGBA":
        raise SystemExit(f"{sheet} has no alpha channel; run key.py on it first.")
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, x1, y1, x2, y2 in boxes:
        out_path = out_dir / f"{name}.png"
        if out_path.exists() and not overwrite:
            raise SystemExit(f"{out_path} already exists; pass --overwrite to replace it.")
        crop = image.crop((x1, y1, x2, y2))
        crop.save(out_path)
        print(f"{out_path}: {x2 - x1}x{y2 - y1} at source offset ({x1}, {y1})")


def _parse_box(value: str) -> Box:
    try:
        name, coords = value.split(":", 1)
        x1, y1, x2, y2 = (int(v) for v in coords.split(","))
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"expected name:x1,y1,x2,y2, got {value!r}") from exc
    return name, x1, y1, x2, y2


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("sheet", type=Path)
    parser.add_argument("out_dir", type=Path)
    parser.add_argument(
        "--box", action="append", type=_parse_box, dest="boxes", default=[],
        metavar="name:x1,y1,x2,y2",
        help="A named part and its source-image pixel box. Repeatable.",
    )
    parser.add_argument("--overwrite", action="store_true", help="Replace existing named outputs.")
    args = parser.parse_args(argv)
    if not args.boxes:
        raise SystemExit("at least one --box is required")
    cut(args.sheet, args.out_dir, args.boxes, args.overwrite)
    return 0


if __name__ == "__main__":
    sys.exit(main())
