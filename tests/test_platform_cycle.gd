## The falling platform's clock.
##
## Everything a falling platform is made of is a duration, so this is where the
## hazard actually lives. The node around it senses a foot, moves a body and
## draws a slab, and none of those three can be asserted headlessly.
extends TestCase

const HAZARDS := "res://config/hazards.tres"

# A slab on the floor of a bench: 320 px down to the bottom of a 360 px room,
# plus its own depth. The numbers are only here to give the phases something
# real to be measured against.
const DROP: float = 52.0
const WARN: float = 0.45
const HOLD: float = 0.8
const GRAVITY: float = 1400.0


func _fall() -> float:
	return PlatformCycle.fall_seconds(DROP, GRAVITY)


func _phase(elapsed: float) -> PlatformCycle.Phase:
	return PlatformCycle.phase_at(elapsed, WARN, _fall(), HOLD)


func test_a_platform_nobody_has_touched_is_steady() -> void:
	check_eq(_phase(-1.0), PlatformCycle.Phase.STEADY, "untouched is steady")
	check_eq(_phase(0.0), PlatformCycle.Phase.SHAKING, "standing on it arms it")


## The order of the cycle, which is the whole of the design: it warns, it goes,
## it is missing, it is back.
func test_the_cycle_runs_in_order() -> void:
	var fall := _fall()
	check_eq(_phase(WARN * 0.5), PlatformCycle.Phase.SHAKING, "it warns first")
	check_eq(_phase(WARN + fall * 0.5), PlatformCycle.Phase.FALLING, "then it goes")
	check_eq(_phase(WARN + fall + HOLD * 0.5), PlatformCycle.Phase.GONE, "then it is missing")
	check_eq(
		_phase(PlatformCycle.cycle_seconds(WARN, fall, HOLD)),
		PlatformCycle.Phase.STEADY,
		"and then it is back, load bearing, as if nothing happened"
	)
	check_eq(_phase(1000.0), PlatformCycle.Phase.STEADY, "and it stays back")


## The one rule that separates this from a trapdoor. A slab that vanished the
## moment it let go would have no frame in it where the player can react, and
## the whole hazard is that you can still jump off what is already falling.
func test_it_is_solid_all_the_way_down() -> void:
	check(PlatformCycle.is_solid(PlatformCycle.Phase.STEADY), "steady holds you")
	check(PlatformCycle.is_solid(PlatformCycle.Phase.SHAKING), "a warning still holds you")
	check(PlatformCycle.is_solid(PlatformCycle.Phase.FALLING), "and so does a falling slab")
	check(
		not PlatformCycle.is_solid(PlatformCycle.Phase.GONE),
		"only a slab that has left the room is not there to land on"
	)


## The fall is derived from how far it has to go, so a room that hangs a
## platform somewhere else does not need a second number in the config.
func test_the_fall_is_as_long_as_the_drop_makes_it() -> void:
	check_near(
		PlatformCycle.drop_offset(_fall(), GRAVITY), DROP, 0.01,
		"a platform has fallen exactly its drop when its fall is over"
	)
	check(
		PlatformCycle.fall_seconds(DROP * 4.0, GRAVITY) > _fall(),
		"a platform hung higher up takes longer to get out of the room"
	)
	check_eq(PlatformCycle.fall_seconds(0.0, GRAVITY), 0.0, "no drop, no fall")
	check_eq(PlatformCycle.fall_seconds(DROP, 0.0), 0.0, "no gravity, no fall")


func test_a_platform_that_has_gone_is_out_of_the_room_and_not_at_home() -> void:
	var fall := _fall()
	var offset := PlatformCycle.offset_at(
		WARN + fall + HOLD * 0.5, WARN, fall, HOLD, GRAVITY, 1.5, 16.0
	)
	check_near(offset.y, DROP, 0.01, "it waits out its absence at the bottom of its fall")


## The shake is the only warning there is, and a tell that does not grow says
## "something is happening" rather than "this is about to go".
func test_the_warning_shake_ramps_up() -> void:
	var fall := _fall()
	var biggest_early := 0.0
	var biggest_late := 0.0
	for i in 200:
		var t := WARN * float(i) / 200.0
		var offset := PlatformCycle.offset_at(t, WARN, fall, HOLD, GRAVITY, 1.5, 16.0)
		if t < WARN * 0.25:
			biggest_early = maxf(biggest_early, absf(offset.x))
		elif t > WARN * 0.75:
			biggest_late = maxf(biggest_late, absf(offset.x))
	check(
		biggest_late > biggest_early * 2.0,
		"the tremor at the end is %.2f px against %.2f px at the start" % [
			biggest_late, biggest_early
		]
	)
	check(biggest_late <= 1.5, "and it never throws the slab further than the config says")


## A shaking platform is still exactly where it was vertically. It is a tremor,
## not a sag, and a slab that dipped would change the jump you are about to make.
func test_the_warning_does_not_move_the_slab_down() -> void:
	var fall := _fall()
	for i in 50:
		var offset := PlatformCycle.offset_at(
			WARN * float(i) / 50.0, WARN, fall, HOLD, GRAVITY, 1.5, 16.0
		)
		check_eq(offset.y, 0.0, "a warning shake is sideways only")


## The config's own numbers, against the room they have to serve.
func test_the_real_numbers_make_a_platform_worth_standing_on() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var fall := PlatformCycle.fall_seconds(DROP, hazards.platform_fall_gravity)
	check(
		fall < hazards.platform_warn_time,
		"a slab leaves the room in %.2f s, faster than the %.2f s it warned you for" % [
			fall, hazards.platform_warn_time
		]
	)
	check(
		PlatformCycle.cycle_seconds(
			hazards.platform_warn_time, fall, hazards.platform_return_time
		) < 2.0,
		"the whole cycle is under two seconds, so going back is a cost and not a queue"
	)


## N1: a slab that holds one landing creaks on the first and goes on the
## second; an ordinary slab goes on the first.
func test_a_slab_arms_on_the_landing_after_the_ones_it_holds() -> void:
	check(PlatformCycle.arms_on(1, 0), "an ordinary slab arms on the first landing")
	check(not PlatformCycle.arms_on(1, 1), "one that holds one creaks on the first")
	check(PlatformCycle.arms_on(2, 1), "and goes on the second")
	check(not PlatformCycle.arms_on(2, 2), "one that holds two holds the second too")
