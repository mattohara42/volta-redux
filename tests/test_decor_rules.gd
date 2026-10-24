## `DecorRules`, on maps small enough to read. The claims: battlements stand
## along a wall walk over a drop and not on the ground; torches need a back
## wall and keep their distance; tufts and roots grow where grass and earth
## are; nothing ever lands on anything the map placed; and the grid it writes
## reads back as the same decoration.
extends TestCase


func _rows(level_text: String) -> LevelGrid.Level:
	var level := LevelGrid.parse(level_text)
	check_eq(level.errors.size(), 0, "reads cleanly: %s" % [level.errors])
	return level


func test_battlements_stand_on_a_wall_walk_over_a_drop() -> void:
	var level := _rows("""[map]
..........
..........
.....#####
.....#####
.....#####
##########
""")
	var grid := DecorRules.place(level, "castle")
	check_eq(grid[1], ".....nnnnn", "along the walk")
	check_eq(grid[4], "..........", "and not on the ground below it, which drops nowhere")


func test_torches_need_a_back_wall_and_keep_apart() -> void:
	var text := """[map]
......................
......................
......................
######################
[back]
######################
######################
######################
"""
	var grid := DecorRules.place(_rows(text), "castle")
	var torches := grid[1].count("t")
	check_eq(torches, 3, "every %d cells along the floor" % DecorRules.TORCH_PITCH)
	var bare := DecorRules.place(_rows(text.split("[back]")[0]), "castle")
	check_eq(bare[1].count("t"), 0, "and none with no wall behind")


func test_a_torch_keeps_clear_of_a_brazier() -> void:
	var grid := DecorRules.place(_rows("""[map]
.......
...B...
#######
[back]
#######
#######
"""), "castle")
	check_eq(grid[0].count("t"), 0, "a brazier lights it already")


func test_forest_grass_and_earth() -> void:
	var level := _rows("""[map]
..............................
..............................
######..........##############
######........................
""")
	var grid := DecorRules.place(level, "forest")
	check(grid[1].count(",") > 0, "tufts on the grass")
	check_eq(grid[1].substr(6, 10).count(","), 0, "and none over the gap")
	check(grid[3].substr(16).count("'") > 0, "roots under the overhang")
	check_eq(grid[3].substr(0, 16).count("'"), 0, "and nowhere else")


func test_nothing_lands_on_what_the_map_placed() -> void:
	var level := _rows("""[map]
..........
.@B.C..E..
##########
""")
	var grid := DecorRules.place(level, "forest")
	for x in level.rows[1].length():
		if level.rows[1][x] != ".":
			check_eq(grid[1][x], ".", "nothing on '%s'" % level.rows[1][x])


func test_the_grid_reads_back() -> void:
	var text := """[map]
..........
..........
.....#####
.....#####
.....#####
##########
"""
	var grid := DecorRules.place(_rows(text), "castle")
	var again := LevelGrid.parse(text + DecorRules.section(grid))
	check_eq(again.errors.size(), 0, "reads cleanly: %s" % [again.errors])
	check_eq(again.decor_cells("battlement").size(), 5, "every battlement")
	check_eq(DecorRules.place(_rows(text), "castle"), grid, "and the same level always decorates the same")


func test_a_creature_flies_in_front_of_the_parapet() -> void:
	var level := _rows("""[map]
..........
.......OO.
.....#####
.....#####
.....#####
##########
[things]
O bat
""")
	check_eq(DecorRules.place(level, "castle")[1], ".....nnnnn", "unbroken where the bat flies")


func test_no_parapet_stands_before_a_building() -> void:
	var level := _rows("""[map]
..........
..........
.....#####
.....#####
.....#####
##########
[back]
.......###
.......###
""")
	check_eq(DecorRules.place(level, "castle")[1], ".....nn...", "only out in the open")


