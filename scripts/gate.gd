## A gate a switch opens.
##
## Solid while shut and not there at all while open. It owns no logic about
## *why* it is open: a room wires a switch to it, which is what keeps a room's
## puzzle inside that room (CLAUDE.md: a room never reaches into another room).
class_name Gate
extends StaticBody2D

## What was last asked for. Whether the bars actually moved is `is_really_open`,
## and the two are not the same claim: this one is set the moment somebody asks.
var is_open := false

var _shape: CollisionShape2D
## A portcullis tile to draw in place of the bench bars, for a real room. Null
## in the benches.
var art: Texture2D = null:
	set(value):
		art = value
		texture_repeat = TEXTURE_REPEAT_ENABLED if value != null else TEXTURE_REPEAT_PARENT_NODE
		queue_redraw()
## How much of a raised portcullis still shows at the top of its opening.
const RAISED_SHOWING: float = 6.0


## Builds its own collision rather than being handed one, so nothing depends on
## what a node added in code ends up being named. A `$CollisionShape2D` lookup
## here found nothing, because Godot names an unnamed child `@ClassName@N`.
func configure(size: Vector2) -> void:
	_shape = CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	_shape.shape = box
	add_child(_shape)


func _ready() -> void:
	add_to_group("gates")


func set_open(open: bool) -> void:
	if open == is_open or _shape == null:
		return
	is_open = open
	# Deferred because a switch reports during physics, and a body cannot change
	# its own collision mid-step. It lands on the next frame.
	_shape.set_deferred("disabled", is_open)
	queue_redraw()


## Whether the bars are **actually** out of the way, read off the collision
## shape rather than off what was last requested.
##
## These came apart once already: `set_open` set `is_open` and then failed to
## reach the shape, so the gate reported open while staying solid, and the room
## was unfinishable in a way its own log line denied. Anything reporting on a
## gate should ask this one.
func is_really_open() -> bool:
	return _shape != null and _shape.disabled


## Drawn as the bars it is, so an open gate reads as an opening rather than as
## something that vanished.
func _draw() -> void:
	if _shape == null:
		return
	var shape := _shape.shape as RectangleShape2D
	var rect := Rect2(-shape.size * 0.5, shape.size)
	if art != null:
		# Raised, only its teeth show under the lintel; dropped, it fills the way.
		var shown := Rect2(rect.position, Vector2(rect.size.x, RAISED_SHOWING)) if is_open else rect
		draw_texture_rect_region(art, shown, Rect2(Vector2(0.0, rect.size.y - shown.size.y), shown.size))
		return
	if is_open:
		# The frame stays. Only the bars go.
		draw_rect(rect, Color(Palette.STONE_DEEP, 0.35))
		draw_rect(rect, Color(Palette.STONE_MID, 0.5), false, 1.0)
		return
	draw_rect(rect, Palette.STONE_DEEP)
	var bars := maxi(int(rect.size.x / 7.0), 2)
	for i in range(1, bars):
		var x := rect.position.x + rect.size.x * float(i) / float(bars)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Palette.STONE_LIT, 2.0)
	draw_rect(rect, Palette.STONE_LIT, false, 1.0)
