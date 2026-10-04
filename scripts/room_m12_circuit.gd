## The M12 bench: Act 3's current, alone in a room (`SPEC.md` → *Conduct*).
##
##   the wall    metal at the far left: a live piece above, a dead stub below,
##               and an insulating seam between them at throw height
##   the switch  wired to the stub, and holding the gate open while it is live
##   the floor   a live plate near the start, to show that live metal kills
##
## Turn round, throw into the seam, and the sword touches both sides of it: the
## stub goes live, the switch with it, and the gate rises. Hold J and the sword
## comes home, the bridge breaks, and the gate drops. An instrument, like the
## other benches: it asks nothing hard, it shows the rule working.
class_name RoomM12Circuit
extends Bench

const ROOM_WIDTH: float = 760.0
## One, as on M2's switch bench: with more, holding J throws a fresh sword into
## the seam before the recall, and the bridge never visibly breaks.
const SWORDS_HANDED_OUT: int = 1
const WORLD: WorldConfig = preload("res://config/world.tres")

const WALL_X: float = 0.0
const WALL_WIDTH: float = 24.0
const WALL_TOP: float = 120.0
## The seam sits where a standing throw flies, so the sword lands across it.
const SEAM_HEIGHT: float = 2.0

const LIVE_PLATE := Rect2(80.0, FLOOR_TOP - 4.0, 48.0, 4.0)
const SWITCH := Rect2(440.0, FLOOR_TOP - 140.0, 16.0, 16.0)
const GATE := Rect2(480.0, FLOOR_TOP - 120.0, 16.0, 120.0)


static func seam_y() -> float:
	return FLOOR_TOP - WORLD.hero_height * 0.5 - SEAM_HEIGHT * 0.5


static func live_piece() -> Rect2:
	return Rect2(WALL_X, WALL_TOP, WALL_WIDTH, seam_y() - WALL_TOP)


static func stub() -> Rect2:
	var top := seam_y() + SEAM_HEIGHT
	return Rect2(WALL_X, top, WALL_WIDTH, FLOOR_TOP - top)


func _ready() -> void:
	_hand_out_swords(SWORDS_HANDED_OUT)
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(GATE.position.x, 0.0, GATE.size.x, GATE.position.y))
	var network := _add_network()
	_add_conductor(network, live_piece(), true)
	var lower := _add_conductor(network, stub(), false)
	_add_conductor(network, LIVE_PLATE, true)
	var switch := _add_current_switch(network, SWITCH)
	network.wire(lower, switch)
	var gate := _add_gate(GATE)
	switch.held_changed.connect(gate.set_open)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	# The seam: insulation, drawn the dark of a gap so it reads as a break.
	draw_rect(Rect2(WALL_X, seam_y(), WALL_WIDTH, SEAM_HEIGHT), Palette.BACKDROP)
	# The wire from the stub to the switch, along the floor and up the wall.
	var wire := Palette.ARC_RESIDUE
	draw_line(Vector2(WALL_WIDTH, FLOOR_TOP - 2.0), Vector2(SWITCH.get_center().x, FLOOR_TOP - 2.0), wire, 1.0)
	draw_line(Vector2(SWITCH.get_center().x, FLOOR_TOP - 2.0), SWITCH.get_center(), wire, 1.0)
	draw_rect(Rect2(ROOM_WIDTH - 60.0, FLOOR_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
