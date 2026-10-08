## The hero's camera leads the way they run (N0), and its numbers are in
## `config/camera.tres`.
extends TestCase

const CONFIG := "res://config/camera.tres"


func test_running_draws_the_lead_out_ahead() -> void:
	var lead := CameraLead.step(0.0, 200.0, 64.0, 160.0, 20.0, 0.1)
	check_eq(lead, 16.0, "a tenth of a second at 160 px/s")
	check_eq(CameraLead.step(60.0, 200.0, 64.0, 160.0, 20.0, 1.0), 64.0, "and stops at the distance")


func test_turning_and_running_swings_it_to_the_other_side() -> void:
	check_eq(CameraLead.step(64.0, -200.0, 64.0, 160.0, 20.0, 0.5), -16.0, "back across the middle")


func test_standing_or_creeping_holds_it() -> void:
	check_eq(CameraLead.step(64.0, 0.0, 64.0, 160.0, 20.0, 1.0), 64.0, "standing still")
	check_eq(CameraLead.step(64.0, -10.0, 64.0, 160.0, 20.0, 1.0), 64.0, "a turn on the spot to throw")


func test_the_camera_numbers_make_sense() -> void:
	var config := load(CONFIG) as CameraConfig
	check(config != null, "config/camera.tres is a CameraConfig")
	check(config.look_ahead >= 0.0 and config.look_ahead < 320.0, "the lead keeps the hero on screen")
	check(config.look_ahead_speed > 0.0, "the lead moves")
	check(config.look_ahead_min_speed >= 0.0, "the hold speed is not negative")
	check(config.smoothing_speed > 0.0, "smoothing is positive")
