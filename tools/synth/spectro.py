"""Draws a sound so it can be looked at: waveform over spectrogram, one row
per file. The audio version of CLAUDE.md's "draw the thing you measured"."""
import sys
import wave
import numpy as np
from PIL import Image, ImageDraw
from scipy import signal


def load(path):
    with wave.open(path) as f:
        n = f.getnframes(); ch = f.getnchannels(); sr = f.getframerate()
        data = np.frombuffer(f.readframes(n), dtype="<i2").astype(float) / 32768.0
    if ch == 2:
        data = data.reshape(-1, 2).mean(axis=1)
    return data, sr


def row(path, width=900, height=150):
    x, sr = load(path)
    img = Image.new("RGB", (width, height + 60), (20, 16, 34))
    d = ImageDraw.Draw(img)
    # waveform
    cols = np.array_split(x, width)
    for i, c in enumerate(cols):
        if c.size:
            lo, hi = c.min(), c.max()
            d.line([(i, 30 - hi * 28), (i, 30 - lo * 28)], fill=(240, 166, 60))
    f, t, s = signal.spectrogram(x, sr, nperseg=512, noverlap=384)
    s = 10 * np.log10(s + 1e-12)
    s = np.clip((s + 100) / 80, 0, 1)
    keep = f < 8000
    s = s[keep][::-1]
    im = Image.fromarray((s * 255).astype(np.uint8)).resize((width, height))
    col = Image.merge("RGB", (im, im.point(lambda v: int(v * 0.8)), im.point(lambda v: int(min(255, v * 1.2)))))
    img.paste(col, (0, 60))
    d.text((4, 2), f"{path.split('/')[-1]}  {x.size / sr:.2f}s  peak {np.abs(x).max():.2f}", fill=(255, 217, 138))
    return img


rows = [row(p) for p in sys.argv[2:]]
out = Image.new("RGB", (900, sum(r.height for r in rows)))
y = 0
for r in rows:
    out.paste(r, (0, y)); y += r.height
out.save(sys.argv[1])
