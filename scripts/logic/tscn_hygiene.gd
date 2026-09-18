## Finds a key declared twice inside one resource block of a `.tscn` or
## `.tres` file's raw text.
##
## PR #53's bug: a hand edit replaced `run`'s `Hip:position:y` and
## `Neck:rotation` tracks but left the old `tracks/N/...` lines sitting in the
## same `[sub_resource type="Animation" ...]` block. Godot's resource parser
## lets the later declaration win, so nothing broke, but the file carried dead,
## confusing content that nobody would have caught by loading the scene: the
## loaded resource only ever shows one track per index, never both. This has
## to be a text-level check for exactly that reason.
class_name TscnHygiene

## Matches a real property assignment at the start of a line: an identifier
## made of letters, digits, underscore, slash or period, then `=`. Deliberately
## excludes `:`, which is how a multi-line dictionary literal's own entries are
## written (`"times": PackedFloat32Array(...)`), so a continuation line is
## never mistaken for a second top-level key.
const KEY_PATTERN := "^([A-Za-z_][A-Za-z0-9_./]*)\\s*="


## Returns one entry per duplicate found: {"block": the enclosing `[...]`
## header, "key": the property declared twice}. Empty means the file is clean.
static func duplicate_keys(text: String) -> Array[Dictionary]:
	var key_regex := RegEx.new()
	key_regex.compile(KEY_PATTERN)

	var duplicates: Array[Dictionary] = []
	var current_block := ""
	var seen: Dictionary = {}
	for line in text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("[") and trimmed.ends_with("]"):
			current_block = trimmed
			seen = {}
			continue
		var match_result := key_regex.search(trimmed)
		if match_result == null:
			continue
		var key := match_result.get_string(1)
		if seen.has(key):
			duplicates.append({"block": current_block, "key": key})
		else:
			seen[key] = true
	return duplicates
