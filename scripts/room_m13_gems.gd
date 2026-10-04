## The M13 bench: Act 4's gems, alone in a room (`SPEC.md` → *Act 4*).
##
##   the rail     four pieces of metal high overhead, live at the left, with a
##                break between each pair, and the last wired to a switch
##   the gems     three, lying on the floor at the start
##   the holders  three pedestals, each wired up to one break
##
## Pick up the gems, walk into each pedestal and the gem is set: its break
## closes. All three, and current reaches the switch and the gate rises. An
## instrument, like the other benches.
class_name RoomM13Gems
extends Bench

const ROOM_WIDTH: float = 900.0
const RAIL_Y: float = 96.0
const RAIL_HEIGHT: float = 8.0
const RAIL_X: float = 300.0
const PIECE_WIDTH: float = 80.0
const BREAK: float = 40.0
const PEDESTAL := Vector2(16.0, 24.0)
const GEMS_X: Array[float] = [140.0, 180.0, 220.0]
const SWITCH := Rect2(760.0, RAIL_Y - 4.0, 16.0, 16.0)
const GATE := Rect2(800.0, FLOOR_TOP - 120.0, 16.0, 120.0)


static func pieces() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i in 4:
		out.append(Rect2(RAIL_X + i * (PIECE_WIDTH + BREAK), RAIL_Y, PIECE_WIDTH, RAIL_HEIGHT))
	return out


## The pedestal under break `i`.
static func pedestal(i: int) -> Rect2:
	var gap_centre := RAIL_X + PIECE_WIDTH + BREAK * 0.5 + i * (PIECE_WIDTH + BREAK)
	return Rect2(gap_centre - PEDESTAL.x * 0.5, FLOOR_TOP - PEDESTAL.y, PEDESTAL.x, PEDESTAL.y)


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(GATE.position.x, 0.0, GATE.size.x, GATE.position.y))
	var network := _add_network()
	var rail: Array[Conductor] = []
	var all := pieces()
	for i in all.size():
		rail.append(_add_conductor(network, all[i], i == 0))
	for i in 3:
		_add_gem_holder(network, pedestal(i), rail[i], rail[i + 1])
	var switch := _add_current_switch(network, SWITCH)
	network.wire(rail[3], switch)
	var gate := _add_gate(GATE)
	switch.held_changed.connect(gate.set_open)
	for x in GEMS_X:
		_add_gem(Vector2(x, FLOOR_TOP))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	var wire := Palette.ARC_RESIDUE
	for i in 3:
		var top := pedestal(i)
		var x := top.get_center().x
		var left := pieces()[i].end.x
		var right := pieces()[i + 1].position.x
		# Two wires up from the pedestal, one to each side of its break, so
		# the pedestal reads as the missing link between them.
		var fork := Vector2(x, RAIL_Y + RAIL_HEIGHT + 24.0)
		draw_line(Vector2(x, top.position.y), fork, wire, 1.0)
		draw_line(fork, Vector2(left, RAIL_Y + RAIL_HEIGHT), wire, 1.0)
		draw_line(fork, Vector2(right, RAIL_Y + RAIL_HEIGHT), wire, 1.0)
	draw_line(Vector2(pieces()[3].end.x, RAIL_Y + RAIL_HEIGHT * 0.5), SWITCH.get_center(), wire, 1.0)
	draw_rect(Rect2(ROOM_WIDTH - 60.0, FLOOR_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
