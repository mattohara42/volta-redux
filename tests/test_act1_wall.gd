## Act 1's second level (`levels/act1_wall.level`), as arithmetic. It folds in
## the claims the wall, bailey and gate rooms made: the wall is climbed and
## never jumped; the gatehouse is passed with a sword, and its sill is where a
## throw lands on top of the guard; the breach and the high road can both be
## crossed; wood holds a throw and stone does too, at hurdle height; each
## switch is ahead of the yard it is thrown from, with its gate in view; the
## ditch cannot be crossed without standing on your own sword. Every number it
## rests on lives in `config/` or the level file.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const ENEMIES := "res://config/enemies.tres"
const SWORD := "res://config/sword.tres"

## The surfaces the sections stand on, as the map draws them.
const BANK_TOP: float = 704.0
const WALK_TOP: float = 416.0
const BAILEY_TOP: float = 512.0
const YARD_TOP: float = 576.0
const FAR_TOP: float = 448.0
const PIT_TOP: float = 560.0


func _level() -> LevelGrid.Level:
	return GridRoom.read(Act1Wall.LEVEL)


func _throw_y(surface: float) -> float:
	var world: WorldConfig = load(WORLD)
	return surface - world.hero_height * 0.5


func _flat_reach() -> float:
	var move: MovementConfig = load(MOVE)
	return Motion.jump_reach(
		move.jump_height, move.time_to_apex, move.fall_gravity_multiplier, move.max_run_speed, 0.0
	)


## The solid whose top is `top` and which covers `x`, or an empty rect.
func _surface(level: LevelGrid.Level, top: float, x: float) -> Rect2:
	for solid in level.solids():
		if is_equal_approx(solid.position.y, top) and x >= solid.position.x and x < solid.end.x:
			return solid
	return Rect2()


## The open stretch of floor at `top` round `x`: where the solids at that
## height (and anything in `also`) stop either side of it.
func _gap(level: LevelGrid.Level, top: float, x: float, also: Array[Rect2] = []) -> Rect2:
	var left := 0.0
	var right := level.size.x
	for solid in level.solids() + also:
		if solid.position.y < top + 0.5 and solid.end.y > top - 0.5:
			if solid.end.x <= x:
				left = maxf(left, solid.end.x)
			elif solid.position.x > x:
				right = minf(right, solid.position.x)
	return Rect2(left, top, right - left, 0.0)


func test_the_level_reads_cleanly() -> void:
	var level := _level()
	check_eq(level.errors, [] as Array[String], "no errors in the level file")
	check(level.has_start, "the hero has somewhere to start")
	check_eq(level.start.y, BANK_TOP, "on the moat bank")
	check(level.exit.size != Vector2.ZERO, "and an exit")


func test_the_wall_is_three_storeys_each_climbed() -> void:
	var move: MovementConfig = load(MOVE)
	var world: WorldConfig = load(WORLD)
	check_eq(BANK_TOP - WALK_TOP, world.tier_height * 3.0, "the wall walk is three tiers over the bank")
	check(world.tier_height > move.jump_height, "a tier is too tall to jump")
	var storeys := 0
	for ladder in _level().ladders:
		if ladder.end.x <= 34.0 * 16.0 and is_equal_approx(ladder.end.y - ladder.position.y, world.tier_height):
			storeys += 1
	check_eq(storeys, 3, "a ladder a tier tall up each storey's face")


## The gatehouse: the lowest solid over the guard's home.
func _roof(level: LevelGrid.Level) -> Rect2:
	var home := level.thing("A").rect.get_center().x
	var roof := Rect2()
	for solid in level.solids():
		if home >= solid.position.x and home < solid.end.x and solid.end.y < WALK_TOP and solid.end.y > roof.end.y:
			roof = solid
	return roof


