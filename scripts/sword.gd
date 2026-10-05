## The sword. One scene, one script, one state machine, per CLAUDE.md.
##
## The rules are in SwordFlight and the node does not second-guess them: each
## frame it gathers the facts, asks for the next state, and behaves accordingly.
## Embed, recall and conduct are M2 and M3 and they become states here, not a
## second script.
class_name Sword
extends Area2D

## Back in the player's hand, caught in the air or picked up off the floor.
## `caught_in_flight` is true only for the first of those: SPEC.md and M1's
## done-when both already treat a catch and a walk-over pick-up as different
## things ("a missed catch leaves a sword on the floor you can walk over to
## pick up"), and the hero's own catch pose is specifically about the first
## one. Nothing brace for a sword that was just lying there.
signal recovered(caught_in_flight: bool)
## Hit something solid mid-flight. That sword is gone.
signal destroyed

@export var config: SwordConfig
@export var world: WorldConfig

## How deep the standable surface of an embedded sword is, px. Thin, because a
## sword is thin, and the player stands on its top edge.
const LEDGE_THICKNESS: float = 4.0
const ATMOSPHERE: AtmosphereConfig = preload("res://config/atmosphere.tres")
## Set by a room's `CircuitNetwork`: this sword is wired into a live circuit.
## Embedded is the state; conducting is what the circuit says about it.
var conducting := false:
	set(value):
		if value != conducting:
			conducting = value
			queue_redraw()

var state: SwordFlight.State = SwordFlight.State.FLYING

var _thrower: Node2D
var _velocity := Vector2.ZERO
var _distance_travelled := 0.0
var _return_distance := 0.0
## What was run into this frame, cleared every frame. Wood and stone are the
## same event to the physics engine and different events to the game.
var _contact: SwordFlight.Contact = SwordFlight.Contact.NONE
var _landed := false
## Set by `recall()` and spent on the next step, so the player can ask without
## knowing which state the sword happens to be in.
var _recalled := false
## Set by a live `Barrier` the sword's path crossed, and acted on at the next
## step like any other contact.
var _fried := false
## Set by `yank`: torn out of the wall at this horizontal speed, at the next step.
var _yank_speed := 0.0
## Whether what it last bit was metal rather than wood, for which burst it
## throws: sparks off copper, chips off a plank.
var _bit_metal := false
## A short gold wake behind a sword in the air (`_make_trail`), so where a
## throw is going reads at a glance.
var _trail: CPUParticles2D
## The whirr of a sword in the air, looping and panned with it: what says
## where a sword is without looking (`SwordConfig.fly_sound`).
var _hum: AudioStreamPlayer2D
## Whether the step that destroyed it was a live barrier, which sounds
## different from a sword breaking on stone.
var _burnt := false

@onready var _shape: CollisionShape2D = $CollisionShape2D
## The one-tile ledge an embedded sword becomes. A separate body because an
## Area2D cannot be stood on, on its own layer so the sword's own detection
## never sees it, and disabled everywhere except EMBEDDED.
@onready var _ledge: CollisionShape2D = $Ledge/CollisionShape2D
## ANIMATION.md: "an actor and its sound are one event off one tick, never
## two schedules." Played directly from `_enter()`, the one place a state
## change happens, rather than from a timer or an animation callback.
@onready var _sound: AudioStreamPlayer2D = $Sound


func _ready() -> void:
	add_to_group("swords")
	var box := _shape.shape as RectangleShape2D
	box.size = Vector2(world.sword_length, world.sword_length * 0.36)
	var ledge_box := _ledge.shape as RectangleShape2D
	ledge_box.size = Vector2(world.sword_length, LEDGE_THICKNESS)
	_ledge.disabled = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# A glint, so the most important shape on screen is never lost in a dark
	# corner of a room (`LightField`).
	add_child(LightSource.point(ATMOSPHERE.light_sword_radius, Palette.GOLD_FACE, ATMOSPHERE.light_sword_strength))
	_trail = _make_trail()
	add_child(_trail)
	_sound.bus = Sfx.BUS
	_hum = AudioStreamPlayer2D.new()
	_hum.stream = config.fly_sound
	_hum.bus = Sfx.BUS
	add_child(_hum)


