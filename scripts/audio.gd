## The mix and the music, an autoload (`Audio`). Sets the music and effects
## buses to `config/audio.tres`'s levels, plays each act's loop and crossfades
## between them, and muffles the music while the hero is dead. The effects
## themselves are played by whatever makes them (`Sfx`).
##
## The music follows the room: whatever the current scene's act names
## (`ActConfig.music`), unless the room names its own in a `music` property,
## as the ending's flight does. Walking from one room of an act to the next
## leaves the music running, because the track has not changed.
extends Node

const CONFIG: AudioConfig = preload("res://config/audio.tres")
const MUSIC_BUS := &"Music"
const SFX_BUS := &"Sfx"
## Quiet enough to start a track from and stop one at, in decibels.
const SILENT_DB := -60.0

var _muffle_left := 0.0
var _scene: Node = null
var _playing: AudioStreamPlayer = null
## The fades running now, so a quit can stop them.
var _fades: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_bus_volume(MUSIC_BUS, CONFIG.music_volume_db)
	_set_bus_volume(SFX_BUS, CONFIG.sfx_volume_db)


## Quitting mid-fade leaves the fade's tween holding the track, and the track
## its stream, which Godot reports as a leak at exit. So the fades are killed
## and the music stopped on the way out.
func _exit_tree() -> void:
	for tween in _fades:
		if tween.is_valid():
			tween.kill()
	_fades.clear()
	for child in get_children():
		var player := child as AudioStreamPlayer
		if player != null:
			player.stop()
			player.stream = null


## The music goes dull for a moment: a death, heard as well as seen.
func muffle() -> void:
	_muffle_left = CONFIG.death_muffle_seconds
	_set_muffled(true)


## The music fades away under an act's card, until the next room asks again.
func fade_out() -> void:
	_crossfade(null)


## What is playing, for the capture tool and a test: the track's file, or
## "silence".
func status() -> String:
	if _playing == null or _playing.stream == null:
		return "music: silence"
	return "music: %s" % _playing.stream.resource_path.get_file()


func _process(delta: float) -> void:
	if _muffle_left > 0.0:
		_muffle_left -= delta
		if _muffle_left <= 0.0:
			_set_muffled(false)
	var scene := get_tree().current_scene
	# Between two rooms there is a frame with no scene at all. Answering it
	# would fade the act's music out and straight back in at every door.
	if scene != null and scene != _scene:
		_scene = scene
		_crossfade(music_for(scene))


## The track a room plays: its own if it names one, else its act's.
func music_for(scene: Node) -> AudioStream:
	if scene == null:
		return null
	var own: Variant = scene.get("music")
	if own is AudioStream:
		return own
	var act_state := get_node_or_null("/root/ActState")
	if act_state == null:
		return null
	var act: ActConfig = act_state.act_of(scene.scene_file_path)
	return act.music if act != null else null


## `stream`, set to loop. Music is an Ogg, and an Ogg's loop flag lives in its
## `.import` file, which this repo does not commit (`.gitignore`): set there,
## it would hold on one machine and nowhere else. So the code that plays a
## track is what makes it loop.
static func looping(stream: AudioStream) -> AudioStream:
	var ogg := stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = true
	return stream


## The playing track fades out over `music_fade_seconds` while `stream`, if
## any, fades in from silence. The same track asked for again carries on.
func _crossfade(stream: AudioStream) -> void:
	if _playing != null and _playing.stream == stream:
		return
	if _playing != null:
		var leaving := _playing
		var out := _fade()
		out.tween_property(leaving, "volume_db", SILENT_DB, CONFIG.music_fade_seconds)
		out.tween_callback(leaving.queue_free)
	_playing = null
	if stream == null:
		return
	_playing = AudioStreamPlayer.new()
	_playing.stream = looping(stream)
	_playing.bus = MUSIC_BUS
	_playing.volume_db = SILENT_DB
	add_child(_playing)
	_playing.play()
	_fade().tween_property(_playing, "volume_db", 0.0, CONFIG.music_fade_seconds)


func _fade() -> Tween:
	_fades = _fades.filter(func(tween: Tween) -> bool: return tween.is_valid())
	var tween := create_tween()
	_fades.append(tween)
	return tween


func _set_muffled(on: bool) -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus >= 0 and AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.set_bus_effect_enabled(bus, 0, on)


func _set_bus_volume(bus_name: StringName, volume_db: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, volume_db)
