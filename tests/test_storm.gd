## The storm (`Storm`, `StormRules`). What a test can hold is the rule: a
## strike is a few pulses and an afterglow, the flash over everything comes
## once a strike, a bolt stays in its window's glass, and the storm is in the
## acts it was asked for. What it looks like is a screenshot's job.
extends TestCase

const CONFIG: StormConfig = preload("res://config/storm.tres")
const PANE := Rect2(89, 36, 40, 115)


func test_a_strike_is_pulses_with_half_light_between_then_an_afterglow() -> void:
	var pulse := 0.06
	var gap := 0.07
	check_eq(StormRules.sky(-0.01, 3, pulse, gap, 0.35, 0.35), 0.0, "dark before the strike")
	check_eq(StormRules.sky(0.03, 3, pulse, gap, 0.35, 0.35), 1.0, "full in the first pulse")
	check_eq(StormRules.sky(0.09, 3, pulse, gap, 0.35, 0.35), 0.35, "half light in the gap")
	check_eq(StormRules.sky(0.16, 3, pulse, gap, 0.35, 0.35), 1.0, "full in the second pulse")
	var end := StormRules.length(3, pulse, gap, 0.35)
	check_near(end, 3 * pulse + 2 * gap + 0.35, 0.0001, "a strike lasts its pulses, gaps and afterglow")
	check(StormRules.sky(end - 0.1, 3, pulse, gap, 0.35, 0.35) < 1.0, "fading in the afterglow")
	check_eq(StormRules.sky(end + 0.01, 3, pulse, gap, 0.35, 0.35), 0.0, "dark again after it")


## The flash over everything comes once, on the first pulse, so a strike is
## one white beat however many times the sky flickers. Never a strobe.
func test_the_whiteout_is_one_beat_and_clears_before_the_strike_ends() -> void:
	var hold := CONFIG.whiteout_hold_seconds
	var fade := CONFIG.whiteout_fade_seconds
	check_eq(StormRules.whiteout(0.0, hold, fade), 1.0, "full at the strike")
	var cleared := hold + fade
	check_eq(StormRules.whiteout(cleared + 0.001, hold, fade), 0.0, "clear after the hold and fade")
	var last := 1.0
	var t := 0.0
	while t < cleared:
		var now := StormRules.whiteout(t, hold, fade)
		check(now <= last, "never brightens again once clearing (%.2f s)" % t)
		last = now
		t += 0.01
	check(cleared < 0.5, "the room is back in under half a second (%.2f s)" % cleared)


## Rare, or a flash is a strobe and the game has a photosensitivity problem.
func test_strikes_are_rare() -> void:
	check(CONFIG.strike_gap_min >= 5.0, "at least five seconds between strikes")
	check(CONFIG.strike_gap_max >= CONFIG.strike_gap_min, "the gap's range runs low to high")
	check(CONFIG.pulses_max <= 4, "no more than four pulses a strike")
	check_near(StormRules.gap(0.0, 10.0, 24.0), 10.0, 0.0001, "a roll of 0 is the shortest gap")
	check_near(StormRules.gap(1.0, 10.0, 24.0), 24.0, 0.0001, "a roll of 1 is the longest")
	check_eq(StormRules.pulses(0.0, 3), 1, "a roll of 0 is one pulse")
	check_eq(StormRules.pulses(1.0, 3), 3, "a roll of 1 is the most")


func test_a_window_arch_is_pointed_and_fills_its_pane() -> void:
	var arch := StormRules.arch(PANE)
	var bounds := Rect2(arch[0], Vector2.ZERO)
	for p in arch:
		bounds = bounds.expand(p)
	check_eq(bounds, PANE, "the arch fills its pane exactly")
	check_eq(StormRules.arch_half_width(PANE, PANE.end.y - 1.0), PANE.size.x * 0.5, "full width at the sill")
	check_eq(StormRules.arch_half_width(PANE, PANE.position.y), 0.0, "nothing at the tip")


func test_a_bolt_stays_in_its_window_glass() -> void:
	for seed_value in 20:
		var path := ArcPath.bolt(Vector2(109, 38), Vector2(100, PANE.end.y), seed_value, CONFIG.bolt_subdivisions, CONFIG.bolt_jag)
		for p in StormRules.inside_arch(path, PANE):
			var reach := StormRules.arch_half_width(PANE, p.y)
			check(absf(p.x - PANE.get_center().x) <= reach, "seed %d: %s inside the arch" % [seed_value, p])
			check(p.y >= PANE.position.y and p.y <= PANE.end.y, "seed %d: %s between tip and sill" % [seed_value, p])


func test_the_storm_is_out_on_the_wall_and_in_the_hall_windows() -> void:
	var act1: ActConfig = load("res://config/act1.tres")
	var act4: ActConfig = load("res://config/act4.tres")
	check_eq(act1.storm, Storm.Kind.RAIN, "Act 1 has rain and lightning")
	check_eq(act4.storm, Storm.Kind.WINDOWS, "Act 4 sees it through its windows")
	check(not act4.tiles.windows.is_empty(), "Act 4's painting says where its windows are")
	for act in ["res://config/act2.tres", "res://config/act3.tres"]:
		check_eq((load(act) as ActConfig).storm, Storm.Kind.NONE, "%s is under the mountain, out of the weather" % act.get_file())
	var thunder: AudioStream = (load("res://config/audio.tres") as AudioConfig).thunder
	check(thunder != null, "the thunder is wired")


## The flash is Volta's colour, and never pure white (`ART_DIRECTION.md`).
func test_the_flash_is_volta_and_never_pure_white() -> void:
	check(Palette.ARC_CORE != Color.WHITE, "the flash is not pure white")
	check(CONFIG.whiteout < 1.0, "the flash never quite covers the room")
