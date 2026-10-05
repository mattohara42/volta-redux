#!/usr/bin/env python3
"""Sums up the play log the game writes while it is played (`PlayLog`): per
room, how long it took, how often it killed you and with what, and per act
and in total. Read-only.

    python3 tools/play_log.py                 the log in Godot's user folder
    python3 tools/play_log.py path/to/play_log.csv

A room played more than once (across sessions, or after a new game) is
summed over every visit; the visits column says how many.
"""

import csv
import os
import sys
from collections import Counter, OrderedDict

USER_DIRS = [
    "~/Library/Application Support/Godot/app_userdata/Volta Redux",
    "~/.local/share/godot/app_userdata/Volta Redux",
    "%APPDATA%/Godot/app_userdata/Volta Redux",
]


def default_path():
    for folder in USER_DIRS:
        path = os.path.join(os.path.expandvars(os.path.expanduser(folder)), "play_log.csv")
        if os.path.exists(path):
            return path
    return None


def minutes(seconds):
    return f"{int(seconds // 60)}:{int(seconds % 60):02d}"


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else default_path()
    if not path or not os.path.exists(path):
        print("No play log yet. It is written as rooms are left, from a plain launch of the game.")
        return 1
    rooms = OrderedDict()
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            key = (int(row["act"]), row["room"])
            room = rooms.setdefault(key, {"visits": 0, "seconds": 0.0, "deaths": 0, "causes": Counter(), "restarts": 0, "quits": 0})
            room["visits"] += 1
            room["seconds"] += float(row["seconds"])
            room["deaths"] += int(row["deaths"])
            room["restarts"] += int(row["restarts"])
            room["quits"] += row["ended"] != "exit"
            parts = row["causes"].split()
            for name, count in zip(parts[::2], parts[1::2]):
                room["causes"][name] += int(count)
    print(f"{'act':>3}  {'room':<18} {'visits':>6} {'time':>7} {'deaths':>6}  causes")
    acts = OrderedDict()
    for (act, name), room in rooms.items():
        causes = " ".join(f"{k} {v}" for k, v in room["causes"].most_common()) or "-"
        note = f"  (left mid-room {room['quits']}x)" if room["quits"] else ""
        print(f"{act:>3}  {name:<18} {room['visits']:>6} {minutes(room['seconds']):>7} {room['deaths']:>6}  {causes}{note}")
        total = acts.setdefault(act, [0.0, 0])
        total[0] += room["seconds"]
        total[1] += room["deaths"]
    print()
    for act, (seconds, deaths) in acts.items():
        print(f"Act {act}: {minutes(seconds)}, {deaths} deaths")
    print(f"All: {minutes(sum(t[0] for t in acts.values()))}, {sum(t[1] for t in acts.values())} deaths")
    return 0


if __name__ == "__main__":
    sys.exit(main())
