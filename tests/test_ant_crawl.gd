## The ant's loop, as arithmetic: it visits all four corners in order and never
## leaves the track.
extends TestCase

const TRACK := Rect2(100.0, 50.0, 60.0, 80.0)


func test_perimeter_is_the_sum_of_all_four_legs() -> void:
	check_near(
		AntCrawl.perimeter(TRACK), 2.0 * (TRACK.size.x + TRACK.size.y), 0.001,
		"perimeter should be twice width plus twice height"
	)


func test_it_starts_at_the_top_left_corner() -> void:
	var pos := AntCrawl.position_at(0.0, TRACK)
	check_near(pos.x, TRACK.position.x, 0.001, "x at distance 0")
	check_near(pos.y, TRACK.position.y, 0.001, "y at distance 0")


func test_it_visits_all_four_corners_in_order() -> void:
	var corners := [
		TRACK.position,
		Vector2(TRACK.position.x, TRACK.end.y),
		TRACK.end,
		Vector2(TRACK.end.x, TRACK.position.y),
	]
	var travelled := 0.0
	for corner in corners:
		var pos := AntCrawl.position_at(travelled, TRACK)
		check_near(pos.distance_to(corner), 0.0, 0.001, "corner at distance %.1f should be %s, got %s" % [
			travelled, corner, pos
		])
		travelled += TRACK.size.y if corners.find(corner) % 2 == 0 else TRACK.size.x


func test_it_never_leaves_the_track_rectangle() -> void:
	var d := 0.0
	while d < AntCrawl.perimeter(TRACK) * 2.0:
		var pos := AntCrawl.position_at(d, TRACK)
		check(
			pos.x >= TRACK.position.x - 0.01 and pos.x <= TRACK.end.x + 0.01,
			"x %.2f left the track" % pos.x
		)
		check(
			pos.y >= TRACK.position.y - 0.01 and pos.y <= TRACK.end.y + 0.01,
			"y %.2f left the track" % pos.y
		)
		d += 3.7


func test_the_loop_repeats_after_one_full_perimeter() -> void:
	var perim := AntCrawl.perimeter(TRACK)
	var start := AntCrawl.position_at(12.0, TRACK)
	var after_lap := AntCrawl.position_at(12.0 + perim, TRACK)
	check_near(start.distance_to(after_lap), 0.0, 0.001, "a full lap should return to the same point")


func test_surface_normal_points_away_from_each_face() -> void:
	check(
		AntCrawl.surface_normal_at(0.0, TRACK).x > 0.0,
		"on the left wall, away should point into the room (+x)"
	)
	check(
		AntCrawl.surface_normal_at(TRACK.size.y + TRACK.size.x * 0.5, TRACK).y < 0.0,
		"on the floor, away should point up (-y)"
	)
	check(
		AntCrawl.surface_normal_at(TRACK.size.y + TRACK.size.x + TRACK.size.y * 0.5, TRACK).x < 0.0,
		"on the right wall, away should point into the room (-x)"
	)
	var ceiling_at := TRACK.size.y + TRACK.size.x + TRACK.size.y + TRACK.size.x * 0.5
	check(
		AntCrawl.surface_normal_at(ceiling_at, TRACK).y > 0.0,
		"on the ceiling, away should point down (+y), which is hanging"
	)
