## A hollow stump in the forest (`LEVELS.md` → *Stump portals*, decision 8):
## land on the top of one and you come up out of another somewhere else in the
## level. One way only, so it reads as something that happens to you rather
## than as a door you use. It works every time, so dying past it never costs
## you the way it gave you.
##
## The stump itself is wood, built by `Bench._add_stump`, so a sword bites it
## like any other wood. This node is only the hollow on top and the watch on
## it. A stump with no `to` is just a stump, which is what a warp comes out of.
class_name Stump
extends Node2D

## The stump's whole rect, in the room's coordinates.
var rect := Rect2()
## Where a warp puts the hero's feet, or null for a stump that goes nowhere.
var to: Variant = null

var _was_standing := false


func _physics_process(_delta: float) -> void:
	if to == null:
		return
	var standing := false
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player == null or player.is_dead() or not player.is_on_floor():
			continue
		var feet := player.global_position + Vector2(0.0, player.world.hero_height * 0.5)
		if absf(feet.y - rect.position.y) <= 2.0 and feet.x >= rect.position.x and feet.x <= rect.end.x:
			standing = true
			# Landing on it, never standing there already: a hero put on a stump
			# by a respawn is not sent anywhere until they jump on it again.
			if not _was_standing:
				_send(player, to as Vector2)
				standing = false
	_was_standing = standing


func _send(player: Player, feet: Vector2) -> void:
	Burst.emit(get_parent(), Vector2(rect.get_center().x, rect.position.y), Burst.Kind.CHIPS)
	player.warp_to(feet)
	Burst.emit(get_parent(), feet, Burst.Kind.CHIPS)
	Sfx.play(self, Sfx.CONFIG.crumble)


## A trunk, not a crate: bark running up it, roots flaring at its foot, and a
## dark hollow in its top, the same on every stump, so which one a stump leads
## to is found by jumping on it. Drawn in code until the forest has art (G2).
func _draw() -> void:
	var r := Rect2(rect.position - position, rect.size)
	draw_rect(r, Palette.WOOD_DEEP)
	var x := r.position.x + 3.0
	while x < r.end.x - 2.0:
		draw_line(Vector2(x, r.position.y + 4.0), Vector2(x, r.end.y), Palette.WOOD_FACE, 1.0)
		x += 5.0
	for side: float in [-1.0, 1.0]:
		var foot := Vector2(r.position.x if side < 0.0 else r.end.x, r.end.y)
		draw_colored_polygon(PackedVector2Array([
			foot + Vector2(side * 4.0, 0.0), foot, foot + Vector2(0.0, -8.0),
		]), Palette.WOOD_DEEP)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 4.0)), Palette.WOOD_FACE)
	draw_rect(Rect2(r.position + Vector2(4.0, 1.0), Vector2(r.size.x - 8.0, 3.0)), Palette.BACKDROP)
