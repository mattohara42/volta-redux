# BUILD_PLAN.md: M0 to M16

> Read `SPEC.md` first. **Work exactly one milestone at a time**, and state
> which one is active at the start of every session, with its done-when.

## The shape of the plan, and the one rule that matters

Four phases: **the verb**, **the look**, **the game**, **ship**. They are in that
order for a reason.

**No art before M5, and no level building before M10.** The previous attempt at
this project died, and the most common way a project like this dies is by
spending its energy on assets for a game whose core does not yet feel good. M0
through M4 are grey boxes and capsules. If the game is not fun as coloured
rectangles, painting it will not help, and finding that out costs four
milestones instead of ten.

**G1, the vertical slice gate, sits after M5 and it is a real gate.** One room,
finished: art, sound, hazards, an enemy, the sword. Play it. If it is not fun,
stop and rework the spec. That gate is the whole reason the phases are ordered
this way.

---

## Phase 1: the verb (M0 to M4)

Grey boxes throughout. No PNG enters the repo in this phase.

### M0: the project, and how it feels to move
Godot 4 project, git, CI (`godot --headless` runs the test scenes), one grey
room, a capsule that runs and jumps.

Movement carries **coyote time, jump buffering, variable jump height by hold
duration, and air control**, all of them exposed in one tuning resource
(`config/movement.tres`) rather than scattered through the character script.

**Done when**: a capsule crosses a grey room and the jump feels good enough that
you stop noticing it, and every number that decides that lives in one file.

### M1: throw, return, catch, consume
The sword's four base states. Flies out to max range, turns, returns to the
player's *current* position, is caught by standing in its path, is destroyed on
contact with anything solid.

**Done when**: all four states work in a grey room, the catch window is a tunable
number, and a missed catch leaves a sword on the floor you can walk over to pick
up.

### M2: the sword as a tool
Embed in wood, recall on hold, stand on an embedded sword, hit a switch across a
gap.

**Done when**: there is a grey room that **cannot be finished** without standing
on your own thrown sword, and a second one that cannot be finished without
recalling it while it holds a switch down.

### M3: hazards and the death loop
Lava, spikes, geysers, moving and falling platforms. Braziers as checkpoints, lit
by walking past. Instant respawn with swords restored.

**Done when**: death to respawn to moving again is **under one second**, measured,
and dying twenty times in a row is annoying but not tedious.

### M4: the enemies
Five of `SPEC.md`'s six, as coloured shapes with real behaviour: bat, scorpion,
giant ant, floating eyeball, dragon. The eyeball has to actually eat a returning
sword. The sixth, the generator, is Act 3's boss and needs the sword's `conduct`
state and the conductivity vocabulary that don't exist until M12. It ships
there, not here: building it now would mean doing M12's work under M4's name.

**Done when**: each of the five is beatable, each punishes the mistake its row
names, and the grey rooms proving them are survivable with three swords.

---

## Phase 2: the look (M5 to M9)

### M5: the art spike, one room end to end
**One** room, fully drawn. One background, one tileset, one animated hero, one
enemy. The point is to run the whole pipeline once (`ART.md`) before committing
to eighteen rooms of it, and to find out what a room actually costs.

**Done when**: that room is in the game, at final quality, and `ART.md` carries
the real number of generations it took.

**Reopened 2026-09-26 for pixel art.** The first pass was painted (Gemini, 4x,
a cutout rig) and it is done and recorded in `ART.md`. The switch to Sprite
Fusion and pixel art (`ART_DIRECTION.md`) means the same room is redrawn once
more, through the new pipeline, with the same done-when plus credits spent.
This PR is also where the project's texture filter flips to Nearest.

**Closed 2026-09-28**, in pixel art: Matt called the room final quality.

### 🚧 G1: the vertical slice gate
Take M5's room, add sound, and play it for an hour. **This is a decision point,
not a milestone.** Fun: continue to M6. Not fun: the fault is in `SPEC.md` and
that is where the fix goes. Do not proceed on the theory that seventeen more
rooms will fix one that is not fun.

**Passed** on the painted art. The art change does not reopen it: G1 judged
the game, not the picture.

### M6: the hero, animated
Idle, run, jump, fall, land, throw, catch, climb, die, the somersault and the
dive, all as pixel-art frame animations on the existing `AnimationTree` state
machine (`ANIMATION.md`). The seven rig states already built are replaced, and
the state logic behind them (`Locomotion`) carries over.

