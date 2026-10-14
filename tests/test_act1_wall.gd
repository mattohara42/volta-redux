## Act 1's second level, the outer wall as rebuilt from its beat sheet
## (`levels/act1_wall.beats`, N3), as arithmetic. Slice 1, beats 1 to 5: the
## culvert's mouth, the first ladder and its bat, the postern's sill over a
## sleeping skeleton, the guardroom with a step at each end, and the tower
## stair. Every number it rests on lives in `config/` or the level file.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const ENEMIES := "res://config/enemies.tres"
const SWORD := "res://config/sword.tres"

## The floors, as the map draws them: floor 1 is the ground at the wall's
## foot, floor 2 the postern and guardroom, floor 4 the wall walk.
const FLOOR_1: float = 704.0
const FLOOR_2: float = 608.0
const FLOOR_4: float = 320.0


func _level() -> LevelGrid.Level:
	return GridRoom.read(Act1Wall.LEVEL)


func _throw_y(surface: float) -> float:
	var world: WorldConfig = load(WORLD)
	return surface - world.hero_height * 0.5


## A scorpion's patrol as a span of x its body covers: from its home, out
## `range` to the right and back.
func _patrol(t: LevelGrid.Thing) -> Vector2:
	var home := t.rect.get_center().x
	var half := GridRoom.SCORPION_SIZE.x * 0.5
	return Vector2(home - half, home + t.number("range", 0.0) + half)


## The bat's box: the rect its anchor fills, which is how far it roams.
func _bat_box(anchor: String) -> Rect2:
	return _level().thing(anchor).rect


func test_the_level_reads_cleanly() -> void:
	var level := _level()
	check_eq(level.errors, [] as Array[String], "no errors in the level file")
	check(level.has_start, "the hero has somewhere to start")
	check_eq(level.start.y, FLOOR_1, "at the culvert's mouth, on floor 1")
	check(level.exit.size != Vector2.ZERO, "and an exit")


func test_the_first_ladder_climbs_a_tier_past_a_bat_on_the_throw_line() -> void:
	var world: WorldConfig = load(WORLD)
	var level := _level()
	var first := Rect2()
	for ladder in level.ladders:
		if is_equal_approx(ladder.end.y, FLOOR_1) and (first.size == Vector2.ZERO or ladder.position.x < first.position.x):
			first = ladder
	check_eq(first.size.y, world.tier_height, "a tier tall")
	check_eq(first.position.y, FLOOR_2, "up to floor 2")
	var box := _bat_box("O")
	var line := _throw_y(FLOOR_1)
	check(box.position.y < line and box.end.y > line, "the bat's box crosses a throw from the floor")
	check(box.end.x <= first.position.x, "and it is between the start and the ladder, so it is faced first")


## Beat 3. The passage fits the hero but not a jump over the skeleton, the
## skeleton's patrol stays under the roof, and from the sill a throw lands in
## its top whichever way it faces.
func test_the_postern_sill_lands_a_throw_in_the_skeletons_top() -> void:
	var world: WorldConfig = load(WORLD)
	var enemies: EnemyConfig = load(ENEMIES)
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var skeleton := level.thing("K")
	check(skeleton.flag("dormant"), "asleep")
	var patrol := _patrol(skeleton)
	var roof := Rect2()
	for solid in level.solids():
		if solid.end.y < FLOOR_2 and solid.position.x <= patrol.x and solid.end.x >= patrol.y and solid.end.y > roof.end.y:
			roof = solid
	var headroom := FLOOR_2 - roof.end.y
	check(headroom > world.hero_height, "%.0f px of headroom fits a %.0f px hero" % [headroom, world.hero_height])
	check(headroom < world.hero_height + GridRoom.SCORPION_SIZE.y, "and is less than it takes to jump it")
	var sill_cells := level.thing("T")
	var sill := Act1Wall.sill_rect(sill_cells.rect, sill_cells.number("height", 0.0))
	check(sill.size.y > 5.0 and sill.size.y < 16.0, "the sill is a %.0f px step" % sill.size.y)
	check_eq(sill.end.y, FLOOR_2, "on floor 2")
	check(sill.end.x < roof.position.x, "outside the passage, under open sky")
	var half_height := GridRoom.SCORPION_SIZE.y * 0.5
	var from_sill := sill.position.y - world.hero_height * 0.5 - (FLOOR_2 - half_height)
	for facing in [-1.0, 1.0]:
		check(
			ScorpionPatrol.is_vulnerable_to(
				Vector2(-10.0, from_sill), facing, half_height, enemies.scorpion_armor_top_fraction
			),
			"from the sill a throw gets through facing %.0f" % facing
		)
	var edge := sill.end.x - world.hero_width * 0.5
	check(edge + sword.max_range >= patrol.x, "a throw from the sill's edge reaches it")
	var gap := skeleton.rect.get_center().x - edge
	check(gap > enemies.dormant_wake_range, "it sleeps through you standing on the sill (%.0f px)" % gap)


## Beat 4. Two guards awake, neither reaching a step, each in range of a
## throw from the step on its side; a chest at the door in and a brazier at
## the door out.
func test_the_guardroom_has_a_step_in_range_of_each_guard() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var near := Act1Wall.sill_rect(level.thing("J").rect, level.thing("J").number("height", 0.0))
	var far := Act1Wall.sill_rect(level.thing("L").rect, level.thing("L").number("height", 0.0))
	var first := _patrol(level.thing("A"))
	var second := _patrol(level.thing("M"))
	check(not level.thing("A").flag("dormant") and not level.thing("M").flag("dormant"), "both awake")
	check(first.x > near.end.x and second.y < far.position.x, "neither guard reaches a step")
	check(near.end.x - world.hero_width * 0.5 + sword.max_range >= first.x, "the near step reaches the first")
	check(far.position.x + world.hero_width * 0.5 - sword.max_range <= second.y, "the far step reaches the second")
	var chest := false
	for base in level.chests:
		chest = chest or (is_equal_approx(base.y, FLOOR_2) and base.x < near.position.x)
	check(chest, "a chest before the near step")
	var brazier := false
	for base in level.braziers:
		brazier = brazier or (is_equal_approx(base.y, FLOOR_2) and base.x > far.end.x)
	check(brazier, "a brazier past the far step")


## Beat 5. Three ladders a tier each from floor 2 to floor 4, switching sides,
## with a bat on the throw line of the floor or landing at each one's foot.
func test_the_tower_stair_switches_sides_past_a_bat_a_storey() -> void:
	var world: WorldConfig = load(WORLD)
	var level := _level()
	var stair: Array[Rect2] = []
	for ladder in level.ladders:
		if ladder.position.y >= FLOOR_4 - 0.5 and ladder.end.y <= FLOOR_2 + 0.5 and ladder.position.x > level.thing("L").rect.end.x:
			stair.append(ladder)
	stair.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.end.y > b.end.y)
	check_eq(stair.size(), 3, "three ladders")
	if stair.size() != 3:
		return
	check_eq(stair[0].end.y, FLOOR_2, "from floor 2")
	check_eq(stair[2].position.y, FLOOR_4, "to floor 4")
	for i in stair.size():
		check_eq(stair[i].size.y, world.tier_height, "ladder %d is a tier" % i)
	check(stair[0].position.x > stair[1].position.x and stair[2].position.x > stair[1].position.x, "right, left, right")
	var bats := ["P", "Q", "R"]
	for i in stair.size():
		var box := _bat_box(bats[i])
		var line := _throw_y(stair[i].end.y)
		check(box.position.y < line and box.end.y > line, "bat %s crosses the throw line at ladder %d's foot" % [bats[i], i])
