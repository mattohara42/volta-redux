## How long a frame takes in a room, measured in a real running build
## (`BUILD_PLAN.md` R3: a ten-screen by five-floor grey level holds frame
## rate). Loads the scene, lets it settle, then carries the hero along every
## floor of it and times each drawn frame on the wall clock, so drawing is
## counted. Prints the mean, the 95th percentile and the worst, against a
## 60 fps budget.
##
##     tools/dev.sh frametime res://scenes/rooms/test_tall.tscn
##
## It needs a display (the dev.sh wrapper adds one on Linux): headless draws
## nothing and would measure nothing. A cloud container draws in software, so
## its numbers are an upper bound; compare rooms against each other there, and
## take the absolute number from Matt's machine, which prints the same way.
##
## Driven by a node awaiting frames, as `capture.gd` is: a SceneTree's own
## `_process` never ran with a display attached.
extends SceneTree

const SETTLE_FRAMES: int = 60
const MEASURE_FRAMES: int = 600
const BUDGET_MS: float = 1000.0 / 60.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var driver := Driver.new()
	driver.scene_path = args[0] if not args.is_empty() else "res://scenes/rooms/test_tall.tscn"
	root.add_child(driver)


class Driver:
	extends Node

	var scene_path := ""

	func _ready() -> void:
		_run.call_deferred()

	func _run() -> void:
		var scene := (load(scene_path) as PackedScene).instantiate()
		get_tree().root.add_child(scene)
		for i in SETTLE_FRAMES:
			await get_tree().process_frame
		var hero := get_tree().get_first_node_in_group("player") as Node2D
		var path := _route(scene as Bench)
		if hero != null:
			hero.set_physics_process(false)
		var times: Array[float] = []
		var last := Time.get_ticks_usec()
		for i in MEASURE_FRAMES:
			if hero != null and not path.is_empty():
				# Carried, not steered: this measures the room, not the controls.
				hero.global_position = path[mini(i * path.size() / MEASURE_FRAMES, path.size() - 1)]
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			times.append((now - last) / 1000.0)
			last = now
		_report(times)
		get_tree().quit(0)

	## Along each floor in turn, from the bottom up, from the walk-back
	## surfaces the room already knows.
	func _route(bench: Bench) -> Array[Vector2]:
		var points: Array[Vector2] = []
		if bench == null:
			return points
		var layout := bench.walk_back_layout()
		var surfaces := WalkBack.surfaces_of(layout.solids, layout.deadly, bench.world.hero_height)
		surfaces.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y > b.position.y)
		for s in surfaces:
			if s.size.x < 64.0 or s.position.y < 0.0:
				continue
			var x := s.position.x
			while x < s.end.x:
				points.append(Vector2(x, s.position.y - bench.world.hero_height * 0.5))
				x += 16.0
		return points

	func _report(times: Array[float]) -> void:
		var sorted := times.duplicate()
		sorted.sort()
		var total := 0.0
		for t in times:
			total += t
		var mean := total / times.size()
		var p95: float = sorted[int(sorted.size() * 0.95)]
		var worst: float = sorted[sorted.size() - 1]
		print("frametime: %s" % scene_path)
		print("frametime: %d frames, mean %.2f ms, p95 %.2f ms, worst %.2f ms (60 fps is %.2f ms)" % [
			times.size(), mean, p95, worst, BUDGET_MS])
		print("frametime: %s" % ("within budget" if p95 <= BUDGET_MS else "OVER budget at the 95th percentile"))
