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
	var xs: Array[float] = []
	for point in (area.get_child(0) as CollisionPolygon2D).polygon:
		xs.append(absf(area.position.x + point.x))
	return Vector2(xs.min(), xs.max())


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


## `SPEC.md`: a telegraphed cone. It leaves the jaws at head height, the top
## of the box, and spreads down to the floor by a third of its reach.
func test_the_breath_is_a_cone_from_the_jaws_to_the_floor() -> void:
	var cone := DragonBreath.cone(100.0, 30.0, 0.5, 0.35, 1.0)
	var jaws_bottom := -INF
	var far_bottom := -INF
	var top := INF
	for point in cone:
		if is_zero_approx(point.x):
			jaws_bottom = maxf(jaws_bottom, point.y)
		if point.x >= 35.0:
			far_bottom = maxf(far_bottom, point.y)
		top = minf(top, point.y)
	check_near(top, -15.0, 0.001, "its top is the box's top, the jaws' height")
	check_near(jaws_bottom, 0.0, 0.001, "at the jaws only the top half burns")
	check_near(far_bottom, 15.0, 0.001, "and it reaches the floor past a third of its reach")
	check_near(DragonBreath.cone_gap(0.0, 0.5, 0.35), 0.5, 0.001, "the shader's edge at the jaws")
	check_near(DragonBreath.cone_gap(0.35, 0.5, 0.35), 0.0, 0.001, "and where it opens")
