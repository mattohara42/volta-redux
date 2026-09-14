## The floating eyeball's drift. Pure, so the tests can reach it.
##
## SPEC.md: tracks you slowly, at your height, and it is the anti-catch enemy:
## it exists to eat returning swords. There is no special case for that
## anywhere in the sword's machine (see `Sword._on_area_entered`) or in this
## one. An eyeball that is honestly drifting toward wherever the hero now is
## ends up on the flat line the sword returns along often enough on its own,
## because that line passes through the hero's height and this is the one
## enemy that is always heading there too.
##
## `roam` is the box the room lets it drift inside, the way a bat gets a box to
## tumble in: this file only knows how to close on a target, not where it is
## allowed to go.
class_name EyeballSeek


## One step of closing on `target`, at `speed` px/s, kept inside `roam`.
static func step(current: Vector2, target: Vector2, speed: float, delta: float, roam: Rect2) -> Vector2:
	var next := current.move_toward(target, maxf(speed, 0.0) * delta)
	return Vector2(
		clampf(next.x, roam.position.x, roam.end.x),
		clampf(next.y, roam.position.y, roam.end.y)
	)
