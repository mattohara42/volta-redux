"""Which pitch classes sound loudest in each window: a check that a score
rendered the notes it was written with."""
import sys, wave, numpy as np
NAMES = ['C','C#','D','Eb','E','F','F#','G','Ab','A','Bb','B']
def load(p):
    f = wave.open(p); n = f.getnframes()
    x = np.frombuffer(f.readframes(n), dtype='<i2').astype(float).reshape(-1, 2).mean(axis=1) / 32768
    return x
def chroma(seg, sr=44100):
    spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
    freqs = np.fft.rfftfreq(len(seg), 1 / sr)
    c = np.zeros(12)
    keep = (freqs > 60) & (freqs < 2000)
    midi = 69 + 12 * np.log2(freqs[keep] / 440.0)
    for m, a in zip(midi, spec[keep]):
        c[int(round(m)) % 12] += a * a
    return c / c.max()
x = load(sys.argv[1]); bpm = float(sys.argv[2]); beats = float(sys.argv[3])
win = int(beats * 60 / bpm * 44100)
for i in range(0, min(len(x), win * int(sys.argv[4])), win):
    c = chroma(x[i:i + win])
    top = [NAMES[k] for k in np.argsort(c)[::-1][:4]]
    print(f"{i / win + 1:>3.0f}", ' '.join(top))
