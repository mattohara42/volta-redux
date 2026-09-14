## The life of a geyser. Pure, so the tests can reach it.
##
## The third clock in M3, and the only one whose output is a speed rather than a
## floor. `PlatformCycle` is a consequence of standing somewhere. `PlatformFerry`
## was never asking about you at all, and neither is this, but where a ferry
## offers you a floor for a while, a geyser takes your vertical speed off you and
## decides it itself. That is what makes it the one hazard in the milestone that
## is also a route: SPEC.md has geysers in Act 2 both as a thing that hurls you
## and as one of the two ordinary ways to gain a storey.
##
##   SWELL     about to go, and not lifting anybody yet
##   ERUPTING  the column is up, and what is inside it is going up with it
##   DORMANT   quiet, and the vent is a hole in the floor
##
## **The cycle starts at the swell rather than at the quiet.** That is a decision
## about dying rather than about geysers: a respawn puts the clock back to zero,
## so zero has to be the beginning of the window you board in, and the tell has
## to be the first thing you see when the controls come back. A ferry's reset
## leaves it at the start of a dock for the same reason, and for the same reason
## again both of them sit out the respawn freeze before their clock starts.
##
## **A geyser does not kill.** SPEC.md lists what kills instantly as lava, water,
## spikes and animals, and names geysers in the same breath without putting them
## on it. It is the platforms' bargain: the mechanism moves you, and what it
## moves you into is the thing with the killing box.
class_name GeyserCycle

enum Phase {
	## Swelling at the vent. The tell, and where a respawn leaves it.
	SWELL,
	## The column is up and carrying whatever is inside it.
	ERUPTING,
	## Quiet. Nothing to read but the vent and how far the jet reaches.
	DORMANT,
}


## Swell, eruption, quiet, and round again.
static func period(swell: float, erupt: float, dormant: float) -> float:
	return maxf(swell, 0.0) + maxf(erupt, 0.0) + maxf(dormant, 0.0)


## Where in the period `elapsed` lands. Anything before the start is the start:
## a geyser has no state that precedes its clock, and a respawn deliberately
## parks it at a negative number so the freeze it still owes the player is spent
## before the swell rather than out of it.
static func _cursor(elapsed: float, swell: float, erupt: float, dormant: float) -> float:
	var whole := period(swell, erupt, dormant)
	if whole <= 0.0:
		return 0.0
	return fposmod(maxf(elapsed, 0.0), whole)


static func phase_at(elapsed: float, swell: float, erupt: float, dormant: float) -> Phase:
	var warning := maxf(swell, 0.0)
	var blowing := maxf(erupt, 0.0)
	var at := _cursor(elapsed, warning, blowing, dormant)
	if at < warning:
		return Phase.SWELL
	if at < warning + blowing:
		return Phase.ERUPTING
	return Phase.DORMANT


## Whether it is carrying anything right now. The one question the node asks of
## this file every physics frame.
static func lifts(phase: Phase) -> bool:
	return phase == Phase.ERUPTING


## How far through the warning it is, from 0 at the first frame of the swell to
## 1 at the last. Zero outside the swell.
##
## The tell ramps up across the warning rather than being flat, for the reason a
## falling slab's shake does: a warning as loud in its first frame as in its last
## says "something is happening" and not "this is about to go", and the second is
## the sentence a player has to read while running at a moat.
static func swell_ramp(elapsed: float, swell: float, erupt: float, dormant: float) -> float:
	if phase_at(elapsed, swell, erupt, dormant) != Phase.SWELL:
		return 0.0
	if swell <= 0.0:
		return 1.0
	return clampf(_cursor(elapsed, swell, erupt, dormant) / swell, 0.0, 1.0)


## How long it takes to be carried `rise` px at `speed`.
##
## Derived rather than authored, for the reason `PlatformFerry.travel_seconds` is
## derived: what the config cares about is how fast the water goes up, and how
## long a ride lasts is a consequence of how far the room asked it to carry you.
## A ride time in the config would go stale the moment a room put a ledge higher.
static func ride_seconds(rise: float, speed: float) -> float:
	if rise <= 0.0 or speed <= 0.0:
		return 0.0
	return rise / speed


## The last moment you can be standing in the column and still be carried the
## whole way, measured from the start of the clock.
##
## The number a room with a geyser in it is laid out against, the way
## `platform_wait_time` is the number the ferry bench is laid out against. A
## checkpoint is placed well when the run from it to the vent fits inside this,
## and badly when every death costs a whole quiet period as well as the climb
## you missed. That difference is the whole of M3's second done-when.
static func boarding_window(swell: float, erupt: float, rise: float, speed: float) -> float:
	return maxf(swell, 0.0) + maxf(maxf(erupt, 0.0) - ride_seconds(rise, speed), 0.0)


## For the debug overlay and `tools/capture.gd`. A dormant vent and a vent one
## frame from swelling are the same picture.
static func phase_name(phase: Phase) -> String:
	match phase:
		Phase.SWELL:
			return "swelling"
		Phase.ERUPTING:
			return "erupting"
		_:
			return "dormant"
