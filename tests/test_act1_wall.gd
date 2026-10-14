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


const LIP: float = 640.0
const FAR_TOP: float = 576.0
const DITCH_FLOOR: float = 688.0


## Beat 13. The ditch, kept from the old wall: crossed only on your own sword.
func test_the_ditch_needs_the_sword() -> void:
	var level := _level()
	var hoarding := Rect2()
	for wood in level.wood:
		if is_equal_approx(wood.position.y, FAR_TOP):
			hoarding = wood
	check(hoarding.size != Vector2.ZERO, "the far side is faced with wood")
	var near := 0.0
	for solid in level.solids():
		if is_equal_approx(solid.position.y, LIP) and solid.end.x <= hoarding.position.x:
			near = maxf(near, solid.end.x)
	DitchChecks.run(self, "Act1Wall", near, LIP, FAR_TOP, hoarding, DITCH_FLOOR)


## Beat 9. The caged dragon over a quiet stretch of the bailey: above where
## you walk, big enough for the dragon, nothing hunting under it, and a
## brazier at the way in.
func test_the_cage_is_scenery_over_a_quiet_bailey() -> void:
	var level := _level()
	var grate := level.thing("D").rect
	check(grate.end.y < FLOOR_1, "it ends above the bailey floor")
	check(grate.encloses(Act1Wall.dragon_rect(grate)), "the dragon fits inside it")
	check(grate.end.x < level.thing("1").rect.position.x, "before the yard and its switch")
	for t in level.of_kind("scorpion") + level.of_kind("bat"):
		check(absf(t.rect.get_center().x - grate.get_center().x) > grate.size.x, "nothing hunts under the cage (%s)" % t.anchor)
	var lit := false
	for base in level.braziers:
		lit = lit or (is_equal_approx(base.y, FLOOR_1) and base.x < grate.position.x and base.x > level.thing("I").rect.end.x)
	check(lit, "a brazier where the bailey begins")


## Beat 10. The yard's switch is the far face on the floor's throw line; its
## ladder up stands clear of a sword held in it; the gate is up on floor 2
## with stone over it; two bats round the ladder past it.
func test_the_bailey_yard_switch_opens_the_gate_above() -> void:
	var world: WorldConfig = load(WORLD)
	var level := _level()
	var switch := level.thing("1")
	var gate := level.thing("2").rect
	check_eq(String(switch.params.get("opens", "")), "2", "it opens the gate")
	var line := _throw_y(FLOOR_1)
	check(switch.rect.position.y < line and switch.rect.end.y > line, "on the yard's throw line")
	check_eq(gate.end.y, FLOOR_2, "the gate is on floor 2")
	var over := false
	for solid in level.solids():
		if solid.position.x <= gate.position.x and solid.end.x >= gate.end.x and is_equal_approx(solid.end.y, gate.position.y):
			over = true
	check(over, "with stone over it")
	var up := Rect2()
	for ladder in level.ladders:
		if is_equal_approx(ladder.end.y, FLOOR_1) and is_equal_approx(ladder.position.y, FLOOR_2) and ladder.end.x <= switch.rect.position.x:
			up = ladder
	check(up.size != Vector2.ZERO, "a ladder up from the yard")
	check(switch.rect.position.x - up.end.x >= world.sword_length, "clear of a sword held in the switch")
	var bats := 0
	for anchor in ["3", "4"]:
		var box := _bat_box(anchor)
		if box.position.x > gate.end.x:
			bats += 1
	check_eq(bats, 2, "two bats past the gate")


## Beat 11. The barbican stair climbs from floor 1 to floor 3 with nothing on
## it but a roost asleep beside it: one low, which comes down to the floor's
## throw line, one high, and each wakes as the climb passes it.
func test_the_barbican_roost_sleeps_beside_the_stair() -> void:
	var enemies: EnemyConfig = load(ENEMIES)
	var world: WorldConfig = load(WORLD)
	var level := _level()
	var stair := Rect2()
	for ladder in level.ladders:
		if is_equal_approx(ladder.end.y, FLOOR_1) and is_equal_approx(ladder.position.y, FLOOR_3) and ladder.position.x > level.thing("2").rect.end.x and ladder.position.x < level.thing("7").rect.position.x:
			stair = ladder
	check_eq(stair.size.y, FLOOR_1 - FLOOR_3, "a stair from floor 1 to floor 3")
	var middle := stair.get_center().x
	var low := level.thing("5")
	var high := level.thing("6")
	for t in [low, high]:
		check(t.flag("dormant"), "bat %s asleep" % t.anchor)
		check(absf(t.rect.get_center().x - middle) < enemies.dormant_wake_range, "bat %s wakes as the climb passes it" % t.anchor)
	check(low.rect.get_center().y > high.rect.get_center().y, "one low, one high")
	var line := _throw_y(FLOOR_1)
	check(low.rect.position.y < line and low.rect.end.y > line, "the low one comes down to the floor's throw line")
	var asleep_at := low.rect.get_center()
	var from_floor := Vector2(middle, FLOOR_1 - world.hero_height * 0.5).distance_to(asleep_at)
	check(from_floor > enemies.dormant_wake_range, "it sleeps through you standing at the foot (%.0f px)" % from_floor)


