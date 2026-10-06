# SPEC.md: the reimagination

> **Source of truth.** Every other doc in this repo is downstream of this one.
> If a build plan and this file disagree, this file wins and the plan gets
> corrected.

## What this is

A 2D puzzle platformer, reimagining **Conan: Hall of Volta** (Datasoft, 1984,
designed by Eric Robinson and Eric Parker, Apple II original with C64 and Atari
8-bit ports). It is not a port, a demake or a faithful remake. The first attempt
at this project was a faithful copy and it stalled, because the 1984 game is not
good enough to be worth copying: seven one-screen levels solved by memorising a
fixed sequence, with jumps you cannot steer and hazards that kill on contact.

**That attempt is in this repo's history** (Phaser 3, no build step, first commit
through 2026-08-01). It got a long way: Level 1 pixel-traced from the Sharp X1
release, ladder climbing, coyote time, a two-frame walk cycle from a ripped
sprite, a flying enemy, and a working throw. Then it stopped, one board into
seven, with no objects, no audio and no menus. **Nothing was wrong with the
execution.** The effort went into fidelity to a game that did not deserve it,
which is the specific failure the plan below is arranged to avoid.

What it **is** worth taking is one mechanic that nobody has built a whole game
around, and a setting that hands you a puzzle vocabulary for free.

## What the original actually did

Established from research, and worth having written down so nobody re-derives it:

- **Seven one-screen levels**, each modelled as a real place: the outer castle
  wall, a moat, a lava pit, interior halls, and the Hall of Volta itself.
- **Per level**: collect gems, place them in gem holders, find the key, unlock
  the door. In a fixed sequence.
- **The weapon is a boomerang sword.** You carry ten. Thrown, it travels a set
  distance and then returns to you. **Catch it and you keep it. Hit a wall or an
  enemy and it is destroyed.** Restock points are scattered through the levels.
- **Conan somersaults rather than jumps**, and a fall becomes a dive. The
  animation was a selling point of the original.
- **Enemies**: bats, scorpions, giant ants, fire-breathing dragons, floating
  eyeballs, and a huge electrical generator gone haywire.
- **Hazards**: lava pits, geysers that hurl you into the air, spike pits,
  floating platforms. Lava, water, spikes and animals all kill instantly.
- **The ending**: place three gems in three holders, which frees the caged
  **avian ally**. It drops Volta into a pool of fire, then carries you out
  through the open door.
- **The contemporary and retrospective complaint** is consistent: stopping
  precisely is hard, jumping is unreliable, and once you are airborne there is
  nothing to do but hope the angle was right. It is remembered as an early
  forerunner of the puzzle platformer, which is a compliment about ambition and
  not about execution.

**One thing is unresolved.** Sources disagree on the throwable: most say
"boomerang swords", one walkthrough says you need "three axes" for the final
level. Probably the same object described differently across ports. It does not
change anything below, but do not treat "ten swords" as a settled number.

## The sword is the game

The boomerang sword is the whole reason to build this. **A throwable that
returns to you, that you can catch to reuse, and that is consumed when it hits
something, is a risk and reward economy sitting inside a single button.** Every
throw is a decision: spend the sword to kill the thing, or place the throw so it
comes home.

The reimagination makes that the core verb and builds the puzzles, the enemies
and the level geometry to serve it. Concretely, the sword does five things:

1. **Throw and catch.** It flies out along a flat arc to a maximum range, then
   turns and returns to where you are *now*, not to where you threw from. Stand
   in its path and it is back in your hand. Miss the catch and it lands on the
   floor, retrievable, but you have lost your position and your tempo.
2. **Kill.** It hits an enemy and both die. The sword is gone.
3. **Embed.** It hits **wood** and sticks, and a stuck sword is **a one-tile
   ledge you can stand on**. This is the move that turns a weapon into a
   traversal tool, and it is where the puzzles live. The art has to read as
   **bitten into** the wood rather than resting against it by the tip, because
   a blade that looks balanced on a surface does not look like one that would
   hold your weight.
4. **Recall.** Hold the throw button and an embedded sword flies back to you,
   taking its ledge with it. Standing on the ledge you are recalling is a
   legitimate and bad idea.
