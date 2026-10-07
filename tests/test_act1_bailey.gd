## Act 1's third room, as arithmetic, read from its level file
## (`levels/act1_bailey.level`). Its claims: both hurdles can be jumped and
## both catch a standing throw, the switch sits ahead of you where a standing
## throw from the yard lands, the gate it opens is on screen when you throw,
## the gate cannot be jumped or climbed over, the yard has a ladder at each
## end, and the dragon's grate is scenery above the floor. Every number it
## rests on lives in `config/` or the level file.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"

## The level above the yard and the yard's floor, as the map draws them.
const UPPER_TOP: float = 256.0
const YARD_TOP: float = 320.0


func _level() -> LevelGrid.Level:
	return GridRoom.read(Act1Bailey.LEVEL)


func _throw_y(surface: float) -> float:
	var world: WorldConfig = load(WORLD)
	return surface - world.hero_height * 0.5


## The yard: the gap between the level you drop from and the face across it,
## down to the yard's floor. Below it the map is stone wall to wall, so the
## floor itself merges with everything under the levels either side.
func _yard(level: LevelGrid.Level) -> Rect2:
	var left := 0.0
	var right := INF
	for rect in level.ground:
		if is_equal_approx(rect.position.y, UPPER_TOP) and is_zero_approx(rect.position.x):
			left = rect.end.x
	for rect in level.ground:
		if is_equal_approx(rect.position.y, UPPER_TOP) and rect.position.x > left:
			right = minf(right, rect.position.x)
	return Rect2(left, UPPER_TOP, right - left, YARD_TOP - UPPER_TOP)


func test_the_level_reads_cleanly() -> void:
	var level := _level()
	check_eq(level.errors.size(), 0, "no errors: %s" % [level.errors])
	check(level.has_start, "the hero has somewhere to start")
	check(level.exit.size != Vector2.ZERO, "and somewhere to leave")


func test_both_hurdles_are_jumped_and_catch_a_throw() -> void:
	var move: MovementConfig = load(MOVE)
	var level := _level()
	var y := _throw_y(UPPER_TOP)
	var hurdles: Array[Rect2] = []
	hurdles.append_array(level.wood)
	for rect in level.ground:
		if rect.end.y == UPPER_TOP:
			hurdles.append(rect)
	check_eq(hurdles.size(), 2, "a wooden hurdle and a stone one")
	for block in hurdles:
		check(block.size.y < move.jump_height, "%.0f px is under a jump" % block.size.y)
		check(y > block.position.y and y < block.end.y, "a standing throw at %.0f meets it" % y)


func test_the_switch_is_where_a_standing_throw_lands() -> void:
	var level := _level()
	var switch := level.thing("S")
	check(switch != null and switch.kind == "switch", "S is the switch")
	var y := _throw_y(YARD_TOP)
	check(
		y > switch.rect.position.y and y < switch.rect.end.y,
		"a throw at %.0f goes into the switch's %.0f to %.0f" % [y, switch.rect.position.y, switch.rect.end.y]
	)
	check_eq(switch.rect.position.x, _yard(level).end.x, "flush with the face across the yard")
	check_eq(switch.rect.end.y, YARD_TOP, "at the foot of it")
	check_eq(String(switch.params.get("opens", "")), "G", "and it opens the gate")


## The playtest (2026-10-06): behind you after the drop, nobody found it.
func test_the_switch_is_ahead_of_you_and_the_gate_in_view() -> void:
	var level := _level()
	var yard := _yard(level)
	check(level.thing("S").rect.position.x >= yard.end.x, "you land in the yard facing it")
	var screen: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	check(
		level.thing("G").rect.end.x - yard.position.x < screen,
		"the gate is on the same screen as the yard you throw from"
	)


func test_the_switch_is_inside_throwing_range_of_the_yard() -> void:
	var sword: SwordConfig = load(SWORD)
	var yard := _yard(_level())
	check(yard.size.x < sword.max_range, "from anywhere in the yard, the switch is in range")


func test_the_gate_is_the_only_way_on() -> void:
	var move: MovementConfig = load(MOVE)
	var level := _level()
	var gate := level.thing("G").rect
	check(gate.size.y > move.jump_height, "too tall to jump")
	check_eq(gate.end.y, UPPER_TOP, "down to the level above the yard")
	var over := false
	for wall in level.walls:
		if wall.position.x == gate.position.x and wall.end.y == gate.position.y and wall.position.y == 0.0:
			over = true
	check(over, "with stone over it to the top")


func test_the_yard_has_a_way_back_up_and_on() -> void:
	var level := _level()
	var yard := _yard(level)
	var ends := 0
	for ladder in level.ladders:
		if is_equal_approx(ladder.position.y, UPPER_TOP) and is_equal_approx(ladder.end.y, YARD_TOP):
			if is_equal_approx(ladder.position.x, yard.position.x) or is_equal_approx(ladder.end.x, yard.end.x):
				ends += 1
	check_eq(ends, 2, "a ladder at the drop and one up the far face")


func test_the_grate_is_scenery_above_the_floor() -> void:
	check(Act1Bailey.GRATE.end.y < UPPER_TOP, "it ends above where you walk")
	check(Act1Bailey.GRATE.encloses(Act1Bailey.dragon_rect()), "the dragon fits inside it")
	check(Act1Bailey.GRATE.end.x < _yard(_level()).position.x, "over the quiet stretch, not over the yard and its switch")
