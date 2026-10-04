## The ending's flight, as rules. Pure, so the tests can reach them.
class_name FlightRules


## The rider's height after a step: `steer` is -1 (up), 0 or 1 (down), and the
## result stays between `top` and `bottom`.
static func height_after(y: float, steer: float, speed: float, delta: float, top: float, bottom: float) -> float:
	return clampf(y + steer * speed * delta, top, bottom)


## Whether the rider's box touches any pillar.
static func crashed(rider: Rect2, pillars: Array[Rect2]) -> bool:
	for pillar in pillars:
		if rider.intersects(pillar):
			return true
	return false


## Whether a rider of height `size_y` can get from gap `a` to gap `b`, the
## pillars `distance` apart, at these speeds: the worst case is leaving the
## far edge of one gap for the far edge of the next.
static func reachable(a: Vector2, b: Vector2, size_y: float, distance: float, forward: float, vertical: float) -> bool:
	# `a` and `b` are each a gap's top and bottom y; the rider must fit.
	if a.y - a.x < size_y or b.y - b.x < size_y:
		return false
	var climb := maxf(absf(b.x - a.x), absf(b.y - a.y))
	return climb / vertical <= distance / forward