5. **Conduct.** A sword embedded in a conductive surface carries current. This
   is the Act 3 vocabulary and it is not invented: the original's boss hazard was
   already an electrical generator gone haywire, and Volta's name is a unit of
   electric potential.

   **How conduct works** (Matt, 2026-10-04). A sword sticks in conductive
   metal exactly as it sticks in wood. Metal comes in pieces, and current runs
   from a source along any path of metal and swords: an embedded sword joins
   every piece its blade touches, so a sword thrown into an insulating seam
   bridges the pieces either side, and recalling it breaks the bridge. A
   switch that needs current opens while it is on a live path. **Live metal
   kills on contact**, like lava; dead metal is safe. The generator cannot be
   hit by a sword: its own current runs out through broken rails, and bridging
   every break at once closes the loop back into it and shorts it out.

   **A sword carrying current is live metal** too: a rung thrown into live
   copper kills whoever steps on it. **A barrier** (Matt, 2026-10-04) is a live
   field fed from a source. It kills the hero, and any sword whose path crosses
   it while it is live is destroyed, recalled ones included: the one exception
   to "a recall cannot fail". Recall calls every sword at once, so a barrier
   held open by a sword would always cost that sword; barriers are therefore
   always on, and the decision is where you stand when you recall.

**The sword count is the difficulty dial and it is small.** Start with three,
cap at five. Ten was too many to make any single throw matter.

**Swords carry between levels, and levels resupply** (Matt, 2026-10-03,
reworded 2026-10-06). You walk into the next level with what is in your hand; a
sword left embedded behind you stays there. **A chest tops up what is in your
hand to three**, ignoring any swords of yours still out in the level, and keeps
refilling while you stand in it (Matt, 2026-10-06: the old rule counted swords
left in a wall as owned, and to a player that read as a broken chest). Chests
are placed where a fight or a puzzle needs them, not one per room; later levels
also hide swords off the main route or offer a mechanism that gives more.
Recall still caps you at five.

**A level is one large scene, and you can always walk back to its start**
(Matt, 2026-10-06). Five to ten floors tall and many screens wide, with braziers
inside it. Every drop has a way back up, and anything that closes behind you (a
gate a sword was holding, a branch that fell) leaves another route. A test holds
this for every level. Only a level's exit is one way.

## What changes from 1984, and why

| the original | here | because |
|---|---|---|
| Seven one-screen levels | **Four acts of large levels**, five to ten floors tall, each about ten times one of today's rooms | "bigger boards" means a castle you climb through, not a screen you memorise. The first build had ~18 small rooms and a family playtest found it short and linear (2026-10-06) |
| Committed, unsteerable jumps | Coyote time, jump buffering, variable height, real air control | The single most-cited complaint, and it is a solved problem |
| Insta-death everywhere, few lives | **Insta-death everywhere, instant respawn** | The lethality is the good part. The punishment was the bad part |
| Puzzles are fixed sequences to memorise | Puzzles are **uses of the sword** | A puzzle you solve by understanding a verb replays well. A sequence you memorise does not |
| Ten swords | Three, cap five | Scarcity is what makes the catch matter |
| Somersault as decoration | Somersault as **a state with different physics** | See `ANIMATION.md`. A move that looks different should behave differently |
| Avian ally appears in the last scene | A **caged dragon**, in view from Act 1 and freed with current | The ending lands if you have been walking past it for an hour, and freeing it uses the verb Volta's domain is built on |

### The one thing the first attempt decided differently, and it was right

That build set `jumpPower` **deliberately below a tier's height so that ladders
mattered**, and moved you between tiers by climbing rather than by jumping.

**This plan argued the opposite and lost.** Both were built in M0 and both were
played, and the short jump is the better game. So: **a storey is climbed, never
jumped.** The jump is 56 px against a 96 px tier and it is for gaps, short steps
and reaching a sword you put somewhere. `config/movement.tres` holds those
numbers; `config/movement_strong.tres` keeps the alternative, and Tab still
swaps them live because M14 retunes everything.

The argument against was that a platformer whose traversal is ladders has traded
away the thing that makes moving fun. That risk is real and it is now the thing
to watch for at G1.

**What it buys is the sword.** The old argument here said a weak jump fights the
sword, because half of what makes an embedded sword interesting is that it
extends a jump you could almost make. That was backwards. With a jump that
cannot reach the next storey, an embedded sword stops being a small extension
and becomes **a way up that nothing else in the room provides**. In a game whose
thesis is that the sword is the game, the weak jump is what makes the thesis
true in the level geometry rather than only in the combat.

