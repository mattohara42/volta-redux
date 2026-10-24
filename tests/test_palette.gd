## ART_DIRECTION.md: every dark is a coloured dark, and there is no neutral black
## or grey anywhere. Automated here so it stays true as colours get added.
extends TestCase


func test_every_named_colour_obeys_the_coloured_dark_rule() -> void:
	for entry in Palette.all():
		var colour: Color = Palette.all()[entry]
		check(
			ColourRules.is_legal(colour),
			"Palette.%s: %s" % [entry, ColourRules.explain(colour)]
		)


func test_no_named_colour_is_pure_black_or_pure_white() -> void:
	for entry in Palette.all():
		var colour: Color = Palette.all()[entry]
		check(colour != Color.BLACK, "Palette.%s is not pure black" % entry)
		check(colour != Color.WHITE, "Palette.%s is not pure white" % entry)


## The check has to be able to fail, or a green suite proves nothing.
func test_the_rule_rejects_a_neutral_dark() -> void:
	check(not ColourRules.is_legal(Color("111111")), "a neutral dark is rejected")
	check(not ColourRules.is_legal(Color.BLACK), "pure black is rejected")
	check(ColourRules.is_legal(Color("1a1030")), "a violet dark of the same value passes")
	check(ColourRules.is_legal(Color("cccccc")), "the rule only constrains darks")


## The engine keeps its own copy of the backdrop for the letterbox and anything
## the room does not cover. A neutral grey there is still a neutral grey.
func test_the_project_clear_colour_is_the_backdrop() -> void:
	var clear: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
	check_near(clear.r, Palette.BACKDROP.r, 0.004, "clear colour red matches Palette.BACKDROP")
	check_near(clear.g, Palette.BACKDROP.g, 0.004, "clear colour green matches Palette.BACKDROP")
	check_near(clear.b, Palette.BACKDROP.b, 0.004, "clear colour blue matches Palette.BACKDROP")


## The weather (`shaders/weather.gdshader`) multiplies the art, so damp on the
## deepest stone, under the back wall's shade, must still be a coloured dark.
func test_damp_stone_stays_a_coloured_dark() -> void:
	for stone in [Palette.STONE_DEEP, Palette.STONE_DEEP * Palette.BACK_SHADE]:
		var damp: Color = stone * Palette.WEATHER_DAMP
		check(ColourRules.is_legal(damp), "damp %s: %s" % [stone.to_html(false), ColourRules.explain(damp)])
