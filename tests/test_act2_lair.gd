## Act 2's lair, as arithmetic. The fight is `RoomM4Dragon`'s and its tests hold
## it; these hold what the lair changes. A throw from the ledge still clears the
## dragon and meets the timber, the timber is in range, there is room to walk
## under it once the dragon is chained, and only one sword is handed out.
extends TestCase

const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"


func test_a_throw_from_the_ledge_clears_the_dragon_and_meets_the_timber() -> void:
	var world: WorldConfig = load(WORLD)
	var y := Act2Lair.LEDGE.position.y - world.hero_height * 0.5
	check(y < Bench.FLOOR_TOP - Act2Lair.DRAGON_SIZE.y, "it passes over the dragon's back")
	check(y > Act2Lair.TIMBER.position.y and y < Act2Lair.TIMBER.end.y, "and bites the timber")


func test_the_timber_is_in_range_from_the_ledge() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var from := Act2Lair.LEDGE.end.x - world.hero_width * 0.5
	check(Act2Lair.TIMBER.position.x - from < sword.max_range, "within one throw")


func test_there_is_room_to_walk_under_the_timber() -> void:
	var world: WorldConfig = load(WORLD)
	check(Bench.FLOOR_TOP - Act2Lair.TIMBER.end.y > world.hero_height, "a standing hero fits under it")


func test_one_sword_proves_the_fight_costs_none() -> void:
	check_eq(Act2Lair.SWORDS_HANDED_OUT, 1, "with one, the only throw is the one that has to come home")
