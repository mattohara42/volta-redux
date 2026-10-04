## A live field (`SPEC.md` → *Conduct*, Matt 2026-10-04). Current hung between
## two posts: it kills the hero like any live metal, and any sword whose path
## crosses it while it is live is destroyed, recalled ones included. So a sword
## left on the far side of one is a sword you recall before you cross, or lose.
##
## A conductor in every other way, so a room can power it from a source or put
## it in a circuit. It is not metal a sword can bite and it is not solid: the
## hero walks into it, which is the point.
class_name Barrier
extends Conductor

## Where each sword was last frame, by instance id, so a fast sword cannot step
## over a field a few pixels wide.
var _last := {}


func configure(area: Rect2, source: bool = false) -> void:
	super.configure(area, source)
	remove_from_group("metal")
	collision_layer = 0
	collision_mask = 0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var seen := {}
	for node in get_tree().get_nodes_in_group("swords"):
		var sword := node as Sword
		if sword == null:
			continue
		var id := sword.get_instance_id()
		var now := sword.global_position
		seen[id] = now
		if is_live and Circuit.crosses(_last.get(id, now), now, rect):
			sword.fry()
	_last = seen


## Two posts and the field between them. The field itself is the charged
## shader `Conductor` shows while live; dead, only the posts are left and a
## faint line where it was.
func _draw() -> void:
	var local := Rect2(-rect.size * 0.5, rect.size)
	var post := Vector2(rect.size.x + 4.0, 4.0)
	draw_rect(Rect2(Vector2(-post.x * 0.5, local.position.y), post), Palette.STONE_LIT)
	draw_rect(Rect2(Vector2(-post.x * 0.5, local.end.y - post.y), post), Palette.STONE_LIT)
	if not is_live:
		draw_line(Vector2(0.0, local.position.y + post.y), Vector2(0.0, local.end.y - post.y), Palette.ARC_RESIDUE, 1.0)
