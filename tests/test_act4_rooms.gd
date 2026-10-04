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


func test_the_throne_seam_is_thrown_from_the_floor() -> void:
	var sword: SwordConfig = load(SWORD)
	var half := Sword.LEDGE_THICKNESS * 0.5 + sword.conduct_reach
	var y := Act4Room.throw_y(Bench.FLOOR_TOP)
	check(y - half < Act4Throne.live_copper().end.y and y + half > Act4Throne.stub().position.y, "a floor throw lands across the dais seam")
	check(Act4Throne.FACE_X - Act4Throne.LIP_X == Act4Throne.RECESS, "the live face sits back under the dais lip")


func test_the_throne_rail_needs_every_gem() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var move: MovementConfig = load(MOVE)
	var rail := Act4Throne.rail()
	check_eq(rail.size(), 4, "three breaks make four pieces")
	for i in rail.size() - 1:
		var gap := rail[i + 1].position.x - rail[i].end.x
		check(gap > world.sword_length + sword.conduct_reach * 2.0, "break %d is too wide for a sword" % i)
		var centre := Act4Throne.pedestal(i).get_center().x
		check(centre > rail[i].end.x and centre < rail[i + 1].position.x, "pedestal %d stands under its break" % i)
	check(Act4Throne.RAIL_Y + Act4Throne.RAIL_HEIGHT < Bench.FLOOR_TOP - move.jump_height - world.hero_height, "the rail is out of reach")


func test_the_throne_third_gem_is_cut_from_the_gallery() -> void:
	var sword: SwordConfig = load(SWORD)
	var y := Act4Room.throw_y(Act4Throne.GALLERY.position.y)
	check(y > Act4Throne.SHELF.position.y and y < Act4Throne.SHELF.end.y, "a gallery throw flies through the shelf")
	check(Act4Throne.SHELF.position.x - Act4Throne.GALLERY.end.x < sword.max_range, "in range")
	check(Act4Throne.SHELF.position.x < Act4Throne.VOLTA_WAKES_X, "and Volta wakes only once you are past it")


func test_volta_is_out_of_reach() -> void:
	var move: MovementConfig = load(MOVE)
	var sword: SwordConfig = load(SWORD)
	check(Bench.FLOOR_TOP - Act4Throne.DAIS_TOP > move.jump_height, "the dais cannot be jumped")
	check(Act4Throne.VOLTA_AT.x - Act4Throne.LIP_X > sword.max_range * 0.5, "and he stands well back from its lip")
