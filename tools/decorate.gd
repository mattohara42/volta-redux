## Writes a level's `[decor]` section from `DecorRules` (N2), so decoration
## placed by rule lands in the file as text and is reviewed in its diff.
##
##     tools/dev.sh decorate levels/act1_wall.level castle
##     tools/dev.sh decorate levels/act1_wall.level castle --replace
##
## A level that already has a `[decor]` section is refused: it may carry hand
## edits, and replacing them is the destructive mode, so it is the flag
## (`CLAUDE.md`). Run it again after the map or the `[back]` changes.
extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var replace := args.has("--replace")
	var plain := Array(args).filter(func(a: String) -> bool: return not a.begins_with("--"))
	if plain.size() != 2 or not DecorRules.STYLES.has(plain[1]):
		printerr("usage: tools/dev.sh decorate LEVEL %s [--replace]" % "|".join(DecorRules.STYLES))
		quit(2)
		return
	var path: String = plain[0]
	if not path.begins_with("res://"):
		path = "res://" + path
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		printerr("decorate: cannot read %s" % path)
		quit(1)
		return
	var had := _without_decor(text)
	if had[1] and not replace:
		printerr("decorate: %s already has a [decor] section; --replace writes over it, hand edits and all" % path)
		quit(1)
		return
	var level := LevelGrid.parse(had[0])
	if not level.errors.is_empty():
		printerr("decorate: %s does not read cleanly: %s" % [path, level.errors])
		quit(1)
		return
	var grid := DecorRules.place(level, plain[1])
	var out: String = had[0].strip_edges(false, true) + "\n" + DecorRules.section(grid)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(out)
	file.close()
	var placed := 0
	for row in grid:
		placed += row.length() - row.count(".")
	print("decorate: wrote %d decorations into %s" % [placed, path])
	quit(0)


## The file without its `[decor]` section, and whether it had one.
func _without_decor(text: String) -> Array:
	var kept := PackedStringArray()
	var inside := false
	var had := false
	for line in text.split("\n"):
		var bare := line.strip_edges()
		if bare.begins_with("[") and bare.ends_with("]"):
			inside = bare == "[decor]"
			had = had or inside
		if not inside:
			kept.append(line)
	return ["\n".join(kept), had]
