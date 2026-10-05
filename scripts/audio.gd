## The mix, the music and the ambience, an autoload (`Audio`). Sets each bus
## to `config/audio.tres`'s level, plays the act's music and its ambience bed
## and crossfades each between acts, and muffles the music while the hero is
## dead. The effects themselves are played by whatever makes them (`Sfx`).
##
## Both follow the room: whatever the current scene's act names
## (`ActConfig.music`, `ActConfig.ambience`), unless the room names its own
## music in a `music` property, as the ending's flight does. Walking from one
## room of an act to the next leaves both running, because neither changed.
extends Node

const CONFIG: AudioConfig = preload("res://config/audio.tres")
const MUSIC_BUS := &"Music"
const SFX_BUS := &"Sfx"
const AMBIENCE_BUS := &"Ambience"
## Quiet enough to start a track from and stop one at, in decibels.
const SILENT_DB := -60.0
## Where a player's own levels are kept between sessions.
const SETTINGS := "user://settings.cfg"

var _muffle_left := 0.0
var _scene: Node = null
## The player's own level for each bus they can set, 0 to 1 of the mix's
## level in `config/audio.tres` (`level_db`). Set from the pause menu.
var levels: Dictionary = {MUSIC_BUS: 1.0, SFX_BUS: 1.0}
## What each bus is playing now, by bus name.
var _playing: Dictionary = {}
## The fades running now, so a quit can stop them.
var _fades: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved := ConfigFile.new()
	if saved.load(SETTINGS) == OK:
		for bus: StringName in levels:
			levels[bus] = clampf(float(saved.get_value("audio", String(bus), 1.0)), 0.0, 1.0)
	_apply_levels()


## Sets a player's level for `bus`, 0 to 1, and keeps it for next time.
func set_level(bus: StringName, level: float) -> void:
	levels[bus] = clampf(level, 0.0, 1.0)
	_apply_levels()
	var saved := ConfigFile.new()
	saved.load(SETTINGS)
	for each: StringName in levels:
		saved.set_value("audio", String(each), levels[each])
	saved.save(SETTINGS)


## A bus's level in decibels: the mix's own, scaled by what the player set.
## Silence at nothing; the effects' level also carries the ambience, which is
## a room sound like any other.
static func level_db(mix_db: float, level: float) -> float:
	if level <= 0.0:
		return SILENT_DB
	return mix_db + linear_to_db(level)


func _apply_levels() -> void:
	_set_bus_volume(MUSIC_BUS, level_db(CONFIG.music_volume_db, levels[MUSIC_BUS]))
	_set_bus_volume(SFX_BUS, level_db(CONFIG.sfx_volume_db, levels[SFX_BUS]))
	_set_bus_volume(AMBIENCE_BUS, level_db(CONFIG.ambience_volume_db, levels[SFX_BUS]))


## Quitting mid-fade leaves the fade's tween holding the track, and the track
## its stream, which Godot reports as a leak at exit. So the fades are killed
## and the tracks stopped on the way out.
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
## The ambience carries on: the room is still there under the card.
func fade_out() -> void:
	_crossfade(MUSIC_BUS, null)


## What is playing, for the capture tool and a test: the music's file and the
## ambience's, or "silence".
func status() -> String:
	return "music: %s, ambience: %s" % [_name_of(MUSIC_BUS), _name_of(AMBIENCE_BUS)]


func _name_of(bus: StringName) -> String:
	var player: AudioStreamPlayer = _playing.get(bus)
	if player == null or player.stream == null:
		return "silence"
	return player.stream.resource_path.get_file()


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
		_crossfade(MUSIC_BUS, music_for(scene))
		_crossfade(AMBIENCE_BUS, ambience_for(scene))


## The track a room plays: its own if it names one, else its act's.
func music_for(scene: Node) -> AudioStream:
	if scene == null:
		return null
	var own: Variant = scene.get("music")
	if own is AudioStream:
		return own
	var act := _act_of(scene)
	return act.music if act != null else null


## The bed under a room: its act's.
func ambience_for(scene: Node) -> AudioStream:
	var act := _act_of(scene)
	return act.ambience if act != null else null


func _act_of(scene: Node) -> ActConfig:
	var act_state := get_node_or_null("/root/ActState")
	if act_state == null or scene == null:
		return null
	return act_state.act_of(scene.scene_file_path)


## `stream`, set to loop. Music is an Ogg, and an Ogg's loop flag lives in its
## `.import` file, which this repo does not commit (`.gitignore`): set there,
## it would hold on one machine and nowhere else. So the code that plays a
## track is what makes it loop.
static func looping(stream: AudioStream) -> AudioStream:
	var ogg := stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = true
	return stream


## What `bus` is playing fades out over `music_fade_seconds` while `stream`,
## if any, fades in from silence. The same track asked for again carries on.
func _crossfade(bus: StringName, stream: AudioStream) -> void:
	var playing: AudioStreamPlayer = _playing.get(bus)
	if playing != null and playing.stream == stream:
		return
	if playing != null:
		var out := _fade()
		out.tween_property(playing, "volume_db", SILENT_DB, CONFIG.music_fade_seconds)
		out.tween_callback(playing.queue_free)
	_playing.erase(bus)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = looping(stream)
	player.bus = bus
	player.volume_db = SILENT_DB
	add_child(player)
	player.play()
	_playing[bus] = player
	_fade().tween_property(player, "volume_db", 0.0, CONFIG.music_fade_seconds)


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
