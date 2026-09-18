## Every `.gd` file in the game, checked against UntypedDeclarations' rule.
##
## Substitutes for Godot's own warnings-as-errors setting, which does not
## surface through this project's headless pipeline (see
## scripts/logic/untyped_declarations.gd for what was actually tried). The
## codebase is typed throughout by habit; this is what holds that habit in
## place once a script is written quickly and a type hint gets left off.
extends TestCase

const SKIPPED_DIRECTORIES: PackedStringArray = [".git", ".godot", "assets", "export", "build"]


func test_no_script_declares_an_untyped_variable() -> void:
	var paths := _scan("res://")
	check(paths.size() > 10, "scanned %d scripts" % paths.size())
	for path in paths:
		var text := FileAccess.get_file_as_string(path)
		for offender in UntypedDeclarations.find(text):
			check(false, "%s: %s" % [path, offender])


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
		elif entry.get_extension().to_lower() == "gd":
			found.append(path)
		entry = directory.get_next()
	directory.list_dir_end()
	return found
