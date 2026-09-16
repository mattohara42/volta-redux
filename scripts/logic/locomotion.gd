## Which locomotion animation state the hero's rig should be in. Pure and
## testable: everything here is a function of horizontal speed, nothing else.
##
## ANIMATION.md: idle and run are both rig states, driven by an AnimationTree
## state machine on `hero_rig.tscn`. This file owns which of its two states
## applies; the character script only reads the answer and travels there.
class_name Locomotion

enum State { IDLE, RUN }


## Any nonzero horizontal speed reads as running. `Motion.step_horizontal`
## brings speed to exactly zero at a stop rather than merely close to it, so
## no epsilon is needed to tell "stopped" from "still slowing down".
static func state_for(speed_x: float) -> State:
	return State.IDLE if is_zero_approx(speed_x) else State.RUN


## The AnimationTree state machine's own node names, which `hero_rig.tscn`'s
## animations are authored under. One place both sides read from, so a rename
## there cannot desync from the travel target here.
static func state_name(state: State) -> String:
	match state:
		State.RUN:
			return "run"
		_:
			return "idle"
