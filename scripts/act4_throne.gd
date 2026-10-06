## Act 4, room 3: the throne. **Three gems, the right conductor, and the
## dragon finishes him.**
##
## The third gem is on a shelf cut down from a gallery, as in `Act4Gallery`,
## now under Volta's eye. Three pedestals close the rail overhead, which runs
## to the recessed copper face of his dais. A sword across its seam carries
## current to the dragon's chains, and if it holds for `volta_chain_burn_time`
## the chains let go. Volta casts at you meanwhile, and every few casts he
## pulls: every embedded sword in the room is torn out and thrown toward him,
## which breaks the circuit and starts the burn again. Freed, the dragon
## breathes on him and he falls into the fire below his dais, and the way out
## is the dragon, come down to the floor for you.
class_name Act4Throne
extends Act4Room

const ROOM_WIDTH: float = 1280.0
const RECESS: float = 16.0
const COPPER_WIDTH: float = 24.0
const SEAM_HEIGHT: float = 2.0
const COPPER: Texture2D = preload("res://assets/art/act3/tiles_px/copper.png")

const CRATE := Rect2(180.0, FLOOR_TOP - 40.0, 40.0, 40.0)
const GALLERY := Rect2(240.0, FLOOR_TOP - 100.0, 120.0, 100.0)
const WOOD_FACE: float = 12.0
const SHELF := Rect2(470.0, FLOOR_TOP - 124.0, 14.0, 12.0)

const PEDESTALS_X: Array[float] = [560.0, 660.0, 760.0]
const PEDESTAL := Vector2(16.0, 24.0)
const RAIL_Y: float = 96.0
const RAIL_HEIGHT: float = 8.0
const BREAK: float = 40.0

## The dais: its lip, the copper face recessed under it, and a fire pit.
const DAIS_TOP: float = FLOOR_TOP - 120.0
const LIP_X: float = 940.0
const FACE_X: float = LIP_X + RECESS
const OVERHANG: float = 16.0
const PIT := Rect2(1150.0, DAIS_TOP + 36.0, 80.0, FLOOR_TOP - DAIS_TOP - 36.0)
const CHAINS_SWITCH := Rect2(1000.0, DAIS_TOP - 14.0, 12.0, 12.0)
const DRAGON_AT := Vector2(1040.0, DAIS_TOP)
## The dragon sprite's origin is its body's centre, this far above its feet
## (`scenes/dragon_sprite.tscn`: both strips stand about 24 to 29 px below it).
const DRAGON_FEET_BELOW: float = 26.0
const VOLTA_AT := Vector2(1120.0, DAIS_TOP)
## Where the dragon waits for you once he is gone.
const DRAGON_LANDS := Vector2(880.0, FLOOR_TOP)

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 120.0
const VOLTA_WAKES_X: float = 520.0
const DRAGON_SCENE: PackedScene = preload("res://scenes/dragon_sprite.tscn")

var _burn := 0.0
var _switch: CurrentSwitch
var _dragon: Node2D
var _volta: Volta
var _freed := false
## The rail's first piece, the hall's power: it dies with him.
var _power: Conductor


static func seam() -> float:
	return throw_y(FLOOR_TOP) - SEAM_HEIGHT * 0.5


static func live_copper() -> Rect2:
	var top := DAIS_TOP + OVERHANG
	return Rect2(FACE_X, top, COPPER_WIDTH, seam() - top)


static func stub() -> Rect2:
	var top := seam() + SEAM_HEIGHT
	return Rect2(FACE_X, top, COPPER_WIDTH, FLOOR_TOP - top)


static func rail() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var left := 440.0
	for x in PEDESTALS_X:
		out.append(Rect2(left, RAIL_Y, x - BREAK * 0.5 - left, RAIL_HEIGHT))
		left = x + BREAK * 0.5
	out.append(Rect2(left, RAIL_Y, FACE_X + COPPER_WIDTH - left, RAIL_HEIGHT))
	return out


static func pedestal(i: int) -> Rect2:
	var x: float = PEDESTALS_X[i]
	return Rect2(x - PEDESTAL.x * 0.5, FLOOR_TOP - PEDESTAL.y, PEDESTAL.x, PEDESTAL.y)


static func wood() -> Rect2:
	return Rect2(GALLERY.position, Vector2(WOOD_FACE, GALLERY.size.y))


