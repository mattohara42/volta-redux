## The capsule. Runs, jumps, climbs, and reads every number it uses out of a
## MovementConfig, so M14 can retune the whole game without opening this file.
##
## The rules live in scripts/logic/. This script owns state and the engine calls;
## it owns no arithmetic that a headless test would want to reach.
class_name Player
extends CharacterBody2D

## The game's movement, and the alternative it beat. M0 settled the
## jump-versus-ladders question in SPEC.md by feel: a storey is climbed, not
## jumped. Tab still swaps them live, which M14 will want.
@export var preset_climb: MovementConfig
@export var preset_strong: MovementConfig
@export var world: WorldConfig
@export var sword_config: SwordConfig
@export var death_config: DeathConfig
@export var sword_scene: PackedScene

## Hero heights to cycle with [ and ], around ART_DIRECTION.md's estimate of 40.
const HERO_HEIGHT_STEPS: PackedFloat32Array = [28.0, 34.0, 40.0, 46.0, 54.0]

## The rig this species is built from, painted once for the whole game.
## `assets/art/hero/rig/`, cut from the M5 delivery `ART.md` records.
const RIG_SCENE: PackedScene = preload("res://scenes/hero_rig.tscn")
## `scenes/hero_rig.tscn`'s own bone and sprite offsets, composited: top of the
## head to the sole of the boot, and the horizontal centreline through the
## standing figure. Read off the rig's recorded numbers, not measured from a
## screenshot, so a redraw of the rig is the only thing that moves them.
const RIG_SOURCE_TOP: float = 80.0
const RIG_SOURCE_BOTTOM: float = 1140.0
const RIG_SOURCE_CENTRE_X: float = 440.0
## `assets/art/hero/rig/torso.png`'s own height, in the same source pixels as
## the three constants above. `Bat.RIG_TARGET_BODY_LENGTH` sizes against this.
const RIG_SOURCE_TORSO_LENGTH: float = 470.0

var config: MovementConfig
## The painted rig, standing in for the drawn capsule wherever one is
## available. Null only if `RIG_SCENE` fails to load, in which case `_draw`
## falls back to the capsule rather than showing nothing.
var _rig: Node2D = null
## `_rig`'s own `AnimationTree`. Null under the same condition as `_rig`, or if
## a future rig scene drops the node; `_update_animation` no-ops either way.
var _anim_tree: AnimationTree = null
## How long the landing pose holds, read once from the rig's own "land"
## animation length rather than duplicated as a number here, so retiming the
## pose in `hero_rig.tscn` is the only place that has to change. Zero (no
## hold at all) if the rig or the animation is missing.
var _land_pose_duration := 0.0
## Counts down from `_land_pose_duration` after a landing; `Locomotion` reads
## it to hold the LAND state for that long before falling back to idle/run.
var _landing_timer := 0.0
## Where the next death puts you. Starts as wherever the room placed you and
## moves only when a brazier is lit, which is the only thing in the game that
## touches it.
var spawn_point := Vector2.ZERO
## Read by the debug overlay. How many braziers have been lit, so "did that one
## take" is answerable by looking rather than by dying to find out.
var checkpoints_lit := 0

## Ammunition. SPEC.md: three swords, cap five, and the count is the difficulty
## dial. A thrown sword is spent the moment it leaves your hand and only comes
## back if you catch it or walk to it.
var swords_held := 0
## What a respawn restores you to. Normally the config's count, but a room may
## lower it: M2's switch room needs you to hold exactly one, or recall is not
## the only way to get your sword back and the puzzle has a second solution.
var swords_at_spawn := 0
## Which way a throw goes. Held rather than derived from velocity, or a standing
## player would have no facing to throw along.
var facing := 1.0
var _throw_cooldown := 0.0
## How long the throw button has been down. SPEC.md puts recall on a hold of the
## same button, so this is what separates the two.
var _throw_held := 0.0
var _recall_fired := false

# Forgiveness windows, owned here and interpreted by JumpGate.
var _coyote_timer := 0.0
var _buffer_timer := 0.0

