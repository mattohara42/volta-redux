## Which locomotion animation state the hero's rig should be in. Pure and
## testable: everything here is a function of ground contact, vertical and
## horizontal speed, and whether a landing just happened.
##
## ANIMATION.md: idle, run, jump, fall and land are all rig states, driven by
## an AnimationTree state machine on `hero_rig.tscn`. This file owns which of
## its five states applies; the character script only reads the answer and
## travels there.
class_name Locomotion

enum State { IDLE, RUN, JUMP, FALL, LAND }


## Airborne always wins, on the sign of vertical speed: rising reads as the
## jump, falling (including walking off a ledge with no jump at all) reads as
## the fall. Grounded and freshly landed holds LAND for as long as the caller
## keeps `landing_timer` above zero; once it lapses, ground state falls back
## to whichever of idle or run the horizontal speed says.
static func state_for(on_floor: bool, velocity_y: float, landing_timer: float, speed_x: float) -> State:
	if not on_floor:
		return State.JUMP if velocity_y < 0.0 else State.FALL
	if landing_timer > 0.0:
		return State.LAND
	return State.IDLE if is_zero_approx(speed_x) else State.RUN


## The AnimationTree state machine's own node names, which `hero_rig.tscn`'s
## animations are authored under. One place both sides read from, so a rename
## there cannot desync from the travel target here.
static func state_name(state: State) -> String:
	match state:
		State.RUN:
			return "run"
		State.JUMP:
			return "jump"
		State.FALL:
			return "fall"
		State.LAND:
			return "land"
		_:
			return "idle"
