## Which locomotion state the hero's rig reads as, from ground contact,
## vertical and horizontal speed, and a landing hold.
extends TestCase


func test_standing_still_is_idle() -> void:
	check_eq(Locomotion.state_for(true, 0.0, 0.0, 0.0), Locomotion.State.IDLE, "zero speed")


func test_any_speed_either_way_is_run() -> void:
	check_eq(Locomotion.state_for(true, 0.0, 0.0, 50.0), Locomotion.State.RUN, "moving right")
	check_eq(Locomotion.state_for(true, 0.0, 0.0, -50.0), Locomotion.State.RUN, "moving left")
	check_eq(Locomotion.state_for(true, 0.0, 0.0, 0.001), Locomotion.State.RUN, "barely moving still counts")


func test_rising_off_the_floor_is_jump() -> void:
	check_eq(Locomotion.state_for(false, -400.0, 0.0, 0.0), Locomotion.State.JUMP, "rising")


func test_falling_off_the_floor_is_fall_however_it_started() -> void:
	check_eq(Locomotion.state_for(false, 200.0, 0.0, 0.0), Locomotion.State.FALL, "falling after the apex")
	check_eq(Locomotion.state_for(false, 0.0, 0.0, 0.0), Locomotion.State.FALL, "walked off a ledge, no jump")


func test_airborne_wins_over_a_stale_landing_timer() -> void:
	check_eq(
		Locomotion.state_for(false, -400.0, 0.2, 0.0), Locomotion.State.JUMP,
		"a second jump mid-hold should not get stuck on the landing pose"
	)


func test_landing_timer_holds_land_until_it_lapses() -> void:
	check_eq(Locomotion.state_for(true, 0.0, 0.05, 0.0), Locomotion.State.LAND, "timer still running")
	check_eq(Locomotion.state_for(true, 0.0, 0.0, 0.0), Locomotion.State.IDLE, "timer lapsed, standing")
	check_eq(Locomotion.state_for(true, 0.0, 0.0, 80.0), Locomotion.State.RUN, "timer lapsed, moving")


func test_state_names_match_the_state_machine_nodes() -> void:
	# hero_sprite.tscn's AnimationNodeStateMachine states are named to match.
	check_eq(Locomotion.state_name(Locomotion.State.IDLE), "idle", "idle state name")
	check_eq(Locomotion.state_name(Locomotion.State.RUN), "run", "run state name")
	check_eq(Locomotion.state_name(Locomotion.State.JUMP), "jump", "jump state name")
	check_eq(Locomotion.state_name(Locomotion.State.FALL), "fall", "fall state name")
	check_eq(Locomotion.state_name(Locomotion.State.LAND), "land", "land state name")
	check_eq(Locomotion.state_name(Locomotion.State.THROW), "throw", "throw state name")
	check_eq(Locomotion.state_name(Locomotion.State.CATCH), "catch", "catch state name")
	check_eq(Locomotion.state_name(Locomotion.State.CLIMB), "climb", "climb state name")
	check_eq(Locomotion.state_name(Locomotion.State.CLIMB_STILL), "climb_still", "climb_still state name")
	check_eq(Locomotion.state_name(Locomotion.State.DIE), "die", "die state name")
	check_eq(Locomotion.state_name(Locomotion.State.SOMERSAULT), "somersault", "somersault state name")
	check_eq(Locomotion.state_name(Locomotion.State.DIVE), "dive", "dive state name")
	check_eq(Locomotion.state_name(Locomotion.State.DIVE_LAND), "dive_land", "dive_land state name")


func test_a_throw_timer_wins_over_ground_and_air_alike() -> void:
	check_eq(
		Locomotion.state_for(true, 0.0, 0.0, 0.0, 0.1, 0.0), Locomotion.State.THROW,
		"grounded and standing still, but a throw just fired"
	)
	check_eq(
		Locomotion.state_for(false, -400.0, 0.0, 0.0, 0.1, 0.0), Locomotion.State.THROW,
		"mid-jump, but a throw just fired: the wind-up still has to read"
	)
	check_eq(
		Locomotion.state_for(true, 0.0, 0.1, 0.0, 0.1, 0.0), Locomotion.State.THROW,
		"a throw fired mid-landing-hold takes over from LAND"
	)


func test_a_catch_timer_wins_over_a_throw_timer() -> void:
	check_eq(
		Locomotion.state_for(true, 0.0, 0.0, 0.0, 0.1, 0.1), Locomotion.State.CATCH,
		"both timers running at once: the catch is the one that has to be legible"
	)


func test_throw_and_catch_lapse_back_to_whatever_state_for_says_next() -> void:
	check_eq(
		Locomotion.state_for(true, 0.0, 0.0, 0.0, 0.0, 0.0), Locomotion.State.IDLE,
		"timer lapsed, standing"
	)
	check_eq(
		Locomotion.state_for(false, -400.0, 0.0, 0.0, 0.0, 0.0), Locomotion.State.JUMP,
		"timer lapsed, still rising"
	)


