# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-28 · **Phase:** 3, the game · **Active:** M10, Act 1.
M7 stays open at five of six enemies until credits return (the generator).
**Done when:** someone who has never played it gets through Act 1 without being
told what the sword does (`BUILD_PLAN.md`).

## Where this is

**Credits: 0, and Matt has paused buying more (2026-09-28).** Do not propose a
top-up; build with existing art and code. The estimate is in `ART.md`.

**Room 1 of 4 built:** `Act1Bank` (`scenes/rooms/act1_bank.tscn`, last on F2).
A bank to practise throwing on, a culvert with a sleeping scorpion facing away,
a checkpoint, a sally port with an awake one. `tests/test_act1_bank.gd` holds
the geometry; two scenarios hold the kill and the armour. Real rooms extend
`Bench` and draw with `TileArt` (`Bench`'s class comment says why). References:
`assets/art_raw/_experiments/m10_act1_bank_left.png`, `_right.png`.

**Before this:** M6 passed Matt's playtest; M9 is built (lava, arcs, charged
floors, the light layer on braziers, breath and arcs).

## The next action

**Matt plays `Act1Bank`**, ideally without the overlay (F1). Then room 2 (the
outer wall: ladders, bats, the scorpion's from-above trick), room 3 (embed:
wood, a switch, a glimpse of the chained dragon), room 4 (must stand on your own
sword, ends at the gate), with the act-state autoload arriving alongside room 2.

## Blocked on Matt

1. **Playing `Act1Bank`**: does it teach the throw and the scorpion's armour
   with no words?
2. **A sword counter** (`BACKLOG.md`, raised during M10): there is none outside
   the debug overlay, and a new player probably needs one.
3. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw and
   the dormant scorpion's wake-to-danger gap. Blocks M14's tuning of those.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary to `~/godot/godot`
each session. **Opening the project rewrites `project.godot`**: close the
editor, `git diff project.godot`, restore, then pull. **A new `class_name`
script fails every caller until a reimport, and the test runner still exits 0
with the parse error printed**: read its output, not its exit code. The same
goes for a `SCRIPT ERROR` mid-test. **Tests run before the tree is ready**, so
nothing needing `get_tree()` can be tested headless.

**Only `generate` honours `size`.** `animate` starts on the input's own pose
and never moves its feet. **Generated frames can boil**: `tools/capture.gd
--filmstrip=N`, starting `--input` with `debug_toggle_overlay:1` or the overlay
hides the hero. **A test can pass while a texture is missing**: load a room
with `tools/dev.sh shot` after touching art. **`assets/art_raw/` is
`.gdignore`d**: Godot cannot decode Sprite Fusion's animated WebP.

## Settled, do not relitigate

**Pixel art.** **Straight sword, asymmetric hilt.** **M5 final quality.**
**Moving jumps are somersaults, no throwing during one; dives cost a
recovery pause** (Matt, 2026-09-28, and the playtest passed the somersault,
dive, run pace, hero height 36 and lava brightness). **M4:** contact with any enemy kills, the
dragon is vulnerable only to RECALLING. **G1:** passed. **Generation budget:**
not a hard gate. **`LEVELS.md`'s twelve questions**
(Matt, 2026-09-28): the caged creature is the Act 2 dragon, chained then freed
in Act 4; the forest folds into Act 1; about 18 rooms; remix rooms wanted.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `LEVELS.md`
Matt's expanded level vision, decided · `assets/reference/` original.
