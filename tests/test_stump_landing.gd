## Landing on a stump's top, anywhere the hero's body rests on it.
extends TestCase

const TOP := Rect2(1664.0, 640.0, 32.0, 32.0)
const HALF := 9.0


func test_the_middle_counts() -> void:
	check(StumpLanding.is_on_top(Vector2(1680.0, 640.0), HALF, HALF, TOP), "feet on the middle of the top")


func test_an_edge_counts_with_the_centre_past_it() -> void:
	# Matt's playtest: approached from the right and came to rest on the left
	# edge, centre at 1660.9 and feet half a pixel under the rim.
	check(StumpLanding.is_on_top(Vector2(1660.9, 640.5), HALF, HALF, TOP), "left edge")
	check(StumpLanding.is_on_top(Vector2(1700.0, 643.0), HALF, HALF, TOP), "right edge, sunk on the corner")


func test_beside_or_under_does_not() -> void:
	check(not StumpLanding.is_on_top(Vector2(1650.0, 672.0), HALF, HALF, TOP), "on the floor beside it")
	check(not StumpLanding.is_on_top(Vector2(1655.0, 640.0), HALF, HALF, TOP), "body clear of the left side")
	check(not StumpLanding.is_on_top(Vector2(1680.0, 620.0), HALF, HALF, TOP), "in the air above it")
