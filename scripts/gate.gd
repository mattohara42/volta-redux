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
## How long the bars take to wind up, and to drop, seconds. Purely how it
## looks: the gate is passable or solid the moment it is asked, so the drop is
## fast, because bars still on their way down are already in the way.
const RISE_SECONDS: float = 0.35
const DROP_SECONDS: float = 0.08

## How far down the drawn bars are, 0 raised to 1 dropped, chasing `is_open`.
var _drop := 1.0
## False until the first frame has drawn, so a room that opens a gate while it
## is still setting up shows it open rather than winding up as the room appears.
var _settled := false


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


func _process(delta: float) -> void:
	var target := 0.0 if is_open else 1.0
	if not _settled:
		_settled = true
		_drop = target
		# A gate opened before this first frame (a hero placed on its plate)
		# was last drawn dropped: without this it stays drawn that way.
		queue_redraw()
		return
	if is_equal_approx(_drop, target):
		return
	var speed := 1.0 / (RISE_SECONDS if is_open else DROP_SECONDS)
	_drop = move_toward(_drop, target, speed * delta)
	queue_redraw()


func set_open(open: bool) -> void:
	if open == is_open or _shape == null:
		return
	is_open = open
	# Deferred because a switch reports during physics, and a body cannot change
	# its own collision mid-step. It lands on the next frame.
	_shape.set_deferred("disabled", is_open)
	# Grit shaken out of the slot the bars run in, once the room is running.
	var box := _shape.shape as RectangleShape2D
	if box != null and is_inside_tree() and _settled:
		Burst.emit(get_parent(), global_position - Vector2(0.0, box.size.y * 0.5), Burst.Kind.DEBRIS)
		Sfx.play(self, Sfx.CONFIG.gate)
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
		# Between the two while it winds up or drops.
		var height := lerpf(RAISED_SHOWING, rect.size.y, _drop)
		var shown := Rect2(rect.position, Vector2(rect.size.x, height))
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
