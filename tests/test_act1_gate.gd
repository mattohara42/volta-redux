## Act 1's last room, as arithmetic. Its claim: it **cannot be finished without
## standing on your own sword**. The far side is out of a jump's reach, and a
## sword in the wooden face under it is a step you can reach and climb off, with
## nothing above the ledge in the way (the bug `RoomM2Gap`'s arithmetic missed).
## Then the gate: the switch sits where a standing throw from the yard lands,
## and the gate cannot be jumped.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"


func _reach(rise: float) -> float:
	var move: MovementConfig = load(MOVE)
	return Motion.jump_reach(
		move.jump_height, move.time_to_apex, move.fall_gravity_multiplier, move.max_run_speed, rise
	)


func _near_lip() -> float:
	var world: WorldConfig = load(WORLD)
	return Act1Gate.NEAR_EDGE - world.hero_width * 0.5


func _ledge_centre() -> float:
	var world: WorldConfig = load(WORLD)
	return SwordFlight.embed_position(Act1Gate.HOARDING.position.x, 1.0, world.sword_length)


func _ledge_top() -> float:
	var world: WorldConfig = load(WORLD)
	return (Act1Gate.NEAR_TOP - world.hero_height * 0.5) - Sword.LEDGE_THICKNESS * 0.5


func test_the_far_side_cannot_be_jumped_to() -> void:
	var move: MovementConfig = load(MOVE)
	check(
		Act1Gate.NEAR_TOP - Act1Gate.FAR_TOP > move.jump_height,
		"the far side is %.0f px up against a %.0f px jump" % [Act1Gate.NEAR_TOP - Act1Gate.FAR_TOP, move.jump_height]
	)


func test_the_sword_ledge_can_be_reached_and_climbed_off() -> void:
	var move: MovementConfig = load(MOVE)
	var reach_to := _ledge_centre() - _near_lip()
	var rise := Act1Gate.NEAR_TOP - _ledge_top()
	check(reach_to <= _reach(rise), "lip to ledge: %.0f px, budget %.0f" % [reach_to, _reach(rise)])
	var climb := _ledge_top() - Act1Gate.FAR_TOP
	check(climb < move.jump_height, "ledge to the far side: %.0f px up, under a %.0f px jump" % [climb, move.jump_height])
	check_eq(Act1Gate.HOARDING.position.x, Act1Gate.FAR_EDGE, "the wood is the far side's own face")
	check_eq(Act1Gate.HOARDING.position.y, Act1Gate.FAR_TOP, "running up to its top, so nothing overhangs the ledge")


func test_falling_in_is_a_retry() -> void:
	var move: MovementConfig = load(MOVE)
	check(Act1Gate.PIT_TOP - Act1Gate.NEAR_TOP < move.jump_height, "the ditch is shallower than a jump on the near side")
	check(Act1Gate.PIT_TOP - Act1Gate.FAR_TOP > move.jump_height, "and the far side is out of reach from it")


func test_the_hoarding_catches_a_throw_from_the_lip() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var y := Act1Gate.NEAR_TOP - world.hero_height * 0.5
	check(y > Act1Gate.HOARDING.position.y and y < Act1Gate.HOARDING.end.y, "a throw at %.0f meets the wood" % y)
	check(Act1Gate.HOARDING.position.x - _near_lip() < sword.max_range, "and it is in range")


func test_the_switch_is_where_a_standing_throw_lands() -> void:
	var world: WorldConfig = load(WORLD)
	var y := Bench.FLOOR_TOP - world.hero_height * 0.5
	check(y > Act1Gate.SWITCH.position.y and y < Act1Gate.SWITCH.end.y, "a yard throw goes into the switch")
	check_eq(Act1Gate.SWITCH.end.x, Act1Gate.YARD_X, "flush with the face you dropped from")
	var sword: SwordConfig = load(SWORD)
	check(Act1Gate.GATE.position.x - Act1Gate.YARD_X < sword.max_range, "and in range from anywhere short of the gate")


func test_the_gate_is_the_only_way_out() -> void:
	var move: MovementConfig = load(MOVE)
	check(Act1Gate.GATE.size.y > move.jump_height, "too tall to jump")
	check_eq(Act1Gate.gate_wall().position.y, 0.0, "with stone over it to the ceiling")
	check_eq(Act1Gate.LADDER_X, Act1Gate.YARD_X, "and a ladder back up from the yard")


func test_the_checkpoint_is_past_the_ditch() -> void:
	check(Act1Gate.CHECKPOINT_X > Act1Gate.FAR_EDGE and Act1Gate.CHECKPOINT_X < Act1Gate.YARD_X, "lit once you are across")
