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
## How a lying gem bobs and catches the light: art px, and seconds a cycle.
## Purely how it looks: what you walk into to take it does not move.
const BOB: float = 2.0
const BOB_SECONDS: float = 1.6
const TWINKLE_SECONDS: float = 1.3

var _clock := 0.0


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


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


## Bobbing a whole pixel at a time, and now and then a glint off its top facet:
## a gem waiting to be taken should look like it wants to be.
func _draw() -> void:
	var lift := roundf(BOB * (0.5 + 0.5 * sin(TAU * _clock / BOB_SECONDS)))
	var centre := Vector2(0.0, -SIZE.y * 0.5 - lift)
	draw_gem(self, centre, SIZE)
	if fmod(_clock, TWINKLE_SECONDS) < 0.12:
		var at := (centre + Vector2(-SIZE.x * 0.25, -SIZE.y * 0.35)).floor()
		draw_rect(Rect2(at + Vector2(-1.0, 0.0), Vector2(3.0, 1.0)), Palette.ARC_CORE)
		draw_rect(Rect2(at + Vector2(0.0, -1.0), Vector2(1.0, 3.0)), Palette.ARC_CORE)


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
