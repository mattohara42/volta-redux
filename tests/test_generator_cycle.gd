## The generator's arc clock: rest, warning, strike, starting at rest.
extends TestCase

const P := GeneratorCycle.Phase


func test_it_starts_at_rest_so_a_respawn_is_safe() -> void:
	check_eq(GeneratorCycle.phase_at(0.0, 1.6, 0.8, 0.3), P.REST, "zero is rest")
	check_eq(GeneratorCycle.phase_at(-1.0, 1.6, 0.8, 0.3), P.REST, "and a frozen clock below zero is too")


func test_the_phases_run_in_order_and_repeat() -> void:
	check_eq(GeneratorCycle.phase_at(1.7, 1.6, 0.8, 0.3), P.WARNING, "warning after rest")
	check_eq(GeneratorCycle.phase_at(2.5, 1.6, 0.8, 0.3), P.STRIKING, "strike after warning")
	check_eq(GeneratorCycle.phase_at(2.8, 1.6, 0.8, 0.3), P.REST, "then rest again")
	check_eq(GeneratorCycle.arc_index(2.8, 1.6, 0.8, 0.3), 1, "on the second arc")


func test_the_warning_can_be_walked_out_of() -> void:
	var enemies: EnemyConfig = load("res://config/enemies.tres")
	var move: MovementConfig = load("res://config/movement.tres")
	var world: WorldConfig = load("res://config/world.tres")
	var clear := enemies.generator_strike_size.x * 0.5 + world.hero_width * 0.5
	check(move.max_run_speed * enemies.generator_warning_time > clear * 2.0, "the warning is long enough to step clear at a run, twice over")
