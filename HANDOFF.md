# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-28 · **Phase:** 2, the look · **Active:** M6, the hero
animated. **Done when:** every state transitions cleanly into every other
state it can reach, and the somersault reads as a somersault at game size in
a screenshot, not just in the editor (`BUILD_PLAN.md`).

## Where this is

**M5 is closed** in pixel art. **M6 is half done:** idle, run, jump, fall,
land, throw, catch, climb and die are frame animations on `hero_sprite.tscn`,
each filmstripped through its transitions in a running build
(`assets/art_raw/_experiments/m6_transitions.png`). `ART.md` has the recipe
and cost of both milestones, `GEMINI_NOTES.md` what Sprite Fusion actually
does. Credits: 165.

**What is left of M6 is the somersault and the dive**, which do not exist as
movement yet. Their frames are a few requests once the movement exists.

## The next action

**Matt settles how the somersault and dive behave**, then they get built as
`Locomotion` states with their numbers in `config/movement.tres`, then
animated. `ANIMATION.md`'s proposal is the starting point: a jump at run
speed becomes a somersault that travels further, rises less, and cannot
throw; a fall past a threshold speed becomes a dive.

## Blocked on Matt

1. **Somersault and dive behaviour.** Blocks finishing M6.
2. **Feel, by playing:** the run cycle's pace against ground speed (0.25 s a
   cycle, `hero_sprite.tscn`), and `hero_height` at 36 instead of 40.
   Blocks nothing now; M14 retunes whatever this turns up.
3. **`LEVELS.md`'s open questions**, the ending swap chief among them. Blocks
   M10's level building.
4. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw and
   the dormant scorpion's wake-to-danger gap. Blocks M14's tuning of those.
5. **Sprite Fusion's reply on `edit` ignoring `size`.** Blocks nothing now:
   `animate` from the still replaced the pose step.

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
