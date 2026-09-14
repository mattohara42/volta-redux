## The geyser bench, as arithmetic.
##
## Same claim as the other three M3 benches: not that the room is clever, but
## that it can be finished at all. A death bench you cannot cross stops measuring
## the death loop and starts measuring frustration with the room.
##
## This one has a shape the others do not. A ferry is a floor that is sometimes
## somewhere else, and being early for it costs you nothing. A geyser is the only
## way up, so the room has a **floor as well as a ceiling** on where a checkpoint
## can go: too far from the moat and a respawn misses the jet, too close and it
## arrives at the lip before the jet does and dies having made no mistake.
extends TestCase


func _move() -> MovementConfig:
	return load("res://config/movement.tres")


func _hazards() -> HazardConfig:
	return load("res://config/hazards.tres")


func _world() -> WorldConfig:
	return load("res://config/world.tres")


func _tier() -> float:
	return _world().tier_height


## How far a jet carries you, and how long that takes at the speed in the config.
func _ride() -> float:
	return GeyserCycle.ride_seconds(RoomM3Geysers.ride_height(_tier()), _hazards().geyser_lift_speed)


## How long after the controls come back you can still step into a jet and be
## carried the whole way.
##
## Measured from control and not from the death, which is the whole of what
## `Geyser.reset` parking the clock at minus the respawn freeze buys: by the time
## anybody can run at a vent, its clock reads zero and the swell is about to
## start. There is deliberately no freeze term in here.
func _boarding_window() -> float:
	var hazards := _hazards()
	return GeyserCycle.boarding_window(
		hazards.geyser_swell_time, hazards.geyser_erupt_time,
		RoomM3Geysers.ride_height(_tier()), hazards.geyser_lift_speed
	)


func _run_time(distance: float) -> float:
	var move := _move()
	return Motion.run_time(distance, move.max_run_speed, move.ground_accel)


## The point of the room. If either ledge could be jumped, the jets are scenery
## and nothing in here is being measured.
func test_neither_ledge_can_be_jumped_to() -> void:
	var move := _move()
	check(
		_tier() > move.jump_height,
		"a storey is %.0f px against a %.0f px jump, so the jet is the only way up"
		% [_tier(), move.jump_height]
	)
	check_eq(
		RoomM3Geysers.first_ledge(_tier()), Bench.FLOOR_TOP - _tier(),
		"the first ledge is a storey off the floor"
	)
	check_eq(
		RoomM3Geysers.second_ledge(_tier()), RoomM3Geysers.first_ledge(_tier()) - _tier(),
		"and the second is a storey above that"
	)


## Both jets carry you the same distance, so the room asks one question twice
## rather than two questions at once. The first is entered at the floor and the
## second at the lip, and each of those is a storey below the ledge it serves.
func test_both_jets_carry_you_the_same_storey_and_a_little_past_it() -> void:
	var tier := _tier()
	check_eq(
		RoomM3Geysers.ride_height(tier), tier + RoomM3Geysers.COLUMN_OVERSHOOT,
		"a ride is a storey plus the overshoot"
	)
	check_eq(
		Bench.FLOOR_TOP - RoomM3Geysers.first_column(tier).position.y,
		RoomM3Geysers.ride_height(tier),
		"the first jet carries you that far off the floor"
	)
	check_eq(
		RoomM3Geysers.first_ledge(tier) - RoomM3Geysers.second_column(tier).position.y,
		RoomM3Geysers.ride_height(tier),
		"and the second carries you that far off the lip"
	)
	check(
		RoomM3Geysers.COLUMN_OVERSHOOT > 0.0,
		"a jet stops above its ledge, or stepping off it has no air in it"
	)


## The forgiving half of the design, and the only reason a scripted run or a
## player who simply holds the direction they were going gets anywhere: each
## shaft has the face of the ledge it serves down one side.
func test_each_shaft_runs_up_the_face_of_the_ledge_it_serves() -> void:
	var tier := _tier()
	check_eq(
		RoomM3Geysers.first_column(tier).end.x, RoomM3Geysers.LEDGE_START,
		"the first jet's far side is the face of the first ledge"
	)
	check_eq(
		RoomM3Geysers.second_column(tier).end.x, RoomM3Geysers.FAR_BANK_START,
		"and the second's is the face of the far bank"
	)


## The second jet is the one that can cost you. It comes up out of the moat, so
## the box that lifts has to start at the lava and not at the lip: a step off the
## lip during the quiet has to fall into something rather than be caught by a
## column that is not there.
func test_the_second_jet_rises_out_of_the_lava() -> void:
	var tier := _tier()
	check_eq(
		RoomM3Geysers.second_column(tier).end.y, RoomM3Geysers.moat(tier).position.y,
		"the jet starts at the surface of the lava"
	)
	check_eq(
		RoomM3Geysers.moat(tier).position.y - RoomM3Geysers.first_ledge(tier),
		RoomM3Geysers.LAVA_INSET,
		"and the lava is below the lip you step off, not level with it"
	)
	check_eq(
		RoomM3Geysers.moat(tier).size.x, RoomM3Geysers.COLUMN_WIDTH,
		"the moat is the shaft, so there is nothing to aim at but the jet"
	)


