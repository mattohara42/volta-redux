## The gem bench as arithmetic: a sword cannot do a gem's job, the rail is out
## of reach, and every pedestal can be jumped.
extends TestCase


func test_no_sword_can_bridge_a_break() -> void:
	var world: WorldConfig = load("res://config/world.tres")
	var sword: SwordConfig = load("res://config/sword.tres")
	check(RoomM13Gems.BREAK > world.sword_length + sword.conduct_reach * 2.0, "a break is wider than a sword's reach across it")


func test_the_rail_is_out_of_reach() -> void:
	var world: WorldConfig = load("res://config/world.tres")
	var move: MovementConfig = load("res://config/movement.tres")
	var highest_head := Bench.FLOOR_TOP - move.jump_height - world.hero_height
	check(RoomM13Gems.RAIL_Y + RoomM13Gems.RAIL_HEIGHT < highest_head, "the hero's head at the top of a jump stays under the live rail")


func test_the_pedestals_can_be_jumped() -> void:
	var move: MovementConfig = load("res://config/movement.tres")
	check(RoomM13Gems.PEDESTAL.y < move.jump_height, "a pedestal is a step, not a wall")


func test_three_gems_close_the_rail() -> void:
	var links: Array = []
	for i in 3:
		check(not Circuit.connected(0, 3, links), "with %d gems set the switch is dead" % i)
		links.append([i, i + 1])
	check(Circuit.connected(0, 3, links), "with three it is live")
