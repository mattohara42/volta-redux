## A chest of swords: walk into it and the swords you own come back up to
## `SwordConfig.chest_fill`. It never runs out, so a room can never leave you
## stranded without anything to throw (Matt, 2026-10-03: early rooms resupply
## from a chest of three; later rooms from hidden swords or a mechanism).
##
## Gold hilts standing out of it say what it gives before it is used
## (`ART_DIRECTION.md`). Art: `assets/art/act1/props/sword_chest.png`.
class_name SwordChest
extends Area2D

const SIZE := Vector2(20.0, 14.0)
const CONFIG: SwordConfig = preload("res://config/sword.tres")
const ART: Texture2D = preload("res://assets/art/act1/props/sword_chest.png")


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = SIZE
	shape.shape = box
	shape.position = Vector2(0.0, -SIZE.y * 0.5)
	add_child(shape)
	# The player is layer 3 (`collision_layer = 4` in player.tscn) and that is
	# the only thing this watches, as with `Brazier`.
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player != null:
		var before := player.swords_held
		player.top_up_swords(CONFIG.chest_fill)
		if player.swords_held > before:
			Burst.emit(get_parent(), global_position + Vector2(0.0, -SIZE.y), Burst.Kind.SPARKLE)


func _draw() -> void:
	draw_texture(ART, Vector2(-ART.get_width() * 0.5, -ART.get_height()))
