## The slash with the sword that never leaves his hand (`SlashRules`, `Slash`).
extends TestCase

const HALF := 9.0
const REACH := 22.0
const HEIGHT := 28.0
const ACTIVE := 0.12
const RECOVERY := 0.3


func test_the_strike_is_in_front_whichever_way_he_faces() -> void:
	var right := SlashRules.box(1.0, HALF, REACH, HEIGHT)
	check_near(right.position.x, HALF, 0.001, "facing right it starts at his front")
	check_near(right.end.x, HALF + REACH, 0.001, "and reaches out by the reach")
	var left := SlashRules.box(-1.0, HALF, REACH, HEIGHT)
	check_near(left.end.x, -HALF, 0.001, "facing left it ends at his front")
	check_near(left.position.x, -HALF - REACH, 0.001, "and reaches out by the reach")
	check_near(right.get_center().y, 0.0, 0.001, "centred on his middle")


func test_it_cuts_only_while_it_strikes() -> void:
	check(SlashRules.is_striking(0.0, ACTIVE), "the press cuts")
	check(SlashRules.is_striking(ACTIVE * 0.9, ACTIVE), "and keeps cutting through the strike")
	check(not SlashRules.is_striking(ACTIVE, ACTIVE), "and stops when it ends")
	check(not SlashRules.is_striking(INF, ACTIVE), "never struck, nothing cuts")


func test_recovery_holds_the_next_slash() -> void:
	check(SlashRules.can_slash(INF, ACTIVE, RECOVERY, false, false), "the first press always cuts")
	check(not SlashRules.can_slash(ACTIVE + RECOVERY * 0.5, ACTIVE, RECOVERY, false, false), "not mid-recovery")
	check(SlashRules.can_slash(ACTIVE + RECOVERY, ACTIVE, RECOVERY, false, false), "free again after it")


func test_a_somersault_or_a_dive_holds_it_as_it_holds_the_throw() -> void:
	check(not SlashRules.can_slash(INF, ACTIVE, RECOVERY, true, false), "not mid-somersault")
	check(not SlashRules.can_slash(INF, ACTIVE, RECOVERY, false, true), "not in a dive's recovery")


func test_the_blade_sweeps_from_raised_to_lowered() -> void:
	var sweep := deg_to_rad(150.0)
	check_near(SlashRules.blade_angle(0.0, ACTIVE, sweep), -sweep * 0.5, 0.001, "starts raised")
	check_near(SlashRules.blade_angle(ACTIVE * 0.5, ACTIVE, sweep), 0.0, 0.001, "is level halfway")
	check_near(SlashRules.blade_angle(ACTIVE, ACTIVE, sweep), sweep * 0.5, 0.001, "ends lowered")


## SPEC.md: the bosses are anti-sword, and the slash does not change that
## (Matt, 2026-10-25). The dragon only answers to a sword coming home, so a
## cut from the hand is turned.
func test_the_dragon_shrugs_off_a_slash() -> void:
	var dragon := Dragon.new()
	var hand := Node2D.new()
	check(not dragon.is_vulnerable_to(hand), "a slash is not a recalling sword")
	hand.free()
	dragon.free()


func test_the_scorpions_armour_turns_a_slash_as_it_turns_a_throw() -> void:
	# The cut comes from the hand: in front of a scorpion facing right, at its
	# middle, is the armoured side.
	check(not ScorpionPatrol.is_vulnerable_to(Vector2(20.0, 0.0), 1.0, 17.0, 0.35), "a cut at its face is turned")
	check(ScorpionPatrol.is_vulnerable_to(Vector2(-20.0, 0.0), 1.0, 17.0, 0.35), "a cut at its back gets through")
