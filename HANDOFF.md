# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 150 lines.

**Updated:** 2026-10-07 · **Phase:** 3 rebuilt, the scale · **Active:** G2,
Act 1 at full size. **G2 done when:** it is fun at that size and the cost of
one level, in sessions and credits, is written down (`BUILD_PLAN.md`). Cost
is written down (one session, no credits, per level: `BACKLOG.md`); fun is
Matt's to answer. M14 is paused until R4.

## Where this is

**Act 1 is two grey-boxed levels**: the forest and the moat
(`levels/act1_forest.level`, played and it plays well), then the outer wall
to the castle gate (`levels/act1_wall.level`, `Act1Wall`), which replaced
the wall, bailey and gate rooms. Acts 2 to 4 are built, connected and
dressed at the old room size. **Credits: 405.**

## The next action

**Matt plays Act 1 end to end** from a new game. Fun: G2 passes and R4
starts. Not fun: the fix goes in `SPEC.md` first.

## Blocked on Matt

1. **Play level 2** (after the forest, from a new game): fun at this size?
   High road's bats fair? Plinth switch found? Judge layout, not look.
   Blocks G2. `BACKLOG.md` has the rest to watch.
2. **R2, final quality?** The flame, the sword, the four doors and the ride
   (`BACKLOG.md`). Blocks R2.
3. **Frame time on a real machine**: `tools/dev.sh frametime`, then with
   `res://scenes/rooms/act1_forest.tscn` and `act1_wall.tscn`: p95 under
   16.7 ms? Blocks R3's frame-rate half.
4. **Older and still open**: `RoomM7Sheet` consistent in treatment (closes
   M7); the unattended calls from 2026-10-05 (death lines by cause, ambient
   levels); M4's dragon pacing and dormant-scorpion gap; the painted acts'
   seams in play; a play log (`user://`, #136) when one is to hand.

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

**A bat's box is where it can kill you**: put it across the line a throw
takes from outside it, or it cannot be fought. **Walk-back's "exit out of
reach" means the level is blocked**: its drawing is full height now.

**Sprite Fusion**: `style-reference` ignores `size`, `animate` starts on the
input's pose, frames can boil (filmstrip first), an SSL EOF charges nothing.
**A test can pass while a texture is missing**: shoot the room after art.

## Settled, do not relitigate

**Pixel art.** **Straight sword, asymmetric hilt.** **M5 final quality.**
**Moving jumps are somersaults; dives cost a recovery pause** (2026-09-28).
**M4:** contact with any enemy kills; the dragon dies only to RECALLING.
**G1:** passed. **`LEVELS.md`'s twelve questions** (Matt, 2026-09-28).
**R1's play half** (Matt, 2026-10-07): the bailey switch and the dragon read.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `assets/audio/README.md` sound ·
`CLAUDE.md` how to work here · `README.md` running it · `BACKLOG.md` raised
and not judged · `LEVELS.md` Matt's level vision, decided.
