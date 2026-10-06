# BACKLOG.md

Mid-build ideas land here, never in the active milestone. Nothing in this file is
committed to until Matt says yes. Resolved entries are deleted; `git log` keeps
them.

**Reorganised 2026-10-06** around the first family playthrough (Matt and the
kids). The playtest notes and the plan that comes out of them are first, then
every older entry, filed under the stage of that plan it belongs to.

## The playtest, 2026-10-06

Matt and the kids each played it through. What worked: the music, the movement,
the puzzles. Everyone had fun. What did not, with what the code says about it:

1. **Some chests gave no swords.** Not a mis-wire: the rule is doing what it
   says. `ActRoute.chest_top_up` brings the swords you *own* up to three, and
   it counts every sword of yours still in the room, embedded in wood or lying
   on the floor, as owned. Leave two in a wall, walk into a chest holding one,
   and it gives nothing. To a player that is a broken chest. It also only
   fires on walking in (`body_entered`), so a chest you are already standing in
   never refills.
2. **The wooden switch under the dragon did not read.** `Act1Bailey`, beat 3.
   Nobody worked out that a sword goes in it. The room drops you into the yard
   with the switch *behind* you ("turn round, throw"), so the first thing you
   see is a shut portcullis and nothing pointing at the answer. It is also the
   first switch in the game, with no room before it that shows one.
3. **The caged dragon read as a solid block with blinking eyes.** Same room.
   The grate is code-drawn bars over a dark rectangle with two eyes, dimmed as
   background. Nobody knew what it was, and it sits right above the switch, so
   it pulled attention off the one puzzle that needed it. Note that
   `assets/art/enemies/dragon_chained_sheet.png` already exists.
4. **Drops you cannot get back up.** A handful of places let you move forward
   past a drop too high to jump back. **New rule from Matt: a player can always
   walk back to the beginning of the level.**
5. **The sword and the "door" are placeholders.** The sword is drawn in code
   (`Sword._draw`, gold rectangles and a polygon) and the room exit is a flat
   gold rectangle (`RoomExit._draw`). Both are below everything around them.
6. **The dragon's flame still does not look real.** It is a shader polygon
   clipped to the kill box (`Flame`, `shaders/flame.gdshader`).
7. **Lothar riding the dragon does not look real.** `DragonRider` stacks the
   standing hero sprite on the flight sheet.
8. **It is far too short and too linear.** The headline note. Matt wants each
   level much longer and often taller: five to ten floors of a castle, with
   mixed enemy groups, about ten times the size. The census backs him up. The
   whole game has 21 playable rooms, each one screen tall (360 px) and two to
   four screens wide, and in all of them there are four scorpions, two bats,
   one eyeball, the dragon and the generator. The giant ant is in no room.
   Act 3 has no creature except its boss.

## Decisions requested

Each of these changes what gets built, so none is assumed. Recommendations are
mine and are only that.

1. **What is a "level"?** Today an act is a chain of one-screen-tall rooms with
   exits that only lead forward. *Recommend:* a level is one large continuous
   scene, five to ten floors tall and many screens wide, with braziers inside
   it, and each act is two or three of them. Today's rooms become sections of
   a level rather than being thrown away. The alternative, rooms linked both
   ways with doors, needs every room to remember its swords, gates and dead
   enemies while you are elsewhere, which is a save system inside the game
   loop and much more to build.
2. **The walk-back rule's reach.** *Recommend:* always true inside a level,
   and a level's exit stays one way (as `SPEC.md` says of rooms now). Some
   things should still be allowed to close behind you: a gate a sword was
   holding, a cracked branch that fell. *Recommend* a fallen route must leave
   another way back, so the rule holds and the trap still bites.
