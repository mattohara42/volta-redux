"""The score: one loop per act and one for the ride out.

Each act sounds like its place and its verb. Act 1 is a wary march along a
wall at night, D minor, plucked and restrained. Act 2 is the caverns, E
Phrygian, slow and heavy, a forge in the dark. Act 3 is the generator, A
minor, a sequencer that never stops, metal for drums. Act 4 is Volta's hall,
C minor, organ and choir and timpani. The flight is the only major key in the
game, and the only time the drums run.

Each boss room has its own loop in its act's key, built from its act's
material and pushed harder: the dragon is Act 2's riff at a gallop with a
roar in it, the generator is Act 3's sequencer gone haywire, a semitone
alarm over it, and Volta is Act 4's hall with an organ toccata that never
draws breath.

Written out note by note rather than generated, so a bar can be found and
changed. A note is (pitch, beats); "-" is a rest.
"""

import numpy as np

import instruments as ins
from instruments import hz
from song import Song


def chord(names):
    return [hz(n) for n in names]


def play_line(song, voice, line, start_bar, gain=1.0, pan=0.0, send=0.25, gap=0.92, **kw):
    """A melody: (pitch, beats) pairs from the downbeat of `start_bar`."""
    t = song.at(start_bar)
    for pitch, beats in line:
        dur = song.beats(beats)
        if pitch != "-":
            song.put(voice(hz(pitch), dur * gap, **kw), t, gain=gain, pan=pan, send=send)
        t += dur


def arpeggio(song, voice, tones, bar, beats, step, pattern, gain=1.0, pan=0.0, send=0.3, **kw):
    """`tones` cycled through `pattern` (indices) every `step` beats."""
    t = song.at(bar)
    count = int(round(beats / step))
    for i in range(count):
        f = tones[pattern[i % len(pattern)]]
        song.put(voice(f, song.beats(step) * 0.9, **kw), t + song.beats(step * i), gain=gain, pan=pan, send=send)


# ---------------------------------------------------------------- Act 1

def act1():
    """The moat and the outer wall: wary, cold, moving forward."""
    s = Song(bpm=88, bars=32)
    prog = [
        ("D3 F3 A3", "D2"), ("Bb2 D3 F3", "Bb1"), ("F2 A2 C3", "F1"), ("C3 E3 G3", "C2"),
        ("D3 F3 A3", "D2"), ("G2 Bb2 D3", "G1"), ("Bb2 D3 F3", "Bb1"), ("A2 C#3 E3", "A1"),
    ]
    for rep in range(2):
        for i, (tones, root) in enumerate(prog):
            bar = 1 + rep * 16 + i * 2
            notes = tones.split()
            # Pad under everything.
            s.put(ins.pad(chord(notes), s.beats(8) + 0.4, bright=0.8, seed=bar), s.at(bar), gain=0.22, send=0.5)
            # Bass: root on one, fifth-ish on three.
            for b in range(2):
                s.put(ins.bass(hz(root), s.beats(1.8)), s.at(bar + b), gain=0.55, send=0.1)
                fifth = hz(root) * 1.5
                s.put(ins.bass(fifth, s.beats(0.9)), s.at(bar + b, 2.0), gain=0.4, send=0.1)
                s.put(ins.bass(hz(root), s.beats(0.9)), s.at(bar + b, 3.0), gain=0.4, send=0.1)
            # The pluck: up and down the chord an octave up, eighth notes.
            up = [hz(n) * 2 for n in notes] + [hz(notes[0]) * 4]
            arpeggio(s, ins.pluck, up, bar, 8, 0.5, [0, 1, 2, 3, 2, 1, 0, 1], gain=0.3, pan=-0.25, send=0.35)
    # Drums from bar 5: a kick that walks, a hat that ticks.
    for bar in range(5, 33):
        for beat in (0.0, 1.5, 2.0):
            s.put(ins.kick(0.9 if beat == 0.0 else 0.6), s.at(bar, beat), gain=0.55, send=0.05)
        for e in range(8):
            s.put(ins.hat(0.5 if e % 2 else 0.3, seed=bar * 8 + e), s.at(bar, e * 0.5), gain=0.25, pan=0.3, send=0.05)
        s.put(ins.snare(0.6, seed=bar), s.at(bar, 3.0), gain=0.25, send=0.2)
        if bar % 8 == 0:
            # The toms are pitched, so the fill walks down the bar's chord:
            # C major at bars 8 and 24, A major at 16 and 32.
            fill = ["E3", "C3", "G2"] if bar % 16 == 8 else ["E3", "C#3", "A2"]
            for k, note in enumerate(fill):
                s.put(ins.tom(hz(note), 0.8), s.at(bar, 3.0 + k * 0.33), gain=0.45, send=0.2)
    melody = [
        ("A4", 1.5), ("G4", 0.5), ("F4", 1), ("E4", 1), ("D4", 3), ("A4", 1),
        ("Bb4", 1.5), ("A4", 0.5), ("G4", 1), ("F4", 1), ("D4", 2), ("F4", 1), ("G4", 1),
        ("A4", 1.5), ("C5", 0.5), ("A4", 1), ("F4", 1), ("G4", 3), ("E4", 1),
        ("E4", 1), ("G4", 1), ("C5", 1), ("Bb4", 1), ("A4", 4),
        ("D5", 1.5), ("C5", 0.5), ("A4", 1), ("F4", 1), ("A4", 2), ("D5", 2),
        ("Bb4", 1.5), ("A4", 0.5), ("G4", 1), ("D4", 1), ("G4", 3), ("A4", 1),
        ("Bb4", 1), ("A4", 1), ("G4", 1), ("F4", 1), ("E4", 2), ("G4", 2),
        ("A4", 1.5), ("C#5", 0.5), ("E5", 1), ("C#5", 1), ("A4", 4),
    ]
    play_line(s, ins.lead, melody, 17, gain=0.32, pan=0.15, send=0.35, width=0.4, cutoff=2200.0)
    # The same tune an octave down on a softer voice, bars 1 to 16, half the notes.
    sparse = [(p if i % 2 == 0 else "-", b) for i, (p, b) in enumerate(melody)]
    play_line(s, ins.pluck, [(p[:-1] + str(int(p[-1]) - 1) if p != "-" else p, b) for p, b in sparse], 1, gain=0.22, pan=0.3, send=0.5)
    return s.render(room=1.1)


