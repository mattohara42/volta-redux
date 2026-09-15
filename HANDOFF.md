# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 1 closing, 2 opening · **Active
milestone:** M5

**M4 is closed** on Matt's word. Its done-when is rescoped in `BUILD_PLAN.md`:
five of the six enemies, not six. The generator, the sixth, is Act 3's boss
and needs the sword's unbuilt `conduct` state and the conductivity vocabulary
that don't exist until M12; it was never M4's to build, and the old done-when
conflated "grey-box the verb against a hazard" with "build a mechanic that
doesn't exist yet." It ships with M12.

## Where this is

**M4, as closed:** bat, scorpion, giant ant, floating eyeball, dragon, each
proven in a running build. `scripts/enemy.gd` is the shared base (extends
`Hazard`: touching one kills you). `room_m4_enemies.tscn` holds the first
four; `room_m4_dragon.tscn` is the boss arena, beaten only by recalling the
sword through the body. `FloorPlate` and dormant-until-approached enemies are
both built and proven (`room_m4_plate.tscn`, `room_m4_dormant.tscn`).

**`LEVELS.md` is several rounds deep**, Matt's expanded level vision, sorted
into what reuses existing mechanics, what is new scope, what conflicts with
something settled. It carries its own open-questions list; this file does not
duplicate it.

## The next action

**M5: the art spike, one room end to end.** Done-when (`BUILD_PLAN.md`): that
room is in the game at final quality, and `ART.md` carries the real number of
generations it took. Not started. `GEMINI_NOTES.md` is required reading
before the first art prompt; `ART_DIRECTION.md` governs every visual choice
made along the way.

## Blocked on Matt

1. **The open questions in `LEVELS.md`**, the ending swap (caged dragon vs.
   caged bird) chief among them, touching a decision `CLAUDE.md` currently
   marks "do not relitigate."
2. **M4 playtest feedback, not blocking, reopen if it bothers him:** the
   dragon's one-rest-period pacing, whether the ledge-to-wood throw reads as
   the intended route, whether missing a catch on purpose feels discoverable
   or feels like a trick, whether the dormant scorpion's wake-to-danger gap is
   fair.
3. **M5 itself**: which room, which enemy, is the one to spend the pipeline
   run on.

## Traps that will bite again

**Opening the project rewrites `project.godot`, and a stale editor deletes
from it.** Close the editor, `git diff project.godot`, restore, then pull.

**A new `class_name` script is invisible until a reimport.** Referencing it
before `tools/dev.sh import` fails every caller with "Could not resolve
class", which reads like a real compile error and is not one.

**A shared method cannot be overridden with extra parameters.**
`Hazard.configure(size)` takes one argument; `Enemy`'s species give their own
entry point (`place`) a different name instead, the way `Platform`'s
subclasses do with `_build`.

**A sword can park mid-air rather than fall.** `RETURNING` with an exact,
unmoving target converges to zero offset and stops there, no overshoot, no
`return_spent`: a genuinely missed, `GROUNDED` sword needs the player's
position to keep changing during the return, not just their height.
`room_m4_plate.gd`'s comment has a sequence that reliably produces a miss.

## Settled, do not relitigate

**M4:** contact with any enemy kills the hero, unconditionally. A killed
enemy is `queue_free`d, not left as a corpse, and does not return on respawn.
The dragon is immune to FLYING and RETURNING, vulnerable only to RECALLING,
one hit, no health bar; its breath is a `DragonBreath` clock, the same shape
as `GeyserCycle`. **The generator is M12's**, not M4's.

**The gates:** no art before M5, no level building before M10, G1 after M5.
`BUILD_PLAN.md` carries the reasoning, unchanged.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md` and `GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged ·
`LEVELS.md` Matt's expanded level vision, not yet decided ·
`assets/reference/` the original.
