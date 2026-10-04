## The M12 bench, as arithmetic: the seam sits where a standing throw flies,
## and a sword embedded there reaches the metal on both sides of it, so it
## bridges. If M14 retunes the hero's height or the blade, this says so.
extends TestCase

const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"


func test_the_seam_is_at_throw_height() -> void:
	var world: WorldConfig = load(WORLD)
	var throw_y := Bench.FLOOR_TOP - world.hero_height * 0.5
	var seam := RoomM12Circuit.seam_y()
	check(throw_y >= seam and throw_y <= seam + RoomM12Circuit.SEAM_HEIGHT, "a standing throw flies down the seam")


func test_a_sword_in_the_seam_reaches_both_sides() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var throw_y := Bench.FLOOR_TOP - world.hero_height * 0.5
	var half := Sword.LEDGE_THICKNESS * 0.5 + sword.conduct_reach
	check(throw_y - half < RoomM12Circuit.live_piece().end.y, "it touches the live piece above")
	check(throw_y + half > RoomM12Circuit.stub().position.y, "and the stub below")
