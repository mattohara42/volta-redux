## Act 4's first two rooms, as arithmetic.
extends TestCase

const WORLD := "res://config/world.tres"
const MOVE := "res://config/movement.tres"
const SWORD := "res://config/sword.tres"


func _rung_top(stand: float) -> float:
	return Act4Room.throw_y(stand) - Sword.LEDGE_THICKNESS * 0.5


func test_the_gallery_is_one_sword_up() -> void:
	var move: MovementConfig = load(MOVE)
	var g := Act4Gallery.GALLERY
	var crate := Act4Gallery.CRATE
	check(Bench.FLOOR_TOP - g.position.y > move.jump_height, "the gallery cannot be jumped from the floor")
	check(crate.position.y - g.position.y > move.jump_height, "nor from the crate")
	check(_rung_top(crate.position.y) - g.position.y < move.jump_height, "a sword thrown from the crate is the step up")
	check(Bench.FLOOR_TOP - crate.position.y < move.jump_height, "and the crate is a jump up")


func test_the_shelf_is_cut_from_the_gallery_only() -> void:
	var world: WorldConfig = load(WORLD)
	var move: MovementConfig = load(MOVE)
	var sword: SwordConfig = load(SWORD)
	var shelf := Act4Gallery.SHELF
	var from_gallery := Act4Room.throw_y(Act4Gallery.GALLERY.position.y)
	check(from_gallery > shelf.position.y and from_gallery < shelf.end.y, "a throw from the gallery flies through the shelf")
	for stand in [Bench.FLOOR_TOP, Act4Gallery.CRATE.position.y]:
		var y := Act4Room.throw_y(stand)
		check(y > shelf.end.y, "a throw from %.0f passes under it" % stand)
	check(shelf.position.x - Act4Gallery.GALLERY.end.x < sword.max_range, "the shelf is in range from the gallery's edge")
	var reach := Bench.FLOOR_TOP - world.hero_height - move.jump_height
	check(shelf.position.y - Gem.SIZE.y < reach and shelf.position.y < reach, "the gem on it is above any jump from the floor")


func test_the_guard_step_kills_from_above() -> void:
	var world: WorldConfig = load(WORLD)
	var move: MovementConfig = load(MOVE)
	check(Act4Guard.STEP_DROP >= 5.0 and Act4Guard.STEP_DROP <= 16.0, "the step sits in Act1Wall's from-above band")
	check(Act4Guard.TUNNEL_CLEARANCE < world.hero_height + move.jump_height, "the scorpion cannot be jumped in the passage")
	var sword: SwordConfig = load(SWORD)
	var near_side := Act4Guard.GUARD_HOME_X - Act4Guard.SCORPION_SIZE.x * 0.5
	check(near_side > Act4Guard.STEP_END + world.hero_width, "its patrol never reaches the step")
	check(near_side - Act4Guard.STEP_END < sword.max_range, "but its near end is in range of a throw from it")
	check(Act4Guard.GUARD_HOME_X + Act4Guard.GUARD_RANGE < Act4Guard.PASSAGE.end.x, "and it stays under the roof")
