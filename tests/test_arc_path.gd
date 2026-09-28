## The arc's jagged path: seeded, whole-pixel, bounded, and its fork grows out of
## the bolt it belongs to.
extends TestCase

const A := Vector2(20.0, 100.0)
const B := Vector2(220.0, 100.0)


func test_a_bolt_has_two_to_the_n_plus_one_points() -> void:
	for n in [0, 1, 3, 4]:
		check_eq(ArcPath.bolt(A, B, 1, n, 0.16).size(), (1 << n) + 1, "%d subdivisions" % n)


func test_a_bolt_starts_and_ends_where_it_was_told() -> void:
	var path := ArcPath.bolt(A, B, 7, 4, 0.16)
	check_eq(path[0], A, "starts at a")
	check_eq(path[path.size() - 1], B, "ends at b")


func test_the_same_seed_is_the_same_bolt_and_another_seed_is_not() -> void:
	check_eq(ArcPath.bolt(A, B, 5, 4, 0.16), ArcPath.bolt(A, B, 5, 4, 0.16), "same seed")
	check(ArcPath.bolt(A, B, 5, 4, 0.16) != ArcPath.bolt(A, B, 6, 4, 0.16), "different seed")


func test_every_vertex_is_a_whole_pixel() -> void:
	for seed_value in 20:
		for point in ArcPath.bolt(A, B, seed_value, 4, 0.2):
			if point != point.round():
				check(false, "seed %d has a vertex at %s" % [seed_value, point])
				return
	check(true, "twenty bolts, every vertex on the pixel grid")


## Pushes are jag, half jag, a quarter and so on, so no vertex can be further off
## the straight line than twice the first push (plus a pixel of rounding).
func test_a_bolt_stays_near_its_line() -> void:
	var length := A.distance_to(B)
	var limit := length * 0.16 * 2.0 + 1.0
	for seed_value in 50:
		for point in ArcPath.bolt(A, B, seed_value, 4, 0.16):
			if absf(point.y - A.y) > limit:
				check(false, "seed %d strays %.1f px against a limit of %.1f" % [seed_value, point.y - A.y, limit])
				return
	check(true, "fifty bolts stay within %.0f px of the line" % limit)


func test_zero_jag_is_a_straight_line() -> void:
	for point in ArcPath.bolt(A, B, 3, 4, 0.0):
		check_near(point.y, A.y, 0.001, "no jag, no deviation")


func test_a_fork_grows_out_of_the_bolt() -> void:
	for seed_value in 20:
		var main := ArcPath.bolt(A, B, seed_value, 4, 0.16)
		var branch := ArcPath.fork(main, seed_value, 0.35, 4, 0.16)
		check(branch.size() > 1, "seed %d has a fork" % seed_value)
		check(main.has(branch[0]), "seed %d's fork starts on the bolt" % seed_value)
		var reach := branch[0].distance_to(branch[branch.size() - 1])
		check(reach > 0.0 and reach <= A.distance_to(B) * 0.35 + 2.0, "seed %d's fork is shorter than the bolt" % seed_value)


func test_a_bolt_too_short_to_fork_has_no_fork() -> void:
	check_eq(ArcPath.fork(PackedVector2Array([A, B]), 1, 0.35, 4, 0.16).size(), 0, "two points cannot fork")
