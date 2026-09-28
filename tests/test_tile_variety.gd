## Tile variants spread across a room without repeating as wallpaper, and land
## the same way every load.
extends TestCase


func test_the_same_cell_always_gets_the_same_variant() -> void:
	for x in range(-5, 5):
		check_eq(TileVariety.pick(Vector2i(x, 3), 6), TileVariety.pick(Vector2i(x, 3), 6), "cell %d stable" % x)


func test_every_pick_is_a_valid_index() -> void:
	for x in range(-40, 40):
		for y in range(-10, 10):
			var i := TileVariety.pick(Vector2i(x, y), 6)
			if i < 0 or i >= 6:
				check(false, "cell (%d, %d) picked %d" % [x, y, i])
				return
	check(true, "every pick across a 80x20 room is in range")


func test_a_single_variant_is_always_index_zero() -> void:
	check_eq(TileVariety.pick(Vector2i(7, 2), 1), 0, "one variant means index 0")


## The point of variants: across one row of a room, every variant appears and
## none dominates. A row of 40 cells, 6 variants, so about 7 each.
func test_a_row_uses_every_variant_and_none_dominates() -> void:
	var counts := [0, 0, 0, 0, 0, 0]
	for x in 40:
		counts[TileVariety.pick(Vector2i(x, 5), 6)] += 1
	for i in 6:
		check(counts[i] > 0, "variant %d appears in a row of 40" % i)
		check(counts[i] <= 14, "variant %d is not most of the row (%d of 40)" % [i, counts[i]])


func test_neighbouring_rows_are_not_the_same_row_again() -> void:
	var same := 0
	for x in 40:
		if TileVariety.pick(Vector2i(x, 0), 6) == TileVariety.pick(Vector2i(x, 1), 6):
			same += 1
	check(same < 20, "rows 0 and 1 agree in %d of 40 cells, not a repeated row" % same)
