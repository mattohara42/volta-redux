## Act 3's first two rooms, as arithmetic. Each seam sits where its throw flies
## and a sword there reaches the metal either side; the insulator's low seam
## has wood under it, which is not a conductor; every live face is recessed so
## dropping past it never touches it; and every face is in range of its throw.
extends TestCase

const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"


func _spans(throw_y: float, above: Rect2, below: Rect2) -> bool:
	var sword: SwordConfig = load(SWORD)
	var half := Sword.LEDGE_THICKNESS * 0.5 + sword.conduct_reach
	return throw_y - half < above.end.y and throw_y + half > below.position.y


func _throw_y(stand: float) -> float:
	var world: WorldConfig = load(WORLD)
	return stand - world.hero_height * 0.5


func test_the_hall_seam_joins_live_copper_to_the_stub() -> void:
	check(_spans(_throw_y(Bench.FLOOR_TOP), Act3Hall.live_copper(), Act3Hall.stub()), "a throw from the yard lands across the seam")


func test_the_insulator_high_seam_needs_the_step() -> void:
	var move: MovementConfig = load("res://config/movement.tres")
	check(_spans(_throw_y(Act3Insulator.STEP.position.y), Act3Insulator.live_copper(), Act3Insulator.wired_copper()), "a throw from the step lands across the copper seam")
	check(not _spans(_throw_y(Bench.FLOOR_TOP), Act3Insulator.live_copper(), Act3Insulator.wired_copper()), "a throw from the floor does not")
	check(Bench.FLOOR_TOP - Act3Insulator.STEP.position.y < move.jump_height, "and the step is a jump up")


func test_the_insulator_low_seam_has_wood_under_it() -> void:
	check(_spans(_throw_y(Bench.FLOOR_TOP), Act3Insulator.wired_copper(), Act3Insulator.wood()), "the floor throw lands across the low seam, copper over wood")
	check(Act3Insulator.wood().end.y == Bench.FLOOR_TOP, "the wood runs to the floor, so nothing below it conducts")


func test_live_faces_are_recessed_from_the_drop() -> void:
	var world: WorldConfig = load(WORLD)
	for face in [Act3Hall.FACE_X, Act3Insulator.FACE_X]:
		check(Act3Room.RECESS > Conductor.TOUCH, "a hero dropping past the lip never brushes the copper at %.0f" % face)
	check_eq(Act3Hall.YARD_X - Act3Hall.FACE_X, Act3Room.RECESS, "the hall's face sits back under its ledge")
	check(world.hero_width * 0.5 > 0.0, "the hero has width")


func test_every_face_is_in_range_of_its_throw() -> void:
	var sword: SwordConfig = load(SWORD)
	check(Act3Hall.GATE.position.x - Act3Hall.FACE_X < sword.max_range, "anywhere in the hall's yard short of the gate")
	check(Act3Insulator.STEP.end.x - Act3Insulator.FACE_X < sword.max_range, "anywhere on the insulator's step")


func test_the_copper_floor_room_can_be_thrown_from_the_stone() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	check(_spans(_throw_y(Bench.FLOOR_TOP), Act3Floor.live_copper(), Act3Floor.stub()), "a yard throw lands across its seam")
	var off_strip := Act3Floor.STRIP.end.x + world.hero_width * 0.5
	check(off_strip - Act3Floor.FACE_X < sword.max_range, "standing just off the copper, the face is in range")
	check(Act3Floor.GATE.position.x > off_strip, "and the gate is beyond the copper, so nobody has to cross it live")


func test_the_series_room_needs_both_seams() -> void:
	check(_spans(_throw_y(Bench.FLOOR_TOP), Act3Series.middle(), Act3Series.stub()), "the yard throw bridges the low seam")
	check(_spans(_throw_y(Act3Series.STEP.position.y), Act3Series.live_copper(), Act3Series.middle()), "the step throw bridges the high seam")
	check(not _spans(_throw_y(Bench.FLOOR_TOP), Act3Series.live_copper(), Act3Series.middle()), "and the yard throw cannot reach the high one")
	var links_low := Circuit.links_through([1, 2])
	var links_high := Circuit.links_through([0, 1])
	check(not Circuit.connected(0, 2, links_low), "the low seam alone leaves the stub dead")
	check(not Circuit.connected(0, 2, links_high), "the high seam alone leaves the stub dead")
	check(Circuit.connected(0, 2, links_low + links_high), "both together make it live")
