## Shared plumbing for the Phase 1 grey benches.
##
## **These are instruments, not rooms.** Their geometry is generated from
## `WorldConfig` so that distances stay multiples of tier height and tile size
## when those numbers change. The real rooms in Phase 3 are authored scenes
## built on a tileset (`BUILD_PLAN.md` → M10), and they do not extend this.
class_name Bench
extends Node2D

@export var world: WorldConfig
## Only the benches that place a spike bed wire this. Lava needs no shape
## tuning, so most rooms leave it null and never ask for it.
@export var hazards: HazardConfig
## Only the benches that place an enemy wire this.
@export var enemies: EnemyConfig

const ROOM_HEIGHT: float = 360.0
const FLOOR_TOP: float = 320.0
const SLAB: float = 24.0
const LADDER_WIDTH: float = 16.0
## A ladder overshoots the ledge it serves, so you climb above the surface and
## step onto it rather than stopping level with it and falling off.
const LADDER_OVERSHOOT: float = 28.0
## How much of a spike tooth is drawn as its lit point. Purely how it looks, so
## it stays here rather than in `config/hazards.tres` with the numbers that
## decide whether it kills you.
const TIP_FRACTION: float = 0.6

var _solids: Array[Rect2] = []
var _ladders: Array[Rect2] = []
var _woods: Array[Rect2] = []
var _lavas: Array[Rect2] = []
var _spike_beds: Array[Rect2] = []


func _add_solid(rect: Rect2) -> StaticBody2D:
	_solids.append(rect)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
	return body


## Solid like anything else, and in the "wood" group so a sword can tell. Wood
## is not its own physics layer: it is ordinary geometry that happens to bite,
## and a layer would mean every room declaring it solid twice.
func _add_wood(rect: Rect2, drawn := true) -> void:
	_add_solid(rect).add_to_group("wood")
	# Drawn as wood rather than stone, so it comes back out of the stone list.
	_solids.remove_at(_solids.size() - 1)
	# `drawn` is false for wood that paints itself, like a switch, which would
	# otherwise get plank grain drawn underneath it.
	if drawn:
		_woods.append(rect)


## Lava. Not solid: you fall into it and it kills you, which is the whole of
## SPEC.md's hazard design and the reason `Hazard` has no other behaviour.
##
## Drawn flat here. ART_DIRECTION.md and BUILD_PLAN.md M9 both say bubbling lava
## is a scrolling noise displacement plus an emitter plus heat haze, and that
## drawing it as a PNG loop is a bug in the approach. A grey-box rectangle is
## neither, and M9 replaces this.
func _add_lava(rect: Rect2) -> Hazard:
	_lavas.append(rect)
	var hazard := Hazard.new()
	hazard.configure(rect.size)
	hazard.position = rect.get_center()
	add_child(hazard)
	return hazard


## A bed of spikes standing on the surface at `surface_y`, `count` teeth wide,
## with its left-hand tooth starting at `x`.
##
## A room gives it a surface and a number of teeth rather than a rectangle,
## because the rectangle is made of `config/hazards.tres` and a room that
## carried its own pixel height would go stale the moment M14 retunes the teeth.
##
## What is drawn and what kills are not the same rectangle here, which is the
## one thing about spikes worth being careful with. See `Spikes.lethal_box`.
func _add_spikes(surface_y: float, x: float, count: int) -> Hazard:
	if hazards == null:
		# A bench copied without the resource would place an invisible box that
		# kills, which is a worse bug than having no spikes at all.
		push_error("bench: a spike bed needs config/hazards.tres wired into the scene")
		return null
	var bed := Spikes.bed_on(
		surface_y, x, count, hazards.spike_tooth_pitch, hazards.spike_tooth_height
	)
	_spike_beds.append(bed)
	var lethal := Spikes.lethal_box(bed, hazards.spike_tooth_pitch, hazards.spike_grace)
	var hazard := Hazard.new()
	hazard.configure(lethal.size)
	hazard.position = lethal.get_center()
	add_child(hazard)
	return hazard


