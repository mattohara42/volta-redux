## The dragon's fire breath: a clock, the same shape as `GeyserCycle` and for
## the same reason. Pure, so the tests can reach it.
##
## SPEC.md: telegraphed cone, immobile, and the mistake it punishes is panic
## throwing. The cone is what makes panic possible to punish: it is a second,
## ranged reason to keep your distance, on top of the dragon's own body
## already killing on touch like every other animal on SPEC.md's kill list.
##
##   CHARGE     the tell. Not lethal yet.
##   BREATHING  the cone is out and killing.
##   REST       quiet, and safe to approach.
##
## **The cycle starts at the charge rather than at rest**, for the reason
## `GeyserCycle` starts at the swell: a respawn parks the clock at the first
## frame of the tell, so the first thing the controls come back to is a
## warning and never a breath already out.
class_name DragonBreath

enum Phase {
	## The tell. A respawn lands here.
	CHARGE,
	## The cone is out and lethal.
	BREATHING,
	## Quiet. Safe to stand in front of.
	REST,
}


static func period(charge: float, breathe: float, rest: float) -> float:
	return maxf(charge, 0.0) + maxf(breathe, 0.0) + maxf(rest, 0.0)


## Anything before the start is the start, the same rule `GeyserCycle` and
## `PlatformFerry` both keep: nothing precedes a clock a respawn just parked.
static func _cursor(elapsed: float, charge: float, breathe: float, rest: float) -> float:
	var whole := period(charge, breathe, rest)
	if whole <= 0.0:
		return 0.0
	return fposmod(maxf(elapsed, 0.0), whole)


static func phase_at(elapsed: float, charge: float, breathe: float, rest: float) -> Phase:
	var warning := maxf(charge, 0.0)
	var out := maxf(breathe, 0.0)
	var at := _cursor(elapsed, warning, out, rest)
	if at < warning:
		return Phase.CHARGE
	if at < warning + out:
		return Phase.BREATHING
	return Phase.REST


## The one question the node asks every physics frame. False is what the
## dragon is doing most of the time, the same way an eruption is the
## exception for a geyser.
static func is_lethal(phase: Phase) -> bool:
	return phase == Phase.BREATHING


## How far through the charge it is, 0 at the first frame to 1 at the last, so
## the telegraph can grow louder rather than being flat right up to the
## breath. Zero outside the charge.
static func charge_ramp(elapsed: float, charge: float, breathe: float, rest: float) -> float:
	if phase_at(elapsed, charge, breathe, rest) != Phase.CHARGE:
		return 0.0
	if charge <= 0.0:
		return 1.0
	return clampf(_cursor(elapsed, charge, breathe, rest) / charge, 0.0, 1.0)


## For the debug overlay and `tools/capture.gd`.
static func phase_name(phase: Phase) -> String:
	match phase:
		Phase.CHARGE:
			return "charging"
		Phase.BREATHING:
			return "breathing"
		_:
			return "resting"
