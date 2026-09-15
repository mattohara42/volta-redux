## A switch that senses weight rather than a socket a blade goes into.
##
## `SwordSwitch` is a wall fixture a thrown sword bites. This is the floor kind
## `BACKLOG.md` asked for: something standing on it holds it down, and unlike
## the wall switch it does not care what is doing the standing. The hero's own
## weight, an enemy's, or a spent sword left lying on it all count, because a
## plate does not ask who or what is heavy, only whether something is.
##
## Polls rather than listens, for the same reason `SwordSwitch` does: a body
## can already be standing on the plate the instant it is asked, with no
## enter signal to have fired.
class_name FloorPlate
extends Area2D

## True while something is weighing it down.
signal held_changed(is_held: bool)

var is_held := false

var _size := Vector2.ZERO


## Builds its own collision rather than being handed one, so nothing depends on
## what a node added in code ends up being named. See `SwordSwitch.configure`.
func configure(size: Vector2) -> void:
	_size = size
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	add_child(shape)


func _ready() -> void:
	add_to_group("plates")
	# The player's own layer, plus enemies (an Area2D layer, see Enemy) and
	# swords (to see a grounded one lying across it). Not the world layer:
	# the plate does not care what solid ground it is bolted to.
	collision_layer = 0
	collision_mask = 4 | Enemy.ENEMY_LAYER | 8


func _physics_process(_delta: float) -> void:
	var held := _is_weighted()
	if held == is_held:
		return
	is_held = held
	held_changed.emit(is_held)
	queue_redraw()


func _is_weighted() -> bool:
	for body in get_overlapping_bodies():
		if body is Player:
			return true
	for area in get_overlapping_areas():
		if area is Enemy:
			return true
		var sword := area as Sword
		if sword != null and SwordFlight.rests_on_a_plate(sword.state):
			return true
	return false


## Stone that sinks a hair when weighted, so the tell is the plate itself
## moving rather than only a colour change. Gold reserved for what the
## player throws or embeds, per ART_DIRECTION.md; a plate is stood on, not
## thrown at, so it stays in the cold, matte register everything standable
## uses.
func _draw() -> void:
	if _size == Vector2.ZERO:
		return
	var sink := 2.0 if is_held else 0.0
	var rect := Rect2(-_size.x * 0.5, -_size.y * 0.5 + sink, _size.x, _size.y - sink)
	draw_rect(rect, Palette.STONE_DEEP)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Palette.STONE_LIT)
