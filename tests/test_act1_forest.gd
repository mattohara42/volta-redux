## Act 1's first level (`levels/act1_forest.level`), as arithmetic. It folds in
## the old moat bank's claims and holds every scorpion in the level to them:
## the only way through a scorpion's tunnel is a sword in its back, there is
## always somewhere safe to stand and wait for that back to turn, and nothing
## here teaches the outer wall's from-above trick by accident. Every number it
## rests on lives in `config/`.
extends TestCase

const LEVEL := "res://levels/act1_forest.level"
const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const ENEMIES := "res://config/enemies.tres"
const SWORD := "res://config/sword.tres"


## Each scorpion, with the roof of the tunnel it patrols: the nearest solid
## over its home whose underside is above its floor.
func _patrols(level: LevelGrid.Level) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for t in level.of_kind("scorpion"):
		var home := t.rect.get_center().x
		var floor_y := t.rect.end.y
		var roof := Rect2()
		for solid in level.solids():
			if solid.position.x <= home and solid.end.x >= home and solid.end.y <= floor_y \
					and solid.end.y > roof.end.y:
				roof = solid
		found.append({
			"anchor": t.anchor, "home": home, "floor": floor_y,
			"range": t.number("range", 0.0), "roof": roof, "dormant": t.flag("dormant"),
		})
	return found


func test_the_level_reads_cleanly() -> void:
	var level := GridRoom.read(LEVEL)
	check_eq(level.errors, [] as Array[String], "no errors in the level file")
	check(level.has_start, "the hero has somewhere to start")
	check(level.exit.size != Vector2.ZERO, "and an exit")


func test_every_scorpion_is_in_a_tunnel_it_cannot_be_jumped_in() -> void:
	var world: WorldConfig = load(WORLD)
	for p in _patrols(GridRoom.read(LEVEL)):
		var roof: Rect2 = p["roof"]
		check(roof.size != Vector2.ZERO, "scorpion %s has a roof over it" % p["anchor"])
		var headroom: float = p["floor"] - roof.end.y
		check(headroom > world.hero_height, "%s: %.0f px fits a %.0f px hero" % [p["anchor"], headroom, world.hero_height])
		check(
			headroom < world.hero_height + GridRoom.SCORPION_SIZE.y,
			"%s: and is less than the %.0f px it takes to jump a scorpion"
				% [p["anchor"], world.hero_height + GridRoom.SCORPION_SIZE.y]
		)


## The mouth is the safe place to stand. A patrol that reached out of its
## tunnel would take it away.
func test_each_patrol_stays_inside_its_tunnel() -> void:
	var half := GridRoom.SCORPION_SIZE.x * 0.5
	for p in _patrols(GridRoom.read(LEVEL)):
		var roof: Rect2 = p["roof"]
		var near: float = p["home"] - half
		var far: float = p["home"] + p["range"] + half
		check(near >= roof.position.x, "%s starts inside its tunnel (%.0f >= %.0f)" % [p["anchor"], near, roof.position.x])
		check(far <= roof.end.x, "%s ends inside its tunnel (%.0f <= %.0f)" % [p["anchor"], far, roof.end.x])


## Standing at the mouth, a throw reaches the nearest the first scorpion in a
## tunnel ever comes; in a nest, a throw from where the one before it patrolled
## reaches the next.
func test_a_throw_from_where_you_stand_reaches_the_next_scorpion() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var patrols := _patrols(GridRoom.read(LEVEL))
	patrols.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["home"] < b["home"])
	var last_roof := Rect2()
	var stand := 0.0
	for p in patrols:
		var roof: Rect2 = p["roof"]
		if roof != last_roof:
			stand = roof.position.x - world.hero_width * 0.5
		var near: float = p["home"] - GridRoom.SCORPION_SIZE.x * 0.5
		check(stand + sword.max_range >= near, "%s: a throw from %.0f reaches %.0f" % [p["anchor"], stand, near])
		stand = p["home"]
		last_roof = roof


