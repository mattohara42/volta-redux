## Act 1's third room, as arithmetic. Its claims: both hurdles can be jumped and
## both catch a standing throw, the switch sits where a standing throw from the
## yard lands, the gate cannot be jumped or climbed over, and the dragon's grate
## is scenery above the floor. Every number it rests on lives in `config/`.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"


func _throw_y(surface: float) -> float:
	var world: WorldConfig = load(WORLD)
	return surface - world.hero_height * 0.5


func test_both_hurdles_are_jumped_and_catch_a_throw() -> void:
	var move: MovementConfig = load(MOVE)
	var y := _throw_y(Act1Bailey.UPPER_TOP)
	for block in [Act1Bailey.WOOD_BLOCK, Act1Bailey.STONE_BLOCK]:
		check(block.size.y < move.jump_height, "%.0f px is under a jump" % block.size.y)
		check(y > block.position.y and y < block.end.y, "a standing throw at %.0f meets it" % y)
		check_eq(block.end.y, Act1Bailey.UPPER_TOP, "and it stands on the floor")


func test_the_switch_is_where_a_standing_throw_lands() -> void:
	var y := _throw_y(Bench.FLOOR_TOP)
	check(
		y > Act1Bailey.SWITCH.position.y and y < Act1Bailey.SWITCH.end.y,
		"a throw at %.0f goes into the switch's %.0f to %.0f" % [y, Act1Bailey.SWITCH.position.y, Act1Bailey.SWITCH.end.y]
	)
	check_eq(Act1Bailey.SWITCH.end.x, Act1Bailey.YARD_X, "flush with the face you dropped from")
	check_eq(Act1Bailey.SWITCH.end.y, Bench.FLOOR_TOP, "at the foot of it")


func test_the_switch_is_inside_throwing_range_of_the_yard() -> void:
	var sword: SwordConfig = load(SWORD)
	check(
		Act1Bailey.GATE.position.x - Act1Bailey.YARD_X < sword.max_range,
		"from anywhere short of the gate, the switch is in range"
	)


func test_the_gate_is_the_only_way_on() -> void:
	var move: MovementConfig = load(MOVE)
	check(Act1Bailey.GATE.size.y > move.jump_height, "too tall to jump")
	check_eq(Act1Bailey.GATE.end.y, Bench.FLOOR_TOP, "down to the floor")
	check_eq(Act1Bailey.gate_wall().position.y, 0.0, "with stone over it to the ceiling")


func test_the_yard_has_a_way_back_up() -> void:
	check_eq(Act1Bailey.LADDER_X, Act1Bailey.YARD_X, "a ladder at the drop")


func test_the_grate_is_scenery_above_the_floor() -> void:
	check(Act1Bailey.GRATE.end.y < Act1Bailey.UPPER_TOP, "it ends above where you walk")
	for x in Act1Bailey.GRATE_CHAINS:
		check(x > Act1Bailey.GRATE.position.x and x < Act1Bailey.GRATE.end.x, "a chain inside the window")
