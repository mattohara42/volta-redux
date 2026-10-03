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


func test_the_ditch_needs_the_sword() -> void:
	DitchChecks.run(
		self, "Act1Gate", Act1Gate.NEAR_EDGE, Act1Gate.NEAR_TOP,
		Act1Gate.FAR_TOP, Act1Gate.HOARDING, Act1Gate.PIT_TOP
	)


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
