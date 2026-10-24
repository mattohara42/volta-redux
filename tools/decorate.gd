## Writes a level's `[decor]` section from `DecorRules` (N2), so decoration
## placed by rule lands in the file as text and is reviewed in its diff.
##
##     tools/dev.sh decorate levels/act1_wall.level castle
##     tools/dev.sh decorate levels/act1_wall.level castle --replace
##
## A level that already has a `[decor]` section is refused: it may carry hand
## edits, and replacing them is the destructive mode, so it is the flag
## (`CLAUDE.md`). Run it again after the map or the `[back]` changes.
##
##     tools/dev.sh decorate levels/act1_wall.level castle --add=slit,ivy
##
## `--add` keeps every cell the file already has and writes only the named
## kinds, only into cells it leaves empty: how a new rule reaches a level
## that has been edited by hand without undoing the edits.
extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var replace := args.has("--replace")
	var add := PackedStringArray()
	for a: String in args:
		if a.begins_with("--add="):
			add = a.trim_prefix("--add=").split(",", false)
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
	if had[1] and not replace and add.is_empty():
		printerr("decorate: %s already has a [decor] section; --replace writes over it, hand edits and all" % path)
		quit(1)
		return
	var level := LevelGrid.parse(had[0])
	if not level.errors.is_empty():
		printerr("decorate: %s does not read cleanly: %s" % [path, level.errors])
		quit(1)
		return
	var grid := DecorRules.place(level, plain[1])
	if not add.is_empty():
		grid = _merged(LevelGrid.parse(text), grid, add)
	var out: String = had[0].strip_edges(false, true) + "\n" + DecorRules.section(grid)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(out)
	file.close()
	var placed := 0
	for row in grid:
		placed += row.length() - row.count(".")
	print("decorate: wrote %d decorations into %s" % [placed, path])
	quit(0)


## The file's own `[decor]`, with each cell of `kinds` from `placed` written
## into the cells it leaves empty.
func _merged(level: LevelGrid.Level, placed: Array[String], kinds: PackedStringArray) -> Array[String]:
	var grid: Array[String] = []
	for row in placed:
		grid.append(DecorRules.AIR.repeat(row.length()))
	for c: String in LevelGrid.DECOR:
		for at: Vector2i in level.decor_cells(LevelGrid.DECOR[c]):
			var row := grid[at.y]
			row[at.x] = c
			grid[at.y] = row
	for y in placed.size():
		for x in placed[y].length():
			var c := placed[y][x]
			if c != DecorRules.AIR and kinds.has(LevelGrid.DECOR.get(c, "")) and grid[y][x] == DecorRules.AIR:
				var row := grid[y]
				row[x] = c
				grid[y] = row
	return grid


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
