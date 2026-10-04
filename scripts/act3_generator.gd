## Act 3's boss room: the generator (`SPEC.md` → *Conduct*). **It cannot be
## beaten by throwing.** It hangs on a shelf over the yard, and a sword thrown
## at it breaks. Its current runs out to the top of a recessed copper face,
## down through three breaks, one at each height a throw flies from (the yard
## and the two steps, as in `Act3Toll`), and back along a wire to a socket
## beside it. Bridge all three at once and the loop closes into it: it shorts,
## for good, and the gate beyond it lifts.
##
## Meanwhile it throws arcs at wherever you stood when it finished charging,
## so each throw is taken between arcs and you move after it.
class_name Act3Generator
extends Act3Room

const ROOM_WIDTH: float = 1040.0
const UPPER_TOP: float = FLOOR_TOP - 144.0
const YARD_X: float = 560.0
const OVERHANG: float = 16.0
const FACE_X: float = YARD_X - RECESS
const COPPER_X: float = FACE_X - COPPER_WIDTH

const STEP_LOW := Rect2(600.0, FLOOR_TOP - 40.0, 64.0, 40.0)
const STEP_HIGH := Rect2(664.0, FLOOR_TOP - 80.0, 64.0, 80.0)

## The generator's shelf, run out from the gate wall over the yard with room to
## walk under it, and the generator on it at the height of a throw from the
## high step, so that throw has something to break on.
const GATE := Rect2(920.0, FLOOR_TOP - 120.0, 32.0, 120.0)
const SHELF := Rect2(770.0, FLOOR_TOP - 68.0, GATE.position.x - 770.0, 16.0)
const CASING := Rect2(780.0, SHELF.position.y - 72.0, 72.0, 72.0)
## Where the loop comes home: a socket on the shelf, beside the generator.
const BACK := Rect2(872.0, SHELF.position.y - 16.0, 16.0, 16.0)

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 120.0
const EXIT_X: float = ROOM_WIDTH - 40.0


static func seams() -> Array[float]:
	return [seam_at(STEP_HIGH.position.y), seam_at(STEP_LOW.position.y), seam_at(FLOOR_TOP)]


## The copper, top to bottom: the piece the generator feeds, two middles, and
## the stub wired back to it.
static func pieces() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var top := UPPER_TOP + OVERHANG
	for seam in seams():
		result.append(Rect2(COPPER_X, top, COPPER_WIDTH, seam - top))
		top = seam + SEAM_HEIGHT
	result.append(Rect2(COPPER_X, top, COPPER_WIDTH, FLOOR_TOP - top))
	return result


static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, UPPER_TOP, COPPER_X, ROOM_HEIGHT - UPPER_TOP),
		Rect2(COPPER_X, UPPER_TOP, YARD_X - COPPER_X, OVERHANG),
		Rect2(COPPER_X, FLOOR_TOP, ROOM_WIDTH - COPPER_X, ROOM_HEIGHT - FLOOR_TOP),
		STEP_LOW,
		STEP_HIGH,
		SHELF,
	]


static func gate_wall() -> Rect2:
	return Rect2(GATE.position.x, CEILING_HEIGHT, GATE.size.x, GATE.position.y - CEILING_HEIGHT)


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	_add_solid(gate_wall())
	var network := _add_network()
	var all := pieces()
	var out: Conductor
	var stub: Conductor
	for i in all.size():
		var piece := _add_conductor(network, all[i], i == 0, COPPER)
		if i == 0:
			out = piece
		stub = piece
	var back := _add_current_switch(network, BACK)
	network.wire(stub, back)
	var generator := Generator.new()
	add_child(generator)
	generator.configure(CASING, out, back, enemies)
	generator.wake_x = YARD_X
	var gate := _add_gate(GATE)
	gate.art = TileArt.PORTCULLIS_TILE
	generator.shorted.connect(gate.set_open.bind(true))
	_add_brazier(Vector2(START_BRAZIER_X, UPPER_TOP))
	_add_chest(Vector2(CHEST_X, UPPER_TOP))
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
	for seam in seams():
		_draw_seam(COPPER_X, seam, COPPER_WIDTH)
	# Out from the generator to the top of the face, and back from the stub to
	# the socket beside it: one loop, broken three times.
	_draw_wire_overhead(Vector2(CASING.position.x, CASING.position.y + 8.0), Vector2(FACE_X, UPPER_TOP + OVERHANG + 4.0))
	_draw_wire(Vector2(FACE_X, FLOOR_TOP - 3.0), Vector2(STEP_LOW.position.x - 4.0, FLOOR_TOP - 3.0))
	_draw_wire_overhead(Vector2(STEP_LOW.position.x - 4.0, FLOOR_TOP - 3.0), BACK.get_center())
