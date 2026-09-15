# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 2, the look · **Active milestone:** M5

**M4 is closed**, rescoped to five enemies in `BUILD_PLAN.md`; the generator
is M12's. See git log for the reasoning if it needs re-reading.

## Where this is

**M5's "one rigged hero" is done.** Background, tileset and hero landed;
the hero is cut into rig parts (`assets/art/hero/rig/`) and assembled into
a real `Skeleton2D` (`scenes/hero_rig.tscn`, framed for screenshots by
`scenes/hero_rig_test.tscn`), verified against an actual running build, not
just written and assumed correct. Bat and the pose-sheet test are what's
left of M5's five prompts.

**No Godot was installed in this session's environment.** The official
4.7.2 Linux binary (matching `README.md`'s pinned version) was downloaded to
`/tmp` to run `import`/`test`/`shot` for real. That does not persist: a
future session here starts the same way, no `$GODOT` until it fetches one.
`tools/dev.sh test` passes clean, 221 tests, 1572 checks, after all of this.

**Six lessons paid for and folded into `ART.md`/`GEMINI_NOTES.md`/here:**
a scene or a character has a compositional prior a hedged instruction
barely moves, state framing positively and rule out the default by name;
the background is atmosphere only, the tileset carries the path; `key.py`'s
despill needed a real fix, three-px was not enough against a real 6-7px
contamination band; a character painting has no backdrop between its parts,
so `cut-rig.py`'s boxes are read off by eye, and a prop crossing the body
(the held sword) can drag an unrelated part into a box that holds both
ends of it; **reassembling cut parts on one canvas before trusting them
catches gaps a part-by-part look never will** (the leg boxes left a real
gap between torso and legs, invisible until composited); and a Godot 4.7.2
`Skeleton2D` logs a harmless but alarming `det == 0` error for every leaf
`Bone2D`, confirmed by a three-line reproduction, not a sign of a rig bug.

**6 generations spent, 3 of 5 M5 assets landed.** Past `ART.md`'s own
budget-rule ceiling of 5 for the whole room now, not a hard stop since every
miss bought a real lesson, but worth naming plainly.

**`tools/key.py`, `tools/palette-check.py`, `tools/cut-sheet.py` and
`tools/cut-rig.py`** are all built and proven against real deliveries.
`tools/pose-sheet.py` is still not built: the pose-sheet test delivery is
what will tell us its real shape.

**Porting from `hook-line-and-sentence`** needs that repo attached with push
access; this session's own permissions denied attaching it, though reading
it (public, unattached) was allowed and is what found the compositional
prior fix, twice. Not blocking: every tool built fresh so far has worked
first try against a real delivery.

## The next action

**The bat and pose-sheet test prompts**, mindful of the generation count
above, are what's left of M5's five. Once they land, M5's remaining
done-when is `ART.md` carrying the real generation count, which it already
does as it goes.

## Blocked on Matt

1. **The open questions in `LEVELS.md`**, the ending swap (caged dragon vs.
   caged bird) chief among them, touching a decision `CLAUDE.md` currently
   marks "do not relitigate." Includes whether a forest sits before or
   replaces Act 1, which is why M5 painted to `SPEC.md`'s still-settled
   description rather than waiting on that question.
2. **M4 playtest feedback, not blocking, reopen if it bothers him:** the
   dragon's one-rest-period pacing, the ledge-to-wood throw, whether missing
   a catch on purpose feels discoverable, the dormant scorpion's
   wake-to-danger gap.
3. **Whether to keep spending generations at this rate**, per the flag above.
4. **The remaining two Gemini generations**, whenever he's ready.
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
field does not.** Full details in `GEMINI_NOTES.md`. State framing
positively and explicitly, then rule out the default by name; a hedged
instruction will not reliably move it.

**A cut edge's backdrop contamination runs wider than it looks at a
glance.** Measured 6 to 7px on a real delivery. A despill radius has to be
generous (`key.py` defaults to 10px now) or verified against real pixels,
not assumed from how clean the edge looks zoomed out.

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