3. **How rooms are authored.** Every room today is `Rect2` constants in a
   GDScript file. That is fine for 21 small rooms and will not survive ten
   times the area. *Recommend:* a plain-text grid per level (one character per
   tile, a legend for wood, stone, ladders, lava, spikes, chests and each
   enemy, plus a short list for mechanisms and wiring), parsed by a pure
   function in `scripts/logic/` into the same `Bench` builders that exist now.
   It diffs, it can be written and reviewed in a PR, and a test can read it.
   The other route is painting `TileMapLayer`s in the editor, which is nicer
   by hand but stores tiles as packed numbers nobody can review or write
   outside the editor. Either is built into Godot, so no addon.
4. **How much bigger, and in what order.** *Recommend* doing it the way G1
   was done: build Act 1 as one or two big castle levels first, play them with
   the kids, count what a level cost to make, and only then commit to the
   other three acts at that size. Call it **G2**. Ten times the content is the
   scope that killed the first attempt, and one finished big level answers
   whether this one survives it.
5. **The chest rule.** *Recommend:* a chest tops up what is *in your hand* to
   three, ignoring swords left in the room, and refills while you stand in it.
   That makes it possible to own more than three for a while (recall still caps
   at five), which is a small gift, and the old rule's only point was stopping
   it.
6. **Enemy density and the sword economy.** Many more enemies means many more
   swords spent, and `SPEC.md` keeps three and a cap of five. *Recommend*
   keeping that and letting the levels pay for it: chests where a fight needs
   them, hidden swords off the main route (the optional-risk idea below), and
   fights built around catching rather than spending.
7. **`SPEC.md`, `LEVELS.md` and `BUILD_PLAN.md` all say about 18 rooms.**
   `LEVELS.md` decision 4 ("room count stays at about 18") is Matt's own and
   this overturns it. Once 1 to 4 are answered, those three files get rewritten
   to match, in one PR, before any level is built.

## The plan, in stages

Each stage is one milestone in the `BUILD_PLAN.md` sense, done one at a time.
M14 stays the active milestone in name; this playtest is its first set of notes
and the stages below are what it turned into.

### Stage 1: fix what the playtest hit

These hold whatever the answer to the scale question is, because each one is
a rule or a component that big levels reuse.

- **The chest rule** (decision 5), with a test on `ActRoute.chest_top_up`.
- **A walk-back checker.** A pure function in `scripts/logic/` that takes a
  room's solids, ladders and the jump from `config/movement.tres` and finds
  every standing surface you can reach going forward but not return from.
  Run in CI on every room, so the rule is held by a test from now on instead
  of by playing. Run it on today's rooms and fix what it finds only in rooms
  that survive the rebuild; the report says which drops the kids met.
- **Teach the switch.** Put the first switch in front of the hero with the
  gate it opens in view, right after the wooden hurdle that just taught "a
  sword sticks in wood". Give it a slot that catches light, and a visible link
  to the gate (a chain or rod that moves when the sword lands). Fold in the
  older entry about mounting M2's switch in a wall so it reads as a fixture.
- **Move the cage and make it a dragon.** Out of the switch's sightline, into a
  quiet stretch of its own. Draw an actual creature behind the bars, from the
  existing chained-dragon sheet: a head and snout, chains on the neck, a slow
  breath, a curl of smoke, a growl as you pass. `LEVELS.md` said Act 1 shows
  "something short of the whole creature"; the kids showed that a shape in the
  dark is too short. Worth a yes from Matt, since it changes that line.

### Stage 2: replace the placeholder art

Independent of everything else, and it spends credits (`ART.md`, 510 left).
`GEMINI_NOTES.md` before any prompt; filmstrip every animated delivery.

- **The sword**, in hand, in flight, embedded and lying on the floor, to the
  settled design (straight blade, asymmetric hilt). Embedded has to read as
  bitten in (`SPEC.md`).
- **The door**: the room exit and the portcullis. Today's gold rectangle
  becomes a doorway in each act's own material.
- **The flame.** Probably still code (`CLAUDE.md`: atmosphere is code), but a
  better one: particles with heat haze and a hot core over the shader, not
  more polygon. The kill box can stay straight while what you see is not.
