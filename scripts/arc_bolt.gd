## An electric arc between two points: a fresh jagged bolt many times a second,
## hard-edged, with a fork now and then and sparks at both ends. Cool and thin
## against a world that is warm and soft, which is `ART_DIRECTION.md`'s whole
## reason for electricity looking like this.
##
## Purely how it looks. What an arc does to the hero is the generator's, in M12,
## and its box will be the room's, the way a dragon's cone is.
##
## Every number is `config/atmosphere.tres`, every colour is `Palette`, and the
## shape of one bolt is `ArcPath`, so a test can hold it.
class_name ArcBolt
extends Node2D

const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _main := PackedVector2Array()
var _fork := PackedVector2Array()
var _clock: float = 0.0
var _seed: int = 0
var _light: LightGlow


## Both ends in this node's own coordinates.
func setup(from: Vector2, to: Vector2, start_seed: int = 1) -> void:
	_from = from
	_to = to
	_seed = start_seed
	# An arc is light, so it draws over the room's dark (`LightField`).
	LightField.emissive(self)
	add_child(_sparks(from))
	add_child(_sparks(to))
	var radius := CONFIG.light_arc_radius + from.distance_to(to) * 0.35
	_light = LightGlow.make(radius, Palette.ARC_RESIDUE, CONFIG.light_arc_strength)
	_light.position += (from + to) * 0.5
	add_child(_light)
	Sfx.loop_on(self, Sfx.CONFIG.arc_loop, (from + to) * 0.5)
	_reshape()


func _process(delta: float) -> void:
	_clock += delta
	var period := 1.0 / maxf(CONFIG.arc_flicker_hz, 1.0)
	if _clock >= period:
		_clock = fmod(_clock, period)
		_seed += 1
		_reshape()


func _reshape() -> void:
	# A new bolt is a new flash: the light jumps with it instead of holding steady.
	_light.set_strength(CONFIG.light_arc_strength * (0.6 + 0.4 * float(_seed % 3) / 2.0))
	_main = ArcPath.bolt(_from, _to, _seed, CONFIG.arc_subdivisions, CONFIG.arc_jag)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 31 + 7
	_fork = PackedVector2Array()
	if rng.randf() < CONFIG.arc_fork_chance:
		_fork = ArcPath.fork(_main, _seed, CONFIG.arc_fork_length, CONFIG.arc_subdivisions, CONFIG.arc_jag)
	queue_redraw()


## A halo, the bolt, then a one-pixel core, each on the pixel grid: lines of odd
## width centred on a pixel's middle land exactly on whole pixels.
func _draw() -> void:
	for path in [_main, _fork]:
		if path.size() < 2:
			continue
		var centred := PackedVector2Array()
		for point in path:
			centred.append(point + Vector2(0.5, 0.5))
		draw_polyline(centred, Palette.ARC_RESIDUE, 3.0)
		draw_polyline(centred, Palette.ARC, 1.0 if path == _fork else 2.0)
		draw_polyline(centred, Palette.ARC_CORE, 1.0)


## Sparks spat off an end of the bolt: single pixels, cyan to nothing.
func _sparks(at: Vector2) -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.position = at
	sparks.amount = maxi(CONFIG.arc_sparks, 1)
	sparks.lifetime = 0.35
	sparks.explosiveness = 0.5
	sparks.direction = Vector2.UP
	sparks.spread = 180.0
	sparks.initial_velocity_min = 18.0
	sparks.initial_velocity_max = 50.0
	sparks.gravity = Vector2(0.0, 60.0)
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.set_color(0, Palette.ARC_CORE)
	ramp.set_color(1, Color(Palette.ARC, 0.0))
	sparks.color_ramp = ramp
	return sparks
