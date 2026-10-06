## Every number that decides how the lava and the arcs look and move.
##
## CLAUDE.md puts tuning in `config/`, and these are the numbers M14's pass will
## reach for first: an effect that is too busy hides the hazard it belongs to.
## Nothing here is a colour. Colours come from `Palette`, which is
## `ART_DIRECTION.md`'s hex side, so an effect cannot drift off the palette.
## Distances are art pixels, one design pixel at 640x360.
class_name AtmosphereConfig
extends Resource

@export_group("Lava surface")
## How fast the lava drifts sideways, art px/s.
@export var lava_scroll_speed: float = 5.0
## Noise frequency, per art px. Smaller is broader flows.
@export var lava_noise_scale: float = 0.07
## How hard the noise bends itself, which is what makes a flow look like it is
## folding instead of sliding.
@export var lava_warp: float = 1.8
## Heat above which a pixel is the flow colour, the fissure colour and the core
## colour. Ascending, or a band disappears.
@export_range(0.0, 1.0) var lava_flow_cut: float = 0.52
@export_range(0.0, 1.0) var lava_fissure_cut: float = 0.70
@export_range(0.0, 1.0) var lava_core_cut: float = 0.92
## How far below the surface the lava stays hot, art px. Deeper is crust.
@export var lava_hot_depth: float = 16.0
## Bubbles: the size of the cell one may grow in, art px, and how often a cell's
## bubble cycles, per second.
@export var lava_bubble_cell: float = 16.0
@export var lava_bubble_rate: float = 0.35
## The bright line along the surface, art px thick, and how far it wobbles.
@export var lava_crest_depth: float = 2.0

@export_group("Embers")
## Embers per 100 px of lava width, and how long one lives, seconds.
@export var ember_per_100px: float = 5.0
@export var ember_lifetime: float = 1.6
## How fast an ember leaves the surface, art px/s, and the pull back down.
@export var ember_speed_min: float = 14.0
@export var ember_speed_max: float = 34.0
@export var ember_gravity: float = 10.0

@export_group("Heat haze")
## How tall the shimmering band above the lava is, art px, and the widest shift
## in it, art px. Whole pixels only, or pixel art smears.
@export var haze_height: float = 30.0
@export var haze_shift: float = 1.6
@export var haze_speed: float = 2.4
@export var haze_frequency: float = 0.5

@export_group("Glow")
## The warm light the lava throws up the wall: how tall, and how strong at the
## surface (0 to 1, added over what is behind it).
@export var glow_height: float = 90.0
@export_range(0.0, 1.0) var glow_strength: float = 0.6

@export_group("Arc")
## New bolt shape this many times a second. Fast and hard-edged, or it reads as
## a wire and not as electricity.
@export var arc_flicker_hz: float = 14.0
## Segments after the midpoint splitting, and how far a vertex may be pushed off
## the straight line as a fraction of the bolt's length.
@export var arc_subdivisions: int = 4
@export var arc_jag: float = 0.16
## Chance a bolt throws a fork, and how long the fork is as a fraction of it.
@export_range(0.0, 1.0) var arc_fork_chance: float = 0.6
@export_range(0.0, 1.0) var arc_fork_length: float = 0.35
## Sparks per burst at each end of a bolt.
@export var arc_sparks: int = 6

@export_group("Flame")
## How fast the breath streams away from the mouth, in art pixels a second, and
## the noise's scale. Lower scale, bigger tongues.
@export var flame_stream_speed: float = 160.0
@export var flame_noise_scale: float = 0.09

@export_group("Light")
## How quickly a flickering light wobbles, radians a second.
@export var light_flicker_speed: float = 9.0
## A lit brazier: reach in px, brightness 0 to 1, and how much it flickers.
@export var light_brazier_radius: float = 60.0
@export_range(0.0, 1.0) var light_brazier_strength: float = 0.5
@export_range(0.0, 1.0) var light_brazier_flicker: float = 0.35
## A wall torch: smaller and dimmer than a brazier, so the checkpoint still
## reads as the brightest thing on a wall walk.
@export var light_torch_radius: float = 40.0
@export_range(0.0, 1.0) var light_torch_strength: float = 0.35
@export_range(0.0, 1.0) var light_torch_flicker: float = 0.45
## The dragon's breath, at its brightest.
@export var light_breath_radius: float = 80.0
@export_range(0.0, 1.0) var light_breath_strength: float = 0.6
## An arc: reach beyond half its own length, and brightness.
@export var light_arc_radius: float = 36.0
@export_range(0.0, 1.0) var light_arc_strength: float = 0.35


