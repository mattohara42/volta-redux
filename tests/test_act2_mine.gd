## Act 2's mine, as arithmetic. Both storeys are sword-step ditches and
## `DitchChecks` holds each. The eyeball stays off both landings, so arriving
## and taking aim are always safe, and it sits at the middle level's height.
extends TestCase

const WORLD := "res://config/world.tres"


func test_the_first_storey_needs_a_sword() -> void:
	DitchChecks.run(self, "Act2Mine first", Act2Mine.NEAR_1, Act2Mine.TOP_0, Act2Mine.TOP_1, Act2Mine.HOARDING_1, Act2Mine.PIT_1)


func test_the_second_storey_needs_a_sword() -> void:
	DitchChecks.run(self, "Act2Mine second", Act2Mine.NEAR_2, Act2Mine.TOP_1, Act2Mine.TOP_2, Act2Mine.HOARDING_2, Act2Mine.PIT_2)


func test_the_eyeball_keeps_off_both_landings() -> void:
	var world: WorldConfig = load(WORLD)
	var half := Act2Mine.EYEBALL_SIZE.x * 0.5
	check(Act2Mine.EYEBALL_ROAM.position.x - half > Act2Mine.MID_CHEST_X, "it never reaches the landing with the chest")
	check(
		Act2Mine.EYEBALL_ROAM.end.x + half < Act2Mine.NEAR_2 - world.hero_width,
		"and a hero at the second lip is clear of it"
	)


func test_the_eyeball_works_the_middle_level_at_body_height() -> void:
	var world: WorldConfig = load(WORLD)
	var body_y := Act2Mine.TOP_1 - world.hero_height * 0.5
	check(body_y >= Act2Mine.EYEBALL_ROAM.position.y and body_y <= Act2Mine.EYEBALL_ROAM.end.y, "it can drift to a hero's height there")
	check(Act2Mine.EYEBALL_ROAM.end.y <= Act2Mine.TOP_1, "and never into the floor")
