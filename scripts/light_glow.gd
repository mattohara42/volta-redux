## A coloured point light, as a rectangle carrying `shaders/light.gdshader`.
## Purely how it looks: it lights the picture and changes nothing about play.
##
## `ART.md`: the light layer is what makes generated and painted layers one
## picture, because the same coloured light falls across all of them. Braziers,
## the dragon's breath and arcs each make one of these instead of drawing their
## own halo, so a light looks the same wherever it is.
##
## Every number is `config/atmosphere.tres`; every colour is `Palette`.
class_name LightGlow
extends ColorRect

const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")
const LIGHT_SHADER: Shader = preload("res://shaders/light.gdshader")

var _source: LightSource


## A light centred on the origin of whatever it is added to.
static func make(radius: float, tint: Color, strength: float, flicker: float = 0.0) -> LightGlow:
	var light := LightGlow.new()
	light.size = Vector2(radius, radius) * 2.0
	light.position = -light.size * 0.5
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = LIGHT_SHADER
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("strength", strength)
	material.set_shader_parameter("flicker", flicker)
	material.set_shader_parameter("flicker_speed", CONFIG.light_flicker_speed)
	light.material = material
	# The same light, told to the room's `LightField`, so the dark draws back
	# from wherever a glow is: the glow adds the colour, the field lifts the dark.
	light._source = LightSource.point(radius, tint, strength, flicker)
	light._source.position = light.size * 0.5
	light.add_child(light._source)
	LightField.emissive(light)
	return light


## Brighter or dimmer without rebuilding it, for a light that swells and fades.
func set_strength(strength: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("strength", strength)
	if _source != null:
		_source.strength = strength
