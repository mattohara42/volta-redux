# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 150 lines.

**Updated:** 2026-10-08 · **Phase:** 3 rebuilt, depth before breadth.
**Active milestone:** N0, fixes and the method (`BUILD_PLAN.md`).
**N0 done-when:** Matt has approved the wording of `SPEC.md`'s new *How a
level is built*, the fixes are shot before and after from a real build, and
the camera's feel is Matt's to judge by playing. Then N1 and N2 (they can run
side by side), then N3, the outer wall rebuilt from Matt's beat sheet. R4 and
M14 wait until G2 passes on the rebuilt Act 1.

## Where this is

**G2's first answer was "not fun yet"** (Matt, 2026-10-07): too short,
simple, stilted, blocky and linear. A review found the cause is how levels
are made, not the mechanics; Matt adopted its plan and four rulings
(`LEVELS.md`, *Decisions 2026-10-07*). **Act 1 is two levels**: the forest
(`levels/act1_forest.level`, in its own art bar the background: `ART.md`,
*The forest*) and the outer wall (`levels/act1_wall.level`, grey-boxed, the
one N3 rebuilds). Acts 2 to 4 are still the old one-screen rooms.
**Credits: 285.**

## The next action

**N0's six fixes are in** (shot before and after; the PR has the pictures),
and *How a level is built* is drafted in `SPEC.md`, marked as a draft, with
the beat-sheet format. N0 now waits on Matt (below). Next for Claude: N1,
which can start alongside.

## Blocked on Matt

1. **Approve *How a level is built*** (`SPEC.md`), or mark it up. Blocks N0.
2. **Play the look-ahead camera** (`config/camera.tres`: 64 px ahead, swings
   at 160 px/s, holds below 20 px/s so a turn on the spot to throw does not
   move the view). Its feel closes N0. A look down while falling is not built.
3. **Sketch the outer wall's beat sheet** in that format. Blocks N3. Playing
   today's level 2 once first is cheap evidence of what to keep.
4. **Paint the forest's background** in Gemini from the prompt in `ART.md`
   (*The forest*), saved to `assets/art_raw/forest_bg.*`.
5. **Frame time on a real machine**: `tools/dev.sh frametime`, then with
   `res://scenes/rooms/act1_forest.tscn` and `act1_wall.tscn`: p95 under
   16.7 ms? Blocks R3's frame-rate half.
6. **Older and still open**: R2's final quality (the flame, the sword, the
   doors, the ride); `RoomM7Sheet` consistent in treatment (closes M7); the
   unattended calls from 2026-10-05; M4's dragon pacing; a play log (`user://`,
   #136) when one is to hand. Three rulings wait for N1: does a found fourth
   sword survive a death, faster ladder climbing, and a test build that lets
   you throw mid-somersault (it reopens 2026-09-28).

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
takes from outside it, or it cannot be fought. **A scorpion is only a sword
fight in a tunnel**: the throw is flat at 18 px and it is 34 px tall, so a
step before it means the top or nothing, and in the open you jump it. **Walk-back's "exit out of
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
