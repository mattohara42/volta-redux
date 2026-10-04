## Act 3, room 2: the insulator. **Wood does not carry current.**
##
## The same recessed copper face as the hall, cut twice. The seam at floor
## throw height is copper above and **wood** below: a sword there bites both and
## carries nothing, because wood is not a conductor. The real seam is higher,
## copper on copper, and only a throw from the stone step in the yard flies down
## it. That joins the live copper at the top to the copper below, which is wired
## to the socket over the gate.
class_name Act3Insulator
extends Act3Room

const ROOM_WIDTH: float = 1000.0
const UPPER_TOP: float = FLOOR_TOP - 96.0
const YARD_X: float = 560.0
const OVERHANG: float = 16.0
const FACE_X: float = YARD_X - RECESS
const COPPER_X: float = FACE_X - COPPER_WIDTH

## The step a throw down the real seam is made from: a jump up from the yard.
const STEP := Rect2(620.0, FLOOR_TOP - 40.0, 64.0, 40.0)
const SWITCH := Rect2(812.0, FLOOR_TOP - 150.0, 16.0, 16.0)
const GATE := Rect2(860.0, FLOOR_TOP - 120.0, 32.0, 120.0)
const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 740.0
const EXIT_X: float = ROOM_WIDTH - 40.0
const WOOD_ART: Texture2D = preload("res://assets/art/act1/tiles_px/wood.png")


## The real seam, a throw from the step.
static func high_seam() -> float:
	return seam_at(STEP.position.y)


## The decoy, a throw from the yard floor.
static func low_seam() -> float:
	return seam_at(FLOOR_TOP)


static func live_copper() -> Rect2:
	var top := UPPER_TOP + OVERHANG
	return Rect2(COPPER_X, top, COPPER_WIDTH, high_seam() - top)


## Between the two seams: dead until the high seam is bridged, and wired to the
## socket.
static func wired_copper() -> Rect2:
	var top := high_seam() + SEAM_HEIGHT
	return Rect2(COPPER_X, top, COPPER_WIDTH, low_seam() - top)


static func wood() -> Rect2:
	var top := low_seam() + SEAM_HEIGHT
	return Rect2(COPPER_X, top, COPPER_WIDTH, FLOOR_TOP - top)


static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, UPPER_TOP, COPPER_X, ROOM_HEIGHT - UPPER_TOP),
		Rect2(COPPER_X, UPPER_TOP, YARD_X - COPPER_X, OVERHANG),
		Rect2(COPPER_X, FLOOR_TOP, ROOM_WIDTH - COPPER_X, ROOM_HEIGHT - FLOOR_TOP),
		STEP,
	]


static func gate_wall() -> Rect2:
	return Rect2(GATE.position.x, CEILING_HEIGHT, GATE.size.x, GATE.position.y - CEILING_HEIGHT)


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	_add_solid(gate_wall())
	_add_wood(wood(), false)
	var network := _add_network()
	_add_conductor(network, live_copper(), true, COPPER)
	var middle := _add_conductor(network, wired_copper(), false, COPPER)
	var switch := _add_current_switch(network, SWITCH)
	network.wire(middle, switch)
	var gate := _add_gate(GATE)
	gate.art = TileArt.PORTCULLIS_TILE
	switch.held_changed.connect(gate.set_open)
	_add_brazier(Vector2(START_BRAZIER_X, UPPER_TOP))
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT), TILES)
	for ground in grounds():
		TileArt.draw_ground(self, ground, TILES)
	TileArt.draw_wall(self, gate_wall(), TILES)
	draw_texture_rect(WOOD_ART, wood(), true)
	_draw_seam(COPPER_X, high_seam(), COPPER_WIDTH)
	_draw_seam(COPPER_X, low_seam(), COPPER_WIDTH)
	_draw_wire_overhead(Vector2(FACE_X, wired_copper().get_center().y), SWITCH.get_center())
