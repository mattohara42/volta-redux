## Every number that decides how the storm looks, moves and sounds (`Storm`):
## the rain driven across the foreground, and the lightning behind the room
## that flashes over everything with thunder after it.
##
## Nothing here is a colour. The rain is `Palette.STONE_LIT` and the flash is
## `Palette.ARC_CORE`, Volta's own: the storm is his (`ART_DIRECTION.md`).
## Distances are art pixels, one design pixel at 640x360.
class_name StormConfig
extends Resource

@export_group("Rain")
## Streaks on screen at once.
@export var rain_amount: int = 650
## How fast a streak falls, art px/s, and how much one may differ from the
## next, as a fraction.
@export var rain_speed: float = 520.0
@export_range(0.0, 1.0) var rain_speed_spread: float = 0.25
## How far the wind drives it off the vertical, degrees. Positive leans the
## streaks down to the right.
@export_range(-60.0, 60.0) var rain_slant: float = 24.0
## How long one streak is, art px, and how opaque at its densest, 0 to 1.
@export var rain_streak_length: float = 14.0
@export_range(0.0, 1.0) var rain_alpha: float = 0.9

@export_group("Lightning")
## Seconds before the first strike in a room, then between one strike and the
## next, at random between these.
@export var first_strike_seconds: float = 6.0
@export var strike_gap_min: float = 10.0
@export var strike_gap_max: float = 24.0
## A strike flickers: this many pulses at most (at random from 1), each
## lasting `pulse_seconds` with `pulse_gap_seconds` of half light between.
@export var pulses_max: int = 3
@export var pulse_seconds: float = 0.06
@export var pulse_gap_seconds: float = 0.1
## The afterglow fading out after the last pulse, seconds.
@export var afterglow_seconds: float = 0.4
## How far the gaps between pulses stay lit, 0 to 1 of a pulse.
@export_range(0.0, 1.0) var gap_level: float = 0.25

@export_group("Flash")
## How much the far layer brightens toward the flash at a pulse's peak,
## 0 to 1: the painting behind the room lights up and what stands in front of
## it goes to silhouette.
@export_range(0.0, 1.0) var sky_lift: float = 0.6
## The flash over everything, once a strike, on its first pulse: how opaque
## at its height, 0 to 1, how long it holds there and how long it takes to
## clear, seconds.
@export_range(0.0, 1.0) var whiteout: float = 0.92
@export var whiteout_hold_seconds: float = 0.05
@export var whiteout_fade_seconds: float = 0.18

@export_group("Windows")
## A room whose painting has windows (`ActTiles.windows`) sees the sky only
## through them: how bright a pane goes at a pulse's peak, 0 to 1.
@export_range(0.0, 1.0) var pane_lift: float = 0.6
## The cold light a flashing window throws into the room (`LightField`).
@export var window_light_radius: float = 150.0
@export_range(0.0, 1.0) var window_light_strength: float = 0.9
## The bolt seen through a window: rounds of splitting and how jagged
## (`ArcPath`), and the chance it forks.
@export var bolt_subdivisions: int = 4
@export var bolt_jag: float = 0.2
@export_range(0.0, 1.0) var bolt_fork_chance: float = 0.5

@export_group("Thunder")
## Seconds from the flash to the crack, at random between these. Short: the
## storm is overhead.
@export var thunder_delay_min: float = 0.15
@export var thunder_delay_max: float = 0.9
## The crack's level, decibels, on the effects bus.
@export_range(-60.0, 6.0) var thunder_volume_db: float = 0.0
## How far one crack may wander in pitch from the last, as a fraction, so the
## same recipe is not the same crack every time.
@export_range(0.0, 0.3) var thunder_pitch_jitter: float = 0.12