## The death loop. `_death_elapsed` accumulates real deltas rather than being
## compared against a wall clock, so `last_downtime` is what the game actually
## took and not what config/death.tres asked for. Those differ by up to a frame
## and the measured one is the one M3's done-when is about.
var _dead := false
var _death_elapsed := 0.0
## Read by the debug overlay. Seconds from dying to the controls answering, as
## measured on the last death. Zero until you have died once.
var last_downtime := 0.0
## Read by the debug overlay. Dying twenty times in a row is the other half of
## M3's done-when and counting them is how you know you did.
var deaths := 0

## The death message, which the 1984 original had fifteen of. The bag is what
## makes the rotation unique: every line is seen once before any repeats.
## `message_index` is read by `_draw` and by the overlay.
var message_index := -1
var _message_bag: PackedInt32Array = []
var _message_timer := 0.0

## How fast something is carrying the hero upward this physics step, px/s, or
## zero for the usual arrangement where gravity decides. Written by whatever is
## doing the lifting and spent in the same step.
##
## Nothing here counts entering or leaving anything, unlike the ladder probe
## below. A geyser is a column you are inside rather than a fixture you take hold
## of, and the honest way to say that is that it has to keep saying so: one frame
## without a lift and the hero is falling again, which is what stepping sideways
## out of a jet is.
var _lift_speed := 0.0

# Ladders currently overlapping the body.
var _ladders_touched := 0
## Read by the debug overlay.
var climbing := false

# Read by the debug overlay. The apex of the jump you are in or just finished,
# measured in px above the point you left the floor.
var peak_height := 0.0
var _takeoff_y := 0.0

@onready var _message_label: Label = $DeathMessage/Label
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _ladder_probe: Area2D = $LadderProbe
@onready var _probe_shape: CollisionShape2D = $LadderProbe/CollisionShape2D
## ANIMATION.md: "an actor and its sound are one event off one tick, never
## two schedules." The throw sound belongs to the hero, not the sword: a
## thrown sword's own life starts a frame later than the press that spends it.
@onready var _sound: AudioStreamPlayer2D = $Sound


func _ready() -> void:
	add_to_group("player")
	config = preset_climb
	spawn_point = global_position
	swords_at_spawn = sword_config.starting_swords
	swords_held = swords_at_spawn
	if RIG_SCENE != null:
		_rig = RIG_SCENE.instantiate()
		add_child(_rig)
		_anim_tree = _rig.get_node_or_null("AnimationTree")
		var anim_player := _rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim_player != null and anim_player.has_animation("land"):
			_land_pose_duration = anim_player.get_animation("land").length
	_apply_hero_size(world.hero_height)
	_message_label.add_theme_font_size_override("font_size", death_config.message_font_size)
	_message_label.add_theme_color_override("font_color", Palette.FIRE_HOT)
	_message_label.text = ""
	_ladder_probe.area_entered.connect(func(_a: Area2D) -> void: _ladders_touched += 1)
	_ladder_probe.area_exited.connect(func(_a: Area2D) -> void: _ladders_touched = maxi(_ladders_touched - 1, 0))


