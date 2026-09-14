## The M4 enemy bench, as arithmetic: nothing overlaps anything it should not,
## and every zone is separated by a brazier the way M3's hazards are.
extends TestCase

const HALF_HERO_WIDTH: float = 9.0


func test_scorpion_patrol_stays_inside_the_room() -> void:
	var far_end := RoomM4Enemies.SCORPION_HOME_X + RoomM4Enemies.SCORPION_RANGE
	check(far_end < RoomM4Enemies.MID_BRAZIER_1_X, "the scorpion should not walk into the brazier past it")
	check(RoomM4Enemies.SCORPION_HOME_X > RoomM4Enemies.START_BRAZIER_X, "and not back into the start")


func test_the_mid_braziers_separate_every_zone() -> void:
	check(
		RoomM4Enemies.MID_BRAZIER_1_X > RoomM4Enemies.SCORPION_HOME_X + RoomM4Enemies.SCORPION_RANGE,
		"brazier 1 sits past the scorpion's whole range"
	)
	check(
		RoomM4Enemies.MID_BRAZIER_1_X < RoomM4Enemies.ANT_TRACK.position.x,
		"and before the ant's track begins"
	)
	check(
		RoomM4Enemies.MID_BRAZIER_2_X > RoomM4Enemies.ANT_TRACK.end.x,
		"brazier 2 sits past the ant's track"
	)
	check(
		RoomM4Enemies.MID_BRAZIER_2_X < RoomM4Enemies.EYEBALL_ROAM.position.x,
		"and before the eyeball is allowed to roam"
	)


func test_the_ant_track_floor_leg_is_the_real_floor() -> void:
	check_near(
		RoomM4Enemies.ANT_TRACK.end.y, RoomM4Enemies.FLOOR_TOP, 0.001,
		"the ant's floor leg should be the same floor the hero walks, not a second one"
	)


func test_the_bat_box_dips_low_enough_to_reach_a_standing_hero() -> void:
	var lowest := RoomM4Enemies.BAT_CENTRE.y + RoomM4Enemies.BAT_HALF_EXTENTS.y
	var world: WorldConfig = load("res://config/world.tres")
	var hero_head := RoomM4Enemies.FLOOR_TOP - world.hero_height
	check(
		lowest > hero_head,
		"the bat's lowest reach (%.0f) should dip below a standing hero's head (%.0f)" % [
			lowest, hero_head
		]
	)


func test_the_eyeball_roam_reaches_the_floor() -> void:
	check_near(
		RoomM4Enemies.EYEBALL_ROAM.end.y, RoomM4Enemies.FLOOR_TOP, 0.001,
		"the eyeball has to be able to come down to where the hero can be standing"
	)


func test_the_finish_sits_inside_the_eyeball_roam() -> void:
	check(
		RoomM4Enemies.FINISH_X >= RoomM4Enemies.EYEBALL_ROAM.position.x
			and RoomM4Enemies.FINISH_X <= RoomM4Enemies.EYEBALL_ROAM.end.x,
		"the eyeball is meant to be the last thing between the hero and the door"
	)


## A sword thrown at the near edge of the scorpion's patrol has to be able to
## reach it, or the bench cannot demonstrate the armour at all.
func test_the_scorpion_is_within_sword_range_of_its_own_patrol() -> void:
	var sword: SwordConfig = load("res://config/sword.tres")
	check(
		RoomM4Enemies.SCORPION_RANGE < sword.max_range,
		"a sword thrown from one end of the patrol should reach the other"
	)
