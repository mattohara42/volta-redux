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

## The ledge above the floor, one tier up, reached by the ladder. A whole
## number of floor tiles wide, so its art ends on a tile edge.
const LEDGE_X_START: float = 360.0
const LEDGE_TILE_COUNT: int = 13
const LADDER_X: float = 340.0

const BAT_SIZE := Vector2(20.0, 14.0)
const BAT_CENTRE := Vector2(240.0, FLOOR_TOP - 90.0)
const BAT_HALF_EXTENTS := Vector2(80.0, 50.0)

## Set once in `_ready`, from `world.tier_height` rather than a literal, so a
## retuned storey height moves the ledge and the ladder together with it.
var _ledge_top: float = 0.0
var _ledge_width: float = 0.0


func _ready() -> void:
	_ledge_top = FLOOR_TOP - world.tier_height
	_ledge_width = LEDGE_TILE_COUNT * TileArt.tile_width()
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(LEDGE_X_START, _ledge_top, _ledge_width, FLOOR_TOP - _ledge_top))
	_add_ladder(LADDER_X, _ledge_top, FLOOR_TOP)
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_bat(Rect2(BAT_CENTRE - BAT_SIZE * 0.5, BAT_SIZE), BAT_HALF_EXTENTS)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background(self)
	TileArt.draw_ladder(self, Rect2(
		LADDER_X, _ledge_top - LADDER_OVERSHOOT, LADDER_WIDTH, FLOOR_TOP - _ledge_top + LADDER_OVERSHOOT
	))
	TileArt.draw_ground(self, Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	TileArt.draw_ground(self, Rect2(LEDGE_X_START, _ledge_top, _ledge_width, FLOOR_TOP - _ledge_top))
	_draw_ruler()
