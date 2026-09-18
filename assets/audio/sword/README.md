# Placeholder sword sounds

Four short synthesized tones, generated once by a script kept in this
session's history rather than in `tools/` (this project has no audio
pipeline yet). Each is a pure sine sweep or pair of tones written directly
to a WAV file with Python's stdlib `wave` module, no samples, no synth
plugin, no external asset.

- `throw.wav`: a descending sweep, 900 to 280 Hz over 90 ms.
- `catch.wav`: a steady bright tone at 1200 Hz, 80 ms.
- `embed.wav`: two low tones in sequence, around 150 and 110 Hz, 120 ms total.
- `recall.wav`: a rising sweep, 400 to 1000 Hz over 150 ms, the mirror of throw.

BUILD_PLAN.md M15 replaces these with real sound design ("the throw, the
catch, the embed and the recall need four distinguishable sounds"). Until
then these hold the wiring in place: `config/sword.tres` points to them,
so M15 is an asset swap in one file rather than a new signal path.
