## Which locomotion animation state the hero's rig should be in. Pure and
## testable: everything here is a function of ground contact, vertical and
## horizontal speed, and whether a landing, throw or catch just happened.
##
## ANIMATION.md: idle, run, jump, fall, land, throw and catch are all rig
## states, driven by an AnimationTree state machine on `hero_rig.tscn`. This
## file owns which of its seven states applies; the character script only
## reads the answer and travels there.
class_name Locomotion

enum State { IDLE, RUN, JUMP, FALL, LAND, THROW, CATCH }


## Catch beats throw beats everything else. Both are timer-held poses the
## same way LAND is: the caller sets `throw_timer`/`catch_timer` to the rig's
## own animation length the instant the action happens (a button press, a
## sword arriving home) and this just reads them back down to zero.
##
## Unlike LAND, these two beat "airborne always wins" on purpose. That rule
## exists so a second jump mid-hold is never stuck showing the landing pose;
## a throw or catch is not a byproduct of ground contact, it is a thing the
## player just did, and ANIMATION.md is explicit that both have to read:
## the throw's wind-up is telegraphed and the catch has to be legible in one
## frame. Neither of those survives losing to whichever way gravity happens
## to be pulling that frame, so they sit above JUMP/FALL instead of below it.
## A player who throws mid-jump and then lands before the throw pose lapses
## sees the throw pose hold through the landing too, which is the same "do
## not get stuck" question CLAUDE.md's tuning pass exists to answer by
## playing, not by reasoning about it here.
static func state_for(
	on_floor: bool, velocity_y: float, landing_timer: float, speed_x: float,
	throw_timer: float = 0.0, catch_timer: float = 0.0
) -> State:
	if catch_timer > 0.0:
		return State.CATCH
	if throw_timer > 0.0:
		return State.THROW
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
		State.THROW:
			return "throw"
		State.CATCH:
			return "catch"
		_:
			return "idle"
