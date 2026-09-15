## The M4 dormant bench: decoration that turns out to be alive.
##
## LEVELS.md's skeleton idea, generalised: a scorpion that starts asleep,
## reads as a prop, and wakes the moment the hero comes close enough to need
## to get past it. Sitting where a floor plate is proves the other half of
## `BACKLOG.md`'s "leave an enemy on it" at the same time: its dormant weight
## holds the gate open for free, and waking it is the cost of getting close
## enough to find that out.
##
## No claim here about whether a player can slip through before it wanders
## off the plate: that is a feel question for whoever tunes the real room,
## not a fact this grey-box bench asserts.
class_name RoomM4Dormant
extends Bench

const ROOM_WIDTH: float = 480.0

const START_BRAZIER_X: float = 40.0

## Sitting exactly on the plate, per the class comment: its dormant weight
## already holds the gate for anyone who has not woken it yet.
const PLATE := Rect2(190.0, 312.0, 40.0, 8.0)
const SCORPION_SIZE := Vector2(30.0, 34.0)
const SCORPION_HOME_X: float = 210.0
const SCORPION_RANGE: float = 90.0

const GATE := Rect2(280.0, 200.0, 16.0, 120.0)

const GOAL_X: float = ROOM_WIDTH - 60.0


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))

	var plate := _add_plate(PLATE)
	var gate := _add_gate(GATE)
	plate.held_changed.connect(gate.set_open)

	var scorpion := _add_scorpion(
		Rect2(SCORPION_HOME_X - SCORPION_SIZE.x * 0.5, FLOOR_TOP - SCORPION_SIZE.y, SCORPION_SIZE.x, SCORPION_SIZE.y),
		SCORPION_RANGE
	)
	scorpion.start_dormant()

	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	draw_rect(Rect2(GOAL_X, FLOOR_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