## Wood is a group rather than a physics layer, because wood is ordinary solid
## geometry that happens to bite. Making it its own layer would mean every room
## remembering to mark planks as solid twice.
func _on_body_entered(body: Node2D) -> void:
	if _contact == SwordFlight.Contact.WOOD:
		# Two bodies in one frame: wood wins, rather than whichever signal was
		# emitted second.
		return
	# Metal bites like wood (`SPEC.md` → *Conduct*): a sword has to embed in a
	# conductor to carry its current.
	var bites := body.is_in_group("wood") or body.is_in_group("metal")
	_contact = SwordFlight.Contact.WOOD if bites else SwordFlight.Contact.SOLID
	_bit_metal = body.is_in_group("metal")


## An enemy is its own physics layer rather than a body, because touching it
## also has to kill the hero (`Enemy` extends `Hazard` for that half) and
## `Hazard` is an `Area2D`. To the sword this is just another solid thing to
## stop against: SPEC.md's "both die" is the enemy's own decision, made
## independently when its area sees the sword arrive, not something the sword
## needs to know about.
func _on_area_entered(area: Area2D) -> void:
	if _contact == SwordFlight.Contact.WOOD:
		return
	if area.is_in_group("enemies"):
		_contact = SwordFlight.Contact.SOLID


## Crossed live current (`Barrier`). The sword is gone at its next step,
## whatever it was doing.
func fry() -> void:
	_fried = true


## Torn out of whatever it is embedded in and thrown toward `toward_x` at
## `speed`, falling as it goes. Only an embedded sword answers, like a recall.
func yank(toward_x: float, speed: float) -> void:
	_yank_speed = signf(toward_x - global_position.x) * speed


## Bring it home. Only an embedded sword answers; the rest ignore it, so the
## player can shout at every sword on screen and let the machine sort it out.
func recall() -> void:
	_recalled = true


## Called by whoever threw it. `direction` is -1 or 1: the sword has no arc and
## no vertical aim, which is the whole point of the flat return.
func launch(thrower: Node2D, direction: float) -> void:
	_thrower = thrower
	global_position = thrower.global_position
	_velocity = Vector2(signf(direction) * config.speed, 0.0)
	state = SwordFlight.State.FLYING
	_trail.emitting = true
	_set_humming(true)


func _physics_process(delta: float) -> void:
	var target := _target_position()
	var offset_before := target.x - global_position.x

	_advance(delta)

	var offset_after := target.x - global_position.x
	var caught := (
		(state == SwordFlight.State.RETURNING or state == SwordFlight.State.RECALLING)
		and SwordFlight.is_within(global_position, target, config.catch_radius)
	)
	var picked_up := (
		state == SwordFlight.State.GROUNDED
		and SwordFlight.is_within(global_position, target, config.pickup_radius)
	)

	var next := SwordFlight.next_state(
		state,
		SwordFlight.at_max_range(_distance_travelled, config.max_range),
		SwordFlight.return_spent(_return_distance, config.max_return_distance),
		caught,
		picked_up,
		SwordFlight.Contact.LIVE if _fried else _contact,
		state == SwordFlight.State.RETURNING and SwordFlight.has_overshot(
			offset_before, offset_after
		),
		_landed,
		_recalled,
		_yank_speed != 0.0
	)
	_contact = SwordFlight.Contact.NONE
	_recalled = false
	_burnt = _fried
	_fried = false
	if next == SwordFlight.State.FALLING and state == SwordFlight.State.EMBEDDED:
		# Torn out: falling has gravity, this gives it the throw.
		_velocity = Vector2(_yank_speed, 0.0)
		rotation = 0.0
	_yank_speed = 0.0
	_shock_whoever_touches_it()

	if next != state:
		_enter(next, caught)
	queue_redraw()


