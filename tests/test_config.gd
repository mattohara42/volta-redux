## The tuning files themselves. CLAUDE.md puts every feel-deciding number in
## config/, which only helps if something notices when one of them stops making
## sense.
extends TestCase

const CLIMB := "res://config/movement.tres"
const STRONG := "res://config/movement_strong.tres"
const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"
const HAZARDS := "res://config/hazards.tres"

## The two presets are a controlled experiment, so everything except the jump
## and the time it takes has to be identical between them.
const SHARED_PROPERTIES: PackedStringArray = [
	"max_run_speed", "ground_accel", "ground_friction", "air_accel", "air_friction",
	"fall_gravity_multiplier", "jump_release_damping", "max_fall_speed",
	"coyote_time", "jump_buffer_time", "climb_speed",
]


func test_every_tuning_file_loads() -> void:
	check(load(CLIMB) is MovementConfig, "config/movement.tres is a MovementConfig")
	check(load(STRONG) is MovementConfig, "config/movement_strong.tres is a MovementConfig")
	check(load(WORLD) is WorldConfig, "config/world.tres is a WorldConfig")
	check(load(SWORD) is SwordConfig, "config/sword.tres is a SwordConfig")
	check(load(HAZARDS) is HazardConfig, "config/hazards.tres is a HazardConfig")


func test_no_tuning_number_is_nonsense() -> void:
	var presets: PackedStringArray = [CLIMB, STRONG]
	for path in presets:
		var config: MovementConfig = load(path)
		var name := path.get_file()
		check(config.max_run_speed > 0.0, "%s run speed is positive" % name)
		check(config.jump_height > 0.0, "%s jump height is positive" % name)
		check(config.time_to_apex > 0.0, "%s time to apex is positive" % name)
		check(config.ground_accel > 0.0, "%s ground accel is positive" % name)
		check(config.climb_speed > 0.0, "%s climb speed is positive" % name)
		check(config.max_fall_speed > 0.0, "%s max fall speed is positive" % name)
		check(config.coyote_time >= 0.0, "%s coyote time is not negative" % name)
		check(config.jump_buffer_time >= 0.0, "%s jump buffer is not negative" % name)
		check(
			config.fall_gravity_multiplier >= 1.0,
			"%s falls at least as fast as it rises, or the jump floats" % name
		)
		check(
			config.jump_release_damping >= 0.0 and config.jump_release_damping <= 1.0,
			"%s release damping is a fraction" % name
		)
		check(
			config.air_accel <= config.ground_accel,
			"%s air control does not exceed ground control" % name
		)


## The jump-versus-ladders question in SPEC.md, stated as an assertion. If either
## of these fails, the two presets have stopped being the two answers.
func test_the_two_presets_sit_on_opposite_sides_of_a_tier() -> void:
	var world: WorldConfig = load(WORLD)
	var strong: MovementConfig = load(STRONG)
	var climb: MovementConfig = load(CLIMB)
	check(
		strong.jump_height > world.tier_height,
		"the strong preset clears a tier without a ladder"
	)
	check(
		climb.jump_height < world.tier_height,
		"the game's jump cannot clear a tier, which is the whole point of it"
	)


## Gravity is the same in both, so jump height is the only variable and the
## comparison means something. See the note in config/movement.tres.
func test_the_two_presets_share_a_gravity() -> void:
	var strong: MovementConfig = load(STRONG)
	var climb: MovementConfig = load(CLIMB)
	var g_strong := Motion.gravity_for(strong.jump_height, strong.time_to_apex)
	var g_climb := Motion.gravity_for(climb.jump_height, climb.time_to_apex)
	check_near(g_climb, g_strong, g_strong * 0.01, "derived gravity matches within 1 percent")


func test_the_two_presets_differ_in_nothing_else() -> void:
	var strong: MovementConfig = load(STRONG)
	var climb: MovementConfig = load(CLIMB)
	for property in SHARED_PROPERTIES:
		check_eq(
			climb.get(property), strong.get(property),
			"%s is shared between the presets" % property
		)