@export_group("The bailey's cage and switch")
## The caged dragon in Act 1's bailey is lit from inside, so it reads as a
## creature behind bars rather than eyes in a black block (playtest,
## 2026-10-06). Its own glow: reach, brightness and flicker.
@export var cage_light_radius: float = 72.0
@export_range(0.0, 1.0) var cage_light_strength: float = 0.5
@export_range(0.0, 1.0) var cage_light_flicker: float = 0.2
## Seconds on each frame of its slow breathing.
@export var cage_breath_seconds: float = 0.9
## Seconds between puffs of smoke from its nostrils.
@export var cage_smoke_period: float = 3.5
## How close the hero comes, px from the cage's middle, before it roars once.
@export var cage_roar_range: float = 200.0
## The first sword switch catches the light: a glint on its slot every so
## often while it is empty, and a small warm light on it.
@export var switch_glint_period: float = 2.2
@export var light_switch_radius: float = 34.0
@export_range(0.0, 1.0) var light_switch_strength: float = 0.35


@export_group("Light field")
## Bands between full dark and full light in a room's light (`LightField`).
## Fewer is chunkier pixel-art banding, more is smoother.
@export var light_field_steps: float = 8.0
## The hero's own light, so the thing you steer is never lost in the dark.
## Faint on purpose: it is a rim of firelight, not a lantern.
@export var light_hero_radius: float = 72.0
@export_range(0.0, 1.0) var light_hero_strength: float = 0.22
## A lava pit lights the room along its whole surface.
@export var light_lava_radius: float = 120.0
@export_range(0.0, 1.0) var light_lava_strength: float = 0.75
@export_range(0.0, 1.0) var light_lava_flicker: float = 0.12
## Live copper and a live barrier, along their length.
@export var light_live_radius: float = 40.0
@export_range(0.0, 1.0) var light_live_strength: float = 0.5
## A gem, lying or set: small and cold.
@export var light_gem_radius: float = 28.0
@export_range(0.0, 1.0) var light_gem_strength: float = 0.4
## A lit window in a painted background (`ActTiles.lights`): the room's dark
## draws back around it, gently, because the painting already has its glow.
@export var light_window_radius: float = 56.0
@export_range(0.0, 1.0) var light_window_strength: float = 0.3
@export_range(0.0, 1.0) var light_window_flicker: float = 0.1
## Volta's staff: his orb lights the throne room cold.
@export var light_volta_radius: float = 70.0
@export_range(0.0, 1.0) var light_volta_strength: float = 0.45
@export_range(0.0, 1.0) var light_volta_flicker: float = 0.25
## A geyser's jet while it is up: steam lit from the vent, cool, lifting the
## dark around it a little so the column reads as steam and not as a slab.
@export var light_steam_radius: float = 26.0
@export_range(0.0, 1.0) var light_steam_strength: float = 0.35
## A sword in flight or lying loose: a glint, so the most important shape on
## screen is never lost in a dark corner.
@export var light_sword_radius: float = 22.0
@export_range(0.0, 1.0) var light_sword_strength: float = 0.3

@export_group("Steam")
## A geyser's jet (`shaders/steam.gdshader`): how fast its billows rise, px/s.
@export var steam_rise_speed: float = 110.0
## How far up from the vent the jet keeps the lava's warmth, 0 to 1 of its
## height.
@export_range(0.0, 1.0) var steam_warm_reach: float = 0.3
## How dense the jet is at its thinnest, so the whole lifting box always reads.
@export_range(0.0, 1.0) var steam_edge_alpha: float = 0.26
## Bands between no steam and the thickest, as every soft thing is banded.
@export var steam_steps: float = 5.0

@export_group("Backdrop")
## How fast each of a backdrop's two layers moves against the room: 1 moves
## with it, 0 holds still on the screen.
@export_range(0.0, 1.0) var backdrop_far_depth: float = 0.2
@export_range(0.0, 1.0) var backdrop_near_depth: float = 0.45
## Act 2: how fast a lavafall runs down the far wall, and ash drifts up, art px/s.
@export var backdrop_fall_speed: float = 30.0
@export var backdrop_ash_speed: float = 9.0
## Act 3: how fast a flywheel turns, radians a second, and how often a lamp
## blinks, per second.
@export var backdrop_gear_spin: float = 0.15
@export var backdrop_lamp_rate: float = 0.7
## Act 4: how fast the rain runs, and the chance the storm flashes in any sixth
## of a second. Rare on purpose: a flash is a lift of dull colours, never a
## white, and a frequent one would be a strobe.
@export var backdrop_rain_speed: float = 140.0
@export_range(0.0, 0.1) var backdrop_flash_chance: float = 0.012

@export_group("Motes")
## Dust hanging in a room's air, catching whatever light there is: how many
## on screen at once, how long each lives, and how fast it drifts, art px/s.
@export var motes_amount: int = 40
@export var motes_lifetime: float = 9.0
@export var motes_drift: float = 4.0

@export_group("Transitions")
## How long a room takes to dissolve in from the dark as you enter it, and an
## act's card to come up over the room, seconds. The room is live from its
## first frame either way.
@export var room_reveal_seconds: float = 0.35
@export var card_cover_seconds: float = 0.45

@export_group("Rim light")
## How strongly a light reaching a sprite lights its rim: the light's own
## strength at the sprite times this, never more than `rim_max` of the way
## to the light's colour.
@export var rim_gain: float = 1.6
@export_range(0.0, 1.0) var rim_max: float = 0.6
