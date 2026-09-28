## `hero_sprite.tscn` against `Locomotion`: every state the game can ask for has
## an animation, a state-machine node and real frames to show. Nothing else in
## the suite draws the hero, so a missing state or texture was invisible to it
## (PR #69 said so in HANDOFF.md).
extends TestCase

const SCENE := "res://scenes/hero_sprite.tscn"
const MOVEMENT := "res://config/movement.tres"


func _sprite() -> Node:
	return (load(SCENE) as PackedScene).instantiate()


func test_every_locomotion_state_has_an_animation_and_a_machine_node() -> void:
	var sprite := _sprite()
	var player := sprite.get_node("AnimationPlayer") as AnimationPlayer
	var machine := (sprite.get_node("AnimationTree") as AnimationTree).tree_root as AnimationNodeStateMachine
	for state in Locomotion.State.values():
		var name := Locomotion.state_name(state)
		check(player.has_animation(name), "%s has an animation" % name)
		check(machine.has_node(name), "%s has a state-machine node" % name)
	sprite.free()


## The animation sets `AnimatedSprite2D:animation` to its own name and keys only
## frames that exist, and every frame has a texture.
func test_every_state_shows_real_frames_of_its_own_name() -> void:
	var sprite := _sprite()
	var player := sprite.get_node("AnimationPlayer") as AnimationPlayer
	var frames := (sprite.get_node("AnimatedSprite2D") as AnimatedSprite2D).sprite_frames
	for state in Locomotion.State.values():
		var name := Locomotion.state_name(state)
		if not player.has_animation(name) or not frames.has_animation(name):
			check(false, "%s has both an animation and frames" % name)
			continue
		var anim := player.get_animation(name)
		var shown := ""
		var indices: Array = []
		for i in anim.get_track_count():
			var path := str(anim.track_get_path(i))
			if path == "AnimatedSprite2D:animation":
				shown = str(anim.track_get_key_value(i, 0))
			elif path == "AnimatedSprite2D:frame":
				for k in anim.track_get_key_count(i):
					indices.append(int(anim.track_get_key_value(i, k)))
		check_eq(shown, name, "%s shows its own frames" % name)
		for index in indices:
			check(
				index >= 0 and index < frames.get_frame_count(name)
				and frames.get_frame_texture(name, index) != null,
				"%s frame %d exists and has a texture" % [name, index]
			)
	sprite.free()


## `dive_recovery_time` in config/ owns how long the pause is; the dive-landing
## animation is drawn to fit it. If one moves, the other has to.
func test_the_dive_landing_animation_fits_the_recovery_pause() -> void:
	var sprite := _sprite()
	var player := sprite.get_node("AnimationPlayer") as AnimationPlayer
	var movement: MovementConfig = load(MOVEMENT)
	check_near(
		player.get_animation("dive_land").length, movement.dive_recovery_time, 0.01,
		"the dive landing lasts the recovery pause"
	)
	sprite.free()


## M6's done-when: every state transitions into every other state it can reach.
## The Player can ask for any state from any other (a throw mid-dive, a death
## on a ladder), so every ordered pair needs a transition, or `travel` finds no
## path and the sprite freezes on the old state.
func test_every_state_can_travel_to_every_other_state() -> void:
	var sprite := _sprite()
	var machine := (sprite.get_node("AnimationTree") as AnimationTree).tree_root as AnimationNodeStateMachine
	var missing := 0
	for a in Locomotion.State.values():
		for b in Locomotion.State.values():
			var from := Locomotion.state_name(a)
			var to := Locomotion.state_name(b)
			if a != b and not machine.has_transition(from, to):
				missing += 1
				check(false, "no transition %s -> %s" % [from, to])
	if missing == 0:
		check(true, "all %d ordered pairs of states are joined" % (Locomotion.State.size() * (Locomotion.State.size() - 1)))
	sprite.free()