## A platform that lets go once you stand on it, with its top face at
## `rect.position.y`. It falls until it is out of the room and then comes back.
##
## The room owns where it is and how far it has to fall, because both are facts
## about the room: `FallingPlatform` knows what it does and not where it is.
func _add_falling_platform(rect: Rect2) -> FallingPlatform:
	if hazards == null:
		# A bench copied without the resource would place a slab with no clock
		# in it, which reads as ordinary floor and is a worse bug than no
		# platform at all.
		push_error("bench: a falling platform needs config/hazards.tres wired into the scene")
		return null
	var platform := FallingPlatform.new()
	# Far enough to be below the room, plus its own depth so nothing is left
	# poking up into the gap it used to fill.
	platform.configure(rect.size, ROOM_HEIGHT - rect.position.y + rect.size.y, hazards)
	platform.position = rect.get_center()
	add_child(platform)
	return platform


## A ferry: a platform that crosses `travel` and comes back, on a clock that
## started before the player did and has no trigger on it at all. `rect` is
## where it sits at the near end of that trip, with its top face at
## `rect.position.y`.
##
## The room owns where it goes and how far, for the same reason it owns a
## falling platform's drop: both are facts about the moat, and `MovingPlatform`
## knows what it does rather than where it is.
func _add_moving_platform(rect: Rect2, travel: Vector2) -> MovingPlatform:
	if hazards == null:
		# A bench copied without the resource would place a slab with no clock
		# in it, which reads as ordinary floor over a moat nobody can cross.
		push_error("bench: a moving platform needs config/hazards.tres wired into the scene")
		return null
	var platform := MovingPlatform.new()
	platform.configure(rect.size, travel, hazards)
	platform.position = rect.get_center()
	add_child(platform)
	return platform


## A geyser filling the shaft `column`. Its bottom face is the surface the jet
## comes out of and its top face is as high as the jet can carry anything.
##
## The room owns both, for the same reason it owns a ferry's span and a falling
## slab's drop: how far a mechanism moves you is a fact about the place it was
## put, and `Geyser` knows what it does rather than where it is.
func _add_geyser(column: Rect2) -> Geyser:
	if hazards == null:
		# A bench copied without the resource would place a shaft with no clock in
		# it, which is a way up that never comes and a room nobody can finish.
		push_error("bench: a geyser needs config/hazards.tres wired into the scene")
		return null
	var geyser := Geyser.new()
	geyser.configure(column.size, hazards)
	geyser.position = column.get_center()
	add_child(geyser)
	# Behind the hero, like a brazier and for the same reason. A jet is the one
	# mechanism in M3 that the hero is inside rather than on top of, and
	# ART_DIRECTION.md makes silhouette a rule rather than a taste: drawn over the
	# capsule, a column hides the thing the player is steering.
	move_child(geyser, 0)
	return geyser


## A bat, tumbling a Lissajous path inside a box centred on `rect`. `rect`'s
## size is the killing box and `half_extents` is how far it is allowed to roam
## either side of that centre, which is a fact about the room the way a
## ferry's span is.
func _add_bat(rect: Rect2, half_extents: Vector2) -> Bat:
	if enemies == null:
		# A bench copied without the resource would place a bat with no path,
		# which stands still, which is not a bat.
		push_error("bench: a bat needs config/enemies.tres wired into the scene")
		return null
	var bat := Bat.new()
	bat.place(rect.size, half_extents, enemies)
	bat.position = rect.get_center()
	add_child(bat)
	return bat


## A scorpion, walking from `rect`'s centre out to `range` and back. `rect`'s
## size is its killing box, and the room owns `range` for the same reason it
## owns a ferry's span: how far a patrol goes is a fact about the floor it is
## walking, not about what a scorpion does.
func _add_scorpion(rect: Rect2, range: float) -> Scorpion:
	if enemies == null:
		push_error("bench: a scorpion needs config/enemies.tres wired into the scene")
		return null
	var scorpion := Scorpion.new()
	scorpion.place(rect.size, range, enemies)
	scorpion.position = rect.get_center()
	add_child(scorpion)
	return scorpion


## A giant ant, walking the inside of `track` forever. `size` is its killing
## box; `track` is the loop itself, already pulled in from the walls by
## however far the ant's own body sits off them, the same way a spike bed's
## lethal box is inset from the drawn teeth.
func _add_ant(size: Vector2, track: Rect2) -> GiantAnt:
	if enemies == null:
		push_error("bench: an ant needs config/enemies.tres wired into the scene")
		return null
	var ant := GiantAnt.new()
	ant.place(size, track, enemies)
	add_child(ant)
	return ant


