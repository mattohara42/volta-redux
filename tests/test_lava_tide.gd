## The lava tide's rule. It starts low, so a respawn lands in a dry window; it
## moves smoothly between its two levels; and its dry window for a floor is the
## low hold plus the part of the rise still under that floor.
extends TestCase


func test_it_starts_low_and_cycles_in_order() -> void:
	check_eq(LavaTide.phase_at(0.0, 2.0, 1.0, 1.5, 1.0), LavaTide.Phase.LOW, "zero is low")
	check_eq(LavaTide.phase_at(2.5, 2.0, 1.0, 1.5, 1.0), LavaTide.Phase.RISING, "then rising")
	check_eq(LavaTide.phase_at(3.5, 2.0, 1.0, 1.5, 1.0), LavaTide.Phase.HIGH, "then high")
	check_eq(LavaTide.phase_at(5.0, 2.0, 1.0, 1.5, 1.0), LavaTide.Phase.FALLING, "then falling")
	check_eq(LavaTide.phase_at(5.6, 2.0, 1.0, 1.5, 1.0), LavaTide.Phase.LOW, "and round again")


func test_the_level_moves_between_its_ends() -> void:
	check_eq(LavaTide.level_at(1.0, 2.0, 1.0, 1.5, 1.0, 336.0, 296.0), 336.0, "low is the low level")
	check_eq(LavaTide.level_at(4.0, 2.0, 1.0, 1.5, 1.0, 336.0, 296.0), 296.0, "high is the high level")
	var mid := LavaTide.level_at(2.5, 2.0, 1.0, 1.5, 1.0, 336.0, 296.0)
	check(mid < 336.0 and mid > 296.0, "halfway up it is between them")


func test_the_dry_window_ends_when_the_lava_reaches_the_floor() -> void:
	var window := LavaTide.dry_window(2.0, 1.0, 336.0, 296.0, 320.0)
	check(window > 2.0 and window < 3.0, "the low hold plus part of the rise (%.2f s)" % window)
	check_near(LavaTide.level_at(window, 2.0, 1.0, 1.5, 1.0, 336.0, 296.0), 320.0, 0.1, "and at its end the lava is at the floor")
