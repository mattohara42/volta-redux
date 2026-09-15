# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 1, the verb · **Active milestone:** M4

**M4 done-when:** each of the six enemies is beatable, each punishes the
mistake its row names, and a grey room with all six is survivable with
three swords. Five of six built and proven; the generator is what is left.

## Where this is

**M3 is closed.** Matt played all five benches tonight and called dying
twenty times in a row "not tedious." Both halves of its done-when answered.

**M4 has five of six enemies built and proven**: bat, scorpion, giant ant,
eyeball, dragon. `scripts/enemy.gd` is the shared base. **The generator is
the only one left and needs the sword's unbuilt `conduct` state**, M12's
job: no proposal exists beyond SPEC.md's one line and `BACKLOG.md`'s
switches-that-need-current entry.

**Tonight's M3 playtest filed five things in `BACKLOG.md`**: a `room_m2_gap`
ladder that does not hold at the top, a falling platform that snaps back
instead of reforming, a rail-vs-gears question on the ferry, an idea for a
jump-off geyser platform, and a longer death-and-difficulty conversation.
v1 stays exactly what SPEC.md already says; a separate "Punishing Mode,"
unlocked after finishing the game once, joins the deferred shelf. Neither
`SPEC.md` nor `CLAUDE.md` changed.

## The next action

**M4:** the generator, blocked on M12 groundwork. **Level design notes** in
`LEVELS.md`, unchanged, still waiting on Matt.

## Blocked on Matt

1. **Play the dragon bench once it can be felt, not only measured**: the
   ledge-to-wood throw and the rest period before embed-then-recall.
2. **The six open questions in `LEVELS.md`**, the ending swap chief among them.
3. **Whether checkpoint braziers are right at all**, once real Act 1 rooms
   exist rather than M3's dying-focused benches. Matt's own reservation, in
   `BACKLOG.md`.

## Traps that will bite again

**Opening the project rewrites `project.godot`; a stale editor deletes from
it.** Close the editor, `git diff project.godot`, restore, then pull.
`tests/test_project_settings.gd` catches it.

**A new `class_name` script is invisible until a reimport**, failing every
caller with "Could not resolve class," which is not a real error. **A
shared method cannot take extra parameters in an override**: give a
subclass its own entry point (`place`, `_build`) instead of redeclaring
`Hazard.configure(size)`.

**Godot writes a `.uid` sidecar the moment it opens a script that lacks
one.** Opening the editor before pulling a branch that tracks those same
paths collides on checkout. Fetch and pull first.

## Settled, do not relitigate

**M4 so far:** contact with any enemy kills the hero, unconditionally. A
killed enemy is `queue_free`d, not a corpse, and does not return on respawn.
Body size is a room constant for now, not species-wide: M14 can revisit.
The dragon is immune to FLYING and RETURNING, vulnerable only to RECALLING,
one hit, no health bar.

**The gates:** no art before M5, no level building before M10, G1 after M5.
`BUILD_PLAN.md` carries the reasoning, unchanged.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md` and `GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged ·
`LEVELS.md` Matt's expanded level vision, not yet decided ·
`assets/reference/` the original.
