## The far layers `Backdrop` draws until painted backgrounds exist. What a test
## can hold is `ART_DIRECTION.md`'s rule for them: backgrounds lose. Every
## colour a backdrop draws with is darker than the stone you stand on, duller
## than lava, and a coloured dark rather than a grey one.
extends TestCase

const STYLES: Array[Backdrop.Style] = [Backdrop.Style.CAVERN, Backdrop.Style.WORKS, Backdrop.Style.HALL]


func test_every_backdrop_colour_is_darker_than_the_stone_you_stand_on() -> void:
	var stone := ColourRules.luminance(Palette.STONE_MID)
	for style in STYLES:
		var colours := Backdrop.colours_for(style)
		check(not colours.is_empty(), "%s draws with something" % Backdrop.Style.keys()[style])
		for key: String in colours:
			var colour: Color = colours[key]
			check(ColourRules.luminance(colour) < stone, "%s %s is darker than lit-side stone (%.3f against %.3f)" % [
				Backdrop.Style.keys()[style], key, ColourRules.luminance(colour), stone
			])


func test_no_backdrop_colour_is_as_saturated_as_lava() -> void:
	for style in STYLES:
		var colours := Backdrop.colours_for(style)
		for key: String in colours:
			var colour: Color = colours[key]
			check(colour.s < Palette.LAVA_FLOW.s, "%s %s is duller than lava (saturation %.2f)" % [
				Backdrop.Style.keys()[style], key, colour.s
			])


func test_every_backdrop_colour_is_a_coloured_dark() -> void:
	for style in STYLES:
		var colours := Backdrop.colours_for(style)
		for key: String in colours:
			var colour: Color = colours[key]
			check(ColourRules.is_legal(colour), "%s %s: %s" % [Backdrop.Style.keys()[style], key, ColourRules.explain(colour)])


## Act 1 has a painted wall; the other three draw theirs in code until theirs
## are painted, and an act that has both would draw one over the other.
func test_each_act_without_a_painting_names_a_backdrop() -> void:
	var paths := ["res://config/act1.tres", "res://config/act2.tres", "res://config/act3.tres", "res://config/act4.tres"]
	var tiles := [TileArt.ACT1, Act2Mouth.TILES, Act3Room.TILES, Act4Room.TILES]
	for i in paths.size():
		var act: ActConfig = load(paths[i])
		var painted: bool = (tiles[i] as ActTiles).background != null
		check(painted == (act.backdrop == Backdrop.Style.NONE), "%s: a backdrop exactly when there is no painting" % paths[i].get_file())


## Every style the act files can name has a shader, and each shader takes the
## colours `colours_for` hands it, so a renamed uniform is caught here rather
## than as a black stripe in a screenshot.
func test_every_style_has_a_shader_with_its_colours() -> void:
	for style in STYLES:
		check(Backdrop.SHADERS.has(style), "%s has a shader" % Backdrop.Style.keys()[style])
		var shader: Shader = Backdrop.SHADERS[style]
		var code := shader.code
		for key: String in Backdrop.colours_for(style):
			check(code.contains("uniform vec4 %s " % key), "%s's shader takes %s" % [Backdrop.Style.keys()[style], key])
		for key: String in Backdrop.motion_for(style):
			check(code.contains("uniform float %s " % key), "%s's shader takes %s" % [Backdrop.Style.keys()[style], key])
