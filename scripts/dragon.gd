## SPEC.md's fire-breathing dragon: an Act 2 mini-boss, telegraphed cone,
## immobile. The two bosses are both anti-sword on purpose, and this one's
## answer is already sitting in `SwordFlight`: a recalling sword steers
## through geometry and "cannot fail", so a hit that arrives while a sword is
## RECALLING is immune to whatever stopped it getting there. `is_vulnerable_to`
## just says so. Nothing in the sword's own machine changes, the same way
## nothing changed there for the eyeball.
##
## That makes the whole fight a positioning puzzle rather than a new system:
## a FLYING or RETURNING sword bounces off the body like hitting stone (fresh
## ammunition, SPEC.md's mistake), and the only sword that gets through is one
## already embedded in wood past the dragon and called home, which the room
## has to make possible without ever asking the player to throw through the
## body to get there.
##
## The breath is the second half: a ranged reason to keep your distance, on
## its own clock (`DragonBreath`), so panicking and closing in to throw is
## also the wrong answer.
class_name Dragon
extends Enemy

## The pixel-art dragon (`ANIMATION.md`): a slow breathing loop, drawn at 1x,
## crouched and immobile. The art faces right and is mirrored to face the way
## the breath goes. The breath is a flame shader (`shaders/flame.gdshader`)
## over the cone that kills (`DragonBreath.cone`). Honesty about what is lethal
## still comes first: at full breath every pixel of that cone is fire. The plume frays
## a few px past it (`flame_spill`) because a flame cut off square at its
## edges read as a brick (playtest, 2026-10-06), and fire you can see but not
## die to is a mercy, never a trap.
const SPRITE_SCENE: PackedScene = preload("res://scenes/dragon_sprite.tscn")
const FLAME_SHADER: Shader = preload("res://shaders/flame.gdshader")
const ATMOSPHERE: AtmosphereConfig = preload("res://config/atmosphere.tres")

var _elapsed: float = 0.0
var _breath_offset := Vector2.ZERO
var _breath_size := Vector2.ZERO
var phase: DragonBreath.Phase = DragonBreath.Phase.CHARGE

## Built in `place`, not with `@onready`: this node is often configured
## before it is ever added to the tree (see `Bench._add_dragon`), and
## `@onready` would not run until then. `Hazard.configure` and `Geyser.configure`
## make the same choice for the same reason.
var _breath: Area2D
var _flame: ColorRect
## Overpowered: no breath, no bite, chains across it, and no longer an enemy.
var is_chained := false
var _light: LightGlow
var _embers: CPUParticles2D


## `breath_offset` is where the cone sits relative to the dragon's own centre,
## and its sign is the only place this file says which way the dragon faces:
## the room places it, the way a ferry's span decides which way a slab goes.
## The room's box fixes how far the breath reaches. Its near edge is pulled back
## to the snout, so the fire leaves the mouth, and within the box the cone
## (`DragonBreath.cone`) is what kills.
func place(size: Vector2, breath_offset: Vector2, breath_size: Vector2, enemy_config: EnemyConfig) -> void:
	configure(size)
	_config = enemy_config
	var side := signf(breath_offset.x) if not is_zero_approx(breath_offset.x) else 1.0
	var far := absf(breath_offset.x) + breath_size.x * 0.5
	var reach := minf(_config.dragon_snout_reach, far)
	_breath_offset = Vector2(side * (far + reach) * 0.5, breath_offset.y)
	_breath_size = Vector2(far - reach, breath_size.y)
	_breath = _make_breath_area()
	_breath.position = _breath_offset
	# The cone, its jaws at the near edge of the box (`DragonBreath.cone`).
	var cone := DragonBreath.cone(
		_breath_size.x, _breath_size.y, _config.dragon_cone_mouth, _config.dragon_cone_open, side
	)
	var jaws := Vector2(-side * _breath_size.x * 0.5, 0.0)
	for i in cone.size():
		cone[i] += jaws
	(_breath.get_child(0) as CollisionPolygon2D).polygon = cone
	_flame = _make_flame()
	_embers = _make_embers()
	_light = LightGlow.make(ATMOSPHERE.light_breath_radius, Palette.FIRE_FALLOFF, 0.0)
	_light.position += _breath_offset
	add_child(_light)
	add_to_group("mechanisms")


func _make_breath_area() -> Area2D:
	var area := Area2D.new()
	area.add_child(CollisionPolygon2D.new())
	# The player's own layer, per `Hazard.configure`. Not monitorable: nothing
	# needs to find the breath itself, only to be found by it.
	area.collision_layer = 0
	area.collision_mask = 4
	add_child(area)
	return area


