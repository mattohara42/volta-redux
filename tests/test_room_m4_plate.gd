## The floor plate bench, as arithmetic: the pieces sit in the order the
## puzzle needs and within the sword's own reach.
extends TestCase


func test_the_plate_sits_before_the_gate_and_the_gate_before_the_goal() -> void:
	check(RoomM4Plate.PLATE.end.x <= RoomM4Plate.GATE.position.x, "plate before the gate")
	check(RoomM4Plate.GATE.end.x <= RoomM4Plate.GOAL_X, "gate before the goal")


func test_the_gate_reaches_the_floor_and_the_room_has_no_way_around_it() -> void:
	check_near(RoomM4Plate.GATE.end.y, RoomM4Plate.FLOOR_TOP, 0.001, "the gate reaches the floor")
	check(RoomM4Plate.GATE.position.y < RoomM4Plate.FLOOR_TOP - 96.0, "and reaches above a storey, nothing to jump over")


func test_the_plate_is_within_a_throw_of_where_the_room_starts() -> void:
	var sword: SwordConfig = load("res://config/sword.tres")
	var distance := RoomM4Plate.PLATE.position.x - RoomM4Plate.START_BRAZIER_X
	check(distance < sword.max_range, "a throw from the start should reach the plate")
