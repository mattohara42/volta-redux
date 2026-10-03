## Act 1's second room, as arithmetic. Its claims: the wall is climbed and never
## jumped, the gatehouse can only be passed with a sword, the step down into it
## is where a throw lands on top of the scorpion, and the breach can be crossed
## on the slabs. Every number it rests on lives in `config/`.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const ENEMIES := "res://config/enemies.tres"
const SWORD := "res://config/sword.tres"


func _level_reach() -> float:
	var move: MovementConfig = load(MOVE)
	return Motion.jump_reach(
		move.jump_height, move.time_to_apex, move.fall_gravity_multiplier, move.max_run_speed, 0.0
	)


func test_the_wall_is_one_storey_and_climbed() -> void:
	var move: MovementConfig = load(MOVE)
	var world: WorldConfig = load(WORLD)
	check_eq(Bench.FLOOR_TOP - Act1Wall.WALK_TOP, world.tier_height, "the wall walk is one tier up")
	check(world.tier_height > move.jump_height, "too tall to jump, so the ladder is the way")
	check_eq(Act1Wall.LADDER_X + Bench.LADDER_WIDTH, Act1Wall.WALL_X, "the ladder stands against the wall")


func test_the_passage_fits_the_hero_but_not_a_jump_over_the_scorpion() -> void:
	var world: WorldConfig = load(WORLD)
	var headroom := Act1Wall.LOWER_TOP - Act1Wall.PASSAGE.end.y
	check(headroom > world.hero_height, "%.0f px of headroom fits a %.0f px hero" % [headroom, world.hero_height])
	check(
		headroom < world.hero_height + Act1Wall.SCORPION_SIZE.y,
		"and is less than it takes to jump a scorpion"
	)


func test_the_patrol_stays_inside_the_passage() -> void:
	var half := Act1Wall.SCORPION_SIZE.x * 0.5
	check(Act1Wall.GUARD_HOME_X - half >= Act1Wall.PASSAGE.position.x, "it never comes out to the step")
	check(
		Act1Wall.GUARD_HOME_X + Act1Wall.GUARD_RANGE + half <= Act1Wall.PASSAGE.end.x,
		"or out the far end"
	)


## The lesson. Standing on the step's edge, the sword flies at the hero's middle,
## which is inside the top band of the scorpion's body: through, either way it
## faces. Down on the passage floor the same throw meets its face.
func test_a_throw_from_the_step_lands_on_top_of_the_scorpion() -> void:
	var world: WorldConfig = load(WORLD)
	var enemies: EnemyConfig = load(ENEMIES)
	var sword: SwordConfig = load(SWORD)
	var half_height := Act1Wall.SCORPION_SIZE.y * 0.5
	var scorpion_y := Act1Wall.LOWER_TOP - half_height
	var from_step := Act1Wall.WALK_TOP - world.hero_height * 0.5 - scorpion_y
	var from_floor := Act1Wall.LOWER_TOP - world.hero_height * 0.5 - scorpion_y
	check(from_step > -half_height, "the throw from the step still hits the body (%.0f)" % from_step)
	for facing in [-1.0, 1.0]:
		check(
			ScorpionPatrol.is_vulnerable_to(
				Vector2(-10.0, from_step), facing, half_height, enemies.scorpion_armor_top_fraction
			),
			"from the step it gets through facing %.0f" % facing
		)
	check(
		not ScorpionPatrol.is_vulnerable_to(
			Vector2(-10.0, from_floor), -1.0, half_height, enemies.scorpion_armor_top_fraction
		),
		"and from the passage floor its face still stops it"
	)
	var edge := Act1Wall.STEP_X - world.hero_width * 0.5
	var nearest := Act1Wall.GUARD_HOME_X - Act1Wall.SCORPION_SIZE.x * 0.5
	check(edge + sword.max_range >= nearest, "a throw from the edge reaches its nearest point")


func test_the_breach_can_be_crossed_on_the_slabs() -> void:
	var reach := _level_reach()
	var from := Act1Wall.BREACH_X
	for x in Act1Wall.SLABS:
		check(x - from < reach, "a gap of %.0f px is inside a %.0f px jump" % [x - from, reach])
		from = x + Act1Wall.SLAB_WIDTH
	check(Act1Wall.BREACH_END - from < reach, "and so is the last one, %.0f px" % (Act1Wall.BREACH_END - from))


func test_a_slab_is_one_row_of_its_art() -> void:
	var slab := Act1Wall.slab(Act1Wall.SLABS[0])
	check_eq(slab.position.y, Act1Wall.LOWER_TOP, "its top is level with the walk")
	check_eq(slab.size.y, float(Act1Wall.CRUMBLE_ART.get_height()), "and it is as deep as the art")


func test_the_checkpoint_sits_between_the_gatehouse_and_the_breach() -> void:
	var move: MovementConfig = load(MOVE)
	check(Act1Wall.CHECKPOINT_X > Act1Wall.PASSAGE.end.x, "lit after the gatehouse")
	check(
		Act1Wall.BREACH_X - Act1Wall.CHECKPOINT_X >= Motion.run_up_distance(move.max_run_speed, move.ground_accel),
		"with room to get up to speed before the first jump"
	)
