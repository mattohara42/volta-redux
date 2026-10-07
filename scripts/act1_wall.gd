## Act 1, level 2: the outer wall to the castle gate (G2). The old wall, bailey
## and gate rooms are its sections, left to right:
##
##   1. **The climb.** Three storeys of the outer wall, a ladder up each face
##      and bats round them. A ladder is where you cannot throw, so the order
##      is yours.
##   2. **The wall walk.** A skeleton asleep on it, then the gatehouse: a
##      passage roofed too low to jump its guard. The sill before it is the
##      lesson: standing on it, a throw lands in the top of the scorpion and
##      kills it whichever way it faces. The map's cells are 16 px and the sill
##      needs a 5 to 16 px step, so the map marks where it is (`T`) and says
##      how high, and this script builds it.
##   3. **The breach.** The walk is gone over a spike pit, bridged by slabs that
##      fall. Or the high road: up the gatehouse tower and across the
##      scaffolds above, past two bats, and down a ladder past the breach.
##   4. **The bailey.** A wooden hurdle and a stone one (wood holds a sword,
##      stone breaks it), the caged dragon over a quiet stretch, and a yard
##      whose switch is ahead of you and raises the gate on the level above.
##   5. **The ditch.** The far side is out of a jump's reach and faced with a
##      wooden hoarding: throw into it and stand on your own sword, with a bat
##      working the air over the ledge.
##   6. **The gate yard.** The castle stands on a plinth whose face, ahead of
##      you, is the switch; the gate on it is Act 1's way out.
##
## The cage, the sill and the chain from each switch to its gate are this
## script; everything else is `levels/act1_wall.level` (`GridRoom`).
class_name Act1Wall
extends GridRoom

const LEVEL := "res://levels/act1_wall.level"

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

## The chain from a switch to its gate runs this far above the gate's top.
const LINK_RISE: float = 16.0
const LINK_PITCH: float = 4.0

const ATMOSPHERE_CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")

var _clock := 0.0
var _smoke_clock := 0.0
var _glint_clock := 0.0
var _roared := false
## Each switch and the gate it opens, by the switch's anchor: the switch,
## its rect, the gate's rect, and how far its chain has run (px), so the
## links visibly travel as the gate rises and falls.
var _links: Array[Dictionary] = []
var _grate := Rect2()
var _cage := Node2D.new()
var _smoke := CPUParticles2D.new()


## The step a sill (`T sill height=12`) stands for: the bottom of its cells,
## as high as it says.
static func sill_rect(cells: Rect2, height: float) -> Rect2:
	return Rect2(cells.position.x, cells.end.y - height, cells.size.x, height)


## Where the dragon is drawn: sat on the window's sill, in the middle.
static func dragon_rect(grate: Rect2) -> Rect2:
	return Rect2(
		Vector2(grate.get_center().x - DRAGON_FRAME.x * 0.5, grate.end.y - DRAGON_FRAME.y - 2.0),
		DRAGON_FRAME
	)


func _ready() -> void:
	level_file = LEVEL
	super._ready()


func _built() -> void:
	for t in level.of_kind("sill"):
		_add_solid(sill_rect(t.rect, t.number("height", 0.0)))
	for t in level.of_kind("switch"):
		var gate := level.thing(String(t.params.get("opens", "")))
		var switch: SwordSwitch = switches[t.anchor]
		_links.append({"switch": switch, "rect": t.rect, "gate": gate.rect, "run": 0.0})
		switch.add_child(LightSource.point(
			ATMOSPHERE_CONFIG.light_switch_radius, Palette.FIRE_CORE, ATMOSPHERE_CONFIG.light_switch_strength
		))
	_grate = level.thing("D").rect
	# The cage's own light, so the dark of the level does not swallow it.
	_cage.position = dragon_rect(_grate).get_center()
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
	var glint := _glint_clock >= ATMOSPHERE_CONFIG.switch_glint_period
	if glint:
		_glint_clock = 0.0
	for link in _links:
		var switch: SwordSwitch = link["switch"]
		var rect: Rect2 = link["rect"]
		if glint and not switch.is_held:
			# Both switches face the yard they are thrown at from, on their left.
			Burst.emit(self, Vector2(rect.position.x, rect.get_center().y), Burst.Kind.GLINT)
		var target := LINK_PITCH * 6.0 if switch.is_held else 0.0
		link["run"] = move_toward(link["run"], target, LINK_PITCH * 6.0 * delta)
	_listen_for_the_hero()
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


