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

**M4 got a running start while M3 waits on a playtest**: the rest of M4 is
grey-box work that needs no feel-testing either, and Matt asked for exactly
that. Four of six enemies are built, tested and proven in a running build:
bat, scorpion, giant ant, floating eyeball. `scripts/enemy.gd` is the shared
base (extends `Hazard`: touching one kills you, the way SPEC.md's kill list
already has animals on it beside lava and spikes); each species is a thin
node driven by a pure logic file in `scripts/logic/`; `config/enemies.tres`
holds the tuning. `scenes/rooms/room_m4_enemies.tscn` has all four on one
floor, and CI proves three things in a real build: contact kills regardless
of side, a sword thrown at the scorpion's back kills it, and one thrown at
its front bounces off the armour instead.

**Found by running it**: a scorpion 20 px tall put its centre far enough
below a standing hero's throw height that every ground-level throw read as
"from above", and the front/back rule was unreachable without jumping first.
Fixed at 34 px; the arithmetic is a comment in `room_m4_enemies.gd`.

**The two bosses are not built.** `BACKLOG.md` has both. The dragon has a
cheap, concrete proposal: `SwordFlight` already makes a recalling sword
immune to contact ("a recall cannot fail" is the docstring), so a dragon
vulnerable only to one is nearly free. It is a design decision about how the
fight reads, so it is waiting on Matt's go rather than half-built. The
generator has no proposal: it needs the sword's unbuilt `conduct` state and
Act 3's whole conductivity vocabulary, which is M12's job, not a session's.

## The next action

**M3:** play all five benches (see "Blocked on Matt", unchanged from before).

**M4:** say go or no on the dragon proposal in `BACKLOG.md`. Roughly the size
of one of the four enemies already built, if so. The generator stays blocked
on M12 either way.

**Level design notes:** Matt has ideas, not yet typed up. Once they arrive,
write them into a notes doc (rooms and pacing per act), no in-engine
building, per his own answer on keeping this inside the M10 gate.

## Blocked on Matt

1. **Play all five M3 benches, twenty deaths each, and answer the felt
   half.** Open from before: spacing on the first two hazards, whether 0.45 s
   reads as a warning, whether the 0.7 s ferry dock is an invitation or dead
   time, whether a missed ferry's 2.45 s is too long, whether a dormant
   geyser shaft says "way up" before you have seen one go, whether 1.6 s of
   quiet is too long when alive and late, whether a ride reads as carried or
   as a passenger, and whether `spike_grace` is a dial anybody can feel.
2. **The dragon proposal in `BACKLOG.md`: go or no.**
3. **Level ideas, whenever there is a minute**, for the notes doc above.

## Traps that will bite again

**Opening the project rewrites `project.godot`, and a stale editor deletes
from it.** Close the editor, `git diff project.godot`, restore, then pull.
`tests/test_project_settings.gd` catches that one.

**A new `class_name` script is invisible until a reimport.** Referencing it
before `tools/dev.sh import` fails every caller with "Could not resolve
class", which reads like a real compile error and is not one.

**A shared method cannot be overridden with extra parameters.**
`Hazard.configure(size)` takes one argument; redeclaring `configure` with
more breaks static resolution for every caller, not just the one that added
them. `Platform`'s subclasses already dodge this with their own entry point
over a shared `_build`; `Enemy`'s four species do the same with `place`.

## Settled, do not relitigate

**M4 so far:** contact with any enemy kills the hero, unconditionally. A
killed enemy is `queue_free`d, not left as a corpse, and does not return on a
respawn; only a living enemy's position or clock resets, M3's mechanisms
bargain applied to combat. An enemy's body size is a room constant for now,
like a spike bed's, not a species-wide config number: M14 can revisit.

**The gates:** no art before M5, no level building before M10, G1 after M5.
`BUILD_PLAN.md` carries the reasoning, unchanged.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md` and `GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `assets/reference/`
the original.
