## M9's atmosphere bench: bubbling lava with its embers, haze and glow, an arc
## between two posts, and a charged plate, on the Act 1 wall so the light has
## something to fall on. An instrument, like the other benches: the arc and the
## plate look dangerous and do nothing, because the generator that makes them
## lethal is M12's.
class_name RoomM9Atmosphere
extends Bench

const ROOM_WIDTH: float = 640.0

const START_BRAZIER_X: float = 40.0

## The pit, as an x range, with lava at the bottom.
const PIT := Vector2(230.0, 400.0)
const LAVA_INSET: float = 10.0

## Two posts either side of the pit and the arc between their tips.
const POST_LEFT_X: float = 200.0
const POST_RIGHT_X: float = 430.0
const POST_HEIGHT: float = 70.0

## A charged plate on the far floor.
const PLATE := Rect2(480.0, FLOOR_TOP - 6.0, 130.0, 6.0)


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, PIT.x, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(PIT.y, FLOOR_TOP, ROOM_WIDTH - PIT.y, ROOM_HEIGHT - FLOOR_TOP))
	_add_lava(Rect2(PIT.x, FLOOR_TOP + LAVA_INSET, PIT.y - PIT.x, ROOM_HEIGHT - FLOOR_TOP - LAVA_INSET))
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	var bolt := ArcBolt.new()
	bolt.setup(
		Vector2(POST_LEFT_X, FLOOR_TOP - POST_HEIGHT), Vector2(POST_RIGHT_X, FLOOR_TOP - POST_HEIGHT)
	)
	add_child(bolt)
	var plate := ChargedSurface.new()
	plate.setup(PLATE)
	add_child(plate)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background(self)
	TileArt.draw_ground(self, Rect2(0.0, FLOOR_TOP, PIT.x, ROOM_HEIGHT - FLOOR_TOP))
	TileArt.draw_ground(self, Rect2(PIT.y, FLOOR_TOP, ROOM_WIDTH - PIT.y, ROOM_HEIGHT - FLOOR_TOP))
	for x in [POST_LEFT_X, POST_RIGHT_X]:
		draw_rect(Rect2(x - 3.0, FLOOR_TOP - POST_HEIGHT, 6.0, POST_HEIGHT), Palette.STONE_MID)
		draw_rect(Rect2(x - 4.0, FLOOR_TOP - POST_HEIGHT - 3.0, 8.0, 4.0), Palette.STONE_LIT)
