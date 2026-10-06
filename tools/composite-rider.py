"""Lothar riding the dragon, as one sheet: the rider cut from a still and laid
onto every frame of the dragon's clean wing beat.

R2 (2026-10-06). The family playtest said the old ride did not read: the
standing hero sprite was stacked on the dragon's back. Sprite Fusion drew a
good still of him seated astride (`ride_dragon_rider_0`, a two-image `edit`),
but animating it smeared the wing. So the rider is cut from that still where
it differs from the original flying dragon (`enemy_dragon_flying_1`, aligned
by the offset below), holes filled and specks dropped, and pasted onto each
frame of `dragon_flight_sheet.png`, whose wing beat is clean.

    python3 tools/composite-rider.py            # writes the sheet
"""
import numpy as np
from PIL import Image
ride=np.array(Image.open('assets/art_raw/ride_dragon_rider_0.png').convert('RGBA')).astype(int)
src=np.array(Image.open('assets/art_raw/enemy_dragon_flying_1.png').convert('RGBA')).astype(int)
sheet=np.array(Image.open('assets/art/enemies/dragon_flight_sheet.png').convert('RGBA')).astype(int)
fw=sheet.shape[1]//4
f0=sheet[:,0:fw]
# Align the still to the first clean frame on the rows below the rider.
best=None
H,W=f0.shape[:2]
for dy in range(-4,5):
  for dx in range(-4,5):
    err=0;n=0
    for y in range(35,H):
      ry=y+dy
      if ry<0 or ry>=ride.shape[0]: continue
      for x in range(0,W):
        rx=x+dx
        if rx<0 or rx>=ride.shape[1]: continue
        a=f0[y,x];b=ride[ry,rx]
        if a[3]>0 or b[3]>0:
          err+=abs(a[:3]-b[:3]).sum()*(1 if a[3]>0 and b[3]>0 else 0)+(0 if (a[3]>0)==(b[3]>0) else 300); n+=1
    e=err/max(n,1)
    if best is None or e<best[0]: best=(e,dx,dy)
_, dx, dy = best
diff=np.zeros((ride.shape[0],ride.shape[1]),bool)
for ry in range(ride.shape[0]):
  for rx in range(ride.shape[1]):
    b=ride[ry,rx]
    if b[3]==0: continue
    y=ry-dy;x=rx-dx
    a=f0[y,x] if 0<=y<H and 0<=x<W else np.array([0,0,0,0])
    if a[3]==0 or abs(a[:3]-b[:3]).sum()>90: diff[ry,rx]=True
from collections import deque
def shift_or(a):
    o=a.copy()
    for oy in (-1,0,1):
        for ox in (-1,0,1):
            o|=np.roll(np.roll(a,oy,0),ox,1)
    return o
def shift_and(a):
    o=a.copy()
    for oy in (-1,0,1):
        for ox in (-1,0,1):
            o&=np.roll(np.roll(a,oy,0),ox,1)
    return o
def components(a):
    seen=np.zeros_like(a); comps=[]
    for y,x in zip(*np.where(a)):
        if seen[y,x]: continue
        q=deque([(y,x)]); seen[y,x]=True; c=[]
        while q:
            cy,cx=q.popleft(); c.append((cy,cx))
            for ny,nx in ((cy+1,cx),(cy-1,cx),(cy,cx+1),(cy,cx-1)):
                if 0<=ny<a.shape[0] and 0<=nx<a.shape[1] and a[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True; q.append((ny,nx))
        comps.append(c)
    return comps
m=diff.copy(); m[:, :60]=False; m[56:,:]=False
m=shift_and(shift_or(m))
outside=np.zeros_like(m); q=deque()
for y in range(m.shape[0]):
    for x in (0,m.shape[1]-1):
        if not m[y,x]: q.append((y,x)); outside[y,x]=True
for x in range(m.shape[1]):
    for y in (0,m.shape[0]-1):
        if not m[y,x] and not outside[y,x]: q.append((y,x)); outside[y,x]=True
while q:
    cy,cx=q.popleft()
    for ny,nx in ((cy+1,cx),(cy-1,cx),(cy,cx+1),(cy,cx-1)):
        if 0<=ny<m.shape[0] and 0<=nx<m.shape[1] and not m[ny,nx] and not outside[ny,nx]:
            outside[ny,nx]=True; q.append((ny,nx))
m=~outside
keep=np.zeros_like(m)
for c in components(m):
    if len(c)>=20:
        for y,x in c: keep[y,x]=True
m=keep & (ride[:,:,3]>0)
# composite canvas: same width, height H + pad so the raised sword fits
ys=np.where(m)[0]; pad=max(0, -(ys.min()-dy))
frames=[]
for i in range(4):
    f=sheet[:, i*fw:(i+1)*fw].copy()
    canvas=np.zeros((H+pad, fw, 4), int); canvas[pad:]=f
    for ry,rx in zip(*np.where(m)):
        canvas[ry-dy+pad, rx-dx]=ride[ry,rx]
    frames.append(canvas)
out=np.concatenate(frames,axis=1).astype('uint8')
Image.fromarray(out,'RGBA').save('assets/art/enemies/dragon_rider_sheet.png')
