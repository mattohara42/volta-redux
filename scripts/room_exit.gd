## Where a room ends. The hero walking into it is handed to `ActState`, which
## knows what comes next; the room never does.
##
## Gold, because gold means interactive (`ART_DIRECTION.md`), drawn as the
## doorway post the rooms used before they were connected.
class_name RoomExit
extends Area2D

var _size := Vector2.ZERO


func configure(size: Vector2) -> void:
	_size = size
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	add_child(shape)
	# The player is layer 3 (`collision_layer = 4` in player.tscn) and that is
	# the only thing this watches, as with `Brazier`.
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or player.is_dead():
		return
	var state := get_node_or_null("/root/ActState")
	if state == null:
		return
	var scene := get_tree().current_scene
	# A room loaded under another node (the capture tool) is not the current
	# scene, and has nowhere to go.
	if scene == null:
		return
	state.leave_room(scene.scene_file_path, player.swords_held, player.sword_config.max_swords, player.gems_held)


func _draw() -> void:
	draw_rect(Rect2(-_size * 0.5, _size), Palette.GOLD_FACE)
