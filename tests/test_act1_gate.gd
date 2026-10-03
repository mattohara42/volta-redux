## Act 1's last room, as arithmetic. Its claim is `RoomM2Gap`'s: it **cannot be
## finished without standing on your own sword**. The crossing is that room's,
## raised onto the approach, so these are that file's checks measured from
## `NEAR_TOP` instead of the floor. Then the gate: the switch sits where a
## standing throw from the yard lands, and the gate cannot be jumped.
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
	return SwordFlight.embed_position(Act1Gate.POST.position.x, 1.0, world.sword_length)


func _ledge_top() -> float:
	var world: WorldConfig = load(WORLD)
	return (Act1Gate.NEAR_TOP - world.hero_height * 0.5) - Sword.LEDGE_THICKNESS * 0.5


func test_the_gap_cannot_be_jumped() -> void:
	var rise := Act1Gate.NEAR_TOP - Act1Gate.FAR_TOP
	var needed := Act1Gate.FAR_EDGE - Act1Gate.NEAR_EDGE
	check(needed > _reach(rise), "the bare gap is %.0f px against a %.0f px jump" % [needed, _reach(rise)])


func test_the_sword_makes_it_crossable() -> void:
	var world: WorldConfig = load(WORLD)
	var first := _ledge_centre() - _near_lip()
	var first_rise := Act1Gate.NEAR_TOP - _ledge_top()
	check(first <= _reach(first_rise), "to the ledge: %.0f px, budget %.0f" % [first, _reach(first_rise)])
	var second := (Act1Gate.FAR_EDGE + world.hero_width * 0.5) - _ledge_centre()
	var second_rise := _ledge_top() - Act1Gate.FAR_TOP
	check(second <= _reach(second_rise), "off the ledge: %.0f px, budget %.0f" % [second, _reach(second_rise)])


func test_the_crossing_cannot_be_skipped() -> void:
	var move: MovementConfig = load(MOVE)
	check(Act1Gate.NEAR_TOP - Act1Gate.POST.position.y > move.jump_height, "the post is too tall to land on")
	check(Act1Gate.PIT_TOP - Act1Gate.FAR_TOP > move.jump_height, "the far side is out of reach from the ditch")
	check(Act1Gate.PIT_TOP - Act1Gate.NEAR_TOP < move.jump_height, "and falling in is a retry")


func test_the_post_catches_a_throw_from_the_lip() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var y := Act1Gate.NEAR_TOP - world.hero_height * 0.5
	check(y > Act1Gate.POST.position.y and y < Act1Gate.POST.end.y, "a throw at %.0f meets the post" % y)
	check(Act1Gate.POST.position.x - _near_lip() < sword.max_range, "and the post is in range")


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
