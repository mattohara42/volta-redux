## A level written as text (Matt, 2026-10-06: `LEVELS.md`), read into the
## rectangles and placements `Bench` already knows how to build. Pure, so a
## test can read a level the way the game does.
##
## A level file has a `[map]`, one character per cell, and a `[things]` list
## for anything with numbers or wiring attached:
##
##     size 16
##     height 360         (optional: the room's height, if not the map's)
##     [map]
##     ...........G........
##     .@.B.C..w..G.....E..
##     ####################
##     [things]
##     G gate
##
## The map's characters:
##
##     .  air                    #  stone, drawn as ground
##     %  stone, drawn as wall   w  wood (a sword sticks in it)
##     ~  lava                   ^  spikes, standing on the cell below
##     =  a falling slab         H  a ladder, filling the air it climbs
##     @  where the hero starts  B  a brazier   C  a chest   E  the exit
##
## Any other capital letter or digit is an anchor: every cell carrying it
## makes one rectangle, and a line in `[things]` says what it is. A line is
## `<anchor> <kind> key=value ...`. The kinds a `GridRoom` builds:
##
##     gate                     a portcullis
##     switch opens=G           wood a sword holds down, opening gate G
##     scorpion range=96        a patrol; `dormant` asleep until you come near
##     bat                      flies about the rect it fills
##     stump to=U               land on it, come up on stump U (one way)
##     stump                    a stump that leads nowhere, or a warp's end
##
## Every placement stands on the bottom of its cell: a brazier, a chest, the
## hero's feet and the exit all sit on whatever is below. A ladder's top is the
## top of its highest `H`, which is the surface it serves.
class_name LevelGrid
extends RefCounted

const AIR := "."
const MATERIALS := "#%w~^="
const MARKERS := "@BCEH"


class Thing:
	extends RefCounted
	var anchor := ""
	var kind := ""
	var rect := Rect2()
	var params := {}

	func number(key: String, fallback: float) -> float:
		return float(params[key]) if params.has(key) else fallback

	func size(key: String, fallback: Vector2) -> Vector2:
		if not params.has(key):
			return fallback
		var parts := String(params[key]).split("x")
		return Vector2(float(parts[0]), float(parts[1])) if parts.size() == 2 else fallback

	func flag(key: String) -> bool:
		return params.has(key)


class Level:
	extends RefCounted
	var cell := 16.0
	var size := Vector2.ZERO
	## How tall the room is, if the file says (`height 360`); otherwise the
	## map's own height. A one-screen room's map overhangs by half a row,
	## since 360 is not a whole number of 16 px rows.
	var height := 0.0
	var ground: Array[Rect2] = []
	var walls: Array[Rect2] = []
	## The same stone, merged down each column first, for drawing: every top
	## edge of one of these is a real surface, where the row-first merge above
	## (fewer pieces, for collision) leaves seams that would draw as ledges.
	var ground_faces: Array[Rect2] = []
	var wall_faces: Array[Rect2] = []
	var wood: Array[Rect2] = []
	var lava: Array[Rect2] = []
	var spikes: Array[Rect2] = []
	var falling: Array[Rect2] = []
	var ladders: Array[Rect2] = []
	var start := Vector2.ZERO
	var has_start := false
	var braziers: Array[Vector2] = []
	var chests: Array[Vector2] = []
	var exit := Rect2()
	var things: Array[Thing] = []
	var errors: Array[String] = []

	## Everything solid: ground, walls and wood.
	func solids() -> Array[Rect2]:
		var all: Array[Rect2] = []
		all.append_array(ground)
		all.append_array(walls)
		all.append_array(wood)
		return all

	func thing(anchor: String) -> Thing:
		for t in things:
			if t.anchor == anchor:
				return t
		return null

	func of_kind(kind: String) -> Array[Thing]:
		var found: Array[Thing] = []
		for t in things:
			if t.kind == kind:
				found.append(t)
		return found


