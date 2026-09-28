## Act 1's first room, as arithmetic. Its claim is that the only way through each
## tunnel is a sword in a scorpion's back, that there is always somewhere safe to
## stand and wait for that back to turn, and that nothing here teaches a later
## room's trick by accident. Every number it rests on lives in `config/`.
extends TestCase

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const ENEMIES := "res://config/enemies.tres"
const SWORD := "res://config/sword.tres"


func _tunnels() -> Array[Rect2]:
	return [Act1Bank.CULVERT, Act1Bank.SALLY_PORT]


func _patrols() -> Array[Vector2]:
	# (home x, range), one per tunnel and in the same order.
	return [
		Vector2(Act1Bank.SLEEPER_HOME_X, Act1Bank.SLEEPER_RANGE),
		Vector2(Act1Bank.GUARD_HOME_X, Act1Bank.GUARD_RANGE),
	]


func test_a_tunnel_fits_the_hero_but_not_a_jump_over_a_scorpion() -> void:
	var world: WorldConfig = load(WORLD)
	for tunnel in _tunnels():
		var headroom := Bench.FLOOR_TOP - tunnel.end.y
		check(headroom > world.hero_height, "%.0f px of headroom fits a %.0f px hero" % [headroom, world.hero_height])
		check(
			headroom < world.hero_height + Act1Bank.SCORPION_SIZE.y,
			"and is less than the %.0f px it takes to jump a scorpion"
				% (world.hero_height + Act1Bank.SCORPION_SIZE.y)
		)


## The mouth is the safe place to stand. A patrol that reached out of its tunnel
## would take it away.
func test_each_patrol_stays_inside_its_tunnel() -> void:
	var tunnels := _tunnels()
	var patrols := _patrols()
	var half := Act1Bank.SCORPION_SIZE.x * 0.5
	for i in tunnels.size():
		var near := patrols[i].x - half
		var far := patrols[i].x + patrols[i].y + half
		check(near >= tunnels[i].position.x, "patrol %d starts inside its tunnel (%.0f >= %.0f)" % [i, near, tunnels[i].position.x])
		check(far <= tunnels[i].end.x, "patrol %d ends inside its tunnel (%.0f <= %.0f)" % [i, far, tunnels[i].end.x])


## Standing at the mouth, a throw reaches the nearest the scorpion ever comes.
func test_a_throw_from_the_mouth_reaches_the_scorpion() -> void:
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var tunnels := _tunnels()
	var patrols := _patrols()
	for i in tunnels.size():
		var from := tunnels[i].position.x - world.hero_width * 0.5
		var near := patrols[i].x - Act1Bank.SCORPION_SIZE.x * 0.5
		check(from + sword.max_range >= near, "tunnel %d: a throw from %.0f reaches %.0f" % [i, from, near])


## The sleeper faces away from the hero walking in from the left, so the back
## is what the first throw meets.
func test_the_sleeper_has_its_back_to_the_way_in() -> void:
	var enemies: EnemyConfig = load(ENEMIES)
	check_eq(
		ScorpionPatrol.facing_at(0.0, Act1Bank.SLEEPER_RANGE, enemies.scorpion_speed), 1.0,
		"at rest it faces right, away from the left-hand approach"
	)
	check(
		enemies.dormant_wake_range > (Act1Bank.SCORPION_SIZE.x + load(WORLD).hero_width) * 0.5,
		"and it wakes before the hero can walk into it"
	)


## A standing throw meets a scorpion's side, not its top, so the armour decides
## and this room teaches the armour rather than the from-above trick.
func test_a_standing_throw_meets_the_armour_and_not_the_top() -> void:
	var world: WorldConfig = load(WORLD)
	var enemies: EnemyConfig = load(ENEMIES)
	var half_height := Act1Bank.SCORPION_SIZE.y * 0.5
	var sword_y := Bench.FLOOR_TOP - world.hero_height * 0.5
	var offset := Vector2(-10.0, sword_y - (Bench.FLOOR_TOP - half_height))
	check(
		not ScorpionPatrol.is_vulnerable_to(offset, -1.0, half_height, enemies.scorpion_armor_top_fraction),
		"a standing throw into its face is stopped by the armour"
	)
	check(
		ScorpionPatrol.is_vulnerable_to(offset, 1.0, half_height, enemies.scorpion_armor_top_fraction),
		"and the same throw into its back gets through"
	)


func test_the_bank_is_safe_to_throw_from() -> void:
	var move: MovementConfig = load(MOVE)
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	check(Act1Bank.PLINTH.size.y <= move.jump_height, "the plinth can be jumped onto")
	var furthest := Act1Bank.PLINTH.end.x + world.hero_width * 0.5 + sword.max_range
	check(
		furthest < Act1Bank.CULVERT.position.x,
		"a throw from the plinth turns at %.0f, before the culvert's face at %.0f"
			% [furthest, Act1Bank.CULVERT.position.x]
	)


func test_the_ditch_is_a_retry_not_a_trap() -> void:
	var move: MovementConfig = load(MOVE)
	check(Act1Bank.DITCH.size.y < move.jump_height, "the ditch is shallower than a jump")


func test_the_checkpoint_sits_between_the_tunnels() -> void:
	check(
		Act1Bank.CHECKPOINT_X > Act1Bank.CULVERT.end.x and Act1Bank.CHECKPOINT_X < Act1Bank.DITCH.position.x,
		"lit after the culvert, before the ditch and the sally port"
	)
