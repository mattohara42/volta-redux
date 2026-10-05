## The mix, an autoload (`Audio`): sets the music and effects buses to
## `config/audio.tres`'s levels, and muffles the music while the hero is dead.
## The sounds themselves are played by whatever makes them (`Sfx`).
extends Node

const CONFIG: AudioConfig = preload("res://config/audio.tres")
const MUSIC_BUS := &"Music"
const SFX_BUS := &"Sfx"

var _muffle_left := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_bus_volume(MUSIC_BUS, CONFIG.music_volume_db)
	_set_bus_volume(SFX_BUS, CONFIG.sfx_volume_db)


## The music goes dull for a moment: a death, heard as well as seen.
func muffle() -> void:
	_muffle_left = CONFIG.death_muffle_seconds
	_set_muffled(true)


func _process(delta: float) -> void:
	if _muffle_left <= 0.0:
		return
	_muffle_left -= delta
	if _muffle_left <= 0.0:
		_set_muffled(false)


func _set_muffled(on: bool) -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus >= 0 and AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.set_bus_effect_enabled(bus, 0, on)


func _set_bus_volume(bus_name: StringName, volume_db: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, volume_db)
