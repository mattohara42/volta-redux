## The keys, checked against the keys the overlay advertises.
##
## `debug_next_preset` shipped bound to physical keycode 9 rather than KEY_TAB
## (4194306), so Tab did nothing and M0's jump-versus-ladders question could not
## be answered by playing at all. Forty tests passed the whole time, because a
## keybinding is one of the things CLAUDE.md means by "an assertion proves the
## code ran, not that the picture is right". This file is the cheap half of
## drawing it: it cannot tell you Tab feels wrong, only that Tab is Tab.
extends TestCase

## Every action, and the physical keys `DebugOverlay.LEGEND` and the docstrings
## in `room_m0.gd` promise it is on. Add a row here when you add an action.
const KEYS_BY_ACTION := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"climb_up": [KEY_W, KEY_UP],
	"climb_down": [KEY_S, KEY_DOWN],
	"throw": [KEY_J],
	"debug_next_preset": [KEY_TAB],
	"debug_size_down": [KEY_BRACKETLEFT],
	"debug_size_up": [KEY_BRACKETRIGHT],
	"debug_respawn": [KEY_R],
	"debug_toggle_overlay": [KEY_F1],
	"debug_next_bench": [KEY_F2],
	"pause": [KEY_ESCAPE],
}

const SCRIPT_ROOTS: PackedStringArray = ["res://scripts", "res://tools"]


func test_every_action_is_bound_to_the_key_it_advertises() -> void:
	for action: String in KEYS_BY_ACTION:
		if not InputMap.has_action(action):
			check(false, "%s is in the input map" % action)
			continue
		check_eq(
			_keys_bound_to(action), _readable(KEYS_BY_ACTION[action]),
			"%s is bound to the key it advertises" % action
		)


## A key doing two jobs is the same class of bug as a key doing none, and it is
## just as invisible until somebody plays.
func test_no_physical_key_does_two_jobs() -> void:
	var owner_of: Dictionary = {}
	for action: String in KEYS_BY_ACTION:
		for key: int in KEYS_BY_ACTION[action]:
			var name := OS.get_keycode_string(key)
			check(
				not owner_of.has(name),
				"%s is bound to %s alone (also on %s)" % [name, action, owner_of.get(name, "")]
			)
			owner_of[name] = action


## The other direction: an action the code polls for but nothing binds is silent
## at runtime, because `Input.is_action_just_pressed` on an unknown action is
## false rather than an error.
func test_every_action_the_code_polls_for_exists() -> void:
	var pattern := RegEx.create_from_string('is_action(?:_just)?_(?:pressed|released)\\("([a-z_]+)"\\)')
	var polled: PackedStringArray = []
	for path in _scripts():
		for found in pattern.search_all(FileAccess.get_file_as_string(path)):
			var action := found.get_string(1)
			check(
				InputMap.has_action(action),
				"%s polls for the action %s, which is bound" % [path.get_file(), action]
			)
			if not polled.has(action):
				polled.append(action)
	# Proves the sweep reached the scripts, so a broken regex cannot pass quietly.
	check(polled.size() >= 8, "the sweep found %d actions in the scripts" % polled.size())
	check(polled.has("debug_next_preset"), "the sweep reaches the debug keys")


func _keys_bound_to(action: String) -> String:
	var keys: Array = []
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			keys.append(key.physical_keycode)
	return _readable(keys)


## Names rather than numbers, because "got 9, wanted 4194306" is the failure
## message that made this bug hard to see in the first place.
func _readable(keys: Array) -> String:
	var names: PackedStringArray = []
	for key: int in keys:
		names.append(OS.get_keycode_string(key))
	names.sort()
	return ", ".join(names)


func _scripts() -> PackedStringArray:
	var found: PackedStringArray = []
	for root in SCRIPT_ROOTS:
		found.append_array(_walk(root))
	found.sort()
	return found


func _walk(root: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var directory := DirAccess.open(root)
	if directory == null:
		return found
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var path := root.path_join(entry)
		if directory.current_is_dir():
			found.append_array(_walk(path))
		elif entry.ends_with(".gd"):
			found.append(path)
		entry = directory.get_next()
	directory.list_dir_end()
	return found