func test_dying_beats_everything() -> void:
	check_eq(
		Locomotion.state_for(false, 300.0, 0.1, 80.0, 0.1, 0.1, true, true), Locomotion.State.DIE,
		"dying mid-air, mid-catch, on a ladder is still dying"
	)


func test_climbing_beats_airborne_and_holds_still_when_not_moving() -> void:
	check_eq(
		Locomotion.state_for(false, -90.0, 0.0, 0.0, 0.0, 0.0, true), Locomotion.State.CLIMB,
		"climbing up the ladder"
	)
	check_eq(
		Locomotion.state_for(false, 0.0, 0.0, 30.0, 0.0, 0.0, true), Locomotion.State.CLIMB,
		"shuffling sideways on the ladder"
	)
	check_eq(
		Locomotion.state_for(false, 0.0, 0.0, 0.0, 0.0, 0.0, true), Locomotion.State.CLIMB_STILL,
		"hanging still on the ladder"
	)


func test_a_throw_from_a_ladder_still_shows_the_throw() -> void:
	check_eq(
		Locomotion.state_for(false, 0.0, 0.0, 0.0, 0.1, 0.0, true), Locomotion.State.THROW,
		"throwing while climbing"
	)


## The state_for arguments after `dying`, spelled once so the tests below read.
func _air(velocity_y: float, somersaulting: bool, dive_speed: float = INF) -> Locomotion.State:
	return Locomotion.state_for(
		false, velocity_y, 0.0, 100.0, 0.0, 0.0, false, false, somersaulting, dive_speed
	)


func test_a_moving_jump_is_a_somersault_from_takeoff_to_landing() -> void:
	check_eq(_air(-400.0, true), Locomotion.State.SOMERSAULT, "rising")
	check_eq(_air(300.0, true), Locomotion.State.SOMERSAULT, "falling")
	check_eq(_air(-400.0, false), Locomotion.State.JUMP, "the same rise without the flip")
	check_eq(_air(300.0, false), Locomotion.State.FALL, "the same fall without the flip")


func test_a_fast_enough_fall_is_a_dive_and_beats_the_somersault() -> void:
	check_eq(_air(640.0, false, 640.0), Locomotion.State.DIVE, "at the threshold")
	check_eq(_air(700.0, true, 640.0), Locomotion.State.DIVE, "a flip dropped a full storey")
	check_eq(_air(639.0, false, 640.0), Locomotion.State.FALL, "just under is an ordinary fall")
	check_eq(_air(-700.0, false, 640.0), Locomotion.State.JUMP, "rising is never a dive")


func test_no_dive_speed_means_no_dive() -> void:
	check_eq(_air(9999.0, false), Locomotion.State.FALL, "the default threshold is never")


func test_landing_from_a_dive_holds_the_dive_landing_not_the_ordinary_one() -> void:
	check_eq(
		Locomotion.state_for(true, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, 640.0, 0.2),
		Locomotion.State.DIVE_LAND, "recovering beats the ordinary landing hold"
	)
	check_eq(
		Locomotion.state_for(true, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, 640.0, 0.0),
		Locomotion.State.LAND, "no recovery left, the ordinary landing hold"
	)


func test_a_somersault_ends_on_the_ground() -> void:
	check_eq(
		Locomotion.state_for(true, 0.0, 0.0, 100.0, 0.0, 0.0, false, false, true),
		Locomotion.State.RUN, "on the floor the flip flag no longer shows"
	)


func test_dying_still_beats_a_dive_and_a_somersault() -> void:
	check_eq(
		Locomotion.state_for(false, 700.0, 0.0, 0.0, 0.0, 0.0, false, true, true, 640.0, 0.2),
		Locomotion.State.DIE, "dying"
	)


func test_a_jump_starts_a_somersault_only_when_moving() -> void:
	check(Locomotion.starts_somersault(200.0, 20.0), "running right")
	check(Locomotion.starts_somersault(-200.0, 20.0), "running left")
	check(Locomotion.starts_somersault(26.0, 20.0), "one frame of held direction from a standstill")
	check(not Locomotion.starts_somersault(0.0, 20.0), "straight up")
	check(not Locomotion.starts_somersault(19.0, 20.0), "drifting")


func test_the_throw_button_is_dead_mid_somersault_and_during_recovery() -> void:
	check(Locomotion.can_throw(false, false), "on your feet")
	check(not Locomotion.can_throw(true, false), "mid-somersault")
	check(not Locomotion.can_throw(false, true), "recovering from a dive")
	check(not Locomotion.can_throw(true, true), "both")