## The snout, in the level's coordinates, after the flip to face left.
func _snout() -> Vector2:
	var rect := dragon_rect(_grate)
	return Vector2(rect.end.x - DRAGON_SNOUT.x, rect.position.y + DRAGON_SNOUT.y)


func _draw_under() -> void:
	_draw_grate()


func _draw_over() -> void:
	for t in level.of_kind("sill"):
		TileArt.draw_ground(self, sill_rect(t.rect, t.number("height", 0.0)), _tiles)
	for link in _links:
		_draw_link(link)


## The window into the dark: a recess darker than the wall, the dragon chained
## inside it and breathing, and the bars in front.
func _draw_grate() -> void:
	draw_rect(_grate, Palette.BACKDROP)
	var frame := int(_clock / ATMOSPHERE_CONFIG.cage_breath_seconds) % DRAGON_FRAMES
	var source := Rect2(Vector2(DRAGON_FRAME.x * frame, 0.0), DRAGON_FRAME)
	# Flipped, so it faces the way you come and watches you along the stretch.
	var rect := dragon_rect(_grate)
	draw_set_transform(Vector2(rect.end.x + rect.position.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(DRAGON_SHEET, rect, source, DRAGON_SHADE)
	draw_set_transform(Vector2.ZERO)
	var x := _grate.position.x + BAR_PITCH * 0.5
	while x < _grate.end.x:
		draw_rect(Rect2(x - BAR_WIDTH * 0.5, _grate.position.y, BAR_WIDTH, _grate.size.y), Palette.STONE_DEEP)
		draw_rect(Rect2(x - BAR_WIDTH * 0.5, _grate.position.y, 1.0, _grate.size.y), Palette.STONE_MID)
		x += BAR_PITCH
	for y in [_grate.position.y, _grate.end.y - BAR_WIDTH]:
		draw_rect(Rect2(_grate.position.x, y, _grate.size.x, BAR_WIDTH), Palette.STONE_DEEP)


## The chain that says a switch and its gate are one machine: up the face
## from the switch, along, over a pulley and down to the gate. Gold like the
## switch's plates, and bright with them while a blade holds it; its links
## run toward the gate as it rises.
func _draw_link(link: Dictionary) -> void:
	var switch: SwordSwitch = link["switch"]
	var switch_rect: Rect2 = link["rect"]
	var gate_rect: Rect2 = link["gate"]
	var colour: Color = Palette.GOLD_FACE if switch.is_held else Palette.GOLD_SHADE
	var link_y := gate_rect.position.y - LINK_RISE
	var start := Vector2(switch_rect.get_center().x, switch_rect.position.y)
	var corner := Vector2(start.x, link_y)
	var pulley := Vector2(gate_rect.get_center().x, link_y)
	var gate_top := Vector2(pulley.x, gate_rect.position.y)
	var run := 0.0
	for leg: Array in [[start, corner], [corner, pulley], [pulley, gate_top]]:
		run = _draw_links(leg[0], leg[1], run, link["run"], colour)
	draw_circle(pulley, 4.0, Palette.STONE_MID)
	draw_arc(pulley, 4.0, 0.0, TAU, 12, colour, 1.0)


## Links from `from` to `to`, carrying on the spacing from `run`. Returns the
## run at the end, so a chain turning a corner keeps its rhythm.
func _draw_links(from: Vector2, to: Vector2, run: float, travel: float, colour: Color) -> float:
	var length := from.distance_to(to)
	var along := (to - from) / maxf(length, 0.001)
	var across := Vector2(-along.y, along.x)
	var d := fposmod(LINK_PITCH - fposmod(run + travel, LINK_PITCH), LINK_PITCH)
	var i := int((run + travel + d) / LINK_PITCH)
	while d < length:
		var at := from + along * d
		# Alternate rings face on and edge on, as a chain does.
		var half := across * (1.5 if i % 2 == 0 else 0.5) + along * 1.5
		draw_line(at - half, at + half, colour, 1.0)
		d += LINK_PITCH
		i += 1
	return run + length
