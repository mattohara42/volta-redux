## M5's room: the moat and the outer wall, `ART.md`'s spike prompts as one
## assembled scene rather than five separate verification scenes.
##
## `BUILD_PLAN.md`'s M5 done-when is "that room is in the game, at final
## quality," and `ART.md` flagged what was still missing to reach it: nothing
## placed the background, the tileset as walkable platforms, the hero and the
## bat together. This is that placement. It is still a `Bench`, not one of
## `BUILD_PLAN.md` M10's authored rooms: the floor and the ledge are the same
## generated `Rect2` geometry every Phase 1 bench used, now carrying real art
## instead of a grey rectangle.
class_name RoomM5Wall
extends Bench

const ROOM_WIDTH: float = 640.0

const START_BRAZIER_X: float = 40.0

## `ART.md`'s import rule: art is painted at 4x and downscaled, never the
## reverse. Applies to the tileset and the ladder alike, so nothing about how
## big a painted brick is has to be guessed twice.
const TILE_SCALE: float = 0.25

## `assets/art/act1/tiles/wall_tile_1.png`: the wide floor-and-ledge module,
## `ART.md`'s tileset delivery.
const FLOOR_TILE: Texture2D = preload("res://assets/art/act1/tiles/wall_tile_1.png")
const FLOOR_TILE_NATIVE_SIZE: Vector2 = Vector2(453.0, 353.0)
const FLOOR_TILE_SIZE: Vector2 = FLOOR_TILE_NATIVE_SIZE * TILE_SCALE
## The row a hero actually stands on: measured as the tile's own brightest
## row (the pale ledge lip between the wall above and the mossy stone below),
## not eyeballed. `tools/` has no pixel-measuring tool yet; this one came from
## a one-off scan of the delivered PNG, `HANDOFF.md`'s note for whoever builds
## that tool for real.
const FLOOR_LIP_FRACTION: float = 214.0 / 353.0
const FLOOR_LIP_OFFSET: float = FLOOR_TILE_SIZE.y * FLOOR_LIP_FRACTION
## Enough to cover `ROOM_WIDTH` with a tile to spare; the spare hangs past the
## right wall, outside `_frame_camera`'s limit, so it costs nothing.
const FLOOR_TILE_COUNT: int = 6

## The ledge above the floor, one tier up, reached by the ladder.
const LEDGE_TILE_COUNT: int = 2
const LEDGE_X_START: float = 360.0

## `assets/art/act1/tiles/wall_tile_8.png`: the iron-runged ladder module.
const LADDER_TILE: Texture2D = preload("res://assets/art/act1/tiles/wall_tile_8.png")
const LADDER_TILE_NATIVE_WIDTH: float = 208.0
const LADDER_TILE_WIDTH: float = LADDER_TILE_NATIVE_WIDTH * TILE_SCALE
const LADDER_X: float = 340.0

## `assets/art/act1/wall_moat_bg.png`: the background, atmosphere only, not
## the player's path (`ART.md`). Scaled to fill the room's own height rather
## than the tileset's shared 4x, since a background that left a gap at the
## top would put sky where the prompt asked for none.
const BG_TEXTURE: Texture2D = preload("res://assets/art/act1/wall_moat_bg.png")
const BG_NATIVE_SIZE: Vector2 = Vector2(1376.0, 768.0)
const BG_SCALE: float = ROOM_HEIGHT / BG_NATIVE_SIZE.y
const BG_WIDTH: float = BG_NATIVE_SIZE.x * BG_SCALE

const BAT_SIZE := Vector2(20.0, 14.0)
const BAT_CENTRE := Vector2(240.0, FLOOR_TOP - 90.0)
const BAT_HALF_EXTENTS := Vector2(80.0, 50.0)

## Set once in `_ready`, from `world.tier_height` rather than a literal, so a
## retuned storey height moves the ledge and the ladder together with it.
var _ledge_top: float = 0.0


func _ready() -> void:
	_ledge_top = FLOOR_TOP - world.tier_height
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(LEDGE_X_START, _ledge_top, LEDGE_TILE_COUNT * FLOOR_TILE_SIZE.x, FLOOR_TOP - _ledge_top))
	_add_ladder(LADDER_X, _ledge_top, FLOOR_TOP)
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_bat(Rect2(BAT_CENTRE - BAT_SIZE * 0.5, BAT_SIZE), BAT_HALF_EXTENTS)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(BG_TEXTURE, Rect2(0.0, 0.0, BG_WIDTH, ROOM_HEIGHT), false)
	for i in FLOOR_TILE_COUNT:
		draw_texture_rect(
			FLOOR_TILE,
			Rect2(i * FLOOR_TILE_SIZE.x, FLOOR_TOP - FLOOR_LIP_OFFSET, FLOOR_TILE_SIZE.x, FLOOR_TILE_SIZE.y),
			false
		)
	for i in LEDGE_TILE_COUNT:
		draw_texture_rect(
			FLOOR_TILE,
			Rect2(
				LEDGE_X_START + i * FLOOR_TILE_SIZE.x, _ledge_top - FLOOR_LIP_OFFSET,
				FLOOR_TILE_SIZE.x, FLOOR_TILE_SIZE.y
			),
			false
		)
	draw_texture_rect(
		LADDER_TILE,
		Rect2(
			LADDER_X - (LADDER_TILE_WIDTH - LADDER_WIDTH) * 0.5, _ledge_top - LADDER_OVERSHOOT,
			LADDER_TILE_WIDTH, FLOOR_TOP - _ledge_top + LADDER_OVERSHOOT
		),
		false
	)
	_draw_ruler()
