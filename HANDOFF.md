# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-14 · **Phase:** 1, the verb · **Active milestone:** M3,
closing · **Also underway:** M4

**M3 done-when:** death to respawn to moving again is **under one second**,
measured, and dying twenty times in a row is annoying but not tedious. The
measured half is done. The felt half is Matt's alone to answer by playing,
and nothing below is waiting on it.

## Where this is

**M3 is unchanged and still open on the felt half.** See "Blocked on Matt".

**M4 got a running start while M3 waits on a playtest**, on Matt's own ask to
build ahead wherever the work does not need him. Five of six enemies are now
built, tested and proven in a running build: bat, scorpion, giant ant,
floating eyeball, and now the dragon.

`scripts/enemy.gd` is the shared base (extends `Hazard`: touching one kills
you, per SPEC.md's kill list). `scenes/rooms/room_m4_enemies.tscn` holds the
first four; CI proves contact kills regardless of side, a hit from the
scorpion's back kills it, and one from the front bounces off its armour.

**The dragon shipped on Matt's go-ahead**, in `scripts/dragon.gd` +
`scripts/logic/dragon_breath.gd`, arena in `room_m4_dragon.tscn`: a ledge,
the dragon, wood past it. `Dragon.is_vulnerable_to` checks the sword's own
state and nothing else: FLYING or RETURNING bounces off the body (fresh
ammunition, SPEC.md's mistake), only RECALLING gets through, which needs one
already embedded past the dragon and called home. The room hands out exactly
one sword, so the only throw available is the one that has to come back,
which is what makes M11's "without spending a sword" true by construction
rather than by asking a player not to take a second throw. CI proves the
bounce, the breath's kill, and the embed-then-recall kill with the sword
back in hand.

**Two geometry bugs, both found by running it, not by reasoning about it.**
A scorpion 20 px tall put its centre far enough below a standing hero's
throw height that every ground-level throw read as "from above"; fixed at
34 px, comment in `room_m4_enemies.gd`. A dragon-and-ledge gap of 22 px was
too narrow for a falling hero to land in without overshooting into the
dragon's own body; fixed by moving the dragon out to give the landing 100 px
of real floor, comment in `room_m4_dragon.gd`.

**The generator is still not built.** `BACKLOG.md` has it: it needs the
sword's unbuilt `conduct` state and Act 3's conductivity vocabulary, which
is M12's job, not a session's.

## The next action

**M3:** play all five benches (see "Blocked on Matt", unchanged from before).

**M4:** the generator is what is left, and it is blocked on M12 groundwork
rather than on anything a session here can decide.

**Level design notes:** written up in `LEVELS.md`. The biggest of the ideas
in it (a caged dragon rather than a caged bird, freed rather than fought, as
the ending) touches something `CLAUDE.md` currently calls settled, so it is
a question there rather than a decision made in this file.

## Blocked on Matt

1. **Play all five M3 benches, twenty deaths each, and answer the felt
   half.** Open from before: spacing on the first two hazards, whether 0.45 s
   reads as a warning, whether the 0.7 s ferry dock is an invitation or dead
   time, whether a missed ferry's 2.45 s is too long, whether a dormant
   geyser shaft says "way up" before you have seen one go, whether 1.6 s of
   quiet is too long when alive and late, whether a ride reads as carried or
   as a passenger, and whether `spike_grace` is a dial anybody can feel.
2. **Play the dragon bench once it can be felt rather than only measured**:
   does the ledge-to-wood throw read as the intended route or as a trick you
   have to be told; is one rest period (2.6 s) enough to line up the whole
   embed-then-recall without feeling rushed.
3. **The six open questions in `LEVELS.md`**, the ending swap chief among
   them.

## Traps that will bite again

**Opening the project rewrites `project.godot`, and a stale editor deletes
from it.** Close the editor, `git diff project.godot`, restore, then pull.
`tests/test_project_settings.gd` catches that one.

**A new `class_name` script is invisible until a reimport.** Referencing it
before `tools/dev.sh import` fails every caller with "Could not resolve
class", which reads like a real compile error and is not one.

**A shared method cannot be overridden with extra parameters.**
`Hazard.configure(size)` takes one argument; redeclaring `configure` with
more breaks static resolution for every caller. `Enemy`'s five species give
their own entry point (`place`) a different name instead, calling
`configure` unchanged, the way `Platform`'s two subclasses do with `_build`.

## Settled, do not relitigate

**M4 so far:** contact with any enemy kills the hero, unconditionally. A
killed enemy is `queue_free`d, not left as a corpse, and does not return on a
respawn; only a living enemy's position or clock resets, M3's mechanisms
bargain applied to combat. An enemy's body size is a room constant for now,
like a spike bed's, not a species-wide config number: M14 can revisit.

**The dragon:** immune to FLYING and RETURNING, vulnerable only to
RECALLING, one hit, no health bar. The breath is a `DragonBreath` clock,
the same shape as `GeyserCycle`, and resets to the first frame of its tell
on respawn for the same fairness reason.

**The gates:** no art before M5, no level building before M10, G1 after M5.
`BUILD_PLAN.md` carries the reasoning, unchanged.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md` and `GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged ·
`LEVELS.md` Matt's expanded level vision, not yet decided ·
`assets/reference/` the original.
