#!/usr/bin/env python3
"""Portal door art from the cut door sheet (ART.md, *The portal's doors*).

For each material, the arch is the frame, the opening is found row by row,
the slab is cut from the middle of the matching door piece to the opening's
shape, and both are pixelated at one scale so the opening is HOLE_H tall.
Prints each opening's rect in its frame, for `ActTiles.portal_hole`.

Usage:
    tools/key.py kit_portals.jpg DIR/keyed.png --tolerance 40
    tools/cut-sheet.py DIR/keyed.png DIR/cut --prefix p --min-area 2000
    tools/portal-art.py DIR        # writes DIR/px/portal_<material>_{frame,slab}.png
"""
import json, sys
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image

S = Path(sys.argv[1]); OUT = S / "px"; OUT.mkdir(exist_ok=True)  # a folder holding cut/p_1..9.png from cut-sheet.py
HOLE_H = 48  # the door rect's height in the game, px

def hole_mask(a):
    """The opening, row by row: the clear run through the opening's middle,
    held to the width it has at two-thirds height, where both legs stand."""
    alpha = a[..., 3] > 0
    h, w = alpha.shape
    def run(y, x):
        if alpha[y, x]:
            return None
        l = x
        while l > 0 and not alpha[y, l - 1]:
            l -= 1
        r = x
        while r < w - 1 and not alpha[y, r + 1]:
            r += 1
        if l == 0 or r == w - 1:
            return None  # open to the outside: not inside the arch
        return l, r
    ym = int(h * 0.66)
    # the bounded clear run nearest the middle of that row
    best = None
    for x in range(w):
        rr = run(ym, x)
        if rr and (best is None or abs((rr[0] + rr[1]) / 2 - w / 2) < abs((best[0] + best[1]) / 2 - w / 2)):
            best = rr
    x0, x1 = best
    cx = (x0 + x1) // 2
    mask = np.zeros_like(alpha)
    y = ym
    while y >= 0 and run(y, cx):  # up to the arch's crown
        l, r = run(y, cx); mask[y, max(l, x0):min(r, x1) + 1] = True; y -= 1
    for y in range(ym + 1, h):  # down to the floor, between the legs
        mask[y, x0:x1 + 1] = ~alpha[y, x0:x1 + 1]
    return mask


def clean(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    a[(r > 170) & (b > 170) & (g < 120), 3] = 0  # magenta flecks
    return a

def pix(img, size):
    """Box downscale then every pixel opaque or clear, as pixel art is."""
    rgba = np.asarray(img.convert("RGBA")).astype(float)
    pre = rgba.copy(); pre[..., :3] *= pre[..., 3:4] / 255.0
    small = Image.fromarray(pre.astype(np.uint8), "RGBA").resize(size, Image.BOX)
    s = np.asarray(small).astype(float)
    al = s[..., 3:4]
    rgb = np.where(al > 0, s[..., :3] * 255.0 / np.maximum(al, 1), 0)
    out = np.dstack([rgb, np.where(al[..., 0] >= 128, 255, 0)]).clip(0, 255).astype(np.uint8)
    im = Image.fromarray(out, "RGBA")
    q = im.convert("RGB").quantize(24, method=Image.Quantize.FASTOCTREE).convert("RGB")
    return Image.fromarray(np.dstack([np.asarray(q), out[..., 3]]), "RGBA")

# material: frame piece, door piece, the door's interior as fractions (l, t, r, b)
MATERIALS = {
    "stump": ("p_1", "p_2", (0.12, 0.12, 0.88, 0.80)),
    "stone": ("p_4", "p_5", None),  # same size as its arch: masked in place
    "basalt": ("p_7", "p_8", (0.16, 0.16, 0.84, 0.97)),
}
meta = {}
for name, (frame_id, door_id, inner) in MATERIALS.items():
    frame = clean(np.array(Image.open(S / "cut" / f"{frame_id}.png").convert("RGBA")))
    door = clean(np.array(Image.open(S / "cut" / f"{door_id}.png").convert("RGBA")))
    mask = hole_mask(frame)
    ys, xs = np.nonzero(mask)
    hx0, hy0, hx1, hy1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    hw, hh = hx1 - hx0, hy1 - hy0
    if inner is None:
        slab = door[hy0:hy1, hx0:hx1].copy()
    else:
        dh, dw = door.shape[:2]
        l, t, r, b = inner
        crop = Image.fromarray(door).crop((int(l * dw), int(t * dh), int(r * dw), int(b * dh)))
        slab = np.array(crop.resize((hw, hh), Image.LANCZOS))
    slab[..., 3] = np.where(mask[hy0:hy1, hx0:hx1], 255, 0)
    s = HOLE_H / hh
    fsize = (round(frame.shape[1] * s), round(frame.shape[0] * s))
    hole = [round(hx0 * s), round(hy0 * s), round(hw * s), HOLE_H]
    pix(Image.fromarray(frame), fsize).save(OUT / f"portal_{name}_frame.png")
    pix(Image.fromarray(slab), (hole[2], hole[3])).save(OUT / f"portal_{name}_slab.png")
    meta[name] = {"frame": fsize, "hole": hole, "scale": round(s, 4)}
print(json.dumps(meta, indent=1))
