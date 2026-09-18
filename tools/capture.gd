## Takes a screenshot of a scene from a real running build.
##
## CLAUDE.md: an assertion proves the code ran, not that the picture is right,
## so draw the thing you measured. This is how that gets done in Godot without
## a human at a keyboard, and it is what CI and a headless session use to look
## at the game.
##
## Needs a display. Headless gives you a dummy renderer and a blank image, so
## run it under Xvfb:
##
##   xvfb-run -a godot --path . --script res://tools/capture.gd -- \
##       --scene=res://scenes/rooms/room_m0.tscn --out=shot.png \
##       --input="move_right:70;climb_up:80"
##
## `--input` is a sequence of phases, each naming every action held during it
## and how many frames it lasts. An action listed in one phase and not the next
## is released, so "move_right:70;climb_up:80" runs right and then climbs. What
## is still held after the last phase stays held, which is what `--until-apex`
## needs to measure a running jump.
##
## A phase named `-` holds nothing, which is how you wait for something the game
## is doing on its own: "move_left:10;throw:6;-:45" faces left, throws, and then
## lets go while the sword flies. Letting go matters, because an action held too
## long is a different action: a held throw is a recall.
##
## `--filmstrip=N` captures N frames spread evenly across the whole `--input`
## sequence (after the initial settle) and composites them into one wide strip
## image at `--out`, instead of the single end-of-run frame. This is how a
## transition gets reviewed as a sequence rather than a single still: PR #51's
## bug (a property floating across the idle/run crossfade) and PR #55's
## (jump, fall and land all reading as the same pose) were both found by Matt
## playing, because a single screenshot cannot show a blend in progress. Not
## combined with `--until-apex`, which is ignored when a filmstrip is asked
## for: a filmstrip already covers the arc the input describes.
##
## Writing over an existing file is the flag, not the default.
extends SceneTree

const SETTLE_FRAMES := 12
## The phase name that means "hold nothing".
const NOTHING_HELD := "-"

var _scene_path := ""
var _out_path := ""
var _phases: Array[Dictionary] = []
var _until_apex := false
var _overwrite := false
var _zoom := 0.0
var _centre := Vector2.INF
var _filmstrip_count := 0


func _initialize() -> void:
	_parse_arguments()
	if _scene_path.is_empty() or _out_path.is_empty():
		printerr("capture: --scene and --out are both required")
		quit(2)
		return
	if FileAccess.file_exists(_out_path) and not _overwrite:
		printerr("capture: %s exists. Pass --overwrite to replace it." % _out_path)
		quit(2)
		return

	var packed := load(_scene_path) as PackedScene
	if packed == null:
		printerr("capture: cannot load %s" % _scene_path)
		quit(2)
		return

	root.add_child(packed.instantiate())
	var agent := CaptureAgent.new()
	agent.configure(_out_path, _phases, _until_apex, _zoom, _centre, _filmstrip_count)
	root.add_child(agent)


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		var value := argument.get_slice("=", 1)
		if argument.begins_with("--scene="):
			_scene_path = value
		elif argument.begins_with("--out="):
			_out_path = value
		elif argument.begins_with("--input="):
			_phases = _parse_phases(value)
		elif argument.begins_with("--zoom="):
			_zoom = value.to_float()
		elif argument.begins_with("--centre="):
			var parts := value.split(",", false)
			if parts.size() == 2:
				_centre = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument == "--until-apex":
			_until_apex = true
		elif argument == "--overwrite":
			_overwrite = true
		elif argument.begins_with("--filmstrip="):
			_filmstrip_count = value.to_int()


## "move_right:70;climb_up:80" becomes two phases of held actions and durations.
func _parse_phases(text: String) -> Array[Dictionary]:
	var phases: Array[Dictionary] = []
	for chunk in text.split(";", false):
		var parts := chunk.split(":", false)
		if parts.size() != 2:
			printerr("capture: cannot read input phase \"%s\"" % chunk)
			continue
		# `-` is the empty controller, not an action called "-".
		var actions := PackedStringArray()
		if parts[0] != NOTHING_HELD:
			actions = parts[0].split(",", false)
		phases.append({
			"actions": actions,
			"frames": parts[1].to_int(),
		})
	return phases