func _physics_process(delta: float) -> void:
	_handle_debug_keys()

	# Ticked before the dead branch returns, or the message would freeze on screen
	# for the length of the hold and then vanish the instant you could move.
	_message_timer = maxf(_message_timer - delta, 0.0)
	_update_message()

	# Before the input reads, not after. A dead player who still gets a frame of
	# steering is the bug this ordering exists to prevent.
	if _dead:
		_step_death(delta)
		return

	var on_floor := is_on_floor()
	var input_dir := Input.get_axis("move_left", "move_right")
	var climb_dir := Input.get_axis("climb_up", "climb_down")
	if not is_zero_approx(input_dir):
		facing = signf(input_dir)
	_throw_cooldown = maxf(_throw_cooldown - delta, 0.0)
	_step_throw_button(delta)

	_coyote_timer = JumpGate.coyote_next(on_floor, _coyote_timer, config.coyote_time, delta)
	_buffer_timer = JumpGate.buffer_next(
		Input.is_action_just_pressed("jump"), _buffer_timer, config.jump_buffer_time, delta
	)

	if climbing:
		_step_climbing(input_dir, climb_dir, delta)
	else:
		_step_airborne(input_dir, climb_dir, on_floor, delta)

	move_and_slide()
	# Spent. Whatever was lifting has to say so again next frame or the hero is
	# falling, which is the whole of how you get out of a jet.
	_lift_speed = 0.0
	# After the move, so the apex is the position the body actually reached and
	# not the one it held a frame earlier.
	_track_peak()
	# Checked again after the move: `on_floor` above is where the body ended
	# last frame, this is where it ended this one, and the edge between the
	# two is a landing.
	var grounded_now := is_on_floor()
	if grounded_now and not on_floor:
		_landing_timer = _land_pose_duration
	else:
		_landing_timer = maxf(_landing_timer - delta, 0.0)
	_update_rig()
	_update_animation(grounded_now)
	queue_redraw()


func _step_climbing(input_dir: float, climb_dir: float, delta: float) -> void:
	if _ladders_touched == 0 or Input.is_action_just_pressed("jump"):
		climbing = false
		if Input.is_action_just_pressed("jump"):
			_jump(delta)
		return
	velocity.y = climb_dir * config.climb_speed
	velocity.x = Motion.step_horizontal(
		velocity.x, input_dir, config.air_accel, config.ground_friction,
		config.climb_speed, delta
	)


func _step_airborne(input_dir: float, climb_dir: float, on_floor: bool, delta: float) -> void:
	if _ladders_touched > 0 and not is_zero_approx(climb_dir):
		climbing = true
		velocity = Vector2.ZERO
		return

	if _lift_speed > 0.0:
		# A column owns your vertical speed for as long as you are in it, gravity
		# and the jump's release damping included. Rising at a fixed speed is what
		# makes the drawn jet a promise about where it puts you, and it is what
		# makes leaving one a decision rather than a thing that happens to you.
		velocity.y = -_lift_speed
		# A ride is not a jump, and the overlay's apex reading is about jumps.
		# Held at the body's own height while the column has hold of it, so what
		# it reports afterwards is how far you coasted above the top of the jet.
		_takeoff_y = global_position.y
		peak_height = 0.0
	else:
		var gravity := Motion.gravity_for(config.jump_height, config.time_to_apex)
		velocity.y = Motion.step_vertical(
			velocity.y, gravity, config.fall_gravity_multiplier, config.max_fall_speed, delta
		)
		if Input.is_action_just_released("jump"):
			velocity.y = Motion.damp_on_release(velocity.y, config.jump_release_damping)

	velocity.x = Motion.step_horizontal(
		velocity.x,
		input_dir,
		config.ground_accel if on_floor else config.air_accel,
		config.ground_friction if on_floor else config.air_friction,
		config.max_run_speed,
		delta
	)

	if JumpGate.should_jump(_coyote_timer, _buffer_timer):
		_jump(delta)


## One button, two verbs. The throw goes out on the press so it never feels
## laggy, and the recall fires later in the same hold, once the button has been
## down longer than any tap. Holding therefore throws and then calls everything
## home, which is what you want when you are out of swords and standing on one.
func _step_throw_button(delta: float) -> void:
	if not Input.is_action_pressed("throw"):
		_throw_held = 0.0
		_recall_fired = false
		return
	if Input.is_action_just_pressed("throw"):
		_throw()
	_throw_held += delta
	if SwordFlight.recall_triggered(_throw_held, sword_config.recall_hold_time, _recall_fired):
		_recall_fired = true
		_recall_embedded()


## Shouts at every sword on screen. Only the embedded ones answer, which keeps
## the decision about which sword comes back inside the machine that owns it.
func _recall_embedded() -> void:
	for node in get_tree().get_nodes_in_group("swords"):
		var sword := node as Sword
		if sword != null:
			sword.recall()


