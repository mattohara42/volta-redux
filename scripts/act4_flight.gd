## The ending (`SPEC.md` → *Act 4*): the freed dragon carries you out of the
## Hall of Volta. A short playable flight through a cavern of stone pillars,
## steering only up and down, and then the game's last card.
class_name Act4Flight
extends Node2D

const FLIGHT: FlightConfig = preload("res://config/flight.tres")
const TILES: ActTiles = preload("res://assets/art/act3/act3_tiles.tres")
const ROOM_WIDTH: float = 2400.0
const CEILING: float = 32.0
const FLOOR: float = Bench.FLOOR_TOP
const START := Vector2(80.0, 150.0)
const FINISH_X: float = 2200.0
const PILLAR_WIDTH: float = 40.0
## Each gap as (x, top, bottom): the open air the dragon has to pass through.
const GAPS: Array[Vector3] = [
	Vector3(480.0, 60.0, 200.0),
	Vector3(800.0, 150.0, 300.0),
	Vector3(1120.0, 50.0, 180.0),
	Vector3(1440.0, 130.0, 260.0),
	Vector3(1760.0, 170.0, 300.0),
]

var _rider: DragonRider


## Two pillars per gap, from the ceiling down to the gap and from the gap down
## to the floor.
static func pillars() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for gap in GAPS:
		out.append(Rect2(gap.x, CEILING, PILLAR_WIDTH, gap.y - CEILING))
		out.append(Rect2(gap.x, gap.z, PILLAR_WIDTH, FLOOR - gap.z))
	return out


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	_rider = DragonRider.new()
	add_child(_rider)
	_rider.configure(START, CEILING, FLOOR, FINISH_X, pillars(), FLIGHT)
	_rider.finished.connect(_on_finished)
	queue_redraw()


func _on_finished() -> void:
	var state := get_node_or_null("/root/ActState")
	var scene := get_tree().current_scene
	if state == null or scene == null:
		return
	state.leave_room(scene.scene_file_path, 0, 0, 0)


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, Rect2(0.0, 0.0, ROOM_WIDTH, CEILING), TILES)
	TileArt.draw_ground(self, Rect2(0.0, FLOOR, ROOM_WIDTH, Bench.ROOM_HEIGHT - FLOOR), TILES)
	for pillar in pillars():
		TileArt.draw_wall(self, pillar, TILES)
	# Daylight at the cave mouth: the way out.
	draw_rect(Rect2(FINISH_X, CEILING, ROOM_WIDTH - FINISH_X, FLOOR - CEILING), Palette.FIRE_HOT)
