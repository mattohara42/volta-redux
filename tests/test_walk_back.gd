## `WalkBack`, on rooms small enough to see in your head. The claims: a drop
## deeper than the jump strands you unless a ladder serves it, a step the jump
## clears does not, a sword ledge takes you forward and never home, lava is
## never somewhere to stand, and a room the model cannot cross says so.
extends TestCase

const MOVEMENT: MovementConfig = preload("res://config/movement.tres")
const WORLD: WorldConfig = preload("res://config/world.tres")
const SWORD: SwordConfig = preload("res://config/sword.tres")

const WIDTH: float = 640.0
const FLOOR: float = 320.0


func _moves() -> WalkBack.Moves:
	var moves := WalkBack.Moves.new()
	moves.jump_height = MOVEMENT.jump_height
	moves.time_to_apex = MOVEMENT.time_to_apex
	moves.fall_multiplier = MOVEMENT.fall_gravity_multiplier
	moves.run_speed = MOVEMENT.max_run_speed
	moves.max_fall_speed = MOVEMENT.max_fall_speed
	moves.hero_width = WORLD.hero_width
	moves.hero_height = WORLD.hero_height
	moves.sword_range = SWORD.max_range
	moves.sword_length = WORLD.sword_length
	return moves


## A room whose left half stands `step` px above its right half, with walls,
## the hero starting on the left and the exit on the right.
func _stepped(step: float) -> WalkBack.Layout:
	var layout := WalkBack.Layout.new()
	layout.solids = [
		Rect2(0.0, FLOOR - step, 320.0, 360.0 - FLOOR + step),
		Rect2(320.0, FLOOR, WIDTH - 320.0, 360.0 - FLOOR),
		Rect2(-24.0, 0.0, 24.0, 360.0),
		Rect2(WIDTH, 0.0, 24.0, 360.0),
	]
	layout.start = Vector2(40.0, FLOOR - step)
	layout.exit = Rect2(600.0, FLOOR - 48.0, 8.0, 48.0)
	return layout


func test_a_drop_deeper_than_the_jump_strands_you() -> void:
	var report := WalkBack.check(_stepped(MOVEMENT.jump_height + 8.0), _moves())
	check(report.start_found, "the hero starts on the upper level")
	check(report.exit_reached, "the drop takes you to the exit")
	check_eq(report.stranded.size(), 1, "the lower level has no way back")


func test_a_step_the_jump_clears_does_not() -> void:
	var report := WalkBack.check(_stepped(MOVEMENT.jump_height - 16.0), _moves())
	check(report.exit_reached, "the step down takes you to the exit")
	check_eq(report.stranded.size(), 0, "and a jump takes you back up")


func test_a_ladder_is_a_way_back() -> void:
	var step := MOVEMENT.jump_height + 40.0
	var layout := _stepped(step)
	layout.ladders = [Rect2(320.0, FLOOR - step - 28.0, 16.0, step + 28.0)]
	var report := WalkBack.check(layout, _moves())
	check_eq(report.stranded.size(), 0, "the ladder at the foot of the drop serves the top")


## A tall wooden wall in the middle of a flat room: a sword thrown into it is
## the only way over, and coming back over it would need another.
func test_a_sword_ledge_goes_forward_and_never_home() -> void:
	var layout := _stepped(0.0)
	var wall := Rect2(300.0, FLOOR - 100.0, 24.0, 100.0)
	layout.solids.append(wall)
	layout.embeddable = [wall]
	var report := WalkBack.check(layout, _moves())
	check(report.exit_reached, "a ledge in the wood gets you over")
	check_eq(report.stranded.size(), 1, "and the far side has no way home without one")
	layout.embeddable = []
	check(not WalkBack.check(layout, _moves()).exit_reached, "stone gives no ledge, so the exit is out of reach")


func test_lava_is_never_somewhere_to_stand() -> void:
	var layout := _stepped(0.0)
	var pit := Rect2(200.0, FLOOR - 1.0, 40.0, 360.0 - FLOOR)
	layout.deadly = [pit]
	var surfaces := WalkBack.surfaces_of(layout.solids, layout.deadly, WORLD.hero_height)
	for surface in surfaces:
		check(surface.end.x <= pit.position.x or surface.position.x >= pit.end.x,
			"no surface runs under the lava (%s)" % surface)


func test_a_low_ceiling_is_not_somewhere_to_stand() -> void:
	var solids: Array[Rect2] = [
		Rect2(0.0, FLOOR, WIDTH, 40.0),
		Rect2(100.0, FLOOR - WORLD.hero_height + 4.0, 100.0, 8.0),
	]
	var surfaces := WalkBack.surfaces_of(solids, [], WORLD.hero_height)
	for surface in surfaces:
		if is_equal_approx(surface.position.y, FLOOR):
			check(surface.end.x <= 100.0 or surface.position.x >= 200.0,
				"the floor under a slab too low to stand under is not a surface")


## A barrier from floor to ceiling cuts a room in two. Stepping off the end of
## the floor it cuts used to "land" on the far side before the arc checked for
## death, which let the rungs room's floor cross its barrier.
func test_nothing_crosses_a_barrier() -> void:
	var layout := _stepped(0.0)
	layout.deadly = [Rect2(400.0, 0.0, 6.0, FLOOR)]
	var report := WalkBack.check(layout, _moves())
	check(not report.exit_reached, "the exit beyond the barrier is out of reach")
