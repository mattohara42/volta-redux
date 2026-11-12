#!/usr/bin/env python3
"""Runs every capture.gd scenario in tools/scenarios_data.py and checks its
log against the assertions ported from .github/workflows/ci.yml.

    tools/dev.sh scenarios              # every scenario
    tools/dev.sh scenarios dragon       # only scenarios whose name matches

CLAUDE.md: "Build and test through tools/dev.sh... it is what CI runs, so a
command that works there works here." Before this, the 28 capture-and-grep
steps that actually catch a mechanism regression (a switch that stopped
sensing, a gate that stopped opening, a ferry that missed its dock) lived
only inline in ci.yml, reachable by pushing and waiting rather than by
running anything locally.

Runs every scenario regardless of earlier failures and reports all of them
at the end, the same choice tests/case.gd makes ("collects failures rather
than aborting, so one bad number does not hide the other nineteen"). CI's
old per-step arrangement stopped at the first failing scenario and never
even wrote the screenshots for the ones after it; this fixes that too.

Runs several at once, one Godot process each, as many as the machine has
cores (`SCENARIO_JOBS` overrides it; 1 runs them one by one). Safe because
capture.gd counts every phase in physics frames, not wall time, so a busy
machine runs a scenario slower but never differently. Results print in the
list's order whatever order they finish in.

Usage: tools/scenarios.py GODOT_BINARY [name-filter]
"""
from __future__ import annotations

import os
import platform
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from scenarios_data import SCENARIOS

REPO_ROOT = Path(__file__).resolve().parent.parent


def _player_position(log: str) -> tuple[float, float] | None:
	match = re.search(r"capture: player at \(([0-9.]+), ([0-9.]+)", log)
	if match is None:
		return None
	return float(match.group(1)), float(match.group(2))


def _run_check(check: dict, log: str) -> str | None:
	"""Returns None if the check passes, or its failure message if not."""
	kind = check["type"]
	pattern = check.get("pattern", "")
	if kind == "contains":
		ok = pattern in log
	elif kind == "not_contains":
		ok = pattern not in log
	elif kind == "contains_regex":
		ok = re.search(pattern, log) is not None
	elif kind == "not_contains_regex":
		ok = re.search(pattern, log) is None
	elif kind == "count_regex":
		ok = len(re.findall(pattern, log)) == check["count"]
	elif kind == "player_position":
		position = _player_position(log)
		if position is None:
			return check["message"] + " (no player position line found in the log at all)"
		x, y = position
		ok = True
		if "min_x" in check:
			ok = ok and x > check["min_x"]
		if "max_x" in check:
			ok = ok and x < check["max_x"]
		if "min_y" in check:
			ok = ok and y > check["min_y"]
		if "max_y" in check:
			ok = ok and y < check["max_y"]
	else:
		return "unknown check type %r" % kind
	return None if ok else check["message"]


def _display_wrapped(command: list[str]) -> list[str]:
	if platform.system() != "Darwin" and shutil.which("xvfb-run"):
		return ["xvfb-run", "-a"] + command
	return command


def _run_scenario(godot: str, scenario: dict) -> list[str]:
	"""Returns a list of failure messages; empty means the scenario passed."""
	out_path = REPO_ROOT / scenario["out"]
	centre_x, centre_y = scenario["centre"]
	command = [
		godot, "--path", ".", "--resolution", "1280x720",
		"--script", "res://tools/capture.gd", "--",
		"--scene=%s" % scenario["scene"],
		"--out=%s" % scenario["out"],
		"--zoom=%s" % scenario["zoom"],
		"--centre=%s,%s" % (centre_x, centre_y),
		"--overwrite",
	]
	if scenario["input"]:
		command.insert(-1, "--input=%s" % scenario["input"])
	if "at" in scenario:
		command.insert(-1, "--at=%s,%s" % scenario["at"])
	result = subprocess.run(
		_display_wrapped(command), cwd=REPO_ROOT, capture_output=True, text=True
	)
	log = result.stdout + result.stderr
	if result.returncode != 0:
		return ["capture.gd exited %d\n%s" % (result.returncode, log.strip())]

	failures: list[str] = []
	for check in scenario["checks"]:
		message = _run_check(check, log)
		if message is not None:
			failures.append(message)
	if not out_path.exists():
		failures.append("no output file was written at %s" % out_path)
	return failures


def main() -> int:
	if len(sys.argv) < 2:
		print("usage: tools/scenarios.py GODOT_BINARY [name-filter]", file=sys.stderr)
		return 2
	godot = sys.argv[1]
	name_filter = sys.argv[2].lower() if len(sys.argv) > 2 else ""

	scenarios = [s for s in SCENARIOS if name_filter in s["name"].lower()]
	if not scenarios:
		print("scenarios: no scenario name matches %r" % name_filter, file=sys.stderr)
		return 2

	jobs = int(os.environ.get("SCENARIO_JOBS", os.cpu_count() or 1))
	failed = 0
	with ThreadPoolExecutor(max_workers=max(jobs, 1)) as pool:
		results = pool.map(lambda scenario: _run_scenario(godot, scenario), scenarios)
		for scenario, failures in zip(scenarios, results):
			failed += _report(scenario, failures)

	print("%d scenarios, %d failed" % (len(scenarios), failed))
	return 1 if failed else 0


def _report(scenario: dict, failures: list[str]) -> int:
	"""Prints one scenario's result, and returns 1 if it failed."""
	if failures:
		print("FAIL  %s" % scenario["name"])
		for message in failures:
			print("        %s" % message)
	else:
		print("ok    %s" % scenario["name"])
	sys.stdout.flush()
	return 1 if failures else 0


if __name__ == "__main__":
	sys.exit(main())