## A floating eyeball, starting at `rect`'s centre and drifting to stay level
## with the hero for as long as it is inside `roam`. `rect`'s size is its
## killing box.
func _add_eyeball(rect: Rect2, roam: Rect2) -> Eyeball:
	if enemies == null:
		push_error("bench: an eyeball needs config/enemies.tres wired into the scene")
		return null
	var eyeball := Eyeball.new()
	eyeball.place(rect.size, roam, enemies)
	eyeball.position = rect.get_center()
	add_child(eyeball)
	return eyeball


## A dragon, its body at `rect`, breathing into `breath_size` centred
## `breath_offset` from its own centre. All three are the room's to decide,
## the way a ferry's span and a geyser's shaft are: what the dragon does is
## `Dragon`'s, where it does it to is the arena's.
func _add_dragon(rect: Rect2, breath_offset: Vector2, breath_size: Vector2) -> Dragon:
	if enemies == null:
		push_error("bench: a dragon needs config/enemies.tres wired into the scene")
		return null
	var dragon := Dragon.new()
	dragon.place(rect.size, breath_offset, breath_size, enemies)
	dragon.position = rect.get_center()
	add_child(dragon)
	return dragon


## A brazier standing on the floor at `base`, which is a point on a surface and
## not a rectangle: a brazier has no extent you can collide with, only a place
## it stands and a zone that notices you went past.
func _add_brazier(base: Vector2) -> Brazier:
	var brazier := Brazier.new()
	brazier.configure()
	brazier.position = base
	add_child(brazier)
	# Behind the hero. A room's own `_draw` runs before any child, so the only
	# thing child order decides is which mechanism paints over which, and a
	# brazier bowl is at chest height: left last in the list it hides the hero
	# standing at the checkpoint it just put them at.
	move_child(brazier, 0)
	return brazier


## A switch, sized to `rect`, with its detection area grown past the block so a
## sword resting against its face registers. It is wood, so a throw bites it.
func _add_switch(rect: Rect2) -> SwordSwitch:
	_add_wood(rect, false)
	var switch := SwordSwitch.new()
	switch.configure(rect.size)
	switch.position = rect.get_center()
	add_child(switch)
	return switch


## A gate. Solid until something opens it, and it is the room that decides what.
func _add_gate(rect: Rect2) -> Gate:
	var gate := Gate.new()
	gate.configure(rect.size)
	gate.position = rect.get_center()
	add_child(gate)
	return gate


## How many swords this room hands you, for a room whose puzzle depends on the
## count. Call it from `_ready`: the player is a child, so it is already up.
func _hand_out_swords(count: int) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player != null:
			player.set_swords_at_spawn(count)


## `top` is the surface the ladder serves; it is drawn reaching above that.
func _add_ladder(x: float, top: float, bottom: float) -> void:
	var rect := Rect2(x, top - LADDER_OVERSHOOT, LADDER_WIDTH, bottom - top + LADDER_OVERSHOOT)
	_ladders.append(rect)
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	area.position = rect.get_center()
	# Layer 2 is ladders and nothing else, so the player's probe can watch for
	# them without hearing about the world geometry.
	area.collision_layer = 2
	area.collision_mask = 0
	area.add_to_group("ladders")
	area.add_child(shape)
	add_child(area)


## Walls and a ceiling, so nothing leaves the instrument.
func _add_enclosure(width: float) -> void:
	_add_solid(Rect2(-SLAB, 0.0, SLAB, ROOM_HEIGHT))
	_add_solid(Rect2(width, 0.0, SLAB, ROOM_HEIGHT))
	_add_solid(Rect2(-SLAB, -SLAB, width + SLAB * 2.0, SLAB))


## The room owns the camera bounds, not the player. A player scene carrying one
## room's width cannot be dropped into a room of another size, which is exactly
## what happened when the M1 bench inherited the M0 bench's 1600.
func _frame_camera(width: float) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		for child in node.get_children():
			var camera := child as Camera2D
			if camera == null:
				continue
			camera.limit_left = 0
			camera.limit_top = 0
			camera.limit_right = int(width)
			camera.limit_bottom = int(ROOM_HEIGHT)


