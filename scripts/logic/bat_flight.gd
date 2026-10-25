## The bat's path. Pure, so the tests can reach it.
##
## SPEC.md: erratic flight, fast, no ground contact, and the mistake it
## punishes is throwing at a moving target. A true random walk cannot be
## tested or replayed, so this is a Lissajous figure instead: two sine waves at
## a ratio away from 1:1, which never closes into a circle or an ellipse and
## reads as tumbling rather than as a lap.
##
## The room owns the box the bat tumbles inside, the way it owns a ferry's span
## and a geyser's shaft: `half_extents` is a fact about where the bat was put,
## and this file only knows the shape of the path, not where it flies.
class_name BatFlight

## Splits the two axes out of phase, so the path is a figure rather than a
## line traced twice. A quarter turn, the way two waves are put in quadrature.
const PHASE: float = PI * 0.5


## Offset from the centre of the box, at `elapsed` seconds.
static func offset_at(
	elapsed: float, angular_speed: float, axis_ratio: float, half_extents: Vector2
) -> Vector2:
	return Vector2(
		half_extents.x * sin(elapsed * angular_speed),
		half_extents.y * sin(elapsed * angular_speed * axis_ratio + PHASE)
	)


## The derivative of `offset_at`, for facing and for a future draw call that
## wants to bank into the turn.
static func velocity_at(
	elapsed: float, angular_speed: float, axis_ratio: float, half_extents: Vector2
) -> Vector2:
	return Vector2(
		half_extents.x * angular_speed * cos(elapsed * angular_speed),
		half_extents.y * angular_speed * axis_ratio * cos(elapsed * angular_speed * axis_ratio + PHASE)
	)


## Which way it is pointed, for the sprite. Holds the last facing rather than
## flipping at the instant the horizontal speed is exactly zero, which a sine
## crosses every half-cycle.
static func facing_at(
	elapsed: float, angular_speed: float, axis_ratio: float, half_extents: Vector2, previous: float
) -> float:
	var vx := velocity_at(elapsed, angular_speed, axis_ratio, half_extents).x
	if is_zero_approx(vx):
		return previous
	return signf(vx)


## The box a bat's centre roams, given the box the level drew for it. A side
## of `box` that touches something solid is pulled in by `body_half`, so the
## drawn bat stops at the wall, floor or ceiling instead of flying into it
## (Matt, 2026-10-25). A side open to air is left alone: the bat may lean out
## over it, as it always could. A box too small for the bat on an axis
## collapses to its middle there, and the bat holds still on that axis.
static func fitted_box(box: Rect2, body_half: Vector2, solids: Array[Rect2]) -> Rect2:
	var left := box.position.x
	var right := box.end.x
	var top := box.position.y
	var bottom := box.end.y
	if _touches(Rect2(box.position.x - 1.0, box.position.y, 1.0, box.size.y), solids):
		left += body_half.x
	if _touches(Rect2(box.end.x, box.position.y, 1.0, box.size.y), solids):
		right -= body_half.x
	if _touches(Rect2(box.position.x, box.position.y - 1.0, box.size.x, 1.0), solids):
		top += body_half.y
	if _touches(Rect2(box.position.x, box.end.y, box.size.x, 1.0), solids):
		bottom -= body_half.y
	if right < left:
		left = (left + right) * 0.5
		right = left
	if bottom < top:
		top = (top + bottom) * 0.5
		bottom = top
	return Rect2(left, top, right - left, bottom - top)


static func _touches(strip: Rect2, solids: Array[Rect2]) -> bool:
	for s in solids:
		if s.intersects(strip):
			return true
	return false
