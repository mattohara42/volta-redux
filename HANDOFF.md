# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 150 lines.

**Updated:** 2026-11-12 · **Phase:** 3 rebuilt, depth before breadth.
**G2 passed** on the rebuilt Act 1 (Matt, 2026-11-12: "much better ... but we
need to keep evolving it"). N3 is done.
**Active milestone:** N4, the forest rebuilt from a beat sheet
(`BUILD_PLAN.md`; named this session from N3's "then the forest gets a
density pass", so the name and done-when are Claude's, Matt to confirm).
**N4 done-when:** Matt has approved `levels/act1_forest.beats`, route,
walkback, tests and scenarios pass, every beat is shot where the sheet puts
it, and Matt plays Act 1 and says the forest now matches the wall.

## Where it is

The three features held for G2 are on `main`: the scorpion hunts (#203), the
slash (#210), the portal (#206, the forest's stumps are now portal doors).
Each one's open calls are in its PR description and in *Blocked on Matt*.
Merge rule changed: enable auto-merge, never merge over red (`CLAUDE.md`,
#208).

## The next action

**Draft `levels/act1_forest.beats`** for Matt to mark up, the way the wall's
was drafted (`levels/act1_wall.beats` is the model, `SPEC.md` *How a level is
built* the method). Nothing is built from it until he approves it.

## Blocked on Matt

1. **Turn on auto-merge** (#208): repo Settings, General, *Allow
   auto-merge*; and a branch rule on `main` requiring *Headless tests and
   the capture scenarios*. Until then Claude waits for green and merges by
   hand, which is the same rule done slower.
2. **Play the three merged features** and judge the dials (all in
   `config/`) and calls: the hunt's sight and instant turn (#203); the
   slash's reach and recovery, and whether it belongs outside `Sword`
   (#210); the portal's 3 s open and 1 s shut, and whether `Stump`,
   `StumpLanding` and `room_g2_stump` can be deleted (#206).
3. **The slash's art, next 15 credits**: the first `animate` turned the hero
   round and curved the blade (`ART.md`, *The slash*). Same prompt again, or
   the reworded one there? The placeholder stands until then.
4. **Mark up `levels/act2_caverns.beats`.** Blocks building Act 2 (R4).
5. **Close N1 and N2**: play the N1 benches (F2) and say which combinations
   are worth beats; say whether N2's look is natural. Both are inputs to
   the forest sheet, so they are worth doing first.
6. **Frame time on a real machine**: `tools/dev.sh frametime`, then with
   `act1_forest.tscn` and `act1_wall.tscn`: p95 under 16.7 ms? Blocks R3's
   frame-rate half.
7. **Older and still open**: R2's final quality (the flame, the sword, the
   doors, the ride); `RoomM7Sheet` consistent in treatment (closes M7); the
   unattended calls from 2026-10-05; M4's dragon pacing; a play log
   (`user://`, #136). Two rulings that waited on N1: faster ladder
   climbing, and a test build that lets you throw mid-somersault.

**Matt's to judge while playing Act 1** (each built on his word, dials in
`config/`): the forest's terraces, oak and fronds; the storm (FLASHES in the
pause menu turns it down); the cards and lettering; the death line's fly-in;
the tall wall painting's mirror seams.

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

**A ladder with nothing at its top makes the hero bob there**, and a jump
pressed mid-bob does nothing. **A missed return falls with its homeward
speed** and lands about 140 px past the hero. **A bat's box is where it can
kill you**, pulled in by half its body wherever it touches solid (#201): a
sword or a throw line in a bat's reach needs a cell of air between box and
wall. **A scorpion is only a sword fight in a tunnel**: the throw is flat at
18 px and it is 34 px tall. **A scorpion that sees you hunts you** now: a
beat that relied on its fixed range needs re-checking in play. **Walk-back's
"exit out of reach" means the level is blocked**: its drawing is full height.

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
**Auto-merge on green** (2026-11-12). **The foreground kit, the new trees
and assets** are good enough to go on with (2026-10-24).

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `assets/audio/README.md` sound ·
`CLAUDE.md` how to work here · `README.md` running it · `BACKLOG.md` raised
and not judged · `LEVELS.md` Matt's level vision, decided. Open issue: #209
(scenarios by goal, not frame count).
