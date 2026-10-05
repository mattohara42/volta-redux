## The sword's state machine. SPEC.md calls the sword the whole reason to build
## this, so its transitions get walked one at a time rather than trusted.
extends TestCase

const DT := 1.0 / 60.0
const S := SwordFlight.State
const SOLID := SwordFlight.Contact.SOLID
const WOOD := SwordFlight.Contact.WOOD


## Every transition out of every live state, in one place, because that is what
## a transition table is for.
func test_the_machine_goes_where_it_says_it_goes() -> void:
	check_eq(_step(S.FLYING), S.FLYING, "flying stays flying")
	check_eq(_step(S.FLYING, {"at_max_range": true}), S.RETURNING, "range turns it around")
	check_eq(_step(S.FLYING, {"contact": SOLID}), S.DESTROYED, "a wall consumes it")

	check_eq(_step(S.RETURNING), S.RETURNING, "returning stays returning")
	check_eq(_step(S.RETURNING, {"caught": true}), S.CAUGHT, "a catch ends it well")
	check_eq(_step(S.RETURNING, {"contact": SOLID}), S.DESTROYED, "a wall ends it badly")
	check_eq(_step(S.RETURNING, {"overshot": true}), S.FALLING, "passing you spends it")
	check_eq(_step(S.RETURNING, {"return_spent": true}), S.FALLING, "so does running away")

	check_eq(_step(S.FALLING), S.FALLING, "falling stays falling")
	check_eq(_step(S.FALLING, {"on_floor": true}), S.GROUNDED, "it lands")

	check_eq(_step(S.GROUNDED), S.GROUNDED, "it waits")
	check_eq(_step(S.GROUNDED, {"picked_up": true}), S.CAUGHT, "you walk over to it")

	check_eq(_step(S.EMBEDDED), S.EMBEDDED, "an embedded sword stays put")
	check_eq(_step(S.EMBEDDED, {"recalled": true}), S.RECALLING, "a hold calls it home")

	check_eq(_step(S.RECALLING), S.RECALLING, "recalling stays recalling")
	check_eq(_step(S.RECALLING, {"caught": true}), S.CAUGHT, "and ends in your hand")


## A catch beats a wall in the same frame. If the sword got inside your catch
## radius the throw already worked, and standing near a wall should not cost you
## a sword you had your hand on.
func test_a_catch_beats_a_solid_hit() -> void:
	check_eq(
		_step(S.RETURNING, {"caught": true, "contact": SOLID}), S.CAUGHT,
		"catch wins the tie"
	)


## A falling sword is already spent, and the floor it lands on is not what
## killed it. Without this a missed catch would destroy itself on landing and
## the done-when would be unreachable.
func test_landing_is_not_the_same_event_as_hitting_a_wall() -> void:
	check_eq(
		_step(S.FALLING, {"contact": SOLID, "on_floor": true}), S.GROUNDED,
		"it lands rather than shatters"
	)
	check_eq(_step(S.FALLING, {"contact": SOLID}), S.FALLING, "and a wall does not stop it")


func test_terminal_states_are_terminal() -> void:
	check_eq(_step(S.CAUGHT, {"contact": SOLID}), S.CAUGHT, "caught stays caught")
	check_eq(_step(S.DESTROYED, {"caught": true}), S.DESTROYED, "destroyed stays destroyed")


func test_range_and_return_budget_are_distances_not_guesses() -> void:
	check(not SwordFlight.at_max_range(199.0, 200.0), "still going out")
	check(SwordFlight.at_max_range(200.0, 200.0), "turns exactly at range")
	check(not SwordFlight.return_spent(299.0, 300.0), "still coming back")
	check(SwordFlight.return_spent(300.0, 300.0), "gives up exactly at the budget")


