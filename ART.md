# ART.md: the asset pipeline

> `ART_DIRECTION.md` owns what the art should look like. `ANIMATION.md` owns what
> moves and how. **This file owns how a picture gets from a prompt into the
> game**, and the open requests. `GEMINI_NOTES.md` owns what was learned about
> the previous generator, and is still **required reading before writing any
> prompt**: most of it is about prompting in general, and none of it has been
> re-tested against Sprite Fusion yet.

## The generator changed, 2026-09-26

**From Gemini, driven by hand, to the Sprite Fusion API, driven by Claude.**
Sprite Fusion only makes pixel art, so the art direction moved with it
(`ART_DIRECTION.md`) and so did animation (`ANIMATION.md`). The API does five
things: *generate* from a prompt, *edit* an existing sprite, match a *style
reference*, make *8 directions* of one sprite, and *animate* a still into
frames. The last one is the reason for the switch.

Base URL `https://www.spritefusion.com/api/v1`, bearer-token auth,
`POST /generate` (streams Server-Sent Events), `POST /uploads` (short-lived
upload URL for a large input), `GET /credits`. The key lives in the
`SPRITE_FUSION_API_KEY` environment variable and **nowhere in this repo**: not
in a file, a log, a URL, or anything that ships.

**The client is `tools/sprite-fusion.py`.** A generation is a dry run
unless `--spend` is passed, since spending credits is the irreversible step
here. Deliveries land untouched in `assets/art_raw/` as `NAME_<index>`, and
every request is appended to `assets/art_raw/sprite-fusion-log.jsonl` with its
asset ids, which is how a later edit or animate finds its source.

**What the API docs say** (read 2026-09-28; where they turned out wrong, it says so):

- **Every request costs 15 credits**, whatever the operation, reserved up
  front and refunded only if nothing was saved. A `generate` returns several
  variations for that price.
- **Output is 16, 32 or 64 px square, nothing else.** True of `generate`
  only. `edit` and `style-reference` ignore `size` and come back as large as
  94 px (`GEMINI_NOTES.md`, *Sprite Fusion, measured*). **A 640x360
  background cannot come from this API**, which is what *Four layers* below
  answers.
- **No sheets.** The docs forbid asking for a grid, atlas or several poses on
  one canvas. Each pose is its own `edit` of the source sprite.
- **Animate from a matching pose.** For a run, a throw or a jump, `edit` the
  still into that action's starting pose first, then `animate` that. Idle can
  animate the still directly. **Open for M6:** `edit` does not hold size, so
  the pose step needs another route (see *M5 in pixel art* below).
- **Prompts describe the subject only.** No pixel sizes (that is `--size`),
  no "transparent background" or "pixel-perfect". The agent guide calls these
  noise.

**First delivery, 2026-09-28: the hero, one `generate` at size 64.** 12
variations for 15 credits (`assets/art_raw/hero_lothar_px_*.png`, contact
sheet at 4x in `assets/art_raw/_experiments/hero_lothar_px_contact.png`).
Measured:

- **The side view was ignored by 9 of 12.** The nine polished ones are a
  three-quarter front stance, the exact default `GEMINI_NOTES.md` fought on
  the painted hero. The three that did draw a profile (1, 2, 3) face left
  instead of right, which `flip_h` fixes, and are visibly rougher.
- **Size 64 does not mean 64.** The nine three-quarter ones came back 73x73
  with the figure filling all 73 rows. The profiles are 64x64 with the figure
  58 to 62 px tall. **Either way the hero is 1.5 to 1.8 times
  `config/world.tres`'s `hero_height` of 40**, and pixel art cannot be
  resampled down to fit. Decided since: size 32, a 34 to 40 px hero
  (`ART_DIRECTION.md`, *Scale and resolution*).
- **Real transparency, hard edges.** No partial alpha anywhere, so no key
  step for Sprite Fusion deliveries.
- **Not a small palette.** 1,100 to 3,100 distinct colours per sprite. Six
  fail `palette-check.py` narrowly (0.5% to 2.6% neutral-dark pixels), which
  a palette remap fixes. `generate` has no colours parameter; `animate` does.
- **`media.spritefusion.com` answers 403 to urllib's default User-Agent.** The
  tool now sends its own and records every asset id before downloading.

## Four layers, each made the way that suits it

Decided 2026-09-28, because Sprite Fusion cannot make anything over 64 px.

| layer | what | how |
|---|---|---|
| far background | atmosphere, parallax, designed to repeat | painted in Gemini (the M5 pipeline), then `tools/pixelate.py` to 1x at the room's height |
| playfield | everything the hero stands on or touches | Sprite Fusion tiles, `generate` at 16 px (style reference ignores size) |
| props | windows, torches, the caged bird, banners | Sprite Fusion sprites, 32 or 64 px |
| light | glow, torchlight, fog, heat | code: shaders, lights, particles (`CLAUDE.md`) |

**The light layer is what makes the other three one picture.** A painted,
pixelated back layer and generated front layers only look like one place
when the same coloured light falls across all of them.

**Since 2026-10-04 the light layer has a dark as well as lights.** Every room
in an act carries a `LightField`: the whole room multiplied by the act's
`ambient_light` (a coloured dark, set in `config/actN.tres`), lifted back
wherever a `LightSource` reaches, banded and dithered on the art-pixel grid.
Braziers, torches, lava, live copper, arcs, gems, the sword and the hero are
the lights. Anything that is itself light (lava, glows, arcs, flames) draws
over the dark through `LightField.emissive`, so the dark never dims the thing
doing the lighting. Benches stay lit evenly.

