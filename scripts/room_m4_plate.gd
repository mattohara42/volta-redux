## The M4 floor plate bench: a gate a plate opens, and two ways to hold it.
##
## `FloorPlate` does not care what is weighing it down. This bench proves the
## honest case first, standing on it yourself, and then the puzzle
## `BACKLOG.md` actually wanted: leaving a sword behind to hold the plate for
## you, at the cost of the sword, so you can walk through while it stays.
##
## Luring an enemy onto the plate instead is the other case `FloorPlate`'s
## own mask already answers to (`Enemy.ENEMY_LAYER`), but none of M4's five
## built enemies can hold still long enough to make that a real puzzle: all
## five either patrol without stopping or chase the hero without stopping.
## That is the dormant-until-approached idea in `LEVELS.md`, not yet built,
## and this bench does not pretend otherwise.
class_name RoomM4Plate
extends Bench

const ROOM_WIDTH: float = 520.0

const START_BRAZIER_X: float = 40.0

## Wide on purpose. Where exactly a missed sword drifts to before it falls
## depends on its own leftover horizontal speed as much as on where the
## miss happened, and pinning that to a narrow target is a tuning question
## for M14, not a fact worth hard-coding into a grey-box proof. Wide enough
## to catch a miss anywhere from the ladder to short of the gate.
const PLATE := Rect2(150.0, 312.0, 160.0, 8.0)

const GATE := Rect2(320.0, 200.0, 16.0, 120.0)

const GOAL_X: float = ROOM_WIDTH - 60.0

## A way to change height without changing x much: `SwordFlight`'s own
## docstring is explicit that a flat return is missed by height, not by
## position, and a ladder is the honest way to ask for that on purpose.
## Set into the plate's own span, so missing the catch here is also standing
## roughly where the sword needs to land.
const LADDER_X: float = 245.0


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_ladder(LADDER_X, 0.0, FLOOR_TOP)

	var plate := _add_plate(PLATE)
	var gate := _add_gate(GATE)
	plate.held_changed.connect(gate.set_open)

	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	draw_rect(Rect2(GOAL_X, FLOOR_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