## The miss. The sword steers in x only, so crossing your x without catching is
## what a miss is, and it has to survive the player moving during the return.
func test_overshoot_is_a_sign_change_and_not_a_position() -> void:
	check(SwordFlight.has_overshot(12.0, -3.0), "crossed from ahead to behind")
	check(SwordFlight.has_overshot(-12.0, 3.0), "and the other way")
	check(not SwordFlight.has_overshot(12.0, 4.0), "still closing")
	check(not SwordFlight.has_overshot(-12.0, -4.0), "still closing, other side")
	check(not SwordFlight.has_overshot(0.0, -4.0), "landing exactly on you is not a miss")
	check(not SwordFlight.has_overshot(4.0, 0.0), "nor is arriving exactly on you")


func test_the_return_always_steers_at_full_speed_toward_you() -> void:
	check_eq(SwordFlight.return_velocity_x(100.0, 300.0, 420.0), 420.0, "you are to the right")
	check_eq(SwordFlight.return_velocity_x(300.0, 100.0, 420.0), -420.0, "you are to the left")
	check_eq(SwordFlight.return_velocity_x(100.0, 100.0, 420.0), 0.0, "you are right here")


func test_the_catch_window_is_a_radius() -> void:
	var origin := Vector2(100.0, 200.0)
	check(SwordFlight.is_within(origin, Vector2(110.0, 200.0), 14.0), "inside horizontally")
	check(SwordFlight.is_within(origin, Vector2(100.0, 213.0), 14.0), "inside vertically")
	check(not SwordFlight.is_within(origin, Vector2(115.0, 200.0), 14.0), "just outside")
	check(
		not SwordFlight.is_within(origin, Vector2(110.0, 210.0), 14.0),
		"diagonal distance is real distance, not the larger axis"
	)


## The height rule, stated as a test. A hero is 40 px tall and the catch radius
## is 14, so jumping is enough to miss and standing still is not.
func test_a_jump_is_enough_to_miss_and_standing_still_is_not() -> void:
	var throw_height := Vector2(100.0, 300.0)
	check(
		SwordFlight.is_within(throw_height, Vector2(100.0, 300.0), 14.0),
		"stood where you threw, you catch it"
	)
	check(
		not SwordFlight.is_within(throw_height, Vector2(100.0, 300.0 - 40.0), 14.0),
		"one hero height up and it goes under you"
	)


func test_a_spent_sword_falls_and_bleeds_off_its_speed() -> void:
	var speed := 420.0
	var drag := 600.0
	var velocity := Vector2(speed, 0.0)
	var frames := 0
	while not is_zero_approx(velocity.x) and frames < 600:
		velocity = SwordFlight.step_fall(velocity, 900.0, drag, 500.0, DT)
		frames += 1
	check_eq(velocity.x, 0.0, "horizontal speed reaches zero and stops there")
	check(velocity.y > 0.0, "and it is going down")
	# Time to stop is speed over drag, and saying so here means a change to
	# either number has to be a deliberate one.
	check_near(float(frames) * DT, speed / drag, DT * 1.5, "it takes speed over drag to stop")

	var terminal := Vector2.ZERO
	for i in 120:
		terminal = SwordFlight.step_fall(terminal, 900.0, 600.0, 500.0, DT)
	check_eq(terminal.y, 500.0, "capped at max fall speed")


## Wood is the whole of M2. It has to bite on both legs, or which way the sword
## happened to be travelling would decide whether you get a ledge, and the
## player has no way to reason about that.
func test_wood_bites_and_stone_kills() -> void:
	check_eq(_step(S.FLYING, {"contact": WOOD}), S.EMBEDDED, "wood catches it on the way out")
	check_eq(_step(S.RETURNING, {"contact": WOOD}), S.EMBEDDED, "and on the way back")
	check_eq(_step(S.FLYING, {"contact": SOLID}), S.DESTROYED, "stone still kills it")
	check_eq(_step(S.RETURNING, {"contact": SOLID}), S.DESTROYED, "on either leg")


