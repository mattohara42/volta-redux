## The dragon's breath clock, as arithmetic. See `test_geyser_cycle.gd`: same
## claims, same reasons, a different mechanism.
extends TestCase

const CHARGE := 0.8
const BREATHE := 0.6
const REST := 1.6


func _phase(elapsed: float) -> DragonBreath.Phase:
	return DragonBreath.phase_at(elapsed, CHARGE, BREATHE, REST)


func test_the_period_is_the_three_durations() -> void:
	check_near(DragonBreath.period(CHARGE, BREATHE, REST), 3.0, 0.0001, "charge, breath, rest")


## The claim a respawn near the dragon rests on. See `Dragon.reset`.
func test_the_cycle_starts_at_the_tell() -> void:
	check_eq(_phase(0.0), DragonBreath.Phase.CHARGE, "zero is the first frame of the charge")
	check_eq(
		_phase(-0.15), DragonBreath.Phase.CHARGE,
		"and so is the respawn freeze the clock is parked behind"
	)
	check_eq(_phase(-99.0), DragonBreath.Phase.CHARGE, "nothing precedes the clock")


func test_each_phase_owns_its_own_stretch() -> void:
	check_eq(_phase(CHARGE * 0.5), DragonBreath.Phase.CHARGE, "halfway through the tell")
	check_eq(_phase(CHARGE), DragonBreath.Phase.BREATHING, "the breath comes as the tell ends")
	check_eq(_phase(CHARGE + BREATHE * 0.5), DragonBreath.Phase.BREATHING, "and stays out")
	check_eq(_phase(CHARGE + BREATHE), DragonBreath.Phase.REST, "and then it is quiet")
	check_eq(
		_phase(CHARGE + BREATHE + REST - 0.01), DragonBreath.Phase.REST,
		"quiet right up to the end of the period"
	)


func test_it_comes_round_again() -> void:
	var period := DragonBreath.period(CHARGE, BREATHE, REST)
	check_eq(_phase(period), DragonBreath.Phase.CHARGE, "a whole period later it is charging again")


func test_only_breathing_is_lethal() -> void:
	check(DragonBreath.is_lethal(DragonBreath.Phase.BREATHING), "a breath kills")
	check(not DragonBreath.is_lethal(DragonBreath.Phase.CHARGE), "a charge does not")
	check(not DragonBreath.is_lethal(DragonBreath.Phase.REST), "and rest does not")


func test_the_tell_ramps_up_across_the_charge() -> void:
	check_near(DragonBreath.charge_ramp(0.0, CHARGE, BREATHE, REST), 0.0, 0.001, "nothing at first")
	check_near(
		DragonBreath.charge_ramp(CHARGE * 0.5, CHARGE, BREATHE, REST), 0.5, 0.001,
		"half a charge in, half a tell"
	)
	check_near(
		DragonBreath.charge_ramp(CHARGE + 0.1, CHARGE, BREATHE, REST), 0.0, 0.001,
		"the tell is over once the breath is doing the talking"
	)


func test_a_clock_with_no_time_in_it_does_not_divide_by_zero() -> void:
	check_eq(DragonBreath.phase_at(5.0, 0.0, 0.0, 0.0), DragonBreath.Phase.REST, "quiet forever")
	check_eq(DragonBreath.period(0.0, 0.0, 0.0), 0.0, "and its period is nothing")


func test_every_phase_has_a_name_for_the_log() -> void:
	check_eq(DragonBreath.phase_name(DragonBreath.Phase.CHARGE), "charging", "charging")
	check_eq(DragonBreath.phase_name(DragonBreath.Phase.BREATHING), "breathing", "breathing")
	check_eq(DragonBreath.phase_name(DragonBreath.Phase.REST), "resting", "resting")
