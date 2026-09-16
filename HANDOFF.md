# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-16 · **Phase:** 2, the look · **Active:** G1, the
vertical slice gate. Not a milestone, a decision point (`BUILD_PLAN.md`):
play `room_m5_wall.tscn` for real and judge whether it is fun.

## Where this is

**M5 is closed**, done-when met: `scenes/rooms/room_m5_wall.tscn`
(`scripts/room_m5_wall.gd`) assembles all five spike assets, background,
tileset floor and ledge, ladder, hero, bat, into one `Bench`. Matt's call on
the open structural question: the assembly was M5's own remaining work.

**The rig swap went in globally**, not scoped to the new room: `Player` and
`Bat` show their painted `Skeleton2D` rig in every Phase 1 bench now,
hiding the old grey capsule/diamond whenever a rig is present. `ART.md` has
the write-up: rig scale and position read off the rig scenes' own recorded
offsets, the floor tile's ledge lip measured against the collision line
rather than eyeballed.

**Verified against a real build**: `tools/dev.sh test` 221 tests, 1572
checks clean; `tools/dev.sh shot` against both rooms shows the right scale
and no regressions in the M4 bench's other three enemies.

## The next action

**Play `room_m5_wall.tscn` for the G1 verdict**, blocks M6, a feel
criterion and not the code's to answer. G1 also asks for sound added first;
none is in this room yet, worth deciding whether to add some or judge
without it.

## Blocked on Matt

G1's fun verdict is above. None of the rest block anything yet.

1. **Generation rate**: 10 for M5 against a soft ceiling of 5. Decide
   before M7's six-enemy sheet.
2. **`LEVELS.md`'s open questions**, the ending swap chief among them.
3. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw,
   the dormant scorpion's wake-to-danger gap.
4. **`hook-line-and-sentence` push access**; read access already covered it.

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
Matters again for M6's action poses and M7's six enemies. **A cut rig
looks right at rest and wrong the moment something moves**,
test by moving it, not by reassembling it still (relevant to M6); **some
part boundaries have no silhouette gap or colour split to cut by** (the
bat's wing seam, fixed with a hand-traced polyline, `ART.md` and
`BACKLOG.md` have the rest). **A tileset module's own painted line will not
land on the collision line by construction either**: measure the pixel row,
don't eyeball it (`BACKLOG.md` has the note on a real tool for M10).

## Settled, do not relitigate

**M4:** contact with any enemy kills the hero, unconditionally; the dragon
is vulnerable only to RECALLING; the generator is M12's, not M4's. **The
gates:** no art before M5, no level building before M10.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `LEVELS.md`
Matt's expanded level vision, not yet decided · `assets/reference/` the original.
