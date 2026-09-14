## The eyeball's drift, as arithmetic: it closes on the target and it never
## leaves its roam box.
extends TestCase

const ROAM := Rect2(0.0, 0.0, 200.0, 120.0)


func test_it_moves_toward_the_target() -> void:
	var next := EyeballSeek.step(Vector2(10.0, 10.0), Vector2(100.0, 10.0), 45.0, 1.0, ROAM)
	check(next.x > 10.0, "should have moved toward the target's x")
	check_near(next.y, 10.0, 0.001, "y should not have moved when already level")


func test_it_does_not_overshoot_a_close_target() -> void:
	var next := EyeballSeek.step(Vector2(10.0, 10.0), Vector2(10.5, 10.0), 45.0, 1.0, ROAM)
	check_near(next.x, 10.5, 0.001, "a target closer than one step's travel should be reached exactly")


func test_it_is_clamped_to_the_roam_box_even_chasing_a_target_outside_it() -> void:
	var next := EyeballSeek.step(Vector2(190.0, 60.0), Vector2(500.0, 60.0), 45.0, 10.0, ROAM)
	check(next.x <= ROAM.end.x, "should not be pulled past the roam box chasing a far target")
