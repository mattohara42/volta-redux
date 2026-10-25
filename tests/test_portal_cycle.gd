## The original's portal: two doors taking turns (`PortalCycle`).
extends TestCase

const OPEN := 3.0
const GAP := 1.0


func test_the_doors_take_turns_with_a_gap_between() -> void:
	check_eq(PortalCycle.open_door(0.0, OPEN, GAP), PortalCycle.FIRST, "the first door opens first")
	check_eq(PortalCycle.open_door(2.9, OPEN, GAP), PortalCycle.FIRST, "for its whole open time")
	check_eq(PortalCycle.open_door(3.5, OPEN, GAP), PortalCycle.NEITHER, "then both are shut")
	check_eq(PortalCycle.open_door(4.0, OPEN, GAP), PortalCycle.SECOND, "a second later the other opens")
	check_eq(PortalCycle.open_door(7.5, OPEN, GAP), PortalCycle.NEITHER, "then both are shut again")
	check_eq(PortalCycle.open_door(8.0, OPEN, GAP), PortalCycle.FIRST, "and round")
	check_near(PortalCycle.period(OPEN, GAP), 8.0, 0.001, "a full turn is both doors and both gaps")


func test_neither_door_opens_during_a_respawn_freeze() -> void:
	check_eq(PortalCycle.open_door(-0.2, OPEN, GAP), PortalCycle.NEITHER, "the clock is parked")


func test_a_door_slides_open_and_shut() -> void:
	check_near(PortalCycle.openness(0.0, PortalCycle.FIRST, OPEN, GAP, 0.25), 0.0, 0.001, "shut as it starts")
	check_near(PortalCycle.openness(1.5, PortalCycle.FIRST, OPEN, GAP, 0.25), 1.0, 0.001, "open in the middle")
	check_near(PortalCycle.openness(1.5, PortalCycle.SECOND, OPEN, GAP, 0.25), 0.0, 0.001, "the other is shut meanwhile")


func test_a_hero_in_the_doorway_is_one_whose_middle_is_in_it() -> void:
	var door := Rect2(100.0, 52.0, 32.0, 48.0)
	check(PortalCycle.in_doorway(Rect2(107.0, 60.0, 18.0, 40.0), door), "standing in it")
	check(not PortalCycle.in_doorway(Rect2(80.0, 60.0, 18.0, 40.0), door), "beside it, overlapping the frame")
	check(not PortalCycle.in_doorway(Rect2(107.0, 0.0, 18.0, 40.0), door), "above it")
	check_eq(PortalCycle.foot_of(door), Vector2(116.0, 100.0), "out of it, feet on its floor")
