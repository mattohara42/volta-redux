# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-10-06 · **Phase:** 3, the game · **Active:** M14, the pass,
waiting on Matt's answers to the playtest plan. **M14 done when:** three full playthroughs with no
note worth writing down (`BUILD_PLAN.md`). M13's done-when (the game can be
completed from a new save) is met in CI by `tools/dev.sh route`.

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

**Matt and the kids played it through** (2026-10-06). They had fun; the music,
movement and puzzles landed. The notes, and a five-stage plan merged with the
old backlog, are at the top of `BACKLOG.md`. The headline: levels about ten
times bigger and five to ten floors tall, which reopens `SPEC.md`'s ~18 rooms.
**Nothing is built until Matt answers `BACKLOG.md` → Decisions requested.**
Stage 1 (chest rule, walk-back checker, the switch, the cage) can start as
soon as decision 5 and the cage change get a yes.

## Blocked on Matt

1. **`BACKLOG.md` → Decisions requested**, seven of them: what a level is,
   the walk-back rule, the level format, G2 before Acts 2 to 4, the chest
   rule, the sword economy, and rewriting `SPEC.md`/`LEVELS.md`/`BUILD_PLAN.md`.
2. **The play log** from this playthrough (`user://`, #136), if it was kept.
3. **Older and still open**: `RoomM7Sheet` consistent in treatment (closes
   M7); the unattended calls from 2026-10-05 (death lines by cause, the save
   per act, ambient levels); M4's dragon pacing and dormant-scorpion gap; the
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
