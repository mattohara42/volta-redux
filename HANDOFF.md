# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 150 lines.

**Updated:** 2026-10-25 (late) · **Phase:** 3 rebuilt, depth before breadth.
**Active milestone:** N3, the outer wall rebuilt from a beat sheet
(`BUILD_PLAN.md`). Matt approved the sheet, `levels/act1_wall.beats`, on
2026-10-13. N0 is done; N1 and N2 are built and wait only on Matt's play.
**N3 done-when:** route, walkback, tests and scenarios pass, every beat is
shot where the sheet puts it, and Matt and the kids play Act 1 from a new
game and say it is better (G2 again). R4 and M14 wait on that.

## The next action

**N3 is built and waits on Matt's play.** Every beat on the sheet is in
`levels/act1_wall.level`; where the build departs from the sheet is at the
foot of `levels/act1_wall.beats` (*As built*). `act1_wall_old` (F2) is the
pre-N3 wall to compare. **Next for Claude**: Matt's play notes.

**Three features are built and held, unmerged, for after G2** (Matt,
2026-10-25: built after he plays N3, so the wall compares like with like).
Each is a ready PR titled *HOLD until G2*, green, with its open calls in
its description:

- **#203, the scorpion hunts** (`SPEC.md`, *The scorpion hunts*): sees you
  ahead on its own floor, comes after you, waits at its floor's edge.
  Dials in `config/enemies.tres`.
- **#210, the slash** (K, gamepad B): free, short, armour turns it, the
  bosses ignore it. Dials in `config/sword.tres`. Placeholder look until
  its Sprite Fusion `animate` is run (`ART.md`, *The slash*).
- **#206, the portal** (`LEVELS.md`, Decisions 2026-10-25): two doors
  taking turns, the forest's stumps reworked to it, painted doors for
  forest, castle and caverns. Dials in `config/hazards.tres`.

After G2, merge them one at a time: each touches `tools/scenarios_data.py`
and two touch `scripts/player.gd`, so the second and third take a merge
from `main` first. All three change Act 1's feel, which is the point.

**Act 2's first sheet is drafted ahead of the gate**:
`levels/act2_caverns.beats`. Nothing is built from it until Matt approves
it; his answers to its questions are at its foot (*Decided*).

## Blocked on Matt

1. **Play Act 1 from a new game, with the kids** (the rebuilt wall is level
   2). Better than before? That is G2 again, and closes N3. Read the *As
   built* notes in `levels/act1_wall.beats` first. Blocks R4, M14, and
   merging #203, #206, #210.
2. **Then play the three held PRs** and judge their dials and the calls in
   each description (the hunt's sight and instant turn; the slash's reach
   and recovery, and whether it belongs outside `Sword`; the portal's 3 s
   and 1 s, and whether `Stump` and `room_g2_stump` can go).
3. **Mark up `levels/act2_caverns.beats`.** Blocks building Act 2.
4. **Put `SPRITE_FUSION_API_KEY` in the cloud environment** (environment
   menu, Edit, Network secrets). Blocks the slash's animation in a cloud
   session.
5. **Paint the sword graveyard** (`ART.md`, *The next three*, prompt 3).
   Blocks caverns beat 8a's look, not its build.
6. **#208: auto-merge instead of merging at once.** #201 merged with a red
   scenario because CI takes 10 minutes and the rule is to merge straight
   away. Changes a `CLAUDE.md` rule, so Matt's.
