## The counter's rule: every sword you still own gets an icon, in hand first,
## never more than the cap, and a spent sword gets none.
extends TestCase


func test_in_hand_comes_before_out() -> void:
	check_eq(SwordTally.icons(2, 1, 5), [true, true, false] as Array[bool], "two held, one out")


func test_nothing_owned_shows_nothing() -> void:
	check_eq(SwordTally.icons(0, 0, 5).size(), 0, "no swords, no icons")


func test_never_more_than_the_cap() -> void:
	check_eq(SwordTally.icons(4, 3, 5).size(), 5, "four held and three out still shows five")
	check_eq(SwordTally.icons(7, 0, 5).size(), 5, "held alone is capped too")


func test_negative_counts_are_nothing() -> void:
	check_eq(SwordTally.icons(-1, -2, 5).size(), 0, "a negative count draws no icons")