## A catch is still the best outcome available. Wood inside your catch radius
## means you had your hand on it, and the same reasoning that beats a wall beats
## a plank.
func test_a_catch_beats_wood_too() -> void:
	check_eq(
		_step(S.RETURNING, {"caught": true, "contact": WOOD}), S.CAUGHT,
		"catch wins that tie as well"
	)


## The cost of a recall is the ledge, not the sword. A recall that could be
## eaten by the geometry between you and the plank would make the move a gamble,
## and SPEC.md sells recall as the answer to the dragon rather than a risk.
func test_a_recall_cannot_be_taken_away_from_you() -> void:
	check_eq(_step(S.RECALLING, {"contact": SOLID}), S.RECALLING, "stone does not stop a recall")
	check_eq(_step(S.RECALLING, {"contact": WOOD}), S.RECALLING, "nor does more wood")
	check_eq(_step(S.RECALLING, {"return_spent": true}), S.RECALLING, "nor running away")
	check_eq(_step(S.RECALLING, {"overshot": true}), S.RECALLING, "nor passing you")


## Volta tears embedded swords out of the walls: they fall, they do not fly
## home, and nothing else in the room can do it.
func test_a_yank_tears_an_embedded_sword_out_and_drops_it() -> void:
	check_eq(_step(S.EMBEDDED, {"yanked": true}), S.FALLING, "an embedded sword falls")
	check_eq(_step(S.EMBEDDED, {"yanked": true, "recalled": true}), S.RECALLING, "a recall in the same step still wins")
	check_eq(_step(S.FLYING, {"yanked": true}), S.FLYING, "one in flight ignores it")


## Except current. A live barrier destroys a sword in any state that is still
## out in the room (Matt, 2026-10-04): recall early, or lose what you left behind.
func test_a_live_barrier_destroys_a_sword_in_any_state() -> void:
	for state in [S.FLYING, S.RETURNING, S.RECALLING, S.EMBEDDED, S.FALLING, S.GROUNDED]:
		check_eq(_step(state, {"contact": SwordFlight.Contact.LIVE}), S.DESTROYED, "%s is destroyed" % SwordFlight.state_name(state))
	check_eq(_step(S.CAUGHT, {"contact": SwordFlight.Contact.LIVE}), S.CAUGHT, "one already in hand is not")


## An embedded sword answers nothing except the recall, because a ledge that
## vanished when something brushed it would not be a ledge.
func test_an_embedded_sword_ignores_everything_but_the_recall() -> void:
	check_eq(_step(S.EMBEDDED, {"contact": SOLID}), S.EMBEDDED, "it is already in a wall")
	check_eq(_step(S.EMBEDDED, {"caught": true}), S.EMBEDDED, "you cannot catch it by standing there")
	check_eq(_step(S.EMBEDDED, {"on_floor": true}), S.EMBEDDED, "the floor is irrelevant to it")
	check_eq(_step(S.EMBEDDED, {"at_max_range": true}), S.EMBEDDED, "so is its old range")


## Unlike the return leg, which is flat on purpose, a recall steers in y as well.
## The whole reason to embed a sword is to put it somewhere you are not.
func test_a_recall_steers_in_both_axes() -> void:
	var straight_up := SwordFlight.recall_velocity(Vector2(0.0, 100.0), Vector2(0.0, 0.0), 380.0)
	check_near(straight_up.x, 0.0, 0.001, "no drift when it is directly below you")
	check_near(straight_up.y, -380.0, 0.001, "and it climbs at the recall speed")

	var diagonal := SwordFlight.recall_velocity(Vector2.ZERO, Vector2(30.0, 40.0), 100.0)
	check_near(diagonal.length(), 100.0, 0.001, "a diagonal recall is not faster than a straight one")
	check_near(diagonal.x, 60.0, 0.001, "3-4-5, so x is 60")
	check_near(diagonal.y, 80.0, 0.001, "and y is 80")

	var arrived := SwordFlight.recall_velocity(Vector2(5.0, 5.0), Vector2(5.0, 5.0), 380.0)
	check_eq(arrived, Vector2.ZERO, "a sword already on you does not jitter")


