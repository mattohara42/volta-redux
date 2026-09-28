# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-28 · **Phase:** 2, the look · **Active:** M5, pixel art.
**Done when:** the M5 room is in the game at final quality in pixel art, and
`ART.md` carries the generations and credits it took (`BUILD_PLAN.md`).

## Where this is

**M5 is built and waiting on Matt's eye.** The room renders in pixel art in a
running build: an animated idle hero (36 px, `hero_height` now 36), a flapping
bat, Sprite Fusion tiles, the pixelated background, filter Nearest, integer
stretch. `ART.md` carries the cost (*M5 in pixel art*: 14 requests, 210
credits, about 120 once the recipe is known). The painted rigs are no longer
drawn; their scenes and parts stay until M6 deletes them.

**The recipe that works:** `generate` at the target size, `direction-set` for
a side view, `animate` for motion, `tools/recolour-darks.py` then
`tools/palette-check.py` on everything. Only `generate` honours `size`
(`GEMINI_NOTES.md`, *Sprite Fusion, measured*).

## The next action

**Matt looks at the room and calls final quality or not**
(`assets/art_raw/_experiments/m5_pixel_room.png`, or `tools/dev.sh play`,
F2 to the M5 bench). The two things to judge are in `ART.md`'s *Open* list:
the idle's boot flicker and the bright ledge face. Then M5 closes and M6
starts: the hero's other six states, which show idle frames today.

## Blocked on Matt

1. **M5's final-quality call.** Blocks closing M5 and starting M6.
2. **M6's pose route.** `edit` ignores `size`, so turning the still into a
   run or throw start pose has no clean route yet. Options are in `ART.md`'s
   *Open* list; Sprite Fusion's reply to Matt's ticket may settle it.
3. **`LEVELS.md`'s open questions**, the ending swap chief among them. Blocks
   M10's level building, nothing before it.
4. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw and
   the dormant scorpion's wake-to-danger gap. Blocks M14's tuning of those.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary to `~/godot/godot`
each session and `tools/dev.sh` finds it. **Opening the project rewrites
`project.godot`**, and a stale editor deletes from it: close the editor,
`git diff project.godot`, restore, then pull. **A new `class_name` script
fails every caller with "Could not resolve class" until a reimport**, which
reads like a compile error and isn't.

**Generated frames may look right one at a time and boil in motion**:
`tools/capture.gd --filmstrip=N`. **The debug overlay covers the hero in a
zoomed capture**; start `--input` with `debug_toggle_overlay:1`. **Godot's
`debug/gdscript/warnings/*` settings do not surface through this headless
pipeline**; `tests/test_repo_typing.gd` substitutes a text scan. **Reading a
public repo of Matt's needs no permission grant**: anonymous clone through
this session's proxy already works.

## Settled, do not relitigate

**Pixel art is the direction** (Matt, after seeing it). **Straight sword,
asymmetric hilt** for rotation readability. **M4:** contact with any enemy
kills, the dragon is vulnerable only to RECALLING, the generator is M12's.
**The gates:** no level building before M10. **G1:** passed, and the art
change does not reopen it. **Generation budget:** not a hard gate.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `LEVELS.md`
Matt's expanded level vision, not yet decided · `assets/reference/` original.
