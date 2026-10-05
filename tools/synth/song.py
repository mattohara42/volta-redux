"""A song as a timeline: instruments placed at bars and beats into a stereo
mix, a reverb bus they send into, and a render that loops without a seam.

A loop is rendered with its tail (the reverb and the last notes ringing out)
and the tail is folded back onto the start, which is what a loop played twice
would have sounded like there. So the join in the engine is inaudible.
"""

import numpy as np

from dsp import pan as pan_to, reverb, samples


class Song:
    def __init__(self, bpm, bars, beats_per_bar=4, tail=3.0):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.beats_per_bar = beats_per_bar
        self.bars = bars
        self.length = bars * beats_per_bar * self.beat
        n = samples(self.length + tail)
        self.dry = np.zeros((2, n))
        self.send = np.zeros((2, n))

    def at(self, bar, beat=0.0):
        """Seconds from the start to `beat` (0-based) of `bar` (1-based)."""
        return ((bar - 1) * self.beats_per_bar + beat) * self.beat

    def beats(self, count):
        return count * self.beat

    def put(self, sound, when, gain=1.0, pan=0.0, send=0.2):
        """Places mono or stereo `sound` at `when` seconds, panned, with
        `send` of it going to the reverb as well."""
        if sound.ndim == 1:
            sound = pan_to(sound, pan)
        start = samples(when)
        stop = min(start + sound.shape[1], self.dry.shape[1])
        if stop <= start:
            return
        chunk = sound[:, : stop - start] * gain
        self.dry[:, start:stop] += chunk
        if send > 0:
            self.send[:, start:stop] += chunk * send

    def render(self, room=1.0, wet=0.9, loudness=0.19, ceiling=0.92):
        """The finished loop: dry plus reverb, the tail folded onto the start,
        brought to one loudness (RMS) so no act is louder than another, and
        its peaks rounded off under `ceiling` rather than clipped."""
        verb = reverb(self.send, wet=wet, size=room, damp=0.4, width=1.0)
        n = self.dry.shape[1]
        mix = self.dry.copy()
        mix += verb[:, :n] - self.send * (1.0 - wet * 0.5)
        loop_n = samples(self.length)
        out = mix[:, :loop_n].copy()
        tail = mix[:, loop_n:]
        # Whatever rings past the end belongs at the start of the next pass.
        out[:, : min(tail.shape[1], loop_n)] += tail[:, :loop_n]
        extra = verb[:, n:]
        out[:, : min(extra.shape[1], loop_n)] += extra[:, :loop_n]
        rms = np.sqrt(np.mean(out ** 2))
        if rms > 0:
            out = out * (loudness / rms)
        return ceiling * np.tanh(out / ceiling)
