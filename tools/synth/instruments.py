"""The band: each instrument a function from a pitch, a length and a velocity
to mono samples. Built from `dsp.py` and nothing else."""

import numpy as np

from dsp import (
    adsr, bandpass, decay, fm, highpass, lowpass, mix, noise, one_pole, osc,
    samples, soft_clip, supersaw, sweep, time, vibrato,
)

NOTE_NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def hz(name):
    """'A4' is 440 Hz. Sharps with '#', flats with 'b': 'C#5', 'Bb3'."""
    letter = name[0]
    rest = name[1:]
    shift = 0
    while rest and rest[0] in "#b":
        shift += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + NOTE_NAMES[letter] + shift
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def pluck(f, dur, vel=1.0):
    """A plucked pulse: bright on the attack, darkening as it dies."""
    length = max(dur, 0.25)
    tone = osc("pulse", f, length, width=0.28)
    tone = lowpass(tone, sweep(f * 8.0 + 800.0, f * 2.0 + 200.0, length), q=1.1)
    return tone * decay(length, 0.18 + 0.1 * min(dur, 1.0)) * vel


def bass(f, dur, vel=1.0):
    """Round and low: a triangle with a little saw for edge."""
    tone = osc("tri", f, dur) + 0.35 * osc("saw", f, dur)
    tone = lowpass(tone, f * 4.0 + 150.0)
    return tone * adsr(dur, 0.006, 0.12, 0.75, min(0.08, dur * 0.3)) * vel


def growl(f, dur, vel=1.0):
    """A bass with teeth, for the caverns: two saws beating, half-closed."""
    tone = osc("saw", f, dur) + osc("saw", f * 1.007, dur) + 0.5 * osc("square", f * 0.5, dur)
    tone = lowpass(tone, sweep(f * 9.0, f * 3.0, dur), q=1.4)
    return soft_clip(tone * 0.6, 1.8) * adsr(dur, 0.01, 0.1, 0.8, min(0.06, dur * 0.3)) * vel


def pad(freqs, dur, vel=1.0, bright=1.0, seed=0):
    """A slow chord: thick saws, filtered, swelling in and fading out."""
    out = np.zeros(samples(dur))
    for i, f in enumerate(freqs):
        out += supersaw(f, dur, voices=3, detune=0.006, seed=seed + i)
    out = lowpass(out / max(len(freqs), 1), 900.0 * bright, q=0.8)
    return out * adsr(dur, min(0.6, dur * 0.3), 0.3, 0.85, min(1.0, dur * 0.4)) * vel


def lead(f, dur, vel=1.0, width=0.5, cutoff=2600.0):
    """A singing square, vibrato arriving once the note has sounded."""
    pitch = vibrato(f, dur, rate=5.2, depth=0.008, delay=0.18)
    tone = osc("pulse", pitch, dur, width=width)
    tone = lowpass(tone, cutoff, q=0.9)
    return tone * adsr(dur, 0.012, 0.15, 0.7, min(0.12, dur * 0.4)) * vel


def brass(f, dur, vel=1.0):
    """A blown saw: the filter opens with the breath."""
    pitch = vibrato(f, dur, rate=5.0, depth=0.006, delay=0.25)
    tone = osc("saw", pitch, dur) + 0.5 * osc("saw", pitch * 1.004, dur)
    env = adsr(dur, 0.06, 0.2, 0.75, min(0.15, dur * 0.4))
    tone = lowpass(tone, 400.0 + 2400.0 * env, q=1.0)
    return tone * env * vel * 0.7


def organ(f, dur, vel=1.0):
    """Drawbars: the fundamental and its octaves and fifths, a slow tremolo."""
    t = time(dur)
    bars = [(0.5, 0.6), (1.0, 1.0), (2.0, 0.6), (3.0, 0.35), (4.0, 0.25), (6.0, 0.12)]
    tone = sum(a * osc("sine", f * r, dur) for r, a in bars) / 2.2
    tone *= 1.0 + 0.08 * np.sin(2 * np.pi * 5.8 * t)
    return tone * adsr(dur, 0.03, 0.1, 0.9, min(0.2, dur * 0.3)) * vel


def choir(f, dur, vel=1.0, seed=0):
    """Voices on 'ah': thick saws through two formant bands."""
    pitch = vibrato(f, dur, rate=4.8, depth=0.01, delay=0.1)
    src = supersaw(pitch, dur, voices=4, detune=0.01, seed=seed)
    tone = bandpass(src, 760.0, q=3.0) + 0.7 * bandpass(src, 1150.0, q=4.0) + 0.3 * bandpass(src, 2600.0, q=6.0)
    return tone * adsr(dur, min(0.35, dur * 0.3), 0.2, 0.9, min(0.6, dur * 0.4)) * vel * 1.6


