# BACKLOG.md

Mid-build ideas land here, never in the active milestone. Nothing in this file is
committed to.

## Deferred from v1 deliberately

- **A forgiving mode**, for a kid. Checkpoint density, hazard lethality and sword
  count are already the three dials that would do it. Stays here until the game
  exists, because a difficulty mode built before the base difficulty is tuned is
  two untuned games.
- **Per-hazard death animations.** v1 has one. Lava, spikes and falls all
  deserve their own.
- **Sword variants.** A heavier sword that does not return. A pair thrown
  together. Both are real design space and both would dilute a single clean verb
  before that verb has proved itself.
- **A speedrun timer and ghost.** Fits the game's shape well. Post-ship.

## Ideas not yet judged

- **Ricochet off metal surfaces**, for angle puzzles. Listed in `SPEC.md` as one
  of the sword's five behaviours but cut down to four for v1. Add it only if Act
  3 turns out thin.
- **More ways up than ladders**: magical portals, elevators, and geysers used as
  traversal rather than only as hazards. Raised when the two-scale rule went into
  `SPEC.md`: the jump owns holes, plinths and short steps, a storey needs
  something else, and right now that something else is almost always a ladder.
  A single answer to every vertical problem is monotonous in a game whose pitch
  is reasoning through unexpected furniture.

  **Geysers are the cheap one and are already in `SPEC.md`** as an Act 2 hazard
  that hurls you. Using one deliberately as a route costs no new system, only a
  room built to mean it. Portals and elevators are new systems, and a new system
  in a one-verb game is the exact scope risk that killed the first attempt, so
  neither is committed to.

  **M3 built the geyser, so the cheap one is no longer hypothetical.** A jet is
  a clock with a lift speed and a room-owned shaft, and `room_m3_geysers` is two
  storeys gained with no ladder in the room. Whether that is a good way to climb
  rather than merely a working one is still a question for playing.

  Judge this after G1, when it is known whether climbing is as dull as
  `SPEC.md` warns it might be. If it is, this is the fix. If it is not, ladders
  and geysers are enough.

- **Spikes where lava cannot go**, which is the only reason to have both. A bed
  bolts to any surface, so the interesting placement is teeth on top of the ledge
  you have to land on: the landing becomes the puzzle and there is no gap to
  read. M3's spike bench does not do this, because the arithmetic says it cannot.
  A 32 px step with a five-tooth bed on it needs the jump to stay above 41 px for
  50 px of travel, and the 56 px jump manages 47.2, leaving a takeoff window of
  two or three frames. That is the 1984 complaint `SPEC.md` exists to throw away.

  It wants a moving platform to arrive on, or a sword ledge, not a wider bed.
  Revisit when the rest of M3's hazards exist. If M14 ever raises the jump this
  becomes possible, and it is a reason to check rather than a reason to raise it.

- **`spike_grace` may be a dial nobody can feel.** It holds the killing box 3 px
  below the points so a jump that brushes them lives. Setting it to zero and
  re-sweeping the M3 spike bench moved the takeoff window by nothing at all: the
  only approach it can affect is a jump arc crossing a bed near its apex, and
  nothing else meets a bed slowly from above. Either it is doing invisible good
  work or it is a number for its own sake, and only playing tells them apart.
  M14, or delete it.

- **The hero reaches into the room's mechanisms on a respawn.** Placing the
  player at a checkpoint frees every sword in play and resets every mechanism
  with a clock in it, both by walking a group from inside `player.gd`. Raised
  while building the falling platforms, and the trigger written down then was
  that a third kind of mechanism meant fixing it.

  **The third kind arrived with geysers, and this was not what got built.** What
  got built was the cheap half: platforms and geysers share a "mechanisms" group
  and one `call_group`, so the walk stopped growing a branch per kind. The smell
  this entry is actually about is untouched. The hero still knows that rooms
  contain mechanisms, still knows they have clocks, and still hands one of them a
  number out of `config/death.tres` because a free-running clock has to sit out
  the respawn freeze. A signal carrying "the player has the controls back", with
  the room listening and resetting what it built, says all of that without the
  hero knowing any of it. It is half a day and it touches `player.gd`,
  `bench.gd`, both platforms, the geyser and the sword, which is why it did not
  happen inside a hazard change.