func test_world_scale_holds_together() -> void:
	var world: WorldConfig = load(WORLD)
	check(world.hero_height > 0.0, "hero height is positive")
	check(world.hero_width > 0.0, "hero width is positive")
	check(
		world.hero_width < world.hero_height,
		"the hero is taller than it is wide, or the silhouette will not read"
	)
	check(
		world.tier_height > world.hero_height,
		"a tier is taller than the hero, or it is a step and not a storey"
	)
	check(
		is_zero_approx(fmod(world.tier_height, world.tile_size)),
		"tier height is a whole number of tiles"
	)


## The sword's numbers. SPEC.md makes the sword the game, so the file that
## decides how it behaves gets held to the claims the design makes about it.
func test_the_sword_numbers_hold_together() -> void:
	var sword: SwordConfig = load(SWORD)
	var world: WorldConfig = load(WORLD)
	check(sword.speed > 0.0, "it goes somewhere")
	check(sword.max_range > 0.0, "it has a range")
	check(
		sword.max_return_distance > sword.max_range,
		"the return has more budget than the throw, or standing still would miss"
	)
	check(sword.catch_radius > 0.0, "there is a catch window at all")
	check(
		sword.catch_radius < world.hero_height * 0.5,
		"the catch window is smaller than half a hero, or a jump would not miss"
	)
	check(sword.pickup_radius > 0.0, "a grounded sword can be walked over")
	check(sword.fall_gravity > 0.0, "a spent sword falls")
	check(sword.max_fall_speed > 0.0, "and stops accelerating eventually")
	check(sword.throw_cooldown > 0.0, "a held button is not an automatic weapon")


## SPEC.md: three swords, cap five. Ten was the original's number and it is why
## no single throw mattered there.
func test_the_sword_count_is_the_difficulty_dial_and_it_is_small() -> void:
	var sword: SwordConfig = load(SWORD)
	check(sword.starting_swords >= 1, "you start with something to throw")
	check(
		sword.starting_swords <= sword.max_swords,
		"you do not start over the cap"
	)
	check(sword.max_swords <= 5, "cap five, per SPEC.md")


## An embedded sword is a one-tile ledge in M2. If these drift apart, that stops
## being true and the Act 1 puzzles stop working.
func test_a_sword_is_one_tile_long() -> void:
	var world: WorldConfig = load(WORLD)
	check_eq(world.sword_length, world.tile_size, "sword length is one tile")


## The spike numbers. The one that decides how the game feels is `spike_grace`,
## and it is a forgiveness, so the only way it can be wrong in a way arithmetic
## catches is by being large enough to walk through a bed.
func test_the_spike_numbers_hold_together() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var world: WorldConfig = load(WORLD)
	check(hazards.spike_tooth_height > 0.0, "a tooth stands off the surface")
	check(hazards.spike_tooth_pitch > 0.0, "and the points are spaced apart")
	check(
		hazards.spike_tooth_height <= world.tile_size,
		"a tooth is no taller than a tile, or a bed is terrain and not a hazard"
	)
	check(
		hazards.spike_tooth_pitch < world.hero_width,
		"at least two points sit under a standing hero, or a bed reads as a fence"
	)
	check(hazards.spike_grace >= 0.0, "the grace is forgiveness, never extra reach")
	check(
		hazards.spike_grace < hazards.spike_tooth_height,
		"the grace is smaller than a tooth, or the bed has no killing box left"
	)


## The grace is forgiveness and most of a tooth still has to kill, or a bed
## stops being a hazard and becomes a texture.
func test_the_spike_grace_leaves_most_of_the_tooth_lethal() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var fraction := hazards.spike_grace / hazards.spike_tooth_height
	check(
		fraction < 0.34,
		"the spike grace is %.0f%% of a tooth" % [fraction * 100.0]
	)


