## M2's second room: **it cannot be finished without recalling the sword while
## it holds a switch down.** That is the other half of BUILD_PLAN.md's
## done-when, and every part of it is load-bearing.
##
## You are handed **one** sword. That is what makes recall the only answer
## rather than one of two: with three you would spend one on the switch and
## another on the gap, and never learn what recall is for.
##
##   1. Turn around and throw the sword into the switch set in the wall behind
##      you. The gate opens while it is held.
##   2. Walk through. You are now past the gate and out of swords.
##   3. The gap beyond needs a ledge, and your sword is in the switch. An
##      embedded sword cannot be walked over and picked up, only recalled.
##   4. Hold J. The sword comes home and the gate slams behind you, which is
##      the price and does not matter, because you are already through.
##
## Recalling too early strands you on the near side with your sword, which is
## recoverable: throw it at the switch again. Spending it on the closed gate
## destroys it, and R restores both your position and your sword.
##
## The gap uses the same numbers as `RoomM2Gap`, measured the same way, and
## `tests/test_room_m2_switch.gd` holds them.
class_name RoomM2Switch
extends Bench

const ROOM_WIDTH: float = 900.0

## One. See the class comment: the whole puzzle rests on this number.
const SWORDS_HANDED_OUT: int = 1

## Set into the left wall, flush with its face, occupying the bottom 40 px so
## the slot lands at exactly the height a standing throw travels.
##
## It stood free on the floor first and read as a crate: the person who built
## the room could not find it. A mechanism in a wall is a fixture; the same
## mechanism on the floor is furniture, and no amount of gold paint on a box in
## the middle of a room fixes that. ART_DIRECTION.md carries the general rule.
##
## Walking into it still does nothing. A switch is weight in a socket.
const SWITCH := Rect2(0.0, FLOOR_TOP - 40.0, 24.0, 40.0)

## The stone above the switch, which is what makes it read as set **into**
## something rather than stuck **onto** it.
const SWITCH_WALL := Rect2(0.0, 0.0, 24.0, FLOOR_TOP - 40.0)

## Stone, and 120 px of it above the floor against a 56 px jump, so the only way
## past is the switch. A sword thrown at it while it is shut is a sword gone.
const GATE := Rect2(400.0, 200.0, 16.0, FLOOR_TOP - 200.0)

## The same crossing as M2's first room, on the far side of the gate: the far
## side out of a jump's reach, with a wooden face the sword makes a step in.
const NEAR_EDGE: float = 560.0
const FAR_EDGE: float = 632.0
const FAR_TOP: float = FLOOR_TOP - 64.0
const HOARDING := Rect2(FAR_EDGE, FAR_TOP, 16.0, ROOM_HEIGHT - FAR_TOP)
const PIT_TOP: float = 356.0


func _ready() -> void:
	_hand_out_swords(SWORDS_HANDED_OUT)

	_add_solid(Rect2(0.0, FLOOR_TOP, NEAR_EDGE, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(SWITCH_WALL)
	_add_solid(Rect2(HOARDING.end.x, FAR_TOP, ROOM_WIDTH - HOARDING.end.x, ROOM_HEIGHT - FAR_TOP))
	_add_solid(Rect2(NEAR_EDGE, PIT_TOP, FAR_EDGE - NEAR_EDGE, ROOM_HEIGHT - PIT_TOP))
	_add_wood(HOARDING)
	_add_ladder(NEAR_EDGE + 4.0, FLOOR_TOP, PIT_TOP)

	# The room wires its own switch to its own gate. CLAUDE.md: a room never
	# reaches into another room, and neither of these knows what the other is.
	var switch := _add_switch(SWITCH)
	var gate := _add_gate(GATE)
	switch.held_changed.connect(gate.set_open)

	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	draw_rect(Rect2(ROOM_WIDTH - 70.0, FAR_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
