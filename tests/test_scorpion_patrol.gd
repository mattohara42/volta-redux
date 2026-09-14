## The scorpion's walk and its armour, as arithmetic.
extends TestCase

const RANGE := 120.0
const SPEED := 60.0


func test_it_walks_the_whole_range_and_back() -> void:
	var leg := RANGE / SPEED
	check_near(ScorpionPatrol.offset_at(0.0, RANGE, SPEED), 0.0, 0.001, "starts at the near end")
	check_near(ScorpionPatrol.offset_at(leg, RANGE, SPEED), RANGE, 0.001, "reaches the far end at one leg")
	check_near(
		ScorpionPatrol.offset_at(leg * 2.0, RANGE, SPEED), 0.0, 0.001,
		"is back at the near end after two legs"
	)
	check_near(
		ScorpionPatrol.offset_at(leg * 0.5, RANGE, SPEED), RANGE * 0.5, 0.001,
		"is halfway at half a leg"
	)


func test_it_never_waits_at_either_end() -> void:
	check_near(
		ScorpionPatrol.period(RANGE, SPEED), (RANGE / SPEED) * 2.0, 0.001,
		"a patrol has no dock, so its period is exactly two crossings"
	)


func test_facing_flips_at_each_end() -> void:
	var leg := RANGE / SPEED
	check(ScorpionPatrol.facing_at(0.0, RANGE, SPEED) == 1.0, "walking out")
	check(ScorpionPatrol.facing_at(leg * 1.5, RANGE, SPEED) == -1.0, "walking back")


func test_a_hit_from_the_front_is_blocked() -> void:
	# Facing +1, hit arrives from the same side (positive x), below the armour
	# line: this is the mistake SPEC.md exists to punish.
	var vulnerable := ScorpionPatrol.is_vulnerable_to(Vector2(5.0, 0.0), 1.0, 20.0, 0.35)
	check(not vulnerable, "a front hit at body height should bounce off the armour")


func test_a_hit_from_behind_gets_through() -> void:
	var vulnerable := ScorpionPatrol.is_vulnerable_to(Vector2(-5.0, 0.0), 1.0, 20.0, 0.35)
	check(vulnerable, "a hit from the side opposite the facing should land")


func test_a_hit_from_above_gets_through_regardless_of_side() -> void:
	# Facing +1 and the hit arrives from the front side (x > 0), but high on
	# the body: SPEC.md's "or above" beats the side check.
	var vulnerable := ScorpionPatrol.is_vulnerable_to(Vector2(5.0, -19.0), 1.0, 20.0, 0.35)
	check(vulnerable, "a hit high on the body should land even from the armoured side")


func test_a_hit_at_body_height_from_the_front_does_not_count_as_above() -> void:
	var vulnerable := ScorpionPatrol.is_vulnerable_to(Vector2(5.0, 5.0), 1.0, 20.0, 0.35)
	check(not vulnerable, "a hit below the armour line and on the facing side should bounce")
