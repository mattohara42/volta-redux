## The room's light and dark (`shaders/light_field.gdshader`): one rectangle
## over the camera's view, multiplying everything in the room by the act's
## ambient, a coloured dark, and lifting it back wherever a `LightSource`
## reaches. Purely how it looks: nothing here changes what anything does.
##
## `ART_DIRECTION.md` is pixel art lit by fire and by electricity. Before this,
## lights could only add colour over a room that was lit evenly everywhere, so
## a brazier was a warm patch rather than the reason you could see. Now a room
## is dark in its act's own colour and the braziers you light, the lava and the
## live copper are what push the dark back.
##
## Added by `Bench` to a room that belongs to an act whose `ambient_light` is
## not white. A bench is an instrument and stays lit evenly.
##
## Every number is `config/atmosphere.tres` or the act's `.tres`.
class_name LightField
extends ColorRect

const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")
const SHADER: Shader = preload("res://shaders/light_field.gdshader")
## The shader's own array size. More lights than this in view and the furthest
## from the middle of the screen go unlit, which `_gather` makes the least
## noticeable ones.
const MAX_LIGHTS := 32
## How far past the view the rectangle reaches, art px, so the camera's
## smoothing can never show an unlit edge for a frame.
const MARGIN := 16.0
## Above every room's own drawing, below the HUD and the death message, which
## live on their own canvas layers.
const Z := 100

var _material: ShaderMaterial


## `ambient` multiplies everything no light reaches. `ceiling_dim` darkens the
## top of the room by that fraction more than the floor.
func setup(ambient: Color, ceiling_dim: float, room_height: float = Bench.ROOM_HEIGHT) -> void:
	z_index = Z
	z_as_relative = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("ambient", ambient)
	_material.set_shader_parameter("ceiling_dim", ceiling_dim)
	_material.set_shader_parameter("room_height", room_height)
	_material.set_shader_parameter("steps", CONFIG.light_field_steps)
	_material.set_shader_parameter("flicker_speed", CONFIG.light_flicker_speed)
	material = _material
	add_to_group("light_fields")


func _process(_delta: float) -> void:
	_cover_the_view()
	_gather()


func _cover_the_view() -> void:
	var view := get_viewport_rect().size
	var centre := view * 0.5
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		centre = camera.get_screen_center_position()
		# A camera zoomed out (the capture tool's whole-room shots) sees more.
		view /= camera.zoom
	position = (centre - view * 0.5 - Vector2(MARGIN, MARGIN)).floor()
	size = view + Vector2(MARGIN, MARGIN) * 2.0


## Every shining light whose reach touches the view, nearest the middle first,
## up to the shader's limit.
func _gather() -> void:
	var view := Rect2(position, size)
	var centre := view.get_center()
	var found: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("lights"):
		var light := node as LightSource
		if light == null or not light.is_shining():
			continue
		var ends := light.ends()
		var bounds := Rect2(ends[0], Vector2.ZERO).expand(ends[1]).grow(light.radius)
		if not bounds.intersects(view):
			continue
		var nearest := Geometry2D.get_closest_point_to_segment(centre, ends[0], ends[1])
		found.append({"light": light, "ends": ends, "distance": nearest.distance_squared_to(centre)})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["distance"] < b["distance"])

	var ends_out := PackedVector4Array()
	var colours_out := PackedVector4Array()
	var flickers_out := PackedFloat32Array()
	for entry in found.slice(0, MAX_LIGHTS):
		var light: LightSource = entry["light"]
		var ends: PackedVector2Array = entry["ends"]
		var lit := light.tint * light.strength
		ends_out.append(Vector4(ends[0].x, ends[0].y, ends[1].x, ends[1].y))
		colours_out.append(Vector4(lit.r, lit.g, lit.b, light.radius))
		flickers_out.append(light.flicker)
	# The shader's arrays are fixed size; pad so a shorter list never leaves a
	# stale light from an earlier frame behind its count.
	while ends_out.size() < MAX_LIGHTS:
		ends_out.append(Vector4.ZERO)
		colours_out.append(Vector4.ZERO)
		flickers_out.append(0.0)
	_material.set_shader_parameter("light_count", mini(found.size(), MAX_LIGHTS))
	_material.set_shader_parameter("ends", ends_out)
	_material.set_shader_parameter("colours", colours_out)
	_material.set_shader_parameter("flickers", flickers_out)


## Draws `item` over the room's dark rather than under it, for anything that is
## itself a light: lava, a flame, an arc, a glow. The dark multiplies what is
## under it, and a light source that the dark has dimmed reads as a coloured
## object rather than as the thing doing the lighting.
static func emissive(item: CanvasItem) -> void:
	item.z_index = Z + 1
	item.z_as_relative = false


## How many lights are in play right now, for the capture tool's log.
func status() -> String:
	return "light field, %d light(s) in view" % int(_material.get_shader_parameter("light_count"))
