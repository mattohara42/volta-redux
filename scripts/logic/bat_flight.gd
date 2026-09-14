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
