## A gem set on a small wooden shelf hung out of reach (`SPEC.md` → *Act 4*,
## room 1). A sword that flies through the shelf knocks it away and the gem
## drops to `floor_y`, where it can be picked up. The sword flies on: it cut a
## cord, it did not hit a wall.
class_name GemShelf
extends Node2D

## How long the gem takes to fall, seconds. Presentation, not tuning.
const FALL_TIME: float = 0.35

var is_cut := false
## The shelf, in the room's coordinates.
var rect := Rect2()

var _gem: Gem
var _floor_y := 0.0
var _hang_from := 0.0
var _last := {}


func configure(shelf: Rect2, floor_y: float, hang_from: float) -> void:
	rect = shelf
	_floor_y = floor_y
	_hang_from = hang_from
	_gem = Gem.new()
	_gem.position = Vector2(shelf.get_center().x, shelf.position.y)
	add_child(_gem)
	add_to_group("gem_shelves")


func _physics_process(_delta: float) -> void:
	if is_cut:
		return
	var seen := {}
	for node in get_tree().get_nodes_in_group("swords"):
		var sword := node as Sword
		if sword == null:
			continue
		var id := sword.get_instance_id()
		var now := sword.global_position
		seen[id] = now
		if Circuit.crosses(_last.get(id, now), now, rect):
			_cut()
			return
	_last = seen


func status() -> String:
	return "shelf %s" % ("CUT" if is_cut else "holding")


func _cut() -> void:
	is_cut = true
	queue_redraw()
	if is_instance_valid(_gem):
		var tween := create_tween()
		tween.tween_property(_gem, "position:y", _floor_y, FALL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## A chain from above down to a plank, while it holds; only the chain after.
func _draw() -> void:
	var x := rect.get_center().x
	var chain_end := rect.position.y if not is_cut else _hang_from + 24.0
	draw_line(Vector2(x, _hang_from), Vector2(x, chain_end), Palette.STONE_LIT, 1.0)
	if not is_cut:
		draw_rect(rect, Palette.WOOD_DEEP)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Palette.WOOD_FACE)
