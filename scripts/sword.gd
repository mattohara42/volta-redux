## The sword. One scene, one script, one state machine, per CLAUDE.md.
##
## The rules are in SwordFlight and the node does not second-guess them: each
## frame it gathers the facts, asks for the next state, and behaves accordingly.
## Embed, recall and conduct are M2 and M3 and they become states here, not a
## second script.
class_name Sword
extends Area2D

## Back in the player's hand, caught in the air or picked up off the floor.
signal recovered
## Hit something solid mid-flight. That sword is gone.
signal destroyed

@export var config: SwordConfig
@export var world: WorldConfig

## How deep the standable surface of an embedded sword is, px. Thin, because a
## sword is thin, and the player stands on its top edge.
const LEDGE_THICKNESS: float = 4.0

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


## Wood is a group rather than a physics layer, because wood is ordinary solid
## geometry that happens to bite. Making it its own layer would mean every room
## remembering to mark planks as solid twice.
func _on_body_entered(body: Node2D) -> void:
	if _contact == SwordFlight.Contact.WOOD:
		# Two bodies in one frame: wood wins, rather than whichever signal was
		# emitted second.
		return
	_contact = SwordFlight.Contact.WOOD if body.is_in_group("wood") else SwordFlight.Contact.SOLID


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
		_contact,
		state == SwordFlight.State.RETURNING and SwordFlight.has_overshot(
			offset_before, offset_after
		),
		_landed,
		_recalled
	)
	_contact = SwordFlight.Contact.NONE
	_recalled = false

	if next != state:
		_enter(next)
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
	var query := PhysicsRayQueryParameters2D.create(
		global_position - step * 2.0, global_position + step
	)
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		# Nothing found, so leave it where it stopped rather than teleport it
		# somewhere arbitrary. Visible as a ledge overlapping the plank.
		return
	global_position.x = SwordFlight.embed_position(
		hit["position"].x, direction, world.sword_length
	)


func _enter(next: SwordFlight.State) -> void:
	state = next
	match state:
		SwordFlight.State.RETURNING:
			_return_distance = 0.0
		SwordFlight.State.EMBEDDED:
			_settle_against_the_surface(_velocity.x)
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
		SwordFlight.State.FALLING:
			# Keeps whatever horizontal speed it had, so a sword that sailed
			# past you lands past you.
			_velocity.y = 0.0
		SwordFlight.State.GROUNDED:
			_velocity = Vector2.ZERO
			rotation = 0.0
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
			recovered.emit()
			queue_free()
		SwordFlight.State.DESTROYED:
			destroyed.emit()
			queue_free()


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