## Killed. Called by anything in the "hazards" group that touches you, and by
## nothing else: there is no damage, no health and no second chance, which is
## SPEC.md keeping the original's lethality on purpose.
##
## Idempotent, because lava is one area and falling into it reports on more than
## one frame. A second call inside a death would otherwise restart the clock and
## strand you.
func die() -> void:
	if _dead:
		return
	_dead = true
	_death_elapsed = 0.0
	velocity = Vector2.ZERO
	climbing = false
	deaths += 1
	_draw_a_message()
	queue_redraw()


## Carried upward at `speed` px/s for this physics step. Called by a geyser, and
## by nothing else.
##
## The hero does not know what a geyser is. It knows that something has taken
## over its vertical speed, which is the same arrangement `Hazard` has with
## `die`: the mechanism owns the rule and the hero owns the body. The strongest
## claim wins, so two jets that overlap is a room's oddity and not a bug here.
##
## A dead body is not lifted. The death loop deliberately stops calling
## `move_and_slide`, so a lift arriving mid-death would be spent on nothing and
## then be waiting in the field when the respawn put the hero down somewhere else.
func lift(speed: float) -> void:
	if _dead:
		return
	_lift_speed = maxf(_lift_speed, speed)


## Takes one line from the bag, refilling it when it runs dry. The message
## outlasts the loop on purpose: it is still on screen once you have the
## controls back, so reading it costs none of SPEC.md's one second.
func _draw_a_message() -> void:
	if death_config.message_seconds <= 0.0:
		message_index = -1
		return
	_message_bag = DeathMessages.refill_if_empty(_message_bag, DeathMessages.count())
	var slot := DeathMessages.slot_for(randf(), _message_bag.size())
	if slot < 0:
		message_index = -1
		return
	message_index = _message_bag[slot]
	_message_bag.remove_at(slot)
	_message_timer = death_config.message_seconds


## One physics step of being dead. `move_and_slide` is deliberately not called,
## so the body stays where it was killed for the whole hold rather than sliding
## or falling through what it died on.
func _step_death(delta: float) -> void:
	var hold := death_config.death_hold
	var freeze := death_config.respawn_freeze
	var before := _death_elapsed
	_death_elapsed += delta

	if DeathClock.crosses_placement(before, _death_elapsed, hold):
		_place_at_checkpoint(death_config.restore_swords)

	if DeathClock.has_control(_death_elapsed, hold, freeze):
		# The measured figure, not the budgeted one. It overshoots config by up
		# to a frame because control returns on a step boundary, and that
		# overshoot is real: it is what the player waited through.
		last_downtime = _death_elapsed
		_dead = false
		_death_elapsed = 0.0
	_update_rig()
	queue_redraw()


## Back at the checkpoint. Swords in play are destroyed rather than left lying,
## or a room would fill with the evidence of twenty failed attempts.
func _place_at_checkpoint(restore_swords: bool) -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	peak_height = 0.0
	# Whatever was carrying you is not carrying you any more, and it is about to
	# be put back at the start of its own clock a few lines below.
	_lift_speed = 0.0
	if restore_swords:
		swords_held = swords_at_spawn
	for node in get_tree().get_nodes_in_group("swords"):
		node.queue_free()
	# Every mechanism with a clock in it back at the start of that clock, now: a
	# slab that let go back at home, a ferry back at the dock you respawn beside,
	# a geyser back at the first frame of its swell. M3's bargain is that a death
	# costs you the jump you missed and nothing else, and arriving to find the
	# route still missing two of its steps, the only way across still out in the
	# middle of the moat, or the vent you need just gone quiet, is a second cost.
	# It is the wait that turns dying twenty times from annoying into tedious.
	#
	# One group and one call, because the third kind of mechanism arrived and
	# `BACKLOG.md` said a third one was the point at which walking a list per kind
	# stopped paying. It is still the hero reaching into the room, which is the
	# smell that entry is really about, and the entry says what the fix is.
	get_tree().call_group("mechanisms", "reset", death_config.respawn_freeze)


func is_dead() -> bool:
	return _dead


