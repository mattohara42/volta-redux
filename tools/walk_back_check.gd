## Can every room be walked back to its start? (`SPEC.md`: "you can always
## walk back to its start", Matt 2026-10-06.) Loads each room of every act as
## the real current scene, reads the geometry it built (`Bench.
## walk_back_layout`) and hands it to `WalkBack`, which does the reasoning.
##
## Prints, per room, every surface you can reach but not come back from, and
## fails if there is one, if the exit is out of reach (the model would then be
## too strict to trust), or if the hero does not start on a surface.
##
## `tools/dev.sh walkback [filter]` runs it; a filter keeps rooms whose path
## contains it, and a `res://` path checks that one scene, in an act or not.
## Exits 1 on any failure.
extends SceneTree

const MOVEMENT: MovementConfig = preload("res://config/movement.tres")
const SWORD: SwordConfig = preload("res://config/sword.tres")
const WORLD: WorldConfig = preload("res://config/world.tres")
const WAIT_SECONDS: float = 15.0

var _rooms: Array[String] = []
var _step := 0
var _frames := 0
var _since := 0
var _failures := 0


func _init() -> void:
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		filter = arg
	if filter.begins_with("res://"):
		# One scene by path, for a level in no act yet.
		_rooms.append(filter)
	else:
		var act_state: Script = load("res://scripts/act_state.gd")
		for act: ActConfig in act_state.ACTS:
			for room in act.rooms:
				if filter.is_empty() or room.contains(filter):
					_rooms.append(room)
	_next()


func _process(_delta: float) -> bool:
	if _step >= _rooms.size():
		print("walkback: %d room(s), %d failed" % [_rooms.size(), _failures])
		quit(1 if _failures > 0 else 0)
		return true
	var scene := current_scene
	if scene == null or scene.scene_file_path != _rooms[_step]:
		if Time.get_ticks_msec() - _since > WAIT_SECONDS * 1000.0:
			_fail(_rooms[_step], "never loaded")
			_advance()
		return false
	# A frame for the room's own deferred building to finish.
	_frames += 1
	if _frames < 2:
		return false
	var bench := scene as Bench
	if bench == null:
		print("skip  %s: not a room you walk" % _rooms[_step])
	else:
		var layout := bench.walk_back_layout()
		_judge(_rooms[_step], layout, WalkBack.check(layout, _moves()))
	_advance()
	return false


func _judge(room: String, layout: WalkBack.Layout, report: WalkBack.Report) -> void:
	var problems: Array[String] = []
	if not report.start_found:
		problems.append("the hero does not start on a surface")
	if not report.exit_reached:
		problems.append("the exit is out of reach, so this check cannot be trusted here")
	for surface in report.stranded:
		problems.append("stranded on y %d, x %d to %d: reachable, and no way back to the start" % [
			int(surface.position.y), int(surface.position.x), int(surface.end.x)])
	if problems.is_empty():
		print("ok    %s (%d surfaces)" % [room, report.surfaces.size()])
		return
	for problem in problems:
		_fail(room, problem)
	_draw(room, layout, report)


## The room as the check saw it, so a failure can be looked at rather than
## believed (`CLAUDE.md`): stone, wood and metal, what kills, ladders, every
## surface, and the stranded ones thick. Written next to the project, where
## screenshots go and git ignores them.
func _draw(room: String, layout: WalkBack.Layout, report: WalkBack.Report) -> void:
	var size := Vector2.ZERO
	for solid in layout.solids:
		size = size.max(solid.end)
	var image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGB8)
	image.fill(Palette.BACKDROP)
	for solid in layout.solids:
		var colour := Palette.WOOD_DEEP if layout.embeddable.has(solid) else Palette.STONE_MID
		_fill(image, solid, colour)
	for hazard in layout.deadly:
		_fill(image, hazard, Palette.LAVA_FLOW)
	for ladder in layout.ladders:
		_fill(image, ladder, Palette.GOLD_SHADE)
	for surface in report.surfaces:
		_fill(image, Rect2(surface.position.x, surface.position.y - 1.0, surface.size.x, 2.0), Palette.STONE_LIT)
	for surface in report.stranded:
		_fill(image, Rect2(surface.position.x, surface.position.y - 6.0, surface.size.x, 6.0), Palette.ARC)
	_fill(image, Rect2(layout.start - Vector2(4.0, 12.0), Vector2(8.0, 12.0)), Palette.GOLD_FACE)
	var out := "walkback_%s.png" % room.get_file().get_basename()
	image.save_png(ProjectSettings.globalize_path("res://").path_join(out))
	print("      drawn to %s" % out)


static func _fill(image: Image, rect: Rect2, colour: Color) -> void:
	var clipped := Rect2i(rect).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if clipped.size.x > 0 and clipped.size.y > 0:
		image.fill_rect(clipped, colour)


func _fail(room: String, why: String) -> void:
	_failures += 1
	print("FAIL  %s: %s" % [room, why])


func _advance() -> void:
	_step += 1
	_next()


func _next() -> void:
	_frames = 0
	_since = Time.get_ticks_msec()
	if _step < _rooms.size():
		change_scene_to_file(_rooms[_step])


static func _moves() -> WalkBack.Moves:
	var moves := WalkBack.Moves.new()
	moves.jump_height = MOVEMENT.jump_height
	moves.time_to_apex = MOVEMENT.time_to_apex
	moves.fall_multiplier = MOVEMENT.fall_gravity_multiplier
	moves.run_speed = MOVEMENT.max_run_speed
	moves.max_fall_speed = MOVEMENT.max_fall_speed
	moves.hero_width = WORLD.hero_width
	moves.hero_height = WORLD.hero_height
	moves.sword_range = SWORD.max_range
	moves.sword_length = WORLD.sword_length
	return moves