## A yard: the open floor before a switch, which is the face across it.
func _yard(level: LevelGrid.Level, switch_anchor: String) -> Rect2:
	var switch := level.thing(switch_anchor).rect
	return _gap(level, YARD_TOP - 1.0, switch.position.x - 1.0, [switch] as Array[Rect2])


func test_the_gatehouse_fits_the_hero_but_not_a_jump_over_its_guard() -> void:
	var world: WorldConfig = load(WORLD)
	var level := _level()
	var guard := level.thing("A")
	var home := guard.rect.get_center().x
	var roof := _roof(level)
	var headroom := WALK_TOP - roof.end.y
	check(headroom > world.hero_height, "%.0f px of headroom fits a %.0f px hero" % [headroom, world.hero_height])
	check(headroom < world.hero_height + GridRoom.SCORPION_SIZE.y, "and is less than it takes to jump the guard")
	var half := GridRoom.SCORPION_SIZE.x * 0.5
	check(home - half >= roof.position.x, "the guard never comes out to the sill")
	check(home + guard.number("range", 0.0) + half <= roof.end.x, "or out the far end")


## The lesson. Standing on the sill, the sword flies at the hero's middle,
## which is inside the top band of the guard's body: through, whichever way
## it faces. Down on the walk the same throw meets its face.
func test_a_throw_from_the_sill_lands_on_top_of_the_guard() -> void:
	var world: WorldConfig = load(WORLD)
	var enemies: EnemyConfig = load(ENEMIES)
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var sill_cells := level.thing("T")
	var sill := Act1Wall.sill_rect(sill_cells.rect, sill_cells.number("height", 0.0))
	check(sill.size.y > 5.0 and sill.size.y < 16.0, "the sill is a %.0f px step, in the 5 to 16 px band" % sill.size.y)
	check_eq(sill.end.y, WALK_TOP, "standing on the walk")
	var half_height := GridRoom.SCORPION_SIZE.y * 0.5
	var guard_y := WALK_TOP - half_height
	var from_sill := sill.position.y - world.hero_height * 0.5 - guard_y
	var from_walk := WALK_TOP - world.hero_height * 0.5 - guard_y
	check(from_sill > -half_height, "the throw from the sill still hits the body (%.0f)" % from_sill)
	for facing in [-1.0, 1.0]:
		check(
			ScorpionPatrol.is_vulnerable_to(
				Vector2(-10.0, from_sill), facing, half_height, enemies.scorpion_armor_top_fraction
			),
			"from the sill it gets through facing %.0f" % facing
		)
	check(
		not ScorpionPatrol.is_vulnerable_to(
			Vector2(-10.0, from_walk), -1.0, half_height, enemies.scorpion_armor_top_fraction
		),
		"and from the walk its face still stops it"
	)
	var edge := sill.end.x - world.hero_width * 0.5
	var nearest := level.thing("A").rect.get_center().x - GridRoom.SCORPION_SIZE.x * 0.5
	check(edge + sword.max_range >= nearest, "a throw from the sill's edge reaches its nearest point")


func test_the_breach_is_crossed_on_slabs_over_spikes() -> void:
	var level := _level()
	var reach := _flat_reach()
	var slabs := level.falling.duplicate()
	slabs.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	check_eq(slabs.size(), 3, "three slabs")
	var breach := _gap(level, WALK_TOP, slabs[0].position.x)
	var from := breach.position.x
	for slab: Rect2 in slabs:
		check_eq(slab.position.y, WALK_TOP, "a slab is level with the walk")
		check(slab.position.x - from < reach, "a gap of %.0f px is inside a %.0f px jump" % [slab.position.x - from, reach])
		from = slab.end.x
	check(breach.end.x - from < reach, "and so is the last one, %.0f px" % (breach.end.x - from))
	var under := 0.0
	for bed in level.spikes:
		if bed.position.x >= breach.position.x and bed.end.x <= breach.end.x:
			under += bed.size.x
	check_eq(under, breach.size.x, "spikes under the whole breach")


