## Act 3's current as a rule: it runs from sources along links, a sword joins
## everything it touches, and a loop is closed only when every break is bridged.
extends TestCase


func test_current_runs_along_links_from_a_source() -> void:
	var live := Circuit.live([0], [[0, 1], [1, 2]])
	check(live.has(0) and live.has(1) and live.has(2), "a source and everything linked to it is live")
	check(not Circuit.live([0], [[1, 2]]).has(1), "a piece linked only to other dead pieces is dead")


func test_a_sword_across_a_seam_joins_both_sides() -> void:
	check(Circuit.live([0], Circuit.links_through([0, 1])).has(1), "a sword touching both pieces carries current across")
	check(not Circuit.live([0], Circuit.links_through([1])).has(1), "a sword touching one piece joins nothing")
	check_eq(Circuit.links_through([4, 5, 6]).size(), 3, "touching three, it joins all three")


func test_a_loop_closes_only_when_every_break_is_bridged() -> void:
	# The generator's out (0) and return (3), with rails 1 and 2 between and a
	# break at each joint: 0|1, 1|2, 2|3.
	var all := [[0, 1], [1, 2], [2, 3]]
	check(Circuit.connected(0, 3, all), "three swords in three breaks short it")
	for i in all.size():
		var missing := all.duplicate()
		missing.remove_at(i)
		check(not Circuit.connected(0, 3, missing), "with break %d open, it is not shorted" % i)


func test_recalling_a_sword_breaks_what_it_bridged() -> void:
	var with_sword := Circuit.links_through([0, 1])
	check(Circuit.live([0], with_sword).has(1), "bridged, the far side is live")
	check(not Circuit.live([0], []).has(1), "recalled, it is dead again")


func test_a_path_crosses_a_thin_field_even_when_both_ends_miss_it() -> void:
	var field := Rect2(100.0, 0.0, 4.0, 100.0)
	check(Circuit.crosses(Vector2(90.0, 50.0), Vector2(120.0, 50.0), field), "a fast sword stepping over it")
	check(Circuit.crosses(Vector2(102.0, 50.0), Vector2(102.0, 50.0), field), "one standing in it")
	check(not Circuit.crosses(Vector2(90.0, 50.0), Vector2(99.0, 50.0), field), "one short of it")
	check(not Circuit.crosses(Vector2(90.0, -40.0), Vector2(120.0, -10.0), field), "one passing over its top")
	check(Circuit.crosses(Vector2(90.0, -10.0), Vector2(120.0, 20.0), field), "one clipping its top corner")
