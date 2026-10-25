## The bat's path, as arithmetic: it stays inside its box, and it is not
## secretly a circle.
extends TestCase

const HALF := Vector2(80.0, 40.0)
const SPEED := 2.4
const RATIO := 0.63


func test_offset_never_leaves_the_box() -> void:
	var t := 0.0
	while t < 30.0:
		var offset := BatFlight.offset_at(t, SPEED, RATIO, HALF)
		check(absf(offset.x) <= HALF.x + 0.001, "x offset %.2f exceeds half-extent %.2f" % [offset.x, HALF.x])
		check(absf(offset.y) <= HALF.y + 0.001, "y offset %.2f exceeds half-extent %.2f" % [offset.y, HALF.y])
		t += 0.13


## A ratio of 1 would trace an ellipse and repeat every cycle of the x axis.
## 0.63 should not: sampled a quarter of the way into the x axis's own period,
## the y axis has not returned to the same point.
func test_the_ratio_keeps_it_off_an_ellipse() -> void:
	var period_x := TAU / SPEED
	var y_at_start := BatFlight.offset_at(0.0, SPEED, RATIO, HALF).y
	var y_a_quarter_later := BatFlight.offset_at(period_x * 0.25, SPEED, RATIO, HALF).y
	check(
		absf(y_at_start - y_a_quarter_later) > 1.0,
		"the y offset barely moved a quarter of the way round, which reads as an ellipse"
	)


func test_facing_holds_through_a_zero_crossing() -> void:
	# velocity_at's x term is a cosine, which crosses zero at t = period/4.
	var period_x := TAU / SPEED
	var quarter := period_x * 0.25
	var facing := BatFlight.facing_at(quarter, SPEED, RATIO, HALF, 1.0)
	check(facing == 1.0, "a zero-velocity frame should keep the facing it was given, got %.1f" % facing)


## Matt, 2026-10-25: bats flew into the walls and floors round their box.
const BODY := Vector2(17.0, 17.0)
const BOX := Rect2(0.0, 0.0, 112.0, 80.0)


func test_a_box_in_open_air_is_left_alone() -> void:
	var none: Array[Rect2] = []
	var fitted := BatFlight.fitted_box(BOX, BODY, none)
	check(fitted == BOX, "an open box changed: %s" % fitted)


func test_a_floor_pulls_the_bottom_up_by_half_the_bat() -> void:
	var floor_only: Array[Rect2] = [Rect2(-50.0, 80.0, 300.0, 16.0)]
	var fitted := BatFlight.fitted_box(BOX, BODY, floor_only)
	check(is_equal_approx(fitted.end.y, 80.0 - BODY.y), "bottom at %.1f" % fitted.end.y)
	check(is_equal_approx(fitted.position.y, 0.0), "the open top moved to %.1f" % fitted.position.y)
	check(is_equal_approx(fitted.size.x, BOX.size.x), "the open sides moved")


func test_the_drawn_bat_never_enters_a_wall_it_touches() -> void:
	var walls: Array[Rect2] = [
		Rect2(-16.0, -16.0, 16.0, 120.0), Rect2(0.0, -16.0, 112.0, 16.0),
		Rect2(112.0, -16.0, 16.0, 120.0), Rect2(0.0, 80.0, 112.0, 16.0),
	]
	var fitted := BatFlight.fitted_box(BOX, BODY, walls)
	var t := 0.0
	while t < 30.0:
		var centre := fitted.get_center() + BatFlight.offset_at(t, SPEED, RATIO, fitted.size * 0.5)
		var drawn := Rect2(centre - BODY, BODY * 2.0)
		for w in walls:
			check(not drawn.intersects(w), "at t=%.2f the bat at %s is inside %s" % [t, centre, w])
		t += 0.13


func test_a_box_narrower_than_the_bat_holds_it_still_on_that_axis() -> void:
	var sides: Array[Rect2] = [Rect2(-16.0, 0.0, 16.0, 80.0), Rect2(24.0, 0.0, 16.0, 80.0)]
	var fitted := BatFlight.fitted_box(Rect2(0.0, 0.0, 24.0, 80.0), BODY, sides)
	check(is_zero_approx(fitted.size.x), "width %.1f" % fitted.size.x)
	check(is_equal_approx(fitted.get_center().x, 12.0), "centre x %.1f" % fitted.get_center().x)