## Flat floors in every scorpion's line: a throw from a step 5 to 16 px up lands
## in the top of its body and kills it head on, which is the outer wall's lesson.
func test_no_step_in_a_scorpions_line() -> void:
	var level := GridRoom.read(LEVEL)
	for p in _patrols(level):
		var roof: Rect2 = p["roof"]
		var line := Rect2(roof.position.x, roof.end.y, roof.size.x, p["floor"] - roof.end.y)
		for solid in level.solids():
			check(
				not solid.intersects(line),
				"%s: nothing stands in the tunnel (%s)" % [p["anchor"], solid]
			)


## A sleeper faces the way its patrol runs, right, away from the hero walking
## in from the left, and it wakes before the hero can walk into it.
func test_a_sleeper_has_its_back_to_the_way_in() -> void:
	var enemies: EnemyConfig = load(ENEMIES)
	var world: WorldConfig = load(WORLD)
	for p in _patrols(GridRoom.read(LEVEL)):
		if p["dormant"]:
			check_eq(
				ScorpionPatrol.facing_at(0.0, p["range"], enemies.scorpion_speed), 1.0,
				"%s at rest faces right" % p["anchor"]
			)
	check(
		enemies.dormant_wake_range > (GridRoom.SCORPION_SIZE.x + world.hero_width) * 0.5,
		"a sleeper wakes before the hero can walk into it"
	)


## The clearing teaches throw and catch: nothing in it can hurt you, and a
## throw from the start or the plinth turns for home before it meets stone.
func test_the_clearing_is_safe_to_throw_in() -> void:
	var level := GridRoom.read(LEVEL)
	var move: MovementConfig = load(MOVE)
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var first_roof := INF
	for p in _patrols(level):
		first_roof = minf(first_roof, (p["roof"] as Rect2).position.x)
	var plinth := Rect2()
	for solid in level.ground:
		if solid.end.y == level.start.y and solid.position.x < first_roof:
			plinth = solid
	check(plinth.size != Vector2.ZERO, "there is a plinth in the clearing")
	check(plinth.size.y <= move.jump_height, "the plinth can be jumped onto")
	var from_start := level.start.x + world.hero_width * 0.5 + sword.max_range
	check(from_start < plinth.position.x, "a throw from the start turns at %.0f, before the plinth at %.0f" % [from_start, plinth.position.x])
	var furthest := plinth.end.x + world.hero_width * 0.5 + sword.max_range
	check(furthest < first_roof, "a throw from the plinth turns at %.0f, before the roots at %.0f" % [furthest, first_roof])
	for rect in level.lava + level.spikes:
		check(rect.position.x > first_roof, "no hazard in the clearing (%s)" % rect)
	for t in level.of_kind("bat"):
		check(t.rect.position.x > first_roof, "no bat in the clearing (%s)" % t.anchor)


## Each stump that leads somewhere leads to another stump.
func test_every_stump_leads_to_a_stump() -> void:
	var level := GridRoom.read(LEVEL)
	var warps := 0
	for t in level.of_kind("stump"):
		if t.params.has("to"):
			warps += 1
			var target := level.thing(String(t.params["to"]))
			check(target != null and target.kind == "stump", "stump %s leads to a stump" % t.anchor)
	check(warps > 0, "the forest has at least one warp")


## N0: the forest drew the castle painting's lit windows into its dark, because
## the lights came from the act's art rather than the level's own.
func test_the_forest_borrows_no_lights_from_the_castle_painting() -> void:
	var room := GridRoom.new()
	room.tiles = load("res://assets/art/forest/forest_tiles.tres")
	var act := load("res://config/act1.tres") as ActConfig
	check(room._art(act) == room.tiles, "the forest's lights come from the forest's own art")
	check(
		TileArt.painted_lights(4000.0, room._art(act), 900.0).is_empty(),
		"and the forest's art, unpainted, has none"
	)
	room.free()


## N0: the forest's lip is moss, which grows on top and never hangs under a trunk.
func test_no_moss_lintel_under_the_forest_trunks() -> void:
	check(not (load("res://assets/art/forest/forest_tiles.tres") as ActTiles).lintel, "forest: none")
	check(TileArt.ACT1.lintel, "the castle's cut stone keeps its lintel")