- **The ride.** A seated, leaning Lothar drawn as one frame set with the
  dragon (or a riding pose for the hero), in place of the standing sprite on
  its back.

### Stage 3: the tools for big levels (after decisions 1 to 3)

- **The level format** (decision 3) and its parser, with today's rooms
  re-expressed in it as the proof that nothing was lost.
- **The walk-back checker** from Stage 1, run on every level.
- **Respawn in a big level.** Today a death resets every mechanism in the room
  from inside `player.gd` (the older entry below). In a level ten floors tall
  that would reset a gate opened half an hour ago. Fix the design smell now:
  the room listens for "the hero is back" and decides what to reset, probably
  only what is near the brazier's section.
- **Save at braziers, not per act.** The save per act was chosen for
  one-sitting acts. A big level needs a save that survives quitting halfway.
- **A performance look.** `LightField`, rim light and every `_draw` were
  measured on rooms two screens wide. Build one ten-by-five grey level and
  check the frame time before art goes on it.

### Stage 4: G2, Act 1 at full size

Act 1 rebuilt as one or two big levels: the forest, the moat and the outer wall
(`LEVELS.md` already has all three), five to ten floors, mixed enemy groups,
the existing rooms folded in as sections. Then Matt and the kids play it.
**Done when** it is fun at that size and the cost of one level is written down.
If it is not fun, or the cost cannot be paid three more times, the fix goes in
`SPEC.md` before anything else is built.

### Stage 5: Acts 2 to 4 at full size

Only after G2. Today's rooms become sections, the bosses stay. Then M14's pass
proper, with three full playthroughs, then M16.

## Ingredients for the big levels

Older entries that were waiting for content to use them. Most are now
needed rather than optional, because the content is about to exist.

- **Mixed enemy groups.** All six species are built. Combinations to try: an
  eyeball patrolling the catch line of a scorpion fight, so the safe throw is
  the one it eats; bats over a sword ledge; an ant on the ceiling above a
  switch, so standing still to throw is the risk; a dormant scorpion beside an
  awake one. Plus the two variants `LEVELS.md` already decided: the skeleton
  (a dormant scorpion) and the armour-flipped guard.
- **The giant ant is in no room.** Act 3 is the obvious home: seven rooms with
  no creature but the generator. Check first what an ant does when it walks
  into an embedded sword.
- **The floor plate and the dormant enemy on a plate** are built
  (`room_m4_plate`, `room_m4_dormant`) and in no room. `LEVELS.md` liked "an
  enemy as a switch".
- **More ways up than ladders.** Five to ten floors climbed only by ladder is
  exactly the monotony `SPEC.md` warns about, so this stops being a "judge
  after G1" question. Free now: geysers as routes (`room_m3_geysers` proves
  it), moving platforms as lifts (`MovingPlatform` already travels any vector),
  vines as ladders with other art (`LEVELS.md` decision 7). New systems still
  needing a yes: two-way portals (decision 8 kept the one-shot stump warp).
- **Spikes where lava cannot go**: teeth on top of the ledge you land on. The
  56 px jump cannot clear a bed on a 32 px step, so it wants a moving platform
  or a sword ledge to arrive on. Revisit when building a level.
- **Every room has a chest**, so swords carrying between rooms never bites.
  With decision 6, chests become placed for fights rather than given per room,
  and later levels hide swords or offer a mechanism, as `SPEC.md` says.
- **Act 2's first two rooms never ask for the sword.** One beat each: a switch
  across a moat hit from a moving ferry, or a vent opened by a sword in a
  valve.
- **Optional risk.** A harder route beside the one everyone solves, worth a
  hidden sword or a secret (`LEVELS.md`). Big levels finally have room for it,
  and the end card's tally is where secrets get counted.
- **Act 4 is thin on danger.** A shelf, the Act 1 guard lesson again, and
  Volta. The other two rooms could ask more.
