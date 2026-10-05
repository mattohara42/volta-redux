## The ending (`SPEC.md` → *Act 4*): the freed dragon carries you out of the
## Hall of Volta. A short playable flight through a cavern of stone pillars,
## steering only up and down, and then the game's last card.
class_name Act4Flight
extends Node2D

const FLIGHT: FlightConfig = preload("res://config/flight.tres")
const FLIGHT_MUSIC: AudioStream = preload("res://assets/audio/music/flight.ogg")
const TILES: ActTiles = preload("res://assets/art/act4/act4_tiles.tres")
const ROOM_WIDTH: float = 2400.0
const CEILING: float = 32.0
const FLOOR: float = Bench.FLOOR_TOP
const START := Vector2(80.0, 150.0)
const FINISH_X: float = 2200.0
const PILLAR_WIDTH: float = 40.0
## How far the daylight at the cave mouth reaches back into the cave, art px.
const DAYLIGHT_REACH: float = 360.0
const DAYLIGHT_GLOW: float = 150.0
## Each gap as (x, top, bottom): the open air the dragon has to pass through.
const GAPS: Array[Vector3] = [
	Vector3(480.0, 60.0, 200.0),
	Vector3(800.0, 150.0, 300.0),
	Vector3(1120.0, 50.0, 180.0),
	Vector3(1440.0, 130.0, 260.0),
	Vector3(1760.0, 170.0, 300.0),
]

## The ride out has its own music, the only major key in the game, rather
## than Act 4's (`Audio.music_for` reads this).
var music: AudioStream = FLIGHT_MUSIC
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
	# The way out is through the caverns again, so the far layers are Act 2's
	# rather than the hall's: the last room you fly through is the first kind
	# of place you climbed down into.
	var backdrop := Backdrop.new()
	backdrop.setup(Backdrop.Style.CAVERN, hash(scene_file_path))
	backdrop.without_near_pillars()
	add_child(backdrop)
	# Act 4's dark, with the daylight at the cave mouth as the one big light:
	# the way out is the bright thing ahead.
	var act_state := get_node_or_null("/root/ActState")
	var act: ActConfig = act_state.act_of(scene_file_path) if act_state != null else null
	if act != null:
		var field := LightField.new()
		field.setup(act.ambient_light, act.ceiling_dim)
		add_child(field)
	var mouth_x := (FINISH_X + ROOM_WIDTH) * 0.5
	var daylight := LightSource.line(
		Vector2(mouth_x, CEILING), Vector2(mouth_x, FLOOR), DAYLIGHT_REACH, Palette.FIRE_HOT, 1.0
	)
	add_child(daylight)
	# And its glow spilling back into the cave, so the mouth is a brightness
	# you fly toward rather than a rectangle you fly into.
	var glow := LightGlow.make(DAYLIGHT_GLOW, Palette.FIRE_CORE, 0.7)
	glow.position += Vector2(FINISH_X, (CEILING + FLOOR) * 0.5)
	add_child(glow)
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
	# Daylight at the cave mouth: the way out. Out past the room's own width,
	# because the flight's camera looks half a screen beyond the finish.
	draw_rect(Rect2(FINISH_X, CEILING, ROOM_WIDTH - FINISH_X, FLOOR - CEILING), Palette.FIRE_HOT)
	draw_rect(Rect2(ROOM_WIDTH, 0.0, Bench.ROOM_HEIGHT, Bench.ROOM_HEIGHT), Palette.FIRE_HOT)
