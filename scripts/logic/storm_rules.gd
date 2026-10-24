## When the storm strikes and how bright a strike is from one moment to the
## next. Pure, so the tests can reach it; `Storm` only draws what this says.
##
## A strike is a few hard pulses with half light between them and an
## afterglow after the last. The flash over everything comes once a strike,
## on the first pulse, so a strike is one white beat and never a strobe.
class_name StormRules


## Seconds until the next strike, `roll` (0 to 1) of the way from `low` to
## `high`.
static func gap(roll: float, low: float, high: float) -> float:
	return lerpf(minf(low, high), maxf(low, high), clampf(roll, 0.0, 1.0))


## How many pulses a strike has, 1 to `most`, from `roll` (0 to 1).
static func pulses(roll: float, most: int) -> int:
	var top := maxi(most, 1)
	return clampi(1 + int(clampf(roll, 0.0, 0.999999) * top), 1, top)


## How long a strike with `count` pulses lasts, afterglow included.
static func length(count: int, pulse: float, gap_seconds: float, afterglow: float) -> float:
	var n := maxi(count, 1)
	return n * pulse + (n - 1) * gap_seconds + afterglow


## How bright the sky is `t` seconds into a strike of `count` pulses, 0 to 1.
## Full during a pulse, `gap_level` between pulses, fading from full to dark
## across the afterglow, and dark before and after.
static func sky(t: float, count: int, pulse: float, gap_seconds: float, afterglow: float, gap_level: float) -> float:
	if t < 0.0:
		return 0.0
	var n := maxi(count, 1)
	var period := pulse + gap_seconds
	var pulses_end := n * pulse + (n - 1) * gap_seconds
	if t < pulses_end:
		return 1.0 if fmod(t, period) < pulse else gap_level
	if afterglow <= 0.0:
		return 0.0
	return clampf(1.0 - (t - pulses_end) / afterglow, 0.0, 1.0)


## How opaque the flash over everything is `t` seconds into a strike, 0 to 1:
## full for `hold`, then clearing evenly across `fade`.
static func whiteout(t: float, hold: float, fade: float) -> float:
	if t < 0.0:
		return 0.0
	if t < hold:
		return 1.0
	if fade <= 0.0:
		return 0.0
	return clampf(1.0 - (t - hold) / fade, 0.0, 1.0)


## A pointed window arch filling `pane`: straight sides up to the springing
## line, a width below the top, then two curves meeting at the tip. Clockwise
## from the bottom left, in whole art px. `steps` points along each curve.
static func arch(pane: Rect2, steps: int = 6) -> PackedVector2Array:
	var points := PackedVector2Array()
	var left := pane.position.x
	var right := pane.end.x
	var half := pane.size.x * 0.5
	var spring := pane.position.y + minf(pane.size.x * 0.6, pane.size.y)
	points.append(Vector2(left, pane.end.y))
	points.append(Vector2(left, spring))
	var n := maxi(steps, 1)
	for i in range(1, n):
		var f := float(i) / n
		points.append(Vector2(left + half * f, spring - (spring - pane.position.y) * sin(f * PI * 0.5)).round())
	points.append(Vector2(left + half, pane.position.y))
	for i in range(n - 1, 0, -1):
		var f := float(i) / n
		points.append(Vector2(right - half * f, spring - (spring - pane.position.y) * sin(f * PI * 0.5)).round())
	points.append(Vector2(right, spring))
	points.append(Vector2(right, pane.end.y))
	return points


## Half the width of `pane`'s arch at height `y`: the full half width below
## the springing line, narrowing to nothing at the tip, as `arch` draws it.
static func arch_half_width(pane: Rect2, y: float) -> float:
	var half := pane.size.x * 0.5
	var spring := pane.position.y + minf(pane.size.x * 0.6, pane.size.y)
	if y >= spring:
		return half
	var rise := spring - pane.position.y
	if rise <= 0.0 or y <= pane.position.y:
		return 0.0
	var f := asin(clampf((spring - y) / rise, 0.0, 1.0)) / (PI * 0.5)
	return half * (1.0 - f)


## `points` pulled sideways into `pane`'s arch, `inset` px clear of its edge,
## so a bolt seen through a window stays in the glass.
static func inside_arch(points: PackedVector2Array, pane: Rect2, inset: float = 1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var centre := pane.get_center().x
	for p in points:
		var y := clampf(p.y, pane.position.y, pane.end.y)
		var reach := maxf(arch_half_width(pane, y) - inset, 0.0)
		out.append(Vector2(clampf(p.x, centre - reach, centre + reach), y).round())
	return out