func _draw_bench(width: float) -> void:
	draw_rect(Rect2(0.0, 0.0, width, ROOM_HEIGHT), Palette.BACKDROP)
	for rect in _solids:
		draw_rect(rect, Palette.STONE_MID)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), Palette.STONE_LIT)
	for rect in _woods:
		draw_rect(rect, Palette.WOOD_DEEP)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), Palette.WOOD_FACE)
		# Grain, so wood reads as wood at 40 px and not as brown stone. Vertical
		# on a plank taller than it is wide, horizontal otherwise.
		var along_y := rect.size.y > rect.size.x
		var span := rect.size.x if along_y else rect.size.y
		var count := int(span / 9.0)
		for i in range(1, count):
			var t := float(i) / float(count)
			if along_y:
				var x := rect.position.x + rect.size.x * t
				draw_line(
					Vector2(x, rect.position.y), Vector2(x, rect.end.y),
					Palette.WOOD_FACE, 1.0
				)
			else:
				var y := rect.position.y + rect.size.y * t
				draw_line(
					Vector2(rect.position.x, y), Vector2(rect.end.x, y),
					Palette.WOOD_FACE, 1.0
				)
	for rect in _lavas:
		# Darkest at the crust, brightest in the fissures, which is the value
		# order ART_DIRECTION.md gives lava. Flat bands stand in for the shader.
		draw_rect(rect, Palette.LAVA_CRUST)
		draw_rect(
			Rect2(rect.position + Vector2(0.0, 3.0), Vector2(rect.size.x, rect.size.y - 3.0)),
			Palette.LAVA_FLOW
		)
		var fissures := int(rect.size.x / 18.0)
		for i in fissures:
			var x := rect.position.x + 18.0 * float(i) + 9.0
			draw_line(
				Vector2(x, rect.position.y + 4.0), Vector2(x, rect.position.y + 11.0),
				Palette.LAVA_FISSURE, 2.0
			)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Palette.LAVA_CORE)
	_draw_spike_beds()
	for rect in _ladders:
		# Cold and matte, with gold rungs. ART_DIRECTION.md reserves warm and
		# saturated for things that kill you, and a ladder is the opposite of
		# that, so a warm ladder teaches the player to read the room backwards.
		draw_rect(rect, Palette.STONE_DEEP)
		var rungs := int(rect.size.y / 12.0)
		for i in rungs:
			var y := rect.position.y + 12.0 * float(i) + 6.0
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Palette.GOLD_FACE, 2.0)
	_draw_ruler()


## The teeth, tooth by tooth, with a lit point on each.
##
## ART_DIRECTION.md gives spikes a dark warm body and a bright tip, and the
## reason the tip is a separate polygon rather than a line is that the point is
## what the player is reading: a row of lit points says "do not land here" from
## across the room, and a uniformly coloured triangle does not.
func _draw_spike_beds() -> void:
	for bed in _spike_beds:
		for tooth in Spikes.teeth(bed, hazards.spike_tooth_pitch):
			draw_colored_polygon(tooth, Palette.SPIKE_IRON)
			var apex := tooth[1]
			draw_colored_polygon(
				PackedVector2Array([
					tooth[0].lerp(apex, TIP_FRACTION), apex, tooth[2].lerp(apex, TIP_FRACTION)
				]),
				Palette.SPIKE_TIP
			)


## A height scale against the left wall, because "did that clear a tier" should
## be answered by looking rather than by arithmetic.
func _draw_ruler() -> void:
	var font := ThemeDB.fallback_font
	var y := FLOOR_TOP
	while y > 0.0:
		var height_above_floor := FLOOR_TOP - y
		var is_tier := is_zero_approx(fmod(height_above_floor, world.tier_height))
		var length := 26.0 if is_tier else 10.0
		var colour: Color = Palette.STONE_LIT if is_tier else Palette.STONE_MID
		draw_line(Vector2(0.0, y), Vector2(length, y), colour, 1.0)
		if is_tier and height_above_floor > 0.0:
			draw_string(
				font, Vector2(length + 4.0, y + 4.0), "%d" % int(height_above_floor),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Palette.STONE_LIT
			)
		y -= world.tile_size
