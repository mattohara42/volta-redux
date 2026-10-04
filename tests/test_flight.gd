## The ending's flight: every gap fits the dragon, and every gap can be reached
## from the one before it at the configured speeds.
extends TestCase


func test_steering_stays_inside_the_cavern() -> void:
	check_eq(FlightRules.height_after(50.0, -1.0, 100.0, 1.0, 40.0, 300.0), 40.0, "the ceiling stops a climb")
	check_eq(FlightRules.height_after(290.0, 1.0, 100.0, 1.0, 40.0, 300.0), 300.0, "the floor stops a dive")
	check_near(FlightRules.height_after(100.0, 1.0, 100.0, 0.5, 40.0, 300.0), 150.0, 0.001, "and between them it moves")


func test_a_pillar_crashes_the_rider() -> void:
	var pillars: Array[Rect2] = [Rect2(100.0, 0.0, 40.0, 100.0)]
	check(FlightRules.crashed(Rect2(90.0, 80.0, 20.0, 20.0), pillars), "touching one")
	check(not FlightRules.crashed(Rect2(90.0, 120.0, 20.0, 20.0), pillars), "passing under it")


func test_every_gap_is_flyable() -> void:
	var flight: FlightConfig = load("res://config/flight.tres")
	var size_y := DragonRider.SIZE.y
	var start := Act4Flight.START.y + DragonRider.BOX_OFFSET.y
	var previous := Vector2(start - size_y * 0.5, start + size_y * 0.5)
	var previous_x := Act4Flight.START.x
	for gap in Act4Flight.GAPS:
		var here := Vector2(gap.y, gap.z)
		var distance: float = gap.x - previous_x - DragonRider.SIZE.x
		check(FlightRules.reachable(previous, here, size_y, distance, flight.forward_speed, flight.vertical_speed), "the gap at %.0f can be reached from the one before" % gap.x)
		previous = here
		previous_x = gap.x + Act4Flight.PILLAR_WIDTH
	check(Act4Flight.FINISH_X > Act4Flight.GAPS[Act4Flight.GAPS.size() - 1].x, "the way out is past the last pillar")
