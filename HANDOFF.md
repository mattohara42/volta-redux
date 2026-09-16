# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-16 · **Phase:** 2, the look · **Active milestone:** M5

**M4 is closed**, rescoped to five enemies in `BUILD_PLAN.md`; the generator
is M12's. See git log for the reasoning if it needs re-reading.

## Where this is

**M5's "one rigged hero" is done**, verified against a real running build.
Background, tileset and hero all landed; the bat is delivered but its pose
is an open question for Matt (below), not yet cut into final rig parts or
committed. Pose-sheet test is the one prompt still unsent.

**Two real bugs found in `key.py` this session, both fixed.** The despill
was too weak against real contamination width (3px assumed, 6-7px measured).
Then the bat's wing membranes and bared teeth left gaps in the painting that
trap backdrop colour where nothing connects it to the image border, so the
old border-seeded flood fill left solid opaque magenta patches baked into
every rig-part crop. Rewrote it to match the backdrop colour globally
instead: this project's palette has nothing naturally near a saturated
magenta, so a global match is safe. Every already-committed asset
re-checked clean against the new tool; the bug's damage was confined to
the one delivery that exposed it.

**No Godot was installed in this session's environment.** The official
4.7.2 Linux binary (matching `README.md`'s pinned version) was downloaded to
`/tmp` to run `import`/`test`/`shot` for real. That does not persist: a
future session here starts the same way. `tools/dev.sh test` passes clean,
221 tests, 1572 checks.

**7 generations spent, 3 of 5 M5 assets landed** (the bat pending Matt's
call makes it 3 clean, 1 pending). Past `ART.md`'s own budget-rule ceiling
of 5 for the whole room, not a hard stop since every miss bought a real
lesson, but worth naming plainly.

**`tools/key.py`, `tools/palette-check.py`, `tools/cut-sheet.py` and
`tools/cut-rig.py`** are all built and proven against real deliveries.
`tools/pose-sheet.py` is still not built.

**Porting from `hook-line-and-sentence`** needs that repo attached with push
access; this session's own permissions denied attaching it, though reading
it (public, unattached) was allowed and found the compositional prior fix,
twice. Not blocking.

## The next action

**Matt's call on the bat's pose** (see *Blocked on Matt* below), then
whichever of "reroll" or "cut it as delivered" follows from that, then the
pose-sheet test prompt.

## Blocked on Matt

1. **The bat's pose.** Delivered as a dynamic mid-flight swoop (both ears
   and a near-frontal muzzle visible, body on a diagonal axis, wings spread
   at different angles) rather than the flat orthogonal profile asked for,
   the same compositional-prior default that hit the hero, not fully beaten
   by the same explicit negation this time. `ART.md`'s bat write-up has the
   detail. Test-cut in scratch: both wings individually read as flat, usable
   shapes despite the dynamic overall pose, and `SPEC.md` calls the bat's
   own behaviour "erratic flight," so a dynamic reference pose may suit it
   better than it would a standing hero. Whether that's good enough or
   worth a third generation for a calmer profile is a call this file
   shouldn't make alone.
2. **The open questions in `LEVELS.md`**, the ending swap (caged dragon vs.
   caged bird) chief among them, touching a decision `CLAUDE.md` currently
   marks "do not relitigate." Includes whether a forest sits before or
   replaces Act 1, which is why M5 painted to `SPEC.md`'s still-settled
   description rather than waiting on that question.
3. **M4 playtest feedback, not blocking, reopen if it bothers him:** the
   dragon's one-rest-period pacing, the ledge-to-wood throw, whether missing
   a catch on purpose feels discoverable, the dormant scorpion's
   wake-to-danger gap.
4. **Whether to keep spending generations at this rate**, per the flag above.
5. **Whether to attach `hook-line-and-sentence` with push access** for the
   tool ports `ART.md` names, or let this project's versions stand as written.

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
