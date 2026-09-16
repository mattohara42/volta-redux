# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-16 · **Phase:** 2, the look · **Active:** M6, the hero
rigged and animated. **Done when:** every state transitions cleanly into
every other state it can reach, and the somersault reads as a somersault at
game size in a screenshot, not just in the editor (`BUILD_PLAN.md`).

## Where this is

**G1 is closed.** Matt played `room_m5_wall.tscn` and judged the mechanic
good enough to proceed, not against the letter of "an hour": one room with
no animation and no sound cannot sustain an hour yet, and that gap is
recorded here rather than papered over. M6 is the reason it will change.

**M5's assembly stands as the base M6 builds on**: `scenes/rooms/
room_m5_wall.tscn` carries the real hero and bat `Skeleton2D` rigs, the
painted background and tileset, the ladder. The rig swap is global, every
Phase 1 bench shows the painted rig over the old grey capsule/diamond.
`ART.md` has the pipeline write-up; `tools/dev.sh test` was last clean at
221 tests, 1572 checks.

## The next action

**Start M6**: `ANIMATION.md` owns the line between rigged continuous motion
(idle, run, jump, fall, land, climb) and painted pose sheets (somersault,
dive), and that line is not a matter of taste. No animation work has
started yet, this is the first slice to pick up.

## Blocked on Matt

1. **`LEVELS.md`'s open questions**, the ending swap chief among them.
2. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw,
   the dormant scorpion's wake-to-danger gap.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary fresh each
session. **Opening the project rewrites `project.godot`**, and a stale
editor deletes from it: close the editor, `git diff project.godot`, restore,
then pull. **A new `class_name` script fails every caller with "Could not
resolve class" until a reimport**, which reads like a compile error and is
not one.

**A scene or character has a compositional prior a flat-field subject does
not, and a dynamic pose carries a stronger one than standing**: state
framing positively, name the default it rules out (`GEMINI_NOTES.md`).
Matters again for M6's action poses. **A cut rig looks right at rest and
wrong the moment something moves**, test by moving it (relevant to M6);
**some part boundaries have no silhouette gap or colour split to cut by**
(`ART.md` and `BACKLOG.md` have the fix). **A tileset module's painted
line will not land on the collision line by construction**: measure the
pixel row, don't eyeball it.

**Reading a public repo of Matt's needs no permission grant**: anonymous
git clone through this session's proxy already works, `add_repo` with
`push` is only for write access. A prior note calling `hook-line-and-
sentence` blocked on push was wrong, it only needed reading. Clone it
fresh whenever M7's pipeline porting needs it.

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
Matt's expanded level vision, not yet decided · `assets/reference/` the
original.
