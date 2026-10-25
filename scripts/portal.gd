## The original's portal (`LEVELS.md`, Decisions 2026-10-25), which replaces
## the forest's one-way stumps. Two doors, far apart, take turns to open
## (`PortalCycle`): run into the open one and you come out of the other,
## still moving the same way. It is for getting somewhere you cannot
## otherwise reach, and each end is placed somewhere dangerous, so going and
## coming back are each a risk.
##
## One node owns both doors, because the pair shares one clock. It sits at
## the room's origin and both doors are rects in the room's own coordinates.
## A doorway is not solid: you run into it, not onto it.
##
## The look is a placeholder until the door sheet is cut in (`ART.md`, *The
## portal's doors*): a stone frame, a slab that slides up out of the way, and
## behind it a gold light, gold because a door you can use is interactive
## (`ART_DIRECTION.md`). The light is a `LightSource`, so it lights the room.
class_name Portal
extends Node2D

## How far, px, the light inside an open door reaches into the room.
const LIGHT_RADIUS := 48.0
const LIGHT_STRENGTH := 0.6
## The frame's thickness round the opening, px.
const FRAME := 3.0
## The width of each band of light inside an open door, px.
const BAND := 4.0

var doors: Array[Rect2] = []
var _config: HazardConfig
var _elapsed := 0.0
## The door the hero last came out of, which does not take him again until
## he has stepped out of it. -1 for neither.
var _arrived := PortalCycle.NEITHER
var _lights: Array[LightSource] = []


func configure(first: Rect2, second: Rect2, hazard_config: HazardConfig) -> void:
	doors = [first, second]
	_config = hazard_config
	add_to_group("mechanisms")
	for door in doors:
		var light := LightSource.point(LIGHT_RADIUS, Palette.GOLD_FACE, 0.0)
		light.position = door.get_center()
		add_child(light)
		_lights.append(light)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var open := PortalCycle.open_door(_elapsed, _config.portal_open_time, _config.portal_gap_time)
	for i in doors.size():
		_lights[i].strength = LIGHT_STRENGTH * _openness(i)
	queue_redraw()
	var hero := get_tree().get_first_node_in_group("player") as Player
	if hero == null or hero.is_dead():
		return
	var body := Rect2(
		hero.global_position - Vector2(hero.world.hero_width, hero.world.hero_height) * 0.5,
		Vector2(hero.world.hero_width, hero.world.hero_height)
	)
	if _arrived != PortalCycle.NEITHER and not PortalCycle.in_doorway(body, doors[_arrived]):
		_arrived = PortalCycle.NEITHER
	if open == PortalCycle.NEITHER or open == _arrived:
		return
	if PortalCycle.in_doorway(body, doors[open]):
		var other := 1 - open
		hero.pass_through(PortalCycle.foot_of(doors[other]))
		_arrived = other
		Burst.emit(get_parent(), doors[open].get_center(), Burst.Kind.SPARKLE)
		Burst.emit(get_parent(), doors[other].get_center(), Burst.Kind.SPARKLE)
		Sfx.play(self, Sfx.CONFIG.crumble)


## The clock goes back to its start, parked for the hero's freeze, like every
## other timed mechanism a respawn puts back.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_arrived = PortalCycle.NEITHER


func _openness(door: int) -> float:
	return PortalCycle.openness(
		_elapsed, door, _config.portal_open_time, _config.portal_gap_time, _config.portal_swing_time
	)


func is_open(door: int) -> bool:
	return PortalCycle.open_door(_elapsed, _config.portal_open_time, _config.portal_gap_time) == door


func _draw() -> void:
	for i in doors.size():
		var door := doors[i]
		draw_rect(door.grow(FRAME), Palette.STONE_MID)
		# Light through the doorway, banded on the pixel grid as the room's
		# own light is: shade at the frame, face, then a hot core.
		draw_rect(door, Palette.GOLD_SHADE)
		draw_rect(door.grow(-BAND), Palette.GOLD_FACE)
		draw_rect(door.grow(-BAND * 2.0), Palette.FIRE_HOT)
		var open := _openness(i)
		var slab := Rect2(door.position, Vector2(door.size.x, door.size.y * (1.0 - open)))
		draw_rect(slab, Palette.STONE_DEEP)
		# The slab's runes, a column of notches, so a shut door reads as a
		# door and not as wall.
		var y := slab.position.y + 6.0
		while y < slab.end.y - 4.0:
			draw_rect(Rect2(slab.get_center().x - 1.0, y, 2.0, 3.0), Palette.STONE_LIT)
			y += 8.0
