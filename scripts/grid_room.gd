## A room built from a level file (`LevelGrid`), through the same `Bench`
## builders every hand-written room uses, so the walk-back check, the tests
## and the drawing all see it the same way.
##
## A room with something the map cannot say (the bailey's caged dragon, a
## chain that links a switch to its gate) extends this, reads what it needs
## from `level`, and adds the rest in `_built` and `_draw_over`.
class_name GridRoom
extends Bench

## The default killing boxes for creatures placed from a map, the same sizes
## the hand-written rooms use. A `[things]` line can set its own with `size=`.
const SCORPION_SIZE := Vector2(30.0, 34.0)
const BAT_SIZE := Vector2(20.0, 14.0)
const ANT_SIZE := Vector2(22.0, 16.0)
const EYEBALL_SIZE := Vector2(24.0, 24.0)
## How deep a floor plate sits in the floor it is set into, as the
## hand-written plate rooms have it.
const PLATE_DEPTH: float = 8.0

@export_file("*.level") var level_file: String
## The level's own art, if it is not its act's (the forest is Act 1 and is not
## drawn in the castle's stone). Null draws the act's set.
@export var tiles: ActTiles

var level: LevelGrid.Level
## What the map's anchors built, by anchor, for a room to reach in `_built`.
var switches := {}
var gates := {}
## Each sword the level lays, by where it lies, so a death can lay it again.
var _loose := {}
var _tiles: ActTiles


## A plate marked on the air above a floor lies on that floor, as the
## hand-built plate rooms have it, so a sword lying there is on it.
static func plate_rect(cells: Rect2) -> Rect2:
	return Rect2(cells.position.x, cells.end.y - PLATE_DEPTH, cells.size.x, PLATE_DEPTH)


## An ant marked on the air of a hollow walks its inside faces, so its
## centre's loop is the hollow pulled in by half its body.
static func ant_track(cells: Rect2, size: Vector2) -> Rect2:
	return cells.grow(-size.y * 0.5)


## A lift's `travel=x,y` is in cells; the platform needs px.
static func lift_travel(t: LevelGrid.Thing, cell: float) -> Vector2:
	var parts := String(t.params.get("travel", "0,0")).split(",")
	if parts.size() != 2:
		return Vector2.ZERO
	return Vector2(float(parts[0]), float(parts[1])) * cell


## The level a room's file describes, read the way the room reads it, for the
## tests and tools that want its geometry without building the room.
static func read(path: String) -> LevelGrid.Level:
	return LevelGrid.parse(FileAccess.get_file_as_string(path))


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	level = read(level_file)
	room_height = level.height
	for error in level.errors:
		push_error("%s: %s" % [level_file, error])
	var act_state := get_node_or_null("/root/ActState")
	if act_state != null and not scene_file_path.is_empty():
		var act: ActConfig = act_state.act_of(scene_file_path)
		if act != null:
			_tiles = act.tiles
	if tiles != null:
		_tiles = tiles
	_build()
	_built()
	_add_enclosure(level.size.x)
	_frame_camera(level.size.x)
	queue_redraw()


func _build() -> void:
	for rect in level.ground:
		_add_solid(rect)
	for rect in level.walls:
		_add_solid(rect)
	for rect in level.castle:
		_add_solid(rect)
	for rect in level.wood:
		_add_wood(rect, false)
	for rect in level.lava:
		_add_lava(rect)
	for rect in level.spikes:
		_add_spikes(rect.end.y, rect.position.x, int(rect.size.x / hazards.spike_tooth_pitch))
	for rect in level.falling:
		var platform := _add_falling_platform(rect)
		if platform != null and _tiles != null and _tiles.crumble_tile != null:
			platform.art = _tiles.crumble_tile
	for rect in level.ladders:
		_add_ladder(rect.position.x, rect.position.y, rect.end.y)
	for base in level.braziers:
		_add_brazier(base)
	for base in level.chests:
		_add_chest(base)
	if level.exit.size != Vector2.ZERO:
		_add_exit(level.exit)
	if level.has_start:
		for node in get_tree().get_nodes_in_group("player"):
			var player := node as Node2D
			if player != null:
				player.position = level.start - Vector2(0.0, world.hero_height * 0.5)
	_build_things()


