## The life of a platform that will not hold you. Pure, so the tests can reach it.
##
## A falling platform is not a hazard: it has no killing box and it never touches
## `Hazard`. It is the thing that puts you in one, which is why it owns a clock
## and nothing else. SPEC.md's Act 2 is "a throw you have to catch before the
## platform you are standing on drops", and every number in that sentence is a
## duration.
##
## The cycle starts the moment something stands on it and then runs to the end on
## its own. It does not stop when you step off, because a platform you can arm
## and then walk away from is a platform you never have to decide about.
##
##   SHAKING   armed, still solid, telling you it is about to go
##   FALLING   still solid, and taking you with it unless you jump
##   GONE      out of the room, and the route across is missing a step
##   STEADY    back home, and it is as if you never touched it
##
## **It stays solid while it falls.** That is the whole design of it: the punish
## is that the floor leaves with you on it, and the out is that you can still
## jump off what is already falling. A platform that vanished under your feet
## would be a trapdoor, and a trapdoor has no moment in it where you can react.
class_name PlatformCycle

enum Phase {
	## At home, waiting. Nothing has stood on it since the last time it fell.
	STEADY,
	## Armed and shaking. Solid, and counting down to letting go.
	SHAKING,
	## On its way out of the room, and still solid all the way down.
	FALLING,
	## Below the room. This is the only phase where it is not there to land on.
	GONE,
}


## How long it takes to fall `drop` px from a standing start under `gravity`.
##
## Derived rather than authored, because what a room cares about is that the
## slab is out of sight, and how long that takes is a consequence of how high up
## it started. A number in the config would go stale the moment a room put a
## platform at a different height.
static func fall_seconds(drop: float, gravity: float) -> float:
	if drop <= 0.0 or gravity <= 0.0:
		return 0.0
	return sqrt(2.0 * drop / gravity)


## How far it has fallen after `falling_for` seconds. Not clamped: the caller
## knows the drop it asked for, and clamping here would hide a phase that ran
## longer than the fall it was sized against.
static func drop_offset(falling_for: float, gravity: float) -> float:
	if falling_for <= 0.0:
		return 0.0
	return 0.5 * gravity * falling_for * falling_for


## The whole cycle, from being stood on to being back and load bearing again.
static func cycle_seconds(warn: float, fall: float, hold: float) -> float:
	return maxf(warn, 0.0) + maxf(fall, 0.0) + maxf(hold, 0.0)


## Where in that cycle `elapsed` seconds lands. Anything at or past the end is
## STEADY, so a caller that stops ticking at the end and one that keeps going
## agree about what the platform is.
static func phase_at(elapsed: float, warn: float, fall: float, hold: float) -> Phase:
	if elapsed < 0.0:
		return Phase.STEADY
	if elapsed < warn:
		return Phase.SHAKING
	if elapsed < warn + fall:
		return Phase.FALLING
	if elapsed < cycle_seconds(warn, fall, hold):
		return Phase.GONE
	return Phase.STEADY


## Whether it is something you can stand on. Only a platform that has left the
## room is not, which is the reverse of what a trapdoor does and is deliberate.
static func is_solid(phase: Phase) -> bool:
	return phase != Phase.GONE


## Where the slab is, relative to home.
##
## One function for both the shake and the drop, because they are the same
## thing to everything that draws or moves it, and splitting them would let the
## node decide which one applies. That decision is the phase, and the phase is
## here.
##
## The shake ramps up across the warning rather than being flat. A tell that is
## as loud in its first frame as its last says "something is happening" and not
## "this is about to go", and the second one is the sentence a player has to be
## able to read while running.
static func offset_at(
	elapsed: float, warn: float, fall: float, hold: float,
	gravity: float, shake: float, shake_hz: float
) -> Vector2:
	match phase_at(elapsed, warn, fall, hold):
		Phase.SHAKING:
			var ramp := clampf(elapsed / maxf(warn, 0.0001), 0.0, 1.0)
			return Vector2(sin(elapsed * TAU * shake_hz) * shake * ramp, 0.0)
		Phase.FALLING:
			return Vector2(0.0, drop_offset(elapsed - warn, gravity))
		Phase.GONE:
			# Parked at the bottom of its fall rather than at home, so a slab
			# that is waiting to come back is not sitting invisibly in the gap
			# it left.
			return Vector2(0.0, drop_offset(fall, gravity))
		_:
			return Vector2.ZERO


## For the debug overlay and `tools/capture.gd`. A screenshot of a platform at
## home and a screenshot of one that is about to go are the same picture.
static func phase_name(phase: Phase) -> String:
	match phase:
		Phase.SHAKING:
			return "shaking"
		Phase.FALLING:
			return "falling"
		Phase.GONE:
			return "gone"
		_:
			return "steady"


## Whether this landing (the first is 1) arms a slab that holds `holds`
## landings before it goes (N1: a slab that drops the second time you cross
## it holds one). Each landing it holds is only a creak.
static func arms_on(landing: int, holds: int) -> bool:
	return landing > maxi(holds, 0)
