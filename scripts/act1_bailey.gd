## Act 1, room 3: the bailey. **It teaches what wood does to a sword**, then
## asks for it once, and it is where the caged dragon is first seen.
##
## Four beats, left to right:
##
##   1. **Two hurdles.** A wooden block and a stone one, both low enough to jump.
##      Throw at the wood and the sword sticks, and holding J brings it home.
##      Throw at the stone and the sword is gone. The chest by the way in makes
##      that a lesson rather than a loss.
##   2. **The cage.** A barred window in the back wall over a quiet stretch of
##      floor, with the dragon chained inside it, lit by its own fire, watching
##      you come. It roars once as you pass. Scenery: it changes nothing about
##      play, and nothing else in the stretch asks for your attention.
##   3. **The yard.** A drop into a yard. Ahead, set into the foot of the far
##      face at throw height, is a wooden switch whose slot glints, and a chain
##      runs from it up the face to the portcullis on the level above. Throw
##      ahead, the switch takes the blade and the chain draws the gate up.
##   4. **The gate.** A ladder up the face, and the open gate to the exit.
##
## The family playtest (2026-10-06) is why it is laid out this way: the switch
## used to sit behind you after the drop, under the cage, and nobody found it;
## the cage was two eyes in a black block, and nobody knew what it was.
##
## Its geometry is a level file, `levels/act1_bailey.level` (`GridRoom`), the
## first room written that way (R3). The cage and the chain are this script.
class_name Act1Bailey
extends GridRoom

const LEVEL := "res://levels/act1_bailey.level"

## The barred window over the quiet stretch: the dragon's first appearance.
const GRATE := Rect2(520.0, 120.0, 176.0, 104.0)
## The dragon is dimmed a little under the playfield, as backgrounds are
## (`ART_DIRECTION.md`), but not much: it is the point of the window.
const DRAGON_SHADE := Color(0.85, 0.78, 0.82)
## Bars far enough apart to see the dragon between them. The portcullis tile
## used to fill the window and hid it completely.
const BAR_PITCH: float = 22.0
const BAR_WIDTH: float = 3.0
const DRAGON_SHEET: Texture2D = preload("res://assets/art/enemies/dragon_chained_sheet.png")
const DRAGON_FRAME := Vector2(95.0, 70.0)
const DRAGON_FRAMES: int = 4
## Where its snout is in a frame, from the frame's left edge before it is
## flipped to face the way you come: smoke rises from here.
const DRAGON_SNOUT := Vector2(84.0, 52.0)

## The chain from the switch to the gate: up the face, along the wall, and
## over a pulley down to the gate's top. How high it runs along the wall.
const LINK_Y: float = 112.0
const LINK_PITCH: float = 4.0

const ATMOSPHERE_CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")

var _clock := 0.0
var _smoke_clock := 0.0
var _glint_clock := 0.0
var _roared := false
## How far the chain has run, px, so its links visibly travel as the gate
## rises and falls.
var _link_run := 0.0
var _switch: SwordSwitch
var _switch_rect := Rect2()
var _gate_rect := Rect2()
var _cage := Node2D.new()
var _smoke := CPUParticles2D.new()


## Where the dragon is drawn: sat on the window's sill, in the middle.
static func dragon_rect() -> Rect2:
	return Rect2(
		Vector2(GRATE.get_center().x - DRAGON_FRAME.x * 0.5, GRATE.end.y - DRAGON_FRAME.y - 2.0),
		DRAGON_FRAME
	)


func _ready() -> void:
	level_file = LEVEL
	super._ready()


## The switch and gate are the map's (`S`, `G`); the light on the switch, the
## cage and its smoke are this room's.
func _built() -> void:
	_switch = switches["S"]
	_switch_rect = level.thing("S").rect
	_gate_rect = level.thing("G").rect
	_switch.add_child(LightSource.point(
		ATMOSPHERE_CONFIG.light_switch_radius, Palette.FIRE_CORE, ATMOSPHERE_CONFIG.light_switch_strength
	))
	# The cage's own light, so the dark of the room does not swallow it.
	_cage.position = dragon_rect().get_center()
	add_child(_cage)
	_cage.add_child(LightSource.point(
		ATMOSPHERE_CONFIG.cage_light_radius, Palette.FIRE_CORE,
		ATMOSPHERE_CONFIG.cage_light_strength, ATMOSPHERE_CONFIG.cage_light_flicker
	))
	_shape_smoke()


func _process(delta: float) -> void:
	var breath := ATMOSPHERE_CONFIG.cage_breath_seconds * DRAGON_FRAMES
	_clock = fmod(_clock + delta, breath)
	_smoke_clock += delta
	if _smoke_clock >= ATMOSPHERE_CONFIG.cage_smoke_period:
		_smoke_clock = 0.0
		_smoke.restart()
	_glint_clock += delta
	if _glint_clock >= ATMOSPHERE_CONFIG.switch_glint_period:
		_glint_clock = 0.0
		if not _switch.is_held:
			Burst.emit(self, Vector2(_switch_rect.position.x, _switch_rect.get_center().y), Burst.Kind.GLINT)
	_listen_for_the_hero()
	var target := 1.0 if _switch.is_held else 0.0
	_link_run = move_toward(_link_run, target * LINK_PITCH * 6.0, LINK_PITCH * 6.0 * delta)
	queue_redraw()