## One step of whatever the current state does. Position is moved by hand rather
## than by a body, because a thrown object should pass through nothing and stop
## for nothing until the rules say so.
func _advance(delta: float) -> void:
	match state:
		SwordFlight.State.FLYING:
			var step := _velocity * delta
			global_position += step
			_distance_travelled += step.length()
			rotation += config.spin_speed * delta * signf(_velocity.x)
		SwordFlight.State.RETURNING:
			_velocity.x = SwordFlight.return_velocity_x(
				global_position.x, _target_position().x, config.speed
			)
			# y is untouched. The return leg is flat and that is the rule the
			# whole catch hangs off.
			var step := Vector2(_velocity.x * delta, 0.0)
			global_position += step
			_return_distance += absf(step.x)
			rotation += config.spin_speed * delta * signf(_velocity.x)
		SwordFlight.State.RECALLING:
			_velocity = SwordFlight.recall_velocity(
				global_position, _target_position(), config.recall_speed
			)
			global_position += _velocity * delta
			rotation += config.spin_speed * delta * signf(_velocity.x)
		SwordFlight.State.FALLING:
			_velocity = SwordFlight.step_fall(
				_velocity, config.fall_gravity, config.fall_drag,
				config.max_fall_speed, delta
			)
			_fall_by(_velocity * delta)


## Falling is the one time the sword needs the floor, so it looks for it rather
## than waiting to overlap it. Landing on a floor is not the same event as
## hitting a wall at speed, and only one of them destroys a sword.
func _fall_by(step: Vector2) -> void:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, global_position + step + Vector2(0.0, world.sword_length * 0.5)
	)
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		global_position += step
		return
	global_position = hit["position"] - Vector2(0.0, world.sword_length * 0.25)
	_landed = true


## Plays a sound at the sword's own position, or does nothing if `config`
## has none set for this cue yet. A null stream is a real state (M15 has not
## landed, or a bench scene skipped SwordConfig's sound fields) rather than a
## bug, so this never errors on one.
func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	_sound.stream = stream
	_sound.play()


## For tools/capture.gd. Whether a sword actually played a sound is a node's
## own runtime state, not arithmetic: the same reason a switch's sensing or a
## gate's opening (`_report_mechanisms`) is reported here rather than
## asserted. Reports the last cue this sword's own Sound node was set to,
## rather than whether it is still audibly playing this exact frame: these
## are short placeholder clips (under 150 ms), and a room can easily hold a
## scene for longer than that before a screenshot is taken, so "still
## playing" would report false on a cue that fired and finished exactly as
## asked.
func sound_status() -> String:
	if _sound == null or _sound.stream == null:
		return "quiet"
	return "played %s" % _sound.stream.resource_path.get_file()


## Finds the face the sword just went through and sits half a blade clear of it.
##
## Asking the world where the surface is, rather than inferring it from where
## the sword was when the overlap got reported. `body_entered` arrives a frame
## or so late, and at throw speed a frame is 7 px, so the inferred answer was
## out by enough to bury half the ledge.
##
## The ray starts well back along the travel direction, outside the plank, and
## runs past the sword, so the first thing it meets is the face that stopped it.
func _settle_against_the_surface(direction: float) -> void:
	var step := Vector2(signf(direction) * world.sword_length, 0.0)
	var space := get_world_2d().direct_space_state
	var hit := {}
	# The centre line and the blade's top and bottom edges, keeping whichever
	# meets a face first: a sword thrown into an insulating seam (`SPEC.md` →
	# *Conduct*) bites the metal either side, and its centre line runs down the
	# gap between them to whatever is behind.
	for lift in [0.0, -LEDGE_THICKNESS * 0.5, LEDGE_THICKNESS * 0.5]:
		var origin := global_position + Vector2(0.0, lift)
		var query := PhysicsRayQueryParameters2D.create(origin - step * 2.0, origin + step)
		query.collision_mask = 1
		var found := space.intersect_ray(query)
		if found.is_empty():
			continue
		if hit.is_empty() or absf(found["position"].x - query.from.x) < absf(hit["position"].x - query.from.x):
			hit = found
	if hit.is_empty():
		# Nothing found, so leave it where it stopped rather than teleport it
		# somewhere arbitrary. Visible as a ledge overlapping the plank.
		return
	global_position.x = SwordFlight.embed_position(
		hit["position"].x, direction, world.sword_length
	)


