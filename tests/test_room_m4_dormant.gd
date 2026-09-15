## The dormant bench, as arithmetic: the scorpion sits where the plate is,
## and the room is laid out in the order the puzzle needs.
extends TestCase


func test_the_scorpion_starts_on_the_plate() -> void:
	check(
		RoomM4Dormant.SCORPION_HOME_X >= RoomM4Dormant.PLATE.position.x
			and RoomM4Dormant.SCORPION_HOME_X <= RoomM4Dormant.PLATE.end.x,
		"the scorpion's home should sit inside the plate it is meant to weigh down"
	)


func test_the_plate_sits_before_the_gate_and_the_gate_before_the_goal() -> void:
	check(RoomM4Dormant.PLATE.end.x <= RoomM4Dormant.GATE.position.x, "plate before the gate")
	check(RoomM4Dormant.GATE.end.x <= RoomM4Dormant.GOAL_X, "gate before the goal")


## The scorpion's patrol has to actually leave the plate once awake, or
## waking it would mean nothing changed.
func test_the_scorpions_patrol_reaches_past_the_plate() -> void:
	var far_end := RoomM4Dormant.SCORPION_HOME_X + RoomM4Dormant.SCORPION_RANGE
	check(far_end > RoomM4Dormant.PLATE.end.x, "the awake patrol should walk clear of the plate")
