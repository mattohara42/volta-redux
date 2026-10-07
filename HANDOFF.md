# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-10-07 · **Phase:** 3 rebuilt, the scale · **Active:** G2,
Act 1 at full size. **G2 done when:** it is fun at that size and the cost of
one level, in sessions and credits, is written down (`BUILD_PLAN.md`). R1, R2
and R3 are built; only Matt's eye (and his GPU, for R3) is left on each. M14
is paused until R4.

## Where this is

**All four acts are built, connected and dressed** (light, far layers,
particles, all sound and music from code, act cards, pause menu, saves at
braziers). M15 is built ahead of M14 (`BUILD_PLAN.md`). **Credits: 405**
after R2. Enemies wait on `RoomM7Sheet`.

## The next action

**G2, level 2: the outer wall to the castle gate**, folding in today's wall,
bailey and gate rooms as sections, grey-boxed like level 1. Level 1, the
forest and the moat, is built (`levels/act1_forest.level`, `BACKLOG.md` has
what to watch) and replaces the bank as Act 1's first room. Cost so far: one
session for the stump warp and level 1, no credits.

## Blocked on Matt

1. **Play level 1**, `tools/dev.sh play` from a new game: is the forest fun
   at this size, is the high road found, do the stumps read? Grey-box, so
   judge the layout, not the look.
2. **R2, final quality?** The flame, the sword, the four doors and the ride
   (`BACKLOG.md`).
3. **Frame time on a real machine**: `tools/dev.sh frametime`, the tall test
   level, then `tools/dev.sh frametime res://scenes/rooms/act1_forest.tscn`.
   Is p95 under 16.7 ms? That closes R3's frame-rate half.
4. **R1's play half**: whether a kid finds the bailey's new switch unaided, and
   whether the caged dragon now reads as one (`BACKLOG.md` has what to watch).
5. **The play log** from this playthrough (`user://`, #136), if it was kept.
6. **Older and still open**: `RoomM7Sheet` consistent in treatment (closes
   M7); the unattended calls from 2026-10-05 (death lines by cause, ambient
   levels; the save is now at braziers); M4's dragon pacing and dormant-scorpion gap; the
   painted acts' seams in play.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary to `~/godot/godot`
each session. **Opening the project rewrites `project.godot`**: close the
editor, `git diff project.godot`, restore, then pull. **A new `class_name`
script fails every caller until a reimport, and the test runner still exits 0
with the parse error printed**: read its output, not its exit code. **Tests
run before the tree is ready**, so nothing needing `get_tree()` can be tested
headless. **Indexing a `const` array of preloaded resources** folds at parse
time and fails to compile: go through a typed variable.

**`*.import` is gitignored**: an import setting set there (a loop flag) holds
on one machine only: loops live in the WAV (`smpl`) or in code, and a fresh
import is the test (#120). **Godot's movie writer is how to see and hear a
real run**: `godot --path . <scene> --write-movie out/f.png --fixed-fps 30
--quit-after N` writes frames and the game's own mix as a WAV. **Only a
plain launch touches the save; `--script` never does.**

**Sprite Fusion**: `style-reference` ignores `size`, `animate` starts on the
input's pose, frames can boil (filmstrip first), an SSL EOF charges nothing.
**A test can pass while a texture is missing**: shoot the room after art.

## Settled, do not relitigate

**Pixel art.** **Straight sword, asymmetric hilt.** **M5 final quality.**
**Moving jumps are somersaults; dives cost a recovery pause** (2026-09-28).
**M4:** contact with any enemy kills; the dragon dies only to RECALLING.
**G1:** passed. **`LEVELS.md`'s twelve questions** (Matt, 2026-09-28).

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `assets/audio/README.md` sound ·
`CLAUDE.md` how to work here · `README.md` running it · `BACKLOG.md` raised
and not judged · `LEVELS.md` Matt's level vision, decided.