# ---------------------------------------------------------------- Act 2

def act2():
    """The lava caverns: slow, heavy, a forge beating somewhere below."""
    s = Song(bpm=76, bars=24)
    # A drone the whole way: the ground itself.
    total = s.length + 1.0
    s.put(ins.rumble(total, 0.8), 0.0, gain=0.5, send=0.2)
    for bar in range(1, 25, 4):
        s.put(ins.pad(chord(["E2", "B2", "F3"]), s.beats(16) + 0.5, bright=0.6, seed=bar), s.at(bar), gain=0.25, send=0.6)
    riff = [("E2", 0.5), ("E2", 0.5), ("F2", 0.5), ("E2", 0.5), ("E2", 0.5), ("G2", 0.5), ("F2", 0.5), ("E2", 0.5)]
    riff_b = [("E2", 0.5), ("E2", 0.5), ("F2", 0.5), ("E2", 0.5), ("D2", 0.5), ("D2", 0.5), ("C2", 0.5), ("D2", 0.5)]
    for bar in range(1, 25):
        line = riff_b if bar % 4 == 0 else riff
        play_line(s, ins.growl, line, bar, gain=0.4, pan=-0.1, send=0.15, gap=0.8)
    # The forge: a huge boom on one and the and of two, an anvil on four.
    for bar in range(3, 25):
        s.put(ins.timpani(hz("E2"), 1.0), s.at(bar, 0.0), gain=0.6, send=0.35)
        s.put(ins.timpani(hz("E2"), 0.7), s.at(bar, 1.5), gain=0.45, send=0.35)
        if bar % 2 == 0:
            s.put(ins.anvil(0.7, seed=bar), s.at(bar, 3.0), gain=0.22, pan=0.4, send=0.5)
        if bar % 4 == 0:
            # Down the mode with the riff's own turn, D C B A.
            for k, note in enumerate(["D2", "C2", "B1", "A1"]):
                s.put(ins.tom(hz(note), 0.8), s.at(bar, 2.0 + k * 0.5), gain=0.4, send=0.3)
    melody = [
        ("E4", 2), ("F4", 1), ("G4", 1), ("F4", 3), ("E4", 1),
        ("D4", 2), ("E4", 1), ("F4", 1), ("E4", 4),
        ("G4", 2), ("A4", 1), ("Bb4", 1), ("A4", 2), ("G4", 1), ("F4", 1),
        ("G4", 1.5), ("F4", 0.5), ("E4", 1), ("D4", 1), ("E4", 4),
    ]
    play_line(s, ins.choir, melody, 9, gain=0.35, pan=0.1, send=0.6, gap=1.0)
    high = [(p[:-1] + str(int(p[-1]) + 1), b) for p, b in melody]
    play_line(s, ins.brass, melody, 17, gain=0.28, pan=-0.2, send=0.45)
    play_line(s, ins.choir, high, 17, gain=0.22, pan=0.25, send=0.6, gap=1.0)
    return s.render(room=1.4, wet=1.0)


