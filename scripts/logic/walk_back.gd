## Can you always walk back to where a room starts? (`SPEC.md`, Matt 2026-10-06.)
##
## A room is reduced to the surfaces a hero can stand on, and the moves between
## them: walking along one, jumping or stepping off it on a real arc (the same
## gravity and run speed as `Motion`), climbing a ladder, riding a ferry, being
## thrown up a geyser. Going forward the hero may also stand on a sword thrown
## into wood or metal. Going back may not: a route home that needs a trick is
## the drop the kids got stuck behind.
##
## What it reports is every surface you can reach from the start that has no
## way back to it. It also says whether the exit was reached at all, which is
## the check on the checker: a model too strict to cross a room that CI
## already crosses would flag drops that are not there.
##
## Deliberately generous where a room is dynamic: gates count as open, falling
## slabs as present, ferries as docked at either end, live metal as dead and a
## lava tide as low. Each of those is a way back only some of the time, and
## timing is the room's puzzle, not a wall.
class_name WalkBack
extends RefCounted

## How often a takeoff is tried along a surface, px.
const STEP_X: float = 8.0
## Simulation step, s. Small enough that no wall is thinner than a step.
const DT: float = 1.0 / 60.0
## Never simulate a jump longer than this, s.
const MAX_AIR: float = 3.0
## Fractions of run speed tried for each takeoff. Air control means anything
## in between is possible; these are enough to land short, middling and long.
const SPEEDS: Array[float] = [1.0, 0.55, 0.25, 0.0]
## How far a ladder may sit from a surface's end and still serve it, px.
const LADDER_SLACK: float = 4.0
## How many rounds of sword ledges thrown from ledges.
const LEDGE_ROUNDS: int = 3


## What a room is made of, as far as moving through it goes.
class Layout:
	extends RefCounted
	## Anything you stand on: stone, wood, metal, pedestals, slabs.
	var solids: Array[Rect2] = []
	## The solids a sword sticks in.
	var embeddable: Array[Rect2] = []
	## Lava, spike beds and barriers.
	var deadly: Array[Rect2] = []
	var ladders: Array[Rect2] = []
	## A ferry's slab at its near dock, and how far it travels to the far one.
	var ferries: Array[Rect2] = []
	var ferry_travel: Array[Vector2] = []
	## A geyser's shaft: its bottom is the vent, its top as high as it throws.
	var geysers: Array[Rect2] = []
	## The hero's feet where the room starts them.
	var start := Vector2.ZERO
	## The exit, or an empty rect for a room whose exit comes later.
	var exit := Rect2()


## The movement numbers, all from `config/`.
class Moves:
	extends RefCounted
	var jump_height: float = 56.0
	var time_to_apex: float = 0.2546
	var fall_multiplier: float = 1.6
	var run_speed: float = 200.0
	var max_fall_speed: float = 700.0
	var hero_width: float = 18.0
	var hero_height: float = 36.0
	var sword_range: float = 200.0
	var sword_length: float = 16.0


## A surface: `position.y` is its top, `position.x` to `end.x` is where the
## middle of a hero can stand. Zero height.
class Report:
	extends RefCounted
	var surfaces: Array[Rect2] = []
	## Surfaces reachable from the start that cannot get back to it.
	var stranded: Array[Rect2] = []
	var exit_reached := false
	var start_found := false


static func check(layout: Layout, moves: Moves) -> Report:
	var report := Report.new()
	# A ferry's slab is something to stand on at either dock.
	var standing := layout.solids.duplicate()
	for f in layout.ferries.size():
		standing.append(layout.ferries[f])
		standing.append(Rect2(layout.ferries[f].position + layout.ferry_travel[f], layout.ferries[f].size))
	var base := surfaces_of(standing, layout.deadly, moves.hero_height)
	report.surfaces = base
	var start := _surface_under(base, layout.start)
	report.start_found = start >= 0
	if start < 0:
		return report

	# Home: no swords. Forward: the same, plus every ledge a throw can make.
	var home := _moves_between(base, layout, moves, [])
	var ledges := _ledges(base, layout, moves)
	var all := base.duplicate()
	all.append_array(ledges)
	var forward := _moves_between(all, layout, moves, ledges)

	var reached := _reach(forward, [start])
	var back := _reach(_reversed(home, base.size()), [start])
	for i in reached:
		if i < base.size() and not back.has(i):
			report.stranded.append(base[i])
	report.exit_reached = layout.exit.size == Vector2.ZERO
	for i in reached:
		if _serves_exit(all[i], layout.exit):
			report.exit_reached = true
	return report


