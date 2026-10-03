## Act 2's causeway, as arithmetic. The crossing itself is `RoomM3Falling`'s and
## its tests hold it. These hold what this room adds: the bat really threatens
## the second crossing, a throw from the island can reach it, and the island
## stays somewhere safe to stand and decide.
extends TestCase

const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"


func _bat_reach() -> Rect2:
	var half := Act2Causeway.BAT_HALF_EXTENTS + Act2Causeway.BAT_SIZE * 0.5
	return Rect2(Act2Causeway.BAT_CENTRE - half, half * 2.0)


func test_the_bat_works_the_air_over_the_second_crossing() -> void:
	var world: WorldConfig = load(WORLD)
	var reach := _bat_reach()
	var slabs := RoomM3Falling.second_crossing()
	check(reach.position.x < slabs[1].end.x and reach.end.x > slabs[1].position.x, "it roams over the middle slab")
	var body := Rect2(0.0, Bench.FLOOR_TOP - world.hero_height, 1.0, world.hero_height)
	check(reach.position.y < body.end.y and reach.end.y > body.position.y, "at the height of a hero standing on a slab")


func test_the_island_stays_safe() -> void:
	check(_bat_reach().position.x > RoomM3Falling.ISLAND_END, "it never reaches back over the island")


func test_a_throw_from_the_island_reaches_the_bat() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var lip := RoomM3Falling.ISLAND_END - world.hero_width * 0.5
	check(lip + sword.max_range > Act2Causeway.BAT_CENTRE.x, "the throw passes its centre")
	var throw_y := Bench.FLOOR_TOP - world.hero_height * 0.5
	var reach := _bat_reach()
	check(throw_y > reach.position.y and throw_y < reach.end.y, "at a height it flies through")
