# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-28 · **Phase:** 2, the look · **Active:** M6, the hero
animated, built and waiting on Matt's eye. **Done when:** every state transitions cleanly into every other
state it can reach, and the somersault reads as a somersault at game size in
a screenshot, not just in the editor (`BUILD_PLAN.md`).

## Where this is

**M5 is closed** in pixel art. **M6 is built:** all twelve states (idle, run,
jump, fall, land, throw, catch, climb, die, somersault, dive, dive landing) are
frame animations on `hero_sprite.tscn`, every one has a transition to every
other, and `tests/test_hero_sprite.gd` holds that. The transitions are
filmstripped in a running build (`assets/art_raw/_experiments/m6_transitions.png`
and `m6_air_moves.png`). `ART.md` has the recipe and cost, `ANIMATION.md` what
the somersault and dive do. Credits: 120.

**Somersault:** a jump taken while moving; no throw or recall until you land.
It flies the jump's own arc, so no room needed retuning. **Dive:** a fall past
640 px/s, then a landing crouch that roots you for 0.25 s.

## The next action

**Matt looks at `m6_air_moves.png` and calls the somersault readable at game
size or not** (M6's done-when), then M6 closes and M7, the enemy sheet, starts:
six enemies derived from one another (`BUILD_PLAN.md`).

## Blocked on Matt

1. **The somersault reading as one** (M6's last done-when), from the filmstrip.
2. **Whether the flip should travel further or rise less.** It does neither
   now, because every M2 to M4 room is measured against the jump's reach.
   Changing it moves those rooms' reach tests in the same PR (`ANIMATION.md`).
3. **Feel, by playing:** the run cycle's pace against ground speed, `hero_height`
   at 36, and the dive: at 640 px/s a fall of about 74 px dives, and so does a
   full jump onto a floor 18 px or more lower. Blocks nothing; M14 retunes.
4. **`LEVELS.md`'s open questions**, the ending swap chief among them. Blocks
   M10's level building.
5. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw and
   the dormant scorpion's wake-to-danger gap. Blocks M14's tuning of those.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary to `~/godot/godot`
each session and `tools/dev.sh` finds it. **Opening the project rewrites
`project.godot`**, and a stale editor deletes from it: close the editor,
`git diff project.godot`, restore, then pull. **A new `class_name` script
fails every caller with "Could not resolve class" until a reimport.**

**Only `generate` honours `size`.** Every other operation keeps roughly its
input's size, and `animate` always starts on the input's own pose.
**Generated frames can boil**: `tools/capture.gd --filmstrip=N`, and start
`--input` with `debug_toggle_overlay:1` or the overlay hides the hero at
zoom. **A test can pass while a texture is missing**, since nothing in the
suite draws the hero: load a room with `tools/dev.sh shot` after touching art.

## Settled, do not relitigate

**Pixel art** (Matt, after seeing it). **Straight sword, asymmetric hilt.**
**M5 final quality**, including the idle's slight boot flicker. **M4:**
contact with any enemy kills, the dragon is vulnerable only to RECALLING.
**G1:** passed. **Generation budget:** not a hard gate.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `LEVELS.md`
Matt's expanded level vision, not yet decided · `assets/reference/` original.
