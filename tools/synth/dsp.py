"""The signal side of the synth: oscillators, envelopes, filters, space.

Everything is numpy arrays of float64 at `SR` samples a second, mono unless a
function says it is stereo (an array of shape (2, n)). Nothing here knows what a
sword or a cavern is; `sfx.py` and `music.py` do.

Deterministic on purpose. Every source of noise takes a seed, so rendering the
same sound twice gives the same file, and a diff of a regenerated asset means a
recipe changed rather than that the dice did.
"""

import numpy as np
from scipy import signal

SR = 44100


def seconds(n):
    return n / SR


def samples(dur):
    return max(int(round(dur * SR)), 1)


def time(dur):
    return np.arange(samples(dur)) / SR


def _as_array(value, n):
    if np.isscalar(value):
        return np.full(n, float(value))
    value = np.asarray(value, dtype=float)
    if value.shape[0] != n:
        value = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, value.shape[0]), value)
    return value


def sweep(start, end, dur, curve="exp"):
    """A frequency (or any value) moving from `start` to `end` over `dur`."""
    n = samples(dur)
    t = np.linspace(0.0, 1.0, n)
    if curve == "exp" and start > 0 and end > 0:
        return start * (end / start) ** t
    return start + (end - start) * t


def _phase(freq, n, phase0=0.0):
    f = _as_array(freq, n)
    return (phase0 + np.cumsum(f) / SR) % 1.0, f / SR


def _blep(t, dt):
    """PolyBLEP: the correction that takes the alias out of a hard edge."""
    y = np.zeros_like(t)
    m = t < dt
    x = t[m] / dt[m]
    y[m] = x + x - x * x - 1.0
    m = t > 1.0 - dt
    x = (t[m] - 1.0) / dt[m]
    y[m] = x * x + x + x + 1.0
    return y


def osc(kind, freq, dur, width=0.5, phase0=0.0):
    """One oscillator. `freq` is a number or an array (a sweep, a vibrato)."""
    n = samples(dur)
    t, dt = _phase(freq, n, phase0)
    dt = np.clip(dt, 1e-6, 0.5)
    if kind == "sine":
        return np.sin(2 * np.pi * t)
    if kind == "tri":
        return 2.0 * np.abs(2.0 * t - 1.0) - 1.0
    if kind == "saw":
        return 2.0 * t - 1.0 - _blep(t, dt)
    if kind in ("square", "pulse"):
        y = np.where(t < width, 1.0, -1.0)
        y += _blep(t, dt)
        y -= _blep((t + 1.0 - width) % 1.0, dt)
        return y
    raise ValueError(kind)


def noise(dur, seed=0):
    return np.random.default_rng(seed).uniform(-1.0, 1.0, samples(dur))


def supersaw(freq, dur, voices=3, detune=0.008, seed=0):
    """Several saws a hair apart, the thick sound a pad is made of."""
    rng = np.random.default_rng(seed)
    out = np.zeros(samples(dur))
    for i in range(voices):
        spread = (i - (voices - 1) / 2.0) * detune
        f = _as_array(freq, samples(dur)) * (1.0 + spread)
        out += osc("saw", f, dur, phase0=rng.uniform())
    return out / voices


def adsr(dur, attack=0.005, decay=0.05, sustain=0.7, release=0.1, hold=None):
    """A note envelope. `hold` is how long the key is down (default: until
    the release has to start to end exactly at `dur`)."""
    n = samples(dur)
    if hold is None:
        hold = max(dur - release, 0.0)
    t = np.arange(n) / SR
    env = np.zeros(n)
    a = max(attack, 1e-4)
    d = max(decay, 1e-4)
    rising = t < a
    env[rising] = t[rising] / a
    falling = (t >= a) & (t < a + d)
    env[falling] = 1.0 - (1.0 - sustain) * (t[falling] - a) / d
    env[(t >= a + d)] = sustain
    level_at_release = np.interp(hold, t, env) if n > 1 else sustain
    after = t >= hold
    env[after] = level_at_release * np.clip(1.0 - (t[after] - hold) / max(release, 1e-4), 0.0, 1.0)
    return env


def decay(dur, tau, attack=0.002):
    """A hit: up fast, then down exponentially with time constant `tau`."""
    t = time(dur)
    env = np.exp(-t / max(tau, 1e-4))
    if attack > 0:
        env *= np.clip(t / attack, 0.0, 1.0)
    return env


