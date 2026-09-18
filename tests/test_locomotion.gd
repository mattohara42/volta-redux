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
	# hero_rig.tscn's AnimationNodeStateMachine states are named to match.
	check_eq(Locomotion.state_name(Locomotion.State.IDLE), "idle", "idle state name")
	check_eq(Locomotion.state_name(Locomotion.State.RUN), "run", "run state name")
	check_eq(Locomotion.state_name(Locomotion.State.JUMP), "jump", "jump state name")
	check_eq(Locomotion.state_name(Locomotion.State.FALL), "fall", "fall state name")
	check_eq(Locomotion.state_name(Locomotion.State.LAND), "land", "land state name")
	check_eq(Locomotion.state_name(Locomotion.State.THROW), "throw", "throw state name")
	check_eq(Locomotion.state_name(Locomotion.State.CATCH), "catch", "catch state name")


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