func _make_flame() -> ColorRect:
	var rect := ColorRect.new()
	var spill := ATMOSPHERE.flame_spill
	var side := signf(_breath_offset.x) if not is_zero_approx(_breath_offset.x) else 1.0
	# Grown by the spill on the top and the far end, never at the mouth, which
	# is the snout, and never below, which is the floor.
	rect.position = _breath_offset - _breath_size * 0.5 - Vector2(spill if side < 0.0 else 0.0, spill)
	rect.size = _breath_size + Vector2(spill, spill)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	var material := ShaderMaterial.new()
	material.shader = FLAME_SHADER
	material.set_shader_parameter("falloff_colour", Palette.FIRE_FALLOFF)
	material.set_shader_parameter("core_colour", Palette.FIRE_CORE)
	material.set_shader_parameter("hot_colour", Palette.FIRE_HOT)
	material.set_shader_parameter("ember_colour", Palette.LAVA_FLOW)
	material.set_shader_parameter("smoke_colour", Color(Palette.STONE_MID, 0.85))
	material.set_shader_parameter("spill", spill)
	material.set_shader_parameter("cone_mouth", _config.dragon_cone_mouth)
	material.set_shader_parameter("cone_open", _config.dragon_cone_open)
	material.set_shader_parameter("box_size", _breath_size)
	# The mouth is the box's edge nearest the dragon's centre.
	material.set_shader_parameter("direction", signf(_breath_offset.x) if not is_zero_approx(_breath_offset.x) else 1.0)
	material.set_shader_parameter("stream_speed", ATMOSPHERE.flame_stream_speed)
	material.set_shader_parameter("noise_scale", ATMOSPHERE.flame_noise_scale)
	rect.material = material
	# Fire is light, so it draws over the room's dark (`LightField`).
	LightField.emissive(rect)
	add_child(rect)
	return rect


## Sparks flung from the mouth along the breath while it burns. Code, not art.
func _make_embers() -> CPUParticles2D:
	var side := signf(_breath_offset.x) if not is_zero_approx(_breath_offset.x) else 1.0
	var embers := CPUParticles2D.new()
	embers.position = Vector2(_breath_offset.x - side * _breath_size.x * 0.5, _breath_offset.y)
	embers.emitting = false
	embers.lifetime = 0.6
	embers.amount = maxi(int(ATMOSPHERE.flame_embers_per_second * embers.lifetime), 1)
	embers.direction = Vector2(side, -0.15)
	embers.spread = 14.0
	embers.initial_velocity_min = _breath_size.x * 1.2
	embers.initial_velocity_max = _breath_size.x * 2.0
	embers.gravity = Vector2(0.0, -40.0)
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(2.0, _breath_size.y * 0.3)
	var fade := Gradient.new()
	fade.set_color(0, Palette.FIRE_HOT)
	fade.add_point(0.5, Palette.FIRE_CORE)
	fade.set_color(fade.get_point_count() - 1, Color(Palette.LAVA_FLOW, 0.0))
	embers.color_ramp = fade
	LightField.emissive(embers)
	add_child(embers)
	return embers


func _ready() -> void:
	_attach_sprite(SPRITE_SCENE, "idle")
	_face_sprite(signf(_breath_offset.x) if not is_zero_approx(_breath_offset.x) else 1.0)


func _physics_process(delta: float) -> void:
	if _step_dormancy(delta):
		return
	_elapsed += delta
	_update()


func _update() -> void:
	var was := phase
	phase = DragonBreath.phase_at(
		_elapsed, _config.dragon_charge_time, _config.dragon_breathe_time, _config.dragon_rest_time
	)
	if phase != was and phase == DragonBreath.Phase.CHARGE and _elapsed > 0.0:
		# The tell is heard as well as seen: it draws breath, then lets go.
		Sfx.play(self, Sfx.CONFIG.roar)
	if DragonBreath.is_lethal(phase):
		for body in _breath.get_overlapping_bodies():
			var player := body as Player
			if player != null:
				player.die(DeathMessages.Cause.FIRE)
	_show_flame()


## Back to the first frame of the tell, the same bargain `Geyser.reset` makes
## and for the same reason: a respawn that landed mid-breath would be a death
## nobody could have seen coming, which is the punishment M3 exists to remove.
func reset(frozen_for: float) -> void:
	if is_chained:
		return
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	if is_chained:
		return "dragon chained"
	return "dragon %s%s" % [DragonBreath.phase_name(phase), _status_suffix()]


## Not killed: overpowered and chained (Matt, 2026-09-28, `LEVELS.md`). It stops
## breathing and stops killing on contact, chains are drawn across it, and it
## leaves the enemies group, because a chained dragon is scenery you walk past.
## Its sprite travels to the chained strain loop.
## It stays chained through a respawn: `reset` leaves it alone.
func _defeat() -> void:
	is_chained = true
	remove_from_group("enemies")
	set_physics_process(false)
	set_deferred("monitoring", false)
	_breath.set_deferred("monitoring", false)
	_flame.visible = false
	_embers.emitting = false
	_light.set_strength(0.0)
	# The strain loop: the generated chained dragon (`ART.md`), heaving against
	# the rings in the floor. Through its AnimationTree, like every state.
	_sprite_tree["parameters/playback"].travel("chained")


## The one override that makes this a boss rather than a fifth animal: a
## FLYING or RETURNING sword is fresh ammunition and bounces, per SPEC.md. Only
## a sword already RECALLING gets through, because a recall cannot fail.
func is_vulnerable_to(sword: Node2D) -> bool:
	var blade := sword as Sword
	return blade != null and blade.state == SwordFlight.State.RECALLING


## Rest is dark, the charge is the same flame growing, the breath is all of it.
## Only the breath kills, and it is the only phase that fills the box.
func _show_flame() -> void:
	_flame.visible = phase != DragonBreath.Phase.REST
	var intensity := 1.0
	if phase == DragonBreath.Phase.CHARGE:
		intensity = DragonBreath.charge_ramp(
			_elapsed, _config.dragon_charge_time, _config.dragon_breathe_time,
			_config.dragon_rest_time
		) * 0.7
	(_flame.material as ShaderMaterial).set_shader_parameter("intensity", intensity)
	_embers.emitting = DragonBreath.is_lethal(phase)
	# The flame lights the wall and floor around it, most when it is fullest.
	_light.set_strength(ATMOSPHERE.light_breath_strength * intensity if _flame.visible else 0.0)