# ---------------------------------------------------------------- Act 3

def act3():
    """The generator: a sequencer that never stops, metal for drums."""
    s = Song(bpm=112, bars=32)
    prog = [("A2", "C3", "E3"), ("F2", "A2", "C3"), ("D2", "F2", "A2"), ("E2", "G#2", "B2")]
    for bar in range(1, 33):
        root, third, fifth = prog[((bar - 1) // 2) % 4]
        tones = [hz(root), hz(root) * 2, hz(fifth), hz(third) * 2]
        # The cutoff breathes over eight bars, so the machine never quite repeats.
        cut = 900.0 + 1400.0 * (0.5 - 0.5 * np.cos(2 * np.pi * ((bar - 1) % 8) / 8.0))
        arpeggio(s, ins.seq, [f * 2 for f in tones], bar, 4, 0.25, [0, 1, 2, 1, 3, 1, 2, 1], gain=0.22, pan=-0.2, send=0.25, cutoff=cut)
        for e in range(8):
            s.put(ins.bass(hz(root), s.beats(0.4)), s.at(bar, e * 0.5), gain=0.38, send=0.05)
        if bar >= 3:
            for beat in range(4):
                s.put(ins.kick(0.8), s.at(bar, beat), gain=0.5, send=0.05)
            for e in range(8):
                if e % 2:
                    s.put(ins.hat(0.6, seed=bar * 8 + e), s.at(bar, e * 0.5), gain=0.25, pan=0.35, send=0.05)
            s.put(ins.clank(0.9, seed=bar), s.at(bar, 1.0), gain=0.32, pan=-0.3, send=0.25)
            s.put(ins.clank(0.9, seed=bar + 99), s.at(bar, 3.0), gain=0.32, pan=0.3, send=0.25)
        if bar % 8 == 0:
            s.put(ins.riser(s.beats(4), 0.6, seed=bar), s.at(bar), gain=0.3, send=0.4)
        if bar % 4 == 1 and bar > 1:
            s.put(ins.anvil(0.8, seed=bar), s.at(bar), gain=0.25, send=0.5)
    pads = [["A3", "C4", "E4"], ["F3", "A3", "C4"], ["D3", "F3", "A3"], ["E3", "G#3", "B3"]]
    for bar in range(1, 33, 2):
        s.put(ins.pad(chord(pads[((bar - 1) // 2) % 4]), s.beats(8), bright=1.2, seed=bar), s.at(bar), gain=0.14, send=0.5)
    melody = [
        ("A4", 0.5), ("C5", 0.5), ("E5", 1), ("D5", 0.5), ("C5", 0.5), ("B4", 1), ("A4", 2), ("E4", 2),
        ("F4", 0.5), ("A4", 0.5), ("C5", 1), ("B4", 0.5), ("A4", 0.5), ("G4", 1), ("A4", 3), ("-", 1),
        ("D5", 1), ("F5", 1), ("E5", 0.5), ("D5", 0.5), ("C5", 1), ("D5", 2), ("A4", 2),
        ("G#4", 1), ("B4", 1), ("D5", 1), ("E5", 1), ("E5", 3), ("-", 1),
    ]
    play_line(s, ins.lead, melody, 17, gain=0.28, pan=0.2, send=0.3, width=0.25, cutoff=3000.0)
    up = [(p[:-1] + str(int(p[-1]) + 1) if p != "-" else p, b) for p, b in melody]
    play_line(s, ins.glass, up, 25, gain=0.18, pan=-0.3, send=0.5)
    return s.render(room=0.9)


# ---------------------------------------------------------------- Act 4

def act4():
    """The Hall of Volta: organ, choir, timpani, and a wizard's patience."""
    s = Song(bpm=80, bars=32)
    prog = [
        (["C3", "Eb3", "G3"], "C2"), (["Ab2", "C3", "Eb3"], "Ab1"),
        (["F2", "Ab2", "C3"], "F1"), (["G2", "B2", "D3"], "G1"),
        (["C3", "Eb3", "G3"], "C2"), (["Eb3", "G3", "Bb3"], "Eb2"),
        (["F2", "Ab2", "C3"], "F1"), (["G2", "B2", "D3"], "G1"),
    ]
    for rep in range(2):
        for i, (tones, root) in enumerate(prog):
            bar = 1 + rep * 16 + i * 2
            dur = s.beats(8)
            for f in chord(tones):
                s.put(ins.organ(f, dur * 0.98), s.at(bar), gain=0.16, send=0.55)
            s.put(ins.organ(hz(root), dur * 0.98), s.at(bar), gain=0.22, send=0.4)
            s.put(ins.choir(hz(tones[0]) * 2, dur, seed=bar), s.at(bar), gain=0.16, pan=-0.3, send=0.7)
            s.put(ins.choir(hz(tones[2]) * 2, dur, seed=bar + 50), s.at(bar), gain=0.13, pan=0.3, send=0.7)
            s.put(ins.timpani(hz(root) * 2, 1.0), s.at(bar), gain=0.55, send=0.4)
            if i % 2 == 1:
                for k in range(6):
                    s.put(ins.timpani(hz(root) * 2, 0.35 + 0.1 * k), s.at(bar + 1, 2.5 + k * 0.25), gain=0.35, send=0.4)
    bell_motif = [("G5", 1), ("Eb5", 1), ("C5", 2)]
    for bar in range(1, 33, 4):
        play_line(s, ins.bell, bell_motif, bar, gain=0.16, pan=0.35, send=0.6)
    melody = [
        ("C5", 2), ("Eb5", 1), ("D5", 1), ("C5", 1), ("G4", 3),
        ("Ab4", 1.5), ("Bb4", 0.5), ("C5", 1), ("Eb5", 1), ("D5", 4),
        ("F5", 2), ("Eb5", 1), ("D5", 1), ("C5", 2), ("Ab4", 2),
        ("B4", 1.5), ("C5", 0.5), ("D5", 1), ("F5", 1), ("G5", 4),
        ("G5", 2), ("F5", 1), ("Eb5", 1), ("D5", 1), ("Bb4", 3),
        ("Eb5", 1.5), ("D5", 0.5), ("C5", 1), ("Bb4", 1), ("C5", 4),
        ("Ab5", 2), ("G5", 1), ("F5", 1), ("Eb5", 2), ("C5", 2),
        ("D5", 1.5), ("Eb5", 0.5), ("F5", 1), ("D5", 1), ("C5", 4),
    ]
    play_line(s, ins.brass, melody, 17, gain=0.3, pan=0.0, send=0.45)
    return s.render(room=1.5, wet=1.0)


# ---------------------------------------------------------------- The flight

def flight():
    """Out on the dragon: the one major key, the one running beat."""
    s = Song(bpm=132, bars=16)
    prog = [
        (["Eb3", "G3", "Bb3"], "Eb2"), (["Bb2", "D3", "F3"], "Bb1"),
        (["C3", "Eb3", "G3"], "C2"), (["Ab2", "C3", "Eb3"], "Ab1"),
        (["Eb3", "G3", "Bb3"], "Eb2"), (["Bb2", "D3", "F3"], "Bb1"),
        (["Ab2", "C3", "Eb3"], "Ab1"), (["Bb2", "D3", "F3"], "Bb1"),
    ]
    for rep in range(2):
        for i, (tones, root) in enumerate(prog):
            bar = 1 + rep * 8 + i
            fs = chord(tones)
            s.put(ins.pad(fs, s.beats(4) + 0.2, bright=1.4, seed=bar), s.at(bar), gain=0.18, send=0.4)
            arpeggio(s, ins.pluck, [f * 2 for f in fs] + [fs[0] * 4], bar, 4, 0.25, [0, 1, 2, 3, 2, 1, 2, 3], gain=0.22, pan=-0.3, send=0.3)
            for e in range(8):
                s.put(ins.bass(hz(root), s.beats(0.45)), s.at(bar, e * 0.5), gain=0.4, send=0.05)
            for beat in range(4):
                s.put(ins.kick(0.9), s.at(bar, beat), gain=0.5, send=0.05)
                s.put(ins.hat(0.6, seed=bar * 4 + beat), s.at(bar, beat + 0.5), gain=0.25, pan=0.3, send=0.05)
            s.put(ins.snare(0.9, seed=bar), s.at(bar, 1.0), gain=0.35, send=0.25)
            s.put(ins.snare(0.9, seed=bar + 31), s.at(bar, 3.0), gain=0.35, send=0.25)
    melody = [
        ("Eb5", 1), ("G5", 1), ("Bb5", 2), ("Ab5", 1), ("G5", 1), ("F5", 2),
        ("G5", 1.5), ("F5", 0.5), ("Eb5", 1), ("C5", 1), ("Eb5", 4),
        ("G5", 1), ("Bb5", 1), ("Eb6", 2), ("D6", 1), ("C6", 1), ("Bb5", 2),
        ("C6", 1), ("Bb5", 1), ("Ab5", 1), ("G5", 1), ("F5", 4),
    ]
    play_line(s, ins.brass, melody, 1, gain=0.3, pan=0.1, send=0.35)
    play_line(s, ins.lead, melody, 9, gain=0.26, pan=0.15, send=0.35, width=0.35)
    harmony = [(p[:-1] + str(int(p[-1]) - 1), b) for p, b in melody]
    play_line(s, ins.brass, harmony, 9, gain=0.18, pan=-0.2, send=0.35)
    return s.render(room=1.0)


# ---------------------------------------------------------------- The dragon

def dragon():
    """Act 2's lair: the caverns' riff at a gallop, a roar on the tritone."""
    s = Song(bpm=100, bars=24)
    total = s.length + 1.0
    s.put(ins.rumble(total, 1.0, seed=21), 0.0, gain=0.55, send=0.2)
    riff = [("E2", 0.5), ("E2", 0.25), ("E2", 0.25), ("F2", 0.5), ("E2", 0.5),
            ("E2", 0.5), ("E2", 0.25), ("E2", 0.25), ("G2", 0.5), ("F2", 0.5)]
    riff_roar = [("E2", 0.5), ("E2", 0.25), ("E2", 0.25), ("F2", 0.5), ("E2", 0.5),
                 ("Bb1", 1.0), ("A1", 0.5), ("Bb1", 0.5)]
    chords = [["E3", "G3", "B3"], ["F3", "A3", "C4"], ["E3", "G3", "B3"], ["D3", "F3", "A3"]]
    for bar in range(1, 25):
        play_line(s, ins.growl, riff_roar if bar % 4 == 0 else riff, bar, gain=0.42, pan=-0.1, send=0.12, gap=0.85)
        # The gallop: a boom on one and three, toms running into each.
        s.put(ins.timpani(hz("E2"), 1.0), s.at(bar, 0.0), gain=0.6, send=0.3)
        s.put(ins.timpani(hz("E2"), 0.8), s.at(bar, 2.0), gain=0.5, send=0.3)
        for beat in (0.75, 1.5, 2.75, 3.5):
            s.put(ins.tom(hz("E2"), 0.7), s.at(bar, beat), gain=0.32, send=0.2)
        # The forge, now a backbeat.
        s.put(ins.anvil(0.8, seed=bar), s.at(bar, 1.0), gain=0.18, pan=0.35, send=0.4)
        s.put(ins.snare(0.8, seed=bar), s.at(bar, 3.0), gain=0.3, send=0.25)
        # Brass stabs on the chord, the last one pushed ahead of the bar.
        tones = chords[(bar - 1) % 4]
        if bar > 4:
            for f in chord(tones):
                s.put(ins.brass(f, s.beats(0.4)), s.at(bar, 0.0), gain=0.14, pan=0.2, send=0.3)
                s.put(ins.brass(f, s.beats(0.4)), s.at(bar, 3.5), gain=0.12, pan=0.2, send=0.3)
        if bar % 8 == 0:
            # The toms are pitched, so the fill walks down the mode.
            for k, note in enumerate(["B2", "A2", "G2", "F2", "E2", "D2", "C2", "B1"]):
                s.put(ins.tom(hz(note), 0.6 + 0.05 * k), s.at(bar, 2.0 + k * 0.25), gain=0.4, send=0.25)
            s.put(ins.riser(s.beats(2), 0.5, seed=bar), s.at(bar, 2.0), gain=0.25, send=0.4)
    for bar in range(1, 25, 4):
        s.put(ins.pad(chord(["E2", "B2", "F3"]), s.beats(16) + 0.5, bright=0.7, seed=bar), s.at(bar), gain=0.2, send=0.6)
    # The roar: up a tritone and falling back, in the brass and the choir.
    roar = [("E4", 1), ("Bb4", 2), ("A4", 0.5), ("G4", 0.5), ("F4", 2), ("E4", 2)]
    for bar in (5, 13, 21):
        play_line(s, ins.brass, roar, bar, gain=0.3, pan=0.0, send=0.4)
    # Act 2's melody, driven: the choir carries it through the middle.
    melody = [
        ("E4", 1), ("F4", 0.5), ("G4", 0.5), ("F4", 1.5), ("E4", 0.5),
        ("D4", 1), ("E4", 0.5), ("F4", 0.5), ("E4", 2),
        ("G4", 1), ("A4", 0.5), ("Bb4", 0.5), ("A4", 1), ("G4", 0.5), ("F4", 0.5),
        ("G4", 1), ("F4", 0.5), ("E4", 0.5), ("D4", 0.5), ("F4", 0.5), ("E4", 1),
    ]
    play_line(s, ins.choir, melody, 9, gain=0.3, pan=0.15, send=0.55, gap=1.0)
    play_line(s, ins.choir, melody, 11, gain=0.3, pan=-0.15, send=0.55, gap=1.0)
    high = [(p[:-1] + str(int(p[-1]) + 1), b) for p, b in melody]
    play_line(s, ins.brass, melody, 17, gain=0.24, pan=-0.2, send=0.4)
    play_line(s, ins.choir, high, 17, gain=0.2, pan=0.25, send=0.6, gap=1.0)
    play_line(s, ins.brass, melody, 19, gain=0.24, pan=-0.2, send=0.4)
    play_line(s, ins.choir, high, 19, gain=0.2, pan=0.25, send=0.6, gap=1.0)
    return s.render(room=1.3, wet=1.0)


# ---------------------------------------------------------------- The generator

def generator():
    """Act 3's boss: the works' sequencer gone haywire, an alarm a semitone
    wide over it, and the floor pumping."""
    s = Song(bpm=128, bars=32)
    prog = [
        ("A2", "C3", "E3"), ("A2", "C3", "E3"), ("Bb2", "D3", "F3"), ("A2", "C3", "E3"),
        ("F2", "A2", "C3"), ("G2", "B2", "D3"), ("E2", "G#2", "B2"), ("E2", "G#2", "B2"),
    ]
    for bar in range(1, 33):
        root, third, fifth = prog[(bar - 1) % 8]
        tones = [hz(root) * 2, hz(fifth) * 2, hz(root) * 4, hz(third) * 4, hz(fifth) * 4]
        cut = 1100.0 + 1900.0 * (0.5 - 0.5 * np.cos(2 * np.pi * ((bar - 1) % 4) / 4.0))
        arpeggio(s, ins.seq, tones, bar, 4, 0.25, [0, 2, 1, 3, 2, 4, 3, 2, 0, 2, 4, 3, 1, 2, 3, 4], gain=0.2, pan=-0.25, send=0.2, cutoff=cut, res=4.0)
        # The floor: octaves pumping on the eighths.
        for e in range(8):
            f = hz(root) * (2.0 if e % 2 else 1.0)
            s.put(ins.bass(f, s.beats(0.35)), s.at(bar, e * 0.5), gain=0.36, send=0.04)
        for beat in range(4):
            s.put(ins.kick(0.9), s.at(bar, beat), gain=0.52, send=0.04)
        for k in range(16):
            if k % 4 == 2:
                s.put(ins.hat(0.7, open_=True, seed=bar * 16 + k), s.at(bar, k * 0.25), gain=0.18, pan=0.3, send=0.05)
            elif k % 2:
                s.put(ins.hat(0.5, seed=bar * 16 + k), s.at(bar, k * 0.25), gain=0.16, pan=0.35, send=0.03)
        s.put(ins.clank(1.0, seed=bar), s.at(bar, 1.0), gain=0.34, pan=-0.25, send=0.2)
        s.put(ins.clank(1.0, seed=bar + 77), s.at(bar, 3.0), gain=0.34, pan=0.25, send=0.2)
        if bar % 2 == 0:
            s.put(ins.clank(0.6, seed=bar + 150), s.at(bar, 3.75), gain=0.22, pan=0.0, send=0.2)
        if bar % 8 == 0:
            s.put(ins.riser(s.beats(4), 0.7, seed=bar), s.at(bar), gain=0.3, send=0.35)
        if bar % 8 == 1:
            s.put(ins.anvil(1.0, seed=bar), s.at(bar), gain=0.28, send=0.5)
    # The alarm: a semitone, high and thin, through the middle sixteen.
    for bar in range(9, 25):
        for half in range(2):
            s.put(ins.glass(hz("E6"), s.beats(0.9)), s.at(bar, half * 2.0), gain=0.1, pan=0.4, send=0.35)
            s.put(ins.glass(hz("F6"), s.beats(0.9)), s.at(bar, half * 2.0 + 1.0), gain=0.1, pan=0.4, send=0.35)
    pads = [["A3", "C4", "E4"], ["A3", "C4", "E4"], ["Bb3", "D4", "F4"], ["A3", "C4", "E4"],
            ["F3", "A3", "C4"], ["G3", "B3", "D4"], ["E3", "G#3", "B3"], ["E3", "G#3", "B3"]]
    for bar in range(1, 33):
        s.put(ins.pad(chord(pads[(bar - 1) % 8]), s.beats(4), bright=1.4, seed=bar), s.at(bar), gain=0.1, send=0.5)
    melody = [
        ("E5", 0.5), ("E5", 0.5), ("A5", 1), ("G5", 0.5), ("F5", 0.5), ("E5", 1),
        ("F5", 0.5), ("F5", 0.5), ("Bb5", 1), ("A5", 0.5), ("G5", 0.5), ("F5", 1),
        ("E5", 0.5), ("D5", 0.5), ("C5", 0.5), ("D5", 0.5), ("E5", 2),
        ("C5", 0.5), ("D5", 0.5), ("E5", 0.5), ("F5", 0.5), ("D5", 1), ("C5", 1),
        ("A4", 0.5), ("C5", 0.5), ("F5", 1), ("E5", 0.5), ("D5", 0.5), ("C5", 1),
        ("B4", 0.5), ("D5", 0.5), ("G5", 1), ("F5", 0.5), ("E5", 0.5), ("D5", 1),
        ("E5", 1), ("G#5", 1), ("B5", 1), ("E6", 1),
        ("D6", 1), ("B5", 1), ("G#5", 1), ("E5", 1),
    ]
    play_line(s, ins.lead, melody, 17, gain=0.26, pan=0.2, send=0.3, width=0.3, cutoff=3200.0)
    play_line(s, ins.lead, melody, 25, gain=0.26, pan=0.2, send=0.3, width=0.3, cutoff=3200.0)
    low = [(p[:-1] + str(int(p[-1]) - 1), b) for p, b in melody]
    play_line(s, ins.brass, low, 25, gain=0.18, pan=-0.2, send=0.3)
    return s.render(room=0.8)


# ---------------------------------------------------------------- Volta

def volta():
    """The throne: Act 4's hall with an organ toccata that never draws breath,
    the choir full, the bell's three notes made into Volta's theme."""
    s = Song(bpm=92, bars=32)
    prog = [
        (["C3", "Eb3", "G3"], "C2"), (["C3", "Eb3", "G3"], "C2"),
        (["Ab2", "C3", "Eb3"], "Ab1"), (["F2", "Ab2", "C3"], "F1"),
        (["G2", "B2", "D3"], "G1"), (["G2", "B2", "F3"], "G1"),
        (["C3", "Eb3", "G3"], "C2"), (["Bb2", "D3", "F3"], "Bb1"),
        (["Ab2", "C3", "Eb3"], "Ab1"), (["F2", "Ab2", "C3"], "F1"),
        (["Db3", "F3", "Ab3"], "Db2"), (["G2", "B2", "D3"], "G1"),
        (["C3", "Eb3", "G3"], "C2"), (["Ab2", "C3", "Eb3"], "Ab1"),
        (["G2", "B2", "D3"], "G1"), (["G2", "B2", "F3"], "G1"),
    ]
    for rep in range(2):
        for i, (tones, root) in enumerate(prog):
            bar = 1 + rep * 16 + i
            fs = chord(tones)
            # The toccata: the chord turned over in sixteenths, an octave up,
            # the top note struck like a mordent.
            run = [fs[2] * 2, fs[1] * 2, fs[2] * 2, fs[0] * 2, fs[1] * 2, fs[0] * 2, fs[2], fs[0] * 2]
            arpeggio(s, ins.organ, run, bar, 4, 0.25, list(range(8)), gain=0.13, pan=-0.15, send=0.45)
            for f in fs:
                s.put(ins.organ(f, s.beats(4) * 0.97), s.at(bar), gain=0.1, send=0.55)
            # The pedal: the root in eighths, low.
            for e in range(8):
                s.put(ins.organ(hz(root), s.beats(0.45)), s.at(bar, e * 0.5), gain=0.14 if e % 2 else 0.2, send=0.3)
            s.put(ins.choir(fs[0] * 2, s.beats(4), seed=bar), s.at(bar), gain=0.13, pan=-0.3, send=0.7)
            s.put(ins.choir(fs[2] * 2, s.beats(4), seed=bar + 70), s.at(bar), gain=0.11, pan=0.3, send=0.7)
            # Timpani on one and three, toms answering.
            s.put(ins.timpani(hz(root) * 2, 1.0), s.at(bar, 0.0), gain=0.55, send=0.35)
            s.put(ins.timpani(hz(root) * 2, 0.75), s.at(bar, 2.0), gain=0.42, send=0.35)
            s.put(ins.tom(fs[2] / 2.0, 0.7), s.at(bar, 1.5), gain=0.3, send=0.25)
            s.put(ins.tom(hz(root) * 2.0, 0.7), s.at(bar, 3.5), gain=0.3, send=0.25)
            if i % 4 == 3:
                for k in range(8):
                    s.put(ins.timpani(hz(root) * 2, 0.3 + 0.08 * k), s.at(bar, 2.0 + k * 0.25), gain=0.32, send=0.35)
    # Volta's theme: the bell's falling three, stated and then climbing.
    for bar in range(1, 33, 4):
        play_line(s, ins.bell, [("G5", 1), ("Eb5", 1), ("C5", 2)], bar, gain=0.15, pan=0.35, send=0.6)
    theme = [
        ("G4", 1), ("Eb4", 1), ("C4", 2), ("G4", 1), ("Ab4", 1), ("G4", 2),
        ("Ab4", 1), ("F4", 1), ("C4", 2), ("F4", 1), ("G4", 1), ("Ab4", 2),
        ("G4", 1), ("B4", 1), ("D5", 2), ("F5", 1.5), ("Eb5", 0.5), ("D5", 2),
        ("C5", 1), ("Eb5", 1), ("G5", 2), ("F5", 1), ("D5", 1), ("B4", 2),
    ]
    play_line(s, ins.brass, theme, 9, gain=0.3, pan=0.0, send=0.45)
    high = [(p[:-1] + str(int(p[-1]) + 1), b) for p, b in theme]
    play_line(s, ins.brass, theme, 21, gain=0.24, pan=-0.15, send=0.45)
    play_line(s, ins.choir, high, 21, gain=0.22, pan=0.2, send=0.65, gap=1.0)
    return s.render(room=1.5, wet=1.0)


TRACKS = {
    "act1": act1,
    "act2": act2,
    "act3": act3,
    "act4": act4,
    "flight": flight,
    "dragon": dragon,
    "generator": generator,
    "volta": volta,
}
