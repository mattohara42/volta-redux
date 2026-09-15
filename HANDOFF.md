# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 2, the look · **Active milestone:** M5

**M4 is closed**, rescoped to five enemies in `BUILD_PLAN.md`; the generator
is M12's. See git log for the reasoning if it needs re-reading.

## Where this is

**M5's background, tileset and hero have all landed**, and the hero is now
cut into rig parts too (`assets/art/hero/rig/`: `head`, `torso`, `arm_near`,
`leg_near`, `leg_far`, matching `ANIMATION.md`'s own "hips, two legs, two
arms, head", minus the far arm this true profile hides entirely). The sword
in the painting was deliberately not cut as a rig part: `CLAUDE.md` says the
sword is its own scene, and the blade was only there so the hand would come
back gripping something. Five lessons paid for and folded into `ART.md`/
`GEMINI_NOTES.md` along the way, the compositional-prior fix (state framing
positively, rule out the default by name) landing twice, once for a scene
and once for a character; `key.py`'s despill needed a real fix, a 3px pull
was not enough against a real 6-7px contamination band; and a character
painting has no backdrop between its parts for a script to find, so
`cut-rig.py`'s boxes are read off the source by eye, sized to avoid an
axis-aligned rectangle sweeping in a distant, unrelated part (the sword's
diagonal blade very nearly pulled both boots into the arm's crop).

**M5's done-when isn't fully met yet.** `BUILD_PLAN.md` wants "one rigged
hero," and what exists is the rig's *parts*, offset-preserved and ready.
Assembling them into an actual `Skeleton2D` scene in Godot, placing `Bone2D`
pivots and parenting each sprite, is still open: always the manual step
`ART.md` said it would be, not something `cut-rig.py` was ever meant to do.

**6 generations spent, 3 of 5 M5 assets landed.** Past `ART.md`'s own
budget-rule ceiling of 5 for the whole room now, not a hard stop since every
miss bought a real lesson, but worth naming plainly. Bat and the
pose-sheet test remain.

**`tools/key.py`, `tools/palette-check.py`, `tools/cut-sheet.py` and
`tools/cut-rig.py`** are all built and proven against real deliveries now.
`tools/pose-sheet.py` is still not built: the pose-sheet test delivery is
what will tell us its real shape.

**Porting from `hook-line-and-sentence`** needs that repo attached with push
access; this session's own permissions denied attaching it, though reading
it (public, unattached) was allowed and is what found the compositional
prior fix, twice. Not blocking: every tool built fresh so far has worked
first try against a real delivery.

## The next action

**Either the `Skeleton2D` assembly in Godot** (turning the rig parts now in
hand into something that actually runs), **or the bat and pose-sheet test
prompts**, mindful of the generation count above. Matt's call which comes
first. M5's done-when (`BUILD_PLAN.md`): the room is in the game at final
quality, and `ART.md` carries the real generation count.

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
4. **Skeleton2D assembly vs. the remaining two prompts**, which comes first.
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
box.** A diagonal sword reaching from the hand to past the far boot means
no axis-aligned rectangle can hold the whole blade without also holding
whatever else sits in that rectangle. Keep a part's box to just that part;
don't fold a crossing prop into it.

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