## Every surface a hero fits on: the top of each solid, less any part with
## something solid or deadly in the hero's height above it, joined where two
## solids meet level.
static func surfaces_of(solids: Array[Rect2], deadly: Array[Rect2], hero_height: float) -> Array[Rect2]:
	var spans: Array[Rect2] = []
	for solid in solids:
		var y := solid.position.y
		var pieces: Array[Vector2] = [Vector2(solid.position.x, solid.end.x)]
		var blockers: Array[Rect2] = []
		for other in solids:
			if other != solid and other.position.y < y - 0.5 and other.end.y > y - hero_height:
				blockers.append(other)
		for hazard in deadly:
			if hazard.position.y < y + 1.0 and hazard.end.y > y - hero_height:
				blockers.append(hazard)
		for blocker in blockers:
			pieces = _cut(pieces, blocker.position.x, blocker.end.x)
		for piece in pieces:
			if piece.y - piece.x >= 1.0:
				spans.append(Rect2(piece.x, y, piece.y - piece.x, 0.0))
	return _join(spans)


## The sword ledges a throw can make: from anywhere on a surface, left or
## right at body height, the first solid within range, if a sword sticks in
## it. Ledges thrown from ledges too, a few rounds deep.
static func _ledges(base: Array[Rect2], layout: Layout, moves: Moves) -> Array[Rect2]:
	var found: Array[Rect2] = []
	var from: Array[Rect2] = base.duplicate()
	for _round in LEDGE_ROUNDS:
		var fresh: Array[Rect2] = []
		for surface in from:
			for x in _samples(surface):
				var y := surface.position.y - moves.hero_height * 0.5
				for dir: float in [-1.0, 1.0]:
					var ledge := _throw(Vector2(x, y), dir, layout, moves)
					if ledge.size.x > 0.0 and not _has(found, ledge) and not _has(fresh, ledge):
						fresh.append(ledge)
		if fresh.is_empty():
			break
		found.append_array(fresh)
		from = fresh
	return found


## Where a sword thrown from `at` along `dir` ends up as a ledge, or an empty
## rect if it hits nothing it sticks in.
static func _throw(at: Vector2, dir: float, layout: Layout, moves: Moves) -> Rect2:
	var best := INF
	var hit := Rect2()
	for solid in layout.solids:
		if at.y <= solid.position.y or at.y >= solid.end.y:
			continue
		var face := solid.position.x if dir > 0.0 else solid.end.x
		var distance := (face - at.x) * dir
		if distance >= 0.0 and distance < best:
			best = distance
			hit = solid
	if best > moves.sword_range or not layout.embeddable.has(hit):
		return Rect2()
	var face_x := hit.position.x if dir > 0.0 else hit.end.x
	var y := snappedf(at.y, 1.0)
	if dir > 0.0:
		return Rect2(face_x - moves.sword_length, y, moves.sword_length, 0.0)
	return Rect2(face_x, y, moves.sword_length, 0.0)


## For each surface, the surfaces one move takes it to.
static func _moves_between(
	surfaces: Array[Rect2], layout: Layout, moves: Moves, ledges: Array[Rect2]
) -> Array[PackedInt32Array]:
	var edges: Array[PackedInt32Array] = []
	for i in surfaces.size():
		edges.append(PackedInt32Array())
	# Ledges are somewhere to land, never in the way: every ledge a throw could
	# make, all at once, would wall off the face they are thrown into.
	var floors := layout.solids
	for i in surfaces.size():
		var surface := surfaces[i]
		var takeoffs := _samples(surface)
		for x in takeoffs:
			for dir: float in [-1.0, 1.0]:
				for speed in SPEEDS:
					var vx := dir * speed * moves.run_speed
					_link(edges, i, _fly(Vector2(x, surface.position.y), vx, true, surfaces, floors, layout.deadly, moves))
		# Stepping off either end without jumping.
		for dir: float in [-1.0, 1.0]:
			var edge_x := surface.end.x if dir > 0.0 else surface.position.x
			for speed in SPEEDS:
				if speed > 0.0:
					var feet := Vector2(edge_x + dir * moves.hero_width * 0.5, surface.position.y)
					_link(edges, i, _fly(feet, dir * speed * moves.run_speed, false, surfaces, floors, layout.deadly, moves))
	_ladders(edges, surfaces, layout.ladders)
	_ferries(edges, surfaces, layout, moves)
	_geysers(edges, surfaces, floors, layout, moves)
	return edges


