# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-18 · **Phase:** 2, the look · **Active:** M6, the hero
rigged and animated. **Done when:** every state transitions cleanly into
every other state it can reach, and the somersault reads as a somersault at
game size in a screenshot, not just in the editor (`BUILD_PLAN.md`).

## Where this is

**Seven of M6's rig states are in**: idle, run, jump, fall, land, throw and
catch, on `hero_rig.tscn`'s real `AnimationTree`. Throw and catch are held
poses timed like `land`, but they beat "airborne always wins" on purpose: a
throw or catch is something the player just did, not a byproduct of ground
contact (`Locomotion.state_for`'s comment says why). `Sword.recovered` now
carries `caught_in_flight`, so the catch pose fires only for a sword caught
in the air, never one walked over off the floor. Checked against a real
build: `tools/capture.gd`'s zoomed single-frame and filmstrip shots show
both poses hold clearly and cross-fade cleanly, no PR #51-style float.
`tools/dev.sh test`: 249 tests, 1619 checks. `scenarios`: still 28, 0 failed.

**Still to pick up**: climb and die as rig states, plus painted pose sheets
for the somersault and dive (`ANIMATION.md`). Animation stays text-authored,
which `ANIMATION.md` records as settled, since Claude cannot drive the
Godot editor here. The sword now plays a placeholder sound on throw, catch,
embed and recall (`assets/audio/sword/`), so M15 is an asset swap only.

## The next action

**Continue M6**: climb and die are the natural next states. Climb has
movement code (`_step_climbing`) to hang a state off; die may be one held
pose, since `_update_rig` already freezes on death. Throw beating airborne
priority (above) is an assumption made without Matt watching it played:
worth a look on `tools/dev.sh play`, in case mid-jump throws read as wrong.

## Blocked on Matt

1. **`LEVELS.md`'s open questions**, the ending swap chief among them.
2. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw
   and the dormant scorpion's wake-to-danger gap.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary fresh each
session. **Opening the project rewrites `project.godot`**, and a stale
editor deletes from it: close the editor, `git diff project.godot`, restore,
then pull. **A new `class_name` script fails every caller with "Could not
resolve class" until a reimport**, which reads like a compile error and isn't.

**A cut rig looks right at rest and wrong the moment something moves**, test
by moving it: `tools/capture.gd --filmstrip=N` now does that without a
Godot editor session. **Some part boundaries have no silhouette gap or
colour split to cut by** (`ART.md`/`BACKLOG.md`). **A tileset module's
painted line will not land on the collision line by construction**: measure
the pixel row. **A compositional prior matters more for a dynamic pose**
(`GEMINI_NOTES.md`), relevant again for the somersault. **Godot's
`debug/gdscript/warnings/*` settings do not surface through this headless
pipeline**; `tests/test_repo_typing.gd` substitutes a text scan instead.
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
