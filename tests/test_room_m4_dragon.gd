## The dragon bench, as arithmetic: the one legitimate shot has to be
## physically possible before anyone can be asked to find it by playing.
extends TestCase


func _climb() -> MovementConfig:
	return load("res://config/movement.tres")


func _strong() -> MovementConfig:
	return load("res://config/movement_strong.tres")


func _world() -> WorldConfig:
	return load("res://config/world.tres")


func _sword() -> SwordConfig:
	return load("res://config/sword.tres")


func test_the_ledge_is_climbable_by_both_presets() -> void:
	var rise := RoomM4Dragon.FLOOR_TOP - RoomM4Dragon.LEDGE.position.y
	check(rise < _climb().jump_height, "the ledge's %.0f px rise should clear the climb preset's jump" % rise)
	check(rise < _strong().jump_height, "and the strong preset's")


## A throw off the ledge is flat at the height the hero is standing, so it
## has to leave from above the dragon's own box or it never reaches the wood
## at all: `Sword._on_area_entered` would stop it on the dragon's body first.
func test_a_throw_from_the_ledge_clears_the_dragons_body() -> void:
	var throw_height := RoomM4Dragon.LEDGE.position.y - _world().hero_height * 0.5
	var dragon_top := RoomM4Dragon.FLOOR_TOP - RoomM4Dragon.DRAGON_SIZE.y
	check(
		throw_height < dragon_top,
		"a throw from the ledge (y=%.0f) should be above the dragon's box (top y=%.0f)" % [
			throw_height, dragon_top
		]
	)


func test_the_wood_is_within_a_throw_from_the_ledge() -> void:
	var throw_x := RoomM4Dragon.LEDGE.end.x
	var distance := RoomM4Dragon.WOOD.position.x - throw_x
	check(
		distance > 0.0 and distance < _sword().max_range,
		"the wood should be a reachable throw (%.0f px) from the near edge of the ledge" % distance
	)


func test_the_wood_sits_past_the_dragon_not_before_it() -> void:
	check(
		RoomM4Dragon.WOOD.position.x > RoomM4Dragon.DRAGON_X,
		"the wood should be on the far side of the dragon from the ledge"
	)


## A recall from the wood has to be able to reach a hero standing well clear
## of the dragon's body, or the only way to trigger it is to already be
## standing somewhere the dragon's own touch would kill.
func test_a_recall_from_the_wood_can_reach_past_the_dragon() -> void:
	var wood_x := RoomM4Dragon.WOOD.position.x
	var clear_of_dragon := RoomM4Dragon.DRAGON_X - RoomM4Dragon.DRAGON_SIZE.x * 0.5 - 20.0
	check(
		wood_x - clear_of_dragon < _sword().max_return_distance,
		"a recall from the wood should reach a hero standing clear of the dragon"
	)