## Beat 12. From the barbican's top, planks that hold once out to a dead end
## closed by a merlon too tall to jump; under them nothing but air down to the
## ditch's lip. The way back from the lip is a drop too deep to climb.
func test_the_bailey_wall_planks_are_the_way_down() -> void:
	var move: MovementConfig = load(MOVE)
	var level := _level()
	var planks := level.thing("7")
	check_eq(planks.number("holds", 0.0), 1.0, "planks that hold once")
	check_eq(planks.rect.position.y, FLOOR_3, "on floor 3")
	var merlon := Rect2()
	for solid in level.solids():
		if solid.position.x >= planks.rect.end.x and solid.end.y <= FLOOR_3 + 0.5 and solid.position.y < FLOOR_3 and solid.position.x < planks.rect.end.x + 64.0:
			merlon = solid
	check(FLOOR_3 - merlon.position.y > move.jump_height, "a merlon at the dead end taller than a jump")
	var below := LIP
	for solid in level.solids():
		if solid.position.x < planks.rect.end.x and solid.end.x > planks.rect.position.x and solid.position.y > FLOOR_3 and solid.position.y < LIP:
			below = minf(below, solid.position.y)
	check_eq(below, LIP, "nothing between the planks and the lip")
	check(FLOOR_1 - LIP > move.jump_height, "the lip is a drop too deep to climb back from the courtyard")


const YARD: float = 704.0
const PLINTH: float = 672.0


## Beat 14. A step over a sleeping skeleton, as at 3, with an eye between
## them that starts above the step's throw line and drifts down across it, out
## of reach of the step. A ladder from the ditch's brazier is the way in and
## back.
func test_the_gallery_eye_drifts_onto_the_steps_line() -> void:
	var world: WorldConfig = load(WORLD)
	var enemies: EnemyConfig = load(ENEMIES)
	var level := _level()
	var step := Act1Wall.sill_rect(level.thing("a").rect, level.thing("a").number("height", 0.0))
	check_eq(step.end.y, FLOOR_3, "the step is on floor 3")
	var skeleton := level.thing("b")
	check(skeleton.flag("dormant"), "the skeleton sleeps")
	var line := step.position.y - world.hero_height * 0.5
	var half_height := GridRoom.SCORPION_SIZE.y * 0.5
	for facing in [-1.0, 1.0]:
		check(
			ScorpionPatrol.is_vulnerable_to(
				Vector2(-10.0, line - (FLOOR_3 - half_height)), facing, half_height, enemies.scorpion_armor_top_fraction
			),
			"from the step a throw gets through facing %.0f" % facing
		)
	var eye := level.thing("c").rect
	check(eye.position.x > step.end.x and eye.end.x < skeleton.rect.position.x, "the eye is between the step and the skeleton")
	check(eye.get_center().y + GridRoom.EYEBALL_SIZE.y * 0.5 < line, "it starts above the step's line")
	check(eye.end.y > line, "and can drift down across it")
	check(eye.position.x - GridRoom.EYEBALL_SIZE.x * 0.5 > step.end.x, "without reaching the step")
	var up := false
	for ladder in level.ladders:
		up = up or (is_equal_approx(ladder.position.y, FLOOR_3) and is_equal_approx(ladder.end.y, FAR_TOP) and ladder.end.x <= step.position.x)
	check(up, "a ladder up from the ditch's far side")


