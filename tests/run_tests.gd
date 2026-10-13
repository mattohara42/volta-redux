## The headless test runner. No addon: it finds `tests/test_*.gd`, calls every
## method on them whose name starts with `test_`, and exits non-zero if any
## check failed.
##
##   godot --headless --script tests/run_tests.gd
extends SceneTree

const TESTS_DIR := "res://tests"


## Counts script errors. A runtime error inside a test (a call on null, a bad
## index) aborts that test and returns to the runner without touching
## `failures`, so without this a crashed test reads as a pass.
class ScriptErrorCounter:
	extends Logger

	var count := 0
	var _lock := Mutex.new()

	func _log_error(
		_function: String, _file: String, _line: int, _code: String,
		_rationale: String, _editor_notify: bool, error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			_lock.lock()
			count += 1
			_lock.unlock()


func _initialize() -> void:
	var files := _discover()
	if files.is_empty():
		printerr("no test files found in %s" % TESTS_DIR)
		quit(1)
		return

	var total_checks := 0
	var failed_tests := 0
	var run_tests := 0
	var report: PackedStringArray = []
	var errors := ScriptErrorCounter.new()
	OS.add_logger(errors)

	for path in files:
		var file_name := path.get_file()
		var script := load(path) as GDScript
		# A file with a parse error still loads as a script, and calling `new` on
		# it aborts this whole function before `quit`, so Godot idles forever and
		# CI sits until its timeout. Asking first makes it a reported failure.
		if script == null or not script.can_instantiate():
			failed_tests += 1
			report.append("FAIL  %s: will not load, see the parse error above" % file_name)
			continue
		var case := script.new() as TestCase
		if case == null:
			failed_tests += 1
			report.append("FAIL  %s: does not extend TestCase" % file_name)
			continue
		for method in case.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var before := case.failures.size()
			var errors_before := errors.count
			case.call(method_name)
			run_tests += 1
			var new_failures := case.failures.size() - before
			var new_errors := errors.count - errors_before
			if new_failures > 0 or new_errors > 0:
				failed_tests += 1
				report.append("FAIL  %s::%s" % [file_name, method_name])
				for i in range(before, case.failures.size()):
					report.append("        %s" % case.failures[i])
				if new_errors > 0:
					report.append("        %d script error(s), see above" % new_errors)
		total_checks += case.checks

	for line in report:
		print(line)
	print("%d tests, %d checks, %d failed" % [run_tests, total_checks, failed_tests])
	OS.remove_logger(errors)
	quit(1 if failed_tests > 0 else 0)


func _discover() -> PackedStringArray:
	var found: PackedStringArray = []
	for file_name in DirAccess.get_files_at(TESTS_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			found.append("%s/%s" % [TESTS_DIR, file_name])
	found.sort()
	return found
