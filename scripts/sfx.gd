## How a sound effect is played: once, where it happened, on the effects bus,
## by whatever made it happen, in the same tick it happened (`ANIMATION.md`:
## an actor and its sound are one event off one tick, never two schedules).
##
## The player node goes into the room rather than under the actor, so a sound
## outlives the thing that made it: a sword that breaks frees itself the
## same frame its break starts sounding.
class_name Sfx

const CONFIG: AudioConfig = preload("res://config/audio.tres")
const BUS := &"Sfx"


## Plays `stream` at `at`'s position. `jitter` wanders the pitch a little, for
## sounds heard so often that one sample would start to grate. A null stream
## plays nothing, which is a real state: a bench may not wire every sound.
static func play(at: Node2D, stream: AudioStream, jitter: bool = false) -> AudioStreamPlayer2D:
	if stream == null or at == null or not at.is_inside_tree():
		return null
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS
	if jitter:
		player.pitch_scale = 1.0 + randf_range(-CONFIG.pitch_jitter, CONFIG.pitch_jitter)
	var room: Node = at.get_tree().current_scene
	if room == null:
		room = at.get_parent()
	room.add_child(player)
	player.global_position = at.global_position
	player.finished.connect(player.queue_free)
	player.play()
	return player