static func grounds() -> Array[Rect2]:
	var back := FACE_X + COPPER_WIDTH
	return [
		Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP),
		CRATE,
		Rect2(GALLERY.position.x + WOOD_FACE, GALLERY.position.y, GALLERY.size.x - WOOD_FACE, GALLERY.size.y),
		Rect2(LIP_X, DAIS_TOP, back - LIP_X, OVERHANG),
		Rect2(back, DAIS_TOP, PIT.position.x - back, FLOOR_TOP - DAIS_TOP),
		Rect2(PIT.position.x, PIT.end.y, PIT.size.x, 0.0),
		Rect2(PIT.end.x, DAIS_TOP, ROOM_WIDTH - PIT.end.x, FLOOR_TOP - DAIS_TOP),
	]


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		if ground.size.y > 0.0:
			_add_solid(ground)
	_add_wood(wood(), false)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	# Off the gallery's far side is a drop no jump climbs back (`SPEC.md`: you
	# can always walk back). The wood is the way up; this is only the way home.
	_add_ladder(GALLERY.end.x, GALLERY.position.y, FLOOR_TOP)
	var shelf := GemShelf.new()
	add_child(shelf)
	shelf.configure(SHELF, FLOOR_TOP, CEILING_HEIGHT)
	var network := _add_network()
	var pieces: Array[Conductor] = []
	var all := rail()
	for i in all.size():
		pieces.append(_add_conductor(network, all[i], i == 0))
	_power = pieces[0]
	for i in PEDESTALS_X.size():
		_add_gem_holder(network, pedestal(i), pieces[i], pieces[i + 1])
	var face := _add_conductor(network, live_copper(), false, COPPER)
	network.wire(pieces[pieces.size() - 1], face)
	var lower := _add_conductor(network, stub(), false, COPPER)
	_switch = _add_current_switch(network, CHAINS_SWITCH)
	network.wire(lower, _switch)
	_add_lava(PIT)
	_dragon = DRAGON_SCENE.instantiate() as Node2D
	_dragon.position = DRAGON_AT - Vector2(0.0, DRAGON_FEET_BELOW)
	# The strip faces right, toward Volta.
	add_child(_dragon)
	(_dragon.get_node("AnimationTree") as AnimationTree)["parameters/playback"].travel("chained")
	_volta = Volta.new()
	add_child(_volta)
	_volta.configure(VOLTA_AT, enemies)
	_volta.wake_x = VOLTA_WAKES_X
	_volta.fallen.connect(_on_volta_fallen)
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	add_to_group("chains")
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _freed:
		return
	var before := _burn
	_burn = VoltaRules.burn_after(_burn, _switch.is_live, delta)
	if VoltaRules.chains_free(_burn, enemies.volta_chain_burn_time):
		_free_the_dragon()
	elif (before > 0.0) != (_burn > 0.0):
		queue_redraw()


func status() -> String:
	if _freed:
		return "chains FREE"
	return "chains holding, burn %.1f" % _burn


func _free_the_dragon() -> void:
	_freed = true
	_volta.stop()
	(_dragon.get_node("AnimationTree") as AnimationTree)["parameters/playback"].travel("idle")
	var breath := FreedBreath.new()
	add_child(breath)
	breath.setup(DRAGON_AT + Vector2(30.0, -30.0), VOLTA_AT + Vector2(0.0, -20.0))
	breath.finished.connect(func() -> void: _volta.fall_into(PIT.end.y))
	queue_redraw()


func _on_volta_fallen() -> void:
	# His hall's current was his: it goes out with him, so the dais is safe.
	_power.is_source = false
	# The dragon comes down to the floor, and walking to it is the way out.
	var tween := create_tween()
	tween.tween_property(_dragon, "position", DRAGON_LANDS - Vector2(0.0, DRAGON_FEET_BELOW), 0.8).set_trans(Tween.TRANS_SINE)
	# Turned to face the hero, who comes from the left.
	tween.tween_property(_dragon, "scale:x", -1.0, 0.1)
	tween.tween_callback(func() -> void:
		_add_exit(Rect2(DRAGON_LANDS.x - 4.0, FLOOR_TOP - 48.0, 8.0, 48.0))
	)


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT), TILES)
	for ground in grounds():
		if ground.size.y > 0.0:
			TileArt.draw_ground(self, ground, TILES)
	TileArt.draw_wood(self, wood())
	TileArt.draw_ladder(self, _ladders[0])
	for i in PEDESTALS_X.size():
		TileArt.draw_ground(self, pedestal(i), TILES)
	draw_rect(Rect2(FACE_X, seam(), COPPER_WIDTH, SEAM_HEIGHT), Palette.BACKDROP)
	var wire := Palette.ARC_RESIDUE
	var pieces := rail()
	for i in PEDESTALS_X.size():
		var top := pedestal(i)
		var fork := Vector2(top.get_center().x, RAIL_Y + RAIL_HEIGHT + 24.0)
		draw_line(Vector2(fork.x, top.position.y), fork, wire, 1.0)
		draw_line(fork, Vector2(pieces[i].end.x, RAIL_Y + RAIL_HEIGHT), wire, 1.0)
		draw_line(fork, Vector2(pieces[i + 1].position.x, RAIL_Y + RAIL_HEIGHT), wire, 1.0)
	draw_line(Vector2(FACE_X + COPPER_WIDTH * 0.5, RAIL_Y + RAIL_HEIGHT), Vector2(FACE_X + COPPER_WIDTH * 0.5, DAIS_TOP), wire, 1.0)
	draw_line(CHAINS_SWITCH.get_center(), Vector2(DRAGON_AT.x, DAIS_TOP - 8.0), wire, 1.0)
	if not _freed:
		# The chains, from the dragon to rings in the dais, lit while they burn.
		var chain := Palette.ARC if _burn > 0.0 else Palette.STONE_LIT
		for ring in [DRAGON_AT + Vector2(-30.0, 0.0), DRAGON_AT + Vector2(30.0, 0.0)]:
			draw_line(DRAGON_AT + Vector2(0.0, -24.0), ring, chain, 2.0)