## Runs inside the tree, because waiting for a drawn frame needs a node.
class CaptureAgent:
	extends Node

	var _out_path := ""
	var _phases: Array[Dictionary] = []
	var _held: PackedStringArray = []
	var _until_apex := false
	var _zoom := 0.0
	var _centre := Vector2.INF
	var _filmstrip_count := 0

	func configure(
		out_path: String, phases: Array[Dictionary], until_apex: bool, zoom: float,
		centre: Vector2, filmstrip_count: int
	) -> void:
		_out_path = out_path
		_phases = phases
		_until_apex = until_apex
		_zoom = zoom
		_centre = centre
		_filmstrip_count = filmstrip_count

	func _ready() -> void:
		if _zoom > 0.0 or _centre.is_finite():
			_pull_the_camera_back()
		await _wait(SETTLE_FRAMES)

		var frames: Array[Image] = []
		if _filmstrip_count > 0:
			frames = await _run_phases_capturing_filmstrip()
		else:
			for phase in _phases:
				_hold_exactly(phase["actions"])
				await _wait(phase["frames"])

		var player := get_tree().get_first_node_in_group("player")
		if _until_apex and _filmstrip_count <= 0 and player != null:
			# Held, not tapped. Releasing early is what variable jump height
			# means, and it produces a hop rather than the jump being measured.
			Input.action_press("jump")
			var guard := 0
			while player.velocity.y >= 0.0 and guard < 30:
				guard += 1
				await get_tree().physics_frame
			# The apex is the frame the sign of vertical velocity flips back.
			while player.velocity.y < 0.0 and guard < 240:
				guard += 1
				await get_tree().physics_frame
			Input.action_release("jump")

		if player != null:
			print("capture: player at %s, peak %.1f px, checkpoint %s, %d sword(s) held" % [
				player.global_position, player.peak_height, player.spawn_point, player.swords_held
			])
			_report_deaths(player)
		_report_swords()
		_report_braziers()
		_report_hazards()
		_report_platforms()
		_report_geysers()
		_report_enemies()
		_report_mechanisms()

		_hold_exactly(PackedStringArray())
		var error: int
		if _filmstrip_count > 0:
			error = _save_filmstrip(frames)
		else:
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			error = image.save_png(_out_path)
			if error == OK:
				print("capture: wrote %s at %dx%d" % [_out_path, image.get_width(), image.get_height()])
		if error != OK:
			printerr("capture: could not write %s (%d)" % [_out_path, error])
			get_tree().quit(1)
			return
		get_tree().quit(0)

	## Walks every phase one physics frame at a time, capturing a rendered
	## image at `_filmstrip_count` points spread evenly across the whole
	## sequence. Frame 0 (right after the settle) and the very last frame are
	## always included, so the strip always shows where the sequence started
	## and where it ended, not just the middle of it.
	func _run_phases_capturing_filmstrip() -> Array[Image]:
		var total := 0
		for phase in _phases:
			total += int(phase["frames"])
		var wanted := _spread(_filmstrip_count, total)

		var frames: Array[Image] = []
		var index := 0
		for phase in _phases:
			_hold_exactly(phase["actions"])
			for i in int(phase["frames"]):
				if wanted.has(index):
					frames.append(await _capture_frame())
				await get_tree().physics_frame
				index += 1
		# The loop above only ever captures a frame *before* a physics step, so
		# its last possible capture is the state before the sequence's final
		# step, one step short of the true end. This closes that gap: the
		# strip's last panel is always the sequence's actual end state, even
		# though that means one panel can sit very close to its neighbour when
		# `_filmstrip_count` already picked the second-to-last frame.
		frames.append(await _capture_frame())
		return frames

	## `count` indices, spread as evenly as integer rounding allows across
	## `[0, total - 1]`, always including both ends. `count` clamped to
	## `total`: asking for more panels than frames exist would just repeat some.
	func _spread(count: int, total: int) -> Dictionary:
		var picked: Dictionary = {}
		if total <= 0:
			return picked
		var n: int = maxi(1, mini(count, total))
		for i in n:
			var index: int = 0 if n <= 1 else roundi(float(i) * (total - 1) / float(n - 1))
			picked[index] = true
		return picked

	func _capture_frame() -> Image:
		await RenderingServer.frame_post_draw
		return get_viewport().get_texture().get_image()

	## Every captured frame laid side by side into one wide image, so a
	## transition is one file to open rather than several to flip between.
	func _save_filmstrip(frames: Array[Image]) -> int:
		if frames.is_empty():
			printerr("capture: filmstrip requested but no frames were captured")
			return ERR_INVALID_DATA
		var w := frames[0].get_width()
		var h := frames[0].get_height()
		var strip := Image.create(w * frames.size(), h, false, frames[0].get_format())
		for i in frames.size():
			strip.blit_rect(frames[i], Rect2i(Vector2i.ZERO, Vector2i(w, h)), Vector2i(w * i, 0))
		var error := strip.save_png(_out_path)
		if error == OK:
			print("capture: wrote a %d-frame filmstrip to %s at %dx%d" % [
				frames.size(), _out_path, strip.get_width(), strip.get_height()
			])
		return error

	## Whether the run died, and what the loop actually cost.
	##
	## BUILD_PLAN.md M3 budgets a second from death to moving again and
	## `test_death_clock.gd` holds `config/death.tres` to it, but that asserts
	## the intent. This is the figure a running build produced, which is the one
	## the done-when is about, and it is the only way a headless CI run can tell
	## that lava killed anybody at all.
	func _report_deaths(player: Player) -> void:
		if player.deaths == 0:
			print("capture: no deaths")
			return
		print("capture: %d death(s), last loop %.3f s, %s" % [
			player.deaths, player.last_downtime,
			DeathClock.phase_name(player.death_phase()),
		])


	## What every sword ended up doing, and where.
	##
	## The picture is the point of this tool, but a picture has to be looked at
	## by somebody, and CI runs when nobody is. These lines put the same facts
	## in the log: a throw that never embedded, or a ledge at the wrong x, is a
	## number here as well as a shape in the PNG.
	func _report_swords() -> void:
		var swords := get_tree().get_nodes_in_group("swords")
		if swords.is_empty():
			print("capture: no swords in play")
			return
		for node in swords:
			var sword := node as Sword
			if sword != null:
				print("capture: sword %s at %s" % [
					SwordFlight.state_name(sword.state), sword.global_position
				])


	## Whether the braziers are lit.
	##
	## The checkpoint on the player line says where a death would put you. This
	## says which brazier put it there, which is the only way to tell a brazier
	## that lit from a brazier whose sensing box the hero ran straight through.
	func _report_braziers() -> void:
		for node in get_tree().get_nodes_in_group("braziers"):
			var brazier := node as Brazier
			if brazier != null:
				print("capture: brazier at %s %s" % [
					brazier.global_position, "LIT" if brazier.is_lit else "dark"
				])


	## Where every hazard is and how big the box that kills actually is.
	##
	## A screenshot shows lava and it shows spikes, and in both cases it shows
	## the drawing rather than the box. For lava those are the same rectangle.
	## For a spike bed they are deliberately not: the box is half a tooth in
	## from each end and starts below the points, so the picture cannot tell you
	## whether the inset is the one that was intended. This line can.
	func _report_hazards() -> void:
		for node in get_tree().get_nodes_in_group("hazards"):
			var hazard := node as Hazard
			if hazard != null:
				print("capture: hazard at %s, killing box %s" % [
					hazard.global_position, hazard.killing_box
				])


	## What every platform is doing, and where it is.
	##
	## The mechanisms in M3 whose whole content is a clock. A screenshot of a
	## slab at home and a screenshot of a slab that is one frame from letting go
	## are the same picture, and so are a ferry that is running and a ferry that
	## is parked. "steady" in this log after a run that stood on a falling
	## platform, or the same ferry position twice, is what this line catches.
	func _report_platforms() -> void:
		for node in get_tree().get_nodes_in_group("platforms"):
			var platform := node as Platform
			if platform != null:
				print("capture: platform at %s %s" % [
					platform.global_position, platform.status()
				])


	## What every geyser is doing, where it is, and how big its lifting box is.
	##
	## Three things a picture cannot say. A jet that is not up is not drawn, so
	## the phase has to be printed or a run that never saw one and a run that
	## rode one look identical in a still. The box has to be printed for the
	## reason a spike bed's does: it is the part of the mechanism the player
	## meets and the drawing is only a claim about it. And a geyser is the one
	## mechanism whose failure is silence, because a vent that never erupts
	## leaves a perfectly good screenshot of a room nobody can leave.
	func _report_geysers() -> void:
		for node in get_tree().get_nodes_in_group("geysers"):
			var geyser := node as Geyser
			if geyser != null:
				print("capture: geyser at %s, column %s, %s" % [
					geyser.global_position, geyser.column(), geyser.status()
				])


	## Which enemies are still alive, and where. A killed one is `queue_free`d
	## rather than drawn dead, so a picture with fewer enemies in it and a log
	## with fewer lines in it are the same claim, and this is the one that a
	## grep can check.
	func _report_enemies() -> void:
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.is_empty():
			print("capture: no enemies remaining")
			return
		for node in enemies:
			var enemy := node as Enemy
			if enemy != null:
				print("capture: %s alive at %s" % [enemy.status(), enemy.global_position])


	## Whether the switches are held and the gates are open.
	##
	## A sword's position can be checked with arithmetic. Whether a switch
	## actually sensed it, and whether the gate that switch is wired to actually
	## opened, cannot: that is an Area2D overlap and a signal, and the only
	## honest way to know is to run it and look.
	func _report_mechanisms() -> void:
		for node in get_tree().get_nodes_in_group("switches"):
			var switch := node as SwordSwitch
			if switch != null:
				print("capture: switch at %s %s" % [
					switch.global_position, "HELD" if switch.is_held else "free"
				])
		for node in get_tree().get_nodes_in_group("plates"):
			var plate := node as FloorPlate
			if plate != null:
				print("capture: plate at %s %s" % [
					plate.global_position, "HELD" if plate.is_held else "free"
				])
		for node in get_tree().get_nodes_in_group("gates"):
			var gate := node as Gate
			if gate != null:
				# is_really_open, not is_open: the second is what was asked for
				# and it once said OPEN while the bars stayed solid.
				print("capture: gate at %s %s (asked for %s)" % [
					gate.global_position,
					"OPEN" if gate.is_really_open() else "SHUT",
					"open" if gate.is_open else "shut"
				])


	## Presses what this phase wants and releases what it does not, so a phase
	## describes a state of the controller rather than a set of key presses.
	func _hold_exactly(actions: PackedStringArray) -> void:
		for action in _held:
			if not actions.has(action):
				Input.action_release(action)
		for action in actions:
			if not _held.has(action):
				Input.action_press(action)
		_held = actions

	## Frames the whole room in one picture, for checking a layout rather than a
	## moment. Limits go with the zoom, or the camera clamps to the play area.
	func _pull_the_camera_back() -> void:
		for node in get_tree().get_nodes_in_group("player"):
			for child in node.get_children():
				var camera := child as Camera2D
				if camera == null:
					continue
				if _zoom > 0.0:
					camera.zoom = Vector2(_zoom, _zoom)
				camera.position_smoothing_enabled = false
				camera.limit_left = -100000
				camera.limit_top = -100000
				camera.limit_right = 100000
				camera.limit_bottom = 100000
				if _centre.is_finite():
					# Off the player, so an overview frames the room and not
					# wherever the player happens to be standing.
					camera.top_level = true
					camera.global_position = _centre

	## Physics frames, not render frames. Rendering runs uncapped and faster than
	## 60 Hz here, so counting drawn frames makes a scripted run travel a
	## different distance every time the machine changes speed.
	func _wait(frames: int) -> void:
		for i in frames:
			await get_tree().physics_frame
