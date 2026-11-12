# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 150 lines.

**Updated:** 2026-11-12 · **Phase:** 3 rebuilt, depth before breadth.
**G2 passed** on the rebuilt Act 1 (Matt, 2026-11-12: "much better ... but we
need to keep evolving it"). N3 is done.
**Active milestone:** N4, the forest rebuilt from a beat sheet
(`BUILD_PLAN.md`; named by Claude, Matt to confirm).
**N4 done-when:** Matt has approved `levels/act1_forest.beats`, route,
walkback, tests and scenarios pass, every beat is shot where the sheet puts
it, and Matt plays Act 1 and says the forest now matches the wall.
**Proposed next:** N5, the look of a level (`BUILD_PLAN.md`, Matt to confirm).

## Where it is

The three features held for G2 are on `main`: the scorpion hunts (#203), the
slash (#210), the portal (#206). Their open calls are in *Blocked on Matt*.
Merge rule: enable auto-merge, never merge over red (`CLAUDE.md`, #208).

**The look is reviewed.** Matt, 2026-11-12: the levels look "blocky,
awkward, amateurish, unpolished" beside the characters; ladders, vines and
trees "too straight, flat, blocky, unnatural". So N2's look is not natural.
Cause, plan and two tested experiments: N5 in `BUILD_PLAN.md`, pictures on
Matt's page (https://claude.ai/artifact/VznJakffciS7aC1PSZj6y3) and in
`assets/art_raw/_experiments/look_*.png`.

## The next action

**`levels/act1_forest.beats` is drafted** and waits on Matt's markup (four
questions at its foot). Nothing is built from it until he approves it.
While it waits, Claude can:

1. **Fix the capture's settle** (N5 step 0, its own PR): it waits 12 frames
   and the reveal takes 0.35 s. N4's beat shots need it too.
2. **Bench beat 16's move** (a bounced throw coming home through a scorpion
   that turned to follow a somersault): the sheet leans on it, unproved.

## Blocked on Matt

1. **Play the three merged features** and judge the dials (all in
   `config/`) and calls: the hunt's sight and instant turn (#203); the
   slash's reach and recovery, and whether it belongs outside `Sword`
   (#210); the portal's 3 s open and 1 s shut (#206).
2. **The slash's art, next 15 credits**: the first `animate` turned the hero
   round and curved the blade (`ART.md`, *The slash*). Same prompt again, or
   the reworded one there? The placeholder stands until then.
3. **Mark up `levels/act1_forest.beats`.** Blocks building N4. N5's support
   rule (every platform and climbable visibly held up) is free if it goes in
   first. **And `levels/act2_caverns.beats`**, which blocks Act 2 (R4).
4. **N5's calls** (`BUILD_PLAN.md`, N5): whether N5 follows N4 (blocks N5);
   paint-over in Gemini or Claude's code mock first (blocks step 1); 30
   credits for the bank block (blocks step 3); whether the vine, the ladder
   and the trunk pass go ahead of N4 as small PRs, and the trunk's lean,
   about 6 to 8 px proposed (blocks those PRs).
5. **Close N1**: play the N1 benches (F2) and say which combinations are
   worth beats. An input to the forest sheet, so worth doing first.
6. **Frame time on a real machine**: `tools/dev.sh frametime`, then with
   `act1_forest.tscn` and `act1_wall.tscn`: p95 under 16.7 ms? Blocks R3's
   frame-rate half.
7. **Older and still open**: R2's final quality (the flame, the sword, the
   doors, the ride); `RoomM7Sheet` consistent in treatment (closes M7); the
   unattended calls from 2026-10-05; M4's dragon pacing; a play log
   (`user://`, #136). Two rulings that waited on N1: faster ladder
   climbing, and a test build that lets you throw mid-somersault.

**Matt's to judge while playing Act 1** (dials in `config/`): the forest's
fronds; the storm (FLASHES in the pause menu); the cards and lettering; the
death line's fly-in; the tall wall painting's mirror seams.

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
its PR run (the PR run tests the merge); merge `main` in. **Two branches
that add scenarios at the same spot** conflict in `tools/scenarios_data.py`;
keep both blocks.

**`*.import` is gitignored**: an import setting set there holds on one
machine only; loops live in the WAV (`smpl`) or in code (#120). **Godot's
movie writer is how to see and hear a real run**: `godot --path . <scene>
--write-movie out/f.png --fixed-fps 30 --quit-after N`. **Only a plain
launch touches the save; `--script` never does**, because a tool's room is
not `current_scene`, which is also why `shot` leaves the room tag blank.
That is deliberate, not a bug to fix. **`capture --zoom` is relative to
the 640x360 design**, so on the 1280x720 window it draws at twice the zoom.
**A `shot` with no input, and every filmstrip's first frame, land
mid-reveal**: dark two-pixel blocks over everything. Add `--input="-:40"`
until N5 step 0 lands.

**A ladder with nothing at its top makes the hero bob there**, and a jump
pressed mid-bob does nothing. **A missed return falls with its homeward
speed** and lands about 140 px past the hero. **A bat's box is where it can
kill you**, pulled in by half its body wherever it touches solid (#201): a
sword or a throw line in a bat's reach needs a cell of air between box and
wall. **A scorpion is only a sword fight in a tunnel**: the throw is flat at
18 px and it is 34 px tall. **A scorpion that sees you hunts you** now: a
beat that relied on its fixed range needs re-checking in play. **Walk-back's
"exit out of reach" means the level is blocked**: its drawing is full height.
**The forest's trunks are decoration, not solid**, and its boughs are solid:
a trunk's art can change freely, but it must still meet its boughs.

**Sprite Fusion**: the key is a cloud network secret, so run the client as
`SPRITE_FUSION_API_KEY=proxy-injected tools/sprite-fusion.py ...` (`ART.md`).
`style-reference` ignores `size`, `animate` starts on the input's pose,
frames can boil (filmstrip first), a big pose change can turn the figure
round, an SSL EOF charges nothing. **Gemini sheets**: `key.py --spill-hue`
eats purple-brown bark with the magenta; key a sheet with warm purples at
`--tolerance 40` and no spill. **A test can pass while a texture is
missing**: shoot the room after art. **A grid level's look is baked at
load**: shoot it, headless draws nothing.

## Settled, do not relitigate

**Pixel art.** **Straight sword, asymmetric hilt.** **M5 final quality.**
**Moving jumps are somersaults; dives cost a recovery pause** (2026-09-28).
**M4:** contact with any enemy kills; the dragon dies only to RECALLING.
**G1, G2, N0, N3:** passed. **Enemies killed since the brazier come back at
a respawn** (2026-10-13). **`LEVELS.md`'s twelve questions** (2026-09-28).
**R1's play half** (2026-10-07). **The slash** (2026-10-25): its own button,
armour turns it, no boss damage. **The portal is the original's** (2026-10-25).
**Auto-merge on green** (2026-11-12). **The foreground kit and assets** are
good enough to go on with (2026-10-24); Matt reopened the trees on
2026-11-12 (N5).

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `assets/audio/README.md` sound ·
`CLAUDE.md` how to work here · `README.md` running it · `BACKLOG.md` raised
and not judged · `LEVELS.md` Matt's level vision, decided. Open issue: #209
(scenarios by goal, not frame count).