func test_the_first_jet_comes_up_out_of_the_floor_and_kills_nobody() -> void:
	var tier := _tier()
	check_eq(
		RoomM3Geysers.first_column(tier).end.y, Bench.FLOOR_TOP,
		"the first jet stands on the floor"
	)
	check(
		RoomM3Geysers.first_column(tier).end.x <= RoomM3Geysers.moat(tier).position.x,
		"and there is no lava anywhere near it, which is what makes it the teaching one"
	)


## You enter the second shaft by walking off a lip at whatever speed you were
## running, and a jet you could cross before it had lifted you would punish
## running rather than punishing misreading the clock.
func test_a_shaft_is_wide_enough_to_lose_a_full_run_in() -> void:
	var move := _move()
	# The same arithmetic as a run-up read backwards: how much air it takes to
	# lose a full run against air friction rather than to reach one on the floor.
	var stopping := Motion.run_up_distance(move.max_run_speed, move.air_friction)
	check(
		RoomM3Geysers.COLUMN_WIDTH > stopping,
		"a shaft is %.0f px and losing a full run takes %.0f"
		% [RoomM3Geysers.COLUMN_WIDTH, stopping]
	)


## An eruption has to outlast a ride by enough that arriving part way through one
## is still worth doing. Equal would mean the only boarding anybody ever makes is
## from a standing start on the vent at the moment it goes.
func test_an_eruption_outlasts_a_ride() -> void:
	check(
		_boarding_window() > _hazards().geyser_swell_time,
		"a ride takes %.2f s of a %.2f s eruption, leaving %.2f s to arrive in"
		% [_ride(), _hazards().geyser_erupt_time, _boarding_window()]
	)


## The first of the two checks that are about the death loop rather than the
## climb. A respawn puts every jet back at the first frame of its swell, so the
## run from the brazier you respawn at to the shaft has to fit inside the window
## that jet is useful for. If it does not, every death costs a whole quiet period
## as well as the climb you missed, which is the difference between twenty deaths
## being annoying and being tedious.
func test_a_respawn_at_the_start_is_in_the_first_jet_before_it_subsides() -> void:
	var run := _run_time(RoomM3Geysers.run_to_column(
		RoomM3Geysers.START_BRAZIER_X, RoomM3Geysers.FIRST_VENT_X, _world().hero_width
	))
	check(
		run < _boarding_window(),
		"a respawn is in the first shaft in %.2f s and the jet is worth having for %.2f s"
		% [run, _boarding_window()]
	)


## And the second, which is the one with two sides to it. The moat is the only
## thing in the room that kills, so the run out of the mid brazier has to land
## inside the eruption at both ends: late enough that the jet is already up when
## you leave the lip, and early enough that it can still carry you.
func test_a_respawn_at_the_mid_brazier_reaches_the_moat_while_the_jet_is_up() -> void:
	var hazards := _hazards()
	var into_the_shaft := _run_time(RoomM3Geysers.run_to_column(
		RoomM3Geysers.MID_BRAZIER_X, RoomM3Geysers.LEDGE_END, _world().hero_width
	))
	check(
		into_the_shaft < _boarding_window(),
		"a respawn is in the second shaft in %.2f s and the window is %.2f s"
		% [into_the_shaft, _boarding_window()]
	)
	# The lip, not the shaft: up to here the ledge is still holding you up, and it
	# is leaving it that commits you to whatever is or is not in the moat.
	var off_the_lip := _run_time(RoomM3Geysers.BOARDING_RUN)
	check(
		off_the_lip > hazards.geyser_swell_time,
		"and it leaves the lip at %.2f s, after the jet came up at %.2f s, so running"
		% [off_the_lip, hazards.geyser_swell_time]
		+ " flat out of the checkpoint is not a death"
	)


## Same rule as the other three benches: the mid brazier sits between the two
## hazards, so a death at the second costs you that climb and not the one you
## already made.
func test_the_mid_brazier_banks_the_first_climb() -> void:
	check(
		RoomM3Geysers.MID_BRAZIER_X > RoomM3Geysers.LEDGE_START,
		"the mid brazier is on the first ledge, past the first climb"
	)
	check(
		RoomM3Geysers.MID_BRAZIER_X < RoomM3Geysers.LEDGE_END,
		"and before the lip, which is the one you die at"
	)
	check(
		RoomM3Geysers.BOARDING_RUN
			> Motion.run_up_distance(_move().max_run_speed, _move().ground_accel),
		"with enough ledge before the lip to reach a full run in"
	)


func test_the_start_brazier_is_on_the_floor_you_begin_on() -> void:
	check(
		RoomM3Geysers.START_BRAZIER_X < RoomM3Geysers.FIRST_VENT_X,
		"there is a checkpoint in the first frame, and it is not inside the shaft"
	)


func test_there_is_floor_past_the_last_climb() -> void:
	check(
		RoomM3Geysers.FAR_BANK_START < RoomM3Geysers.ROOM_WIDTH - 60.0,
		"the far bank is long enough to hold the exit you are running at"
	)
