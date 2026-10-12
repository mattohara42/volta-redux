## `TileShape`, on a map small enough to read: a solid cell's open sides are
## the ones with air beside them, the map's own edge is not an edge, and depth
## counts the rings in from the air.
extends TestCase

const ROWS: Array[String] = [
	"......",
	".####.",
	".####.",
	".####.",
	"######",
]


func test_open_sides_are_where_the_air_is() -> void:
	check_eq(TileShape.open_sides(ROWS, 1, 1), TileShape.UP | TileShape.LEFT, "a top-left corner")
	check_eq(TileShape.open_sides(ROWS, 2, 1), TileShape.UP, "the top")
	check_eq(TileShape.open_sides(ROWS, 4, 2), TileShape.RIGHT, "the right face")
	check_eq(TileShape.open_sides(ROWS, 2, 2), 0, "inside")
	check_eq(TileShape.open_sides(ROWS, 0, 0), 0, "air has no sides")


func test_the_edge_of_the_map_is_not_an_edge() -> void:
	check_eq(TileShape.open_sides(ROWS, 0, 4), TileShape.UP, "the floor's corner is open only on top")
	check_eq(TileShape.open_sides(ROWS, 3, 4), 0, "and under the block, nothing")


func test_depth_counts_rings_in_from_the_air() -> void:
	var d := TileShape.depths(ROWS)
	var at := func(x: int, y: int) -> int: return d[y * 6 + x]
	check_eq(at.call(0, 0), 0, "air")
	check_eq(at.call(1, 1), 1, "a corner touches the air")
	check_eq(at.call(2, 2), 2, "a cell in")
	check_eq(at.call(2, 3), 2, "still two in: its nearest air is two rows up")
	check_eq(at.call(0, 4), 1, "the floor beside the block touches the air above it")
	check_eq(at.call(2, 4), 2, "under the block, two in: the air beside it is two cells away")


func test_below_top_counts_the_stone_above() -> void:
	check_eq(TileShape.below_top(ROWS, 2, 1), 0, "a top")
	check_eq(TileShape.below_top(ROWS, 2, 3), 2, "two under it")
	check_eq(TileShape.below_top(ROWS, 0, 4), 0, "the floor's own top")
