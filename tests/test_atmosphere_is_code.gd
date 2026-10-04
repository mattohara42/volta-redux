## M9's done-when: "neither is a texture someone drew frame by frame." And
## `BUILD_PLAN.md`: "if something here is being drawn as a PNG loop, that is the
## bug." So the lava, the arc and the charged surface may not load an image, and
## the only texture a shader may sample is the screen it distorts.
extends TestCase

const SCRIPTS: PackedStringArray = [
	"res://scripts/lava_surface.gd",
	"res://scripts/arc_bolt.gd",
	"res://scripts/charged_surface.gd",
	"res://scripts/logic/arc_path.gd",
	"res://scripts/dragon.gd",
	"res://scripts/light_glow.gd",
	"res://scripts/light_field.gd",
	"res://scripts/light_source.gd",
	"res://scripts/backdrop.gd",
]
const SHADERS: PackedStringArray = [
	"res://shaders/lava.gdshader",
	"res://shaders/heat_haze.gdshader",
	"res://shaders/glow.gdshader",
	"res://shaders/charged.gdshader",
	"res://shaders/flame.gdshader",
	"res://shaders/light.gdshader",
	"res://shaders/light_field.gdshader",
	"res://shaders/backdrop.gdshaderinc",
	"res://shaders/backdrop_cavern.gdshader",
	"res://shaders/backdrop_works.gdshader",
	"res://shaders/backdrop_hall.gdshader",
	"res://shaders/dither.gdshaderinc",
]


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_no_effect_script_loads_an_image() -> void:
	for path in SCRIPTS:
		var text := _text(path)
		check(text != "", "%s is readable" % path)
		check(not text.contains("res://assets"), "%s loads nothing from assets/" % path)
		check(not text.contains("Texture2D"), "%s names no texture" % path)


func test_no_shader_samples_a_texture_but_the_screen() -> void:
	for path in SHADERS:
		var text := _text(path)
		check(text != "", "%s is readable" % path)
		for line in text.split("\n"):
			if line.contains("sampler2D"):
				check(line.contains("hint_screen_texture"), "%s: %s" % [path, line.strip_edges()])


func test_effect_colours_come_from_the_palette_not_the_shaders() -> void:
	for path in SHADERS:
		var text := _text(path)
		check(not text.contains("vec3(0.0)") and not text.contains("vec3(1.0)"), "%s draws no black or white" % path)
		var code := text.replace("#include", "")
		check(not code.contains("#"), "%s carries no hex colour" % path)