That is about what the move is worth, not how often it is asked for. See
`Structure` below: the sword route is meant to be uncommon.

Ladders are traversal now rather than furniture, and every room plan in
`Structure` is read with that in mind.


## Difficulty

**Faithful and hard, for an adult who wants it hard.** Lava kills on contact,
spikes kill on contact, a scorpion kills on contact. There is no health bar and
no regenerating shield.

The modernisation is entirely in **the cost of dying**, not in the chance of it.
Death restores your swords, respawns you at the last lit brazier, and takes
under a second end to end. Checkpoint braziers are frequent and you light them
by walking past. The model is Celeste and Super Meat Boy: lethal, instant,
retried before you have finished being annoyed.

**Nothing is a difficulty option in v1.** One ruleset. A kid-forgiving mode is
in `BACKLOG.md` and stays there until the game exists.

### The death messages, which are kept

The original named each death: fifteen short, mock-heroic lines drawn in a box
over the level. Four survive in `assets/reference/c64/` ("YOU SUCCUMB TO
LASSITUDE" is the register). **The tradition is kept and the box is not.**

A box you stop and read costs about two seconds, and the one second above is the
whole modernisation, so a faithful box would trade away the thing this game is
for. Instead the line appears **centred and large** as you die, and **lingers past
the respawn**, fading out while you are already running. It costs nothing, and
reading it is optional in a way the original's was not.

**The lines are ours.** `CLAUDE.md` forbids shipping anything out of
`assets/reference/`, so none of the four is used: the lines in
`scripts/logic/death_messages.gd` are written to that register rather than taken
from it. They rotate from a bag, so every line is seen before any repeats,
which matters in a game built to be died in.

**A line knows what killed you** (2026-10-05, from `BACKLOG.md`). A line that
names a hazard (lava, spikes, a beast, current, the dragon's fire) is only
said by that hazard, and lines about nothing in particular can be said by
anything, so an arc never answers with a geyser. Each cause keeps its own bag.
Fifteen lines were written first, to the original's count; the rest arrived so
each cause has a handful of its own.

**The hero being Lothar of the Hill People is doing work here.** A name that is
a joke played straight is exactly the register these lines want.

## Structure

Four acts, each made of two or three large levels (Matt, 2026-10-06). Each act
introduces one new thing the sword does and then asks a hard question about it.
Levels mix enemies in groups rather than meeting one species at a time, and
every species appears outside the room that introduced it.

**The scale is proved on Act 1 first.** Act 1 is rebuilt at full size and played
(G2, `BUILD_PLAN.md`) before Acts 2 to 4 are. Their descriptions below still
count today's rooms; each of those rooms becomes a section of a larger level
when its act is rebuilt.

**Act 1: the forest, the moat and the outer wall** (one or two levels). Teaches
throw, catch, embed and the sword switch, each in front of the player before it
is ever asked for. Somewhere it cannot be crossed without standing on your own
sword. The caged dragon is seen whole, behind bars in a quiet stretch of its
own. Ends at the gate.

**Act 2: the lava caverns** (5 rooms). Geysers that launch you, floating
platforms, rising and falling lava. Teaches the sword under time pressure: a
throw you have to catch before the platform you are standing on drops. The
dragon mini-boss closes the act: it is overpowered and chained, not killed, and
it is the same dragon you free in Act 4.

**Act 3: the generator** (6 rooms). Conductive floors, insulated wood, switches
that need current and not impact. Teaches the sword as wiring. The haywire
generator is the act boss and the fight is a circuit, not a damage race.

**Act 4: the Hall of Volta** (3 rooms). Three gems, three holders, kept from the
original because it is a good ending. Volta himself, then current run through the
right conductor lets the chains go, and the dragon finishes him. You ride it out.
Decided by Matt, 2026-10-04:

- **Gems are conductors.** Each holder is a break in the circuit to the
  dragon's chains, and a set gem closes it, as a sword closes a seam. A break
  is wider than a sword can reach, so only a gem will do.
- **One gem per room**: rooms 1 and 2 each hold one behind a distinct use of
  the sword, and room 3 holds the last and the fight. Gems ride from room to
  room like swords in hand and are never lost to a death.
- **Volta casts and pulls swords.** He throws aimed bolts, and now and then
  he drags every embedded sword out of the walls toward himself, undoing your
  circuit. He cannot be beaten by throwing.
- **The ending is a short playable flight**: you ride the dragon out through
  one scrolling room, steering only up and down, then a card.

**The jump owns a scale, and it is not the storey.** A 56 px jump is for holes
in the floor, plinths, low ledges and the short steps between them. Those are
deliberate furniture and rooms should be full of them, because they are where
moving stays fun once a storey is off the table.

**Gaining a storey has a vocabulary, and the sword is its rarest entry.** The
ordinary ways up are ladders, and in Act 2 the geysers that hurl you. **Once in
a while, where there is wood**, a fallen tree or an interior wall, the way up is
a blade you throw and then stand on, and working that out is the puzzle.

That move is uncommon on purpose. A room that demanded it every time would turn
a surprise into a staircase, and the point of it is that the player arrives at
an unexpected set of navigational furniture, occasionally with a beast on it,
and has to reason the route out. `BACKLOG.md` holds the other vertical modes
that have been raised and not judged.

**Gems and keys survive**, but they change meaning. A gem sits behind a distinct
use of the sword rather than behind a memorised route, and the key is the exit.
Three gems in the final level, as in the original.

## Enemies

Six types, all from the original, each punishing a **different** mistake with the
sword. This is the design constraint that keeps a roster from being decoration.

| enemy | behaviour | the mistake it punishes |
|---|---|---|
| **Bat** | erratic flight, fast, no ground contact | Throwing at a moving target. Costs you the sword nine times in ten |
| **Scorpion** | ground patrol, armoured front | Throwing from the front. Must be hit from behind or above |
| **Giant ant** | walks walls and ceilings, ignores gravity | Assuming the floor is where danger is |
| **Floating eyeball** | tracks you slowly, at your height | Standing in your own catch line. It is the anti-catch enemy and it exists to eat returning swords |
| **Fire-breathing dragon** | Act 2 mini-boss, telegraphed cone, immobile | Panic throwing. It has to be beaten with recall, not ammunition |
| **The generator** | Act 3 boss, arena, cannot be hit by a sword at all | Believing every problem is a throw |

**The two bosses are both anti-sword**, on purpose. A game whose verb is one
button needs its bosses to ask what else the verb can do.

## Name

**Volta Redux.** Repo `volta-redux`, renamed from `Conan`, which is where the
first attempt lived and why the git history starts with a Phaser 3 spike.

The name drops the licensed character on purpose, and it is a design decision
before it is a legal one. Nothing above depends on Conan the Barbarian: the
sword, the castle, the electricity, the caged dragon and the wizard are all ours
the moment the hero has a different name, and the game becomes an actual
reimagination rather than a remake wearing a hat. **Volta stays**, being a unit
of electric potential and a real surname rather than an owned character.

**The hero is Lothar of the Hill People.** Settled, not provisional. It arrived
as a Mike Myers bit and it stays, which means the register this document sets (a
castle with a lava pit in it, an adult who wants it hard) carries a hero whose
name is a joke and plays it straight. **M5 draws him** to that brief.

## What the repo inherits from the first attempt

`assets/reference/` holds 53 screenshots of the original across four platforms,
downloaded from MobyGames for the first attempt. **Keep them.** They are not
being traced this time, but they are the best available record of what the
seven boards actually contained, and `apple2/cast-of-characters.png` and
`apple2/objects.png` document the enemies and pickups directly.

| platform | count | native | use |
|---|---|---|---|
| `sharp-x1` | 17 | 640x400 | **the useful set.** Cleanest, highest res, full level run plus the ending |
| `c64` | 18 | 320x200 | the HUD, and **four of the original's fifteen death messages** |
| `apple2` | 11 | 560x384 | the cast sheet and the objects legend |
| `atari-8-bit` | 7 | ~336x240 | title, start, a couple of layouts |

**The ten sprites ripped from the Apple II release are gone**, deleted in the
same commit that brought this plan in. We are drawing our own, they were the
most clearly infringing thing in a public repo, and git history keeps them if
they are ever wanted.

**A minor discrepancy worth not tripping over.** The Sharp X1 reference set runs
to L8 while every written source says seven levels. Probably a title or ending
screen counted as a board. It changes nothing, but do not treat either number as
authoritative.

## Non-goals for v1

- Multiplayer, of any kind.
- A level editor, or user-made levels.
- Procedural generation. Every room is authored.
- Difficulty modes.
- Mobile or touch controls. Keyboard and gamepad, desktop and web.
- A story told in cutscenes. The chained dragon is the story.
