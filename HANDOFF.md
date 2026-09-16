# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-16 · **Phase:** 2, the look · **Active milestone:** M5

**M4 is closed**, rescoped to five enemies in `BUILD_PLAN.md`; the generator
is M12's. See git log for the reasoning if it needs re-reading.

## Where this is

**All five of M5's prompts are landed and rigged**, in 10 generations
against the plan's soft ceiling of 5, each miss past the first buying a
real lesson (below, under Traps). Background, tileset, hero, bat and the
pose-sheet test are all in `assets/art/`; both the hero and the bat are
real `Skeleton2D`s (`scenes/hero_rig.tscn`, `scenes/bat_rig.tscn`), each
verified by an actual screenshot against a real build. `tools/key.py`,
`tools/palette-check.py`, `tools/cut-sheet.py` and `tools/cut-rig.py` are
built and proven; `tools/pose-sheet.py` is still not, M6 will tell us its
real shape.

**What's not done: `BUILD_PLAN.md`'s literal M5 done-when**, "that room is
in the game, at final quality." Every asset has its own verification
scene; nothing yet places the background, tileset-as-platforms, hero and
bat together in one assembled room. Whether that assembly is M5's own
remaining work or the next milestone's first slice is worth asking Matt.

**No Godot is preinstalled here.** The official 4.7.2 Linux binary
(matching `README.md`'s pinned version) has to be fetched fresh each
session to run `tools/dev.sh import`/`test`/`shot` for real; it does not
persist. `tools/dev.sh test` passes clean right now, 221 tests, 1572
checks.

## The next action

**Whether M5's done-when needs an assembled room, or is satisfied by five
landed, verified assets.** Matt's call, per the flag above.

## Blocked on Matt

1. **M5's done-when**, per the flag above.
2. **The open questions in `LEVELS.md`**, the ending swap (caged dragon vs.
   caged bird) chief among them, touching a decision `CLAUDE.md` currently
   marks "do not relitigate." Includes whether a forest sits before or
   replaces Act 1, which is why M5 painted to `SPEC.md`'s still-settled
   description rather than waiting on that question.
3. **M4 playtest feedback, not blocking, reopen if it bothers him:** the
   dragon's one-rest-period pacing, the ledge-to-wood throw, whether missing
   a catch on purpose feels discoverable, the dormant scorpion's
   wake-to-danger gap.
4. **Whether to keep spending generations at this rate**, 10 for one room
   against a soft ceiling of 5.
5. **Whether to attach `hook-line-and-sentence` with push access**, for the
   tool ports `ART.md` names. Read access (public, unattached) was enough to
   confirm its camera-framing fix and find nothing else `GEMINI_NOTES.md`
   didn't already carry. Not blocking.

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

**A scene, or a character, has a compositional prior; a subject on a flat
field does not, and it can still win even after the fix that beat it once.**
Full details in `GEMINI_NOTES.md`. State framing positively and explicitly,
rule out the default by name; a dynamic-action subject (mid-flight, wings
spread) carries an even stronger prior than a standing pose did.

**A cut edge's backdrop contamination runs wider than it looks at a
glance, and it hides inside enclosed gaps a border flood never reaches.**
`key.py` now matches the backdrop colour globally rather than flooding from
the border, and decontaminates a generous ring (10px default) around every
match. Re-verify against real pixels, not how clean an edge looks zoomed
out; a wing's finger-gaps or an open mouth are exactly where this bites.

**A held prop crossing the body can drag an unrelated part into a rig
box, or leave a gap when you fix that by moving the box instead of masking
the prop.** Full write-up in `ART.md`'s cut-rig section. Reassemble cut
parts on one canvas at their recorded offsets before trusting them; a gap
between two parts is invisible looking at either one alone.

**A rig looks right sitting still and wrong the moment something moves.**
Two overlapping boxes composite fine at rest, since only the topmost
part's pixels show where they cover the same spot, but if the covering
part ever rotates away (a wing, not a static torso), whatever the other
box baked in underneath is now visible and stuck in place. Test a cut rig
by moving something in it, not only by reassembling it at rest.

**Some part boundaries have no silhouette gap and no colour split to find
them by.** A bat's wing membrane attaches to its body directly, one
continuous shape; a box edge always cuts wrong and the two parts' colours
land too close together for a threshold. Only fix found: trace the
artwork's own drawn seam (a fold, a change in line weight) as a hand-picked
polyline and use it as a per-pixel keep/exclude boundary instead of a box
edge. `ART.md`'s bat section has the full method; `BACKLOG.md` has the
tool-generalisation note.

**A Godot 4.7.2 `Skeleton2D` errors on every leaf `Bone2D`, harmlessly.**
"No Bone2D children... cannot calculate bone length" then `ERROR: Condition
"det == 0" is true` from `affine_invert`, on load, every time, regardless of
`rest`/`length`/`bone_angle`/`autocalculate_length_and_angle`. Reproduced in
a three-line scene. The render is correct and `capture.gd` still exits 0;
it's engine log noise, not a rig bug, confirmed rather than assumed.

## Settled, do not relitigate

**M4:** contact with any enemy kills the hero, unconditionally. A killed
enemy is `queue_free`d, not left as a corpse, and does not return on respawn.
The dragon is immune to FLYING and RETURNING, vulnerable only to RECALLING,
one hit, no health bar. **The generator is M12's**, not M4's.

**The gates:** no art before M5, no level building before M10, G1 after M5.
`BUILD_PLAN.md` carries the reasoning, unchanged.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md` and `GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged ·
`LEVELS.md` Matt's expanded level vision, not yet decided ·
`assets/reference/` the original.
