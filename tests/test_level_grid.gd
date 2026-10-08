## `LevelGrid`, on maps small enough to read at a glance. The claims: a
## material becomes as few rectangles as its shape allows, every placement
## stands on the bottom of its cell, a ladder's top is the surface it serves,
## an anchor becomes the thing its line says with its parameters, and a map
## that does not add up says so rather than guessing.
extends TestCase

const MAP := """size 16
[map]
.......G..
.@B.C..G.E
####..####
####~~####
[things]
G gate
"""


func test_a_floor_merges_into_rectangles() -> void:
	var level := LevelGrid.parse(MAP)
	check_eq(level.errors.size(), 0, "reads cleanly: %s" % [level.errors])
	check_eq(level.size, Vector2(160.0, 64.0), "ten cells by four")
	check_eq(level.height, 64.0, "and as tall as its map, when the file does not say")
	check_eq(LevelGrid.parse("height 360\n" + MAP).height, 360.0, "or as tall as it says")
	check_eq(level.ground.size(), 2, "the floor either side of the pit, each one rectangle")
	check_eq(level.ground[0], Rect2(0.0, 32.0, 64.0, 32.0), "the left side, two rows deep")
	check_eq(level.lava, [Rect2(64.0, 48.0, 32.0, 16.0)] as Array[Rect2], "lava in the pit's bottom")


func test_placements_stand_on_the_bottom_of_their_cell() -> void:
	var level := LevelGrid.parse(MAP)
	check(level.has_start, "a start")
	check_eq(level.start, Vector2(24.0, 32.0), "the hero's feet on the floor")
	check_eq(level.braziers, [Vector2(40.0, 32.0)] as Array[Vector2], "a brazier on the floor")
	check_eq(level.chests, [Vector2(72.0, 32.0)] as Array[Vector2], "a chest on the floor")
	check_eq(level.exit, Rect2(144.0, 16.0, 16.0, 16.0), "the exit")


func test_an_anchor_is_the_thing_its_line_says() -> void:
	var level := LevelGrid.parse(MAP)
	var gate := level.thing("G")
	check(gate != null, "G is in the list")
	check_eq(gate.kind, "gate", "a gate")
	check_eq(gate.rect, Rect2(112.0, 0.0, 16.0, 32.0), "both of its cells, as one rectangle")


func test_parameters_are_read() -> void:
	var level := LevelGrid.parse("""[map]
.S..
####
[things]
S scorpion range=180 size=30x34 dormant
""")
	var t := level.thing("S")
	check_eq(t.number("range", 0.0), 180.0, "a number")
	check_eq(t.size("size", Vector2.ZERO), Vector2(30.0, 34.0), "a size")
	check(t.flag("dormant"), "a flag")
	check(not t.flag("awake"), "and no flag that is not there")


func test_a_ladder_tops_out_at_the_surface_it_serves() -> void:
	var level := LevelGrid.parse("""[map]
##..
##H.
##H.
####
""")
	check_eq(level.ladders, [Rect2(32.0, 16.0, 16.0, 32.0)] as Array[Rect2], "from the ledge's top down to the floor")


## A ladder with a branch over its top stops the hero under the branch (the
## forest's first vine did, 2026-10-07), so the map refuses it.
func test_a_ladder_under_a_solid_is_an_error() -> void:
	var level := LevelGrid.parse("""[map]
.www
.H..
.H..
####
""")
	check(" ".join(level.errors).contains("ladder climbs into"), "the branch over the ladder is reported: %s" % [level.errors])


func test_a_map_that_does_not_add_up_says_so() -> void:
	var level := LevelGrid.parse("""[map]
.X..q
#####
[things]
Y gate
""")
	check(level.errors.size() >= 3, "three problems, at least: %s" % [level.errors])
	var all := " ".join(level.errors)
	check(all.contains("'q'"), "an unknown character")
	check(all.contains("'X'"), "an anchor with no line")
	check(all.contains("'Y'"), "a line with no anchor")
	check(not LevelGrid.parse("size 16").errors.is_empty(), "and no map at all")


## Drawn pieces break only where a surface does: a floor with a hurdle on it
## draws the hurdle as its own column, and no seam runs under the floor.
func test_faces_for_drawing_break_only_at_surfaces() -> void:
	var level := LevelGrid.parse("""[map]
..#..
#####
#####
""")
	var tops := {}
	for rect in level.ground_faces:
		tops[rect.position.y] = true
	check_eq(tops.keys().size(), 2, "tops only at the floor and the hurdle: %s" % [level.ground_faces])
	check_eq(level.ground.size(), 2, "and the row-first merge still makes two pieces for collision")


