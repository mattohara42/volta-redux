## A chest of swords: walk into it and the swords you own come back up to
## `SwordConfig.chest_fill`. It never runs out, so a room can never leave you
## stranded without anything to throw (Matt, 2026-10-03: early rooms resupply
## from a chest of three; later rooms from hidden swords or a mechanism).
##
## Drawn in code until its art is generated (`ART.md`). Gold, because it is
## used (`ART_DIRECTION.md`: a mechanism reads as one before it is used).
class_name SwordChest
extends Area2D

const SIZE := Vector2(20.0, 14.0)
const CONFIG: SwordConfig = preload("res://config/sword.tres")


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
		player.top_up_swords(CONFIG.chest_fill)


func _draw() -> void:
	var body := Rect2(-SIZE.x * 0.5, -SIZE.y, SIZE.x, SIZE.y)
	draw_rect(body, Palette.WOOD_DEEP)
	draw_rect(Rect2(body.position, Vector2(body.size.x, 3.0)), Palette.WOOD_FACE)
	# Three gold hilts standing out of it: what it gives, said before it is used.
	for i in 3:
		var x := body.position.x + body.size.x * (0.25 + 0.25 * float(i))
		draw_rect(Rect2(x - 1.0, body.position.y - 8.0, 2.0, 8.0), Palette.GOLD_FACE)
		draw_rect(Rect2(x - 3.0, body.position.y - 5.0, 6.0, 2.0), Palette.GOLD_SHADE)
	# The gold band and lock plate.
	draw_rect(Rect2(body.position.x, body.position.y + 6.0, body.size.x, 2.0), Palette.GOLD_SHADE)
	draw_rect(Rect2(-2.0, body.position.y + 5.0, 4.0, 4.0), Palette.GOLD_FACE)
