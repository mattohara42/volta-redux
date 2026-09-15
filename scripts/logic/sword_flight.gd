## The sword's state machine, as pure functions.
##
## CLAUDE.md: the sword is one scene and one script, and every behaviour it has
## is a state in that one machine. This file is that machine's rules, kept out
## of the node so a headless test can walk every transition without a room.
##
## The return leg is flat. The sword comes back along the height it was thrown
## at, steering only in x toward wherever the player now is, which is what makes
## a missed catch possible at all: you miss by changing height, not by being in
## the wrong place. SPEC.md calls it a flat arc and the floating eyeball exists
## to sit on that line.
class_name SwordFlight

enum State {
	## Outbound, to max range.
	FLYING,
	## Coming back, steering in x toward the player's current position.
	RETURNING,
	## Coming back from wood, steering in both axes. See `recall_velocity`.
	RECALLING,
	## Bitten into wood, and a one-tile ledge while it stays there.
	EMBEDDED,
	## Spent. Gravity has it now.
	FALLING,
	## Lying on the floor, waiting to be walked over.
	GROUNDED,
	## Terminal: back in the player's hand.
	CAUGHT,
	## Terminal: hit something solid mid-flight and is gone.
	DESTROYED,
}

## What the sword just ran into. One value rather than a pair of booleans,
## because it cannot hit two kinds of surface in a frame and a pair would let
## the caller say that it did.
enum Contact {
	NONE,
	## Stone, and the end of that sword.
	SOLID,
	## Wood, which bites and holds. SPEC.md: this is the move that turns a
	## weapon into a traversal tool.
	WOOD,
}


## The whole transition table in one function, so the machine can be read rather
## than reconstructed from scattered ifs.
##
## Order matters in RETURNING: a catch beats a solid hit. If the sword got
## inside your catch radius the throw already succeeded, and standing near a
## wall should not cost you the sword.
##
## A contact only decides anything during flight. A sword that is already
## falling is already spent, and the floor it lands on is not what killed it.
##
## Wood beats stone on both flight legs, so the surface decides the outcome and
## not which direction the sword happened to be going.
##
## A recall cannot fail. It steers through geometry and ends in your hand, and
## the price of it is the ledge you just gave up, not the sword.
static func next_state(
	state: State,
	at_max_range: bool,
	return_spent: bool,
	caught: bool,
	picked_up: bool,
	contact: Contact,
	overshot: bool,
	on_floor: bool,
	recalled: bool
) -> State:
	match state:
		State.FLYING:
			if contact == Contact.WOOD:
				return State.EMBEDDED
			if contact == Contact.SOLID:
				return State.DESTROYED
			if at_max_range:
				return State.RETURNING
			return State.FLYING
		State.RETURNING:
			if caught:
				return State.CAUGHT
			if contact == Contact.WOOD:
				return State.EMBEDDED
			if contact == Contact.SOLID:
				return State.DESTROYED
			if overshot or return_spent:
				return State.FALLING
			return State.RETURNING
		State.RECALLING:
			if caught:
				return State.CAUGHT
			return State.RECALLING
		State.EMBEDDED:
			if recalled:
				return State.RECALLING
			return State.EMBEDDED
		State.FALLING:
			if on_floor:
				return State.GROUNDED
			return State.FALLING
		State.GROUNDED:
			if picked_up:
				return State.CAUGHT
			return State.GROUNDED
	return state


## True once the outbound leg has run its length.
static func at_max_range(distance_travelled: float, max_range: float) -> bool:
	return distance_travelled >= max_range


## True once the return leg has run out of patience, which is what happens when
## you run away from your own sword.
static func return_spent(return_distance: float, max_return_distance: float) -> bool:
	return return_distance >= max_return_distance


## The sword steers in x only, so passing the player's x without catching is the
## miss. Compared as signs rather than positions because the player is moving.
static func has_overshot(offset_before: float, offset_after: float) -> bool:
	if is_zero_approx(offset_before) or is_zero_approx(offset_after):
		return false
	return signf(offset_before) != signf(offset_after)


## Horizontal steering for the return leg. Full speed toward the player's x, and
## the height it was thrown at is not up for negotiation.
static func return_velocity_x(sword_x: float, target_x: float, speed: float) -> float:
	var offset := target_x - sword_x
	if is_zero_approx(offset):
		return 0.0
	return signf(offset) * speed


## True when the sword is close enough to be back in your hand.
static func is_within(sword_position: Vector2, target: Vector2, radius: float) -> bool:
	return sword_position.distance_squared_to(target) <= radius * radius


## Recall steers in **both** axes, which is the one place the sword breaks its
## own flat rule. An embedded sword is above or below you far more often than
## beside you, because being above you is why you threw it at that plank.
static func recall_velocity(sword_position: Vector2, target: Vector2, speed: float) -> Vector2:
	var offset := target - sword_position
	if offset.length_squared() < 0.000001:
		return Vector2.ZERO
	return offset.normalized() * speed


## Where a sword ends up when it bites wood: exactly half a blade clear of the
## surface, so the whole one-tile ledge is outside the plank.
##
## Takes the **surface**, not the sword. An earlier version guessed from the
## sword's own position on the frame the overlap was reported, on the theory
## that it would be about a half-length short of the surface. It is not. A
## captured throw put the sword 12 px inside the plank, which left 7.9 px of
## standable ledge against an 18 px player: the wall pushed the player straight
## off the end of it. Measuring the surface instead makes the answer exact and
## independent of speed and of when the physics engine gets round to telling us.
##
## The ledge is one tile and `WorldConfig.sword_length` is one tile. Those two
## numbers are tied together on purpose and the comment in that file says so.
static func embed_position(surface_x: float, direction: float, length: float) -> float:
	return surface_x - signf(direction) * length * 0.5


## Whether a sword in this state is holding a switch down.
##
## Only an embedded one. A sword flying through a switch does not trip it, and
## one lying on the floor across it does not hold it, because the switch is
## weight in a socket rather than a tripwire. Stated here rather than inside the
## switch so that the rule is one line in the machine that owns sword state.
static func holds_a_switch(state: State) -> bool:
	return state == State.EMBEDDED


## Whether a sword in this state is weight on a floor plate.
##
## The opposite bias from `holds_a_switch`, and for a matching reason: a plate
## is a floor, not a socket, so what rests on it is a spent sword lying flat,
## never one still moving and never one biting a wall. A player who misses a
## catch on purpose, or gives up chasing a throw, can leave a sword behind to
## hold a plate down at the cost of the sword.
static func rests_on_a_plate(state: State) -> bool:
	return state == State.GROUNDED


## Hold-to-recall, per SPEC.md. The throw leaves on the press so that throwing
## never feels laggy, and the recall fires later on the same button, once it has
## been held longer than any tap could last. `already_fired` keeps one hold from
## recalling twice.
static func recall_triggered(held_for: float, hold_time: float, already_fired: bool) -> bool:
	return not already_fired and held_for >= hold_time


## One physics step of a spent sword falling, with its horizontal speed bleeding
## off so a miss lands near where it passed you.
static func step_fall(
	velocity: Vector2, gravity: float, drag: float, max_fall_speed: float, delta: float
) -> Vector2:
	return Vector2(
		move_toward(velocity.x, 0.0, drag * delta),
		minf(velocity.y + gravity * delta, max_fall_speed)
	)


## For the debug overlay, and for a test failure that should say more than "2".
static func state_name(state: State) -> String:
	return State.keys()[state].to_lower()
