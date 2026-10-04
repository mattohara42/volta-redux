## A surface with current in it (`shaders/charged.gdshader`), for Act 3's
## conductive floors. How it looks only: which floors conduct is the room's.
class_name ChargedSurface
extends ColorRect

const SHADER: Shader = preload("res://shaders/charged.gdshader")


## `rect` in the room's coordinates.
func setup(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Current is light, so it draws over the room's dark (`LightField`).
	LightField.emissive(self)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	shader_material.set_shader_parameter("base_colour", Palette.STONE_DEEP)
	shader_material.set_shader_parameter("filament_colour", Palette.ARC)
	shader_material.set_shader_parameter("core_colour", Palette.ARC_CORE)
	shader_material.set_shader_parameter("crawl_speed", 0.9)
	shader_material.set_shader_parameter("noise_scale", 0.16)
	shader_material.set_shader_parameter("line_width", 0.035)
	material = shader_material
