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

## The theme: difficult, modern, replayable

Matt's own framing for all of this: build on the original conceptually, not
literally, toward "a polished, difficult, modern game with a lot of
replayability." That is not a new direction, it is `SPEC.md`'s own model
named out loud: "faithful and hard, for an adult who wants it hard... the
model is Celeste and Super Meat Boy: lethal, instant, retried before you
have finished being annoyed." Both of those games are also two of the most
replayed platformers made, for reasons this project already committed to
before this conversation: "a puzzle you solve by understanding a verb
replays well; a sequence you memorise does not." What follows is what that
buys, concretely, without touching the one ruleset non-goal (`SPEC.md`: "no
difficulty modes").

**Named directly, the original's two failures**: it was short, and once you
beat it there was no reason to go back. The goal is not just to fix the
first one with bigger rooms; a longer game nobody replays is still short in
the way that matters. Everything below is aimed at the second failure, and
at depth, wanting the game to reward getting good at it rather than only
being gotten through.

- **Optional risk, not optional difficulty.** A harder path through a room
  that skips the safe solution, worth a secret or a faster route, sitting
  next to the one the room asks everyone to solve. This is how Celeste and
  Super Meat Boy both get replay value from a single ruleset: the game
  never gets easier or harder, the player chooses how much of it to attempt.
- **Optional gems and secrets beyond the required three per act.** SPEC.md
  keeps three gems in the final room as the critical path; nothing stops a
  handful of extra ones tucked behind an out-of-the-way embed-and-jump
  chain, found by mastery rather than by the story requiring them.
- **Level select, with every cleared room replayable on its own.** The
  cheapest possible enabler of "a lot of replayability": once a room is
  beaten it stays available from a menu, no walk back through the act to
  reach it. M16 territory (menus and saves), not a new gameplay system,
  and it turns every room already built into standalone replay content for
  free the moment it exists.
- **A rating, in place of the original's score.** `assets/reference/`'s own
  screenshots show a literal arcade score in the corner. Bringing that back
  as a number would sit strangely next to no health and no lives, but a
  per-room rating built from `Player.deaths` and `last_downtime` (already
  tracked for M3) at the exit is the same idea, aimed at a game that
  respawns instantly rather than one that spends lives. Exact shape not
  decided: a number, a letter grade, or just the two figures shown plainly.
- **The death count and the clock are already tracked.** `Player.deaths`
  and `last_downtime` exist for M3's own done-when, and `BACKLOG.md`
  already has "a speedrun timer and ghost... fits the game's shape well,"
  filed as post-ship. Worth asking whether "a lot of replayability" moves
  that up, or whether it stays exactly where it is. Not deciding here.
- **Don't patch out emergent technique.** Celeste and Super Meat Boy both
  got real replay depth from things nobody explicitly designed (wavedashing,
  corner-boosts), kept once players found them rather than fixed as bugs.
  Worth writing down as a stance before M14's tuning pass: if something
  skill-expressive falls out of coyote time, the catch radius and air
  control together, the first question is whether it is fun to have found,
  not whether it was intended.
- **New Game+ is the one idea in this list that pushes on "one ruleset."**
  Carrying five swords or harder enemy placement into a second playthrough
  is not a difficulty *option* a player picks before starting, but it
  rhymes with one closely enough to be worth naming rather than assuming.
  A lighter alternative that does not push on it at all: one or two early
  rooms get an authored, harder "remix" (the armour-flipped enemy variant,
  tighter timing) that unlocks after the credits, which is more authored
  content rather than a second playthrough, and stays inside the
  procedural-generation non-goal the same way the rest of the game does.
  Flagged, not recommended either way.

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

### Stump portals

Jump on a stump, emerge from another one elsewhere in the maze. This is not
a new idea to the project: `BACKLOG.md` already raised "magical portals" as
a way up and set it aside on purpose, "a new system in a one-verb game is
the exact scope risk that killed the first attempt," with instructions to
judge it after G1 (the vertical slice gate) once it is known whether
climbing without one is dull. A real two-way portal network is still that
same system, wanted now for lateral surprise in a maze rather than for
vertical traversal, but the cost is the same: new geometry, a teleport
state, a way to signal "these two things are linked" without giving away
the maze.

**The cheap version keeps the surprise and drops the system**: a stump that
drops you somewhere else in the maze, but does not run the other way. A
one-shot warp rather than a two-way door reads as a trap or a shortcut
rather than as infrastructure, and it is a much smaller thing to build,
place, and reason about than a network you can use freely in both
directions. Whether the real thing is worth its cost is still a judgement
for after G1, same as `BACKLOG.md` already said; the one-shot version does
not need to wait for that answer, because it never claims to be how you get
around, only something that happens to you once.

### Hanging vines

Two different ideas share this name. **A vine as a climbable surface** is a
ladder with different art: `Player`'s climbing state already reads any
"ladders" group area, and a vine curtain is that same area shaped like a
plant. Free. **A vine you grab and swing on** is a real new movement state:
momentum, an aim-and-release skill, its own way to miss and fall. SPEC.md
already treats the sword-as-ledge trick as a deliberately rare, special way
to gain height, "a room that demanded it every time would turn a surprise
into a staircase"; a swing move sitting next to that is a second special
traversal trick in a game whose pitch is one verb doing everything. Worth
being clear about which one is meant before art or physics starts on it.

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
- **Skeletons, resolved**: background art in the early rooms, and in the
  lower dungeon the identical-looking prop is alive. That fixes the "not one
  of SPEC.md's six" problem without a seventh enemy: it is a reskin of the
  scorpion or the ant (still to be picked, see "Open questions") with one
  small, genuinely reusable addition to `Enemy`, a dormant state that does
  not patrol or track until the hero comes close. Cheap, and it is not only
  for skeletons: the same trick covers a suit of armour, a gargoyle, a
  weapon rack that turns out to be a bat roost. One mechanism, a whole
  vocabulary of "is this decoration or is it alive" moments across every
  later act. See "Surprises" below.

## The inner castle and the throne room

Past the outer defences, a puzzle path to a throne room. There, the
chandelier drops onto the throne, which is what opens the way down to the
underground levels. Resolved since first raised: a sword thrown at a
bracket or a rope, not a second throwable. See "The torch" for the
mechanic that grew out of the "new mechanic?" question.

What is still open:

- **Is Volta present here?** The throne is empty or he is on it and escapes;
  either changes whether this room is a real confrontation or a trap he set.
  Not decided.

## The torch

Not a thrown weapon. A sword thrown at a brazier knocks the torch out of
it; picking the torch up is what SPEC.md's key already is, a specific object
a specific door or obstacle wants, except carrying it costs something:
no sword while it is in your hands, and (still to be decided) slower or
shorter jumps. There is no health to trade away, so the cost is not damage,
it is capability: for as long as you are carrying it, you cannot clear
anything, which turns every hazard between the brazier and wherever the
torch goes into a reason to have planned the route before picking it up
rather than after. That is the same risk-and-reward shape SPEC.md already
gives the throw itself, applied to a pickup instead of a throw.

Two things fall out of this cleanly rather than needing new design:

- **The throw button does not need a new binding.** Tap throws, hold
  recalls, and there is no sword to throw while the torch is in hand, so the
  same button is free to mean "set the torch down here" instead. One
  button, and what it does depends on what you are holding, the same way it
  already does for a tap versus a hold.
- **Where the torch is used is a lock-and-key placement, not a new verb.**
  Carry it to the right brazier, altar, or pile of oil-soaked kindling and
  it lights on arrival, the way a key fits one door. `SPEC.md`'s own key
  already works this way; this is a second kind of key with a cost attached
  to holding it.

One real constraint for whoever builds rooms around it: if jumping is also
limited while carrying the torch, a room cannot ask for both the torch and a
jump the limited version cannot make, or it becomes solve-the-platforming-
first-then-come-back-for-the-torch by accident rather than by design. Worth
deciding on purpose, not discovering while building M10.

**A small addition that deepens the cost rather than adding to it**: while
the torch is lit and carried, a bat's wander target becomes the hero
instead of its usual path. Carrying it already means you cannot fight;
now it also makes you the one thing in the room every bat wants to visit.
One flag, one line in `Bat`'s own targeting, no new system.

**A matching idea for Act 2**: fire is to the lava caverns what current is
to the generator. `SPEC.md` already reserves "conduct" (an embedded sword
carrying current) for Act 3; a torch-carry puzzle in the caverns is the same
shape one act earlier, in the other element, which would make the four acts
rhyme with each other rather than only sitting side by side.

## The underground levels

"Taking inspiration from the original but expanding the scope, adding more
and more complex puzzles and traps, introducing new mechanics as you go."
This reads as Acts 2 and 3 (lava caverns, the generator) as already scoped in
`SPEC.md` and `BUILD_PLAN.md`, just bigger and with more rooms than the
current ~5 and ~6. No new decision needed here beyond room count, which is
exactly the dial `BUILD_PLAN.md` already says to turn down first if the
schedule needs it.

**A harder puzzle for free**: M2's switch is one embedded sword holding one
switch. A lock needing two switches held at once, with three swords total,
forces real sequencing (which switch first, recalled from where, with which
sword left over) rather than only "find the switch." Same mechanism,
arranged harder, no new code.

**A circuit for the generator, concretely.** SPEC.md promises "conductive
floors, insulated wood, switches that need current, not impact" for Act 3
but does not yet say what a room built on that looks like. One shape: a
gate needs current run through two embedded swords in series, and pulling
either back to recall it breaks the circuit, so finishing the puzzle and
getting both swords back safely needs a third sword in reserve the whole
time. "The sword as wiring" (`SPEC.md`'s own phrase for the act) made into
an actual decision about which one you give up last, using only embed,
conduct and recall as they already exist.

**An enemy as a switch.** `BACKLOG.md` already has an unbuilt idea sitting
here: a floor plate that senses weight, which could be the hero's or an
enemy's. Paired with the dormant-decoration trick above, that is a specific
trap: trick or lure a sleeping enemy onto a plate to hold a gate open,
because standing there yourself means not being wherever the gate leads.
Two existing ideas, combined rather than either needing to grow.

**A sword graveyard, for atmosphere and nothing else.** A room deep in the
underground scattered with `GROUNDED` swords, dozens of them, left by
whoever came before and did not make it back for theirs. No mechanic, no
new art beyond what a sword already has, and it is exactly the kind of
environmental storytelling `SPEC.md`'s non-goals already choose over
cutscenes ("the bird in the cage is the story").

## Surprises and subverted expectations

Matt asked what else could stump the player. The strongest answers turn a
lesson the game already taught back on itself, rather than teaching a new
one:

- **Decoration that turns out to be alive** (skeletons, above) generalises:
  a suit of armour, a gargoyle, a weapon rack. One dormant-until-approached
  state on `Enemy`, reused as art changes.
- **A reskinned enemy with the armour rule flipped.** The scorpion teaches
  "hit it from behind or above." A castle-guard version of the same
  `ScorpionPatrol`-derived logic with the vulnerable side reversed punishes
  the exact habit the first one just taught, for the cost of a config
  value, not a new mechanic.
- **A floor that holds the first time and drops the second.** `FallingPlatform`
  already shakes and lets go on a timer; a version that only starts that
  clock on a *second* crossing turns a corridor you already trust, on the
  way back through it, into the trap. Small addition (count crossings
  instead of just "something is standing here"), large effect on a
  backtracking-heavy castle or dungeon.
- **A plank that reads as stone, or a block that reads as wood.** The whole
  embed mechanic runs on reading wood versus stone at a glance, and
  `ART_DIRECTION.md` treats that legibility as a rule, not a preference.
  Betraying it once, as a single memorable, specific puzzle, is a good
  trick. Betraying it often teaches the player not to trust their own eyes
  on the one read the entire sword mechanic depends on, which is a cost
  worth naming before it is used more than once or twice in the whole game.
- **A "dropped sword" that is not a sword**, an enemy standing in for the
  `GROUNDED` pickup's own silhouette to punish greed. Flagged rather than
  recommended: unlike the wood/stone read, which only matters when a room
  wants it to, the honesty of a lying-on-the-floor sword is something a
  player relies on constantly, and undermining it even rarely teaches
  suspicion of a pickup the rest of the game needs to be trustworthy.

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
4. **Skeletons: scorpion or ant underneath the reskin?** The dormant-decoration
   idea is settled; which of the two it drives is not.
5. ~~The chandelier: rope-and-chain or a second throwable?~~ Settled: no
   second throwable. See "The torch."
6. **Room count.** This vision is bigger than `SPEC.md`'s ~18. Worth
   deciding now whether that number moves, or whether "expand each act,
   cut rooms first if time is short" (already `BUILD_PLAN.md`'s policy)
   is enough.
7. **Does jumping get worse while carrying the torch, or just fighting?**
   Changes what a torch-carrying room is allowed to ask of the player.
8. **Vines: a climbable surface (free, a ladder reskin) or a swing move (a
   second special traversal trick next to the sword's own)?**
9. **Stump portals: the real two-way system now, or the one-shot "drops you
   somewhere" version**, with the network judged after G1 as `BACKLOG.md`
   already planned?
10. **How often is too often** for the wood/stone fake-out? Recommending
    once or twice in the whole game, never more.
11. **Does the speedrun timer and ghost move up from post-ship**, now that
    "a lot of replayability" is a stated goal, or does `BACKLOG.md`'s
    original placement for it still hold?
12. **Is New Game+ (or anything like it) wanted at all?** The one idea in
    this round that sits closest to the "no difficulty modes" line without
    quite crossing it. Not recommending either way.