## One arc, from feet at `feet` with run speed `vx`, jumping or just falling.
## Returns the surface it lands on, or -1 for a death or nowhere.
static func _fly(
	feet: Vector2, vx: float, jumping: bool, surfaces: Array[Rect2],
	solids: Array[Rect2], deadly: Array[Rect2], moves: Moves
) -> int:
	var gravity := Motion.gravity_for(moves.jump_height, moves.time_to_apex)
	var vy := -Motion.jump_speed_for(moves.jump_height, moves.time_to_apex) if jumping else 0.0
	var pos := feet
	var w := moves.hero_width * 0.5
	var h := moves.hero_height
	var t := 0.0
	while t < MAX_AIR:
		t += DT
		var g := gravity if vy < 0.0 else gravity * moves.fall_multiplier
		vy = minf(vy + g * DT, moves.max_fall_speed)
		# Against a wall the hero keeps pushing, and slides up past its top.
		var next_x := pos.x + vx * DT
		if _hits(Rect2(next_x - w, pos.y - h, w * 2.0, h - 1.0), solids):
			next_x = pos.x
		var next_y := pos.y + vy * DT
		if vy < 0.0 and _hits(Rect2(next_x - w, next_y - h, w * 2.0, 1.0), solids):
			vy = 0.0
			next_y = pos.y
		if vy > 0.0:
			for i in surfaces.size():
				var s := surfaces[i]
				if pos.y <= s.position.y + 0.01 and next_y >= s.position.y - 0.01 \
						and next_x >= s.position.x and next_x <= s.end.x:
					return i
		pos = Vector2(next_x, next_y)
		if _hits(Rect2(pos.x - w, pos.y - h, w * 2.0, h), deadly):
			return -1
		if vy > 0.0 and pos.y > 4000.0:
			return -1
	return -1


static func _ladders(edges: Array[PackedInt32Array], surfaces: Array[Rect2], ladders: Array[Rect2]) -> void:
	for ladder in ladders:
		var served := PackedInt32Array()
		for i in surfaces.size():
			var s := surfaces[i]
			if s.position.y >= ladder.position.y - 0.5 and s.position.y <= ladder.end.y + 0.5 \
					and s.position.x <= ladder.end.x + LADDER_SLACK and s.end.x >= ladder.position.x - LADDER_SLACK:
				served.append(i)
		for a in served:
			for b in served:
				if a != b:
					_link(edges, a, b)


## A ferry's slab is a surface at each dock, and riding it joins the two.
## Whatever is level with a dock and reachable from it is reached by the arcs.
static func _ferries(edges: Array[PackedInt32Array], surfaces: Array[Rect2], layout: Layout, moves: Moves) -> void:
	for f in layout.ferries.size():
		var near := layout.ferries[f]
		var far := Rect2(near.position + layout.ferry_travel[f], near.size)
		var a := _surface_under(surfaces, Vector2(near.get_center().x, near.position.y))
		var b := _surface_under(surfaces, Vector2(far.get_center().x, far.position.y))
		if a >= 0 and b >= 0:
			_link(edges, a, b)
			_link(edges, b, a)