**Done when**: every state transitions cleanly into every other state it can
reach, and the somersault reads as a somersault at game size in a screenshot,
not just in the editor.

### M7: the enemy sheet
Six enemies, derived from one another so they match (`ART.md`: a sheet if
Sprite Fusion takes one, the style reference operation if not). Animated in
frames, wired to the M4 behaviours.

**Done when**: the six are on screen, distinguishable at game size, and
consistent with each other in treatment.

**Built for all six** (2026-09-28, the generator 2026-09-30): scorpion, ant,
eyeball, dragon and bat are on screen in `RoomM7Sheet`, wired to their M4
behaviours; the generator stands beside them as a sprite, its behaviour being
M12's. Awaiting Matt's eye on "consistent in treatment" (`ART.md`).

### M8: environments
Tilesets for the four acts, parallax backgrounds, props. The acts have to look
like four different places.

**Done when**: a screenshot from each act is unmistakably its own act.

### M9: lava, electricity, atmosphere
**Shaders and particles, not art.** Bubbling lava is a scrolling noise
displacement on a gradient plus a particle emitter plus heat haze. Arcs, sparks
and charged surfaces are the same. Nothing in this milestone is a generated
asset, and if something here is being drawn as a PNG loop, that is the bug.

**Done when**: the lava bubbles, the generator arcs, and neither is a texture
someone drew frame by frame.

**Built 2026-09-28, ahead of M8 (which needed credits)**: the lava bubbles, an
arc and a charged surface are shaders and particles with a test that no effect
loads an image (`ART.md`). The arc is ready for the generator to use; the
generator itself is M12's.

**Extended 2026-10-05**: a coloured dark that lights push back (`LightField`),
code-drawn far layers for Acts 2 to 4 until they are painted (`Backdrop`), and
bursts for every event the player should notice (`Burst`). `ART.md` has the
light layer's write-up.

---

## Phase 3: the game (M10 to M14)

### M10: Act 1, the moat and the outer wall
Four rooms, built for real. The teaching act.

**Done when**: someone who has never played it gets through Act 1 without being
told what the sword does.

**Room 1 built 2026-09-28**: `Act1Bank`, the moat bank. A safe bank to throw
from, then a culvert with a sleeping scorpion that only a throw in its back
gets you past, a checkpoint, and a sally port with an awake one. Existing art
only; waiting on Matt's play before rooms 2 to 4.

### M11: Act 2, the lava caverns
Five rooms plus the dragon.

**Done when**: playable start to finish, and the dragon is beatable without
spending a sword on it.

### M12: Act 3, the generator
Six rooms plus the generator boss. The conductivity vocabulary.

**Done when**: playable start to finish, and the boss cannot be beaten by
throwing.

### M13: Act 4, the Hall of Volta
Three rooms, Volta, the three gems, the cage, the ending.

**Done when**: the game can be completed from a new save.

### M14: the pass
Play the whole thing repeatedly. Retune every room. This is where a game becomes
good and it is not optional.

**Done when**: three full playthroughs with no note worth writing down.

---

## Phase 4: ship (M15, M16)

### M15: audio
Music per act, and the sound the sword makes. **The throw, the catch, the embed
and the recall need four distinguishable sounds**, because the sword's state is
information the player needs without looking.

**Done when**: you can play with the screen dimmed and still know where your
sword is.

**Built 2026-10-05, ahead of M14 at Matt's request**: every sound and every act's
loop is rendered from code by `tools/synth/` (`assets/audio/README.md`), the
sword's four states built to differ, a fly loop panned with a sword in the air,
ambience beds and loops on lava and current. Nobody has listened yet, so the
done-when is still Matt's to answer.

### M16: menus, saves, export
Title, pause, options, key remapping, save per act. Web export and desktop
builds. Netlify or itch.io.

**Three pieces pulled forward 2026-10-05**: an opening card over the first room
(`OpeningCard`), a pause menu with the two volume levels (`PauseMenu`), and the
save per act (`SavePoint`), so M14's playthroughs need not be one sitting.
Launching resumes the act; the pause menu's NEW GAME starts over. The title
screen, key remapping and export are untouched.

**Done when**: it is at a URL and someone else has finished it.

---

## Rough sizing

Phase 1 is small and fast, and it is where the game is decided. Phase 2 is the
one with the round trips through the image generator in it. Phase 3 is the
longest by wall clock and the least uncertain. **If time runs short, cut rooms
from Acts 2 and 3, never milestones from Phase 1.** A short game with a good verb
is a game. A long one without is the 1984 original.
