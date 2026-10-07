## Whether a hero is standing on a stump's top (`Stump`). The hero's bottom is
## round, so on the stump's edge their feet sit a little below its rim, and
## their centre can be past the edge while their body still rests on it.
## Checking only the centre missed every landing on an edge (Matt, 2026-10-07).
class_name StumpLanding
extends RefCounted


## `feet` is the lowest point of the hero's centre line and `half_width` half
## their body's width. `radius` is how far a round bottom can sink below the
## rim when it rests on the corner; it is under a tile, so a hero standing on
## the floor beside a stump never counts.
static func is_on_top(feet: Vector2, half_width: float, radius: float, top: Rect2) -> bool:
	if feet.x + half_width <= top.position.x or feet.x - half_width >= top.end.x:
		return false
	return feet.y >= top.position.y - 2.0 and feet.y <= top.position.y + radius