def lowpass(x, cutoff, q=0.707, order=2):
    """A low-pass. `cutoff` a number, or an array for a filter that moves,
    processed in short blocks with the filter's state carried between them."""
    return _filter(x, cutoff, "low", q)


def highpass(x, cutoff, q=0.707):
    return _filter(x, cutoff, "high", q)


def bandpass(x, centre, q=2.0):
    return _filter(x, centre, "band", q)


def _biquad(kind, f, q):
    w = 2 * np.pi * np.clip(f, 20.0, SR * 0.45) / SR
    alpha = np.sin(w) / (2 * q)
    cw = np.cos(w)
    if kind == "low":
        b = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2]
    elif kind == "high":
        b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
    else:
        b = [alpha, 0.0, -alpha]
    a = [1 + alpha, -2 * cw, 1 - alpha]
    return np.array(b) / a[0], np.array(a) / a[0]


def _filter(x, freq, kind, q, block=64):
    if np.isscalar(freq):
        b, a = _biquad(kind, freq, q)
        return signal.lfilter(b, a, x)
    f = _as_array(freq, x.shape[0])
    out = np.empty_like(x)
    zi = np.zeros(2)
    for start in range(0, x.shape[0], block):
        stop = min(start + block, x.shape[0])
        b, a = _biquad(kind, f[start], q)
        out[start:stop], zi = signal.lfilter(b, a, x[start:stop], zi=zi)
    return out


def one_pole(x, cutoff):
    """A gentle 6 dB slope, for taking the fizz off something."""
    k = np.exp(-2 * np.pi * cutoff / SR)
    return signal.lfilter([1 - k], [1, -k], x)


def fm(carrier, ratio, index, dur, index_env=None):
    """Two-operator FM: bells, metal, glass. `index_env` shapes the brightness."""
    n = samples(dur)
    t = np.arange(n) / SR
    c = _as_array(carrier, n)
    m_phase = 2 * np.pi * np.cumsum(c * ratio) / SR
    idx = index * (index_env if index_env is not None else 1.0)
    c_phase = 2 * np.pi * np.cumsum(c) / SR
    return np.sin(c_phase + idx * np.sin(m_phase))


def inharmonic(base, partials, dur, taus, seed=0):
    """A struck metal object: partials at non-integer ratios, each dying at
    its own rate, the higher ones faster."""
    rng = np.random.default_rng(seed)
    out = np.zeros(samples(dur))
    for ratio, tau in zip(partials, taus):
        out += osc("sine", base * ratio, dur, phase0=rng.uniform()) * decay(dur, tau, attack=0.0005)
    return out / max(len(partials), 1)


def vibrato(freq, dur, rate=5.5, depth=0.01, delay=0.0):
    t = time(dur)
    onset = np.clip((t - delay) / 0.25, 0.0, 1.0) if delay > 0 else 1.0
    return _as_array(freq, t.shape[0]) * (1.0 + depth * onset * np.sin(2 * np.pi * rate * t))


def mix(*parts):
    """Sums arrays of different lengths, padding the short ones."""
    n = max(p.shape[-1] for p in parts)
    out = np.zeros(n) if parts[0].ndim == 1 else np.zeros((2, n))
    for p in parts:
        if out.ndim == 2 and p.ndim == 1:
            out[:, : p.shape[0]] += p
        else:
            out[..., : p.shape[-1]] += p
    return out


def pad_to(x, dur):
    n = samples(dur)
    if x.shape[-1] >= n:
        return x[..., :n]
    pad = [(0, 0)] * (x.ndim - 1) + [(0, n - x.shape[-1])]
    return np.pad(x, pad)


def delayed(x, dur):
    n = samples(dur)
    pad = [(0, 0)] * (x.ndim - 1) + [(n, 0)]
    return np.pad(x, pad)


def soft_clip(x, drive=1.0):
    return np.tanh(x * drive) / np.tanh(drive)


def fade(x, fade_in=0.002, fade_out=0.01):
    """Ramps both ends, so no sound starts or stops with a click."""
    x = x.copy()
    n = x.shape[-1]
    a = min(samples(fade_in), n)
    b = min(samples(fade_out), n)
    if a > 0:
        x[..., :a] *= np.linspace(0.0, 1.0, a)
    if b > 0:
        x[..., n - b:] *= np.linspace(1.0, 0.0, b)
    return x


def normalise(x, peak=0.89):
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


