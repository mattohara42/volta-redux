## The geyser's clock, as arithmetic.
##
## Every number in it is a duration, and the thing worth being careful about is
## where the cycle starts. A respawn puts the clock back to zero, so zero is not
## an arbitrary point in a loop: it is the first frame of the tell, and getting
## that wrong is a hazard that hands a player a vent which has just gone quiet
## every single time they die.
extends TestCase

const SWELL := 0.5
const ERUPT := 1.4
const DORMANT := 1.1


func _phase(elapsed: float) -> GeyserCycle.Phase:
	return GeyserCycle.phase_at(elapsed, SWELL, ERUPT, DORMANT)


func test_the_period_is_the_three_durations() -> void:
	check_near(GeyserCycle.period(SWELL, ERUPT, DORMANT), 3.0, 0.0001, "swell, eruption, quiet")


## The claim the respawn rests on. See `GeyserCycle` and `Geyser.reset`.
func test_the_cycle_starts_at_the_tell() -> void:
	check_eq(_phase(0.0), GeyserCycle.Phase.SWELL, "zero is the first frame of the swell")
	check_eq(
		_phase(-0.15), GeyserCycle.Phase.SWELL,
		"and so is the respawn freeze the clock is parked behind"
	)
	check_eq(
		_phase(-99.0), GeyserCycle.Phase.SWELL,
		"nothing precedes the clock, however far back you ask"
	)


func test_each_phase_owns_its_own_stretch() -> void:
	check_eq(_phase(SWELL * 0.5), GeyserCycle.Phase.SWELL, "halfway through the warning")
	check_eq(_phase(SWELL), GeyserCycle.Phase.ERUPTING, "the jet comes up as the warning ends")
	check_eq(_phase(SWELL + ERUPT * 0.5), GeyserCycle.Phase.ERUPTING, "and stays up")
	check_eq(_phase(SWELL + ERUPT), GeyserCycle.Phase.DORMANT, "and then it is quiet")
	check_eq(
		_phase(SWELL + ERUPT + DORMANT - 0.01), GeyserCycle.Phase.DORMANT,
		"quiet right up to the end of the period"
	)


func test_it_comes_round_again() -> void:
	var period := GeyserCycle.period(SWELL, ERUPT, DORMANT)
	check_eq(_phase(period), GeyserCycle.Phase.SWELL, "a whole period later it is swelling again")
	check_eq(
		_phase(period * 4.0 + SWELL + 0.1), GeyserCycle.Phase.ERUPTING,
		"and four periods later it is still keeping time"
	)


## The one question the node asks every physics frame, and the reason a geyser is
## not a hazard: the answer being false is the whole of what a geyser does to you
## most of the time.
func test_only_an_eruption_lifts_anything() -> void:
	check(GeyserCycle.lifts(GeyserCycle.Phase.ERUPTING), "an eruption lifts")
	check(not GeyserCycle.lifts(GeyserCycle.Phase.SWELL), "a swell does not")
	check(not GeyserCycle.lifts(GeyserCycle.Phase.DORMANT), "and a quiet vent does not")


func test_the_tell_ramps_up_across_the_warning() -> void:
	check_near(GeyserCycle.swell_ramp(0.0, SWELL, ERUPT, DORMANT), 0.0, 0.001, "nothing at first")
	check_near(
		GeyserCycle.swell_ramp(SWELL * 0.5, SWELL, ERUPT, DORMANT), 0.5, 0.001,
		"half a warning in, half a tell"
	)
	check(
		GeyserCycle.swell_ramp(SWELL - 0.01, SWELL, ERUPT, DORMANT) > 0.97,
		"and all of it by the last frame"
	)
	check_near(
		GeyserCycle.swell_ramp(SWELL + 0.1, SWELL, ERUPT, DORMANT), 0.0, 0.001,
		"the tell is over once the jet is doing the talking"
	)
	check_near(
		GeyserCycle.swell_ramp(SWELL + ERUPT + 0.1, SWELL, ERUPT, DORMANT), 0.0, 0.001,
		"and a quiet vent is not swelling"
	)


func test_a_ride_is_the_distance_over_the_speed() -> void:
	check_near(GeyserCycle.ride_seconds(120.0, 170.0), 0.70588, 0.0001, "120 px at 170 px/s")
	check_eq(GeyserCycle.ride_seconds(0.0, 170.0), 0.0, "nowhere to go takes no time")
	check_eq(GeyserCycle.ride_seconds(120.0, 0.0), 0.0, "and a jet that does not move is not a ride")


## The number a room is laid out against. A checkpoint is placed well when the
## run from it to the vent fits inside this, and badly when every death costs a
## whole quiet period on top of the climb you missed.
func test_the_boarding_window_is_the_warning_plus_what_is_left_of_the_eruption() -> void:
	var window := GeyserCycle.boarding_window(SWELL, ERUPT, 120.0, 170.0)
	check_near(window, SWELL + ERUPT - 0.70588, 0.0001, "the warning, and the eruption less a ride")
	check(
		window < SWELL + ERUPT,
		"arriving on the last frame of an eruption is not a boarding"
	)


## A jet too short-lived to carry you the distance the room asked for. The window
## is then the warning and nothing else, which is a room that cannot be finished
## rather than a negative number that reads as one that can.
func test_a_ride_longer_than_the_eruption_leaves_no_window() -> void:
	check_near(
		GeyserCycle.boarding_window(SWELL, 0.4, 120.0, 170.0), SWELL, 0.0001,
		"an eruption shorter than the ride buys nothing past the warning"
	)


## A geyser a room forgot to give any durations to. It has to read as something
## rather than divide by zero, and the something it reads as is a vent that never
## goes off.
func test_a_clock_with_no_time_in_it_does_not_divide_by_zero() -> void:
	check_eq(GeyserCycle.phase_at(5.0, 0.0, 0.0, 0.0), GeyserCycle.Phase.DORMANT, "quiet forever")
	check_eq(GeyserCycle.period(0.0, 0.0, 0.0), 0.0, "and its period is nothing")
	check_near(GeyserCycle.swell_ramp(5.0, 0.0, 0.0, 0.0), 0.0, 0.001, "with no tell to draw")


func test_every_phase_has_a_name_for_the_log() -> void:
	check_eq(GeyserCycle.phase_name(GeyserCycle.Phase.SWELL), "swelling", "swelling")
	check_eq(GeyserCycle.phase_name(GeyserCycle.Phase.ERUPTING), "erupting", "erupting")
	check_eq(GeyserCycle.phase_name(GeyserCycle.Phase.DORMANT), "dormant", "dormant")
