## One of Act 4's three gems (`SPEC.md` → *Gems and keys survive*). Walk into
## it and it is yours; it rides with you from room to room the way swords in
## hand do, and a death does not take it back. A `GemHolder` spends it.
##
## Cut crystal in the arc's colours, because a gem is a conductor here: placed
## in a holder it closes the break it sits in. Drawn in code until its art is
## generated.
class_name Gem
extends Area2D

const SIZE := Vector2(10.0, 12.0)
const ATMOSPHERE: AtmosphereConfig = preload("res://config/atmosphere.tres")


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = SIZE
	shape.shape = box
	shape.position = Vector2(0.0, -SIZE.y * 0.5)
	add_child(shape)
	# The player alone, layer 3, as `SwordChest` watches.
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	body_entered.connect(_on_body_entered)
	var light := LightSource.point(ATMOSPHERE.light_gem_radius, Palette.ARC, ATMOSPHERE.light_gem_strength)
	light.position = Vector2(0.0, -SIZE.y * 0.5)
	add_child(light)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player != null:
		player.gems_held += 1
		Burst.emit(get_parent(), global_position + Vector2(0.0, -SIZE.y * 0.5), Burst.Kind.ARC_SPARKS)
		Sfx.play(self, Sfx.CONFIG.gem)
		queue_free()


func _draw() -> void:
	draw_gem(self, Vector2(0.0, -SIZE.y * 0.5), SIZE)


## A cut stone, point down: a dark rim, a face and a highlight. Shared with the
## holder and the HUD so the three always read as the same object.
static func draw_gem(canvas: CanvasItem, centre: Vector2, size: Vector2) -> void:
	var half := size * 0.5
	var outline := PackedVector2Array([
		centre + Vector2(-half.x, -half.y * 0.3),
		centre + Vector2(-half.x * 0.5, -half.y),
		centre + Vector2(half.x * 0.5, -half.y),
		centre + Vector2(half.x, -half.y * 0.3),
		centre + Vector2(0.0, half.y),
	])
	canvas.draw_colored_polygon(outline, Palette.ARC_RESIDUE)
	var face := PackedVector2Array()
	for point in outline:
		face.append(centre + (point - centre) * 0.7)
	canvas.draw_colored_polygon(face, Palette.ARC)
	canvas.draw_rect(Rect2(centre + Vector2(-half.x * 0.35, -half.y * 0.6), Vector2(2.0, 2.0)), Palette.ARC_CORE)