- **From `LEVELS.md`, decided and unbuilt:** siege engines on a clock (the
  dragon's breath with other numbers), the torch carried at the cost of the
  sword, a lock needing two switches at once, a floor that holds the first
  time and drops the second, the wood/stone fake-out once or twice, a sword
  graveyard for atmosphere, the one-shot stump warp, the chandelier.
- **Remix rooms** after the credits, harder versions of early sections. Matt
  wants them; add each idea here as it comes. After the pass.

## Readability, to look at while playing

- **A dormant enemy shows no tell** and a frozen sprite looks like a statue.
  Maybe right; play once. Matters more once skeletons are in.
- **The eyeball's pupil could track the hero**, the enemy that "looks back".
  `animate` or `direction-set` could give it left and right frames.
- **Enemy sprites are bigger than their killing boxes** (ant 37 px against 22,
  bat 34 against 20). Grow the box or accept the mercy.
- **The sword counter is gold**, which also means "interactive". Check it does
  not compete.
- **Tunnel walls are masonry darkened upward.** A proper wall-face tile is M8
  work, and tall levels will need a lot more wall.

## To judge by playing (M14)

- **`spike_grace`** may be a dial nobody can feel. Setting it to zero moved
  the takeoff window by nothing. Keep or delete.
- **A pull can lose a sword into the dais recess.** The room's chest refills
  to three. Right cost, or throw swords clear?
- **The throne has one conductor, not a choice of two.** Every decoy layout
  blocked the path.
- **The sounds** have now been heard and the music landed. Any sound effect
  that did not, note it here.
- **Matt's play log** (`user://`, PR #136) from this playthrough would show
  where the time and deaths went. Worth sharing before Stage 1.

## Code and tooling debt

- **The hero reaches into the room's mechanisms on a respawn.** It walks the
  "mechanisms" group from inside `player.gd`, knows they have clocks, and
  hands one a number from `config/death.tres`. A signal carrying "the player
  has the controls back", with the room resetting what it built, says the
  same without the hero knowing. Half a day; touches `player.gd`, `bench.gd`,
  both platforms, the geyser and the sword. Now part of Stage 3.
- **The test runner passes a test that crashes.** A `SCRIPT ERROR` mid-test
  aborts that test and the run still reports 0 failed. Worth making a script
  error a failure.
- **No tool measures where a tile's art meets its collision line.** Done by a
  one-off scan for `room_m5_wall`. A big level format makes this a per-tile
  property, so solve it there.
- **`tools/cut-rig.py` only knows named rectangles.** Mostly moot since the
  move to frame animation; keep only if a rig ever returns.
- **F2's bench cycle leaves out the M4 rooms.** Reachable by
  `tools/dev.sh play` only. An oversight.
- **Quitting mid-track prints "resources still in use at exit".** Harmless
  noise in CI's log.

## Deferred from v1 deliberately

- **A forgiving mode, for a kid.** Checkpoint density, hazard lethality and
  sword count are the three dials. It stays here because a difficulty mode
  built before the base difficulty is tuned is two untuned games. The kids
  had fun at full difficulty, which is a data point for leaving it here.
- **Per-hazard death animations.** v1 has one.
- **Sword variants.** A heavy one that does not return, a pair thrown together.
- **Ricochet off metal**, `SPEC.md`'s fifth behaviour cut to four. Only if
  Act 3 turns out thin.
- **The dragon as a mid-game traversal tool** rather than only the ending
  (this was "the avian ally"). It is a second verb.
- **Sword abilities as upgrades.** Changes the genre, needs currency and
  unlock state, and multiplies authoring. Stage the situations instead: an act
  that never asks for recall until the next one does.
- **A jump upgrade.** Contradicts the ladders decision; only with it.
- **A speedrun timer and ghost.** Post-ship (`LEVELS.md` decision 10).
- **Volta's dialogue.** Very good or very bad, no middle.
- **Desktop builds signed and on itch.io**, beyond M16's web export.
