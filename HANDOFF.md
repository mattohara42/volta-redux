# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-15 · **Phase:** 2, the look · **Active milestone:** M5

**M4 is closed**, rescoped to five enemies in `BUILD_PLAN.md`; the generator
is M12's. See git log for the reasoning if it needs re-reading.

## Where this is

**M5 has five prompts written and logged in `ART.md`**, not yet sent: a
background and a tileset for Act 1's moat and outer wall (`SPEC.md`'s
description, still the settled one), the hero (Lothar, per `SPEC.md`: "M5
paints him"), the bat as M5's one enemy, and a throwaway pose-sheet
consistency test per `GEMINI_NOTES.md`'s open question. Each prompt is a
self-contained block in `ART.md` → *Open requests*, ready to paste into the
Gemini UI.

**`tools/key.py` and `tools/palette-check.py` are built and smoke-tested**
against synthetic images (a magenta-backdrop test subject with a soft edge,
and a planted neutral-grey patch), not yet against a real delivery.
`tools/cut-sheet.py`, `tools/cut-rig.py` and `tools/pose-sheet.py` are not
built: their shape depends on what a real sheet looks like, so building them
against a guess risks getting it wrong twice.

**Porting from `hook-line-and-sentence`** (the source `ART.md` names for
these tools) needs that repo attached to this session; this session's own
permissions denied attaching it. Not blocking: the pipeline works without the
port, and the port is a nice-to-have Matt can unblock directly if he wants it
before a real delivery forces the question anyway.

## The next action

**Matt runs the five prompts in the Gemini UI**, saves each delivery to the
path named in `ART.md`, and the session picks up from there: key each
delivery, run `palette-check.py`, cut the tileset and the bat out of their
sheets, and write up what came back against what was asked, per `ART.md`'s
own record-keeping convention. M5's done-when (`BUILD_PLAN.md`): the room is
in the game at final quality, and `ART.md` carries the real generation count.

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
3. **The five Gemini generations above**, the actual next step.
4. **Whether to attach `hook-line-and-sentence`** for the tool ports `ART.md`
   names, or let this project's versions stand as written fresh.

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