## The forest's last wall is the castle's: solid like any wall, kept apart so
## it is drawn in the castle's stone whatever the level's own art.
func test_castle_stone_is_solid_and_kept_apart() -> void:
	var level := LevelGrid.parse("size 16\n[map]\n..&&\n..&&\n####\n")
	check_eq(level.errors.size(), 0, "reads cleanly: %s" % [level.errors])
	check_eq(level.castle, [Rect2(32.0, 0.0, 32.0, 32.0)] as Array[Rect2], "one block of castle stone")
	check(level.solids().has(level.castle[0]), "and it is solid")
	check(level.walls.is_empty(), "not a wall in the level's own art")
	check(not LevelGrid.parse("size 16\n[map]\n&\nH\n#\n").errors.is_empty(), "a ladder cannot climb into it")


## N1: the kinds that were built for hand-written rooms and are now placeable.
const PLACEABLE := """size 16
[map]
%%%%%%%%%%%%%%%%%%%%
%AAAA.......GG...YYY
%AAAA..L....GG...YYY
%AAAA......SGG.T.YYY
%AAAA..PP..SGG.T.YYY
%%%%%%%%%%%%%%%%%%%%
[things]
A ant
L lift travel=4,-2
G geyser
P plate opens=D
S switch opens=D
T switch opens=D
Y eyeball size=20x20
"""


func test_each_new_kind_is_read_with_its_rect_and_parameters() -> void:
	var level := LevelGrid.parse(PLACEABLE)
	check(level.errors.is_empty() or level.errors.all(func(e: String) -> bool: return e.contains("'D'")),
		"only the missing gate's anchor is a problem: %s" % [level.errors])
	check_eq(level.thing("A").rect, Rect2(16.0, 16.0, 64.0, 64.0), "the ant fills its hollow")
	check_eq(level.thing("L").rect, Rect2(112.0, 32.0, 16.0, 16.0), "the lift at its near end")
	check_eq(level.thing("G").rect, Rect2(192.0, 16.0, 32.0, 64.0), "the geyser's shaft")
	check_eq(level.thing("P").rect, Rect2(112.0, 64.0, 32.0, 16.0), "the plate's air")
	check_eq(level.of_kind("switch").size(), 2, "two switches")
	check_eq(level.thing("Y").rect, Rect2(272.0, 16.0, 48.0, 64.0), "the eyeball's roam")
	check_eq(level.thing("Y").size("size", Vector2.ZERO), Vector2(20.0, 20.0), "with its own size")


func test_the_room_turns_cells_into_what_it_builds() -> void:
	var level := LevelGrid.parse(PLACEABLE)
	check_eq(GridRoom.plate_rect(level.thing("P").rect), Rect2(112.0, 80.0, 32.0, 8.0),
		"a plate is set into the top of the floor under its cells")
	check_eq(GridRoom.ant_track(level.thing("A").rect, Vector2(22.0, 16.0)), Rect2(24.0, 24.0, 48.0, 48.0),
		"an ant's centre walks half its body in from each face")
	check_eq(GridRoom.lift_travel(level.thing("L"), level.cell), Vector2(64.0, -32.0),
		"a lift's travel is in cells")


func test_an_unknown_kind_is_an_error() -> void:
	var level := LevelGrid.parse("""[map]
.S..
####
[things]
S scorpoin range=96
""")
	check(" ".join(level.errors).contains("unknown kind 'scorpoin'"), "a typo is caught: %s" % [level.errors])


## N1's second half: a slab that holds landings, and a sword to be found.
func test_a_slab_and_a_found_sword_are_read() -> void:
	var level := LevelGrid.parse("""size 16
[map]
.Q..XXX.
########
[things]
Q sword
X slab holds=1
""")
	check(level.errors.is_empty(), "reads cleanly: %s" % [level.errors])
	check_eq(level.thing("X").number("holds", 0.0), 1.0, "the slab holds one landing")
	check_eq(level.thing("X").rect, Rect2(64.0, 0.0, 48.0, 16.0), "across its cells")
	var q := level.thing("Q")
	check_eq(GridRoom.lying_at(Vector2(q.rect.get_center().x, q.rect.end.y), 16.0), Vector2(24.0, 12.0),
		"the sword lies on the floor of its cell, as a dropped one does")
