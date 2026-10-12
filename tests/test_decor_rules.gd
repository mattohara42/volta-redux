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
