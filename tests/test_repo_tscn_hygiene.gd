## Every `.tscn` and `.tres` file in the game, checked against TscnHygiene's
## rule: no key declared twice inside one resource block. PR #53 left exactly
## this behind in a merged file, harmless because the parser silently kept the
## later declaration, and this is the automated substitute for the fact that
## loading the resource can never show a hand-edit like that: only the raw
## text can.
extends TestCase

const SCANNED_EXTENSIONS: PackedStringArray = ["tscn", "tres"]
const SKIPPED_DIRECTORIES: PackedStringArray = [".git", ".godot", "assets", "export", "build"]


func test_no_resource_file_declares_the_same_key_twice_in_one_block() -> void:
	var paths := _scan("res://")
	check(paths.size() > 10, "scanned %d resource files" % paths.size())
	for path in paths:
		var text := FileAccess.get_file_as_string(path)
		for entry in TscnHygiene.duplicate_keys(text):
			check(
				false,
				"%s: \"%s\" is declared twice in %s" % [path, entry["key"], entry["block"]]
			)


func _scan(root: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var directory := DirAccess.open(root)
	if directory == null:
		return found
	directory.include_hidden = true
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = directory.get_next()
			continue
		var path := root.path_join(entry) if root != "res://" else "res://" + entry
		if directory.current_is_dir():
			if not SKIPPED_DIRECTORIES.has(entry):
				found.append_array(_scan(path))
		elif SCANNED_EXTENSIONS.has(entry.get_extension().to_lower()):
			found.append(path)
		entry = directory.get_next()
	directory.list_dir_end()
	return found
