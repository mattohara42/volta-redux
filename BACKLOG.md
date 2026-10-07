# BACKLOG.md

Mid-build ideas land here, never in the active milestone. Nothing in this file is
committed to until Matt says yes. Resolved entries are deleted; `git log` keeps
them.

**Reorganised 2026-10-06** around the first family playthrough (Matt and the
kids). The playtest notes are first, then every older entry, filed by where it
belongs in the plan (`BUILD_PLAN.md`, R1 to R4).

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

## Decided, and where the plan went

Matt answered all seven questions and the cage on 2026-10-06, each as
recommended: `LEVELS.md` → *Decisions (2026-10-06)*. The plan is now
`BUILD_PLAN.md`'s R1 to R4 and G2, and `SPEC.md` is rewritten to match. What
follows are working notes for those milestones, detail the plan does not carry.

- **R1 is built, all four pieces.** The chest rule; the walk-back check in
  CI with a ladder home in nine rooms; the bailey's switch moved into the face
  ahead of the yard, with a glinting slot, a small light, and a gold chain to
  the gate on the level above that lights and runs when a blade lands; the
  cage a lit, chained dragon behind sparse bars over the quiet stretch, facing
  you, breathing, a puff of smoke every few seconds and one roar as you come.
  To judge in play: whether the smoke is too faint, and whether the roar (the
  Act 2 dragon's own) startles a kid in a good way. The rungs ladder softens
  that room's barrier lesson. Act 1's gate room (room 4) still sets its switch
  behind you after the drop; once the bailey has taught it, that may be a fair
  twist rather than a trap, but watch for it.
- **R2 is built.** The sword (one sprite, spun in flight, its tip hidden in
  the face when embedded), a doorway per act in place of the gold exit, and
  Lothar seated astride the dragon for the ride, all in `ART.md`. To judge in
  play: the doors' picks (a one-line swap in `config/actN.tres` to another
  candidate), and whether the spinning 16 px sword shimmers.
- **R2, the flame, is built.** The breath is a cone (`SPEC.md`'s own word),
  not a box: it leaves the jaws at head height and spreads down to the floor
  by a third of its reach (`DragonBreath.cone`, `dragon_cone_*` in
  `config/enemies.tres`), and that cone is both what kills and what is drawn
  burning. White-hot at the jaws, cooling through orange and red, frayed and
  rising into dithered smoke past the cone's top and far end (`flame_spill`,
  seen, never lethal), with embers thrown along it. The kill area shrank under
  the jaws only, beside the dragon's own body. The freed dragon's breath in
  Act 4 (`FreedBreath`) is a separate drawing and was not touched; give it the
  same plume if it reads as flat next to this one.
- **R3, the level format, is built.** `levels/*.level`, 16 px a cell
  (Matt, 2026-10-07): a `[map]` and a `[things]` list, read by `LevelGrid`
  (`scripts/logic/`), built by `GridRoom`. The bailey is ported. Not yet in
  the legend: copper, barriers, current switches, plates, gems, the eyeball
  and the ant. Add each when the first level needs it.
- **R3, tall rooms and frame time.** A room can now be taller than a screen
  (`Bench.room_height`, from a level's map or its `height` line), and the
  light field, far backdrop and dust follow. `levels/test_tall.level` is ten
  screens by five floors; `tools/dev.sh frametime` measured it in this
  container's software renderer at 26.3 ms mean, 32.6 ms p95, against the
  one-screen bailey's 25.0 and 28.5: about the same cost for fifty times the
  area. Both are over 16.7 ms only because nothing here has a GPU. Matt's
  machine gives the number that counts.
- **A tall level needs its own background painting.** The act's one-screen
  painting is repeated down a tall room, every other copy flipped, as a
  stopgap; a castle five floors tall wants a painting made for it. G2.
- **R3, respawn.** Resetting every mechanism in a ten-floor level would undo a
  gate opened half an hour ago. Reset only what belongs to the brazier's
  section. This is the debt entry below, finally with a reason to pay it.
- **R3, a tile's collision line** becomes a per-tile property of the format,
  which retires the one-off measuring scan (debt, below).

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
  vines as ladders with other art (`LEVELS.md`, 2026-09-28 decision 7). New
  systems still needing a yes: two-way portals (decision 8 kept the one-shot
  stump warp).
- **Spikes where lava cannot go**: teeth on top of the ledge you land on. The
  56 px jump cannot clear a bed on a 32 px step, so it wants a moving platform
  or a sword ledge to arrive on. Revisit when building a level.
- **Every room has a chest**, so swords carrying between rooms never bites.
  Now that chests fill your hand (`SPEC.md`), they are placed for fights rather than given per room,
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

- **A chest is now unlimited ammunition while you stand in it** (R1, the
  chest rule). Any target in range of a chest can be thrown at forever. Fine
  for every room today; a big level should keep chests out of throwing range
  of a fight that is meant to cost swords.
- **`spike_grace`** may be a dial nobody can feel. Setting it to zero moved
  the takeoff window by nothing. Keep or delete.
- **A pull can lose a sword into the dais recess.** The room's chest refills
  to three. Right cost, or throw swords clear?
- **The throne has one conductor, not a choice of two.** Every decoy layout
  blocked the path.
- **The sounds** have now been heard and the music landed. Any sound effect
  that did not, note it here.
- **Matt's play log** (`user://`, PR #136) from this playthrough would show
  where the time and deaths went. Worth sharing before R1.

## Code and tooling debt

- **The hero reaches into the room's mechanisms on a respawn.** It walks the
  "mechanisms" group from inside `player.gd`, knows they have clocks, and
  hands one a number from `config/death.tres`. A signal carrying "the player
  has the controls back", with the room resetting what it built, says the
  same without the hero knowing. Half a day; touches `player.gd`, `bench.gd`,
  both platforms, the geyser and the sword. Now part of R3.
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
