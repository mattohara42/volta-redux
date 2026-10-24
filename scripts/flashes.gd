## How bright the storm's lightning may get, the player's own setting, 0 to 1
## (`BACKLOG.md`: for photosensitive players). At nothing the rain still falls
## and the thunder still cracks, and nothing on screen lights up.
##
## Kept between sessions in `Audio`'s settings file, beside the volume levels,
## and set from the pause menu. Read by `Storm` every frame, so a change shows
## on the next strike without leaving the room.
class_name Flashes
extends RefCounted

## The settings file, `Audio`'s, reached through its script so this works
## where the autoload does not exist yet.
const AUDIO := preload("res://scripts/audio.gd")
const SECTION := "display"
const KEY := "flashes"

static var _level := 1.0
static var _loaded := false


static func level() -> float:
	if not _loaded:
		_loaded = true
		var saved := ConfigFile.new()
		if saved.load(AUDIO.SETTINGS) == OK:
			_level = clampf(float(saved.get_value(SECTION, KEY, 1.0)), 0.0, 1.0)
	return _level


## Sets the level and keeps it for next time, leaving the file's other
## settings as they were.
static func set_level(value: float) -> void:
	_level = clampf(value, 0.0, 1.0)
	_loaded = true
	var saved := ConfigFile.new()
	saved.load(AUDIO.SETTINGS)
	saved.set_value(SECTION, KEY, _level)
	saved.save(AUDIO.SETTINGS)