static func parse(text: String) -> Level:
	var level := Level.new()
	var rows: Array[String] = []
	var lines: Array[String] = []
	var section := ""
	for raw in text.split("\n"):
		var line := raw.strip_edges(false, true)
		var bare := line.strip_edges()
		if bare.begins_with("[") and bare.ends_with("]"):
			section = bare
			continue
		if section == "[map]":
			if not bare.is_empty():
				rows.append(line.replace(" ", AIR))
			continue
		if bare.is_empty() or bare.begins_with("#"):
			continue
		if section == "[things]":
			lines.append(bare)
		elif bare.begins_with("size "):
			level.cell = float(bare.substr(5))
		elif bare.begins_with("height "):
			level.height = float(bare.substr(7))
	if rows.is_empty():
		level.errors.append("no [map]")
		return level
	var width := 0
	for row in rows:
		width = maxi(width, row.length())
	level.size = Vector2(width, rows.size()) * level.cell
	if level.height <= 0.0:
		level.height = level.size.y

	var cells := {}
	for y in rows.size():
		for x in rows[y].length():
			var c := rows[y][x]
			if c == AIR:
				continue
			if not cells.has(c):
				cells[c] = []
			cells[c].append(Vector2i(x, y))

	level.ground = _merged(rows, "#", level.cell)
	level.walls = _merged(rows, "%", level.cell)
	level.ground_faces = _merged_down(rows, "#", level.cell)
	level.wall_faces = _merged_down(rows, "%", level.cell)
	level.wood = _merged(rows, "w", level.cell)
	level.lava = _merged(rows, "~", level.cell)
	level.spikes = _merged(rows, "^", level.cell)
	level.falling = _merged(rows, "=", level.cell)
	level.ladders = _merged(rows, "H", level.cell)

	var anchors := {}
	for c: String in cells:
		var at: Array = cells[c]
		match c:
			"@":
				level.start = _stand(at[0], level.cell)
				level.has_start = true
			"B":
				for p: Vector2i in at:
					level.braziers.append(_stand(p, level.cell))
			"C":
				for p: Vector2i in at:
					level.chests.append(_stand(p, level.cell))
			"E":
				level.exit = _bounds(at, level.cell)
			_:
				if MATERIALS.contains(c) or c == "H":
					continue
				if c == c.to_upper() and c != c.to_lower() or c.is_valid_int():
					anchors[c] = _bounds(at, level.cell)
				else:
					level.errors.append("unknown map character '%s'" % c)

	for line in lines:
		var words := line.split(" ", false)
		if words.size() < 2:
			level.errors.append("a thing needs an anchor and a kind: '%s'" % line)
			continue
		var t := Thing.new()
		t.anchor = words[0]
		t.kind = words[1]
		for i in range(2, words.size()):
			var pair := words[i].split("=")
			t.params[pair[0]] = pair[1] if pair.size() > 1 else true
		if not anchors.has(t.anchor):
			level.errors.append("thing '%s' has no anchor in the map" % t.anchor)
			continue
		t.rect = anchors[t.anchor]
		level.things.append(t)
	for a: String in anchors:
		if level.thing(a) == null:
			level.errors.append("anchor '%s' in the map has no line in [things]" % a)
	return level


## Every cell of `c`, as few rectangles as a row-then-column merge makes:
## runs along each row, then runs of the same span stacked down the rows.
static func _merged(rows: Array[String], c: String, cell: float) -> Array[Rect2]:
	var open := {}
	var done: Array[Rect2] = []
	for y in rows.size():
		var runs := {}
		var x := 0
		var row := rows[y]
		while x < row.length():
			if row[x] != c:
				x += 1
				continue
			var start := x
			while x < row.length() and row[x] == c:
				x += 1
			runs[Vector2i(start, x)] = true
		var still := {}
		for span: Vector2i in open:
			if runs.has(span):
				still[span] = open[span]
			else:
				done.append(_span_rect(span, open[span], y, cell))
		for span: Vector2i in runs:
			if not still.has(span):
				still[span] = y
		open = still
	for span: Vector2i in open:
		done.append(_span_rect(span, open[span], rows.size(), cell))
	done.sort_custom(func(a: Rect2, b: Rect2) -> bool:
		return a.position.y < b.position.y or (a.position.y == b.position.y and a.position.x < b.position.x))
	return done


## The same cells, merged down each column first and then across, so pieces
## break only where a surface does.
static func _merged_down(rows: Array[String], c: String, cell: float) -> Array[Rect2]:
	var width := 0
	for row in rows:
		width = maxi(width, row.length())
	var columns: Array[String] = []
	for x in width:
		var column := ""
		for row in rows:
			column += row[x] if x < row.length() else AIR
		columns.append(column)
	var flipped: Array[Rect2] = []
	for rect in _merged(columns, c, cell):
		flipped.append(Rect2(rect.position.y, rect.position.x, rect.size.y, rect.size.x))
	return flipped


static func _span_rect(span: Vector2i, top: int, bottom: int, cell: float) -> Rect2:
	return Rect2(span.x * cell, top * cell, (span.y - span.x) * cell, (bottom - top) * cell)


## The middle of the bottom of a cell: where something standing in it stands.
static func _stand(p: Vector2i, cell: float) -> Vector2:
	return Vector2((p.x + 0.5) * cell, (p.y + 1) * cell)


static func _bounds(at: Array, cell: float) -> Rect2:
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-1, -1)
	for p: Vector2i in at:
		lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
		hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
	return Rect2(Vector2(lo) * cell, Vector2(hi - lo + Vector2i.ONE) * cell)