## `caught_in_flight` only means anything on the transition into CAUGHT; every
## other state ignores the argument. Passed in from `_physics_process` rather
## than recomputed here, since by the time `_enter` runs the two conditions
## that could have produced CAUGHT (`caught` and `picked_up`) have already
## been collapsed into a single `next`.
func _enter(next: SwordFlight.State, caught_in_flight: bool = false) -> void:
	var was := state
	state = next
	_trail.emitting = SwordFlight.is_airborne(state)
	_set_humming(SwordFlight.is_airborne(state))
	match state:
		SwordFlight.State.RETURNING:
			_return_distance = 0.0
		SwordFlight.State.EMBEDDED:
			_settle_against_the_surface(_velocity.x)
			# Chips off a plank, sparks off copper, out of the face it bit and
			# back toward where it came from.
			Burst.emit(get_parent(), _point(), Burst.Kind.SPARKS if _bit_metal else Burst.Kind.CHIPS, -signf(_velocity.x))
			# Level, and pointing the way it was going, so the blade is in the
			# plank and the hilt is the bit you stand on.
			rotation = 0.0 if _velocity.x >= 0.0 else PI
			_velocity = Vector2.ZERO
			_ledge.set_deferred("disabled", false)
			_play(config.embed_sound)
		SwordFlight.State.RECALLING:
			# The ledge goes before the sword does. Standing on the one you are
			# recalling is a legitimate and bad idea, per SPEC.md, and this is
			# the line that makes it bad.
			_ledge.set_deferred("disabled", true)
			_play(config.recall_sound)
			if was == SwordFlight.State.EMBEDDED:
				# Pulled out of the wall: the face it was in gives a little.
				var point := global_position + Vector2.RIGHT.rotated(rotation) * world.sword_length * 0.5
				Burst.emit(get_parent(), point, Burst.Kind.SPARKS if _bit_metal else Burst.Kind.CHIPS, -cos(rotation))
		SwordFlight.State.FALLING:
			# Keeps whatever horizontal speed it had, so a sword that sailed
			# past you lands past you.
			_velocity.y = 0.0
			# A torn-out sword is no longer a ledge.
			_ledge.set_deferred("disabled", true)
		SwordFlight.State.GROUNDED:
			_velocity = Vector2.ZERO
			rotation = 0.0
			Burst.emit(get_parent(), global_position + Vector2(0.0, world.sword_length * 0.25), Burst.Kind.DUST)
			Sfx.play(self, config.clatter_sound, true)
		SwordFlight.State.CAUGHT:
			# The sword frees itself this frame, which would cut the sound off
			# mid-play if it stayed a child of this node: `_sound` is handed to
			# the room instead, and frees itself once the clip finishes.
			_sound.stream = config.catch_sound
			var at := _sound.global_position
			remove_child(_sound)
			get_parent().add_child(_sound)
			_sound.global_position = at
			_sound.finished.connect(_sound.queue_free)
			_sound.play()
			if caught_in_flight:
				Burst.emit(get_parent(), global_position, Burst.Kind.GLINT)
			recovered.emit(caught_in_flight)
			queue_free()
		SwordFlight.State.DESTROYED:
			# Spent: its pieces, and the sparks of whatever it broke on.
			Burst.emit(get_parent(), global_position, Burst.Kind.SHARDS)
			Burst.emit(get_parent(), global_position, Burst.Kind.SPARKS, -signf(_velocity.x))
			Sfx.play(self, config.fry_sound if _burnt else config.break_sound, true)
			destroyed.emit()
			queue_free()


