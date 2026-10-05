## A checkpoint you light by walking past it.
##
## The counterweight to `Hazard`. That one kills you and this one decides where
## that costs you from, and between them they are the whole of SPEC.md's bargain:
## keep the 1984 lethality, throw away the 1984 punishment.
##
## Lighting is one way. Walking back past a brazier you already lit does nothing,
## which is what makes "the last lit brazier" mean the furthest one you reached
## rather than the last one you brushed.
class_name Brazier
extends Area2D

## How far past the bowl you still count as walking past it. A brazier you have
## to stand exactly on is a brazier you run past at full speed and miss, and
## finding out you missed it costs a death to discover.
const REACH: float = 16.0
## How tall the sensing box is, measured up from the floor. Covers the hero at
## every size in `Player.HERO_HEIGHT_STEPS`, so a jump over it still lights it.
const TRIGGER_HEIGHT: float = 56.0

const POST_WIDTH: float = 6.0
const POST_HEIGHT: float = 18.0
const BOWL_WIDTH: float = 22.0
const BOWL_HEIGHT: float = 9.0
## Tallest tongue of flame, in px above the rim. Kept under the hero's height
## so a lit brazier does not out-shout the thing the player is meant to watch.
const FLAME_HEIGHT: float = 18.0

const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")

## True once it has been walked past. There is no way back to false: SPEC.md has
## no mechanic that puts a brazier out.
var is_lit := false

## Flame animation phase, in radians. Only advances while lit.
var _flicker := 0.0


## Builds its own collision rather than being handed one, so nothing depends on
## what a node added in code ends up being named. A `$CollisionShape2D` lookup
## here found nothing, because Godot names an unnamed child `@ClassName@N`.
func configure() -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(BOWL_WIDTH + REACH * 2.0, TRIGGER_HEIGHT)
	shape.shape = box
	# Up from the floor, because the origin is the foot and a box centred on it
	# would sense the hero's ankles through the floor below.
	shape.position = Vector2(0.0, -TRIGGER_HEIGHT * 0.5)
	add_child(shape)
	# The player is layer 3 (`collision_layer = 4` in player.tscn) and that is
	# the only thing this watches.
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	add_to_group("braziers")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not is_lit:
		return
	_flicker = fmod(_flicker + delta, TAU)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if is_lit:
		return
	var player := body as Player
	if player == null:
		return
	is_lit = true
	_add_light()
	var bowl := global_position + Vector2(0.0, -POST_HEIGHT - BOWL_HEIGHT)
	Burst.emit(get_parent(), bowl, Burst.Kind.FLARE)
	Sfx.play(self, Sfx.CONFIG.brazier)
	add_child(Embers.rising(Vector2(0.0, -POST_HEIGHT - BOWL_HEIGHT - FLAME_HEIGHT * 0.5), BOWL_WIDTH * 0.3))
	player.light_checkpoint(global_position)
	queue_redraw()


## The light a lit brazier throws over the wall, the floor and the hero, so the
## same amber falls across every layer. It sits at the flame.
func _add_light() -> void:
	var light := LightGlow.make(
		CONFIG.light_brazier_radius, Palette.FIRE_FALLOFF,
		CONFIG.light_brazier_strength, CONFIG.light_brazier_flicker
	)
	light.position += Vector2(0.0, -POST_HEIGHT - BOWL_HEIGHT - FLAME_HEIGHT * 0.4)
	add_child(light)


## Gold **before** it is lit, not after.
##
## ART_DIRECTION.md names a brazier as one of the three mechanisms that has to
## say what it wants while the player is still deciding. M2's switch was built
## the other way round, read as a crate, and the person who built the room could
## not find it. So: a gold bowl from across the room with dark fuel piled in it,
## and lighting it swaps the fuel for the flame and changes nothing else.
##
## The first version of this was a plain gold cup with a hairline of fuel in it
## and it read as a trophy. The fuel is what makes it a brazier, so the fuel is
## drawn proud of the rim.
func _draw() -> void:
	var bowl_top := -POST_HEIGHT - BOWL_HEIGHT

	# The post, with a lit edge down one side. ART_DIRECTION.md separates form
	# by value, and a single flat gold is a silhouette with nothing inside it.
	draw_rect(
		Rect2(-POST_WIDTH * 0.5, -POST_HEIGHT, POST_WIDTH, POST_HEIGHT),
		Palette.GOLD_SHADE
	)
	draw_line(
		Vector2(-POST_WIDTH * 0.5 + 1.0, -POST_HEIGHT),
		Vector2(-POST_WIDTH * 0.5 + 1.0, 0.0),
		Palette.GOLD_FACE, 1.0
	)
	# The foot, so the post does not appear to grow out of the floor tile.
	draw_rect(Rect2(-POST_WIDTH, -3.0, POST_WIDTH * 2.0, 3.0), Palette.GOLD_SHADE)

	# The bowl, wider at the lip than at the stem, which is the shape that says
	# "something goes in here" at 40 px.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-BOWL_WIDTH * 0.5, bowl_top),
			Vector2(BOWL_WIDTH * 0.5, bowl_top),
			Vector2(BOWL_WIDTH * 0.25, bowl_top + BOWL_HEIGHT),
			Vector2(-BOWL_WIDTH * 0.25, bowl_top + BOWL_HEIGHT),
		]),
		Palette.GOLD_SHADE
	)
	draw_line(
		Vector2(-BOWL_WIDTH * 0.5, bowl_top), Vector2(BOWL_WIDTH * 0.5, bowl_top),
		Palette.GOLD_FACE, 2.0
	)

	if is_lit:
		_draw_flame(bowl_top)
	else:
		_draw_fuel(bowl_top)


## Cold fuel, proud of the rim. Warm and saturated is reserved for what kills
## you and an unlit brazier is the most harmless thing in the room, so the logs
## are umber and matte: the shape has to carry this, not the colour.
func _draw_fuel(bowl_top: float) -> void:
	var logs: Array[Vector2] = [
		Vector2(-BOWL_WIDTH * 0.30, -3.0),
		Vector2(BOWL_WIDTH * 0.30, -3.0),
		Vector2(0.0, -5.0),
	]
	for offset in logs:
		draw_line(
			Vector2(offset.x - 4.0, bowl_top + 1.0),
			Vector2(offset.x + 4.0, bowl_top + offset.y),
			Palette.WOOD_DEEP, 3.0
		)


## Amber to honey-cream at the source, never to white (ART_DIRECTION.md). Three
## tongues, each leaning on its own phase, so the silhouette moves without the
## colour ever leaving the firelight ramp.
##
## ART_DIRECTION.md: atmosphere is code, and M9 replaces this with an emitter
## and a shader. It moves because a brazier that does not reads as lit in a
## screenshot and as scenery in motion, and a checkpoint you do not notice is
## not doing its job.
func _draw_flame(bowl_top: float) -> void:
	Flame.draw(self, Vector2(0.0, bowl_top), BOWL_WIDTH * 0.40, FLAME_HEIGHT, _flicker)
