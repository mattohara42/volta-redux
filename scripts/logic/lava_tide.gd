## The life of a lava tide. Pure, so the tests can reach it.
##
##   LOW      under the passage floor: the window you cross in
##   RISING   coming up through the floor
##   HIGH     standing over the passage, below the refuges
##   FALLING  going back down
##
## **It starts low**, for the reason `GeyserCycle` starts at its swell: a respawn
## puts the clock back to zero, so zero has to be the start of the window you act
## in, and coming back to life into a flooded passage would be a second death
## you did nothing to earn.
class_name LavaTide

enum Phase { LOW, RISING, HIGH, FALLING }


static func period(low: float, rise: float, high: float, fall: float) -> float:
	return low + rise + high + fall


static func phase_at(t: float, low: float, rise: float, high: float, fall: float) -> Phase:
	var at := fposmod(maxf(t, 0.0), period(low, rise, high, fall))
	if at < low:
		return Phase.LOW
	if at < low + rise:
		return Phase.RISING
	if at < low + rise + high:
		return Phase.HIGH
	return Phase.FALLING


## The lava's top at time `t`, between `low_y` (under the floor) and `high_y`
## (over it). Smoothstepped, so it eases off the floor and into its crest.
static func level_at(
	t: float, low: float, rise: float, high: float, fall: float, low_y: float, high_y: float
) -> float:
	var at := fposmod(maxf(t, 0.0), period(low, rise, high, fall))
	var up := 0.0
	if at < low:
		up = 0.0
	elif at < low + rise:
		up = smoothstep(0.0, 1.0, (at - low) / rise)
	elif at < low + rise + high:
		up = 1.0
	else:
		up = 1.0 - smoothstep(0.0, 1.0, (at - low - rise - high) / fall)
	return lerpf(low_y, high_y, up)


## How long after a low tide begins the lava first reaches `floor_y`: the whole
## of the window a passage at that height gives you.
static func dry_window(low: float, rise: float, low_y: float, high_y: float, floor_y: float) -> float:
	var fraction := clampf((low_y - floor_y) / (low_y - high_y), 0.0, 1.0)
	# Invert the smoothstep: the time on the rise where the eased level hits it.
	var lo := 0.0
	var hi := 1.0
	for i in 30:
		var mid := (lo + hi) * 0.5
		if smoothstep(0.0, 1.0, mid) < fraction:
			lo = mid
		else:
			hi = mid
	return low + rise * lo