- **A falling slab is drawn over the lava it sinks into.** A room paints itself
  before any of its children, so every mechanism paints over the lava rectangle
  and a slab on its way out crosses the surface rather than entering it. Grey
  box, and M9 replaces the rectangle with a shader and an emitter anyway, so the
  fix belongs there along with whatever a slab hitting molten rock should look
  like. A ferry's rail is the same thing standing still: it is drawn over the
  moat it spans rather than into it.

- **`test_room_m3_moving.gd` counts the respawn freeze twice.** Its
  `_boarding_window` is `platform_wait_time + respawn_freeze`, but the freeze is
  already spent by the time the window opens: `Platform.reset` parks the clock at
  minus the freeze precisely so that a ferry is at its dock for the whole wait
  once the player has the controls. The window from control is the wait, and the
  assertion is 0.15 s looser than the room it is checking. It passes today and
  the CI step that rides the ferry out of a respawn proves the room really works,
  so this is a test that overstates its case rather than a bug in the game.
  Found while writing the same arithmetic for geysers, which does not carry the
  term. **Checked: the suite is still green with the term removed**, so the fix
  is one line and costs the ferry bench nothing. It is filed rather than taken
  only because it belongs to a bench this change was not otherwise touching.

- **The older CI screenshot steps keep their log without reading it.** The two
  spike steps grep for the outcome they claim, so a bed that stops killing or
  stops being jumpable fails the build. The lava, brazier, sword and gate steps
  predate that and only upload the picture, so the same class of regression is
  caught only if somebody looks. Cheap to retrofit, and it was left alone on
  purpose rather than widening a spikes change.

- **The avian ally as a mid-game traversal tool** rather than only the ending.
  Risk: it is a second verb, and the game is about having one.
- **Two kinds of switch: floor plates and wall switches.** A plate you stand on,
  or shove something onto, or leave an enemy on; and a wall switch you push or
  throw a blade into. Raised while playing M2, right after its switch turned out
  to read as a crate.

  **A floor plate is self-teaching in a way a wall fixture never is.** Weight on
  a plate is a thing every player already understands, and it needs no gold
  paint to say so. That alone is a strong argument for it.

  M2's switch is the wall kind, and it is the kind that milestone needs: its
  puzzle is a blade held in a socket and then recalled out of it, which a plate
  cannot do. What would make the existing one read better today is **mounting it
  in a wall** rather than standing it on the floor, which is a room change and
  not a mechanic change.

  Plates want things M2 does not have. "Move something onto it" means pushable
  objects, which are nowhere in SPEC.md. "Leave an enemy on it" means M4, and it
  is a genuinely good idea: an enemy as a tool rather than an obstacle is the
  sort of thing that makes a roster earn its place. Act 3 already owns a switch
  vocabulary (SPEC.md: switches that need current and not impact), so that is
  the natural home for a second kind.

- **Sword abilities as upgrades**, rather than all five from the first room.
  Recall, and embedding as a standable platform, become things you earn: better
  throwing, a potion, gold spent somewhere. Raised while playing M2, from the
  real observation that **the player currently gets every verb at once and
  nothing is staged**. That observation is correct and the pacing problem is
  real.

  Three things to weigh before building it. **It changes the genre**: SPEC.md's
  thesis is one verb and puzzles that are uses of it, and an upgrade turns "I
  cannot do this" from a thing you solve by understanding into a thing you solve
  by coming back later. **It is a lot of new system** (currency or items,
  persistent unlock state, save data, UI) in a project whose first attempt died
  of scope, and G1 has not happened. **It multiplies authoring**: every room
  must be solvable under every capability set a player could arrive with.

  The cheap version costs nothing and gets most of it: stage the **situations**
  rather than the abilities. Act 1 simply never presents a problem that wants
  recall; Act 2's rooms need it. SPEC.md's Structure already says each act
  introduces one thing the sword does, so this is level design the plan has
  asked for, not a new system.

- **A jump upgrade.** Same thought applied to movement. Flagged rather than
  filed neutrally, because it **contradicts the decision M0 just made**: ladders
  won on the argument that a jump which cannot reach the next storey is what
  makes an embedded sword one of only two ways to gain height. A jump that grows
  later takes that back mid-game, and the sword goes back to being a small
  extension in exactly the acts where SPEC.md wants it to be the whole vocabulary.
  Worth having only if the ladders decision is being reopened with it.

- **Volta's dialogue.** The original had none worth keeping. A wizard who
  comments on your deaths is either very good or very bad and there is no middle.
- **Desktop builds signed and on itch.io**, beyond the web export in M16.