## Gold pixels left hanging where the sword has been for a tenth of a second,
## so a sword in the air draws its own path. Particles left behind in the room
## rather than carried along, which is what makes them a wake.
func _make_trail() -> CPUParticles2D:
	var trail := CPUParticles2D.new()
	trail.local_coords = false
	trail.amount = 14
	trail.lifetime = 0.14
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.0
	trail.gravity = Vector2.ZERO
	trail.scale_amount_min = 1.0
	trail.scale_amount_max = 2.0
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, Palette.GOLD_FACE)
	ramp.set_color(1, Color(Palette.GOLD_SHADE, 0.0))
	trail.color_ramp = ramp
	return trail


## The fly loop on while the sword is in the air and off the moment it is
## not, from the same state change that moves it (`ANIMATION.md`).
func _set_humming(on: bool) -> void:
	if _hum == null or _hum.stream == null:
		return
	if on and not _hum.playing:
		_hum.play()
	elif not on and _hum.playing:
		_hum.stop()


## Where the blade's point is, for the burst a bite or a break throws.
func _point() -> Vector2:
	return global_position + Vector2(signf(_velocity.x) * world.sword_length * 0.5, 0.0)


## A sword carrying current is live metal like any other (`SPEC.md` →
## *Conduct*): standing on it or against it kills, which is what makes a rung
## in live copper a trap.
func _shock_whoever_touches_it() -> void:
	if not conducting or state != SwordFlight.State.EMBEDDED:
		return
	var blade := Rect2(
		global_position - Vector2(world.sword_length, LEDGE_THICKNESS) * 0.5,
		Vector2(world.sword_length, LEDGE_THICKNESS)
	).grow(Conductor.TOUCH)
	var hero_size := Vector2(world.hero_width, world.hero_height)
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player != null and Rect2(player.global_position - hero_size * 0.5, hero_size).intersects(blade):
			player.die()


## Where the sword is trying to get back to: where you are now, not where you
## threw from. CLAUDE.md lists that as settled and it is what makes moving
## during a throw a decision.
func _target_position() -> Vector2:
	if not is_instance_valid(_thrower):
		return global_position
	return _thrower.global_position


## Gold, because ART_DIRECTION.md reserves gold for things you interact with and
## nothing else gets to use it. Drawn rather than imported: no PNG before M5.
func _draw() -> void:
	var half := world.sword_length * 0.5
	var w := world.sword_length * 0.18
	draw_rect(Rect2(-half, -w * 0.45, half * 0.72, w * 0.9), Palette.GOLD_SHADE)
	draw_circle(Vector2(-half + w * 0.3, 0.0), w * 0.55, Palette.GOLD_SHADE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half * 0.28, -w),
		Vector2(half, 0.0),
		Vector2(-half * 0.28, w),
	]), Palette.GOLD_FACE)
	# A crossguard, drawn over the blade's base. Without it the silhouette reads
	# as a dart, and ART_DIRECTION.md makes silhouette a rule rather than taste.
	draw_rect(Rect2(-half * 0.4, -w * 1.6, w * 0.5, w * 3.2), Palette.GOLD_SHADE)
	if state == SwordFlight.State.EMBEDDED:
		# The actual collision extent, drawn. An assertion proves the ledge is
		# there; only this proves it is where the player thinks it is.
		draw_rect(
			Rect2(-half, -LEDGE_THICKNESS * 0.5, world.sword_length, LEDGE_THICKNESS),
			Color(Palette.GOLD_FACE, 0.28)
		)
		draw_line(
			Vector2(-half, -LEDGE_THICKNESS * 0.5), Vector2(half, -LEDGE_THICKNESS * 0.5),
			Palette.GOLD_FACE, 1.0
		)
	if state == SwordFlight.State.GROUNDED:
		# A sword you can pick up should say so from across the room.
		draw_arc(
			Vector2.ZERO, config.pickup_radius, 0.0, TAU, 24,
			Color(Palette.GOLD_FACE, 0.35), 1.0
		)
	# Current running through it: a hard cyan line along the blade, the arc's
	# colour, so a wired sword reads as wired.
	if conducting:
		draw_line(Vector2(-half * 0.28, 0.0), Vector2(half, 0.0), Palette.ARC, 1.0)
