# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 2, the look · **Active milestone:** M5

**M4 is closed**, rescoped to five enemies in `BUILD_PLAN.md`; the generator
is M12's. See git log for the reasoning if it needs re-reading.

## Where this is

**M5's background and tileset have both landed.** Background on its third
attempt (`assets/art/act1/wall_moat_bg.png`); tileset first attempt, with a
bonus, 8 modules instead of the 5 asked for (`assets/art/act1/tiles/
wall_tile_1.png` through `_8.png`). Three real lessons paid for on the way,
all folded into `ART.md`/`GEMINI_NOTES.md`: a scene has a strong
compositional prior a hedged fraction barely moves, state the camera framing
positively instead; the background is atmosphere only, designed to repeat,
the tileset carries whatever the hero actually stands on; and `key.py`'s
despill was too weak, a real magenta halo survived a 3px partial pull when
the true contamination band ran 6 to 7px. Fixed with a nearest-clean-neighbour
fill instead of a partial pull, verified against both the synthetic test and
the real delivery.

**4 generations spent, 2 of 5 M5 assets landed.** `ART.md`'s own budget rule
flags more than 5 for the whole room; hero, bat and the pose-sheet test
remain. Still open, not a hard stop, Matt's call each time.

**`tools/key.py`, `tools/palette-check.py` and `tools/cut-sheet.py`** are
built and proven against real deliveries now. `tools/cut-rig.py` and
`tools/pose-sheet.py` are still not built: the hero and pose-sheet
deliveries will be what tells us their real shape.

**Porting from `hook-line-and-sentence`** needs that repo attached with push
access; this session's own permissions denied attaching it, though reading
it (public, unattached) was allowed and is what found the compositional
prior fix. Not blocking: every tool built fresh so far has worked first try
against a real delivery.

## The next action

**The hero prompt**, whenever Matt's ready, mindful of the generation count
above. `assets/art_raw/hero_lothar_idle.png` is the target; `tools/
cut-rig.py` doesn't exist yet and this delivery is what will tell us its
real shape. M5's done-when (`BUILD_PLAN.md`): the room is in the game at
final quality, and `ART.md` carries the real generation count.

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
4. **The remaining three Gemini generations**, whenever he's ready.
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

**A scene has a compositional prior; a subject on a flat field does not.**
Full details in `GEMINI_NOTES.md`. State camera framing positively and
explicitly for any full-scene painting; a hedged fraction of the frame will
not reliably move it.

**A cut edge's backdrop contamination runs wider than it looks at a
glance.** Measured 6 to 7px on a real delivery. A despill radius has to be
generous (`key.py` defaults to 10px now) or verified against real pixels,
not assumed from how clean the edge looks zoomed out.

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
