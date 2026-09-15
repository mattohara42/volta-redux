# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 1, the verb · **Active milestone:** M4

**M3 is closed** on Matt's word ("I think I played everything so far"), taken
as-is: if something from it turns out to bother him in play, the fix is to
say so and reopen it, not to assume silence means every one landed.

## Where this is

**M4: five of six enemies built**, bat, scorpion, giant ant, floating
eyeball, dragon, each proven in a running build rather than only asserted.
`scripts/enemy.gd` is the shared base (extends `Hazard`: touching one kills
you). `room_m4_enemies.tscn` holds the first four; `room_m4_dragon.tscn` is
the boss arena, one sword, beaten only by recalling it through the body
(`Dragon.is_vulnerable_to` reads the sword's own state, nothing new in the
sword's machine). The generator is still not built: it needs the sword's
unbuilt `conduct` state and Act 3's conductivity vocabulary, M12's job, not a
session's. `BACKLOG.md` has it.

**The floor plate is built**, `FloorPlate` sensing the hero's weight, an
enemy's, or a spent sword's (`SwordFlight.rests_on_a_plate`, GROUNDED only).
`room_m4_plate.tscn` proves standing on it, and the puzzle worth having:
missing a catch on purpose (climb a ladder mid-return, per `SwordFlight`'s
own "you miss by changing height") leaves the sword weighing the plate down
while you walk through what it opens.

**Dormant-until-approached enemies are built**, `LEVELS.md`'s skeleton idea
generalised to any species (`Enemy.start_dormant`, `_step_dormancy`,
`dormant_wake_range` in `config/enemies.tres`): motionless and inert to
touch, killable by a sword throughout, wakes on proximity rather than any
room-wired trigger. `room_m4_dormant.tscn` finishes the plate's other case: a
dormant scorpion sits on a plate, holding a gate open for free until the hero
gets close enough to wake it. Confirmed in a running build: the wake fires
before contact, so approach alone never kills, but closing further can catch
you the instant it wakes. Whether that read needs more warning distance is
`config/enemies.tres` tuning for M14, not a bench-time fact.

Two geometry bugs from the enemies work, both found by running it rather
than reasoning about it, are fixed and commented in `room_m4_enemies.gd`
(scorpion height) and `room_m4_dragon.gd` (ledge gap).

**`LEVELS.md` is several rounds deep**, Matt's expanded level vision, the
theme ("difficult, modern, replayable," against the original's two
failures: short, no reason to go back), and ideas sorted into what reuses
existing mechanics, what is new scope, what conflicts with something
settled. It carries its own open-questions list; this file does not
duplicate it.

## The next action

**M4:** the generator, blocked on M12 groundwork. Nothing else in M4 is
waiting on a decision right now.

**LEVELS.md:** whichever open question Matt wants to settle next, at his
pace. Not urgent, not blocking anything being built.

## Blocked on Matt

1. **The open questions in `LEVELS.md`**, the ending swap (caged dragon vs.
   caged bird) chief among them, touching a decision `CLAUDE.md` currently
   marks "do not relitigate."
2. **Anything from actually playing M4**: the dragon's one-rest-period
   pacing, whether the ledge-to-wood throw reads as the intended route,
   whether missing a catch on purpose feels discoverable or feels like a
   trick, whether the dormant scorpion's wake-to-danger gap is fair.

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

**M4 so far:** contact with any enemy kills the hero, unconditionally. A
killed enemy is `queue_free`d, not left as a corpse, and does not return on
respawn. The dragon is immune to FLYING and RETURNING, vulnerable only to
RECALLING, one hit, no health bar; its breath is a `DragonBreath` clock, the
same shape as `GeyserCycle`.

**The gates:** no art before M5, no level building before M10, G1 after M5.
`BUILD_PLAN.md` carries the reasoning, unchanged.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md` and `GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged ·
`LEVELS.md` Matt's expanded level vision, not yet decided ·
`assets/reference/` the original.
