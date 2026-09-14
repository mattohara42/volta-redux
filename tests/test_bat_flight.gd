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
