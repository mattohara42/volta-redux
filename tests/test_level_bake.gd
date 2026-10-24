## N2's look, as far as a headless test can hold it: the darks an art set
## falls into are coloured darks; the interior shade leaves the ring that
## touches the air whole and deepens inward, in the castle's own dark for
## castle stone; a back wall stands behind the stone it is darker than; and
## the decoration in each level file stands only in air, as the rules put it.
## The pictures themselves are `tools/dev.sh shot`'s to show.
extends TestCase

const SETS: PackedStringArray = [
	"res://assets/art/act1/act1_tiles.tres",
	"res://assets/art/forest/forest_tiles.tres",
]
const LEVELS: PackedStringArray = [
	"res://levels/act1_forest.level",
	"res://levels/act1_wall.level",
	"res://levels/act1_wall_old.level",
]


func test_every_set_falls_into_a_coloured_dark() -> void:
	for path in SETS:
		var set: ActTiles = load(path)
		for slot in ["edge_dark", "interior_dark"]:
			var colour: Color = set.get(slot)
			check(ColourRules.is_legal(colour), "%s %s: %s" % [path.get_file(), slot, ColourRules.explain(colour)])


func test_the_back_wall_is_darker_than_the_stone() -> void:
	check(ColourRules.luminance(Palette.BACK_SHADE) < ColourRules.luminance(Palette.GROUND_SHADE[Palette.GROUND_SHADE.size() - 1]),
		"a back wall is shaded below the deepest row of ground ('Backgrounds lose')")
	check(Palette.BACK_SHADE.b > Palette.BACK_SHADE.r, "and cooler, as distance is")


func test_the_shade_deepens_inward_and_spares_the_edge() -> void:
	var level := LevelGrid.parse("""[map]
..........
.@........
######&&&&
######&&&&
######&&&&
######&&&&
""")
	var config: AtmosphereConfig = load("res://config/atmosphere.tres")
	var field := TileArt.shade_field(level, config).get_image()
	check_eq(field.get_pixel(1, 1).a, 0.0, "air is not shaded")
	check_eq(field.get_pixel(1, 2).a, 0.0, "nor the stone that touches it")
	check(field.get_pixel(1, 4).a > field.get_pixel(1, 3).a, "deeper is darker")
	check(field.get_pixel(1, 5).a <= config.ground_shade_most + 0.01, "and no darker than the most it goes")
	check(field.get_pixel(8, 5).a > 0.0, "castle stone is shaded too")
	check(field.get_pixel(8, 5).is_equal_approx(Color(TileArt.ACT1.interior_dark, field.get_pixel(8, 5).a)),
		"in the castle's own dark, whatever the level's set")


func test_the_act1_levels_decorate_only_air_or_deep_stone() -> void:
	for path in LEVELS:
		var level := GridRoom.read(path)
		check_eq(level.errors, [] as Array[String], "%s reads cleanly" % path.get_file())
		var creatures := ""
		for t in level.things:
			if DecorRules.CREATURES.has(t.kind):
				creatures += t.anchor
		var count := 0
		var depths := TileShape.depths(level.rows)
		var width := level.rows[0].length()
		for kind: String in level.decor:
			for at: Vector2i in level.decor_cells(kind):
				count += 1
				var c := level.rows[at.y][at.x]
				# A wall feature may be set into a block's face, deep in the stone.
				var face_kind := DecorRules.FACE_FEATURES.has(kind) or DecorRules.FOREST_FACE.has(kind)
				var in_face := face_kind and depths[at.y * width + at.x] >= DecorRules.FACE_DEPTH
				check(c == "." or creatures.contains(c) or in_face, "%s: %s at %s stands in '%s'" % [path.get_file(), kind, at, c])
		check(count > 0, "%s is decorated" % path.get_file())
		check(not level.back.is_empty(), "%s has a back wall" % path.get_file())
