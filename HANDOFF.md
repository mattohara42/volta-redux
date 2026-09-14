# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-14 · **Phase:** 1, the verb · **Active milestone:** M3

**M3 done-when:** death to respawn to moving again is **under one second**,
measured, and dying twenty times in a row is annoying but not tedious.

## Where this is

**Every hazard M3 names is built**: lava, spikes, the death loop, the
checkpoint, falling platforms, ferries and now geysers. Five benches, and the
loop measures 0.417 s in a real build on all of them.

**A geyser is a clock that takes your vertical speed off you.** It does not kill
(`SPEC.md`'s kill list is lava, water, spikes and animals), it lifts what is
inside the column while it erupts, and you leave it by stepping sideways out.
`scripts/logic/geyser_cycle.gd` owns the clock, `scripts/geyser.gd` the sensing
and the picture, `config/hazards.tres` four numbers, `room_m3_geysers` the bench:
two storeys, no ladder, and the second jet rises out of a lava moat.

## The next action

**The measured half of the done-when is discharged and the felt half is not**, so
nothing here is waiting on a keyboard. M3 closes when the benches have been
played, and M4, the six enemies, is next.

## Blocked on Matt

1. **Play all five benches and answer the felt half.** Twenty deaths at each
   hazard that kills. Open from before: spacing on the first two, whether 0.45 s
   reads as a warning, whether a 0.7 s dock reads as an invitation or as dead
   time, and whether the 2.45 s a missed ferry costs is too long.
2. **And three the geysers add.** Does a dormant shaft say "way up" before you
   have seen one go? Is 1.6 s of quiet too long to stand there when you are alive
   and late, which is the only time you pay it? Does a ride read as being carried
   or as being a passenger, which is what `SPEC.md` threw 1984 away over.
3. **Is `spike_grace` a dial you can feel?** `BACKLOG.md` has the experiment and
   M14 can settle it.

## Traps that will bite again

**Opening the project rewrites `project.godot`, and a stale editor deletes from
it.** One save dropped `[physics]` and `[rendering]`, taking engine gravity from
0 to 980. Close the editor, read `git diff project.godot`, restore it, then pull.
`tests/test_project_settings.gd` catches that one.

**A free-running clock has to sit out the respawn freeze, and no assertion sees
it.** The ferry left two frames before a respawn could reach the lip. A geyser
left running dies a second time in the same moat, measured. One line in `reset`
each, and neither was visible from anywhere but a running build.

**CI fails on what the log says** for the spike, falling, ferry and geyser steps,
not only on keeping the picture (the older ones do not: `BACKLOG.md`). No
screenshot shows a clock, so `tools/capture.gd` prints every mechanism's phase.

**Docs go stale silently.** `.claude/hooks/` warns on a checkout behind
`origin/main`, and on a branch committing code without touching this file.

## Settled, do not relitigate

**M3:** the loop is 0.25 s hold plus 0.15 s freeze, measured at 0.417 s, and the
death messages outlast it. A brazier lights once, so "the last lit brazier" is
the furthest one you reached. Every bench keeps a brazier between its two
hazards, and a respawn puts every mechanism back at the start of its clock.

**Geysers:** a jet does not kill, its cycle starts at the swell rather than the
quiet (so a respawn lands on the tell), the lift replaces gravity outright while
you are in the column, and a shaft's size belongs to the room the way a ferry's
span does. Steam is new in `ART_DIRECTION.md`: cool and desaturated, because warm
and saturated is reserved for what kills you.

**Closed milestones.** M2: standing on a thrown sword and recall-on-hold both
feel right, and a 16 px ledge against an 18 px hero is a fine margin. M1: you
miss by changing height, a catch beats a solid hit in the same frame, and only
flight destroys a sword. M0: a storey is climbed and never jumped, and **Lothar
of the Hill People** is the name M5 paints.

**The gates:** no art before M5, no level building before M10, G1 after M5.
`BUILD_PLAN.md` carries the reasoning, unchanged.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md` and `GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `assets/reference/`
the original.
