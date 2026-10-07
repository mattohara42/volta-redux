## `RespawnRules`: what a death clears and what it leaves. The claims: loose
## swords go and stuck ones stay, the cap is never passed by keeping them
## (the oldest stuck ones go first), and only mechanisms near the respawn are
## reset.
extends TestCase


func test_loose_swords_go_and_stuck_ones_stay() -> void:
	var clear := RespawnRules.swords_to_clear([true, false, true], 1, 5)
	check_eq(clear, [1] as Array[int], "only the loose one, the second thrown")


func test_keeping_stuck_swords_never_passes_the_cap() -> void:
	# Three stuck, a hand of three: six would be over five, so the oldest goes.
	var clear := RespawnRules.swords_to_clear([true, true, true], 3, 5)
	check_eq(clear, [0] as Array[int], "the first thrown, and only that one")
	check_eq(RespawnRules.swords_to_clear([true, true, true], 5, 5), [0, 1, 2] as Array[int], "a full hand clears them all")
	check_eq(RespawnRules.swords_to_clear([], 3, 5), [] as Array[int], "nothing in play, nothing to clear")


func test_only_nearby_mechanisms_reset() -> void:
	var reach := Vector2(640.0, 360.0)
	check(RespawnRules.within_reach(Vector2(100.0, 300.0), Vector2(600.0, 200.0), reach), "the same screen")
	check(not RespawnRules.within_reach(Vector2(100.0, 300.0), Vector2(2000.0, 300.0), reach), "three screens along")
	check(not RespawnRules.within_reach(Vector2(100.0, 600.0), Vector2(100.0, 100.0), reach), "two floors up and more")
