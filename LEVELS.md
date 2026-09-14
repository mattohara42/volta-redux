# LEVELS.md: Matt's expanded vision, not yet decided

This is not `SPEC.md`. `SPEC.md`'s Structure section (four acts, ~18 rooms) is
still the settled plan and `BUILD_PLAN.md`'s "no level building before M10"
still holds: nothing here gets built until it is judged, and this file is the
judging, not the building.

What follows is Matt's own description, organised by area, with where each
piece fits the mechanics that already exist, where it needs something new,
and where it pulls against something `SPEC.md` or `CLAUDE.md` already
settled. Read the "Open questions" list at the end before treating any of
this as decided.

## The shape of the idea

Every act in `SPEC.md` is a single named place (a moat, a cavern, a
generator room, a hall). Matt's version keeps that but wants each place to be
what the original's seven *screens* only gestured at: a real forest, a real
castle wall, a real dungeon, each one big enough to get lost in and dense
enough that a screen's worth of the original becomes a whole area of rooms.
That is a scale question as much as a content one. `BUILD_PLAN.md` already
warns that scope killed the first attempt and that Acts 2 and 3 are where
rooms get cut if time runs short; this file is the wishlist that warning
exists to be checked against, not a commitment to build all of it.

## The forest

A river, and trees to cross it in rather than a bridge: climb a trunk, jump
branch to branch, some branches cracked and dropping whoever is on them onto
hidden spikes below. A scorpion nest as its own kind of trap. Big enough to
scroll both ways, filled with hazards throughout.

