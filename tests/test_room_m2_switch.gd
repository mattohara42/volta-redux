## M2's second room, as arithmetic.
##
## Its claim is that recall is the **only** way to finish it, and that claim
## rests on three things that are not the room's to own: the sword count, the
## rule that an embedded sword cannot be picked up by walking, and the same
## jump numbers the first room depends on. Any of them can move.
extends TestCase


## One sword, and that is the whole puzzle. Two and you spend one on the switch
## and one on the gap, and never find out what recall is for.
func test_the_room_hands_out_exactly_one_sword() -> void:
	check_eq(RoomM2Switch.SWORDS_HANDED_OUT, 1, "the room hands out one sword")
	var sword: SwordConfig = load("res://config/sword.tres")
	check(
		sword.starting_swords > RoomM2Switch.SWORDS_HANDED_OUT,
		"and that is fewer than the %d the game normally gives you, so the room means it"
			% sword.starting_swords
	)


## The two rules that make the recall unavoidable. If either flips, the sword
## can be retrieved another way and the room proves nothing.
func test_an_embedded_sword_can_only_come_back_by_recall() -> void:
	check_eq(
		SwordFlight.next_state(
			SwordFlight.State.EMBEDDED, false, false, false, true,
			SwordFlight.Contact.NONE, false, false, false
		),
		SwordFlight.State.EMBEDDED,
		"walking over an embedded sword does not pick it up"
	)
	check_eq(
		SwordFlight.next_state(
			SwordFlight.State.EMBEDDED, false, false, false, false,
			SwordFlight.Contact.NONE, false, false, true
		),
		SwordFlight.State.RECALLING,
		"only a recall moves it"
	)
	check(
		SwordFlight.holds_a_switch(SwordFlight.State.EMBEDDED),
		"an embedded sword holds the switch"
	)
	check(
		not SwordFlight.holds_a_switch(SwordFlight.State.GROUNDED),
		"one lying on the floor does not, so a dropped sword cannot prop the gate"
	)


## The gate has to be the only way through, or the switch is decoration.
func test_the_gate_cannot_be_gone_over() -> void:
	var move: MovementConfig = load("res://config/movement.tres")
	var height := Bench.FLOOR_TOP - RoomM2Switch.GATE.position.y
	check(
		height > move.jump_height,
		"the gate stands %.0f px against a %.0f px jump" % [height, move.jump_height]
	)


## A standing throw has to meet the switch, or the sword sails under it.
func test_a_floor_level_throw_meets_the_switch() -> void:
	var world: WorldConfig = load("res://config/world.tres")
	var throw_height := Bench.FLOOR_TOP - world.hero_height * 0.5
	check(
		throw_height >= RoomM2Switch.SWITCH.position.y
			and throw_height <= RoomM2Switch.SWITCH.end.y,
		"a throw at y %.0f meets the switch's %.0f to %.0f" % [
			throw_height, RoomM2Switch.SWITCH.position.y, RoomM2Switch.SWITCH.end.y
		]
	)


## An embedded sword sits a half blade clear of the face it bit, and the switch
## only reads swords inside its own reach. Those two numbers have to agree or
## the gate never opens.
func test_the_embedded_sword_lands_inside_the_switch() -> void:
	var world: WorldConfig = load("res://config/world.tres")
	# The switch is in the left wall, so the throw goes left into its right face.
	var sword_x := SwordFlight.embed_position(
		RoomM2Switch.SWITCH.end.x, -1.0, world.sword_length
	)
	var sensed := RoomM2Switch.SWITCH.grow(SwordSwitch.REACH)
	check(
		sword_x <= sensed.end.x,
		"the sword settles at %.0f and the switch senses out to %.0f" % [
			sword_x, sensed.end.x
		]
	)
	# And the ledge it makes has to be clear of the wall, or it is inside stone.
	check(
		sword_x - world.sword_length * 0.5 >= RoomM2Switch.SWITCH.end.x,
		"its ledge starts at %.0f, clear of the wall face at %.0f" % [
			sword_x - world.sword_length * 0.5, RoomM2Switch.SWITCH.end.x
		]
	)


## The crossing beyond the gate, on the same terms as M2's first room.
func test_the_ditch_beyond_the_gate_needs_the_sword() -> void:
	DitchChecks.run(
		self, "RoomM2Switch", RoomM2Switch.NEAR_EDGE, Bench.FLOOR_TOP,
		RoomM2Switch.FAR_TOP, RoomM2Switch.HOARDING, RoomM2Switch.PIT_TOP
	)
