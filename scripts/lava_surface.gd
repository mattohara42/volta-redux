## Lava, as `ART_DIRECTION.md` and `BUILD_PLAN.md` M9 describe it: a scrolling
## warped noise on a gradient (`shaders/lava.gdshader`), embers rising off it, a
## heat haze shimmering above it and its warm light thrown up the wall. Nothing
## here is a texture, and all of it is quantised to the art-pixel grid.
##
## Purely how it looks. What kills is the `Hazard` a room places under it, and
## the two are the same rectangle on purpose.
##
## Every number is `config/atmosphere.tres`; every colour is `Palette`.
class_name LavaSurface
extends Node2D

const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")
const LAVA_SHADER: Shader = preload("res://shaders/lava.gdshader")
const HAZE_SHADER: Shader = preload("res://shaders/heat_haze.gdshader")
const GLOW_SHADER: Shader = preload("res://shaders/glow.gdshader")


## `rect` is the lava's own box in the room's coordinates. Builds its layers,
## back to front: the wall's glow, the lava, the embers, the haze over the top.
func setup(rect: Rect2) -> void:
	position = rect.position
	# The glow, the lava and the embers are light, so they draw over the room's
	# dark (`LightField`). The haze stays under it and above everything else
	# in the room, because it shifts what is already drawn.
	for layer: CanvasItem in [_glow(rect.size.x), _body(rect.size), _embers(rect.size.x)]:
		LightField.emissive(layer)
		add_child(layer)
	add_child(_haze(rect.size.x))
	# Its roar, heard near it: across the whole pit, not only at its middle.
	Sfx.loop_on(self, Sfx.CONFIG.lava_loop, Vector2(rect.size.x * 0.5, 0.0), rect.size.x * 0.5)
	# Its light along the whole surface, so the room's dark draws back from the
	# pit end to end rather than from one spot over its middle (`LightField`).
	add_child(LightSource.line(
		Vector2.ZERO, Vector2(rect.size.x, 0.0), CONFIG.light_lava_radius,
		Palette.FIRE_CORE, CONFIG.light_lava_strength
	))


func _rect(at: Vector2, size: Vector2, shader: Shader) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	return rect


func _body(size: Vector2) -> ColorRect:
	var rect := _rect(Vector2.ZERO, size, LAVA_SHADER)
	var m := rect.material as ShaderMaterial
	m.set_shader_parameter("crust_colour", Palette.LAVA_CRUST)
	m.set_shader_parameter("flow_colour", Palette.LAVA_FLOW)
	m.set_shader_parameter("fissure_colour", Palette.LAVA_FISSURE)
	m.set_shader_parameter("core_colour", Palette.LAVA_CORE)
	m.set_shader_parameter("scroll_speed", CONFIG.lava_scroll_speed)
	m.set_shader_parameter("noise_scale", CONFIG.lava_noise_scale)
	m.set_shader_parameter("warp_strength", CONFIG.lava_warp)
	m.set_shader_parameter("flow_cut", CONFIG.lava_flow_cut)
	m.set_shader_parameter("fissure_cut", CONFIG.lava_fissure_cut)
	m.set_shader_parameter("core_cut", CONFIG.lava_core_cut)
	m.set_shader_parameter("hot_depth", CONFIG.lava_hot_depth)
	m.set_shader_parameter("bubble_cell", CONFIG.lava_bubble_cell)
	m.set_shader_parameter("bubble_rate", CONFIG.lava_bubble_rate)
	m.set_shader_parameter("crest_depth", CONFIG.lava_crest_depth)
	return rect


func _haze(width: float) -> ColorRect:
	var rect := _rect(Vector2(0.0, -CONFIG.haze_height), Vector2(width, CONFIG.haze_height), HAZE_SHADER)
	var m := rect.material as ShaderMaterial
	m.set_shader_parameter("band_height", CONFIG.haze_height)
	m.set_shader_parameter("max_shift", CONFIG.haze_shift)
	m.set_shader_parameter("speed", CONFIG.haze_speed)
	m.set_shader_parameter("frequency", CONFIG.haze_frequency)
	return rect


## A dome of light over the lava, wider than the pit by half its own height each
## side, so the wall above it is lit and the light fades out before any edge.
func _glow(width: float) -> ColorRect:
	var margin := CONFIG.glow_height * 0.5
	var size := Vector2(width + margin * 2.0, CONFIG.glow_height)
	var rect := _rect(Vector2(-margin, -CONFIG.glow_height), size, GLOW_SHADER)
	var m := rect.material as ShaderMaterial
	m.set_shader_parameter("tint", Palette.FIRE_FALLOFF)
	m.set_shader_parameter("band_size", size)
	m.set_shader_parameter("strength", CONFIG.glow_strength)
	return rect


## Sparks and embers lifting off the surface. Two art pixels square, so they
## are pixels and not points, and cooling from hot to crust as they rise.
func _embers(width: float) -> CPUParticles2D:
	var embers := CPUParticles2D.new()
	embers.position = Vector2(width * 0.5, 0.0)
	embers.amount = maxi(int(CONFIG.ember_per_100px * width / 100.0), 1)
	embers.lifetime = CONFIG.ember_lifetime
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(width * 0.5, 1.0)
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.initial_velocity_min = CONFIG.ember_speed_min
	embers.initial_velocity_max = CONFIG.ember_speed_max
	embers.gravity = Vector2(0.0, CONFIG.ember_gravity)
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, Palette.FIRE_HOT)
	ramp.set_color(1, Color(Palette.LAVA_CRUST, 0.0))
	ramp.add_point(0.55, Palette.LAVA_FISSURE)
	embers.color_ramp = ramp
	return embers
