## The save (`SavePoint`), as rules. The claims: a save read back is the save
## written, anything that cannot be resumed is refused rather than misread,
## counts out of range are pulled back in, and a tool never touches it.
extends TestCase


func test_a_save_reads_back_as_it_was_written() -> void:
	var saved := SavePoint.make(2, 4, 9, 13, 812.5)
	check_eq(SavePoint.resume(saved, 4, 5), saved, "Act 3, four swords carried in, thirteen deaths, nine before it")


## Matt, 2026-10-07: a save at braziers. The room and the brazier come back.
func test_a_save_at_a_brazier_reads_back_too() -> void:
	var saved := SavePoint.make(0, 2, 0, 5, 100.0, "res://scenes/rooms/act1_wall.tscn", Vector2(920.0, 236.0), true, 1)
	var back := SavePoint.resume(saved, 4, 5)
	check_eq(back, saved, "the room, the brazier, two swords and a gem")
	check_eq(SavePoint.resume(SavePoint.make(0, 2, 0, 0, 0.0), 4, 5)["has_brazier"], false, "a room's start has no brazier")


func test_nothing_saved_is_nothing_to_resume() -> void:
	check(SavePoint.resume({}, 4, 5).is_empty(), "no save")
	var old := SavePoint.make(1, 3, 0, 0, 0.0)
	old["version"] = SavePoint.VERSION - 1
	check(SavePoint.resume(old, 4, 5).is_empty(), "a save of an older shape is ignored, not misread")


func test_an_act_that_no_longer_exists_is_not_resumed() -> void:
	check(SavePoint.resume(SavePoint.make(4, 3, 0, 0, 0.0), 4, 5).is_empty(), "past the last act")
	check(SavePoint.resume(SavePoint.make(-1, 3, 0, 0, 0.0), 4, 5).is_empty(), "before the first")


func test_counts_out_of_range_are_pulled_back_in() -> void:
	var back := SavePoint.resume(SavePoint.make(1, 9, 20, 6, -3.0), 4, 5)
	check_eq(back["swords"], 5, "never more swords than the cap")
	check_eq(back["act_deaths_before"], 6, "never more deaths before the act than in the run")
	check_eq(back["seconds"], 0.0, "never negative time")
	check_eq(SavePoint.resume(SavePoint.make(1, -4, 0, 0, 0.0), 4, 5)["swords"], -1, "below nothing is the room's own count")


func test_a_tool_or_the_tests_never_read_or_write_the_save() -> void:
	check(not SavePoint.enabled(PackedStringArray(["--script", "res://tools/capture.gd"])), "the capture tool")
	check(not SavePoint.enabled(OS.get_cmdline_args()), "these tests")
	check(SavePoint.enabled(PackedStringArray([])), "the game launched plainly")
	check(SavePoint.enabled(PackedStringArray(["res://scenes/rooms/act3_hall.tscn"])), "or into one room")
