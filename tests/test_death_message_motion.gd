## How the death line flies in, punches, settles and flies out.
##
## These hold the shape of the motion and the pixel rule it lives under. Whether
## it feels like an arrival is Matt's to answer by playing.
extends TestCase

const DEATH := "res://config/death.tres"

const TOTAL := 2.0
const IN := 0.2
const SETTLE := 0.2
const OUT := 0.4
const FROM := 0.5
const PUNCH := 1.5
const EXIT := 3.0
const STEP := 0.5


func _scale(elapsed: float) -> float:
	return DeathMessageMotion.scale_at(elapsed, TOTAL, IN, SETTLE, OUT, FROM, PUNCH, EXIT, STEP)


func _alpha(elapsed: float) -> float:
	return DeathMessageMotion.alpha_at(elapsed, TOTAL, IN, OUT)


func test_it_starts_small_and_faint() -> void:
	check_eq(_scale(0.0), FROM, "it arrives from the background")
	check_eq(_alpha(0.0), 0.0, "and invisible")


func test_it_overshoots_then_rests_at_one() -> void:
	check_eq(_scale(IN), PUNCH, "the punch is reached at the end of the fly-in")
	check_eq(_scale(IN + SETTLE), 1.0, "settled once the settle is done")
	check_eq(_scale(1.0), 1.0, "and read at its own size")
	check_eq(_alpha(1.0), 1.0, "fully opaque while read")


func test_it_grows_toward_the_camera_as_it_fades() -> void:
	var before := _scale(TOTAL - OUT * 0.5)
	var after := _scale(TOTAL - 0.001)
	check(after > before and before >= 1.0, "%.1f then %.1f: still coming toward you" % [before, after])
	check_eq(after, EXIT, "and at the exit size as it goes")
	check(_alpha(TOTAL - OUT * 0.5) < 1.0, "fading on the way out")
	check_eq(_alpha(TOTAL), 0.0, "gone at the end")


func test_every_scale_keeps_the_font_pixels_whole() -> void:
	var t := 0.0
	while t <= TOTAL:
		var s := _scale(t)
		check_near(fmod(s, STEP), 0.0, 0.0001, "%.3f s: scale %.3f is a multiple of %.1f" % [t, s, STEP])
		check(s >= STEP, "%.3f s: scale %.3f never rounds to nothing" % [t, s])
		t += 1.0 / 120.0


func test_a_message_too_short_for_every_beat_still_leaves() -> void:
	var s := DeathMessageMotion.scale_at(0.25, 0.3, IN, SETTLE, OUT, FROM, PUNCH, EXIT, STEP)
	check(s >= 1.0, "the exit wins over the settle")
	check(DeathMessageMotion.alpha_at(0.29, 0.3, IN, OUT) < 0.2, "and it is nearly gone")


## The tuning file's beats fit inside the message, and its scales sit on the
## grid the font's 20 px set (`ART_DIRECTION.md`, *Lettering*).
func test_the_tuning_file_fits() -> void:
	var c: DeathConfig = load(DEATH)
	check(
		c.message_fly_in + c.message_settle + c.message_fade_out <= c.message_seconds,
		"fly-in, settle and fade fit in %.2f s" % c.message_seconds
	)
	check(c.message_scale_from < 1.0, "it flies in from smaller than it is read")
	check(c.message_scale_punch > 1.0, "the punch is bigger than reading size")
	check(c.message_scale_exit > 1.0, "it leaves toward the camera")
	var step := float(Lettering.GRID) / float(c.message_font_size)
	for s: float in [c.message_scale_from, c.message_scale_punch, c.message_scale_exit]:
		check_near(fmod(s, step), 0.0, 0.0001, "%.2f is on the font's %.2f grid" % [s, step])
