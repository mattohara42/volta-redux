## Act 2's tide room, as arithmetic. Its claims: the refuges and banks stand
## clear of a high tide and can be jumped onto from the passage, the lava sits
## under the floor when low, every stretch can be run inside the window one low
## tide gives (from a respawn too), and the whole passage cannot, so the refuges
## are the route. Every number comes from `config/`.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const HAZARDS := "res://config/hazards.tres"


func _window() -> float:
	var h: HazardConfig = load(HAZARDS)
	return LavaTide.dry_window(h.tide_low_time, h.tide_rise_time, Act2Tide.LOW_Y, Act2Tide.HIGH_Y, Bench.FLOOR_TOP)


func _run(distance: float) -> float:
	var move: MovementConfig = load(MOVE)
	return Motion.run_time(distance, move.max_run_speed, move.ground_accel)


func test_the_raised_rock_stands_clear_of_a_high_tide_and_can_be_jumped_onto() -> void:
	var move: MovementConfig = load(MOVE)
	check(Act2Tide.RAISED_TOP < Act2Tide.HIGH_Y, "a high tide stays below the refuges and banks")
	check(Bench.FLOOR_TOP - Act2Tide.RAISED_TOP < move.jump_height, "and they are a jump up from the passage")


func test_a_low_tide_is_under_the_floor_and_a_high_one_over_it() -> void:
	var world: WorldConfig = load(WORLD)
	check(Act2Tide.LOW_Y > Bench.FLOOR_TOP, "low, the passage is dry")
	check(Act2Tide.HIGH_Y < Bench.FLOOR_TOP and Act2Tide.HIGH_Y > Bench.FLOOR_TOP - world.hero_height, "high, it covers a hero's feet")


func test_every_stretch_can_be_run_inside_one_low_tide() -> void:
	var world: WorldConfig = load(WORLD)
	for stretch in Act2Tide.stretches():
		var t := _run(stretch.y - stretch.x + world.hero_width)
		check(t < _window(), "%.0f px takes %.2f s against a %.2f s window" % [stretch.y - stretch.x, t, _window()])


func test_a_respawn_at_either_brazier_makes_its_next_stretch() -> void:
	var world: WorldConfig = load(WORLD)
	var first := Act2Tide.stretches()[0]
	check(_run(first.y - Act2Tide.START_BRAZIER_X + world.hero_width) < _window(), "from the start brazier through the first stretch")
	var last := Act2Tide.stretches()[2]
	check(_run(last.y - Act2Tide.MID_BRAZIER_X + world.hero_width) < _window(), "from the mid brazier through the last")


func test_the_whole_passage_cannot_be_run_in_one_low_tide() -> void:
	check(_run(Act2Tide.EXIT_START - Act2Tide.ENTRY_END) > _window(), "so the refuges are the route, not decoration")
