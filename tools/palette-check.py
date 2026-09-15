#!/usr/bin/env python3
"""Check a delivery against ART_DIRECTION.md's one rule: no neutral darks.

"Every dark is a coloured dark... If a value is below about 15% luminance and
its saturation is under about 0.12, it is wrong."

Usage:
    tools/palette-check.py IMAGE.png [--max-violation-pct 0.5] [--mark OUT.png]

Exits non-zero when the violating fraction of opaque pixels exceeds
--max-violation-pct. --mark writes a copy with every violating pixel painted
warning red: a percentage does not say where to fix the painting, the render
does (CLAUDE.md: draw the thing you measured).

Requires pillow and numpy (tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

_LUMINANCE_THRESHOLD = 0.15
_SATURATION_THRESHOLD = 0.12
_WARNING_COLOUR = (255, 32, 32)


def _luminance(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return 0.299 * r + 0.587 * g + 0.114 * b


def _saturation(rgb: np.ndarray) -> np.ndarray:
    maxc = rgb.max(axis=-1)
    minc = rgb.min(axis=-1)
    delta = maxc - minc
    return np.divide(delta, maxc, out=np.zeros_like(delta), where=maxc > 0)


def check(path: Path, max_violation_pct: float, mark: Path | None) -> bool:
    image = Image.open(path).convert("RGBA")
    arr = np.asarray(image).astype(np.float64) / 255.0
    rgb, alpha = arr[..., :3], arr[..., 3]
    opaque = alpha > 0.5

    luminance = _luminance(rgb)
    saturation = _saturation(rgb)
    violating = opaque & (luminance < _LUMINANCE_THRESHOLD) & (saturation < _SATURATION_THRESHOLD)

    total = int(opaque.sum())
    bad = int(violating.sum())
    pct = 100.0 * bad / total if total else 0.0
    print(f"{path}: {bad}/{total} opaque pixels ({pct:.2f}%) are a neutral dark.")

    if mark is not None:
        marked = np.asarray(image.convert("RGB")).copy()
        marked[violating] = _WARNING_COLOUR
        mark.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(marked).save(mark)
        print(f"violations marked in {mark}")

    return pct <= max_violation_pct


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("image", type=Path)
    parser.add_argument(
        "--max-violation-pct", type=float, default=0.5,
        help="Fail if more than this percent of opaque pixels are a neutral dark (default 0.5).",
    )
    parser.add_argument("--mark", type=Path, default=None, help="Write a copy with violations painted warning red.")
    args = parser.parse_args(argv)
    ok = check(args.image, args.max_violation_pct, args.mark)
    if not ok:
        print("FAIL: too many neutral-dark pixels. See ART_DIRECTION.md's 'one rule'.")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