## For the overlay. ALIVE while alive, so the caller needs no null case.
func death_phase() -> DeathClock.Phase:
	if not _dead:
		return DeathClock.Phase.ALIVE
	return DeathClock.phase_at(
		_death_elapsed, death_config.death_hold, death_config.respawn_freeze
	)


## Banks a checkpoint. Called by a `Brazier` the moment it lights, and by
## nothing else: SPEC.md has exactly one way to move where a death costs you
## from. `base` is the floor point the brazier stands on, and `Checkpoints` owns
## turning that into a position a hero of this height stands at.
func light_checkpoint(base: Vector2) -> void:
	spawn_point = Checkpoints.stand_point(base, world.hero_height)
	checkpoints_lit += 1


## Set by a room that hands out a different number. Also resets what you are
## holding, since it is called before the room's puzzle has begun.
func set_swords_at_spawn(count: int) -> void:
	swords_at_spawn = count
	swords_held = count


## Spends a sword. The count drops now, not when the throw resolves, because
## the sword is out of your hands either way and the decision has been made.
func _throw() -> void:
	if swords_held <= 0 or _throw_cooldown > 0.0 or sword_scene == null:
		return
	var sword := sword_scene.instantiate() as Sword
	get_parent().add_child(sword)
	sword.launch(self, facing)
	sword.recovered.connect(_on_sword_recovered)
	swords_held -= 1
	_throw_cooldown = sword_config.throw_cooldown
	if sword_config.throw_sound != null:
		_sound.stream = sword_config.throw_sound
		_sound.play()


func _on_sword_recovered() -> void:
	swords_held = mini(swords_held + 1, sword_config.max_swords)


func _jump(delta: float) -> void:
	velocity.y = -Motion.jump_speed_for(config.jump_height, config.time_to_apex, delta)
	# Taken here, before the body has moved. Sampling it from the floor check
	# instead reads the position after the first frame of the jump and reports
	# every apex one frame short.
	_takeoff_y = global_position.y
	peak_height = 0.0
	# Spend both windows, or one press keeps buying jumps all the way up.
	_coyote_timer = 0.0
	_buffer_timer = 0.0


## Records the apex of each jump so the overlay can answer "did that clear a
## tier" with a measurement instead of a guess. Called after the move, so it
## reads the height the body actually reached.
func _track_peak() -> void:
	if not is_on_floor():
		peak_height = maxf(peak_height, _takeoff_y - global_position.y)


func _apply_hero_size(height: float) -> void:
	world.hero_height = height
	var capsule := _shape.shape as CapsuleShape2D
	capsule.height = height
	capsule.radius = world.hero_width * 0.5
	var probe := _probe_shape.shape as RectangleShape2D
	probe.size = Vector2(world.hero_width * 0.5, height * 0.8)
	_update_rig()
	queue_redraw()


## Scales and positions the rig so its own feet land on the capsule's own
## floor contact point, whatever `world.hero_height` currently is (M0's [ and
## ] keys included), and mirrors it around its own centreline rather than the
## origin, since the painted figure is not centred on (0, 0) in its own scene.
## Tints it the same cue the capsule drew: dead borrows lava's darkest value
## rather than going grey, ART_DIRECTION.md's darkest colour reserved for what
## it already reserves darkness for; climbing a warm gold, same as before.
func _update_rig() -> void:
	if _rig == null:
		return
	var rig_scale := world.hero_height / (RIG_SOURCE_BOTTOM - RIG_SOURCE_TOP)
	var signed_scale := rig_scale * facing
	_rig.scale = Vector2(signed_scale, rig_scale)
	_rig.position = Vector2(
		-RIG_SOURCE_CENTRE_X * signed_scale,
		world.hero_height * 0.5 - RIG_SOURCE_BOTTOM * rig_scale
	)
	if _dead:
		_rig.modulate = Palette.LAVA_CRUST
	elif climbing:
		_rig.modulate = Color(Palette.GOLD_FACE, 0.95)
	else:
		_rig.modulate = Color.WHITE


