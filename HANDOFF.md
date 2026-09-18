# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-18 · **Phase:** 2, the look · **Active:** M6, the hero
rigged and animated. **Done when:** every state transitions cleanly into
every other state it can reach, and the somersault reads as a somersault at
game size in a screenshot, not just in the editor (`BUILD_PLAN.md`).

## Where this is

**Five of M6's rig states are in**: idle, run, jump, fall and land, on
`hero_rig.tscn`'s real `AnimationTree`. Two real bugs shipped (a property
one animation keyed and another did not; a hand edit left a dead duplicate
track block behind), both caught by Matt playing rather than by anything
automated, and both now have a headless test proven against the real
regression. `tools/dev.sh test`: 246 tests, 1611 checks. `tools/dev.sh
scenarios` now also runs CI's 28 capture-and-check rooms locally.

**Still to pick up**: throw, catch, climb and die as rig states, plus
painted pose sheets for the somersault and dive (`ANIMATION.md`). Claude
cannot drive the Godot editor from this session, so animation stays
text-authored; `ANIMATION.md` records that as settled. `tools/capture.gd
--filmstrip=N` reviews a transition as a frame sequence in one image, for
the next pose that only reads as wrong in motion. The sword itself now
plays a placeholder sound on throw, catch, embed and recall
(`assets/audio/sword/`), so M15 is an asset swap rather than new wiring.

## The next action

**Continue M6**: throw and catch are the natural next rig states, since the
sword already exists as a mechanic and only needs a wind-up and a readable
catch pose on the hero. Climb and die can follow independently.

## Blocked on Matt

1. **`LEVELS.md`'s open questions**, the ending swap chief among them.
2. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw
   and the dormant scorpion's wake-to-danger gap.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary fresh each
session. **Opening the project rewrites `project.godot`**, and a stale
editor deletes from it: close the editor, `git diff project.godot`, restore,
then pull. **A new `class_name` script fails every caller with "Could not
resolve class" until a reimport**, which reads like a compile error and is not.

**A cut rig looks right at rest and wrong the moment something moves**, test
by moving it: `tools/capture.gd --filmstrip=N` now does that without a
Godot editor session. **Some part boundaries have no silhouette gap or
colour split to cut by** (`ART.md`/`BACKLOG.md`). **A tileset module's
painted line will not land on the collision line by construction**: measure
the pixel row. **A compositional prior matters more for a dynamic pose**
(`GEMINI_NOTES.md`), relevant again for the somersault. **Godot's
`debug/gdscript/warnings/*` settings do not surface through this headless
pipeline**, tried several ways on the fetched 4.7.2 binary;
`tests/test_repo_typing.gd` substitutes a text scan instead.

**Reading a public repo of Matt's needs no permission grant**: anonymous
clone through this session's proxy already works, `add_repo` with `push` is
only for write access.

## Settled, do not relitigate

**M4:** contact with any enemy kills the hero, unconditionally; the dragon
is vulnerable only to RECALLING; the generator is M12's, not M4's. **The
gates:** no art before M5, no level building before M10. **G1:** passed on
feel, not on an hour of play. **Generation budget:** not a hard gate, push
past it without stopping to ask.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `LEVELS.md`
Matt's expanded level vision, not yet decided · `assets/reference/` original.
