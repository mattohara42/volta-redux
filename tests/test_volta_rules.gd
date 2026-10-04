## Volta's pulls and the chains' burn.
extends TestCase


func test_every_third_cast_is_a_pull() -> void:
	check(not VoltaRules.is_pull(0, 3), "the first cast is a bolt")
	check(not VoltaRules.is_pull(1, 3), "so is the second")
	check(VoltaRules.is_pull(2, 3), "the third is a pull")
	check(VoltaRules.is_pull(5, 3), "and every third after")
	check(not VoltaRules.is_pull(2, 0), "never, if pulls are off")


func test_the_chains_burn_only_while_current_holds() -> void:
	var burn := 0.0
	for i in 10:
		burn = VoltaRules.burn_after(burn, true, 0.1)
	check_near(burn, 1.0, 0.001, "a second held is a second burnt")
	burn = VoltaRules.burn_after(burn, false, 0.1)
	check_eq(burn, 0.0, "a break starts it again")
	check(VoltaRules.chains_free(2.0, 2.0), "enough burn frees them")


func test_the_burn_fits_between_two_pulls() -> void:
	var c: EnemyConfig = load("res://config/enemies.tres")
	var cast := GeneratorCycle.period(c.volta_rest_time, c.volta_warning_time, c.volta_strike_time)
	var between_pulls := cast * c.volta_pull_every - c.volta_strike_time
	check(c.volta_chain_burn_time < between_pulls * 0.5, "there is room to bridge late and still finish before the next pull")
