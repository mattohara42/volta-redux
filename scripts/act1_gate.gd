## Act 1, room 4: the castle gate. **It cannot be finished without standing on
## your own sword**, and it ends the act at the gate (`HANDOFF.md`).
##
## Two beats, left to right:
##
##   1. **The ditch.** `RoomM2Gap`'s crossing, the same numbers raised onto the
##      approach: a gap too wide to jump with the far side higher, and a wooden
##      post standing in it. A throw into the post grows a one-tile ledge halfway
##      across. A ladder gets you out of the ditch, so falling in is a retry.
##   2. **The gate yard.** A drop into the yard before the castle gate. The
##      switch is set into the face you dropped from, as in the bailey, and the
##      gate is the way out of Act 1. A ladder goes back up, and a chest there
##      means nobody arrives at the last gate with nothing to throw.
##
## `tests/test_act1_gate.gd` holds the crossing to `config/` the way
## `tests/test_room_m2_gap.gd` holds the bench it came from.
class_name Act1Gate
extends Bench

const ROOM_WIDTH: float = 1280.0

## The approach, raised so the far side can stand over a yard with a switch in
## its face. Every number of the crossing is measured from here.
const NEAR_TOP: float = FLOOR_TOP - 48.0

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 96.0

## `RoomM2Gap`'s crossing, the same widths and rises.
const NEAR_EDGE: float = 400.0
const FAR_EDGE: float = 520.0
const FAR_TOP: float = NEAR_TOP - 32.0
const POST := Rect2(465.0, NEAR_TOP - 120.0, 10.0, ROOM_HEIGHT - (NEAR_TOP - 120.0))
const PIT_TOP: float = NEAR_TOP + 36.0

const CHECKPOINT_X: float = 600.0

## The drop into the gate yard, with the switch in its foot.
const YARD_X: float = 760.0
const SWITCH := Rect2(YARD_X - 24.0, FLOOR_TOP - 40.0, 24.0, 40.0)
const LADDER_X: float = YARD_X
const YARD_CHEST_X: float = 840.0

## The castle gate: Act 1's last door.
const GATE := Rect2(920.0, FLOOR_TOP - 120.0, 32.0, 120.0)

const EXIT_X: float = ROOM_WIDTH - 56.0


static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, NEAR_TOP, NEAR_EDGE, ROOM_HEIGHT - NEAR_TOP),
		Rect2(NEAR_EDGE, PIT_TOP, FAR_EDGE - NEAR_EDGE, ROOM_HEIGHT - PIT_TOP),
		Rect2(FAR_EDGE, FAR_TOP, YARD_X - FAR_EDGE, SWITCH.position.y - FAR_TOP),
		Rect2(FAR_EDGE, SWITCH.position.y, SWITCH.position.x - FAR_EDGE, ROOM_HEIGHT - SWITCH.position.y),
		Rect2(YARD_X, FLOOR_TOP, ROOM_WIDTH - YARD_X, ROOM_HEIGHT - FLOOR_TOP),
	]


static func gate_wall() -> Rect2:
	return Rect2(GATE.position.x, 0.0, GATE.size.x, GATE.position.y)


func _ready() -> void:
	for ground in grounds():
		_add_solid(ground)
	_add_solid(gate_wall())
	_add_wood(POST, false)
	_add_ladder(NEAR_EDGE + 4.0, NEAR_TOP, PIT_TOP)
	_add_ladder(LADDER_X, FAR_TOP, FLOOR_TOP)

	_add_brazier(Vector2(START_BRAZIER_X, NEAR_TOP))
	_add_brazier(Vector2(CHECKPOINT_X, FAR_TOP))
	_add_chest(Vector2(CHEST_X, NEAR_TOP))
	_add_chest(Vector2(YARD_CHEST_X, FLOOR_TOP))

	var switch := _add_switch(SWITCH)
	var gate := _add_gate(GATE)
	gate.art = TileArt.PORTCULLIS_TILE
	switch.held_changed.connect(gate.set_open)

	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH)
	# The levels as they read, not the collision pieces: the far side's face runs
	# unbroken down to the yard, with the switch set into it.
	TileArt.draw_ground(self, grounds()[0])
	TileArt.draw_ground(self, grounds()[1])
	TileArt.draw_ground(self, Rect2(FAR_EDGE, FAR_TOP, YARD_X - FAR_EDGE, ROOM_HEIGHT - FAR_TOP))
	TileArt.draw_ground(self, grounds()[4])
	TileArt.draw_wall(self, gate_wall())
	TileArt.draw_wood(self, POST)
	for ladder in _ladders:
		TileArt.draw_ladder(self, ladder)