This is close to the original's own level 2 (`assets/reference/sharp-x1/
level-2.png`): trees, ladders, and the caged bird already visible at the
bottom of the screen. That is a good sign for putting this early, matching
`CLAUDE.md`'s "the caged bird is visible from Act 1."

What it needs, mechanically:

- **A cracked branch is a falling platform reskinned.** `FallingPlatform`
  already does exactly this: stand on it, it shakes, it lets go. Landing on
  hidden spikes below is `Hazard` doing what it already does. No new system,
  just wood-and-leaf art on an existing mechanism whenever M9's pass gets to
  it.
- **A scorpion nest** is several scorpions in one room, which is a room
  decision, not a new enemy or a new kind of trap.
- **Vertical scroll** is a bigger `Bench`-style room with taller camera
  limits. Nothing here is new, but it is a real room and a real camera and
  worth an early art-spike room (M5 territory) to prove a tall room reads
  before eighteen rooms assume it does.

This reads as a strong fit for **Act 1**, in place of or alongside "the moat
and the outer wall." See "Open questions" on what that does to the act
structure.

## The outer castle

Ladders, torches, multilevel, matching the original's own outer-wall level
directly. Bats flying around. Bigger and more complicated than the original.
It should read as an actual castle wall: ramparts, siege engines standing
around as dressing or as hazards. Skeletons. Basic puzzles and traps.

This maps cleanly onto `SPEC.md`'s Act 1 ("the moat and the outer wall...
Teaches throw, catch, and embed") if the forest becomes a separate area
before it, or onto a bigger, later act if the forest **is** Act 1.

What it needs:

- **Bats and ladders** are already built (`Bat`, and ladders are an existing
  room fixture from M0 on).
- **Siege engines as hazards.** A ballista or a catapult firing on a clock is
  the dragon's breath shape again: `DragonBreath` is already a generic
  "telegraph, then a lethal box on a timer" clock, and a siege weapon wants
  the same three phases with different numbers and a different picture. Worth
  naming and reusing rather than a new file per weapon.
- **Skeletons are not one of SPEC.md's six.** The Enemies table is bat,
  scorpion, giant ant, floating eyeball, dragon, generator, "each punishing a
  different mistake." A skeleton needs either its own row (a seventh mistake,
  which the table does not currently have room for) or to be reskinned art
  over one of the six, most naturally the scorpion or the ant (a ground or
  wall patrol dressed as a castle guard rather than an animal). Flagged in
  "Open questions."

## The inner castle and the throne room

Past the outer defences, a puzzle path to a throne room. There, a sword or a
thrown torch (Matt's own "new mechanic?") drops the chandelier onto the
throne, which is what opens the way down to the underground levels.

What it needs:

- **The chandelier drop does not need a new mechanic.** A sword thrown into
  the rope or chain holding the chandelier (wood or a wood-like fixture) is
  `SwordFlight`'s embed doing the cutting, or the switch pattern from M2
  (embed a sword in the right place, something elsewhere responds) triggering
  a rigged release. Either reading uses the verb that already exists rather
  than adding a second throwable next to it.
- **A second throwable (an actual torch) is real new scope.** `SPEC.md`'s
  whole thesis is one verb: "The sword is the game," and a torch is a second
  projectile with its own rules sitting right next to it, which is exactly
  the shape of addition `BACKLOG.md` already argues against elsewhere (sword
  variants, deferred, "would dilute a single clean verb before that verb has
  proved itself"). If a torch is wanted for the fire it makes rather than for
  being a second throw, a **thrown sword that ignites something flammable**
  gets the same beat for free. Recommending the free version; flagged either
  way in "Open questions."
- **Is Volta present here?** The throne is empty or he is on it and escapes;
  either changes whether this room is a real confrontation or a trap he set.
  Not decided.

## The underground levels

"Taking inspiration from the original but expanding the scope, adding more
and more complex puzzles and traps, introducing new mechanics as you go."
This reads as Acts 2 and 3 (lava caverns, the generator) as already scoped in
`SPEC.md` and `BUILD_PLAN.md`, just bigger and with more rooms than the
current ~5 and ~6. No new decision needed here beyond room count, which is
exactly the dial `BUILD_PLAN.md` already says to turn down first if the
schedule needs it.

## The dragon, chained

The dragon is chained up, and freeing it needs current run through
something: electrify the right conductor and the chains let go. The fight
everyone expects turns out to be the wrong read: the actual solve is
freeing it, so it can reach Volta and kill him, and the ending is riding it
out rather than being carried by the bird. Volta used electricity as a
weapon; this is the same current used to free something instead.

This is the biggest idea in the whole set, and it lands directly on two
things `CLAUDE.md` currently calls settled:

- **"The caged bird is visible from Act 1... the ending only lands if you
  have been walking past it for an hour."** A caged **dragon**, seen early
  and freed at the climax, is the same structure with a better-motivated
  payoff: it ties directly into Act 3's conductivity vocabulary (you free it
  with the exact verb Volta's whole domain is built on), which the bird
  never did. This reads like a strengthening of a settled idea more than a
  break from it, if the caged creature simply **becomes** the dragon rather
  than sitting alongside the bird. Worth serious consideration for exactly
  that reason: it is rare that a bigger idea also closes a gap (the bird's
  disconnection from the sword's own thematic material) that already existed
  in the settled version.
- **The Act 2 dragon mini-boss, already built** (M4/M11: beaten by recalling
  a sword through it, never by a fresh throw). If the story dragon is the
  same one, "beaten" in Act 2 can mean **overpowered and chained** rather
  than killed, which changes nothing about the mechanic already shipped,
  only the flavour text and what the room looks like afterward (a chained
  dragon rather than an empty room). If it is a *different* dragon, the Act 2
  fight stands as-is and the chained one is new content elsewhere. Either
  works; picking one is the open question.

## Open questions for Matt

1. **Is the caged bird now the caged dragon**, replacing the ending in
   `SPEC.md`, or does the bird stay and the dragon is a separate late-game
   beat? This is the one item on this list that touches a decision `CLAUDE.md`
   currently marks "do not relitigate," so it is the one worth being most
   deliberate about.
2. **Is the Act 2 dragon mini-boss the same dragon** as the chained one, with
   "beaten" reread as "overpowered and taken away in chains," or a different
   dragon entirely?
3. **Does the forest replace Act 1, sit before it, or fold into it** alongside
   the moat and the outer wall? This decides whether the plan is still four
   acts or becomes five-plus.
4. **Skeletons: a seventh enemy type, or a castle-flavoured reskin** of the
   scorpion or the ant?
5. **The chandelier: a sword thrown into a rope or chain (no new mechanic),
   or a genuine second throwable (a torch)?** Recommending the first.
6. **Room count.** This vision is bigger than `SPEC.md`'s ~18. Worth
   deciding now whether that number moves, or whether "expand each act,
   cut rooms first if time is short" (already `BUILD_PLAN.md`'s policy)
   is enough.
