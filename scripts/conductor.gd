## A piece of conductive metal (`SPEC.md` → *Conduct*). Solid, and a sword
## sticks in it the way it sticks in wood (group "metal"). It carries current
## only when `CircuitNetwork` says it is live, and while live it kills anything
## standing on or against it, like lava. Dead metal is safe.
##
## A source is live always: it is where current comes from.
class_name Conductor
extends StaticBody2D

## How far past its own faces a live piece reaches for a body, so feet resting
## on its top count as touching it. Purely contact, not a tuning number.
const TOUCH: float = 1.0
const ATMOSPHERE: AtmosphereConfig = preload("res://config/atmosphere.tres")

var is_source := false
var is_live := false:
	set(value):
		if value == is_live:
			return
		is_live = value
		_glow.visible = value
		_on_live_changed(value)
		queue_redraw()
## The rect this piece occupies, in the room's coordinates.
var rect := Rect2()

## Plate art repeated across the piece, for a real room. Null on the bench,
## which keeps the drawn shape.
var art: Texture2D = null:
	set(value):
		art = value
		texture_repeat = TEXTURE_REPEAT_ENABLED if value != null else TEXTURE_REPEAT_PARENT_NODE
		queue_redraw()

var _zap: Area2D
var _glow: ChargedSurface


func configure(area: Rect2, source: bool = false) -> void:
	rect = area
	is_source = source
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = area.size
	shape.shape = box
	add_child(shape)
	position = area.get_center()
	add_to_group("metal")
	add_to_group("conductors")
	_zap = Area2D.new()
	var zap_shape := CollisionShape2D.new()
	var zap_box := RectangleShape2D.new()
	zap_box.size = area.size + Vector2(TOUCH, TOUCH) * 2.0
	zap_shape.shape = zap_box
	_zap.add_child(zap_shape)
	# The player alone, layer 3, as `Hazard` watches.
	_zap.collision_layer = 0
	_zap.collision_mask = 4
	_zap.monitorable = false
	add_child(_zap)
	_glow = ChargedSurface.new()
	_glow.setup(Rect2(-area.size * 0.5, area.size))
	_glow.visible = false
	add_child(_glow)
	# Its light, under the glow so it goes out with it: live copper lights the
	# recess it sits in, dead copper is as dark as stone (`LightField`).
	var along := Vector2(area.size.x, 0.0) if area.size.x >= area.size.y else Vector2(0.0, area.size.y)
	var centre := area.size * 0.5
	_glow.add_child(LightSource.line(
		centre - along * 0.5, centre + along * 0.5, ATMOSPHERE.light_live_radius,
		Palette.ARC, ATMOSPHERE.light_live_strength
	))
	is_live = source


func _physics_process(_delta: float) -> void:
	if not is_live or not _kills():
		return
	for body in _zap.get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.die(DeathMessages.Cause.CURRENT)


## Whether touching it while live kills. A switch overrides this: it is a
## socket you wire to, not a floor.
func _kills() -> bool:
	return true


func _on_live_changed(_live: bool) -> void:
	pass


## Cold, matte metal when dead (anything you can stand on is cold and matte,
## `ART_DIRECTION.md`), with the charged shader over it when live. Drawn in code
## until its art is generated.
func _draw() -> void:
	var local := Rect2(-rect.size * 0.5, rect.size)
	if art != null:
		draw_texture_rect(art, local, true)
		return
	draw_rect(local, Palette.STONE_MID)
	draw_rect(Rect2(local.position, Vector2(local.size.x, 2.0)), Palette.STONE_LIT)
	draw_rect(local, Palette.ARC_RESIDUE, false, 1.0)
