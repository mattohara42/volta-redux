# ANIMATION.md: how things move on screen

> Companion to `ART_DIRECTION.md`. Together they are the source of truth for
> every moving thing on screen. This file exists because getting this wrong is
> the most expensive mistake available on this project.

## The rule

**Characters animate in frames. Objects move by transform. Atmosphere is
code.**

Every character state (idle, run, jump, throw, the somersault) is a short
`SpriteFrames` animation of pixel-art frames. Anything rigid (the sword, a
falling platform, a gate) is one sprite moved, flipped or rotated by code.
Lava, arcs and sparks stay shaders and particles, per `CLAUDE.md`.

**Changed 2026-09-26, from rigged to frames.** The first rule was "continuous
motion is rigged, discrete acrobatics are painted frames," with the hero as a
`Skeleton2D` cutout. It moved with the art direction (`ART_DIRECTION.md`):
bone rotation shears and resamples pixels, so a pixel-art cutout rig looks
wrong the moment a limb turns, and the new generator (`ART.md`) animates a
still sprite into frames directly. The seven rig states M6 built are the
thing this replaces. The `AnimationTree` state machine and `Locomotion`'s
state logic are not: they pick which animation plays, and frames do not
change that.

## Why frames are back on the table, and the risk that came with them

The old rule was settled by a measurement: Gemini repaints the whole canvas on
every edit, so separately generated frames wander 1 to 3 px against each other,
which reads as boiling across a run cycle (the full quote is in
`GEMINI_NOTES.md`, *Editing an attached painting*). Two things are different
now. Sprite Fusion's *animate* operation makes every frame of a motion in one
request, from one still, rather than one frame per round trip. And a 40 px
pixel sprite is small enough that a stray pixel can be fixed by hand, which a
2560 px painting was not.

**Neither of those is measured yet.** Boiling is still the failure to look for
first. The first animated delivery gets played back at game size and
filmstripped (`tools/capture.gd --filmstrip=N`) before anything else is built
on top of it, and what it shows goes into `ART.md`'s generator notes.

## What each animation is

| animation | how | note |
|---|---|---|
| idle, breathing | frames | Two to four frames. Almost nothing moves |
| run | frames | The workhorse. Its pace has to match ground speed (PR #52 found this once already) |
| jump, fall, land | frames | Three distinct poses that must read as three actions (PR #55) |
| throw | frames | The wind-up matters more than the release. Telegraph it |
| catch | frames | Must be readable in one frame. See M15 on the audio |
| climb | frames | |
| **somersault** | **frames, about 6** | The signature move of the original. Earn it |
| **dive** | **frames, about 4** | A fall past a threshold speed becomes this |
| **death** | **frames, about 5** | Plays inside `death_hold` in `config/death.tres`, 0.25 s, so five frames is 20 fps. One per hazard family would be better. One is fine for v1 |
| **enemies** | frames | All six. A bat is two or three wing frames |
| **the sword in flight** | **one sprite, rotated** | Never generate rotation frames. It is a transform. `ART_DIRECTION.md` flags the shimmer to check |

## The somersault is a state, not a costume

The original's somersault was decoration: it looked different and behaved like a
jump. Here it is **a distinct movement state with its own physics**, because a
move that looks that different should behave differently or the animation is
lying.

Proposed, and to be settled by feel in M0 rather than by argument now: the
somersault is what a jump becomes when you are already at run speed. It travels
further, it rises less, and **you cannot throw during it**. That last clause is
the interesting one, because it makes the game's best-looking move also its most
committed, and committing is exactly what the 1984 game was criticised for. The
difference is that here it is a choice you make rather than the only jump you
have.

## Godot specifics

- **Every character is an `AnimatedSprite2D`** with a `SpriteFrames` resource,
  one named animation per state. Facing is `flip_h`, never a second set of
  frames.
- **One `AnimationTree` state machine per character**, and the character script
  sets parameters on it. Each state's animation sets the sprite's `animation`
  and `frame` properties, so the tree stays the only thing deciding what is on
  screen. The script must never call `AnimationPlayer.play()` or
  `AnimatedSprite2D.play()` directly. Two things deciding what is on screen is
  how you get a character stuck in a throw pose.
- **Cross-fades are gone.** A blend between two frame animations is a
  double exposure, so state transitions are cuts, timed to land on a frame
  boundary.

## The rule from the fishing project that transfers unchanged

**An actor and its sound are one event off one tick, never two schedules.** The
catch sound and the catch frame come off the same signal. If the sound is
scheduled by a timer and the animation by the state machine, they will drift, and
a catch that sounds a frame late feels like a catch you did not earn.

## Who authors a keyframe

**Frames come from the generator, timing is text.** The frames are PNGs out of
Sprite Fusion (`ART.md`). Which frames make up an animation, and how fast they
play, are written as text into the `.tres`/`.tscn`, as the rig animations were,
because Claude cannot drive the Godot editor from this session.

The guardrails built for the rig stay until the rig is deleted:
`tests/test_rig_track_parity.gd` (every animation keys the same tracks, the rule
behind PR #51) and `tests/test_repo_tscn_hygiene.gd` (no key declared twice in
one block, PR #53). The hygiene test outlives the rig. Whether track parity
still means anything for frame animations is a question for when the first
frame-based character is built. `tools/capture.gd --filmstrip=N` matters more
now, since boiling only shows in motion.
