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
