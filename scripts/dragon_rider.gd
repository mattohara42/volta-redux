## The hero on the freed dragon (`Act4Flight`). Not a `Player`: the dragon
## flies forward at `forward_speed` on its own and the only input is up and
## down (`climb_up`, `climb_down`). A pillar touched ends the attempt and the
## flight starts again; reaching `finish_x` ends the game.
class_name DragonRider
extends Node2D

signal crashed
signal finished

const DRAGON_SCENE: PackedScene = preload("res://scenes/dragon_flight_sprite.tscn")
const ATMOSPHERE: AtmosphereConfig = preload("res://config/atmosphere.tres")
## The box that has to fit through a gap: the dragon's body with the hero on
## its back, a little inside the drawn wings and tail as a forgiving hit box
## should be. Centred `BOX_OFFSET` from this node.
const SIZE := Vector2(88.0, 58.0)
const BOX_OFFSET := Vector2(0.0, -5.0)
## Where the hero sits, astride the neck: drawn into the dragon's own sheet
## (`tools/composite-rider.py`), and where the hero's light rides.
const SEAT := Vector2(22.0, -15.0)

var config: FlightConfig
var crashes := 0
var is_finished := false

var _start := Vector2.ZERO
var _top := 0.0
var _bottom := 0.0
var _finish_x := 0.0
var _pillars: Array[Rect2] = []


func configure(start: Vector2, top: float, bottom: float, finish_x: float, pillars: Array[Rect2], flight: FlightConfig) -> void:
	_start = start
	_top = top + SIZE.y * 0.5 - BOX_OFFSET.y
	_bottom = bottom - SIZE.y * 0.5 - BOX_OFFSET.y
	_finish_x = finish_x
	_pillars = pillars
	config = flight
	position = start
	var dragon := DRAGON_SCENE.instantiate() as Node2D
	add_child(dragon)
	# The hero's own faint light rides with them, as it goes everywhere the
	# hero goes, so the thing you steer is never lost in the cave's dark; and
	# both take a rim from the torches and the daylight, as everything alive
	# in the game does.
	var light := LightSource.point(ATMOSPHERE.light_hero_radius, Palette.FIRE_CORE, ATMOSPHERE.light_hero_strength)
	light.position = SEAT
	add_child(light)
	RimLight.attach(dragon.get_node_or_null("AnimatedSprite2D") as CanvasItem, self)
	var camera := Camera2D.new()
	camera.limit_top = 0
	camera.limit_bottom = int(Bench.ROOM_HEIGHT)
	camera.limit_left = 0
	camera.limit_right = int(finish_x + 320.0)
	add_child(camera)
	add_to_group("riders")


func _physics_process(delta: float) -> void:
	if is_finished:
		return
	var steer := Input.get_axis("climb_up", "climb_down")
	position.x += config.forward_speed * delta
	position.y = FlightRules.height_after(position.y, steer, config.vertical_speed, delta, _top, _bottom)
	if FlightRules.crashed(rect(), _pillars):
		crashes += 1
		position = _start
		crashed.emit()
	elif position.x >= _finish_x:
		is_finished = true
		finished.emit()


func rect() -> Rect2:
	return Rect2(position + BOX_OFFSET - SIZE * 0.5, SIZE)


func status() -> String:
	return "rider at %.0f, %d crash(es)%s" % [position.x, crashes, ", FINISHED" if is_finished else ""]
