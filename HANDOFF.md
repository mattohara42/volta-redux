# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 150 lines.

**Updated:** 2026-10-25 · **Phase:** 3 rebuilt, depth before breadth.
**Active milestone:** N3, the outer wall rebuilt from a beat sheet
(`BUILD_PLAN.md`). Matt approved the sheet, `levels/act1_wall.beats`, on
2026-10-13. N0 is done; N1 and N2 are built and wait only on Matt's play.
**N3 done-when:** route, walkback, tests and scenarios pass, every beat is
shot where the sheet puts it, and Matt and the kids play Act 1 from a new
game and say it is better (G2 again). R4 and M14 wait on that.

## The next action

**N3 is built**: every beat on the sheet and the pocket, in
`levels/act1_wall.level`, from the culvert's mouth to the castle gate. Route,
walk-back, 501 tests and 122 scenarios pass (18 of them walk the new wall's
beats), and every beat was shot. Where the build departs from the sheet is
at the foot of `levels/act1_wall.beats` (*As built*). The pre-N3 wall is
`act1_wall_old` (F2) to compare. Engine changes it needed: enemies revive
at a respawn, bats can sleep, lowercase anchors, WalkBack drops through
slabs. **Next for Claude**: Matt's play notes. N3 is done when Matt and the
kids play Act 1 from a new game and say it is better (G2 again).

**Act 2's first sheet is drafted ahead of the gate** (Matt, 2026-10-25,
overruling the R4-waits rule for planning only): `levels/act2_caverns.beats`,
19 beats from the undercroft to the lair door. Nothing is built from it until
Matt approves it. His answers to its questions are at its foot (*Decided*).

**Waiting for after G2** (Matt, 2026-10-25): the hunting scorpion and the
slash, both in `SPEC.md`. Built after Matt plays N3, so his play of the wall
compares like with like.

**The foreground kit and the new trees and assets are good enough to go on
with** (Matt, 2026-10-24, from the shots of the forest and the castle).
Placements are rules written into `[decor]` (`ART.md`, *The foreground
kit*), still easy to move by hand when play says so.

**Walk-back knows the hero's width** (2026-10-24): a ladder through a hole
narrower than the hero is cut there. It found a second dead end at once,
the ladder past the inner gate (beat 16), now fixed (*As built*).

**FLASHES in the pause menu** (2026-10-24, Matt's yes): scales the storm's
lightning down to nothing, for photosensitive players, kept with the volume
levels (`Flashes`). Rain and thunder stay at any setting.

**Forest rebuild (merged at Matt's word, 2026-10-24, before he played it):** Matt, with *Ghosts 'n Goblins Resurrection* shots: ground at the
bottom, hills, trees with boughs and greenery. The oak's slab is now a trunk
in `[back]` with two boughs (the crown and the sleeper's roof), the hill is
half as tall and terraced. The trees sheet is in: five trees placed by hand
(the clearing, the oak, the island, the far bank, the hill), leaves, moss,
bushes, and two fronds drawn in front of the hero. Matt's to play: the
terraces, the longer drop from the high road to the nest, the oak's vine and
staggered boughs, the sleeper's shorter patrol right of the trunk, and
whether a frond over the hero's legs ever hides something.

**The storm (Matt, 2026-10-24):** driving rain across Act 1's foreground,
and lightning that lights the painting behind the room, flashes over
everything in Volta's arc-core colour and cracks with thunder; in Act 4 it
flashes and strikes through the hall's windows (`Storm`, `config/storm.tres`,
`ART_DIRECTION.md` amended). First strike 6 s into a room, then every 10 to
24 s. Matt's to play: rain density, how often, how bright (`BACKLOG.md`).

**The cards (2026-10-24, Matt delegating while driving):** one pixel font
everywhere a player reads (`ART_DIRECTION.md`, *Lettering*); the opening
card moved up off the floor; each act named as it begins; act cards say
"Lothar fell N times" like the end card; the end card waits for jump; the
room tag hidden in act rooms (F1 still names the room). Matt's to judge the
font and the end card's wording.

**The death line moves (Matt, 2026-10-24):** it flies in from behind the
room, punches to 1.5x, settles, and flies on toward the camera as it fades.
The scale steps by half (Matt chose this over smooth zoom) so the pixel font
never splits a pixel (`DeathMessageMotion`, `config/death.tres`). Matt's to
play: whether the fly-in (0.2 s) reads, and the punch and exit sizes.

## Blocked on Matt

1. **Play Act 1 from a new game, with the kids** (the rebuilt wall is level
   2). Better than before? That is G2 again, and closes N3. Read the *As
   built* notes in `levels/act1_wall.beats` first: each is a call to keep
   or overrule.
2. **Mark up `levels/act2_caverns.beats`** (its questions are answered).
   Not a gate on N3.
3. **Play the N1 benches** (`bench_n1`, `bench_n1_found`, `bench_n1_combos`,
   F2; the top left names the room) and say which combinations are worth
   building beats around. Closes N1.
4. **Look at N2's after shots** (the PR) or play either Act 1 level: is a
   shot natural-looking? That closes N2. The back walls, torches and trunks
   are Claude's placements, easy to move in the level text.
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