func test_the_checkpoint_before_the_breach_has_room_to_run() -> void:
	var move: MovementConfig = load(MOVE)
	var level := _level()
	var breach := _gap(level, WALK_TOP, level.falling[0].position.x)
	var nearest := -INF
	for base in level.braziers:
		if is_equal_approx(base.y, WALK_TOP) and base.x < breach.position.x:
			nearest = maxf(nearest, base.x)
	check(nearest > level.thing("A").rect.position.x, "lit after the gatehouse")
	check(
		breach.position.x - nearest >= Motion.run_up_distance(move.max_run_speed, move.ground_accel),
		"with room to get up to speed before the first jump"
	)


## The high road: up the tower, along its top and across the scaffolds, each
## gap inside a jump, down a ladder past the breach.
func test_the_high_road_can_be_crossed() -> void:
	var level := _level()
	var reach := _flat_reach()
	var tower := _roof(level)
	check(tower.size != Vector2.ZERO, "the gatehouse has a top to walk")
	var steps: Array[Rect2] = [tower]
	for wood in level.wood:
		if wood.end.y <= WALK_TOP - 128.0:
			steps.append(wood)
	steps.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	check_eq(steps.size(), 5, "the tower and four scaffolds")
	for i in range(1, steps.size()):
		var gap := steps[i].position.x - steps[i - 1].end.x
		check(gap < reach, "a %.0f px gap is inside a %.0f px jump" % [gap, reach])
		check(steps[i].position.y >= steps[i - 1].position.y, "and never up")
	var down := false
	for ladder in level.ladders:
		if is_equal_approx(ladder.position.y, steps[-1].position.y) and is_equal_approx(ladder.position.x, steps[-1].end.x) \
				and is_equal_approx(ladder.end.y, WALK_TOP):
			down = true
	check(down, "a ladder from the last scaffold down to the walk past the breach")


func test_both_hurdles_are_jumped_and_catch_a_throw() -> void:
	var move: MovementConfig = load(MOVE)
	var level := _level()
	var y := _throw_y(BAILEY_TOP)
	var hurdles: Array[Rect2] = []
	for rect in level.solids():
		if is_equal_approx(rect.end.y, BAILEY_TOP) and rect.size.y < move.jump_height:
			hurdles.append(rect)
	check_eq(hurdles.size(), 2, "a wooden hurdle and a stone one")
	var wood := 0
	for block in hurdles:
		check(y > block.position.y and y < block.end.y, "a standing throw at %.0f meets the hurdle at %.0f" % [y, block.position.x])
		if level.wood.has(block):
			wood += 1
	check_eq(wood, 1, "one of them wood")


## A switch at the foot of the face across a yard, where a standing throw
## from the yard lands, ahead of you as you arrive, with its gate on screen
## and in range.
func _check_yard_switch(switch_anchor: String, gate_anchor: String) -> void:
	var sword: SwordConfig = load(SWORD)
	var level := _level()
	var switch := level.thing(switch_anchor)
	var gate := level.thing(gate_anchor)
	check(switch != null and switch.kind == "switch", "%s is a switch" % switch_anchor)
	check_eq(String(switch.params.get("opens", "")), gate_anchor, "%s opens %s" % [switch_anchor, gate_anchor])
	var y := _throw_y(YARD_TOP)
	check(y > switch.rect.position.y and y < switch.rect.end.y, "%s: a yard throw at %.0f goes in" % [switch_anchor, y])
	check_eq(switch.rect.end.y, YARD_TOP, "%s: at the foot of the face" % switch_anchor)
	var yard := _yard(level, switch_anchor)
	check_eq(switch.rect.position.x, yard.end.x, "%s: flush with the face ahead of the yard" % switch_anchor)
	check(yard.size.x < sword.max_range, "%s: in range from anywhere in the yard" % switch_anchor)
	var screen: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	check(gate.rect.end.x - yard.position.x < screen, "%s: the gate is on the yard's screen" % gate_anchor)