def pan(x, position):
    """Mono to stereo, `position` -1 left to 1 right, constant power."""
    angle = (position + 1.0) * np.pi / 4.0
    return np.stack([x * np.cos(angle), x * np.sin(angle)])


def _comb(x, delay_samples, feedback, damp):
    # y[n] = x[n] + feedback * lowpass(y[n - d]). The damping one-pole inside
    # the loop is what makes a reverb's tail darken as it dies.
    state = 0.0
    y = np.zeros(x.shape[0])
    # Block-wise: each block of `delay_samples` only depends on the previous.
    d = delay_samples
    for start in range(0, x.shape[0], d):
        stop = min(start + d, x.shape[0])
        prev = y[start - d: stop - d] if start >= d else np.zeros(stop - start)
        filtered, state_arr = signal.lfilter([1 - damp], [1, -damp], prev, zi=[state])
        state = state_arr[0]
        y[start:stop] = x[start:stop] + feedback * filtered
    return y


def _allpass(x, delay_samples, gain=0.5):
    b = np.zeros(delay_samples + 1)
    a = np.zeros(delay_samples + 1)
    b[0] = -gain
    b[-1] = 1.0
    a[0] = 1.0
    a[-1] = -gain
    return signal.lfilter(b, a, x)


def reverb(x, wet=0.25, size=1.0, damp=0.35, width=1.0, predelay=0.012):
    """A Schroeder/Freeverb room: parallel damped combs, then allpasses, a
    little apart in each ear so the space is wide. Mono or stereo in, stereo
    out, with a tail long enough to ring out."""
    if x.ndim == 1:
        x = np.stack([x, x])
    tail = samples(1.6 * size)
    x = np.pad(x, ((0, 0), (0, tail)))
    dry = x
    mono = x.mean(axis=0)
    mono = np.pad(mono, (samples(predelay), 0))[: mono.shape[0]]
    combs = [1116, 1188, 1277, 1356, 1422, 1491]
    allpasses = [556, 441, 341]
    out = []
    for ear, spread in enumerate([0, 23]):
        acc = np.zeros_like(mono)
        for c in combs:
            acc += _comb(mono, int((c + spread) * size), 0.84, damp)
        acc /= len(combs)
        for a in allpasses:
            acc = _allpass(acc, a + spread)
        out.append(acc)
    wet_sig = np.stack(out)
    mid = wet_sig.mean(axis=0)
    wet_sig = mid + (wet_sig - mid) * width
    return dry * (1.0 - wet * 0.5) + wet_sig * wet


def echo(x, time_s, feedback=0.35, wet=0.3, repeats=6):
    n = samples(time_s)
    out = x.copy()
    pad = [(0, 0)] * (x.ndim - 1) + [(0, n * repeats)]
    out = np.pad(out, pad)
    tap = x
    gain = wet
    for i in range(1, repeats + 1):
        out[..., n * i: n * i + tap.shape[-1]] += tap * gain
        gain *= feedback
    return out


def write_wav(path, x, peak=None, loop=False):
    """16-bit WAV, mono or stereo. `loop` writes a `smpl` chunk marking the
    whole file as a forward loop, which Godot's importer reads by default
    ("Detect From WAV"). The loop lives in the file because `*.import` is not
    committed here: settings put there never reach CI or a fresh checkout."""
    import struct
    import wave
    if peak is not None:
        x = normalise(x, peak)
    x = np.clip(x, -1.0, 1.0)
    data = (x * 32767.0).astype("<i2")
    channels = 1 if data.ndim == 1 else 2
    frames = data.shape[-1]
    if channels == 2:
        data = data.T.reshape(-1)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(channels)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data.tobytes())
    if loop:
        smpl = struct.pack(
            "<9I6I",
            0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0,
            0, 0, 0, frames - 1, 0, 0,
        )
        with open(path, "r+b") as f:
            f.seek(0, 2)
            f.write(b"smpl" + struct.pack("<I", len(smpl)) + smpl)
            riff_size = f.tell() - 8
            f.seek(4)
            f.write(struct.pack("<I", riff_size))


def write_ogg(path, x, quality=4):
    """Ogg Vorbis through ffmpeg, which every machine this repo builds on has."""
    import subprocess
    import tempfile
    import os
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_path = tmp.name
    try:
        write_wav(tmp_path, x)
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", tmp_path, "-c:a", "libvorbis",
             "-q:a", str(quality), str(path)],
            check=True,
        )
    finally:
        os.unlink(tmp_path)
