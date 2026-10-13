# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 150 lines.

**Updated:** 2026-10-13 · **Phase:** 3 rebuilt, depth before breadth.
**Active milestone:** N1, everything built is placeable (`BUILD_PLAN.md`).
N0 is done; N1 and N2 are built and wait only on Matt (below).
**N1 done-when:** each new level-file entry has a parser test and a bench
that passes walkback, route and scenarios, and Matt has played the benches
(F2) and said which combinations are worth building beats around. Then N2
(it can run alongside), then N3, the outer wall rebuilt from Matt's beat
sheet. R4 and M14 wait until G2 passes on the rebuilt Act 1.

## Where this is

**G2's first answer was "not fun yet"** (Matt, 2026-10-07): too short,
simple, stilted, blocky and linear. A review found the cause is how levels
are made, not the mechanics; Matt adopted its plan and four rulings
(`LEVELS.md`, *Decisions 2026-10-07*). **Act 1 is two levels**: the forest
(`levels/act1_forest.level`, in its own art, background attempt 1
included: `ART.md`, *The forest*) and the outer wall
(`levels/act1_wall.level`, grey-boxed, the one N3 rebuilds). Acts 2 to 4
are still the old one-screen rooms.
**Credits: 285.**

## The next action

**N2, the minimum look, is built.** A grid level's still parts are drawn
once into textures (`LevelBake`); solid interiors fall into the art set's
coloured dark by depth (`TileShape`); open sides get an edge and ground you
walk under a lintel; levels gain `[back]` and `[decor]` grids, the second
written by rule (`tools/dev.sh decorate`, `DecorRules`). Both Act 1 levels
have both; the forest's back grid keeps only earth, since the painting has
trunks of its own. Before and after shots and frame times are in the N2 PR.
F2 now cycles through the M4 benches too. **Next for Claude**: whatever
Matt's answers to 1 to 3 below open; N3 needs the beat sheet.

## Blocked on Matt

1. **Play the N1 benches** (`bench_n1`, `bench_n1_found`, `bench_n1_combos`,
   F2; the top left names the room) and say which combinations are worth
   building beats around. Closes N1.
2. **Look at N2's after shots** (the PR) or play either Act 1 level: is a
   shot natural-looking? That closes N2. The back walls, torches and trunks
   are Claude's placements, easy to move in the level text.
3. **Mark up the outer wall's beat sheet**, Claude's draft at
   `levels/act1_wall.beats` (Matt asked for one, 2026-10-13). Blocks N3.
   Playing today's level 2 once first is cheap evidence of what to keep.
4. **Paint the forest's background, attempt 2**, in Gemini from the prompt in
   `ART.md` (*The forest*), saved to `assets/art_raw/forest_bg_2.*`. Attempt 1
   is in and dimmed; tall levels mirror it into X shapes when zoomed out.
5. **Frame time on a real machine**: `tools/dev.sh frametime`, then with
   `res://scenes/rooms/act1_forest.tscn` and `act1_wall.tscn`: p95 under
   16.7 ms? Blocks R3's frame-rate half.
6. **Older and still open**: R2's final quality (the flame, the sword, the
   doors, the ride); `RoomM7Sheet` consistent in treatment (closes M7); the
   unattended calls from 2026-10-05; M4's dragon pacing; a play log (`user://`,
   #136) when one is to hand. Two rulings wait for N1: faster ladder
   climbing, and a test build that lets you throw mid-somersault (it reopens
   2026-09-28).

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary to `~/godot/godot`
each session. **Opening the project rewrites `project.godot`**: close the
editor, `git diff project.godot`, restore, then pull. **A new `class_name`
script fails every caller until a reimport**: run `tools/dev.sh import`
first. A parse error or a script error mid-test is a test failure now. **Tests
run before the tree is ready**, so nothing needing `get_tree()` can be tested
headless. **Indexing a `const` array of preloaded resources** folds at parse
time and fails to compile: go through a typed variable.

**`*.import` is gitignored**: an import setting set there (a loop flag) holds
on one machine only: loops live in the WAV (`smpl`) or in code, and a fresh
import is the test (#120). **Godot's movie writer is how to see and hear a
real run**: `godot --path . <scene> --write-movie out/f.png --fixed-fps 30
--quit-after N` writes frames and the game's own mix as a WAV. **Only a
plain launch touches the save; `--script` never does.**

**A ladder with nothing at its top makes the hero bob there**, climbing off
and regrabbing, and a jump pressed mid-bob does nothing: a scenario jumps
from a steady grip a little lower. **A missed return falls with its
homeward speed** and lands about 140 px past the hero. **A bat's box is where it can kill you**: put it across the line a throw
takes from outside it, or it cannot be fought. **A scorpion is only a sword
fight in a tunnel**: the throw is flat at 18 px and it is 34 px tall, so a
step before it means the top or nothing, and in the open you jump it. **Walk-back's "exit out of
reach" means the level is blocked**: its drawing is full height now.

**Sprite Fusion**: `style-reference` ignores `size`, `animate` starts on the
input's pose, frames can boil (filmstrip first), an SSL EOF charges nothing.
**A test can pass while a texture is missing**: shoot the room after art.
**A grid level's look is baked at load**: a change to its art or its text
shows only on a fresh load, and headless draws nothing, so shoot it.

## Settled, do not relitigate

**Pixel art.** **Straight sword, asymmetric hilt.** **M5 final quality.**
**Moving jumps are somersaults; dives cost a recovery pause** (2026-09-28).
**M4:** contact with any enemy kills; the dragon dies only to RECALLING.
**G1:** passed. **Enemies killed since the brazier come back at a respawn**
(Matt, 2026-10-13; `SPEC.md`, *Difficulty*). **N0:** passed (Matt,
2026-10-13: the camera feels good; *How a level is built* approved, open to
change). **`LEVELS.md`'s twelve questions** (Matt, 2026-09-28).
**R1's play half** (Matt, 2026-10-07): the bailey switch and the dragon read.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `assets/audio/README.md` sound ·
`CLAUDE.md` how to work here · `README.md` running it · `BACKLOG.md` raised
and not judged · `LEVELS.md` Matt's level vision, decided.
