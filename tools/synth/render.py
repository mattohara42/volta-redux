#!/usr/bin/env python3
"""Renders the game's sound effects and music from code into `assets/audio/`.

    python3 tools/synth/render.py sfx            every sound effect, as WAV
    python3 tools/synth/render.py music          every act's loop, as Ogg
    python3 tools/synth/render.py sfx gem kill   just those
    python3 tools/synth/render.py ... --overwrite

CLAUDE.md: in a pipeline tool, the destructive mode is the flag. A file that
already exists is left alone, and the run says so, unless `--overwrite` is
given. Re-rendering is deterministic (every noise source is seeded), so an
overwritten file only differs if a recipe did.

Needs numpy and scipy (`tools/requirements.txt`) and ffmpeg for the Ogg.
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dsp import normalise, write_ogg, write_wav  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")


def _writable(path, overwrite):
    if os.path.exists(path) and not overwrite:
        print(f"skip  {os.path.relpath(path, ROOT)} exists (pass --overwrite to replace it)")
        return False
    return True


def render_sfx(names, overwrite):
    import sfx
    os.makedirs(SFX_DIR, exist_ok=True)
    for name in names or list(sfx.RECIPES):
        path = os.path.join(SFX_DIR, f"{name}.wav")
        if not _writable(path, overwrite):
            continue
        samples = sfx.RECIPES[name]()
        write_wav(path, normalise(samples, sfx.LEVELS.get(name, 0.8)), loop=name in sfx.LOOPS)
        print(f"wrote {os.path.relpath(path, ROOT)} ({samples.shape[-1] / 44100:.2f} s)")


def render_music(names, overwrite):
    import music
    os.makedirs(MUSIC_DIR, exist_ok=True)
    for name in names or list(music.TRACKS):
        path = os.path.join(MUSIC_DIR, f"{name}.ogg")
        if not _writable(path, overwrite):
            continue
        samples = music.TRACKS[name]()
        write_ogg(path, samples)
        print(f"wrote {os.path.relpath(path, ROOT)} ({samples.shape[-1] / 44100:.1f} s)")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("what", choices=["sfx", "music"])
    parser.add_argument("names", nargs="*")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    if args.what == "sfx":
        render_sfx(args.names, args.overwrite)
    else:
        render_music(args.names, args.overwrite)


if __name__ == "__main__":
    main()
