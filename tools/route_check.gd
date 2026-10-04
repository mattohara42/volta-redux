## The whole game's route, headless (`BUILD_PLAN.md` M13: "the game can be
## completed from a new save"). Starts at the main scene and, room by room,
## loads each as the real current scene, puts the hero in its exit and checks
## that `ActState` loads the room that should come next, through every act's
## card to the ending and back to a new game.
##
## It does not play the rooms: the scenarios do that, one room at a time.
## This is the part they cannot reach, because under the capture tool a room
## is not the current scene and its exit has nowhere to go.
##
## A boss room's exit appears only after its fight, so the check ends the
## fight the way the room would (the throne's dragon freed, the flight at its
## end). Exits 1 on any failure.
extends SceneTree

## How long to wait for a room to load, or for a card to pass, in seconds of
## wall time: headless frames run far faster than real time, and a card's
## timer counts real time.
const WAIT_SECONDS: float = 15.0

var _expected: Array[String] = []
var _step := 0
var _since := 0
var _nudged := false
var _failed := false


func _init() -> void:
	var act_state: Script = load("res://scripts/act_state.gd")
	for act: ActConfig in act_state.ACTS:
		for room in act.rooms:
			_expected.append(room)
	# After the ending, a new game.
	_expected.append(_expected[0])
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	if main != _expected[0]:
		_fail("the game launches into %s, not the first room %s" % [main, _expected[0]])
	_since = Time.get_ticks_msec()
	change_scene_to_file(main)


func _process(_delta: float) -> bool:
	if _failed or _step >= _expected.size():
		return true
	var scene := current_scene
	if scene == null or scene.scene_file_path != _expected[_step]:
		if _elapsed() > WAIT_SECONDS:
			_fail("expected %s, still on %s" % [_expected[_step], scene.scene_file_path if scene else "nothing"])
		return false
	if _step == _expected.size() - 1:
		print("route: back at %s, a new game. %d rooms in order." % [_expected[_step], _expected.size() - 1])
		quit(0)
		return true
	if not _nudged:
		print("route: %s" % _expected[_step])
		_nudged = true
		_leave(scene)
	if _elapsed() > WAIT_SECONDS:
		_fail("%s never led to %s" % [_expected[_step], _expected[_step + 1]])
		return true
	return false


## Called every frame until the scene changes: walk the hero into the exit, or
## end the fight that makes one.
func _leave(scene: Node) -> void:
	_since = Time.get_ticks_msec()
	_keep_leaving.call_deferred(scene, _step)


func _keep_leaving(scene: Node, step: int) -> void:
	while is_instance_valid(scene) and current_scene == scene and _step == step:
		var player := get_first_node_in_group("player") as Node2D
		var rider := get_first_node_in_group("riders") as Node2D
		var exit := _exit_in(scene)
		if rider != null:
			rider.position.x = 1.0e6
		elif exit != null and player != null:
			player.global_position = exit.global_position
		elif scene.has_method("_free_the_dragon"):
			if not scene.get("_freed"):
				scene.call("_free_the_dragon")
		await physics_frame
	if _step == step:
		_step += 1
		_nudged = false
		_since = Time.get_ticks_msec()


func _exit_in(scene: Node) -> Node2D:
	for child in scene.get_children():
		if child is RoomExit:
			return child
	return null


func _elapsed() -> float:
	return (Time.get_ticks_msec() - _since) / 1000.0


func _fail(message: String) -> void:
	_failed = true
	printerr("route: FAIL: %s" % message)
	quit(1)