## The foreground kit: one wall feature a bay of a back wall, never with no
## wall behind it, never where a ladder stands.
func test_wall_features_need_a_back_wall_and_a_bay() -> void:
	var text := """[map]
..............
..............
..............
..............
..............
##############
[back]
##############
##############
##############
##############
##############
"""
	var grid := DecorRules.place(_rows(text), "castle")
	var features := 0
	for row in grid:
		for c in row:
			if DecorRules.FEATURES.has(LevelGrid.DECOR.get(c, "")):
				features += 1
	check(features > 0, "a bay of back wall gets a feature")
	var bare := DecorRules.place(_rows(text.split("[back]")[0]), "castle")
	for row in bare:
		for c in row:
			check(not DecorRules.FEATURES.has(LevelGrid.DECOR.get(c, "")), "and none with no wall behind")


func test_a_wall_feature_keeps_clear_of_a_ladder() -> void:
	var grid := DecorRules.place(_rows("""[map]
.....
..H..
..H..
..H..
#####
[back]
#####
#####
#####
#####
"""), "castle")
	for row in grid:
		check_eq(row, ".....", "a ladder fills the wall already")


## Ivy hangs from a lip three cells wide with room below, and two never hang
## side by side.
func test_ivy_hangs_from_a_lip_and_keeps_apart() -> void:
	var map := "[map]\n" + "#".repeat(60) + "\n" + (".".repeat(60) + "\n").repeat(6) + "#".repeat(60) + "\n"
	var grid := DecorRules.place(_rows(map), "castle")
	var ivy: Array[int] = []
	for y in grid.size():
		for x in grid[y].length():
			if grid[y][x] == "v":
				check_eq(y, 1, "right under the ceiling")
				ivy.append(x)
	check(not ivy.is_empty(), "a long ceiling grows some")
	for i in range(1, ivy.size()):
		check(ivy[i] - ivy[i - 1] >= DecorRules.IVY_PITCH, "and keeps %d cells apart" % DecorRules.IVY_PITCH)


## A footprint is the room the rules keep clear, so the art must fit in it,
## standing on its anchor (or hanging from it, for ivy), centred on its cell.
func test_the_kit_fits_its_footprints() -> void:
	var cell := 16.0
	var pieces := TileArt.KIT.duplicate()
	pieces["ivy"] = TileArt.IVY
	for kind: String in pieces:
		var foot: Vector3i = DecorRules.FOOTPRINTS[kind]
		for texture: Texture2D in pieces[kind]:
			var size := texture.get_size()
			check(size.x <= (2 * foot.x + 1) * cell, "%s is %d px wide, inside %d cells" % [kind, size.x, 2 * foot.x + 1])
			check(size.y <= foot.y * cell, "%s is %d px tall, inside %d rows" % [kind, size.y, foot.y])


## A big block's face gets features, all of each footprint in stone two
## rings deep, so the ring you play against stays plain; a thin wall gets none.
func test_a_big_block_gets_features_set_into_its_face() -> void:
	var map := "[map]\n" + (".".repeat(30) + "\n").repeat(2) + ("#".repeat(30) + "\n").repeat(12)
	var level := _rows(map)
	var grid := DecorRules.place(level, "castle")
	var depths := TileShape.depths(level.rows)
	var set := 0
	for y in grid.size():
		for x in grid[y].length():
			var kind: String = LevelGrid.DECOR.get(grid[y][x], "")
			if not DecorRules.FACE_FEATURES.has(kind):
				continue
			set += 1
			var foot: Vector3i = DecorRules.FOOTPRINTS[kind]
			for fy in range(y - foot.y + 1, y + 1):
				for fx in range(x - foot.x, x + foot.x + 1):
					check(depths[fy * 30 + fx] >= DecorRules.FACE_DEPTH, "%s at %s stays off the edge" % [kind, Vector2i(x, y)])
	check(set > 0, "a block twelve rows deep gets some")
	var thin := DecorRules.place(_rows("[map]\n" + (".".repeat(30) + "\n").repeat(2) + ("#".repeat(30) + "\n").repeat(2)), "castle")
	for row in thin:
		for c in row:
			check(not DecorRules.FACE_FEATURES.has(LevelGrid.DECOR.get(c, "")) or c == ".", "and a floor two rows thick gets none")
