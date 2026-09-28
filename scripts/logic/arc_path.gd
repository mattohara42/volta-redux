## The jagged path of an electric arc. Pure and seeded, so the same seed draws
## the same bolt and a test can reach it.
##
## Midpoint displacement: split the straight line, push the middle sideways by a
## random amount, then split each half with half the push. Every vertex lands on
## a whole art pixel, which is what keeps a one-pixel bolt one pixel wide.
class_name ArcPath


## A bolt from `a` to `b`. `subdivisions` rounds of splitting give
## `2^subdivisions + 1` points; `jag` is the first push as a fraction of the
## bolt's length, and later pushes are half, then a quarter.
static func bolt(a: Vector2, b: Vector2, seed_value: int, subdivisions: int, jag: float) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array([a, b])
	var push := a.distance_to(b) * jag
	for _round in maxi(subdivisions, 0):
		var next := PackedVector2Array()
		for i in points.size() - 1:
			var p := points[i]
			var q := points[i + 1]
			var along := (q - p).normalized()
			var side := Vector2(-along.y, along.x)
			next.append(p)
			next.append((p + q) * 0.5 + side * rng.randf_range(-1.0, 1.0) * push)
		next.append(points[points.size() - 1])
		points = next
		push *= 0.5
	for i in points.size():
		points[i] = points[i].round()
	return points


## A shorter branch that leaves the main bolt from one of its middle vertices,
## turned 20 to 50 degrees off the bolt's own direction. `length_fraction` is
## the branch's length as a fraction of the whole bolt.
static func fork(
	main: PackedVector2Array, seed_value: int, length_fraction: float, subdivisions: int, jag: float
) -> PackedVector2Array:
	if main.size() < 4:
		return PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var start_index := rng.randi_range(1, main.size() - 3)
	var start := main[start_index]
	var direction := (main[main.size() - 1] - main[0]).normalized()
	var turn := deg_to_rad(rng.randf_range(20.0, 50.0)) * (1.0 if rng.randf() < 0.5 else -1.0)
	var length := main[0].distance_to(main[main.size() - 1]) * length_fraction
	var end := start + direction.rotated(turn) * length
	return bolt(start, end, seed_value + 1, maxi(subdivisions - 1, 1), jag)
