## Act 3, room 3: the copper floor. **Do not stand on what you are about to
## make live.**
##
## The recessed face and its seam again, but the floor in front of the face is
## copper, and it is wired into the circuit between the stub and the socket.
## Bridge the seam while standing on it and the current you just let through
## runs through your feet. Step off it onto the stone first, then throw.
class_name Act3Floor
extends Act3Room

const ROOM_WIDTH: float = 960.0
const UPPER_TOP: float = FLOOR_TOP - 64.0
const YARD_X: float = 560.0
const OVERHANG: float = 16.0
const FACE_X: float = YARD_X - RECESS
const COPPER_X: float = FACE_X - COPPER_WIDTH

## The copper floor, from the face out into the yard. You land on it dead.
const STRIP := Rect2(COPPER_X, FLOOR_TOP, 120.0, ROOM_HEIGHT - FLOOR_TOP)
const SWITCH := Rect2(712.0, FLOOR_TOP - 150.0, 16.0, 16.0)
const GATE := Rect2(760.0, FLOOR_TOP - 120.0, 32.0, 120.0)
const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 700.0
const EXIT_X: float = ROOM_WIDTH - 40.0


static func seam_y() -> float:
	return seam_at(FLOOR_TOP)


static func live_copper() -> Rect2:
	var top := UPPER_TOP + OVERHANG
	return Rect2(COPPER_X, top, COPPER_WIDTH, seam_y() - top)


static func stub() -> Rect2:
	var top := seam_y() + SEAM_HEIGHT
	return Rect2(COPPER_X, top, COPPER_WIDTH, FLOOR_TOP - top)


static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, UPPER_TOP, COPPER_X, ROOM_HEIGHT - UPPER_TOP),
		Rect2(COPPER_X, UPPER_TOP, YARD_X - COPPER_X, OVERHANG),
		Rect2(STRIP.end.x, FLOOR_TOP, ROOM_WIDTH - STRIP.end.x, ROOM_HEIGHT - FLOOR_TOP),
	]


static func gate_wall() -> Rect2:
	return Rect2(GATE.position.x, CEILING_HEIGHT, GATE.size.x, GATE.position.y - CEILING_HEIGHT)


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	_add_solid(gate_wall())
	_add_way_back(YARD_X, UPPER_TOP)
	var network := _add_network()
	_add_conductor(network, live_copper(), true, COPPER)
	var lower := _add_conductor(network, stub(), false, COPPER)
	var floor := _add_conductor(network, STRIP, false, COPPER)
	var switch := _add_current_switch(network, SWITCH)
	network.wire(lower, floor)
	network.wire(floor, switch)
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
	_draw_ways_back()
	_draw_seam(COPPER_X, seam_y(), COPPER_WIDTH)
	_draw_wire_overhead(Vector2(STRIP.end.x - 4.0, FLOOR_TOP - 1.0), SWITCH.get_center())