## Things that come in pairs are wired here: a switch or a plate names the
## gate it opens, and a gate with more than one opens only while all of them
## are held.
func _build_things() -> void:
	for t in level.of_kind("gate"):
		var gate := _add_gate(t.rect)
		gate.art = TileArt.PORTCULLIS_TILE
		gates[t.anchor] = gate
	var openers := {}
	for t in level.of_kind("switch"):
		var switch := _add_switch(t.rect)
		switches[t.anchor] = switch
		_wire_opener(t, switch, openers)
	for t in level.of_kind("plate"):
		_wire_opener(t, _add_plate(plate_rect(t.rect)), openers)
	for opens: String in openers:
		var held: Array = openers[opens]
		var gate: Gate = gates[opens]
		for opener: Node in held:
			opener.held_changed.connect(func(_is_held: bool) -> void:
				gate.set_open(held.all(func(o: Node) -> bool: return o.is_held)))
	for t in level.of_kind("lift"):
		_add_moving_platform(t.rect, lift_travel(t, level.cell))
	for t in level.of_kind("geyser"):
		_add_geyser(t.rect)
	for t in level.of_kind("ant"):
		var size := t.size("size", ANT_SIZE)
		_add_ant(size, ant_track(t.rect, size))
	for t in level.of_kind("slab"):
		var slab := _add_falling_platform(t.rect)
		if slab != null:
			slab.holds = int(t.number("holds", 1.0))
			if _tiles != null and _tiles.crumble_tile != null:
				slab.art = _tiles.crumble_tile
	for t in level.of_kind("sword"):
		_lay_sword(Vector2(t.rect.get_center().x, t.rect.end.y))
	for t in level.of_kind("eyeball"):
		var size := t.size("size", EYEBALL_SIZE)
		_add_eyeball(Rect2(t.rect.get_center() - size * 0.5, size), t.rect)
	for t in level.of_kind("scorpion"):
		var size := t.size("size", SCORPION_SIZE)
		var base := Vector2(t.rect.get_center().x, t.rect.end.y)
		var scorpion := _add_scorpion(Rect2(base - Vector2(size.x * 0.5, size.y), size), t.number("range", 0.0))
		if scorpion != null and t.flag("dormant"):
			scorpion.start_dormant()
	for t in level.of_kind("stump"):
		var to: Variant = null
		if t.params.has("to"):
			var target := level.thing(String(t.params["to"]))
			if target != null and target.kind == "stump":
				to = Vector2(target.rect.get_center().x, target.rect.position.y)
			else:
				push_error("%s: stump '%s' leads to no stump ('%s')" % [level_file, t.anchor, t.params["to"]])
		var stump := _add_stump(t.rect, to)
		if _tiles != null and _tiles.stump_texture != null:
			stump.art = _tiles.stump_texture
	for t in level.of_kind("bat"):
		var size := t.size("size", BAT_SIZE)
		_add_bat(Rect2(t.rect.get_center() - size * 0.5, size), t.rect.size * 0.5)


func _art(act: ActConfig) -> ActTiles:
	return tiles if tiles != null else act.tiles


## A sword lying on the floor at `base`, as one left after a missed catch.
static func lying_at(base: Vector2, sword_length: float) -> Vector2:
	return base - Vector2(0.0, sword_length * 0.25)


func _lay_sword(base: Vector2) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player == null or player.sword_scene == null:
			continue
		var sword := player.sword_scene.instantiate() as Sword
		add_child(sword)
		sword.lie(player, lying_at(base, world.sword_length))
		player.adopt(sword)
		_loose[base] = sword
		return


## A found sword does not survive a death (Matt, 2026-10-08): the hand goes
## back to what it was, and the sword goes back to where it lay.
func _on_hero_respawned(at: Vector2, frozen_for: float) -> void:
	super._on_hero_respawned(at, frozen_for)
	for base: Vector2 in _loose:
		if not is_instance_valid(_loose[base]):
			_lay_sword(base)


func _wire_opener(t: LevelGrid.Thing, opener: Node, openers: Dictionary) -> void:
	var opens := String(t.params.get("opens", ""))
	if not gates.has(opens):
		push_error("%s: %s '%s' opens no gate ('%s')" % [level_file, t.kind, t.anchor, opens])
		return
	if not openers.has(opens):
		openers[opens] = []
	openers[opens].append(opener)


## For a room to add what the map cannot say. Runs after the map is built.
func _built() -> void:
	pass


func _draw() -> void:
	TileArt.draw_background_across(self, level.size.x, _tiles, room_height)
	_draw_under()
	for rect in level.ground_faces:
		TileArt.draw_ground(self, rect, _tiles)
	for rect in level.wall_faces:
		TileArt.draw_wall(self, rect, _tiles)
	for rect in level.castle_faces:
		TileArt.draw_wall(self, rect)
	for rect in level.wood:
		TileArt.draw_wood(self, rect, _tiles)
	for ladder in _ladders:
		TileArt.draw_ladder(self, ladder, _tiles)
	for bed in _spike_beds:
		TileArt.draw_spikes(self, bed, _tiles)
	_draw_over()


## For a room to draw behind the level's stone (a window into the dark).
func _draw_under() -> void:
	pass


## For a room to draw over it (a chain on a face).
func _draw_over() -> void:
	pass
