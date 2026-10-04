## The room's light and dark (`LightField`). What a test can hold is the part
## that is a rule: each act's dark is a coloured dark, the shader and the
## script agree on how many lights there are, and a line light reaches where
## it was told to. What it looks like is a screenshot's job.
extends TestCase

const ACTS: PackedStringArray = [
	"res://config/act1.tres", "res://config/act2.tres",
	"res://config/act3.tres", "res://config/act4.tres",
]
const SHADER := "res://shaders/light_field.gdshader"


## `ART_DIRECTION.md`: every dark is a coloured dark. The ambient is what the
## dark is, so it has to carry a hue, and the darkest stone in the palette
## multiplied by it has to stay a legal colour.
func test_every_act_is_dark_in_a_colour_and_not_in_grey() -> void:
	for path in ACTS:
		var act: ActConfig = load(path)
		var name := path.get_file()
		check(act.ambient_light != Color.WHITE, "%s has a dark at all" % name)
		check(act.ambient_light.s >= ColourRules.MIN_DARK_SATURATION, "%s's dark has a hue (saturation %.2f)" % [name, act.ambient_light.s])
		var stone := Palette.STONE_DEEP * act.ambient_light
		check(ColourRules.is_legal(stone), "%s over the deepest stone: %s" % [name, ColourRules.explain(stone)])
		check(act.ceiling_dim >= 0.0 and act.ceiling_dim < 1.0, "%s's ceiling is dimmer, never black" % name)


## A dark that hides the room is a readability bug, not a mood. The floor has
## to stay well above black with no light on it at all.
func test_no_act_is_too_dark_to_read_unlit() -> void:
	for path in ACTS:
		var act: ActConfig = load(path)
		var floor_lit := Palette.STONE_LIT * act.ambient_light
		check(ColourRules.luminance(floor_lit) > 0.1, "%s leaves lit stone readable (luminance %.3f)" % [
			path.get_file(), ColourRules.luminance(floor_lit)
		])


func test_the_shader_holds_as_many_lights_as_the_script_sends() -> void:
	var text := FileAccess.get_file_as_string(SHADER)
	check(text.contains("const int MAX_LIGHTS = %d;" % LightField.MAX_LIGHTS), "the shader's array is LightField.MAX_LIGHTS long")


func test_a_line_light_reaches_from_one_end_to_the_other() -> void:
	var light := LightSource.line(Vector2(10.0, 20.0), Vector2(110.0, 20.0), 40.0, Palette.ARC, 0.5)
	check_eq(light.position, Vector2(10.0, 20.0), "it starts where it was told")
	check_eq(light.reach, Vector2(100.0, 0.0), "and reaches the far end")
	check_eq(light.radius, 40.0, "with the radius it was given")
	light.free()


func test_a_point_light_has_no_reach() -> void:
	var light := LightSource.point(60.0, Palette.FIRE_CORE, 0.5, 0.3)
	check_eq(light.reach, Vector2.ZERO, "a point is a line of no length")
	check_eq(light.flicker, 0.3, "and keeps its flicker")
	light.free()


## Light sits over the dark, not under it: a glow the dark had dimmed would be
## a coloured patch rather than the thing doing the lighting.
func test_a_light_draws_over_the_dark() -> void:
	var glow := LightGlow.make(30.0, Palette.FIRE_FALLOFF, 0.5)
	check(glow.z_index > LightField.Z and not glow.z_as_relative, "a glow draws over the field")
	glow.free()
