## Which locomotion state the hero's rig reads as, from speed alone.
extends TestCase


func test_standing_still_is_idle() -> void:
	check_eq(Locomotion.state_for(0.0), Locomotion.State.IDLE, "zero speed")


func test_any_speed_either_way_is_run() -> void:
	check_eq(Locomotion.state_for(50.0), Locomotion.State.RUN, "moving right")
	check_eq(Locomotion.state_for(-50.0), Locomotion.State.RUN, "moving left")
	check_eq(Locomotion.state_for(0.001), Locomotion.State.RUN, "barely moving still counts")


func test_state_names_match_the_state_machine_nodes() -> void:
	# hero_rig.tscn's AnimationNodeStateMachine states are named "idle" and
	# "run"; a mismatch here would travel to a state that does not exist.
	check_eq(Locomotion.state_name(Locomotion.State.IDLE), "idle", "idle state name")
	check_eq(Locomotion.state_name(Locomotion.State.RUN), "run", "run state name")
