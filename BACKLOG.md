# BACKLOG.md

Mid-build ideas land here, never in the active milestone. Nothing in this file is
committed to until Matt says yes. Resolved entries are deleted; `git log` keeps
them.

**Triaged 2026-10-13.** The 2026-10-06 playtest notes and the R1 to R3 build
notes are gone: every one became a milestone, and what each left to judge in
play is in `HANDOFF.md`'s open list. What is still open from them is below.

## Left over from R1 to G2

- **A tall level needs its own background painting.** The act's one-screen
  painting is repeated down a tall room, every other copy flipped, as a
  stopgap; a castle five floors tall wants a painting made for it.
- **The respawn sword cap is an assumption, not Matt's words.** If the hand
  plus the swords stuck in walls would pass five on a death, the oldest stuck
  ones go, so dying never farms ledges (`RespawnRules`).
- **A mechanism's respawn reach is measured from its own position**, and the
  giant ant's sits at the room origin. Check it the first time an ant goes
  into a big level.
- **The forest's river is a spiked gorge** because there is no water. Water
  that kills could be lava's rule with its own shader.
- **The freed dragon's breath in Act 4** (`FreedBreath`) is a separate drawing
  from the R2 flame. Give it the same plume if it reads as flat beside it.
- **The old outer wall's questions, for the beat sheet** (N3): whether the
  high road's bats are fair or just a toll, whether the skeleton reads as a
  surprise or a scorpion, and whether the castle's plinth switch is found.

## Ingredients for the big levels

Older entries that were waiting for content to use them. Most are now
needed rather than optional, because the content is about to exist.

- **Mixed enemy groups.** All six species are built. Combinations to try: an
  eyeball patrolling the catch line of a scorpion fight, so the safe throw is
  the one it eats; bats over a sword ledge; an ant on the ceiling above a
  switch, so standing still to throw is the risk; a dormant scorpion beside an
  awake one. Plus the two variants `LEVELS.md` already decided: the skeleton
  (a dormant scorpion) and the armour-flipped guard.
- **The giant ant is placeable and in no level.** Act 3 is the obvious home:
  seven rooms with no creature but the generator. Check first what an ant does
  when it walks into an embedded sword.
- **Two-way portals**, a new system still needing a yes (`LEVELS.md` decision
  8 kept the one-shot stump warp). Lifts and geysers are placeable now.
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
  sword, the wood/stone fake-out once or twice, a sword graveyard for
  atmosphere, the chandelier.
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
- **N2's forest decoration is derived, not drawn** (`tools/derive-decor.py`):
  tufts are the lip's grass grown taller, roots are the soil's roots let out.
  Good enough to judge the rules by. A drawn set (tufts, roots, ferns,
  fungus) is one or two Sprite Fusion requests, gated on Matt's approval.
- **Torches come from the rules, so they follow the back wall.** Every
  back-wall stretch at floor level gets one each ten cells. In the gatehouse
  passage one hangs where the guard stands. Fine in a shot; play it.

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
- **The storm (2026-10-24).** A full-screen flash every 10 to 24 s, held
  0.05 s and cleared in 0.18. Is it too often, too bright, or does it ever
  hide a hazard at the wrong moment? `config/storm.tres` has every dial.
  The pause menu's FLASHES row scales it down to nothing (`Flashes`).

## Code and tooling debt

- **No tool measures where a tile's art meets its collision line.** Done by a
  one-off scan for `room_m5_wall`. It belongs in the level format as a
  per-tile property; N2's `TileShape` does not do it.
- **`tools/cut-rig.py` only knows named rectangles.** Mostly moot since the
  move to frame animation; keep only if a rig ever returns.
- **F2's bench cycle leaves out ten rooms**: Act 3's generator, rungs and
  toll, all four Act 4 rooms, `room_g2_stump`, `room_m13_gems` and
  `test_tall`. Reachable by `tools/dev.sh play` only. Deliberate or not is
  undecided.
- **Quitting mid-track prints "resources still in use at exit".** Harmless
  noise in CI's log.
- **The castle's floor tiles are 17 by 17 on a 16 px grid**
  (`assets/art/act1/tiles_px/floor_top_*.png`). `TileArt.draw_tiled` steps
  by the tile, so a lip's pattern drifts a pixel a cell against the cells
  under it and the masonry below starts a pixel low. Invisible so far;
  cropping to 16 is the fix, and it changes every castle shot.
- **`GridRoom` levels bake; hand-written rooms still draw every frame.** Acts
  2 to 4 are `Bench` rooms drawn in `_draw`. They move to the level format in
  R4, and the bake comes with it.
- **`tools/dev.sh shot` adds the room as a child, not the current scene.**
  Anything reading `current_scene` (the debug overlay's room tag) is blank in
  its shots; a movie-writer launch shows it. Shots may differ from play in
  other ways that read the scene the same way.
- **Two storms in Act 4.** `amb_hall` bakes a distant thunder roll into
  its loop at 6 s, which now plays out of step with the real strikes
  (`Storm`); and `backdrop_hall.gdshader` still draws its own rain and
  flash, unused since Act 4 got a painted background (`backdrop = 0`).
  Re-render `amb_hall` without its thunder, and drop the hall backdrop's
  rain and flash or the whole Hall style if nothing will use it.

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
