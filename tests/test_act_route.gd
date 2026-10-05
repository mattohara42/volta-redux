## How rooms connect, as rules. The claims: exits only lead forward, the last
## room finishes the act, only what is in your hand comes with you, and a chest
## brings you up to its fill without ever taking a sword away or passing the cap.
extends TestCase

const ACT1 := "res://config/act1.tres"
const SWORD := "res://config/sword.tres"
var _rooms := PackedStringArray(["a.tscn", "b.tscn", "c.tscn"])


func test_an_exit_leads_to_the_next_room() -> void:
	check_eq(ActRoute.next_room(_rooms, "a.tscn"), "b.tscn", "a leads to b")
	check_eq(ActRoute.next_room(_rooms, "b.tscn"), "c.tscn", "b leads to c")


func test_the_last_room_finishes_the_act() -> void:
	check_eq(ActRoute.next_room(_rooms, "c.tscn"), "", "nothing after the last room")
	check(ActRoute.is_last(_rooms, "c.tscn"), "and it is the last")
	check(not ActRoute.is_last(_rooms, "a.tscn"), "the first is not")


func test_a_room_outside_the_act_goes_nowhere() -> void:
	check_eq(ActRoute.next_room(_rooms, "bench.tscn"), "", "a bench's exit is dead")
	check(not ActRoute.is_last(_rooms, "bench.tscn"), "and does not finish the act")


func test_an_act_leads_to_the_next_and_the_last_plays_again() -> void:
	check_eq(ActRoute.act_after(0, 2), 1, "Act 1 leads to Act 2")
	check_eq(ActRoute.act_after(1, 2), 0, "after the last act and its ending, a new game")
	check(ActRoute.is_ending(1, 2), "finishing the last act is the ending")
	check(not ActRoute.is_ending(0, 2), "finishing any other is not")


func test_act_two_lists_rooms_that_exist() -> void:
	var act: ActConfig = load("res://config/act2.tres")
	check(act is ActConfig and act.rooms.size() >= 1, "config/act2.tres has its rooms")
	for room in act.rooms:
		check(ResourceLoader.exists(room), "%s exists" % room)


func test_only_the_swords_in_hand_carry() -> void:
	check_eq(ActRoute.carried(2, 5), 2, "two in hand, two arrive")
	check_eq(ActRoute.carried(0, 5), 0, "an empty hand arrives empty")
	check_eq(ActRoute.carried(7, 5), 5, "never past the cap")


func test_a_chest_tops_you_up_and_never_takes_away() -> void:
	check_eq(ActRoute.chest_top_up(0, 0, 3, 5), 3, "empty: up to three")
	check_eq(ActRoute.chest_top_up(1, 1, 3, 5), 2, "one in hand, one out: two more in hand")
	check_eq(ActRoute.chest_top_up(0, 3, 3, 5), 0, "all three out in the room: nothing")
	check_eq(ActRoute.chest_top_up(4, 0, 3, 5), 4, "already over: keeps four")
	check_eq(ActRoute.chest_top_up(0, 0, 9, 5), 5, "a fill past the cap stops at the cap")


func test_act_one_lists_rooms_that_exist() -> void:
	var act: ActConfig = load(ACT1)
	check(act is ActConfig, "config/act1.tres is an ActConfig")
	check(act.rooms.size() >= 2, "it has its rooms")
	check(act.title != "", "and a title for its card")
	check(act.complete_card_seconds > 0.0, "a card that is on screen")
	for room in act.rooms:
		check(ResourceLoader.exists(room), "%s exists" % room)


## The end card's last line: deaths and time, in words a player reads.
func test_the_tally_says_how_the_run_went() -> void:
	check_eq(ActRoute.tally(37, 24.5 * 60.0), "Lothar fell 37 times, in 24 minutes.", "a usual run")
	check_eq(ActRoute.tally(1, 61.0), "Lothar fell once, in a minute.", "one death, one minute")
	check_eq(ActRoute.tally(0, 30.0), "Lothar never fell. It took under a minute.", "a perfect run is noticed")
	check(not ActRoute.tally(120, 7200.0).contains(String.chr(0x2014)), "no em-dash in a string a player reads")