## Beat 15. Two switches hold the inner gate: the low one on the floor's throw
## line, the high one on the line thrown from a sword stuck in the low one.
## Past the gate a brazier, and a ladder up to a roof that drops you back.
func test_the_inner_gate_needs_the_second_switch_from_the_first() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var low := level.thing("d")
	var high := level.thing("e")
	check_eq(String(low.params.get("opens", "")), "f", "the low switch opens the inner gate")
	check_eq(String(high.params.get("opens", "")), "f", "and so does the high one")
	var floor_line := _throw_y(FLOOR_3)
	check(low.rect.position.y < floor_line and low.rect.end.y > floor_line, "the low one is on the floor's line")
	check(not (high.rect.position.y < floor_line and high.rect.end.y > floor_line), "the high one is not")
	var ledge_top := floor_line - Sword.LEDGE_THICKNESS * 0.5
	var ledge_line := ledge_top - world.hero_height * 0.5
	check(high.rect.position.y < ledge_line and high.rect.end.y > ledge_line, "it is on the line from a sword in the low one")
	check(high.rect.position.x - low.rect.position.x <= sword.max_range, "within a throw of it")
	var gate := level.thing("f").rect
	check(gate.position.x > high.rect.end.x, "the gate is past both")
	var lit := false
	for base in level.braziers:
		lit = lit or (is_equal_approx(base.y, FLOOR_3) and base.x > gate.end.x)
	check(lit, "a brazier past the gate")
	var roof := false
	for ladder in level.ladders:
		roof = roof or (ladder.position.x > gate.end.x and ladder.position.y < gate.position.y and is_equal_approx(ladder.end.y, FLOOR_3))
	check(roof, "a ladder up from past the gate to the roof")


## Beat 16. Planks that hold once over the gate yard, ending on stone, with a
## scorpion patrolling the yard floor under them.
func test_the_plinth_approach_planks_hang_over_the_yard_scorpion() -> void:
	var level := _level()
	var planks := level.thing("j")
	check_eq(planks.number("holds", 0.0), 1.0, "planks that hold once")
	check_eq(planks.rect.position.y, FLOOR_3, "on floor 3")
	var ends_on_stone := false
	for solid in level.solids():
		ends_on_stone = ends_on_stone or (is_equal_approx(solid.position.y, FLOOR_3) and is_equal_approx(solid.position.x, planks.rect.end.x))
	check(ends_on_stone, "ending on stone, so coming back is a second landing")
	var patrol := _patrol(level.thing("k"))
	check(patrol.x < planks.rect.end.x and patrol.y > planks.rect.position.x, "the yard scorpion walks under them")
	check_eq(level.thing("k").rect.end.y, YARD, "on the yard floor")


## Beat 17. The plinth's face is the switch, on the yard's throw line; a step
## on a pillar in the yard puts a throw in the top of the scorpion guarding
## the gate; both are inside a jump; the gate stands on the plinth with the
## castle over it, and the exit is past it.
func test_the_gate_yard_combines_the_sill_and_the_switch() -> void:
	var move: MovementConfig = load(MOVE)
	var world: WorldConfig = load(WORLD)
	var enemies: EnemyConfig = load(ENEMIES)
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var switch := level.thing("m")
	check_eq(String(switch.params.get("opens", "")), "n", "the plinth's face opens the castle gate")
	var line := _throw_y(YARD)
	check(switch.rect.position.y < line and switch.rect.end.y > line, "on the yard's throw line")
	check(YARD - PLINTH < move.jump_height, "the plinth is inside a jump")
	var step := Act1Wall.sill_rect(level.thing("o").rect, level.thing("o").number("height", 0.0))
	check(YARD - step.position.y < move.jump_height, "and so is the step on its pillar")
	var guard := level.thing("l")
	check_eq(guard.rect.end.y, PLINTH, "the guard is on the plinth")
	var half_height := GridRoom.SCORPION_SIZE.y * 0.5
	var from_step := step.position.y - world.hero_height * 0.5 - (PLINTH - half_height)
	for facing in [-1.0, 1.0]:
		check(
			ScorpionPatrol.is_vulnerable_to(
				Vector2(-10.0, from_step), facing, half_height, enemies.scorpion_armor_top_fraction
			),
			"from the step a throw gets into its top facing %.0f" % facing
		)
	check(step.end.x - world.hero_width * 0.5 + sword.max_range >= _patrol(guard).y, "the whole of its patrol is in reach")
	var gate := level.thing("n").rect
	check_eq(gate.end.y, PLINTH, "the gate stands on the plinth")
	check(gate.position.x > _patrol(guard).y, "past the guard's patrol")
	check(level.exit.position.x > gate.end.x, "and the exit is past the gate")
