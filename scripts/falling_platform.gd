## A slab that holds you for as long as it feels like it.
##
## The clock and every transition in it live in `PlatformCycle`, where a headless
## test can reach them. This script is the part that cannot be pure: it senses
## being stood on, it moves a body, and it draws.
##
## The body it is, and the fact that a respawn puts it back, are `Platform`:
## those are what it has in common with the ferry in the next moat over. What is
## its own is the sensing, the clock and the picture.
class_name FallingPlatform
extends Platform

## How tall the strip that notices you is, in design px. It sits on the top
## surface, so a jump that clears the slab does not arm it and a foot that lands
## on it does.
const SENSOR_HEIGHT: float = 5.0
## Fraction of the slab's depth the cracked underside takes up when it is drawn.
## Purely how it looks, so it stays here rather than in `config/hazards.tres`
## with the numbers that decide whether you fall.
const FAULT_FRACTION: float = 0.45

## Read by the overlay and by `tools/capture.gd`. What it is doing now.
var phase: PlatformCycle.Phase = PlatformCycle.Phase.STEADY

## How far it falls before it counts as out of the room. The room knows this and
## this script does not, because it depends on where the room put it.
var _drop: float = 0.0
## Seconds since something stood on it, or -1 when nothing has.
var _elapsed: float = -1.0
## How many landings it takes before the one that arms it. Zero for an
## ordinary slab; a level sets it (`slab holds=1`).
var holds := 0
## Landings since it was last at rest, the arming one included.
var _landings := 0


## Built in code rather than handed a scene, like every other mechanism in the
## benches. `drop` is how far below home it has to get before it is gone.
func configure(size: Vector2, drop: float, hazards: HazardConfig) -> void:
	_drop = drop
	_build(size, hazards)

	# The strip that notices a foot. An Area2D rather than asking the player what
	# it is standing on: the player owns no list of what it touches, and adding
	# one so a platform could read it would put this mechanism's rule inside the
	# hero.
	var sensor := Area2D.new()
	var sensor_shape := CollisionShape2D.new()
	var sensor_box := RectangleShape2D.new()
	sensor_box.size = Vector2(size.x, SENSOR_HEIGHT)
	sensor_shape.shape = sensor_box
	sensor.add_child(sensor_shape)
	# Up from the top face, so standing on it registers and being carried inside
	# it does not.
	sensor.position = Vector2(0.0, -(size.y + SENSOR_HEIGHT) * 0.5)
	# The player is layer 3 (`collision_layer = 4` in player.tscn) and that is
	# the only thing this watches. A thrown sword crossing the gap is not a foot.
	sensor.collision_layer = 0
	sensor.collision_mask = 4
	sensor.monitorable = false
	sensor.body_entered.connect(_on_body_entered)
	add_child(sensor)


func _physics_process(delta: float) -> void:
	if _elapsed < 0.0 or config == null:
		return
	_elapsed += delta
	var fall := PlatformCycle.fall_seconds(_drop, config.platform_fall_gravity)
	var was := phase
	phase = PlatformCycle.phase_at(
		_elapsed, config.platform_warn_time, fall, config.platform_return_time
	)
	position = _home + PlatformCycle.offset_at(
		_elapsed, config.platform_warn_time, fall, config.platform_return_time,
		config.platform_fall_gravity, config.platform_shake, config.platform_shake_hz
	)
	if phase != was:
		# Deferred: a body cannot change its own collision in the middle of a
		# physics step. Same reason `Gate` defers, and it lands next frame.
		_shape.set_deferred("disabled", not PlatformCycle.is_solid(phase))
		if phase == PlatformCycle.Phase.STEADY:
			_rest()
		elif phase == PlatformCycle.Phase.SHAKING or phase == PlatformCycle.Phase.FALLING:
			# Grit off its underside as it cracks, and again as it lets go.
			Burst.emit(get_parent(), global_position, Burst.Kind.DEBRIS)
			if phase == PlatformCycle.Phase.SHAKING:
				Sfx.play(self, Sfx.CONFIG.crumble, true)
		queue_redraw()
	elif phase == PlatformCycle.Phase.SHAKING:
		queue_redraw()


## Stood on. One arming only: a platform already on its way out is not armed
## again by somebody landing on it as it goes.
func _on_body_entered(body: Node2D) -> void:
	if _elapsed >= 0.0 or (body as Player) == null:
		return
	_landings += 1
	if not PlatformCycle.arms_on(_landings, holds):
		# It holds this time, and says so: grit and a creak, no shake.
		Burst.emit(get_parent(), global_position, Burst.Kind.DEBRIS)
		Sfx.play(self, Sfx.CONFIG.crumble, true)
		return
	_elapsed = 0.0
	queue_redraw()


## Back at home and load bearing, with no part of the cycle left to run. See
## `Platform.reset` for why a respawn does this at all. Nothing here is running
## until somebody stands on it, so there is no freeze to sit out.
func reset(_frozen_for: float) -> void:
	_elapsed = -1.0
	_landings = 0
	phase = PlatformCycle.Phase.STEADY
	if _shape != null:
		_shape.set_deferred("disabled", false)
	_rest()
	queue_redraw()


func _rest() -> void:
	_elapsed = -1.0
	position = _home


func status() -> String:
	return PlatformCycle.phase_name(phase)


## Cold and matte, because ART_DIRECTION.md reserves warm and saturated for what
## kills you and this does not kill you: the lava under it does.
##
## So the tell has to be shape. A floor slab is a solid block with a lit top
## edge, and this is a thinner one with a fault line through it and a bitten-off
## underside, which is the silhouette of a thing that has already half gone.
## Whether that reads at 40 px is a screenshot question and not a test question.
func _draw() -> void:
	if _draw_art():
		return
	var rect := Rect2(-_size * 0.5, _size)
	draw_rect(rect, Palette.STONE_MID)
	# The lit top edge every solid in the benches has, so it reads as a surface
	# you stand on rather than as an object floating in the gap.
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Palette.STONE_LIT)
	# The fault: the underside is a shade the floor never uses, and the crack
	# runs up out of it to the standing surface.
	var fault := rect.size.y * FAULT_FRACTION
	draw_rect(
		Rect2(rect.position + Vector2(0.0, rect.size.y - fault), Vector2(rect.size.x, fault)),
		Palette.STONE_DEEP
	)
	var step := rect.size.x / 5.0
	for i in range(1, 5):
		var x := rect.position.x + step * float(i)
		# Alternating lean, so the cracks read as a break and not as grouting.
		var lean := 2.0 if i % 2 == 0 else -2.0
		draw_line(
			Vector2(x, rect.end.y), Vector2(x + lean, rect.position.y + 2.0),
			Palette.STONE_DEEP, 1.0
		)
	if phase == PlatformCycle.Phase.SHAKING:
		# Dust off the underside. The shake moves the slab and the dust says
		# which way it is about to go, which the shake on its own does not.
		var falling := clampf(_elapsed / maxf(config.platform_warn_time, 0.0001), 0.0, 1.0)
		for i in 4:
			var x := rect.position.x + step * (float(i) + 0.5)
			draw_line(
				Vector2(x, rect.end.y),
				Vector2(x, rect.end.y + 3.0 + 5.0 * falling),
				Color(Palette.STONE_LIT, 0.35 * falling), 1.0
			)
