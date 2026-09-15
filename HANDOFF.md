# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 2, the look · **Active milestone:** M5

**M4 is closed**, rescoped to five enemies in `BUILD_PLAN.md`; the generator
is M12's. See git log for the reasoning if it needs re-reading.

## Where this is

**M5's background has landed**, on its third attempt: `assets/art_raw/
act1_wall_moat_bg.jpg` (raw) and `assets/art/act1/wall_moat_bg.png`
(imported, no keying needed, it's a full opaque painting). Two real lessons
paid for on the way, both folded into `ART.md`/`GEMINI_NOTES.md` so they
don't get repaid: a scene has a strong compositional prior a hedged fraction
barely moves, state the camera framing positively instead; and the
background is atmosphere only, designed to repeat, the tileset carries
whatever the hero actually stands on, not the background.

**Worth a look before going further: three generations for one asset.**
`ART.md`'s own budget rule says more than five generations for the whole
room is the signal to stop and revise the plan, not push through. Background
alone took three; tileset, hero, bat and the pose-sheet test are still
unsent, so even a clean run on all four puts M5 at 7. Not treated as a hard
stop, flagged in `ART.md`'s *Open requests* and here so it isn't missed.

**Tileset, hero, bat and the pose-sheet test prompts are written**, logged
in `ART.md` → *Open requests*, not yet sent.

**`tools/key.py` and `tools/palette-check.py` are built and proven** against
both synthetic images and this real delivery (0.01% neutral-dark pixels,
clean). `tools/cut-sheet.py`, `tools/cut-rig.py` and `tools/pose-sheet.py`
are still not built: their shape depends on what a real sheet looks like,
and the tileset delivery will be the first one that needs `cut-sheet.py`.

**Porting from `hook-line-and-sentence`** needs that repo attached with push
access; this session's own permissions denied attaching it, though reading
it (public, unattached) was allowed and is what found the compositional
prior fix. Not blocking.

## The next action

**Matt's call on the generation count**, then the tileset prompt, whenever
he's ready: same round trip, `tools/key.py` and `cut-sheet.py` (not built
yet) turn it into individual tile pieces. M5's done-when (`BUILD_PLAN.md`):
the room is in the game at final quality, and `ART.md` carries the real
generation count.

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
4. **The remaining four Gemini generations**, whenever he's ready.
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
