# Audio

Every sound in the game is rendered from code by `tools/synth/` (Python,
numpy and scipy, plus ffmpeg for the Ogg). There are no samples and no
recordings, the same way the lava and the arcs are shaders rather than
drawings (`CLAUDE.md`: atmosphere is code).

```
python3 tools/synth/render.py sfx              # assets/audio/sfx/*.wav
python3 tools/synth/render.py music            # assets/audio/music/*.ogg
python3 tools/synth/render.py sfx gem --overwrite
```

An existing file is left alone unless `--overwrite` is passed. Rendering is
deterministic, every noise source seeded, so an overwritten file only differs
when its recipe did.

## Where each one is decided

| what | recipe | wired in |
|---|---|---|
| the sword's eight (throw, catch, embed, recall, the fly loop, break, clatter, fry) | `tools/synth/sfx.py` | `config/sword.tres` |
| everything else that makes a noise | `tools/synth/sfx.py` | `config/audio.tres` |
| how loud each one peaks | `sfx.LEVELS` | rendered in |
| the two buses' levels, the death muffle, the crossfade | | `config/audio.tres` |
| each act's loop | `tools/synth/music.py` | `config/actN.tres` (`music`) |
| each boss's loop, played in its room in place of the act's | `tools/synth/music.py` | `config/actN.tres` (`boss_room`, `boss_music`) |
| each act's ambience bed (wind, the mountain, the works, rain) | `tools/synth/sfx.py` | `config/actN.tres` (`ambience`) |
| loops on things (a lava pit's roar, an arc's buzz), heard only near them | `tools/synth/sfx.py` | `config/audio.tres` |
| the ride out's loop | `tools/synth/music.py` | `Act4Flight.FLIGHT_MUSIC` |

**The sword's four state sounds are built to differ in every way an ear sorts
sounds** (`BUILD_PLAN.md` M15): the throw is noise sweeping up and away, the
catch a short bright ring, the embed a low knock with the blade humming after
it, the recall a rising shimmer. The fly loop plays for as long as a sword is
in the air and the engine pans it with the sword, which is what lets you know
where your sword is with the screen dimmed.

## The music

One loop per act, one for each of the three bosses and one for the flight,
each written out note by note in `tools/synth/music.py` (a bar can be found
and changed) and played by the `Audio` autoload, which carries a track across
the rooms of its act, crossfades into a boss's loop at the boss's door, and
fades out under an act's card.

| track | key, tempo | what it is doing |
|---|---|---|
| Act 1 | D minor, 88 | a wary march along a wall at night: plucked, restrained, a melody arriving halfway |
| Act 2 | E Phrygian, 76 | the caverns: a growling riff that never lets up, a forge beating, a choir |
| Act 3 | A minor, 112 | the generator: a sequencer that never stops, metal for drums |
| Act 4 | C minor, 80 | Volta's hall: organ, choir, timpani, a bell |
| the flight | E flat major, 132 | the only major key in the game, and the only running beat |
| the dragon (Act 2's lair) | E Phrygian, 100 | Act 2's riff at a gallop, toms running into each beat, a roar up the tritone in the brass |
| the generator (Act 3's last room) | A minor, 128 | Act 3's sequencer in sixteenths with a flat second in it, the floor pumping in octaves, a semitone alarm through the middle |
| Volta (Act 4's throne) | C minor, 92 | an organ toccata that never draws breath, the choir full, the bell's three notes made into his theme |

Each loop is rendered with its reverb tail folded back onto its start, so the
join is seamless, and every loop is brought to the same loudness.

**Nobody has listened to these yet.** They were designed and checked by
drawing them (`tools/synth/spectro.py` draws the waveform over a
spectrogram) and by measuring them (`tools/synth/chroma.py` checks a rendered
track's chords against its score), not by ear. Every recipe is a short
function and every level is one number, so fixing one that sounds wrong is a
small edit and a re-render.