## It roars once, as you come along the quiet stretch beneath it.
func _listen_for_the_hero() -> void:
	if _roared:
		return
	for node in get_tree().get_nodes_in_group("player"):
		var hero := node as Node2D
		if hero != null and absf(hero.global_position.x - _cage.position.x) < ATMOSPHERE_CONFIG.cage_roar_range:
			_roared = true
			Sfx.play(_cage, Sfx.CONFIG.roar)


## A slow puff from its nostrils, drifting up through the bars. Code, not a
## drawn loop (`CLAUDE.md`: atmosphere is code).
func _shape_smoke() -> void:
	_smoke.position = _snout()
	_smoke.one_shot = true
	_smoke.emitting = false
	_smoke.amount = 10
	_smoke.lifetime = 1.8
	_smoke.explosiveness = 0.6
	_smoke.direction = Vector2(-0.4, -1.0)
	_smoke.spread = 20.0
	_smoke.initial_velocity_min = 6.0
	_smoke.initial_velocity_max = 14.0
	_smoke.gravity = Vector2(0.0, -6.0)
	_smoke.scale_amount_min = 2.0
	_smoke.scale_amount_max = 3.0
	var fade := Gradient.new()
	fade.set_color(0, Color(Palette.STONE_LIT, 0.7))
	fade.set_color(1, Color(Palette.STONE_MID, 0.0))
	_smoke.color_ramp = fade
	add_child(_smoke)


## The snout, in the room's coordinates, after the flip to face left.
func _snout() -> Vector2:
	var rect := dragon_rect()
	return Vector2(rect.end.x - DRAGON_SNOUT.x, rect.position.y + DRAGON_SNOUT.y)


func _draw_under() -> void:
	_draw_grate()


func _draw_over() -> void:
	_draw_link()


## The window into the dark: a recess darker than the wall, the dragon chained
## inside it and breathing, and the bars in front.
func _draw_grate() -> void:
	draw_rect(GRATE, Palette.BACKDROP)
	var frame := int(_clock / ATMOSPHERE_CONFIG.cage_breath_seconds) % DRAGON_FRAMES
	var source := Rect2(Vector2(DRAGON_FRAME.x * frame, 0.0), DRAGON_FRAME)
	# Flipped, so it faces the way you come and watches you along the stretch.
	var rect := dragon_rect()
	draw_set_transform(Vector2(rect.end.x + rect.position.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(DRAGON_SHEET, rect, source, DRAGON_SHADE)
	draw_set_transform(Vector2.ZERO)
	var x := GRATE.position.x + BAR_PITCH * 0.5
	while x < GRATE.end.x:
		draw_rect(Rect2(x - BAR_WIDTH * 0.5, GRATE.position.y, BAR_WIDTH, GRATE.size.y), Palette.STONE_DEEP)
		draw_rect(Rect2(x - BAR_WIDTH * 0.5, GRATE.position.y, 1.0, GRATE.size.y), Palette.STONE_MID)
		x += BAR_PITCH
	for y in [GRATE.position.y, GRATE.end.y - BAR_WIDTH]:
		draw_rect(Rect2(GRATE.position.x, y, GRATE.size.x, BAR_WIDTH), Palette.STONE_DEEP)


## The chain that says the switch and the gate are one machine: up the face
## from the switch, along the wall, over a pulley and down to the gate. Gold
## like the switch's plates, and bright with them while a blade holds it; its
## links run toward the gate as it rises.
func _draw_link() -> void:
	var colour: Color = Palette.GOLD_FACE if _switch.is_held else Palette.GOLD_SHADE
	var start := Vector2(_switch_rect.get_center().x, _switch_rect.position.y)
	var corner := Vector2(start.x, LINK_Y)
	var pulley := Vector2(_gate_rect.get_center().x, LINK_Y)
	var gate_top := Vector2(pulley.x, _gate_rect.position.y)
	var run := 0.0
	for leg: Array in [[start, corner], [corner, pulley], [pulley, gate_top]]:
		run = _draw_links(leg[0], leg[1], run, colour)
	draw_circle(pulley, 4.0, Palette.STONE_MID)
	draw_arc(pulley, 4.0, 0.0, TAU, 12, colour, 1.0)


## Links from `from` to `to`, carrying on the spacing from `run`. Returns the
## run at the end, so a chain turning a corner keeps its rhythm.
func _draw_links(from: Vector2, to: Vector2, run: float, colour: Color) -> float:
	var length := from.distance_to(to)
	var along := (to - from) / maxf(length, 0.001)
	var across := Vector2(-along.y, along.x)
	var d := fposmod(LINK_PITCH - fposmod(run + _link_run, LINK_PITCH), LINK_PITCH)
	var i := int((run + _link_run + d) / LINK_PITCH)
	while d < length:
		var at := from + along * d
		# Alternate rings face on and edge on, as a chain does.
		var half := across * (1.5 if i % 2 == 0 else 0.5) + along * 1.5
		draw_line(at - half, at + half, colour, 1.0)
		d += LINK_PITCH
		i += 1
	return run + length
