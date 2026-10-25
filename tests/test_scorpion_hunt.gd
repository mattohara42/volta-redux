## The hunting scorpion's mind, as arithmetic (`ScorpionHunt`).
extends TestCase

const SIGHT := Vector2(160.0, 40.0)
const WALK := 60.0
const HUNT := 100.0
const LOSE := 1.2
const DT := 1.0 / 60.0
const LO := 0.0
const HI := 120.0


func _state(x: float, facing: float = 1.0, hunting: bool = false) -> ScorpionHunt.State:
	var s := ScorpionHunt.State.new()
	s.x = x
	s.facing = facing
	s.hunting = hunting
	return s


## Runs `frames` frames with nothing in sight and an open floor.
func _walk(s: ScorpionHunt.State, frames: int, blocked_left := false, blocked_right := false) -> void:
	for i in frames:
		ScorpionHunt.step(s, false, 0.0, blocked_left, blocked_right, LO, HI, WALK, HUNT, LOSE, DT)


func test_a_walking_scorpion_sees_only_ahead() -> void:
	check(ScorpionHunt.sees(Vector2(80.0, 0.0), 1.0, false, SIGHT), "the hero ahead on its floor is seen")
	check(not ScorpionHunt.sees(Vector2(-80.0, 0.0), 1.0, false, SIGHT), "the hero behind it is not")


func test_a_hunting_scorpion_sees_either_side() -> void:
	check(ScorpionHunt.sees(Vector2(-80.0, 0.0), 1.0, true, SIGHT), "a hunt follows a hero who got behind it")


func test_it_sees_only_its_own_floor_and_only_so_far() -> void:
	check(not ScorpionHunt.sees(Vector2(40.0, -96.0), 1.0, true, SIGHT), "a storey up is out of sight")
	check(not ScorpionHunt.sees(Vector2(40.0, 96.0), 1.0, true, SIGHT), "a storey down is out of sight")
	check(ScorpionHunt.sees(Vector2(40.0, -16.0), 1.0, false, SIGHT), "a step up is still its floor")
	check(not ScorpionHunt.sees(Vector2(SIGHT.x + 1.0, 0.0), 1.0, false, SIGHT), "past its sight is not seen")


func test_unprovoked_it_walks_its_range_and_never_stops() -> void:
	var s := _state(LO)
	var lowest := INF
	var highest := -INF
	var last := s.x
	var still := 0
	for i in 600:
		_walk(s, 1)
		lowest = minf(lowest, s.x)
		highest = maxf(highest, s.x)
		if is_equal_approx(s.x, last):
			still += 1
		last = s.x
	check_near(lowest, LO, 0.5, "reaches the near end")
	check_near(highest, HI, 0.5, "reaches the far end")
	check(still <= 2, "never stands still on an open floor (held %d frames)" % still)


func test_it_turns_early_at_a_ledge_or_wall() -> void:
	var s := _state(60.0, 1.0)
	_walk(s, 1, false, true)
	check_eq(s.facing, -1.0, "blocked ahead, it turns")
	check(s.x < 60.0, "and walks the other way")


func test_blocked_both_ways_it_holds_still() -> void:
	var s := _state(60.0, 1.0)
	_walk(s, 10, true, true)
	check_near(s.x, 60.0, 0.001, "a floor no wider than itself holds it")


func test_seeing_the_hero_starts_a_hunt_toward_him() -> void:
	var s := _state(60.0, 1.0)
	ScorpionHunt.step(s, true, 100.0, false, false, LO, HI, WALK, HUNT, LOSE, DT)
	check(s.hunting, "it hunts once it sees him")
	check_near(s.x, 60.0 + HUNT * DT, 0.001, "and comes at its hunting speed")


func test_a_hunt_turns_to_face_the_hero() -> void:
	var s := _state(60.0, 1.0, true)
	ScorpionHunt.step(s, true, -50.0, false, false, LO, HI, WALK, HUNT, LOSE, DT)
	check_eq(s.facing, -1.0, "its armour turns toward the hero")


func test_a_hunt_waits_at_the_edge_facing_him() -> void:
	var s := _state(60.0, 1.0, true)
	for i in 30:
		ScorpionHunt.step(s, true, 80.0, false, true, LO, HI, WALK, HUNT, LOSE, DT)
	check_near(s.x, 60.0, 0.001, "it does not walk off its floor after him")
	check_eq(s.facing, 1.0, "and waits facing him")


func test_a_hunt_never_overshoots_the_hero() -> void:
	var s := _state(60.0, 1.0, true)
	ScorpionHunt.step(s, true, 0.5, false, false, LO, HI, WALK, HUNT, LOSE, DT)
	check_near(s.x, 60.5, 0.001, "it closes the gap and no further")


func test_out_of_sight_long_enough_it_goes_back_to_walking() -> void:
	var s := _state(60.0, 1.0, true)
	var frames := int(ceil(LOSE / DT)) - 2
	_walk(s, frames)
	check(s.hunting, "a moment out of sight (a jump over it) is still a hunt")
	_walk(s, 4)
	check(not s.hunting, "after %.1f s unseen it walks again" % LOSE)


func test_a_hunt_that_left_its_range_walks_back_to_it() -> void:
	var s := _state(HI + 80.0, 1.0)
	_walk(s, 1)
	check_eq(s.facing, -1.0, "past the far end, it heads back")
	_walk(s, 200)
	check(s.x >= LO and s.x <= HI, "and is back inside its range")
	s = _state(LO - 40.0, -1.0)
	_walk(s, 10, false, true)
	check_near(s.x, LO - 40.0, 0.001, "blocked on the way back, it holds rather than walking further off")