## A geyser lifts whoever steps into its jet, from its vent or from a lip
## beside it (a jet out of lava has no vent), to the top of its shaft, and from
## there they fall wherever they steer.
static func _geysers(
	edges: Array[PackedInt32Array], surfaces: Array[Rect2], solids: Array[Rect2],
	layout: Layout, moves: Moves
) -> void:
	for shaft in layout.geysers:
		# The jet holds you at its top while you steer, so you leave it from
		# either side of the shaft, as if stepping off a ledge up there.
		var landings := PackedInt32Array()
		for dir: float in [-1.0, 1.0]:
			var side := shaft.end.x if dir > 0.0 else shaft.position.x
			var feet := Vector2(side + dir * moves.hero_width * 0.5, shaft.position.y)
			for speed in SPEEDS:
				if speed > 0.0:
					var to := _fly(feet, dir * speed * moves.run_speed, false, surfaces, solids, layout.deadly, moves)
					if to >= 0 and not landings.has(to):
						landings.append(to)
		for i in surfaces.size():
			var s := surfaces[i]
			var beside := s.position.x <= shaft.end.x + moves.hero_width and s.end.x >= shaft.position.x - moves.hero_width
			if beside and s.position.y >= shaft.position.y - 0.5 and s.position.y <= shaft.end.y + 0.5:
				for to in landings:
					_link(edges, i, to)


## Everything reachable from `from` along `edges`.
static func _reach(edges: Array[PackedInt32Array], from: Array[int]) -> Dictionary:
	var seen := {}
	var queue: Array[int] = from.duplicate()
	for i in from:
		seen[i] = true
	while not queue.is_empty():
		var i: int = queue.pop_back()
		for j in edges[i]:
			if not seen.has(j):
				seen[j] = true
				queue.append(j)
	return seen


## The same moves, run backwards, over the first `count` surfaces.
static func _reversed(edges: Array[PackedInt32Array], count: int) -> Array[PackedInt32Array]:
	var back: Array[PackedInt32Array] = []
	for i in count:
		back.append(PackedInt32Array())
	for i in count:
		for j in edges[i]:
			if j < count:
				back[j].append(i)
	return back


static func _link(edges: Array[PackedInt32Array], from: int, to: int) -> void:
	if to >= 0 and to != from and not edges[from].has(to):
		edges[from].append(to)


static func _surface_under(surfaces: Array[Rect2], feet: Vector2) -> int:
	var best := -1
	var best_gap := INF
	for i in surfaces.size():
		var s := surfaces[i]
		var gap := s.position.y - feet.y
		if feet.x >= s.position.x - 1.0 and feet.x <= s.end.x + 1.0 and gap > -2.0 and gap < best_gap:
			best = i
			best_gap = gap
	return best


static func _serves_exit(surface: Rect2, exit: Rect2) -> bool:
	return absf(surface.position.y - exit.end.y) <= 2.0 \
		and surface.position.x <= exit.end.x + 24.0 and surface.end.x >= exit.position.x - 24.0


static func _samples(surface: Rect2) -> Array[float]:
	var xs: Array[float] = [surface.position.x, surface.end.x]
	var x := surface.position.x + STEP_X
	while x < surface.end.x:
		xs.append(x)
		x += STEP_X
	return xs


static func _hits(box: Rect2, rects: Array[Rect2]) -> bool:
	for rect in rects:
		if box.intersects(rect):
			return true
	return false


static func _has(list: Array[Rect2], rect: Rect2) -> bool:
	for other in list:
		if other.position.is_equal_approx(rect.position):
			return true
	return false


static func _cut(pieces: Array[Vector2], from: float, to: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for piece in pieces:
		if to <= piece.x or from >= piece.y:
			out.append(piece)
			continue
		if from > piece.x:
			out.append(Vector2(piece.x, from))
		if to < piece.y:
			out.append(Vector2(to, piece.y))
	return out


static func _join(spans: Array[Rect2]) -> Array[Rect2]:
	spans.sort_custom(func(a: Rect2, b: Rect2) -> bool:
		return a.position.y < b.position.y or (a.position.y == b.position.y and a.position.x < b.position.x))
	var out: Array[Rect2] = []
	for span in spans:
		if not out.is_empty():
			var last := out[out.size() - 1]
			if is_equal_approx(last.position.y, span.position.y) and span.position.x <= last.end.x + 0.5:
				out[out.size() - 1] = Rect2(last.position, Vector2(maxf(last.end.x, span.end.x) - last.position.x, 0.0))
				continue
		out.append(span)
	return out