## A gate too tall to jump, with stone over it to the top of the level.
func _check_gate(anchor: String) -> void:
	var move: MovementConfig = load(MOVE)
	var level := _level()
	var gate := level.thing(anchor).rect
	check(gate.size.y > move.jump_height, "%s: too tall to jump" % anchor)
	var over := false
	for wall in level.walls:
		if wall.position.x <= gate.position.x and wall.end.x >= gate.end.x \
				and is_equal_approx(wall.end.y, gate.position.y) and is_zero_approx(wall.position.y):
			over = true
	check(over, "%s: with stone over it to the top" % anchor)


func test_the_bailey_switch_raises_the_gate_ahead() -> void:
	_check_yard_switch("S", "G")
	_check_gate("G")


func test_the_bailey_yard_has_a_ladder_at_each_end() -> void:
	var level := _level()
	var yard := _yard(level, "S")
	var ends := 0
	for ladder in level.ladders:
		if is_equal_approx(ladder.position.y, BAILEY_TOP) and is_equal_approx(ladder.end.y, YARD_TOP):
			if is_equal_approx(ladder.position.x, yard.position.x) or is_equal_approx(ladder.end.x, yard.end.x):
				ends += 1
	check_eq(ends, 2, "a ladder at the drop and one up the far face")


func test_the_cage_is_scenery_over_the_quiet_stretch() -> void:
	var level := _level()
	var grate := level.thing("D").rect
	check(grate.end.y < BAILEY_TOP, "it ends above where you walk")
	check(grate.encloses(Act1Wall.dragon_rect(grate)), "the dragon fits inside it")
	var yard := _yard(level, "S")
	check(grate.end.x < yard.position.x, "over the stretch before the yard, not over the yard and its switch")
	for t in level.of_kind("scorpion") + level.of_kind("bat"):
		check(absf(t.rect.get_center().x - grate.get_center().x) > grate.size.x, "nothing hunts under the cage (%s)" % t.anchor)


func test_the_ditch_needs_the_sword() -> void:
	var level := _level()
	var hoarding := Rect2()
	for wood in level.wood:
		if is_equal_approx(wood.position.y, FAR_TOP):
			hoarding = wood
	check(hoarding.size != Vector2.ZERO, "the far side is faced with wood")
	var near := _surface(level, BAILEY_TOP, hoarding.position.x - 80.0)
	DitchChecks.run(self, "Act1Wall", near.end.x, BAILEY_TOP, FAR_TOP, hoarding, PIT_TOP)


func test_a_bat_works_the_air_over_the_sword_ledge() -> void:
	var level := _level()
	var over := false
	for t in level.of_kind("bat"):
		if t.rect.position.y < FAR_TOP and t.rect.end.y > FAR_TOP - 96.0:
			for wood in level.wood:
				if is_equal_approx(wood.position.y, FAR_TOP) and t.rect.position.x < wood.position.x and t.rect.end.x > wood.position.x:
					over = true
	check(over, "a bat flies over the hoarding")


func test_the_checkpoint_is_past_the_ditch() -> void:
	var level := _level()
	var lit := false
	for base in level.braziers:
		if is_equal_approx(base.y, FAR_TOP):
			lit = true
	check(lit, "a brazier on the far side")


func test_the_castle_gate_switch_is_the_plinth_face() -> void:
	_check_yard_switch("V", "W")
	_check_gate("W")
	var level := _level()
	var yard := _yard(level, "V")
	var back := false
	for ladder in level.ladders:
		if is_equal_approx(ladder.position.x, yard.position.x) and is_equal_approx(ladder.end.y, YARD_TOP):
			back = true
	check(back, "a ladder back up out of the gate yard")
	var chest := false
	for base in level.chests:
		if base.x > yard.position.x and base.x < yard.end.x:
			chest = true
	check(chest, "and a chest in it, so nobody reaches the last gate with nothing to throw")
