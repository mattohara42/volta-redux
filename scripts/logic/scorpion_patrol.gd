## The scorpion's walk, and the geometry of its armour. Pure, so the tests can
## reach both.
##
## SPEC.md: ground patrol, armoured front, and the mistake it punishes is
## throwing from the front, which has to bounce. It has no dock at either end
## the way `PlatformFerry` does: a patrol does not wait to be boarded, it just
## turns round, so the walk is a plain triangle wave over the range the room
## gave it.
class_name ScorpionPatrol


## One leg, there or back.
static func _leg_time(range: float, speed: float) -> float:
	if range <= 0.0 or speed <= 0.0:
		return 0.0
	return range / speed


static func period(range: float, speed: float) -> float:
	return _leg_time(range, speed) * 2.0


## Distance from the near end of the patrol, at `elapsed` seconds. 0 at one
## end, `range` at the other, and back down again: not clamped, walked.
static func offset_at(elapsed: float, range: float, speed: float) -> float:
	var leg := _leg_time(range, speed)
	if leg <= 0.0:
		return 0.0
	var t := fposmod(maxf(elapsed, 0.0), leg * 2.0)
	if t < leg:
		return speed * t
	return range - speed * (t - leg)


## +1 walking toward the far end, -1 walking back. What the drawn scorpion
## faces, and what its armour faces.
static func facing_at(elapsed: float, range: float, speed: float) -> float:
	var leg := _leg_time(range, speed)
	if leg <= 0.0:
		return 1.0
	var t := fposmod(maxf(elapsed, 0.0), leg * 2.0)
	return 1.0 if t < leg else -1.0


## Whether a hit at `hit_offset` (the sword's position, relative to the
## scorpion's own centre) gets through the armour.
##
## Vertically first: a hit landing in the top `armor_top_fraction` of the body
## is "from above" per SPEC.md, whichever side it came from. Below that line,
## it is a side question: the armoured face is whichever side `facing` points,
## so a hit from the far side is from behind and gets through, and a hit from
## the near side is the mistake this enemy exists to punish.
static func is_vulnerable_to(
	hit_offset: Vector2, facing: float, half_height: float, armor_top_fraction: float
) -> bool:
	var armor_bottom := -half_height + 2.0 * half_height * clampf(armor_top_fraction, 0.0, 1.0)
	if hit_offset.y < armor_bottom:
		return true
	return signf(hit_offset.x) != facing
