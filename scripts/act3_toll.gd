## Act 3, room 5: the toll. **The gate takes every sword you carry, and the
## far side needs one back.**
##
## The recessed face is four pieces of copper with three seams, one at the
## height a throw flies from the yard and one for each step of the stair. All
## three bridged and the gate lifts, which leaves nothing in hand. Past it, the
## way out is a ledge too tall to jump over a wooden face. Recall, and the gate
## drops (`SPEC.md` → *Conduct*: recalling a sword breaks its bridge), so the
## question is only where you stand when you do it.
##
## `LEVELS.md` sketched this room as choosing which sword to give up last, but
## recall calls every embedded sword at once, so the choice here is where to
## recall from rather than which one.
class_name Act3Toll
extends Act3Room

const ROOM_WIDTH: float = 1240.0
## A storey and a half up, so the face below has room for three seams.
const UPPER_TOP: float = FLOOR_TOP - 144.0
const YARD_X: float = 560.0
const OVERHANG: float = 16.0
const FACE_X: float = YARD_X - RECESS
const COPPER_X: float = FACE_X - COPPER_WIDTH

const STEP_LOW := Rect2(600.0, FLOOR_TOP - 40.0, 64.0, 40.0)
const STEP_HIGH := Rect2(664.0, FLOOR_TOP - 80.0, 64.0, 80.0)
const SWITCH := Rect2(812.0, FLOOR_TOP - 150.0, 16.0, 16.0)
const GATE := Rect2(860.0, FLOOR_TOP - 120.0, 32.0, 120.0)

## The way out: a ledge over a wooden face, too tall to jump and one embedded
## sword short of it.
const CLIMB := Rect2(1120.0, FLOOR_TOP - 64.0, ROOM_WIDTH - 1120.0, 64.0)
const WOOD_FACE: float = 12.0

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 120.0
const CHECKPOINT_X: float = 960.0
const EXIT_X: float = ROOM_WIDTH - 40.0


## Where the seams sit, top to bottom: thrown from the high step, the low
## step and the yard.
static func seams() -> Array[float]:
	return [seam_at(STEP_HIGH.position.y), seam_at(STEP_LOW.position.y), seam_at(FLOOR_TOP)]


## The copper, top to bottom: the live piece under the overhang, two middles,
## and the stub wired to the socket.
static func pieces() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var top := UPPER_TOP + OVERHANG
	for seam in seams():
		result.append(Rect2(COPPER_X, top, COPPER_WIDTH, seam - top))
		top = seam + SEAM_HEIGHT
	result.append(Rect2(COPPER_X, top, COPPER_WIDTH, FLOOR_TOP - top))
	return result


static func wood() -> Rect2:
	return Rect2(CLIMB.position, Vector2(WOOD_FACE, CLIMB.size.y))


static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, UPPER_TOP, COPPER_X, ROOM_HEIGHT - UPPER_TOP),
		Rect2(COPPER_X, UPPER_TOP, YARD_X - COPPER_X, OVERHANG),
		Rect2(COPPER_X, FLOOR_TOP, ROOM_WIDTH - COPPER_X, ROOM_HEIGHT - FLOOR_TOP),
		STEP_LOW,
		STEP_HIGH,
		Rect2(CLIMB.position.x + WOOD_FACE, CLIMB.position.y, CLIMB.size.x - WOOD_FACE, CLIMB.size.y),
	]


static func gate_wall() -> Rect2:
	return Rect2(GATE.position.x, CEILING_HEIGHT, GATE.size.x, GATE.position.y - CEILING_HEIGHT)


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_wood(wood(), false)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	_add_solid(gate_wall())
	var network := _add_network()
	var all := pieces()
	var lower: Conductor
	for i in all.size():
		lower = _add_conductor(network, all[i], i == 0, COPPER)
	var switch := _add_current_switch(network, SWITCH)
	network.wire(lower, switch)
	var gate := _add_gate(GATE)
	gate.art = TileArt.PORTCULLIS_TILE
	switch.held_changed.connect(gate.set_open)
	_add_brazier(Vector2(START_BRAZIER_X, UPPER_TOP))
	_add_chest(Vector2(CHEST_X, UPPER_TOP))
	_add_brazier(Vector2(CHECKPOINT_X, FLOOR_TOP))
	_add_exit(Rect2(EXIT_X, CLIMB.position.y - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT), TILES)
	for ground in grounds():
		TileArt.draw_ground(self, ground, TILES)
	TileArt.draw_wall(self, gate_wall(), TILES)
	TileArt.draw_wood(self, wood())
	for seam in seams():
		_draw_seam(COPPER_X, seam, COPPER_WIDTH)
	_draw_wire(Vector2(FACE_X, FLOOR_TOP - 3.0), Vector2(STEP_LOW.position.x - 4.0, FLOOR_TOP - 3.0))
	_draw_wire_overhead(Vector2(STEP_LOW.position.x - 4.0, FLOOR_TOP - 3.0), SWITCH.get_center())
