# HANDOFF.md

> **Rewrite this file, never append.** State snapshot and pointers only. No
> session narrative, that is what `git log` is for. Keep it under 80 lines.

**Updated:** 2026-09-28 · **Phase:** 2, the look · **Active:** M5, reopened
for pixel art. **Done when:** the M5 room is in the game at final quality in
pixel art, and `ART.md` carries the generations and credits it took
(`BUILD_PLAN.md`).

## Where this is

**The art direction pivoted from painted to pixel art**, so the Sprite Fusion
API can be the generator. Decided by Matt on 2026-09-26: frames replace the
cutout rig, art is native 640x360 at 1x, the coloured-dark rule stays. The docs
say so (`ART_DIRECTION.md`, `ANIMATION.md`, `ART.md`, `BUILD_PLAN.md`); no
code or asset has changed yet. M6 is paused with seven rig states in
(`hero_rig.tscn`), and those get replaced by frame animations when M6 resumes.
The rig's state logic (`Locomotion`) carries over.

## The next action

**Hero size is decided: 34 to 40 px on the size-32 canvas, chunky
proportions** (`ART_DIRECTION.md`, *Scale and resolution*). The next request
(needs credits) is one `edit` at size 32 with two inputs: profile variation
1 for the side-view pose, and a polished three-quarter one (6) for the look.
That fixes the stance and measures the real height in one go. Then an idle
`animate` of it, filmstripped at game size for boiling (`ANIMATION.md`).

## Blocked on Matt

1. **Credits: 0.** Every request costs 15.
2. **Backgrounds.** The API only outputs 16, 32 or 64 px, so it cannot make
   a 640x360 background. Structural, Matt's call.
3. **`LEVELS.md`'s open questions**, the ending swap chief among them.
4. **M4 playtest feedback**: the dragon's pacing, the ledge-to-wood throw
   and the dormant scorpion's wake-to-danger gap.

## Traps that will bite again

**No Godot is preinstalled**; fetch the 4.7.2 Linux binary fresh each
session. **Opening the project rewrites `project.godot`**, and a stale
editor deletes from it: close the editor, `git diff project.godot`, restore,
then pull. **A new `class_name` script fails every caller with "Could not
resolve class" until a reimport**, which reads like a compile error and isn't.

**Generated frames may look right one at a time and boil in motion**, test
by moving them: `tools/capture.gd --filmstrip=N` does that without a Godot
editor session. **A tileset module's drawn line will not land on the
collision line by construction**: measure the pixel row. **Godot's
`debug/gdscript/warnings/*` settings do not surface through this headless
pipeline**; `tests/test_repo_typing.gd` substitutes a text scan instead.
**Reading a public repo of Matt's needs no permission grant**: anonymous
clone through this session's proxy already works, `add_repo` with `push` is
only for write access.

## Settled, do not relitigate

**M4:** contact with any enemy kills the hero, unconditionally; the dragon
is vulnerable only to RECALLING; the generator is M12's, not M4's. **The
gates:** no art before M5, no level building before M10. **G1:** passed on
feel, not on an hour of play. **Generation budget:** not a hard gate, push
past it without stopping to ask.

## Pointers

`SPEC.md` what the game is · `BUILD_PLAN.md` what to build next ·
`ART_DIRECTION.md` how it looks · `ANIMATION.md` what moves ·
`ART.md`/`GEMINI_NOTES.md` before any art · `CLAUDE.md` how to work here ·
`README.md` running it · `BACKLOG.md` raised and not judged · `LEVELS.md`
Matt's expanded level vision, not yet decided · `assets/reference/` original.
