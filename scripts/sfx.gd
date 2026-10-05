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


## A loop that sits on `owner` at `at` (its own coordinates) and is heard
## only near it: a lava pit's roar, an arc's buzz. `reach` widens how far it
## carries, for a thing as long as a lava pit. It starts with the room and
## stops with its owner; `playing` is the owner's to switch.
static func loop_on(owner: Node2D, stream: AudioStream, at: Vector2 = Vector2.ZERO, reach: float = 0.0, playing: bool = true) -> AudioStreamPlayer2D:
	if stream == null:
		return null
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS
	player.position = at
	player.max_distance = CONFIG.loop_reach + reach
	player.attenuation = CONFIG.loop_attenuation
	player.volume_db = CONFIG.loop_volume_db
	player.autoplay = playing
	owner.add_child(player)
	return player


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
