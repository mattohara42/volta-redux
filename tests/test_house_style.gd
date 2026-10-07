## CLAUDE.md: no em-dashes, anywhere. Docs, code comments, commit messages, PR
## bodies and any string a player reads.
##
## The last project needed a 1,619-replacement pass to fix this after the fact,
## which is the entire argument for putting the test on it in M0. The character
## is built from its code point so that this file does not fail itself.
extends TestCase

const SCANNED_EXTENSIONS: PackedStringArray = [
	"md", "gd", "level", "tres", "tscn", "godot", "yml", "yaml", "cfg", "txt", "json", "sh",
]
const SKIPPED_DIRECTORIES: PackedStringArray = [
	".git", ".godot", "assets", "export", "build",
]


func test_no_file_in_the_repository_contains_an_em_dash() -> void:
	var em_dash := String.chr(0x2014)
	var offenders: PackedStringArray = []
	for path in _scan("res://"):
		var text := FileAccess.get_file_as_string(path)
		if text.contains(em_dash):
			offenders.append(path)
	check(
		offenders.is_empty(),
		"em-dash found in: %s" % ", ".join(offenders)
	)


## Proves the scan reaches something, so an empty sweep can never pass quietly.
func test_the_scan_actually_reads_files() -> void:
	var paths := _scan("res://")
	check(paths.size() > 10, "scanned %d files" % paths.size())
	check(paths.has("res://CLAUDE.md"), "the scan reaches the docs at the root")
	check(paths.has("res://scripts/player.gd"), "the scan reaches the scripts")


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