## The falling platform's numbers. Every one of them is a duration or a tremor,
## and the two claims worth asserting are that a slab warns you before it goes
## and that it goes gently enough to be jumped off.
func test_the_falling_platform_numbers_hold_together() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var climb: MovementConfig = load(CLIMB)
	var world: WorldConfig = load(WORLD)
	check(hazards.platform_warn_time > 0.0, "a platform warns you before it goes")
	check(hazards.platform_fall_gravity > 0.0, "and then it actually falls")
	check(hazards.platform_return_time >= 0.0, "and comes back, or stays gone")
	var hero_falls := (
		Motion.gravity_for(climb.jump_height, climb.time_to_apex)
		* climb.fall_gravity_multiplier
	)
	check(
		hazards.platform_fall_gravity < hero_falls,
		"a slab falls at %.0f px/s^2 against the hero's %.0f, so it sinks away from"
		% [hazards.platform_fall_gravity, hero_falls]
		+ " under you rather than snapping out of frame"
	)
	check(
		hazards.platform_shake > 0.0 and hazards.platform_shake < world.hero_width * 0.25,
		"the warning is a tremor and not a wobble"
	)
	check(
		hazards.platform_shake_hz > 4.0,
		"and it oscillates fast enough to read as unstable rather than as moving"
	)


## The warning has to be a thing a person can act on. Under the whole of the
## jump buffer it would be a warning you cannot answer even with the input
## already in, which is the 1984 complaint SPEC.md exists to throw away.
func test_the_platform_warning_outlasts_the_forgiveness_windows() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var climb: MovementConfig = load(CLIMB)
	check(
		hazards.platform_warn_time > climb.jump_buffer_time + climb.coyote_time,
		"the %.2f s warning outlasts the %.2f s of buffer and coyote time it has to"
		% [hazards.platform_warn_time, climb.jump_buffer_time + climb.coyote_time]
		+ " be answered through"
	)


## The geyser's numbers. Every one is a duration or a speed, because a geyser has
## no shape of its own: how tall and how wide a shaft is belongs to the room that
## dug it. What is worth asserting here is that the thing warns you, that it
## stays up long enough to be a way up rather than a trick, and that a ride does
## not read as a jump somebody else is doing for you.
func test_the_geyser_numbers_hold_together() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	check(hazards.geyser_swell_time > 0.0, "a geyser warns you before it goes")
	check(hazards.geyser_erupt_time > 0.0, "and then it actually comes up")
	check(hazards.geyser_dormant_time > 0.0, "and goes quiet again, or it is a fountain")
	check(hazards.geyser_lift_speed > 0.0, "and it carries you somewhere while it is up")
	check(
		hazards.geyser_erupt_time > hazards.geyser_swell_time,
		"a jet is up for longer than it spends warning you, or the warning is the event"
	)


## SPEC.md makes geysers one of the two ordinary ways to gain a storey in Act 2.
## That is a claim about these numbers and not about any one room: a jet that
## subsides before it has carried anybody a storey is scenery wherever it is put.
func test_an_eruption_lasts_long_enough_to_carry_a_storey() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var world: WorldConfig = load(WORLD)
	var storey := GeyserCycle.ride_seconds(world.tier_height, hazards.geyser_lift_speed)
	check(
		hazards.geyser_erupt_time > storey,
		"a storey takes %.2f s to ride and an eruption lasts %.2f s"
		% [storey, hazards.geyser_erupt_time]
	)


## The warning has to be a thing a person can act on, which is the same claim the
## falling platform's tell is held to and for the same reason.
func test_the_geyser_warning_outlasts_the_forgiveness_windows() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var climb: MovementConfig = load(CLIMB)
	check(
		hazards.geyser_swell_time > climb.jump_buffer_time + climb.coyote_time,
		"the %.2f s swell outlasts the %.2f s of buffer and coyote time it has to be"
		% [hazards.geyser_swell_time, climb.jump_buffer_time + climb.coyote_time]
		+ " answered through"
	)


## A ride reads as being carried rather than as a jump. It is the difference
## between a mechanism moving you and a mechanism playing the game for you, and
## the tell is that a geyser is plainly slower than you can leave the ground on
## your own.
func test_a_jet_is_slower_than_the_hero_can_jump() -> void:
	var hazards: HazardConfig = load(HAZARDS)
	var climb: MovementConfig = load(CLIMB)
	var takeoff := Motion.jump_speed_for(climb.jump_height, climb.time_to_apex)
	check(
		hazards.geyser_lift_speed < takeoff,
		"a jet lifts at %.0f px/s against a %.0f px/s takeoff"
		% [hazards.geyser_lift_speed, takeoff]
	)
