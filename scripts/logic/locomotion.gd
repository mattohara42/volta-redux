## Which animation state the hero's sprite should be in. Pure and testable:
## everything here is a function of ground contact, vertical and horizontal
## speed, climbing, dying, and whether a landing, throw or catch just happened.
##
## ANIMATION.md: each state is a frame animation, picked by an AnimationTree
## state machine on `hero_sprite.tscn`. This file owns which state applies;
## the character script only reads the answer and travels there.
class_name Locomotion

enum State {
	IDLE, RUN, JUMP, FALL, LAND, THROW, CATCH, CLIMB, CLIMB_STILL, DIE, SOMERSAULT, DIVE, DIVE_LAND
}


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
##
## Dying beats everything: it is the one state nothing else may interrupt.
## `dying` is the death hold only, not the respawn freeze after it, or the
## hero would lie down again at the brazier. Climbing beats airborne, since a
## climber has no gravity, and holds a still frame when not moving so a hero
## hanging on a ladder does not keep pumping his limbs.
##
## A somersault is the airborne state of a jump that began moving, from takeoff
## to landing. A dive is any fall at or past `dive_speed`, and it beats the
## somersault: a hero dropping a full storey stretches out whatever he was
## doing. The landing that follows a dive holds DIVE_LAND for `recovery_timer`
## instead of the ordinary LAND. `dive_speed` defaults to never, so a caller
## that has no dive (a test, a rig) never sees one.
static func state_for(
	on_floor: bool, velocity_y: float, landing_timer: float, speed_x: float,
	throw_timer: float = 0.0, catch_timer: float = 0.0,
	climbing: bool = false, dying: bool = false,
	somersaulting: bool = false, dive_speed: float = INF, recovery_timer: float = 0.0
) -> State:
	if dying:
		return State.DIE
	if catch_timer > 0.0:
		return State.CATCH
	if throw_timer > 0.0:
		return State.THROW
	if climbing:
		var moving := not is_zero_approx(velocity_y) or not is_zero_approx(speed_x)
		return State.CLIMB if moving else State.CLIMB_STILL
	if not on_floor:
		if lands_a_dive(velocity_y, dive_speed):
			return State.DIVE
		if somersaulting:
			return State.SOMERSAULT
		return State.JUMP if velocity_y < 0.0 else State.FALL
	if recovery_timer > 0.0:
		return State.DIVE_LAND
	if landing_timer > 0.0:
		return State.LAND
	return State.IDLE if is_zero_approx(speed_x) else State.RUN


## The AnimationTree state machine's own node names, which
## `hero_sprite.tscn`'s animations are authored under. One place both sides read from, so a rename
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
		State.CLIMB:
			return "climb"
		State.CLIMB_STILL:
			return "climb_still"
		State.DIE:
			return "die"
		State.SOMERSAULT:
			return "somersault"
		State.DIVE:
			return "dive"
		State.DIVE_LAND:
			return "dive_land"
		_:
			return "idle"


## A jump taken while moving is a somersault. SPEC.md: a move that looks that
## different has to behave differently, and what it changes is what you can do
## in the air (`can_throw`), not where it takes you: every room is measured
## against a full-speed jump's reach, so the flip flies the same arc.
static func starts_somersault(speed_x: float, min_speed: float) -> bool:
	return absf(speed_x) >= min_speed


## A fall this fast is a dive, and landing from one costs a recovery pause.
## Positive is downward, as everywhere in `Motion`.
static func lands_a_dive(fall_speed: float, dive_speed: float) -> bool:
	return fall_speed >= dive_speed


## The throw button does nothing mid-somersault and nothing during the pause
## after a dive. Recall is the same button held, so it waits too: committing to
## the flip is the price of the reach it gives you (`ANIMATION.md`).
static func can_throw(somersaulting: bool, recovering: bool) -> bool:
	return not somersaulting and not recovering
