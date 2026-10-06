# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-10-06 · **Phase:** 3 rebuilt, the scale · **Active:** R1,
what the playtest hit. **R1 done when:** the chest rule and the walk-back
checker have tests, the checker passes on every room that survives the
rebuild, and the bailey's switch and cage are shot from a real build
(`BUILD_PLAN.md`). M14 is paused until R4.

## Where this is

**All four acts are built and connected, and an overnight pass (Matt's
request, PRs #116 to #133) dressed them**: light and dark (`LightField`,
rim light), far layers (`Backdrop`), particles (`Burst`), every sound and
all act and boss music from code (`assets/audio/README.md`), death lines by
cause (`SPEC.md`), act cards, an opening card, a pause menu and a save per
act. M15 is built ahead of M14; three M16 pieces are pulled forward
(`BUILD_PLAN.md`). **Credits: 510**, none spent. Enemies wait on
`RoomM7Sheet`.

## The next action

**R1 continues with the switch and the cage**: the first sword switch taught in
front of the player with its gate in view and a visible link, and the caged
dragon seen whole, away from it (`BACKLOG.md` → *Decided* has the notes). Done
in R1: the chest rule, and the walk-back check, now in CI with every room
passing. Matt's 2026-10-06 decisions are in `LEVELS.md`.

## Blocked on Matt

1. **Whether a kid finds the new switch unaided**, once R1 lands.
2. **The play log** from this playthrough (`user://`, #136), if it was kept.
3. **Older and still open**: `RoomM7Sheet` consistent in treatment (closes
   M7); the unattended calls from 2026-10-05 (death lines by cause, ambient
   levels; the save per act becomes a save at braziers in R3); M4's dragon pacing and dormant-scorpion gap; the
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
