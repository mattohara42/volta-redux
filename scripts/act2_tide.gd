## Act 2, room 4: the tide. **Lava that rises and falls** (`SPEC.md`, Act 2).
##
## A low passage between two raised banks, with two rock refuges standing in it.
## The lava lies under the passage floor for a while, comes up over it, stands
## there, and goes back down (`LavaTide`). Cross a stretch while it is low and be
## up on the next refuge before it arrives. No one stretch is long, and the
## whole passage is far too long for one low tide, so the refuges are the route.
##
## Every timing is `config/hazards.tres`'s, and `tests/test_act2_tide.gd` holds
## each stretch to the window a low tide gives.
class_name Act2Tide
extends Bench

const TILES: ActTiles = preload("res://assets/art/act2/act2_tiles.tres")

const ROOM_WIDTH: float = 1200.0
## The banks and refuges, high enough to stand clear of a high tide and low
## enough to jump onto from the passage floor.
const RAISED_TOP: float = FLOOR_TOP - 40.0
const ENTRY_END: float = 200.0
const EXIT_START: float = 1000.0
const REFUGE_WIDTH: float = 40.0
const REFUGES: Array[float] = [440.0, 720.0]
## The tide's range: under the floor when low, over it when high.
const LOW_Y: float = FLOOR_TOP + 16.0
const HIGH_Y: float = FLOOR_TOP - 24.0

const START_BRAZIER_X: float = 60.0
const CHEST_X: float = 120.0
## On the second refuge: a respawn here starts on a low tide with one stretch to go.
const MID_BRAZIER_X: float = 740.0
const EXIT_X: float = ROOM_WIDTH - 40.0
const CEILING := Rect2(0.0, 0.0, ROOM_WIDTH, 32.0)


static func passage() -> Rect2:
	return Rect2(ENTRY_END, FLOOR_TOP, EXIT_START - ENTRY_END, ROOM_HEIGHT - FLOOR_TOP)


static func refuge(x: float) -> Rect2:
	return Rect2(x, RAISED_TOP, REFUGE_WIDTH, ROOM_HEIGHT - RAISED_TOP)


## The stretches of open passage, as x ranges, entry to exit.
static func stretches() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var from := ENTRY_END
	for x in REFUGES:
		out.append(Vector2(from, x))
		from = x + REFUGE_WIDTH
	out.append(Vector2(from, EXIT_START))
	return out


static func grounds() -> Array[Rect2]:
	var out: Array[Rect2] = [
		Rect2(0.0, RAISED_TOP, ENTRY_END, ROOM_HEIGHT - RAISED_TOP),
		passage(),
		Rect2(EXIT_START, RAISED_TOP, ROOM_WIDTH - EXIT_START, ROOM_HEIGHT - RAISED_TOP),
	]
	for x in REFUGES:
		out.append(refuge(x))
	return out


func _ready() -> void:
	for ground in grounds():
		_add_solid(ground)
	_add_solid(CEILING)

	var tide := LavaTideNode.new()
	add_child(tide)
	tide.configure(Vector2(ENTRY_END, EXIT_START), LOW_Y, HIGH_Y, hazards)

	# The rock in front of the lava, so a low tide sinks out of sight.
	var layer := GroundLayer.new()
	layer.rects = grounds()
	layer.tiles = TILES
	add_child(layer)

	_add_brazier(Vector2(START_BRAZIER_X, RAISED_TOP))
	_add_brazier(Vector2(MID_BRAZIER_X, RAISED_TOP))
	_add_chest(Vector2(CHEST_X, RAISED_TOP))
	_add_exit(Rect2(EXIT_X, RAISED_TOP - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, CEILING, TILES)
