## The camera shaken, in whole art pixels and settling over a few tenths of a
## second. `ART_DIRECTION.md` allows it for two things only, the generator and
## lava impacts, because it is a spice and this game has a lot of impacts:
## anything else that calls this is breaking that rule.
##
## Purely how it looks. It moves the camera's `offset`, never the camera or
## anything the game measures.
class_name Shake
extends Node

var _strength := 0.0
var _seconds := 0.0
var _left := 0.0
var _camera: Camera2D


## Shakes whichever camera is drawing `from`'s viewport, `strength` art px at
## first, gone after `seconds`. A stronger kick while one is running wins.
static func kick(from: Node, strength: float, seconds: float) -> void:
	var camera := from.get_viewport().get_camera_2d() if from.is_inside_tree() else null
	if camera == null:
		return
	var shake: Shake = null
	for child in camera.get_children():
		if child is Shake:
			shake = child
	if shake == null:
		shake = Shake.new()
		shake._camera = camera
		camera.add_child(shake)
	if strength >= shake._current():
		shake._strength = strength
		shake._seconds = maxf(seconds, 0.01)
		shake._left = shake._seconds


func _current() -> float:
	return _strength * (_left / _seconds) if _seconds > 0.0 else 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	var amount := _current()
	_camera.offset = Vector2(
		roundf(randf_range(-amount, amount)), roundf(randf_range(-amount, amount))
	)
	if _left <= 0.0:
		_camera.offset = Vector2.ZERO
