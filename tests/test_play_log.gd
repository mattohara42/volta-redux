## The play log's line (`PlayLog`). The claims: a room becomes one CSV line
## with its act counted from 1 and its name without the folder, and deaths by
## cause read most first, in one field with no commas in it.
extends TestCase


func test_a_room_is_one_line_in_the_header_order() -> void:
	var line := PlayLog.row("2026-10-05 07:30:00", 1, "res://scenes/rooms/act2_tide.tscn", 93.25, 4,
		{DeathMessages.Cause.LAVA: 3, DeathMessages.Cause.BEAST: 1}, 3, 2, 1, "exit")
	check_eq(line, "2026-10-05 07:30:00,2,act2_tide,93.2,4,lava 3 beast 1,3,2,1,exit", "Act 2's tide, a minute and a half")
	check_eq(line.split(",").size(), PlayLog.HEADER.split(",").size(), "as many fields as the header")


func test_no_deaths_reads_as_none() -> void:
	check_eq(PlayLog.cause_counts({}), "none", "a clean room")


func test_causes_read_most_first() -> void:
	var causes := {DeathMessages.Cause.SPIKES: 1, DeathMessages.Cause.CURRENT: 5}
	check_eq(PlayLog.cause_counts(causes), "current 5 spikes 1", "the room's real killer first")