## Travels the rig's `AnimationTree` state machine to whatever `Locomotion`
## says the current ground contact, vertical speed and landing hold read as.
## The only thing this script does with the tree: `hero_rig.tscn` owns the
## states and how they animate.
##
## Not called during `_step_death`, so the rig freezes on whatever pose it was
## in the moment the hero died, matching the body staying where it fell.
func _update_animation(grounded: bool) -> void:
	if _anim_tree == null:
		return
	var state := Locomotion.state_for(grounded, velocity.y, _landing_timer, velocity.x)
	_anim_tree["parameters/playback"].travel(Locomotion.state_name(state))


func _handle_debug_keys() -> void:
	if Input.is_action_just_pressed("debug_next_preset"):
		config = preset_strong if config == preset_climb else preset_climb
	if Input.is_action_just_pressed("debug_respawn"):
		# R stays an instant teleport rather than a death. It is how you get out
		# of a bench you have wedged, and routing it through the death loop would
		# make the quickest key in the repo cost most of a second. Dying is what
		# lava is for.
		_place_at_checkpoint(true)
		_dead = false
		_death_elapsed = 0.0
	var step := 0
	if Input.is_action_just_pressed("debug_size_up"):
		step = 1
	elif Input.is_action_just_pressed("debug_size_down"):
		step = -1
	if step != 0:
		var i := _nearest_size_index(world.hero_height)
		_apply_hero_size(HERO_HEIGHT_STEPS[clampi(i + step, 0, HERO_HEIGHT_STEPS.size() - 1)])


func _nearest_size_index(height: float) -> int:
	var best := 0
	for i in HERO_HEIGHT_STEPS.size():
		if absf(HERO_HEIGHT_STEPS[i] - height) < absf(HERO_HEIGHT_STEPS[best] - height):
			best = i
	return best


## A capsule, drawn rather than imported. M5 painted the real thing
## (`_update_rig`), so this only runs as the fallback for a scene that somehow
## has no rig, and the shape it draws is still the one M0 settled on.
func _draw() -> void:
	if _rig != null:
		return
	var h := world.hero_height
	var r := world.hero_width * 0.5
	var top := -h * 0.5 + r
	var bottom := h * 0.5 - r
	# ART_DIRECTION.md makes silhouette a rule rather than a taste, and against
	# STONE_MID platforms a STONE_LIT capsule does not separate. The fix the
	# direction names is a rim light from the nearest real light source, so the
	# grey box gets one too.
	# ART_DIRECTION.md reserves warm and saturated for what kills you, so a
	# killed hero borrows lava's darkest value rather than going grey, which the
	# direction forbids anyway.
	var body := Palette.STONE_LIT
	if _dead:
		body = Palette.LAVA_CRUST
	elif climbing:
		body = Color(Palette.GOLD_FACE, 0.95)
	draw_circle(Vector2(0.0, top), r, body)
	draw_circle(Vector2(0.0, bottom), r, body)
	draw_rect(Rect2(-r, top, r * 2.0, bottom - top), body)
	draw_line(
		Vector2(-facing * r * 0.85, top),
		Vector2(-facing * r * 0.85, bottom),
		Palette.FIRE_CORE,
		2.0
	)
	# A facing mark, so "which way am I pointing" is answerable at 40 px.
	draw_circle(Vector2(facing * r * 0.4, top + r * 0.2), r * 0.22, Palette.STONE_DEEP)


## The death message, centred on the screen and large enough to take in at a
## glance. It lives on its own CanvasLayer, so it ignores the camera and holds
## still while the body is placed back at the checkpoint underneath it, which is
## what lets it outlast the loop without costing any of SPEC.md's one second.
##
## It fades over its last third rather than vanishing. Derived from
## `message_seconds` rather than being its own number, so retuning how long the
## line lingers retunes how long it takes to leave.
func _update_message() -> void:
	if _message_timer <= 0.0 or message_index < 0:
		_message_label.text = ""
		return
	_message_label.text = DeathMessages.message_at(message_index)
	var fade := maxf(death_config.message_seconds / 3.0, 0.01)
	_message_label.modulate = Color(1.0, 1.0, 1.0, clampf(_message_timer / fade, 0.0, 1.0))
