## A room's far layers, drawn by a shader until a painted background replaces
## them (`ART.md` → *Four layers*): Act 2's caverns, Act 3's works and Act 4's
## hall each get two layers of parallax behind the playfield, so a room reads
## as a place with depth rather than a flat colour behind the stone.
##
## Atmosphere is code (`CLAUDE.md`): the silhouettes are noise and arithmetic
## on the art-pixel grid, no texture is loaded, and every colour is a mix of
## `Palette`'s own. `ART_DIRECTION.md`'s "backgrounds lose" is held by
## `test_backdrop.gd`: nothing here is as bright as the stone you stand on.
##
## Added by `Bench` to a room whose act names a style. It sits under the room's
## own drawing and under the `LightField`, so a brazier's light falls on it too.
class_name Backdrop
extends ColorRect

enum Style { NONE, CAVERN, WORKS, HALL }

const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")
const SHADERS: Dictionary = {
	Style.CAVERN: preload("res://shaders/backdrop_cavern.gdshader"),
	Style.WORKS: preload("res://shaders/backdrop_works.gdshader"),
	Style.HALL: preload("res://shaders/backdrop_hall.gdshader"),
}
## Under everything in the room, its own `_draw` included.
const Z := -100
## Past the view each side, so camera smoothing never shows an edge.
const MARGIN := 16.0
## How far into the pattern a room may start, art px. Whole, so the offset
## never puts a silhouette edge between pixels.
const PATTERN_SPAN := 4096

var style := Style.NONE
var _material: ShaderMaterial


## `room_seed` picks where in the pattern the room starts. Any number will do;
## the same number always gives the same room.
func setup(backdrop_style: Style, room_seed: int = 0) -> void:
	style = backdrop_style
	z_index = Z
	z_as_relative = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = SHADERS[style]
	_material.set_shader_parameter("room_height", Bench.ROOM_HEIGHT)
	_material.set_shader_parameter("pattern_offset", float(posmod(room_seed, PATTERN_SPAN)))
	_material.set_shader_parameter("far_depth", CONFIG.backdrop_far_depth)
	_material.set_shader_parameter("near_depth", CONFIG.backdrop_near_depth)
	var colours := colours_for(style)
	for key: String in colours:
		_material.set_shader_parameter(key, colours[key])
	for key: String in motion_for(style):
		_material.set_shader_parameter(key, motion_for(style)[key])
	material = _material


## Every colour a style draws with, by uniform name. All mixes of `Palette`,
## so the backdrop cannot drift off the palette, and all checked by a test.
static func colours_for(backdrop_style: Style) -> Dictionary:
	var air := Palette.BACKDROP
	match backdrop_style:
		Style.CAVERN:
			return {
				"air_top": air,
				"air_bottom": air.lerp(Palette.LAVA_CRUST, 0.4),
				"far_rock": air.lerp(Palette.STONE_DEEP, 0.6),
				"near_rock": air.darkened(0.4),
				"rim": air.lerp(Palette.FIRE_FALLOFF, 0.4),
				"fall_dark": air.lerp(Palette.LAVA_CRUST, 0.65),
				"fall_lit": air.lerp(Palette.LAVA_FLOW, 0.45),
				"ash": air.lerp(Palette.FIRE_FALLOFF, 0.55),
			}
		Style.WORKS:
			return {
				"air_top": air.darkened(0.15),
				"air_bottom": air.lerp(Palette.ARC_RESIDUE, 0.25),
				"far_iron": air.lerp(Palette.STONE_DEEP, 0.55),
				"near_iron": air.darkened(0.35),
				"rim": air.lerp(Palette.ARC_RESIDUE, 0.55),
				"lamp": air.lerp(Palette.ARC, 0.3),
				"lamp_warm": air.lerp(Palette.FIRE_CORE, 0.3),
			}
		Style.HALL:
			return {
				"air_top": air.darkened(0.1),
				"air_bottom": air.lerp(Palette.STONE_DEEP, 0.3),
				"wall": air.lerp(Palette.STONE_DEEP, 0.4),
				"mortar": air.darkened(0.25),
				"storm": air.lerp(Palette.ARC_RESIDUE, 0.3),
				"flash": air.lerp(Palette.STONE_LIT, 0.55),
				"column": air.darkened(0.3),
				"column_lit": air.lerp(Palette.STONE_DEEP, 0.75),
				"banner": air.lerp(Palette.SPIKE_IRON, 0.22).lerp(Palette.STONE_DEEP, 0.3),
				"sigil": air.lerp(Palette.ARC_RESIDUE, 0.7),
			}
	return {}


## The numbers each style moves by, from `config/atmosphere.tres`.
static func motion_for(backdrop_style: Style) -> Dictionary:
	match backdrop_style:
		Style.CAVERN:
			return {"fall_speed": CONFIG.backdrop_fall_speed, "ash_speed": CONFIG.backdrop_ash_speed}
		Style.WORKS:
			return {"gear_spin": CONFIG.backdrop_gear_spin, "lamp_rate": CONFIG.backdrop_lamp_rate}
		Style.HALL:
			return {"rain_speed": CONFIG.backdrop_rain_speed, "flash_chance": CONFIG.backdrop_flash_chance}
	return {}


## Leaves the cavern's nearer pillars out, for a room whose own obstacles are
## pillars: `ART_DIRECTION.md` says two things that become one shape means one
## of them changes, and the one that kills you cannot.
func without_near_pillars() -> void:
	_material.set_shader_parameter("near_pillars", false)


func _process(_delta: float) -> void:
	var view := get_viewport_rect().size
	var centre := view * 0.5
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		centre = camera.get_screen_center_position()
		# A camera zoomed out (the capture tool's whole-room shots) sees more.
		view /= camera.zoom
	var left := (centre.x - view.x * 0.5)
	position = Vector2(floorf(left) - MARGIN, -MARGIN)
	size = Vector2(view.x, Bench.ROOM_HEIGHT) + Vector2(MARGIN, MARGIN) * 2.0
	_material.set_shader_parameter("camera_left", floorf(left))
