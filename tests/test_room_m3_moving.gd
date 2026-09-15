## The moving-platform bench, as arithmetic.
##
## Same claim as the other two M3 benches: not that the room is clever, but that
## it can be finished at all. A death bench you cannot cross stops measuring the
## death loop and starts measuring frustration with the room.
##
## The difference here is that the room is built against a clock that is running
## whether or not anybody is playing, so the checks come in pairs: a distance you
## have to cover, and the window you have to cover it in.
extends TestCase

const HAZARDS := "res://config/hazards.tres"


func _move() -> MovementConfig:
	return load("res://config/movement.tres")


func _hazards() -> HazardConfig:
	return load(HAZARDS)


## How long a full-speed jump is in the air. The number every boarding is
## measured against, because a ferry keeps moving while you are in it.
func _flight() -> float:
	return _reach() / _move().max_run_speed


## How far a full-speed jump carries you on the flat, which is what every jump in
## this room is measured against. Both crossings are level start to finish.
func _reach() -> float:
	var move := _move()
	return Motion.jump_reach(
		move.jump_height, move.time_to_apex, move.fall_gravity_multiplier,
		move.max_run_speed, 0.0
	)


func _crossing_seconds() -> float:
	return PlatformFerry.travel_seconds(RoomM3Moving.SPAN, _hazards().platform_travel_speed)


## The point of the room. If either moat could be jumped, the ferries are
## scenery and nothing in here is being measured.
func test_neither_moat_can_be_jumped() -> void:
	var reach := _reach()
	var moats := {
		"the first": RoomM3Moving.ISLAND_START - RoomM3Moving.FIRST_BANK_END,
		"the second": RoomM3Moving.LAST_BANK_START - RoomM3Moving.ISLAND_END,
	}
	for name in moats:
		check(
			moats[name] > reach * 1.5,
			"%s moat is %.0f px against a reach of %.0f" % [name, moats[name], reach]
		)


## Every jump onto or off a ferry is deliberately an easy one. The question this
## room asks is when to take off, and a gap that was also marginal would produce
## deaths that cannot be told apart, so neither half would be measured.
func test_every_jump_in_the_room_is_a_comfortable_one() -> void:
	var fraction := RoomM3Moving.GAP / _reach()
	check(fraction < 0.6, "a gap is %.0f%% of a full-speed jump" % [fraction * 100.0])


## The first moat teaches on one timed action and the second asks for two. A
## ferry that did not dock flush against the first bank would make boarding a
## jump as well, and the room would open with its own hardest question.
func test_the_first_ferry_can_be_walked_onto_and_the_second_cannot() -> void:
	check_eq(
		RoomM3Moving.first_ferry().position.x, RoomM3Moving.FIRST_BANK_END,
		"the first ferry docks flush against the bank you start on"
	)
	check_eq(
		RoomM3Moving.second_ferry().position.x - RoomM3Moving.ISLAND_END, RoomM3Moving.GAP,
		"and the second docks a jump out from the island"
	)


## The geometry is generated from the span, the slab and the gap, so this is the
## check that a crossing still reaches the bank it is aimed at. A ferry that
## turns round half a jump short is a room nobody can finish, and it draws
## perfectly well.
func test_both_ferries_turn_round_within_a_jump_of_the_far_bank() -> void:
	check_eq(
		RoomM3Moving.gap_to_bank(RoomM3Moving.first_ferry(), RoomM3Moving.ISLAND_START),
		RoomM3Moving.GAP,
		"the first crossing ends a jump short of the island"
	)
	check_eq(
		RoomM3Moving.gap_to_bank(RoomM3Moving.second_ferry(), RoomM3Moving.LAST_BANK_START),
		RoomM3Moving.GAP,
		"and the second a jump short of the far bank"
	)


## You land on a ferry at whatever speed the last jump left you, but the honest
## case is the one where you land badly and stop. A slab you cannot get back to
## full speed on would make the jump off unmakeable for reasons the room never
## shows you.
func test_a_ferry_is_long_enough_to_take_off_from_standing() -> void:
	var move := _move()
	var needed := Motion.run_up_distance(move.max_run_speed, move.ground_accel)
	check(
		RoomM3Moving.SLAB_SIZE.x * 0.5 > needed,
		"half a ferry is %.0f px and reaching full speed needs %.0f" % [
			RoomM3Moving.SLAB_SIZE.x * 0.5, needed
		]
	)