def seq(f, dur, vel=1.0, cutoff=1800.0, res=3.0):
    """A sequencer note: a saw through a resonant filter that snaps shut."""
    length = max(dur, 0.06)
    tone = osc("saw", f, length)
    tone = lowpass(tone, sweep(cutoff, cutoff * 0.25 + 120.0, length), q=res)
    return soft_clip(tone * 0.7, 1.4) * decay(length, length * 0.5) * vel


def bell(f, dur, vel=1.0):
    """A struck bell, by FM: bright at first and mellowing."""
    length = max(dur, 1.2)
    tone = fm(f, 3.5, 2.6, length, index_env=decay(length, 0.25))
    return tone * decay(length, 0.55) * vel


def glass(f, dur, vel=1.0):
    """A small, high chime."""
    length = max(dur, 0.6)
    tone = fm(f, 5.0, 1.4, length, index_env=decay(length, 0.08))
    return tone * decay(length, 0.22) * vel


# Percussion. Each ignores pitch beyond a nudge.

def kick(vel=1.0):
    dur = 0.35
    body = osc("sine", sweep(130.0, 42.0, 0.12).tolist() + [42.0] * (samples(dur) - samples(0.12)), dur)
    click = highpass(noise(0.01, seed=1), 2000.0) * decay(0.01, 0.002)
    return mix(body * decay(dur, 0.12), click * 0.5) * vel


def snare(vel=1.0, seed=2):
    dur = 0.25
    tone = osc("tri", sweep(220.0, 160.0, dur), dur) * decay(dur, 0.04)
    rattle = bandpass(noise(dur, seed=seed), 2400.0, q=0.6) * decay(dur, 0.07)
    return mix(tone * 0.5, rattle) * vel


def hat(vel=1.0, open_=False, seed=3):
    dur = 0.25 if open_ else 0.06
    tone = highpass(noise(dur, seed=seed), 7000.0)
    return tone * decay(dur, 0.08 if open_ else 0.015) * vel


def tom(f=90.0, vel=1.0):
    dur = 0.5
    body = osc("sine", sweep(f * 1.6, f, 0.08).tolist() + [f] * (samples(dur) - samples(0.08)), dur)
    skin = lowpass(noise(0.05, seed=4), 1200.0) * decay(0.05, 0.01)
    return mix(body * decay(dur, 0.16), skin * 0.4) * vel


def timpani(f=65.0, vel=1.0):
    dur = 1.6
    body = osc("sine", f, dur) + 0.4 * osc("sine", f * 1.5, dur) + 0.2 * osc("sine", f * 2.0, dur)
    hit = lowpass(noise(0.08, seed=5), 600.0) * decay(0.08, 0.02)
    return mix(body * decay(dur, 0.45) * 0.6, hit) * vel


def anvil(vel=1.0, seed=6):
    """Metal on metal: the forge, the works."""
    dur = 0.6
    ratios = [1.0, 2.41, 3.83, 5.12]
    tone = sum(osc("sine", 820.0 * r, dur) * decay(dur, 0.25 / (1 + i)) for i, r in enumerate(ratios)) / 3.0
    return mix(tone, highpass(noise(0.02, seed=seed), 3000.0) * decay(0.02, 0.004)) * vel


def clank(vel=1.0, seed=7):
    """A short machine knock, in place of a snare in the works."""
    dur = 0.18
    tone = fm(330.0, 1.41, 4.0, dur, index_env=decay(dur, 0.03)) * decay(dur, 0.05)
    grit = bandpass(noise(dur, seed=seed), 3000.0, q=1.0) * decay(dur, 0.02)
    return mix(tone, grit * 0.6) * vel


def shaker(vel=1.0, seed=8):
    dur = 0.09
    return bandpass(noise(dur, seed=seed), 6000.0, q=1.5) * adsr(dur, 0.02, 0.02, 0.4, 0.04) * vel


def riser(dur, vel=1.0, seed=9):
    """Noise climbing toward a downbeat."""
    tone = bandpass(noise(dur, seed=seed), sweep(300.0, 6000.0, dur), q=2.0)
    return tone * np.linspace(0.0, 1.0, samples(dur)) ** 2 * vel


def rumble(dur, vel=1.0, seed=10):
    """The ground: very low noise, swelling."""
    tone = lowpass(noise(dur, seed=seed), 140.0) * 3.0
    return tone * adsr(dur, dur * 0.4, 0.1, 0.8, dur * 0.4) * vel
