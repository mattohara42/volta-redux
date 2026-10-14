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
		var inside := ladder.position.x > level.thing("L").rect.end.x and ladder.end.x <= level.thing("I").rect.position.x
		if inside and ladder.position.y >= FLOOR_4 - 0.5 and ladder.end.y <= FLOOR_2 + 0.5:
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


const FLOOR_3: float = 416.0
const FLOOR_5: float = 224.0


## Beat 6. A ladder a tier up from the walk to planks that hold once, out to
## a lookout; under the planks nothing but air down to the walk, so the drop
## is a storey onto floor you already stood on.
func test_the_lookout_planks_hold_once_over_the_walk() -> void:
	var world: WorldConfig = load(WORLD)
	var level := _level()
	var planks := level.thing("U")
	check_eq(planks.kind, "slab", "planks")
	check_eq(planks.number("holds", 0.0), 1.0, "that hold once")
	check_eq(planks.rect.position.y, FLOOR_5, "on floor 5")
	var up := false
	for ladder in level.ladders:
		up = up or (is_equal_approx(ladder.position.y, FLOOR_5) and is_equal_approx(ladder.end.y, FLOOR_4) and ladder.end.x <= planks.rect.position.x)
	check(up, "a ladder from the walk up to them")
	check_eq(FLOOR_4 - FLOOR_5, world.tier_height, "a storey above the walk")
	var below := planks.rect.end.y
	for solid in level.solids():
		if solid.position.x < planks.rect.end.x and solid.end.x > planks.rect.position.x and solid.position.y >= planks.rect.end.y and solid.position.y < FLOOR_4:
			below = minf(below, solid.position.y)
	check_eq(below, planks.rect.end.y, "nothing between the planks and the walk")


## Beat 7. The switch is in the gatehouse face across the gap, on the line a
## throw from the walk takes and inside its reach; the gate it opens is in the
## passage under it, on floor 3, with room for the hero.
func test_the_gatehouse_switch_is_thrown_at_from_the_walk() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var switch := level.thing("S")
	check_eq(String(switch.params.get("opens", "")), "G", "it opens the gatehouse gate")
	var line := _throw_y(FLOOR_4)
	check(switch.rect.position.y < line and switch.rect.end.y > line, "the throw from the walk meets it")
	var walk_end := 0.0
	for solid in level.solids():
		if is_equal_approx(solid.position.y, FLOOR_4) and solid.end.x <= switch.rect.position.x:
			walk_end = maxf(walk_end, solid.end.x)
	var gap := switch.rect.position.x - walk_end
	check(gap > world.hero_width * 2.0, "across a gap (%.0f px)" % gap)
	check(gap + world.hero_width * 0.5 <= sword.max_range, "inside a throw's reach")
	var gate := level.thing("G").rect
	check_eq(gate.end.y, FLOOR_3, "the gate stands on floor 3")
	check(gate.size.y > world.hero_height, "and fills a passage the hero fits")
	check(gate.position.x > switch.rect.position.x, "past the switch, so it is dropped to")


## Beat 7a. Two bats over the high hoarding's throw line, planks that hold
## once, and a fourth sword at the far end.
func test_the_high_hoarding_holds_a_fourth_sword() -> void:
	var level := _level()
	var planks := level.thing("V")
	check_eq(planks.number("holds", 0.0), 1.0, "planks that hold once")
	check_eq(planks.rect.position.y, FLOOR_5, "on floor 5")
	check(level.thing("X").rect.position.x > planks.rect.end.x, "the sword past them")
	var line := _throw_y(FLOOR_5)
	for anchor in ["Z", "N"]:
		var box := _bat_box(anchor)
		check(box.position.y < line and box.end.y > line, "bat %s crosses the throw line" % anchor)


## Beat 8. A wooden stanchion, then planks that hold once over spikes, then
## the chest. From the chest's ledge a throw meets the stanchion's face within
## reach, so a sword can be the ledge home.
func test_the_hoarding_chest_is_reached_over_planks_that_hold_once() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var planks := level.thing("Y")
	check_eq(planks.number("holds", 0.0), 1.0, "planks that hold once")
	check_eq(planks.rect.position.y, FLOOR_3, "on floor 3")
	var spiked := 0.0
	for bed in level.spikes:
		if bed.position.x >= planks.rect.position.x and bed.end.x <= planks.rect.end.x:
			spiked += bed.size.x
	check_eq(spiked, planks.rect.size.x, "over spikes their whole width")
	var chest := Vector2.ZERO
	for base in level.chests:
		if is_equal_approx(base.y, FLOOR_3) and base.x > planks.rect.end.x:
			chest = base
	check(chest != Vector2.ZERO, "the chest beyond them")
	var line := _throw_y(FLOOR_3)
	var post := Rect2()
	for wood in level.wood:
		if wood.end.x <= planks.rect.position.x and wood.position.y < line and wood.end.y > line:
			post = wood
	check(post.size != Vector2.ZERO, "a wooden stanchion before them, on the throw line")
	var from := planks.rect.end.x + world.hero_width * 0.5
	check(from - post.end.x <= sword.max_range, "a throw from the chest's ledge reaches it")


## The loop back to the guardroom's brazier: a portcullis into the tower's
## foot whose switch is on the corridor side, on its floor's throw line.
func test_the_loop_opens_only_from_the_corridor() -> void:
	var level := _level()
	var switch := level.thing("F")
	var gate := level.thing("I").rect
	check_eq(String(switch.params.get("opens", "")), "I", "the switch opens the tower's gate")
	check(switch.rect.position.x > gate.end.x, "from the corridor side")
	var line := _throw_y(FLOOR_2)
	check(switch.rect.position.y < line and switch.rect.end.y > line, "on the corridor's throw line")