## The window a respawn gets, measured from the moment the player has the
## controls back. `MovingPlatform.reset` starts its clock at minus the freeze,
## so the freeze itself is already spent at the dock by the time this window
## opens: what is left is the wait, in full.
func _boarding_window() -> float:
	return _hazards().platform_wait_time


## These next two are the only checks in the file that are about the death loop
## rather than about the crossing, and they are the reason the room is laid out
## the way it is. A respawn puts every ferry back at its dock, so the run from
## the brazier you respawn at to the ferry you have to catch has to fit inside
## the time that ferry is there for. If it does not, every death costs the
## crossing you missed and then a wait for the ferry to come back, which is the
## difference between twenty deaths being annoying and being tedious.
##
## The first moat is the walk-on one, so its whole question is whether you are
## standing on the dock before the ferry leaves it.
func test_a_respawn_at_the_start_walks_onto_the_first_ferry_before_it_goes() -> void:
	var move := _move()
	var run := Motion.run_time(
		RoomM3Moving.FIRST_BANK_END - RoomM3Moving.START_BRAZIER_X,
		move.max_run_speed, move.ground_accel
	)
	check(
		run < _boarding_window(),
		"a respawn is at the first dock in %.2f s and the ferry is there for %.2f s" % [
			run, _boarding_window()
		]
	)


## The second moat is jumped onto, and a jump takes long enough that the ferry
## has moved by the time you land on it. What buys that time back is the slab
## being longer than the gap: the jump lands a way in from its near edge, so the
## ferry may already have set off and still be under you.
##
## Getting this wrong is not visible in a screenshot and not visible in the
## arithmetic that only counts pixels. Measured on a running build before the
## reset was made to sit out the respawn freeze, the ferry left two frames before
## a respawn could reach the lip, every single time.
func test_a_respawn_at_the_island_still_catches_the_second_ferry() -> void:
	var move := _move()
	var run := Motion.run_time(
		RoomM3Moving.BOARDING_RUN, move.max_run_speed, move.ground_accel
	)
	# How far into the slab a full-speed jump from the lip lands, as the time the
	# ferry can have been running when you get there.
	var drift := (_reach() - RoomM3Moving.GAP) / _hazards().platform_travel_speed
	var window := _boarding_window() + drift - _flight()
	check(
		run < window,
		"a respawn takes off in %.2f s and the last takeoff that lands on the ferry is %.2f s" % [
			run, window
		]
	)
	check(
		_reach() - RoomM3Moving.GAP < RoomM3Moving.SLAB_SIZE.x,
		"and a full-speed jump from the lip lands on the slab rather than past it"
	)
	check(
		RoomM3Moving.BOARDING_RUN
			> Motion.run_up_distance(move.max_run_speed, move.ground_accel),
		"with enough island before the lip to reach a full run in"
	)


## Same rule as the other two benches: the mid brazier sits between the two
## hazards, so a death at the second one costs you that crossing and not the one
## you already made.
func test_the_mid_brazier_banks_the_first_crossing() -> void:
	check(
		RoomM3Moving.MID_BRAZIER_X > RoomM3Moving.ISLAND_START,
		"the mid brazier is on the island, past the first moat"
	)
	check(
		RoomM3Moving.MID_BRAZIER_X < RoomM3Moving.ISLAND_END,
		"and before the second one, which is the one you die in"
	)


func test_the_start_brazier_is_on_the_floor_you_begin_on() -> void:
	check(
		RoomM3Moving.START_BRAZIER_X < RoomM3Moving.FIRST_BANK_END,
		"there is a checkpoint in the first frame"
	)


func test_every_ferry_rides_clear_of_the_lava_it_crosses() -> void:
	check(
		RoomM3Moving.LAVA_INSET > RoomM3Moving.SLAB_SIZE.y,
		"a ferry rides above the lava rather than through it"
	)
	for ferry in [RoomM3Moving.first_ferry(), RoomM3Moving.second_ferry()]:
		check_eq(ferry.position.y, Bench.FLOOR_TOP, "and its top face is level with the floor")


func test_there_is_floor_past_the_last_crossing() -> void:
	check(
		RoomM3Moving.LAST_BANK_START < RoomM3Moving.ROOM_WIDTH - 60.0,
		"the far bank is long enough to hold the exit you are running at"
	)
