## The breath leaves the dragon's mouth: a room says how far it reaches, and the
## dragon pulls the near edge of the kill box back to its snout, so there is no
## empty block between the face and the fire.
extends TestCase

const ENEMIES := "res://config/enemies.tres"


func _placed(offset: Vector2, size: Vector2) -> Dragon:
	var config := load(ENEMIES) as EnemyConfig
	var dragon := Dragon.new()
	dragon.place(Vector2(56.0, 48.0), offset, size, config)
	return dragon


func _near_and_far(dragon: Dragon) -> Vector2:
	var area: Area2D
	for child in dragon.get_children():
		if child is Area2D:
			area = child
	var half := ((area.get_child(0) as CollisionShape2D).shape as RectangleShape2D).size.x * 0.5
	return Vector2(absf(area.position.x) - half, absf(area.position.x) + half)


func test_the_box_starts_at_the_snout_and_keeps_the_rooms_far_edge() -> void:
	var reach := (load(ENEMIES) as EnemyConfig).dragon_snout_reach
	var dragon := _placed(Vector2(-150.0, 10.0), Vector2(90.0, 30.0))
	var edges := _near_and_far(dragon)
	dragon.free()
	check_near(edges.x, reach, 0.001, "near edge at the snout")
	check_near(edges.y, 195.0, 0.001, "far edge where the room put it")


func test_it_works_facing_right_too() -> void:
	var reach := (load(ENEMIES) as EnemyConfig).dragon_snout_reach
	var dragon := _placed(Vector2(150.0, 10.0), Vector2(90.0, 30.0))
	var edges := _near_and_far(dragon)
	dragon.free()
	check_near(edges.x, reach, 0.001, "near edge at the snout")
	check_near(edges.y, 195.0, 0.001, "far edge where the room put it")
