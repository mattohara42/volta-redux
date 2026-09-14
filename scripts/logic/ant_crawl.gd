## The giant ant's loop: floor, up a wall, across the ceiling, down the other
## wall. Pure, so the tests can reach it.
##
## SPEC.md: walks walls and ceilings, ignores gravity, and the mistake it
## punishes is assuming the floor is where the danger is. "Ignores gravity" is
## taken literally rather than as a physics exemption: this file has no notion
## of up, only of the rectangle it is walking and how far around it the ant
## has got, the same way `PlatformFerry` has no notion of water.
##
## `track` is the loop itself, corner to corner, the way a ferry's `travel` is
## its whole crossing: a room hands over the rectangle the ant's centre walks,
## already pulled in from the walls by however far its body sits off them.
class_name AntCrawl

enum Face {
	## Walking down the left side.
	LEFT_WALL,
	## Walking right along the bottom.
	FLOOR,
	## Walking up the right side.
	RIGHT_WALL,
	## Walking left along the top.
	CEILING,
}


static func perimeter(track: Rect2) -> float:
	return 2.0 * (track.size.x + track.size.y)


## Which leg of the loop `distance` around the perimeter lands on, and how far
## into that leg it is.
static func _leg_at(distance: float, track: Rect2) -> Dictionary:
	var perim := perimeter(track)
	if perim <= 0.0:
		return {"face": Face.FLOOR, "into": 0.0}
	var d := fposmod(distance, perim)
	if d < track.size.y:
		return {"face": Face.LEFT_WALL, "into": d}
	d -= track.size.y
	if d < track.size.x:
		return {"face": Face.FLOOR, "into": d}
	d -= track.size.x
	if d < track.size.y:
		return {"face": Face.RIGHT_WALL, "into": d}
	d -= track.size.y
	return {"face": Face.CEILING, "into": d}


## Where the ant's centre is, `distance` around the loop from the top-left
## corner, walked left-wall-down, floor-right, right-wall-up, ceiling-left.
static func position_at(distance: float, track: Rect2) -> Vector2:
	var leg: Dictionary = _leg_at(distance, track)
	var into: float = leg["into"]
	match leg["face"]:
		Face.LEFT_WALL:
			return Vector2(track.position.x, track.position.y + into)
		Face.FLOOR:
			return Vector2(track.position.x + into, track.end.y)
		Face.RIGHT_WALL:
			return Vector2(track.end.x, track.end.y - into)
		_:
			return Vector2(track.end.x - into, track.position.y)


## The direction "away from the surface" at `distance` around the loop, for
## drawing an ant that hangs off the ceiling upside down rather than floating
## in front of it the right way up. Unit length, and gravity has nothing to do
## with it: it is a fact about which leg of the rectangle the ant is on.
static func surface_normal_at(distance: float, track: Rect2) -> Vector2:
	match _leg_at(distance, track)["face"]:
		Face.LEFT_WALL:
			return Vector2(1.0, 0.0)
		Face.FLOOR:
			return Vector2(0.0, -1.0)
		Face.RIGHT_WALL:
			return Vector2(-1.0, 0.0)
		_:
			return Vector2(0.0, 1.0)
