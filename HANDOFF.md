# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-10-03 · **Phase:** 3, the game · **Active:** M11, Act 2.
M10 waits only on a fresh player getting through Act 1 untold (its done-when).
**M11 done when:** Act 2 is playable start to finish, and the dragon is
beatable without spending a sword on it (`BUILD_PLAN.md`).

## Where this is

**Credits: 765.** Random HTTP 403s cost nothing; retry once.
Spend in small batches, each looked at before the next (`ART.md` → *What is
left to generate*). Enemies and characters wait on `RoomM7Sheet`'s verdict.

**All four Act 1 rooms built and connected:** `Act1Bank` (throw, armour),
`Act1Wall` (from-above), `Act1Bailey` (embed, recall, a switch; the dragon's
grate) and `Act1Gate` (stand on your sword; the castle gate ends the act).
Real rooms extend `Bench` and draw with `TileArt` (`Bench`'s class comment says
why). The sword counter (`SwordCounter`) shows swords in hand and out, top
right, in every room.

**Act 1 art wired** except the brazier and switch, which stay code by choice
(`ART.md` → *Act 1 props*).

## The next action

**Act 2, rooms 1 to 4 built:** `Act2Mouth` (ferries), `Act2Geysers` (jets),
`Act2Causeway` (falling slabs, a bat) extend their M3 benches; `Act2Tide` is
the new lava tide (`LavaTide`). Next: the mine, then the dragon's lair. **Act 2 needs a painted background** (Matt, Gemini);
until then its rooms show a plain backdrop under a rock ceiling.

## Blocked on Matt

1. **Playing Act 1 through**: does each room teach its verb with no words, and
   is the bailey's grate read as something alive in the dark?
2. **`RoomM7Sheet`**: are the six consistent in treatment? That closes M7.
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

**`style-reference` ignores `size`** (58 to 71 when asked 32); `generate`
holds it and `edit` refuses it and keeps the input's size (2026-10-03).
`animate` starts on the input's own pose and never moves its feet. **Generated
frames can boil**: `tools/capture.gd --filmstrip=N`, starting `--input` with
`debug_toggle_overlay:1` or the overlay hides the hero. **A test can pass while
a texture is missing**: load a room with `tools/dev.sh shot` after touching
art. **`assets/art_raw/` is `.gdignore`d**: Godot cannot decode Sprite
Fusion's animated WebP. **An SSL EOF before the API answers charges nothing**:
check `credits`, then retry once.

## Settled, do not relitigate

**Pixel art.** **Straight sword, asymmetric hilt.** **M5 final quality.**
**Moving jumps are somersaults, no throwing during one; dives cost a
recovery pause** (Matt, 2026-09-28, and the playtest passed the somersault,
dive, run pace, hero height 36 and lava brightness). **M4:** contact with any
enemy kills, the dragon is vulnerable only to RECALLING. **G1:** passed.
**Generation budget:** not a hard gate. **`LEVELS.md`'s twelve questions**
(Matt, 2026-09-28): the caged creature is the Act 2 dragon, chained then freed
in Act 4; the forest folds into Act 1; about 18 rooms; remix rooms wanted.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `LEVELS.md`
Matt's expanded level vision, decided · `assets/reference/` original.
