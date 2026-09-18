#!/usr/bin/env bash
#
# One entry point for the four things this project does from a terminal, so the
# command is the same whether a human or Claude types it.
#
#   tools/dev.sh import              reimport after a fresh clone
#   tools/dev.sh test                headless assertions
#   tools/dev.sh play [scene]        run it, F2 cycles the benches
#   tools/dev.sh shot SCENE OUT ...  a screenshot from a real running build
#   tools/dev.sh scenarios [filter]  the capture-and-check scenarios CI runs
#
# CLAUDE.md: the destructive mode is the flag. `shot` does not pass
# --overwrite, so replacing an existing image is something you ask for.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# $GODOT wins, then the PATH, then the places macOS and Linux actually put it.
find_godot() {
	if [[ -n "${GODOT:-}" ]]; then
		echo "$GODOT"
		return
	fi
	local candidate
	for candidate in godot godot4 Godot; do
		if command -v "$candidate" >/dev/null 2>&1; then
			command -v "$candidate"
			return
		fi
	done
	for candidate in \
		"/Applications/Godot.app/Contents/MacOS/Godot" \
		"$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
		"$HOME/godot/godot"; do
		if [[ -x "$candidate" ]]; then
			echo "$candidate"
			return
		fi
	done
	echo "tools/dev.sh: cannot find Godot. Set GODOT to the binary." >&2
	exit 127
}

GODOT_BIN="$(find_godot)"

# Xvfb is how Linux draws a frame without a screen. macOS has a real one and
# does not need it, which is the only place these two platforms differ here.
with_display() {
	if [[ "$(uname -s)" != "Darwin" ]] && command -v xvfb-run >/dev/null 2>&1; then
		xvfb-run -a "$@"
	else
		"$@"
	fi
}

command="${1:-}"
shift || true

case "$command" in
import)
	"$GODOT_BIN" --headless --path . --import
	;;
test)
	"$GODOT_BIN" --headless --path . --script res://tests/run_tests.gd
	;;
play)
	if [[ $# -gt 0 ]]; then
		"$GODOT_BIN" --path . "$1"
	else
		"$GODOT_BIN" --path .
	fi
	;;
shot)
	if [[ $# -lt 2 ]]; then
		echo "usage: tools/dev.sh shot SCENE OUT [--zoom=..] [--centre=x,y] [--input=..] [--overwrite]" >&2
		exit 2
	fi
	scene="$1"
	out="$2"
	shift 2
	with_display "$GODOT_BIN" --path . --resolution 1280x720 \
		--script res://tools/capture.gd -- \
		--scene="$scene" --out="$out" "$@"
	echo "wrote $out"
	;;
scenarios)
	# Ported from ci.yml, not wrapped in with_display here: scenarios.py does
	# its own xvfb-run wrapping per invocation, one Godot process per
	# scenario rather than one for the whole command.
	python3 tools/scenarios.py "$GODOT_BIN" "${1:-}"
	;;
*)
	sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
	exit 2
	;;
esac