**Acts 2 to 4 have code-drawn far layers until theirs are painted.** A
`Backdrop` (a shader, two layers of parallax, every colour a mix of
`Palette`'s) draws the caverns, the generator's works and the hall, and
`test_backdrop.gd` holds it under the stone you stand on. A painted
background replaces it with one line: give the act's `ActTiles` its
`background` and set the act's `backdrop` to 0, which the same test then
expects.

**Pixelating works on large, simple shapes**, so a background prompt asks for
big forms and few small details. Act 1's wall converted cleanly at 24
colours (`assets/art/act1/wall_moat_bg_px.png`), passes `palette-check.py`,
and its lit windows survive because the tool reduces colours by octree, not
by area (the tool's docstring has the comparison).

**Tiles repeat often enough to pick from.** Sprite Fusion makes single
sprites, not tilesets, but tiling each of a request's 12 variations 4x4
showed several seamless ones every time. No hand fix was needed.

## M5 in pixel art: what it took (2026-09-28)

**14 requests, 210 credits.** Eight of them built the room; six were
diagnosing `edit`'s size bug and trying operations for the first time.

| asset | recipe | requests |
|---|---|---|
| hero still | `generate` at 32 (size holds, pose is three-quarter), then `direction-set` on the best one: index 3 is a right-facing profile at 36 px | 2 |
| hero idle | `animate`, 4 frames, from the still | 1 |
| bat | `generate` at 32, then `animate`, 4 frames of flap | 2 |
| floor top, wall fill, ladder | `generate` at 16, one request each, the seamless variation picked | 3 |
| background | none: the painted wall already pixelated (*Four layers*) | 0 |

**So a room like this costs about 8 requests, 120 credits, once the recipe
is known.** Ground tiles then go through `tools/tile-variants.py`, and the
room scatters the variants (`TileVariety`) and steps the masonry darker below
each lip (`Palette.GROUND_SHADE`), which is what keeps a wall face under the
hero's brightness and just above the background's. Every delivery then goes through `tools/recolour-darks.py` and
`tools/palette-check.py` before it leaves `art_raw/`.

**What is in the game**: `scenes/hero_sprite.tscn` and
`scenes/bat_sprite.tscn` (frames on an `AnimatedSprite2D`, picked by an
`AnimationTree`), and `scripts/room_m5_wall.gd` drawing the tiles and the
background at 1x. The painted rigs are no longer drawn anywhere; M6 deletes
them. The texture filter is Nearest and the stretch is integer. The room as
it renders: `assets/art_raw/_experiments/m5_pixel_room.png`.

## M6: the hero's states (2026-09-28)

**12 requests, 180 credits.** Every state is `animate` from the same 36 px
still, no pose step (`GEMINI_NOTES.md`, *Sprite Fusion, measured*), except
the climb, animated from the back view `direction-set` already made. Frames
chosen per state, from `assets/art_raw/hero_*_anim_0_sheet.png`:

| state | frames used | note |
|---|---|---|
| idle | 0 to 3 | the M5 loop |
| run | 1 to 5 | 0.25 s a cycle, to be checked against ground speed by playing |
| jump | 1 to 3 | crouch, spring, tuck |
| fall | jump's 3 | the fall request came back as the still four times |
| land | 1 to 3 | |
| throw | 3 to 5 | release and follow-through: the sword leaves on the press, so a wind-up would play after it had gone |
| catch | 1 to 3 | |
| climb, climb_still | back view 1 to 3, and 0 | |
| die | 1, 4, 5 | 2 and 3 were a pure-white flash |
| somersault | 1 to 7 of 8 | the request came back as a real full flip: spring, tuck, inverted, open |
| dive | 2 and 3 of 4 | the two angled head-first frames, looped |
| dive landing | 1, 2, 3, 5 of 6 | impact, deep crouch, hold, rising; fits the 0.25 s recovery pause |

The sheets are assembled at 36x36 into `assets/art/hero/hero_<state>_sheet.png`
and recoloured. `scenes/hero_sprite.tscn` joins every state to every other
with a cut. Land, throw and catch keep the rig's lengths, because the Player
reads its pose holds from them.

**Open, for whoever is next:**

- **The dive pose is brief on a one-storey drop.** Terminal velocity is 700 and
  a storey is 96 px, so the hero is past `dive_fall_speed` (640) for about 20 px
  of it, two or three frames. Lower the threshold, or accept that the dive shows
  on bigger falls. `ANIMATION.md` has what else the threshold decides.

## M7: the enemy sheet (2026-09-28)

**12 requests, 120 credits, and the balance is now 0.** Four creatures, each a
`generate` and an `animate` from the chosen still, all with the bat's own style
clause ("it kills on contact, so it is warm and saturated... coloured darks,
deep warm umber, never neutral black or grey") so they match without a shared
reference image. One `animate` failed at the SSL handshake before reaching the
API, charged nothing, and was retried once.

| enemy | `generate` size | picked | walks or loops | notes |
|---|---|---|---|---|
| scorpion | 32 | 6 of 12, 37 px | 4-frame walk | the paler armoured claws and face are the tell for "hit it from behind" |
| ant | 32 | 4 of 12, 37 px | 4-frame crawl | rotates by exact 90 degree steps on its loop, which stays crisp |
| eyeball | 32 | 9 of 12, 38 px | 4-frame float and pulse | one forward-looking frame set; does not track |
| dragon | 64 | 4 of 12, 74 px | 4-frame slow breathing | art faces right and mirrors to the breath |

All four came back facing right on request, which the room mirrors by
`_face_sprite`. Every sheet is padded to an even width so mirroring around the
node's origin does not shift a pixel. **Identity held across frames**: mean
colour drifted under 3 of 255 and the bounding box moved by a pixel, the same
as the hero.

**What is in the game**: `scenes/<name>_sprite.tscn` for each, the shared
handling in `Enemy` (`_attach_sprite`, `_face_sprite`, a dormant enemy's sprite
holds still, measured 0 of 7,200 pixels changing against 4,288 for an awake
one), `TileArt` (the ground drawing pulled out of the M5 room so a second room
can use it), and `RoomM7Sheet`, the lineup bench (F2 in the overlay). The
placeholder rectangles are gone; the dragon's breath is still the drawn
rectangle that kills. `tests/test_enemy_sprites.gd` holds that every animation
shows real frames of its own name, and that each ground creature's feet land on
its killing box's bottom edge and are centred on it.

**Silhouettes** (`ART_DIRECTION.md`, rule 1) are all distinct at game size: the
upright hero, the curled tail and claws of the scorpion, the three body
segments of the ant, the wings of the bat, the round eyeball with tendrils, the
big horned dragon. `assets/art_raw/_experiments/m7_silhouettes.png`, and all six: `m7_six.png`.

**The generator, the sixth (2026-09-30).** A `generate` at 64 (picked 4 of 12,
72 px, a horned dynamo with a fire grate) and a 4-frame hum, with 0 neutral
darks in either. It has no behaviour until M12, so `RoomM7Sheet` stands its
sprite alone at the right, and the room grew to 760 to fit it. **Its arc is
painted into the frames**, which `CLAUDE.md` says is the wrong approach
(`BACKLOG.md`).

## Act 1 props (generated 2026-09-30, wired 2026-10-03)

Wired into `Act1Bailey` and `Act1Gate`: wood pick 3, chain 2 and shackle 1 as
listed, and portcullis **6**, because picks 1 and 5 have crossbars and a gate
drawn with them reads as a ladder, which is a climbable thing in this game.
The switch and brazier stay drawn in code: the switch's slot shape was found
by playing (`SwordSwitch`), and the generated ones came back as barrels.

The last 90 credits, one `generate` each, all in `assets/art_raw/` and none
picked or in the game yet. The rooms still draw these as rectangles.

| delivery | size | usable | notes |
|---|---|---|---|
| `tile_wood` | 16 | 1 to 6 | planks; 1 and 6 fail the palette check |
| `tile_portcullis` | 16 | most | for `Gate`, repeats top to bottom |
| `prop_switch` | 32 | 1, 8 | some came back three-quarter barrels; 10 of 12 need `recolour-darks.py` |
| `prop_brazier` | 32 | most | unlit, the flame stays code; 10 of 12 need `recolour-darks.py` |
| `tile_chain` | 16 | 7 to 11 | for the chained dragon |
| `prop_shackle` | 16 | 1, 8, 9 | where the chain meets the wall |

## Act 1 outer wall, batch 1 (2026-10-03)

Four `generate` requests, 60 credits, each usable first time. In
`assets/art_raw/`, contact sheet with tiles repeated three across at
`_experiments/batch1_contact.png`. Wired into `Act1Wall` on 2026-10-03 (crumbling stone moved to pick 8, since 9
leaves a blank right column that shows as a seam); the processed tiles are in
`assets/art/act1/tiles_px/` and the torch in `assets/art/act1/props/`. The room
as it renders: `_experiments/act1_wall_{climb,gatehouse,breach}.png`.

| delivery | size | picks | notes |
|---|---|---|---|
| `tile_battlement` | 16 | 0, then 9, 11 | 0 is the clearest merlon-and-gap row; 1 and 6 are off-palette saturated blue; 8 came back 18x18 |
| `tile_spikes` | 16 | 0, 9 | all pass the palette check; 10 and 11 are brightest and risk competing with lava |
| `tile_stone_crumble` | 16 | 9, 7, 8 | a top-half slab with cracks; 2 to 4 are full-tile and too saturated |
| `prop_wall_torch` | 32 | 6, 7, 9 | 9 of 12 fail the palette check on neutral iron, and `recolour-darks.py` fixes all three picks |

**The one-request recipe held for tiles and props**: the prompt shape in the
log (subject, side view, what repeats, palette in words, coloured darks) gave
several usable picks in every request. Iron still comes back neutral, so budget
`recolour-darks.py` for anything iron, as with the brazier and switch.

## The sword chest (2026-10-03)

One `generate` at 32 (`prop_sword_chest`, prompt in the log), after a first try
came back HTTP 403 with nothing generated. Pick 2: side on, three gold hilts
upright, passes the palette check (only 1 to 3 do). Wired as `SwordChest`.

## Act 2 tiles, batch 1 (2026-10-03)

Four `generate` requests at 16, 60 credits, plus three HTTP 403s that cost
nothing and went through on retry. Picks: cavern floor 2, cavern wall 3, basalt
slab 4 (cropped to its rows), mine beam 1; all pass the palette check. Floor and
wall variants from `tools/tile-variants.py`, whose damp green cast is the moat's
and wrong for a dry cavern: worth a `--dry` flag before Act 2 ships. Drawn
through `ActTiles` (`assets/art/act2/act2_tiles.tres`). Contact sheet:
`_experiments/act2_batch1_contact.png`; in a room: `_experiments/act2_mouth_*.png`.

**Act 2's background is painted** (2026-10-05), and its code `Backdrop` is off.

**Act 2 background, attempt 1 (2026-10-05), landed first time.** Built on Act 1's
landed attempt 3: the same M5 preamble (the painting is pixelated afterwards,
so a painterly source is what `pixelate.py` wants), the same flat stage-
backdrop framing, the same bay repeated three times. Two things are new for a
cave. A rock shelf in a painting reads as somewhere to stand, so every form is
vertical or hanging. Lava painted on the far wall would compete with the
lava that kills you, so the painting shows only lava's light, from below the
frame, as the code `Backdrop` already does with its crust-only lavafalls.
Raw delivery to `assets/art_raw/act2_cavern_bg.*`.

> [preamble] A wide painted background for a side-scrolling platformer: a
> long horizontal strip of the far wall of a vast underground lava cavern, in
> flat side view like a stage backdrop, camera perpendicular to the wall,
> with no vanishing point. It is NOT a three-quarter view, NOT a tunnel
> receding into the distance, and NOT seen from above. The same bay of rock
> repeats three times across the width of the canvas: a heavy curtain of
> stalactites hanging from the top edge, a tall dark column of rock where a
> stalactite has met a stalagmite, then a deep recess where the cavern wall
> falls back into darkness, evenly spaced, so the whole strip reads as a
> continuous run of cavern rather than one view of one place. Rock fills the
> full width of the canvas and the whole top edge: no sky, no opening, no
> daylight anywhere. The cavern is lit only from below, by a red-orange glow
> rising from beneath the bottom edge of the frame: the lower third of the
> wall is warm, ember-lit rust and dull brick red, fading upward into cold
> violet-blue rock, and the top of the canvas is the darkest part of the
> image. The glow is the point of this painting: do not paint the cavern as
> one flat dark tone. No lava is visible anywhere: no lava rivers, no
> lavafalls, no pools, no flowing fire, only the light it throws. There are
> no ledges, shelves, steps, bridges, platforms or flat-topped rocks anywhere
> in the painting: every rock form is vertical or hanging, so nothing in it
> looks like somewhere to stand. No characters, no creatures, no torches, no
> ruins, no chains, no crystals, no foreground rocks. Large, simple shapes
> and few small details: big masses of rock and broad, soft gradients of
> glow. The whole painting stays dark and muted, a background meant to sit
> behind brighter platforms. Cold rock is blue-violet grey, deep violet in
> shadow; the warm light on it is dull rust and brick red, going to amber
> only in its brightest touches and never to yellow or white. The image is
> 2560 by 1440 pixels, aspect ratio 16:9.

**Landed.** Flat side view, three bays, stalactites, the glow from below, no
lava, nothing to stand on. Delivered 1376x768 (ratio 1.792 again). Raw at
`assets/art_raw/act2_cavern_bg.jpg`, untouched.

**Cropped to its third column before pixelating**, because a room tiles the
painting with every other copy mirrored and the uncropped right edge, a
recess, met its own mirror as a symmetrical double arch that read as a
skull. A column mirrors into a column. `pixelate.py` gained `--crop` for it:

    tools/pixelate.py assets/art_raw/act2_cavern_bg.jpg assets/art/act2/cavern_bg_px.png --crop 0,1103

517x360 at 24 colours; `palette-check.py` 0.00% neutral-dark. It loses to
the playfield by a wide margin: no pixel as bright as mid stone (Act 1's
wall has 19%), and its most saturated colour is 0.66 against lava's 0.86.
No painted light sources, so `ActTiles.lights` stays empty; the room's own
lava light lifting the wall above each pit is what makes it look lit.

The code `Backdrop`'s nearer layer is not drawn over it: the painting has
columns of its own, and both would be two sets of pillars. **For Matt's eye
in play:** the mirror seam reads as a symmetrical column, a little like a
carved totem, every 517 px; and the warm lower band is where enemies stand,
so a dark red bat has less contrast against it than against the old purple.
Rim light carries it in every shot so far.

**Act 3 background, attempt 1 (2026-10-05), landed first time.** Act 2's
recipe for the generator's works. Three exclusions are new: no electricity
of any kind, because an arc is the act's hazard and the only cool bright in
the game (`ART_DIRECTION.md`), so a painted one would be read as live; no
copper, brass or gold, because copper means conductive here and gold means
interactive; and nothing horizontal, because a pipe run, a beam or a
catwalk in a painting reads as somewhere to stand. Evenly spaced stone
piers give the mirror seam a column to fall on, as Act 2's did. Raw delivery
to `assets/art_raw/act3_works_bg.*`.

> [preamble] A wide painted background for a side-scrolling platformer: a
> long horizontal strip of the far wall of a vast underground machine hall
> beneath a castle, in flat side view like a stage backdrop, camera
> perpendicular to the wall, with no vanishing point. It is NOT a
> three-quarter view, NOT a corridor receding into the distance, and NOT seen
> from above. The same bay repeats three times across the width of the
> canvas: a tall, plain pier of dark dressed stone running from the top edge
> to the bottom edge, then a stretch of riveted dark iron wall with a bundle
> of thick vertical pipes rising up it, and set into that wall one enormous
> dormant flywheel, a great spoked iron wheel half sunk into the masonry,
> evenly spaced, so the whole strip reads as a continuous run of machinery
> rather than one view of one place. Machinery and stone fill the full width
> of the canvas and the whole top edge: no sky, no windows, no daylight
> anywhere. The hall is lit only by a faint, cold blue-green light falling
> from high above the top edge of the frame: the upper part of the wall
> catches a little of it on the edges of the iron and the curves of the
> wheels, and the wall falls into deep cold darkness toward the bottom of
> the canvas. That fall from a little cold light above into darkness below
> is the point of this painting: do not paint the hall as one flat dark
> tone. There is no electricity anywhere: no lightning, no arcs, no sparks,
> no glowing coils, no glowing lamps, no lit gauges, nothing that shines on
> its own. There is no copper, no brass and no gold anywhere: every metal
> is dark blackened iron, cold blue-grey where light touches it. There are
> no horizontal pipes, no beams, no girders, no catwalks, no walkways, no
> ledges, no shelves and no platforms anywhere in the painting: every pipe
> and every form runs vertically or is round, so nothing in it looks like
> somewhere to stand. No characters, no creatures, no chains, no cables
> strung across, no ladders, no doors, no foreground objects. Large, simple
> shapes and few small details: big masses of stone and iron and broad,
> soft gradients of light. The whole painting stays dark and muted, a
> background meant to sit behind brighter platforms. Stone and iron are cold
> blue-violet and slate blue in the light and deep navy-violet in shadow,
> never a neutral grey or black. The image is 2560 by 1440 pixels, aspect
> ratio 16:9.

**Landed.** Three bays of stone pier, pipe bundle and a half-sunk flywheel,
lit cold teal from above and falling to dark below; no electricity, no
copper, nothing horizontal. Delivered 1376x768. Raw at
`assets/art_raw/act3_works_bg.jpg`, untouched. **No crop needed**: the bays
repeat every 460 px and both edges of the canvas already fall within a few
pixels of a pier's centre, so the mirror seam is a pier with a flywheel each
side of it, which reads as built rather than as a seam:

    tools/pixelate.py assets/art_raw/act3_works_bg.jpg assets/art/act3/works_bg_px.png

645x360 at 24 colours; `palette-check.py` 0.00% neutral-dark; 0.62% of its
pixels at or above mid stone (the teal-lit top of the iron), most saturated
colour 0.62 against lava's 0.86. Act 3's code `Backdrop` is off. **For
Matt's eye in play:** the thin cyan wires that show where current runs now
sit over a teal-tinted wall; they read in every shot, about as faint as they
were before.

## The chained dragon (2026-10-03)

Two requests, 30 credits: an `edit` of `enemies/dragon_px.png` into a chained
pose (pick 1 of 2: head dragged low, chains over its back, rings in the floor),
then a 4-frame `animate` of it straining (`enemies/dragon_chained_sheet.png`,
95x70 a frame; filmstripped, no boil). The `chained` state of
`scenes/dragon_sprite.tscn`, reached from `Dragon._defeat` through the
AnimationTree. In the lair: `_experiments/act2_lair_chained.png`.

## Act 3 tiles, batch 1 (2026-10-04)

Three `generate` requests at 16, 45 credits (690 left): deep floor 0 and deep
wall 0 (dark dressed blocks, matching), copper plate 2 (the most muted, so dead
metal stays cold and matte against the live shader). `ActTiles` set:
`assets/art/act3/act3_tiles.tres`. Contact sheet:
`_experiments/act3_batch1_contact.png`; in a room: `_experiments/act3_*.png`.

## M9: lava, electricity and atmosphere (2026-09-28)

**Nothing here is generated: no credits, no PNG.** Taken while credits were 0
and M8's tilesets needed some.

- **Lava** (`shaders/lava.gdshader`, `LavaSurface`): warped noise drifting
  across a gradient, quantised to `ART_DIRECTION.md`'s four bands (crust, flow,
  fissure, core), a bright wobbling crest, and bubbles that grow as a ring and
  pop as a flash, all computed on the art-pixel grid. Over it: embers
  (`CPUParticles2D`, 2 px squares cooling hot to crust), a heat haze that shifts
  what is behind it by whole art pixels (`heat_haze.gdshader`), and its light
  thrown up the wall as a **Bayer-dithered dome** (`glow.gdshader`). A banded
  dome without the dithering read as a target of concentric rings; dithering
  between the bands is how pixel art shades a falloff.
- **Arc** (`ArcBolt`, `ArcPath`): a new jagged bolt 14 times a second by
  midpoint displacement, whole-pixel vertices, a halo, a body and a one-pixel
  core, a fork most of the time, sparks at both ends. `ArcPath` is pure and
  seeded and has eight tests.
- **Charged surface** (`charged.gdshader`, `ChargedSurface`): filaments crawling
  over a dark base, for Act 3's conductive floors.
- **The light layer** (`light.gdshader`, `LightGlow`): a coloured point light
  added over everything under it (wall, tiles, hero), banded and dithered like
  the lava's glow through the shared `dither.gdshaderinc`. A lit brazier throws
  amber and flickers, the dragon's breath swells with its charge, an arc throws
  cool cyan. Amber from below and cyan from above on the same wall is the
  "same coloured light falls across every layer" `ART.md` asks for. References:
  `_experiments/m9_light_brazier.png`, `m9_light_dragon.png`, `m9_light_arc.png`.
  A light near a room's edge spills into the void beyond it, so a brazier wants
  to sit a light radius (60 px) inside a wall.
- **Every number** is `config/atmosphere.tres`; **every colour** is `Palette`.
  `tests/test_atmosphere_is_code.gd` holds that no effect loads an image and no
  shader samples anything but the screen.

**Measured in a running build** (`assets/art_raw/_experiments/m9_motion.png`):
between frames the lava changes 2,100 to 4,000 of 19,720 pixels, the arc reshapes
every sample, and the plate's filaments crawl. The rendered lava and arc regions
have 0 neutral-dark pixels (`palette-check.py`).

**Every lava pit in the game now uses it**: `Bench._add_lava` places a
`LavaSurface` over the same rectangle the `Hazard` kills in. The room to look at
is `RoomM9Atmosphere` (F2 in the overlay).

**Tuning left for M14**: how bright the lava is against the hero, the haze's
strength, the glow's reach, the lights' radii and strengths, and how often an arc reshapes. All in the one file.

## The pipeline, four steps

1. **Claude writes the prompt and calls the API.** No human round trip, so a
   generation costs credits rather than an hour of Matt's time. A prompt that
   saves a generation is still worth writing carefully.
2. **Key it, if needed.** Whether Sprite Fusion returns real transparency or a
   backdrop to key out is not known until the first delivery. If a backdrop,
   `tools/key.py`.
3. **Cut it.** A sheet becomes N sprites (`tools/cut-sheet.py`). An animation
   becomes frames on a common baseline for a `SpriteFrames` resource.
4. **Check it.** `tools/palette-check.py` against `ART_DIRECTION.md`, and a
   screenshot, plus a filmstrip for anything that moves, of the thing in the
   actual game.

## The rules that came from the last project

Paid for in real generations on Hook, Line and Sentence and on M5 here. They
were learned on a painting generator. Each one is a hypothesis for Sprite
Fusion until it has been tried once.

**Don't generate a piece you could derive.** One idle sprite should be the
source of the run, the throw and the somersault (via *animate* and *edit*),
not a fresh prompt per state. Derived art matches by construction.

**Put the two things hardest to tell apart side by side.** On the last
project a rainbow trout and a steelhead were separated correctly first attempt
when drawn against each other, having been unseparable in words. Sprite Fusion
does not take a multi-subject sheet, so *style reference* is the nearest
substitute: generate one enemy, then the rest against it, passing the ones
already made as references.

**Ask for an edit when there is already a sprite to edit.** Name the one thing
that changes. This is how the hero gets a second costume, or an enemy a variant.

**Art that does not fit is a reroll, not an offset tweak.** At 1x a single
wrong pixel can be fixed by hand, so the bar for "salvageable" is lower than
it was for paintings. Wrong drawn content is still a reroll.

## The tools

| tool | status | does |
|---|---|---|
| `sprite-fusion.py` | new | calls the API, writes deliveries and a request log to `assets/art_raw/` |
| `key.py` | kept, if needed | delivery on a flat backdrop, out comes a transparent PNG |
| `pixelate.py` | new | a painted background in, a 1x pixel-art one out, octree-reduced to a small palette |
| `tile-variants.py` | new | one masonry tile in, N variants out, each brick shifted a little in shade, a few damp or chipped; mortar untouched so every variant joins every other |
| `recolour-darks.py` | new | gives every pixel `palette-check.py` flags the hue of umber or violet-blue, from its nearest clean neighbour, at its own brightness |
| `palette-check.py` | kept | judges a delivery against `ART_DIRECTION.md`'s coloured-dark rule |
| `cut-sheet.py` | kept | one sheet, N connected components, out come N tight crops |
| `cut-rig.py` | **retires** with the rig | one character painting, out come the rig parts |

**In a pipeline tool, the destructive mode is the flag.** The last project got
this backwards on `cut-angler.py` and paid for it three times: the frequent safe
cut needed an argument while the rare cut that overwrote four committed paintings
was what you got by forgetting one. Make the path that destroys work the one you
have to ask for, and let the tool refuse when nobody asked.

## Godot import settings

- **Filter: off (nearest). Mipmaps: off.** Pixel art at 1x, scaled by whole
  numbers. The project setting `rendering/textures/canvas_textures/default_texture_filter`
  goes to Nearest and the stretch scale mode to integer.
- **Not flipped yet, on purpose.** The painted M5 art in `assets/art/` is 4x
  and depends on filtering, and it would look crunchy under Nearest. The
  setting changes in the same PR as the first pixel-art room, so the game is
  never in a state where one kind of art is drawn wrong.
- Set these in the **import defaults for the folder** (`.godot` presets), not per
  file. Three hundred assets in and a per-file setting is unfixable.

## Budget

**One room in pixel art: about 8 requests, 120 credits**, once the recipe is
known, and 210 the first time (*M5 in pixel art* above). The painted M5 took
10 Gemini generations (*Open requests* below). Every request is 15 credits;
`tools/sprite-fusion.py credits` reads the balance: 300 after M5, 0 after M7's
first four, 150 given by Sprite Fusion on 2026-09-30, and 0 again the same day; 900
after Matt's top-up and the developer's matching gift on 2026-10-03, 840 after
batch 1.

## What is left to generate (estimated 2026-10-03)

**About 62 requests, 930 credits, for everything `SPEC.md` and `LEVELS.md`
describe; about 1,100 with a fifth again for misses.** A lean cut is about 52
requests, 780 credits (*The lean cut* below). This is an estimate built from
the recipes measured above, not a costed order: no row has been prompted yet.

**How a row is counted.** Every request is 15 credits.

- **A tile or a prop is one `generate`.** Its 12 variations give the pick and
  the variants (`wall_fill` came from one request), and recolouring is free.
- **An enemy is a `generate` and an `animate`.** That is what M7 measured.
- **A new pose of an existing character is an `edit` and then an `animate`.**
  `edit` now keeps the input's size (`GEMINI_NOTES.md`, *Re-tested again*),
  which is what makes this the recipe.
- **A new character in profile is `generate` plus `direction-set`**, and then
  one `animate` per state. That is the hero's recipe from M5 and M6.
- **Backgrounds cost no credits.** They are painted in Gemini and pixelated
  (*Four layers*), which costs Matt's time instead. Lava, water, fire, arcs,
  geyser spray and glow are code (M9).

**Already made and not counted again:** the hero's thirteen states, all six
enemies, Act 1's floor top, wall fill and ladder, the moat wall background,
and the six Act 1 props (*Act 1 props* above).

### Act 1: the forest, the moat and the outer wall (15)

| asset | recipe | requests |
|---|---|---|
| tree trunk, wood you can embed in | tile | 1 |
| branch platform | tile | 1 |
| cracked branch (`FallingPlatform`) | prop | 1 |
| canopy and leaves | tile | 1 |
| vine (a ladder, `LEVELS.md` decision 7) | tile | 1 |
| stump portal | prop | 1 |
| forest floor and riverbank | tile | 1 |
| spikes, used in every act | tile | 1 |
| rampart and battlement | tile | 1 |
| wall torch (the flame is code) | prop | 1 |
| siege engine, a timed hazard | prop | 1 |
| skeleton, a reskinned dormant scorpion | enemy | 2 |
| banner or arrow-slit dressing | prop | 1 |
| stone falling platform | tile | 1 |

### The inner castle and the throne room (6)

**Assumed** to sit between Act 1's gate and Act 2's descent, since the
chandelier opens the way down. Where it falls in the act structure is M10's
call.

| asset | recipe | requests |
|---|---|---|
| hall floor top and wall fill | tile, one each | 2 |
| throne | prop | 1 |
| chandelier, dropped by a throw | prop | 1 |
| castle guard, the scorpion with its armour flipped (also the remix rooms' enemy) | enemy | 2 |

### Act 2: the lava caverns (8)

| asset | recipe | requests |
|---|---|---|
| cavern floor top and rock wall fill | tile, one each | 2 |
| floating basalt platform | tile | 1 |
| geyser vent (the spray is code) | prop | 1 |
| mine beams or scaffolding, the act's wood | tile | 1 |
| stalactite dressing | prop | 1 |
| the dragon chained, straining | `edit` of the dragon, then `animate` | 2 |

### Act 3: the generator (11)

| asset | recipe | requests |
|---|---|---|
| conductive metal floor | tile | 1 |
| underground stone wall fill | tile | 1 |
| copper conductor rail | tile | 1 |
| current switch, distinct from M2's impact switch | prop | 1 |
| floor plate (`FloorPlate`) | prop | 1 |
| insulator post | prop | 1 |
| cable and conduit dressing | prop | 1 |
| insulated door | prop | 1 |
| the generator without its painted arc (`BACKLOG.md`) | `edit`, then `animate` | done, 2 |
| the generator burnt out after its short | `edit` | done, 1 |

### Act 4: the Hall of Volta (13)

| asset | recipe | requests |
|---|---|---|
| hall floor top, wall fill, pillar dressing | tile, one each | 3 |
| the chained dragon's anchor or cage | prop | 1 |
| Volta, in profile | `generate`, `direction-set` | 2 |
| Volta's idle, cast, stagger, and fall into the fire | `animate` each | 4 |
| the dragon freed, flying, and carrying the hero out | `edit` once, `animate` twice | 3 |

### Across every act (9)

| asset | recipe | requests |
|---|---|---|
| the hero carrying the torch: idle, run, jump, climb | `edit` once, `animate` four times | 5 |
| gem, gem holder, key | prop, one each | 3 |
| the sword, which is drawn by `sword.gd` today | prop | 1 |

### The lean cut (about 52)

Cut first: the four dressing rows (banner, stalactite, cables, pillar), the
siege engine, and the hero's torch climb and torch jump, if those reuse the
torch run. Volta can drop to three animations, the dragon's carry can reuse
its flight, and the sword can stay drawn in code. That is about 10 requests.
**The castle guard, the skeleton, the chained dragon and Volta stay**: each
one is a decision in `LEVELS.md` or `SPEC.md`, not decoration.

### What could move this

- **Matt's eye on `RoomM7Sheet`.** If the six are not consistent in
  treatment, redoing some adds 5 to 10 requests.
- **Volta is the least designed thing here.** A boss fight with more states
  than four could double Act 4's row.
- **Rooms past the first pass.** Remix rooms reuse act art. A new look for
  a room (a library, a crypt) is about 3 tile requests each.

## What `assets/reference/` is for, and what it is not

53 screenshots of the 1984 original, inherited from the first attempt
(`SPEC.md` → *What the repo inherits*). **It is research, not source art.**

Use it to answer "what was actually in that board" and "what did the floating
eyeball look like" before writing a prompt. `apple2/cast-of-characters.png` and
`apple2/objects.png` are the two most useful single files.

**Never trace it, never rip from it, and never attach one of these images to a
generation request.** Attaching one asks the generator to reproduce someone
else's art, which is both the wrong output for `ART_DIRECTION.md` and the wrong
thing to do. Describe what you learned from it in words instead. The attach
mechanic in `GEMINI_NOTES.md` is for editing **our own** paintings.

## Open requests

**Where deliveries live.** Matt saves exactly what Gemini's download UI gives
him into `assets/art_raw/`, one file per generation, untouched. Pipeline output
(keyed, cut, ready to import) goes in `assets/art/`, organised by what it is
(`act1/`, `hero/`, `enemies/`). A generation that is only a technical test,
never meant to ship, stays under `assets/art_raw/_experiments/` and is never
promoted into `assets/art/`.

**The background and the tileset carry different jobs, and only one of them
is the player's path.** Found the hard way on M5's background: `SPEC.md`
rooms scroll, "a room you move through, not a screen you memorise," so a
background that paints one specific, unrepeatable view (a torch here, a
bridge there) has nothing to its left or right for the camera to pan into.
**The background is atmosphere only, designed to repeat.** The floor, the
ledge, the causeway, whatever the hero actually stands on, is tileset
geometry, placed as real Godot tiles with collision wherever a room needs
one, independent of what the background painting shows underneath it. A
background prompt should never describe a piece of walkable geometry; that
question belongs to the tileset and to room design (M10).

### M5's room: the moat and the outer wall (painted, superseded)

**History, kept for its lessons.** Everything from here down is the painted
M5 spike on Gemini, before the switch to pixel art. The prompts are no longer
the ones to use, but the misses (a background that took on the tileset's job,
a camera angle nobody stated) transfer to any generator.


`SPEC.md`'s Act 1 is still "the moat and the outer wall" as of this writing.
`LEVELS.md` has an open question about whether a forest sits before or
replaces it, unresolved and explicitly not blocking anything (`HANDOFF.md`).
Painting to the settled description now is the safe call: if that question
resolves toward the forest later, this is a repaint, not wasted pipeline
learning, and `SPEC.md` is the doc that wins until it says otherwise.

Five prompts below: a background, a tileset, the hero (`SPEC.md`: "M5 paints
him"), one enemy (the bat, an Act 1-appropriate ramparts creature and the
simplest of the six to grey-box), and a throwaway test of `GEMINI_NOTES.md`'s
open question on whether a pose sheet holds one subject consistent across
frames. That question uses a placeholder subject on purpose, so a bad result
costs nothing real.

Shared preamble, prefixed to every prompt below:

> Painted fantasy game art lit by fire and by electricity, in the style of
> hand-painted backgrounds from a hand-animated feature: visible brushwork,
> soft edges, real depth. Character and creature shapes read as a strong
> silhouette first, in the way of Mike Mignola's comic art, but rendered with
> full painterly surface and value, not flat black shapes. Every dark area of
> the painting is a coloured dark: cold violet-blue in stone and shadow, warm
> umber in wood and leather. Never use a neutral black or a neutral grey
> anywhere in the image, including in shadow. Forms are separated by value and
> by edge quality, hard edges where a shape matters, soft edges where it
> recedes, never a uniform ink outline.

**1. Background**, `assets/art_raw/act1_wall_moat_bg.png`:

**Attempt 1, rejected.** The prompt described the wall as filling "the right
two-thirds of the frame," which is the hedged-fraction phrasing
`hook-line-and-sentence`'s `GEMINI_NOTES.md` already found unreliable for a
full scene: **"expect the prior to win on scenes."** It also never stated a
camera angle. What came back was a well-painted but dramatic three-quarter
view of a castle corner, two turrets receding into depth, a second gatehouse
visible behind them. Right palette, right mood, wrong shot for a side
scroller: nothing here reads as a flat plane a camera can pan along. A miss
in drawn content, per that same doc's rule 5, is a reroll, not a salvage.

The fix that repo already paid for: state the camera framing positively and
explicitly, "a flat side view like a stage backdrop," then name what it is
not, and anchor the wall and the waterline to the canvas edges rather than to
a fraction of the frame. `background-stream-far.png` in that repo is the
worked example this borrows from almost verbatim.

**Attempt 2, rejected.** The camera framing landed: a flat plane, no more
three-quarter corner. Measured clean against `ART_DIRECTION.md`'s
neutral-dark rule too (`palette-check.py`, 0.01% of opaque pixels). But
Matt's question cut deeper than the picture: "how is the player going to
move across the scene?" The prompt had painted a specific causeway crossing
the moat and a specific torch bracket, a single fixed view of one spot, with
nothing either side of it for a scrolling camera to pan into. That is the
mistake the new subsection above names: the background had taken on a job
that belongs to the tileset. A crenellated top edge with sky showing above
it, contradicting "rising out of frame," was a second, smaller miss in the
same delivery.

**Attempt 3, current.** Drops the causeway and the torch (both become
tileset or level-design decisions, not atmosphere), and asks for the same
wall bay to repeat three times across the canvas so the strip already reads
as a continuous run rather than one place, which is also what removes the
single-vignette framing that invited a corner view in attempt 1:

> [preamble] A wide painted background for a side-scrolling platformer: a
> long horizontal strip of a castle's outer wall, in flat side view like a
> stage backdrop, camera perpendicular to the wall, with no vanishing point.
> It is NOT a three-quarter view and NOT seen from above. The same bay of
> masonry repeats three times across the width of the canvas: a stretch of
> plain wall-face, then a narrow arrow-slit window lit faintly from within by
> warm firelight, then plain wall-face again, evenly spaced, so the whole
> strip reads as a continuous run of wall rather than one unique view of one
> spot. The wall spans the full width of the canvas and rises out of frame at
> the top: no crenellations, no visible roofline, no sky anywhere in the
> frame. A band along the very bottom of the canvas is the moat's water, its
> edge a straight horizontal line running the full width of the canvas, not
> a diagonal band and not a curve. No characters, no creatures, no causeway,
> no bridge, no torch bracket, no foreground platform geometry, no second
> building or gatehouse: this is pure atmosphere meant to repeat, not a
> picture of one specific place. Cold stone areas are blue-violet grey, damp
> and slightly green near the water, drier and more purple higher up the
> wall. Firelight in the windows is amber going to a honey-cream at its
> hottest point, never to white. The image is 2560 by 1440 pixels, aspect
> ratio 16:9.

**Landed.** Three even bays, flat plane, no vanishing point, no crenellations,
no sky, no causeway, no torch. `palette-check.py`: 0.01% of opaque pixels
neutral-dark, clean. Delivered 1376x768 (ratio 1.792 against the requested
1.778), the usual pixel-dimensions-ignored-ratio-held pattern. Saved as
`assets/art_raw/act1_wall_moat_bg.jpg` (the raw delivery) and
`assets/art/act1/wall_moat_bg.png` (converted, no keying needed since it's a
full opaque painting, nothing else to do to it).

**Generation count, this asset: 3.** That is three of the five `ART.md`'s
own budget rule allows for the *whole room* before it says stop and revise
the plan rather than push on. Tileset, hero, bat and the pose-sheet test are
still unsent; even a clean first-attempt landing on all four puts M5 at 7.
Flagging this now rather than after the fact: whether to keep going and
treat the trigger as informative-not-a-hard-stop, or pause here and think
about it, is Matt's call.

**Running total after the tileset: 4 generations, 2 of 5 assets landed.**
The tileset landed first attempt, so it added exactly 1. Two assets in, at
an average of 2 generations each; hero, bat and the pose-sheet test remain.

**Running total after the hero: 6 generations, 3 of 5 assets landed.** The
hero took 2 (one rejected on pose, one landed). That's past the budget
rule's own ceiling of 5 for the whole room, with the bat and the
pose-sheet test still to come. Still not treated as a hard stop, each of the
three misses so far bought a real, reusable lesson rather than being wasted,
but it's worth naming plainly rather than letting the count go unremarked.

**2. Tileset**, `assets/art_raw/act1_wall_tileset.png`:

> [preamble] A tileset sheet for a side-scrolling platformer: a flat grid of
> individual stone wall and floor modules, painted on a flat solid magenta
> (#FF00FF) backdrop, with generous even spacing between each module so they
> can be cut apart individually. Include: one wide stone floor and ledge
> module seen from the side, one narrower stone floor module about half the
> width of the first, one wall-corner module, one plain wall-face module, and
> one short iron-runged ladder set into the stone, all matching the same
> castle-exterior stonework, all painted at the same scale. Every module
> except the ladder is roughly twice as wide as it is tall; the ladder is
> roughly three times as tall as it is wide. No characters, no creatures, no
> directional lighting effects beyond the stone's own surface colour and
> texture: flat, even light on every module so they tile predictably in
> engine. Cold stone areas are blue-violet grey, drier and more purple than
> the moat's edge. The image is 2560 by 1440 pixels, aspect ratio 16:9.

**Landed first attempt, with a bonus.** Eight modules came back instead of
the five asked for (an extra plain wall-face, an extra window wall, and the
narrower floor module reads closer to the same width as the first than
"about half"), all consistent stonework, all clean on a flat magenta
backdrop with generous gutters. `palette-check.py` on the keyed sheet: 0.01%
neutral-dark. Saved as `assets/art_raw/act1_wall_tileset.jpg` (raw) and, once
cut, `assets/art/act1/tiles/wall_tile_1.png` through `_8.png`, in reading
order (top row left to right, then the next row).

**Found a real bug in `key.py` cutting this one.** The despill from M5's
first build only pulled colour back within a 3px ring, on the theory that
the antialiased seam was a thin fringe. It is not: measured on this real
delivery, backdrop colour was still visibly present 6 to 7px into the kept
pixels (pixel-by-pixel: `(169,5,146)` a single pixel in, still
unmistakably magenta at 6px, clean stone by 8 to 9px). A partial pull that
close to the seam left an obvious magenta halo around every module, visible
at a glance, exactly the "noisy backdrop bled into the subject" failure
`GEMINI_NOTES.md` calls the one kind of miss that is never fixable
downstream. Rewrote `key.py`'s decontamination: every kept pixel within
`--ring` (default 10px) of the cut is now replaced outright with its
nearest clean neighbour's colour, via `scipy.ndimage.distance_transform_edt`,
rather than partially corrected. Re-verified against both the original
synthetic test and this real delivery: zero backdrop colour remains in
either.

**`tools/cut-sheet.py` is built**, to the shape `ART.md` guessed at before a
real sheet existed: connected components of the keyed alpha channel, sorted
into reading order by vertical-span overlap (robust to whatever the actual
grid spacing turns out to be, rather than a fixed pixel bucket), each
cropped tight and numbered. Worked first run against this delivery: 8
components in, 8 modules out, in the right order.

**3. Hero**, `assets/art_raw/hero_lothar_idle.png`:

> [preamble] A single full-body character painting of a lone warrior for a
> side-scrolling platformer, standing in a relaxed idle pose facing right,
> viewed straight on from the side. He is a lean, broad-shouldered adult man
> in his early thirties, ordinary human proportions rather than an
> exaggerated musclebound giant or a lanky youth: a practical fighter's
> build, not a bodybuilder's. He wears simple, weathered leather and fur
> clothing in warm umber and dark hide tones, a plain rather than a heroic
> silhouette, dark shoulder-length hair, no helmet, no cape, no ornamentation
> beyond a leather belt. He holds a straight double-edged sword with a plain
> crossguard, gripped naturally in his right hand, blade pointing down and
> slightly back, exactly as someone actually holds a sword at rest, not
> presented to camera. A warm rim light catches his left side, as if lit by
> a torch just out of frame. Painted on a flat solid magenta (#FF00FF)
> backdrop, full body visible with a small even margin of backdrop on all
> four sides, nothing cropped by the frame. The image is 1536 by 2048
> pixels, aspect ratio 3:4.

**Attempt 1, rejected.** Palette measured clean, but the pose did not read
as a true side view: both shoulders and most of the chest were visible, and
the near leg overlapped the far leg the way it does in a three-quarter
stance. "Viewed straight on from the side" alone was not enough to beat the
generator's default toward a three-quarter fantasy-portrait stance, the same
compositional-prior problem the background hit, showing up on a character
instead of a scene. This one mattered more than the earlier misses:
`ANIMATION.md` is explicit that "a cutout rig cannot sell a full-body
rotation, flat parts seen edge-on are flat parts," so a foreshortened limb
in the source painting would have looked wrong the moment `Bone2D` rotated
it, not just in a still.

**Attempt 2, landed.** Same fix as the background: state the side view
positively and concretely, then rule out the three-quarter default by name.

> [preamble] A single full-body character painting of a lone warrior for a
> side-scrolling platformer, standing in a relaxed idle pose. This is a true
> side view, an orthogonal profile as if traced from directly beside him:
> his whole body faces right, shoulders stacked directly in line with his
> hips, one flank of his body fully hidden behind the other. It is NOT a
> three-quarter view: his chest, both shoulders and both legs must NOT be
> visible at once, only the near side of his body reads at all. He is a
> lean, broad-shouldered adult man in his early thirties, ordinary human
> proportions rather than an exaggerated musclebound giant or a lanky youth:
> a practical fighter's build, not a bodybuilder's. He wears simple,
> weathered leather and fur clothing in warm umber and dark hide tones, a
> plain rather than a heroic silhouette, dark shoulder-length hair, no
> helmet, no cape, no ornamentation beyond a leather belt. He holds a
> straight double-edged sword with a plain crossguard, gripped naturally in
> his near hand, blade pointing down and slightly back, exactly as someone
> actually holds a sword at rest, not presented to camera. A warm rim light
> catches his far side. Painted on a flat solid magenta (#FF00FF) backdrop,
> full body visible with a small even margin of backdrop on all four sides,
> nothing cropped by the frame. The image is 1536 by 2048 pixels, aspect
> ratio 3:4.

Landed a true profile: shoulders stacked, one leg mostly hidden behind the
other, the flat side view a cutout rig needs. `palette-check.py`: 0.00%
neutral-dark. Two small extras beyond the brief, a chest strap and a second
hilt or pouch at the hip, when the prompt said "no ornamentation beyond a
leather belt": not worth a third generation over. Saved as `assets/art_raw/
Lothar1.jpeg` (Matt's own filename, uploaded directly to the branch after
this session's file-attachment path failed twice, an environment issue
rather than anything about how it was sent) and `assets/art/hero/
lothar_idle.png` (keyed, decontamination verified clean at the cut edge
by hand).

**`tools/cut-rig.py` is built**, against this real painting, and it is a
different shape of tool from `cut-sheet.py`. A sheet has a backdrop between
every module for connected-components to find; a character painting is one
continuous shape with no seam between an arm and a torso, so a part is a
named rectangle read off the painting by eye, not detected. Five parts cut
clean: `head`, `torso`, `arm_near`, `leg_near`, `leg_far` (`assets/art/hero/
rig/`), matching `ANIMATION.md`'s own rig granularity for a run cycle,
"hips, two legs, two arms, head", minus the far arm, which this true
profile hides entirely.

**The sword is not one of the rig parts, on purpose.** `CLAUDE.md`: "the
sword is one scene and one script." The blade in this painting was there so
the hand would come back actually gripping something (`GEMINI_NOTES.md`:
"a hand gripping nothing will not come back gripping... give it the object,
then cut"), not to be a reusable sword asset. That mattered for the box
shapes too: the blade crosses diagonally in front of the legs, so any
rectangle wide enough to hold the grip *and* the tip also swept in both
boots, since a crop is axis-aligned and can't tell a blade pixel from a
boot pixel sitting in the same rectangle. Stopping `arm_near`'s box at the
fist sidesteps the worst of it. A small blade sliver still landed inside
`leg_far`'s box regardless, the same geometry problem at a smaller scale;
cleared by colour rather than chased with tighter geometry, since the blade
reads as a distinctly low-saturation, mid-to-high-value grey against warm
brown leather, easy to threshold and mask without touching the boot under
it. Checked by eye against a red-marked preview before applying, so the
mask wasn't trusted blind.

**`draw the thing you measured` caught a real bug here, not just the
sliver.** The first attempt at avoiding the blade problem pushed `leg_near`
and `leg_far`'s top edge down to clear it, and it worked, no more blade in
either crop. What it also did was leave a gap: the torso's box ends where
its own content does, and the legs' new top edge started below that, so a
band of hip and upper thigh that belongs to neither box was never cut at
all. Invisible in each part looked at alone; obvious the moment all five
parts were composited back onto one canvas at their recorded offsets, which
is exactly why that reassembly check is worth doing before trusting a set
of rig parts, not after. Fixed by moving the legs' top edge back up to meet
the torso's bottom edge exactly, and clearing the blade sliver by colour
instead of by geometry.

**Boxes are allowed to overlap where two parts meet**, deliberately: the
torso's box and the arm's box both contain some of the same shoulder
pixels, and that's fine, because a keyed crop's untouched area is
transparent, not blank. Draw the parts back to front in Godot in the order
they're layered in the source painting, torso, then legs, then the arm on
top, and the overlap is invisible: only the topmost part's pixels show
where two boxes cover the same spot.

**That manual step happened too: `scenes/hero_rig.tscn` is a real
`Skeleton2D`.** `Hip` is the root `Bone2D`, with `Torso` as its direct
`Sprite2D` child; `HipFar`, `HipNear`, `Shoulder` and `Neck` are child bones
each carrying one more part. Every bone's position and every sprite's
position (`centered = false` throughout) is set so the rest pose reproduces
the source painting exactly: a bone at absolute canvas point `P`, a sprite
whose crop offset is `Q`, gets local position `Q - P`. `scenes/
hero_rig_test.tscn` wraps it with a `Camera2D` for `tools/dev.sh shot` to
frame, since `capture.gd`'s `--zoom`/`--centre` only drive a camera it finds
under something in the "player" group, and this scene has no player.

**Caught a real bug before it reached Godot, not after.** The first
attempt at the leg boxes (see above) left a gap between the torso's bottom
edge and the legs' new top edge, invisible looking at any one part alone.
Compositing all five parts back onto one canvas at their recorded offsets
in plain PIL, before touching Godot at all, showed it immediately: a band
of missing hip and thigh. `CLAUDE.md`'s "draw the thing you measured" is
the reason this check happened before the scene was built rather than
after, and it is worth doing every time a set of rig parts is cut, not just
this once.

**A real Godot 4.7.2 engine quirk showed up too, confirmed harmless.**
Every leaf `Bone2D` (one with no `Bone2D` child of its own, `HipFar`,
`HipNear`, `Shoulder` and `Neck` here) logs "cannot calculate bone length or
angle reliably" followed by an `ERROR: Condition "det == 0" is true" from
`affine_invert`, on load, every time, regardless of `position`, `rest`,
`length`, `bone_angle` or `autocalculate_length_and_angle`. Reproduced in a
three-line scene with nothing but a `Skeleton2D`, one root bone and one leaf
bone, so it is not this rig's structure at fault: `Bone2D.rest` defaults to
`Transform2D(0, 0, 0, 0, 0, 0)`, a degenerate transform, and Godot's own
internal bone-length auto-calculation tries to invert it for any bone with
no child bone to infer a length from. The picture renders correctly despite
it (verified: `tools/dev.sh shot` output, byte-identical figure to the PIL
reassembly), and `capture.gd` still exits 0 and writes the PNG, so it is
log noise, not a functional break. Worth knowing before someone spends an
hour on it thinking it's a rig bug.

**This was run against a real Godot, not just written and hoped for.** No
Godot was installed in this session's environment; the official 4.7.2 Linux
binary (matching `README.md`'s pinned version) was downloaded to `/tmp` to
actually run `tools/dev.sh import`, `test`, and `shot`. That download does
not persist between sessions in this kind of environment, so a future
session here starts the same way: no `$GODOT`, fetch the binary before
trusting anything Godot-shaped it writes.

**4. The bat**, `assets/art_raw/enemy_bat.png`:

**Revised before sending, not after a miss.** The original wording said
"viewed straight on from the side" once and left it at that, the same
hedge that cost the background one reroll and the hero another: a subject
description without an explicit positive-plus-negation framing barely
moves the generator's default. "Mid-flight, both wings spread wide" is
exactly the kind of dynamic pose that invites a dramatic angle the way the
hero's idle stance did. Applying the fix that already worked twice, before
paying for a third rejection to relearn it:

> [preamble] A single creature painting of a large cave bat for a
> side-scrolling platformer, shown mid-flight with both wings spread wide.
> This is a true side view, an orthogonal profile: the bat's body faces
> right and both wings spread within the picture plane, seen edge-on and
> flat, not foreshortened by any tilt toward or away from the camera. It is
> NOT a three-quarter view and NOT seen from above or below. Larger than a
> real bat, roughly the size of a human torso, with a lean leathery body,
> clawed wingtips, and small sharp teeth bared. Because this creature kills
> on contact in the game, it is warm-toned and saturated rather than cold
> and matte: dark, matte, warm reddish-brown fur and a warm-brown wing
> membrane, not black, not grey. Painted on a flat solid magenta (#FF00FF)
> backdrop, full body and both wingtips visible with a small even margin of
> backdrop on all sides, nothing cropped by the frame. The image is 1536 by
> 1152 pixels, aspect ratio 4:3.

**Delivered, palette clean, and the pre-emptive fix didn't fully hold.**
`palette-check.py`: 0.00% neutral-dark. But the pose is still a dynamic
swoop, not the flat orthogonal profile asked for: the head shows both ears
and a near-frontal muzzle, the body's long axis is diagonal, and the two
wings are spread at different angles rather than symmetrically in-plane.
The explicit "NOT a three-quarter view" that landed the hero on its second
attempt didn't fully override the generator's default here; a creature
"mid-flight, wings spread" carries an even stronger prior toward a dynamic
action shot than a standing human idle pose did.

**Found and fixed a real bug in `key.py` cutting this one, more serious
than the tileset's.** The bat's wing membranes have thin gaps between the
finger-bones, and its bared teeth leave gaps in the mouth: backdrop colour
trapped in those enclosed pockets measured `(239, 36, 240)` against a
detected backdrop of `(243, 46, 248)`, indistinguishable from the real
thing, and `key.py`'s border-seeded flood fill never reached it, because
nothing connects an enclosed pocket to a border seed. The result was solid
magenta patches baked into every rig-part crop as fully opaque "subject"
pixels. Rewrote `key.py` to match the backdrop colour globally, anywhere in
the frame, rather than flooding from the border: this project's palette
(`ART_DIRECTION.md`) has nothing naturally near a saturated magenta, so a
global match has no real subject to false-positive on. Re-checked every
already-committed asset (the hero's rig parts, the tileset tiles, the
hero's full painting) against the new tool: all clean, the bug's actual
damage was confined to this one delivery. A last few sub-pixel specks
remain at extremities (claw tips, an ear notch, under 50px total across the
whole image) where the antialiasing never produces a pixel close enough to
either colour to classify cleanly; noted rather than chased, since no
reasonable tolerance fixes a gap smaller than a pixel's own blend.

**Test-rigged in scratch (never committed) to make the pose call with real
information instead of guessing from a still.** Cut into `body`/
`wing_left`/`wing_right`, reassembled to confirm the cut held, then dropped
into a real `Skeleton2D` next to the hero and screenshotted. Two things the
static painting couldn't have told us:

- **A raw side-by-side against the hero is not a valid size comparison.**
  `GEMINI_NOTES.md` already carries this ("scale comes from a body part,
  never from the figure"): each generation fills its own canvas
  independently, so the bat's painted pixels and the hero's painted pixels
  carry no shared world scale until something deliberately corrects for
  it. Noted so nobody re-learns it from this screenshot.
- **Rotating the wings away from their rest pose exposed a real rig defect,
  independent of the pose question.** A rectangular chunk of wing-shaped
  content stayed fixed in place while the wing sprite rotated away from it,
  because the `body` box's bounds happened to overlap the wing's rest
  position, the same "boxes can overlap, z-order hides it" move that held
  fine for the static hero but breaks the moment something actually
  animates away from what was covering it. This needs fixing in whatever
  delivery gets cut for real, a tighter `body` box or a wing split closer
  to the shoulder joint, regardless of which pose is used.

**Rerolled.** The wings' asymmetry (one raised higher than the other) was
the harder problem than the three-quarter framing: it leaves no clean
neutral point to animate a flap cycle from. Attempt 2 asks for the wings
level and symmetric and the head in a true profile (attempt 1 showed both
ears, a three-quarter tell on the head even though the body mostly read as
a side view), on top of the same fixes already in place:

> [preamble] A single creature painting of a large cave bat for a
> side-scrolling platformer, in a calm gliding reference pose rather than a
> dive or a swoop: body level and horizontal, not tilted on a diagonal
> axis. This is a true side view, an orthogonal profile: the bat's body
> faces right, and only the near side of the head is visible, one eye and
> one ear, not both, the same way a person's profile shows only one side of
> their face. Both wings are spread symmetrically, at the same angle on
> either side of the body, seen edge-on and flat within the picture plane,
> not foreshortened by any tilt toward or away from the camera and not
> staggered at different heights. It is NOT a three-quarter view and NOT
> seen from above or below. Larger than a real bat, roughly the size of a
> human torso, with a lean leathery body, clawed wingtips, and small sharp
> teeth bared. Because this creature kills on contact in the game, it is
> warm-toned and saturated rather than cold and matte: dark, matte, warm
> reddish-brown fur and a warm-brown wing membrane, not black, not grey.
> Painted on a flat solid magenta (#FF00FF) backdrop, full body and both
> wingtips visible with a small even margin of backdrop on all sides,
> nothing cropped by the frame. The image is 1536 by 1152 pixels, aspect
> ratio 4:3.

**Attempt 2, partial landing.** `palette-check.py`: 0.00% neutral-dark. The
wing fix held: level, symmetric, the same angle on both sides, exactly the
neutral flap-cycle point attempt 1 lacked. The head fix did not: zoomed in,
two ears are visible, one facing the camera and a second peeking out from
behind it, the plainest possible three-quarter tell, confirming Matt's read
against a still that looked closer to a profile at a glance than it
measured up close. Body and wings are worth keeping; only the head needs
another pass.

**Recommended next step: attach-and-edit, not a third fresh generation.**
`GEMINI_NOTES.md`'s own finding on editing a delivered painting ("nine hat
deliveries came back as faithful edits, nine times out of nine") is a
better fit here than fighting the compositional prior over again from
scratch: name the one region that changes, keep everything already right.

> Using this exact image, change only the head: turn it further so it
> reads as a true side profile, only the near ear and the near eye
> visible, the far ear fully hidden behind the head. Keep everything else
> identical: the body, both wings, the pose, the colours, the backdrop.

**Attempt 3, the edit, measurably did almost nothing.** Whole-image mean
absolute pixel difference against attempt 2 was about 4.0, the same order
of magnitude as plain JPEG noise on an unchanged image; the head region
alone measured about 10.7, some real change, but a zoomed crop still shows
the same second ear peeking from behind the first. The instruction asked
for two things that fight each other: turn the head further, and keep
everything else, including the head's own shading against the wings,
identical. A real turn changes its own shadow. Faced with that
contradiction the generator played it safe and barely moved.

**Accepted anyway.** Matt's call, on the recommendation that a tenth
generation wasn't worth it: the wings, the part that actually has to hold
up through a flap animation, are fixed and level. The head's three-quarter
tell is cosmetic on a part that doesn't rotate, not a functional problem
the way the wing asymmetry was. `assets/art_raw/enemy_bat.jpg` now holds
this attempt, overwriting attempt 2's file; unlike the hero and the
background, all three bat attempts landed in that same path in turn rather
than each getting its own filename, since only the final one was ever
going to be cut.

**Cutting this delivery found a second real bug, distinct from the
flap-rotation one attempt 1's scratch rig caught.** A first pass at the
three boxes (`body` narrow around the torso, one box per wing) reassembled
with a visible gap: the legs and tail were outside every box entirely,
clipped off, because the body box had been guessed too far right and too
narrow. Caught the same way the hero's torso/leg gap was, by compositing
the cut parts back onto one canvas at their recorded offsets before
touching Godot, not after.

**The real problem underneath that was anatomical, not a bad guess.**
Alpha-channel measurement (not eyeballing) showed the wing membrane and
the body fur share one unbroken silhouette at the shoulder: a bat's
patagium attaches along the body with no gap, so any axis-aligned
rectangle wide enough to hold the whole body also swallows a wedge of
wing membrane at each shoulder, and the reverse box, tight to a wing,
would leave the shoulder's own fur out of every box. Colour-based masking
(the fix that worked for the hero's blade sliver) doesn't apply here:
sampled membrane and fur pixels near the seam land in the same dark
reddish-brown range, `(114,56,42)` for mid-wing against `(89,51,40)` for
shoulder fur, nowhere near the sword's clean grey-against-leather split.

**Fixed with a hand-picked seam line instead of a box edge.** Zoomed
crops of both shoulders show a real drawn boundary, a fold in the fur
where the membrane's leading edge meets it, even though the alpha
silhouette has no gap there. Traced each shoulder's seam as a short
polyline in image coordinates and used it as a keep/exclude boundary
within the overlapping region of the box, generous rectangles for all
three parts, then per-pixel: `wing_left` keeps only what's left of its
seam, `wing_right` only what's right of its seam, `body` only what's
between both, and outside the seams' own y-range (below both shoulders,
where no wing exists) `body` keeps everything in its box unmasked. Verify
by reassembly first, no gap and no doubled membrane; then the actual test
that matters, a scratch `Skeleton2D` with both wings rotated hard up and
away from rest, the same move that exposed attempt 1's frozen wing
fragment. Zoomed on both shoulder joints in that screenshot: clean fur,
no static wing-coloured patch left behind. The bug attempt 1's scratch rig
found does not recur.

**This will happen again for the next winged or membrane-bodied enemy.**
`tools/cut-rig.py` only knows named rectangles; a seam line was written as
a one-off script rather than a new flag, since this is the first
character where two parts touch with no silhouette gap at all. Worth a
polygon or seam-line option on the tool itself if a second such enemy
shows up; noted in `BACKLOG.md` rather than built now, since one use
doesn't justify the general case yet.

**`scenes/bat_rig.tscn` is a real `Skeleton2D`**, the same pattern as the
hero's: `Body` is the root `Bone2D`, `ShoulderLeft` and `ShoulderRight` are
its children, each carrying one wing sprite. `scenes/bat_rig_test.tscn`
wraps it with a `Camera2D` for `tools/dev.sh shot`, same reason as the
hero's test scene: this rig has no player node for `capture.gd`'s
`--zoom`/`--centre` to find. Verified against a real build at rest and
mid-flap; `tools/dev.sh test` still passes clean, 221 tests, 1572 checks.

**5. Pose-sheet test, throwaway**,
`assets/art_raw/_experiments/pose_sheet_test_mannequin.png`:

> A test sheet: the same plain jointed wooden practice mannequin, unpainted
> pale wood, shown in six different rotated poses, arranged in a 3-column by
> 2-row grid on a flat solid magenta (#FF00FF) backdrop, generous even
> spacing between frames so each can be cut apart individually. Each frame is
> the same figure at the same scale and the same camera distance, side view
> throughout, rotating through a full tumble from standing to inverted to
> standing. This is a technical test of whether a multi-pose sheet holds one
> consistent subject across frames, not a final asset: no scenery, no
> colour beyond the wood itself. The image is 2048 by 1365 pixels, aspect
> ratio 3:2.

**Landed first attempt, and the question it was for is answered: yes.**
`cut-sheet.py` found six clean connected components. Measured per-frame
mean RGB and luminance across all six landed within a few points of each
other (full numbers and the write-up of what this means for M6 are in
`GEMINI_NOTES.md`, since that's where the generator-behaviour finding
belongs, not here). One soft miss: the "rotating through a full tumble" ask
didn't land as one clean monotonic sequence in reading order, two poses
read as similarly deep inversions rather than a single peak either side of
a symmetric recovery. Doesn't matter for M6's actual use: a human picks the
poses that work as key frames and orders them, the sheet's own left-to-right
order was never load-bearing. Filed under `assets/art_raw/_experiments/`,
never promoted to `assets/art/`, per this section's own convention for a
test that was never meant to ship.

**Status: all five of M5's prompts are landed. 10 generations spent for
one room** (background 3, hero 2, bat 3, tileset 1, pose-sheet test 1).
Past `ART.md`'s own soft ceiling of 5, not a hard stop since every miss
past the first bought a real lesson (a scene's compositional prior, a
character's compositional prior, the flap-rotation rig bug, the
shoulder-seam rig bug), worth naming plainly rather than smoothing over.
Reading `hook-line-and-sentence` (read access, not attached, cloned
locally to check against) confirmed the camera-framing fix and turned up no
other reusable technique this project's `GEMINI_NOTES.md` didn't already
carry, and that same fix, restated for a character rather than a scene, is
what landed the hero and then the bat. `tools/key.py` and
`tools/palette-check.py` are built and proven against four real deliveries
now, not just synthetic ones; `key.py`'s decontamination got a real fix
along the way (see the tileset write-up above), and its backdrop matching
went from a border flood to a global match (see the bat write-up above).
`tools/cut-sheet.py` and `tools/cut-rig.py` are both built and proven,
against the real tileset sheet and both rigged characters. **Both the hero
and the bat are rigged in Godot**: `scenes/hero_rig.tscn` and `scenes/
bat_rig.tscn`, real `Skeleton2D`s, each verified by an actual screenshot
against a real build, the bat's checked at rest and mid-flap specifically
to rule out a rig bug a still image can't show. `tools/pose-sheet.py` is
still not built: M6 is what will tell us its real shape. Porting from
`hook-line-and-sentence` needs that repo attached to this session with
push access, which this session's own permissions denied; Matt can grant
it directly if porting is worth doing, though the tools built fresh so far
have each worked first try against a real delivery.

**M5's done-when is met.** Matt's call on the open structural question above:
the assembly is M5's own remaining work, not M6's first slice.
`scenes/rooms/room_m5_wall.tscn` (`scripts/room_m5_wall.gd`) places all five
assets in one `Bench`: the background fills the room's own height rather
than the tileset's shared 4x scale (a background that stopped short would
put sky where the prompt asked for none), the wide floor-and-ledge tileset
module (`wall_tile_1.png`) is repeated as the walkable floor and a raised
ledge, the ladder module connects them, and the hero and the bat are the
real rigs, not the grey capsule and diamond.

**The rig swap went in globally, not scoped to this one room.** `Player` and
`Bat` now instantiate their rig (`Player.RIG_SCENE`, `Bat.RIG_SCENE`) in
`_ready` and hide their old grey draw whenever one is present, so every
Phase 1 bench picked up the real art for free rather than carrying two
visual paths into M6. Matt's call, weighed against scoping it to the new
room alone: one path to maintain, and nothing in `BUILD_PLAN.md`'s milestone
gates says a grey-box bench has to stay grey once the art it would show
exists.

**The floor art had to register with the collision line, not just look
close.** `wall_tile_1.png`'s pale ledge lip, the row a hero's feet actually
read as standing on, was measured as the tile's own brightest image row
(`FLOOR_LIP_FRACTION` in `room_m5_wall.gd`) rather than eyeballed, the same
"draw the thing you measured" discipline the rig's own offsets already used.
`tools/` has no general pixel-measuring tool yet; this was a one-off scan of
the delivered PNG, noted in `BACKLOG.md` rather than built into a script for
one use.

**The hero and the bat's rig scale is a fact read off `scenes/hero_rig.tscn`
and `scenes/bat_rig.tscn`'s own recorded offsets, not a second guess at
their size.** `Player.RIG_SOURCE_TOP`/`RIG_SOURCE_BOTTOM`/
`RIG_SOURCE_CENTRE_X` composite the hero rig's bone and sprite positions
into the figure's own bounding box, so the rig now renders at
`world.hero_height` exactly, mirrored around its own centreline rather than
the origin. The bat's scale (`Bat.RIG_TARGET_BODY_LENGTH`) is the one number
in this pass that is a judgement call rather than a measurement: 18 design
px, picked to land roughly at Lothar's own torso height per the prompt's
"roughly the size of a human torso," checked by rendering it and looking
rather than derived from anything else the game already draws.

**Verified against a real build**, not just written and trusted:
`tools/dev.sh test` still passes clean, 221 tests, 1572 checks, and
`tools/dev.sh shot` on `room_m5_wall.tscn` shows the hero standing on the
tile lip at the right scale next to a lit brazier, the bat flying a legible
size against the wall, and the ladder connecting the floor to the ledge with
no gap. The same tool against `room_m4_enemies.tscn` confirms the global rig
swap costs nothing there: the hero and the bat now show real art, the
scorpion, ant and eyeball are unchanged.

## The generator's fight art (2026-10-04, 45 credits)

An `edit` of `generator_px.png` with the arc taken out (pick 0 of 2, both
clean, 67x69 rather than 72: the known `edit` drift, anchored by its base), a
4-frame `animate` of that (`generator_hum_sheet.png`, no boiling, 0 neutral
darks), and an `edit` to a burnt-out still with a cold grate, dull coils and
smoke (`generator_dead_px.png`, pick 0, 2.3% neutral darks in the soot fixed
with `tools/recolour-darks.py`). The arc between the horns is now an
`ArcBolt` in code while it is live, as `CLAUDE.md` asks. "Overloading" was
not generated: the arc warning already says it, in code.

## The dragon in flight (2026-10-04, 30 credits)

An `edit` of `dragon_px.png` to a level flying profile facing right (pick 1
of 2: legs tucked, broad back, 112x67; pick 0 was taller and less level),
written with the positive-plus-negation framing the bat needed, which held
this time. Then a 4-frame `animate` wing beat (`dragon_flight_sheet.png`):
the body stays level, slight boiling on the downstroke. 0 neutral darks in
both. The hero sits on it as the hero sprite, so no rider art was needed.

## Volta and the hall (2026-10-04, 105 credits)

**Volta**: a `generate` at 64 (12 candidates, all palette-clean, nearly all
three-quarter), pick 0 for its silhouette, then `direction-set`, whose index
4 is a true profile facing left, the same index as the hero's. Three
`animate`s from it: idle, cast (the staff thrust forward, orb flaring) and
fall (toppling backward), 64x64, 0 neutral darks in all three although the
still itself failed the check. `scenes/volta_sprite.tscn`.

**Hall tiles**: two `generate`s at 16. Floor 4 (violet marble lip over a
bronze line) and wall 0, the calmest; wall 4 was too saturated to sit behind
play. Wall 0 came back 15x15 with a transparent last row and column, filled
with its own mortar colour before `tile-variants.py`. `act4_tiles.tres`.