## The whole one-tile ledge has to be outside the plank, or the wall pushes the
## player off the end of the sliver that is left. A capture put a real sword at
## 87.9 against a face at 88, which left 7.9 px of ledge for an 18 px player,
## and that is the case these numbers exist to stop coming back.
func test_an_embedded_sword_leaves_its_whole_ledge_outside_the_plank() -> void:
	var world: WorldConfig = load("res://config/world.tres")
	check_eq(world.sword_length, world.tile_size, "blade and tile are the same length")
	var half := world.sword_length * 0.5

	# Thrown right, into the left face of a plank at x = 200.
	var rightward := SwordFlight.embed_position(200.0, 1.0, world.sword_length)
	check_eq(rightward, 192.0, "a rightward throw settles half a blade short of the face")
	check_eq(rightward + half, 200.0, "so the ledge ends exactly at the face")
	check(rightward + half <= 200.0, "and never reaches inside the plank")

	# Thrown left, into the right face of a plank at x = 88, which is the case
	# the M2 bench captures.
	var leftward := SwordFlight.embed_position(88.0, -1.0, world.sword_length)
	check_eq(leftward, 96.0, "a leftward throw settles half a blade past the face")
	check_eq(leftward - half, 88.0, "so that ledge starts exactly at the face")

	# A one-tile ledge is 16 px and the hero is 18 px wide, so the sword is a
	# narrower perch than the thing standing on it. That works, because a body
	# only needs its centre supported, but there is no margin in it. It is the
	# first number to look at if standing on a sword turns out to feel fiddly.
	check(
		world.sword_length >= world.hero_width * 0.8,
		"a one-tile ledge is a usable perch for the hero (ledge %.0f, hero %.0f)" % [
			world.sword_length, world.hero_width
		]
	)


## The throw leaves on the press and the recall arrives later on the same hold,
## so the threshold has to sit above any plausible tap and fire exactly once.
func test_recall_needs_a_hold_and_fires_once() -> void:
	var config: SwordConfig = load("res://config/sword.tres")
	var hold := config.recall_hold_time
	check(hold > 0.2, "the threshold is longer than a tap (%.2f s)" % hold)

	check(not SwordFlight.recall_triggered(0.0, hold, false), "a press alone is a throw")
	check(not SwordFlight.recall_triggered(hold - 0.01, hold, false), "just short is still a throw")
	check(SwordFlight.recall_triggered(hold, hold, false), "the threshold fires it")
	check(
		not SwordFlight.recall_triggered(hold + 5.0, hold, true),
		"and one hold only recalls once, however long it lasts"
	)


## The three states the player sent it into, and none of the ones where it
## is stuck, lying or spent.
func test_only_a_thrown_returning_or_recalled_sword_is_airborne() -> void:
	var airborne := [SwordFlight.State.FLYING, SwordFlight.State.RETURNING, SwordFlight.State.RECALLING]
	for state: SwordFlight.State in SwordFlight.State.values():
		check_eq(SwordFlight.is_airborne(state), airborne.has(state), "%s airborne" % SwordFlight.state_name(state))


func test_every_state_has_a_readable_name() -> void:
	for state in S.values():
		check(not SwordFlight.state_name(state).is_empty(), "state %d is named" % state)


## Defaults are "nothing has happened", so each case above states only the one
## fact it is about.
func _step(state: SwordFlight.State, facts: Dictionary = {}) -> SwordFlight.State:
	return SwordFlight.next_state(
		state,
		facts.get("at_max_range", false),
		facts.get("return_spent", false),
		facts.get("caught", false),
		facts.get("picked_up", false),
		facts.get("contact", SwordFlight.Contact.NONE),
		facts.get("overshot", false),
		facts.get("on_floor", false),
		facts.get("recalled", false),
		facts.get("yanked", false)
	)
