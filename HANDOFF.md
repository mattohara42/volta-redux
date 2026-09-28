# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-28 · **Phase:** 2, the look · **Active:** M7 (five of six
built). M6 passed Matt's playtest. M9 was built ahead of M8 because M8 needs
credits. **Done when:** M7, the six enemies are on screen, distinguishable and
consistent (`BUILD_PLAN.md`).

## Where this is

**Credits: 0.** Every request costs 15, so anything generated waits on a
top-up. Spent this session: M5 210, M6 180, M7 120 (`ART.md`).

**M6 passed:** twelve hero states, every transition tested, the somersault (a
jump taken while moving, no throwing until you land) and the dive (a fall past
640 px/s, then a 0.25 s crouch). **M7 built for five of six:** scorpion, ant,
eyeball, dragon and bat are sprites on their M4 behaviours, in `RoomM7Sheet`.
**M9 built:** lava, an arc and a charged floor are shaders and particles
(`RoomM9Atmosphere`); every lava pit in the game uses it. F2 cycles the benches.
References: `assets/art_raw/_experiments/m6_air_moves.png`, `m7_sheet.png`,
`m9_atmosphere_room.png`.

## The next action

**With credits** (30): the generator's still and animation, which finishes M7.
Then M8, the four acts' tilesets and backgrounds (`ART.md`'s recipe: `generate`
at 16 for tiles, `tile-variants.py`, the painted background through
`pixelate.py`). **Without:** the light layer exists (`LightGlow`: braziers, the
dragon's breath, arcs) but is not yet on torches, the sword or the generator,
and the hero has no rim light (`ART_DIRECTION.md`).

## Blocked on Matt

1. **Credits.** Blocks the generator (30) and all of M8.
2. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw and
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