7. **Play the N1 benches** (`bench_n1`, `bench_n1_found`,
   `bench_n1_combos`, F2) and say which combinations are worth building
   beats around. Closes N1. The found bench's bat now takes about 7 s to
   find the stuck sword (#204).
8. **Look at N2's after shots** or play either Act 1 level: is a shot
   natural-looking? Closes N2.
9. **Frame time on a real machine**: `tools/dev.sh frametime`, then with
   `act1_forest.tscn` and `act1_wall.tscn`: p95 under 16.7 ms? Blocks R3's
   frame-rate half.
10. **Older and still open**: R2's final quality (the flame, the sword, the
    doors, the ride); `RoomM7Sheet` consistent in treatment (closes M7); the
    unattended calls from 2026-10-05; M4's dragon pacing; a play log
    (`user://`, #136). Two rulings wait for N1: faster ladder climbing, and
    a test build that lets you throw mid-somersault.

**Matt's to judge while playing Act 1** (each built on his word, dials in
`config/`): the forest rebuild (terraces, the drop to the nest, the oak's
vine and boughs, the fronds over the hero's legs); the storm (rain density,
how often, how bright; FLASHES in the pause menu turns it down); the cards
and lettering; the death line's fly-in and punch; the tall wall painting
(the sky's clouds fold into a symmetric blot at each mirror seam).

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary to `~/godot/godot`
each session, and `pip install scipy` before `tools/synth` or `tools/key.py`.
**Opening the project rewrites `project.godot`**: close the editor,
`git diff project.godot`, restore, then pull. **A new `class_name` script
fails every caller until a reimport**, and a new test's `.uid` only appears
on the import after it: run `tools/dev.sh import` and commit the `.uid`.
A parse error or a script error mid-test is a test failure. **Tests run
before the tree is ready**, so nothing needing `get_tree()` can be tested
headless. **Indexing a `const` array of preloaded resources** folds at parse
time and fails to compile: go through a typed variable.

**Never edit a tree a scenario run is reading**: each scenario starts its
own Godot, so a mid-run edit mixes two versions. Use a `git worktree` per
branch. **A branch cut before a fix** goes red on its push run and green on
its PR run (the PR run tests the merge); merge `main` in.

**`*.import` is gitignored**: an import setting set there holds on one
machine only; loops live in the WAV (`smpl`) or in code (#120). **Godot's
movie writer is how to see and hear a real run**: `godot --path . <scene>
--write-movie out/f.png --fixed-fps 30 --quit-after N`. **Only a plain
launch touches the save; `--script` never does**, because a tool's room is
not `current_scene`, which is also why `shot` leaves the room tag blank.
That is deliberate, not a bug to fix. **`capture --zoom` is relative to
the 640x360 design**, so on the 1280x720 window it draws at twice the zoom.

**A ladder with nothing at its top makes the hero bob there**, and a jump
pressed mid-bob does nothing. **A missed return falls with its homeward
speed** and lands about 140 px past the hero. **A bat's box is where it can
kill you**, pulled in by half its body wherever it touches solid (#201): a
sword or a throw line in a bat's reach needs a cell of air between box and
wall. **A scorpion is only a sword fight in a tunnel**: the throw is flat at
18 px and it is 34 px tall. **Walk-back's "exit out of reach" means the
level is blocked**: its drawing is full height now.

**Sprite Fusion**: `style-reference` ignores `size`, `animate` starts on the
input's pose, frames can boil (filmstrip first), an SSL EOF charges nothing.
**Gemini sheets**: `key.py --spill-hue` eats purple-brown bark with the
magenta; key a sheet with warm purples at `--tolerance 40` and no spill.
**A test can pass while a texture is missing**: shoot the room after art.
**A grid level's look is baked at load**: shoot it, headless draws nothing.

## Settled, do not relitigate

**Pixel art.** **Straight sword, asymmetric hilt.** **M5 final quality.**
**Moving jumps are somersaults; dives cost a recovery pause** (2026-09-28).
**M4:** contact with any enemy kills; the dragon dies only to RECALLING.
**G1:** passed. **Enemies killed since the brazier come back at a respawn**
(2026-10-13). **N0:** passed. **`LEVELS.md`'s twelve questions**
(2026-09-28). **R1's play half** (2026-10-07). **The slash** (2026-10-25):
its own button, armour turns it, no boss damage. **The foreground kit, the
new trees and assets** are good enough to go on with (2026-10-24).

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `assets/audio/README.md` sound ·
`CLAUDE.md` how to work here · `README.md` running it · `BACKLOG.md` raised
and not judged · `LEVELS.md` Matt's level vision, decided. Open issues:
#208 (merge on green), #209 (scenarios by goal, not frame count).
