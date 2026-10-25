## The portal's clock (`LEVELS.md`, Decisions 2026-10-25: the original's
## portal). Pure, so the tests can reach it.
##
## Two doors take turns. The first is open for `open` seconds, then both are
## shut for `gap`, then the second is open for `open`, then both are shut
## again, and round. A door is used by running into it while it is open,
## which brings you out of the other one.
class_name PortalCycle

const NEITHER := -1
const FIRST := 0
const SECOND := 1


static func period(open: float, gap: float) -> float:
	return 2.0 * (maxf(open, 0.0) + maxf(gap, 0.0))


## Which door is open `elapsed` seconds into the cycle: `FIRST`, `SECOND` or
## `NEITHER`. Before the clock starts (a respawn's freeze) neither is.
static func open_door(elapsed: float, open: float, gap: float) -> int:
	if elapsed < 0.0 or open <= 0.0:
		return NEITHER
	var t := fposmod(elapsed, period(open, gap))
	if t < open:
		return FIRST
	t -= open + maxf(gap, 0.0)
	if t >= 0.0 and t < open:
		return SECOND
	return NEITHER


## How far the door at `door` has opened, 0 to 1, for drawing a slab that
## slides up out of the way over `swing` seconds and drops back as it shuts.
static func openness(elapsed: float, door: int, open: float, gap: float, swing: float) -> float:
	if elapsed < 0.0 or open <= 0.0:
		return 0.0
	var start := 0.0 if door == FIRST else open + maxf(gap, 0.0)
	var t := fposmod(elapsed, period(open, gap)) - start
	if t < 0.0 or t >= open:
		return 0.0
	if swing <= 0.0:
		return 1.0
	return clampf(minf(t, open - t) / swing, 0.0, 1.0)


## Where a hero coming out of a door stands: the middle of its floor.
static func foot_of(door: Rect2) -> Vector2:
	return Vector2(door.get_center().x, door.end.y)


## Whether a hero whose body is `body` is in the doorway `door`: his middle
## inside it, side to side, and his feet on its floor or within a step of it.
static func in_doorway(body: Rect2, door: Rect2) -> bool:
	var mid := body.get_center().x
	return mid > door.position.x and mid < door.end.x \
		and body.end.y > door.position.y and body.position.y < door.end.y
