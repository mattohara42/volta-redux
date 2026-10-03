## M2's first room, as arithmetic.
##
## The room's whole claim is that it **cannot be finished without standing on
## your own thrown sword**, and that claim is a function of numbers in
## `config/`. `DitchChecks` holds it, for this room and every other built on the
## same crossing. If M14 retunes the jump and this goes red, the room needs
## rebuilding and the number is not wrong.
extends TestCase


func test_the_ditch_needs_the_sword() -> void:
	DitchChecks.run(
		self, "RoomM2Gap", RoomM2Gap.NEAR_EDGE, Bench.FLOOR_TOP,
		RoomM2Gap.FAR_TOP, RoomM2Gap.HOARDING, RoomM2Gap.PIT_TOP
	)
