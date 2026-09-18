"""Every capture.gd scenario CI runs, as data.

Ported from .github/workflows/ci.yml so the same scenarios run locally
through `tools/dev.sh scenarios` and in CI through the same command, per
CLAUDE.md: "Build and test through tools/dev.sh... it is what CI runs, so a
command that works there works here." Before this, the 28 capture-and-grep
steps existed only inline in the workflow YAML, so reproducing a CI failure
meant reading shell embedded in YAML and retyping it by hand.

Each scenario is a dict:
    name       -- human-readable, matches the CI step name it replaces
    scene      -- res:// path to the room
    out        -- output PNG, written to the repo root (gitignored)
    input      -- capture.gd's --input phase string, or "" for none
    zoom       -- --zoom
    centre     -- (x, y) for --centre
    checks     -- list of check dicts, run against capture.gd's combined
                  stdout+stderr; empty list means "must simply not crash"

Check types:
    contains          -- substring must appear literally
    not_contains       -- substring must not appear
    contains_regex     -- a regex must match somewhere in the log
    not_contains_regex -- a regex must not match anywhere in the log
    count_regex        -- a regex must match exactly `count` times
    player_position    -- "capture: player at (X, Y..." must satisfy the
                           given min_x/max_x/min_y/max_y bounds (any subset)

Every check carries the same failure message the CI step's `echo` line did,
so a local failure reads the same as a CI one did.
"""

SCENARIOS: list[dict] = [
	{
		"name": "Screenshot the room",
		"scene": "res://scenes/rooms/room_m0.tscn",
		"out": "room_m0.png",
		"input": "move_right:2",
		"zoom": 0.38,
		"centre": (800, 180),
		"checks": [],
	},
	{
		"name": "Screenshot an embedded sword",
		"scene": "res://scenes/rooms/room_m2.tscn",
		"out": "room_m2_embed.png",
		"input": "move_left:10;throw:6;-:45",
		"zoom": 0.5,
		"centre": (250, 240),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "throwing into wood from a safe distance should not have killed the hero"},
			{"type": "contains", "pattern": "sword embedded",
				"message": "the throw should have embedded in the wood, not bounced or fallen"},
			{"type": "contains", "pattern": "sound played embed.wav",
				"message": "embedding should have played the embed cue, not stayed quiet"},
		],
	},
	{
		"name": "Screenshot the ledge over the gap",
		"scene": "res://scenes/rooms/room_m2_gap.tscn",
		"out": "room_m2_gap.png",
		"input": "throw:6;-:40",
		"zoom": 0.5,
		"centre": (440, 250),
		"checks": [],
	},
	{
		"name": "Screenshot the gate a sword opened",
		"scene": "res://scenes/rooms/room_m2_switch.tscn",
		"out": "room_m2_switch.png",
		"input": "move_left:10;throw:6;-:40",
		"zoom": 0.55,
		"centre": (220, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"switch at .* HELD",
				"message": "the embedded sword should be holding the switch down"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "the switch being held should have opened the gate"},
		],
	},
	{
		"name": "Screenshot lava, and time a death",
		"scene": "res://scenes/rooms/room_m3.tscn",
		"out": "room_m3.png",
		"input": "move_right:100;-:60",
		"zoom": 0.55,
		"centre": (350, 220),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: [1-9][0-9]* death",
				"message": "walking off the ledge into lava did not kill anybody"},
		],
	},
	{
		"name": "Screenshot a respawn at a brazier",
		"scene": "res://scenes/rooms/room_m3.tscn",
		"out": "room_m3_brazier.png",
		"input": "move_right:86;move_right,jump:20;move_right:120;-:45",
		"zoom": 1.0,
		"centre": (470, 250),
		"checks": [
			{"type": "contains", "pattern": "brazier at (470.0, 320.0) LIT",
				"message": "walking past the second brazier should have lit it"},
			{"type": "contains", "pattern": "checkpoint (470.0, 300.0)",
				"message": "the respawn should have used the second brazier, not the first"},
		],
	},
	{
		"name": "Screenshot the spikes, and die on them",
		"scene": "res://scenes/rooms/room_m3_spikes.tscn",
		"out": "room_m3_spikes.png",
		"input": "move_right:80;-:60",
		"zoom": 1.0,
		"centre": (300, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: [1-9][0-9]* death",
				"message": "walking into the spikes did not kill anybody"},
		],
	},
	{
		"name": "Jump the marginal bed",
		"scene": "res://scenes/rooms/room_m3_spikes.tscn",
		"out": "room_m3_spikes_cleared.png",
		"input": "move_right:62;move_right,jump:20;move_right:84;move_right,jump:20;move_right:40",
		"zoom": 1.0,
		"centre": (650, 250),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the marginal bed killed a run that should have cleared it"},
		],
	},
	{
		"name": "Stand on a falling platform, and ride it in",
		"scene": "res://scenes/rooms/room_m3_falling.tscn",
		"out": "room_m3_falling.png",
		"input": "move_right:60;move_right,jump:16;jump:120",
		"zoom": 1.2,
		"centre": (380, 290),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: [1-9][0-9]* death",
				"message": "standing still on a falling platform did not kill anybody"},
			{"type": "not_contains_regex", "pattern": r"capture: platform .*(shaking|falling|gone)",
				"message": "a platform was still missing after the respawn"},
		],
	},
	{
		"name": "Cross both moats without stopping",
		"scene": "res://scenes/rooms/room_m3_falling.tscn",
		"out": "room_m3_falling_crossed.png",
		"input": (
			"move_right:58;move_right,jump:16;move_right:12;move_right,jump:16;move_right:12;"
			"move_right,jump:16;move_right:29;move_right,jump:16;move_right:12;move_right,jump:16;"
			"move_right:12;move_right,jump:16;move_right:12;move_right,jump:16;move_right:24"
		),
		"zoom": 1.2,
		"centre": (880, 290),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the crossing killed a run that should have made it"},
		],
	},
	{
		"name": "Watch the ferry leave without you",
		"scene": "res://scenes/rooms/room_m3_moving.tscn",
		"out": "room_m3_moving.png",
		"input": "move_right:60;-:24",
		"zoom": 1.2,
		"centre": (200, 290),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: [1-9][0-9]* death",
				"message": "walking into the moat the ferry had left did not kill anybody"},
			{"type": "count_regex", "pattern": r"capture: platform .* home", "count": 2,
				"message": "a ferry was still out in the moat after the respawn"},
		],
	},
	{
		"name": "Die in the second moat, and catch the ferry from the respawn",
		"scene": "res://scenes/rooms/room_m3_moving.tscn",
		"out": "room_m3_moving_respawn.png",
		"input": (
			"move_right:37;-:143;move_right:17;-:76;move_right:8;move_right,jump:30;"
			"move_right:25;-:85;move_right:57;move_right,jump:30;-:40"
		),
		"zoom": 1.0,
		"centre": (620, 270),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: 1 death\(s\)",
				"message": "the respawn missed the ferry and died again"},
			# 548 is RoomM3Moving.ISLAND_END: past it there is no floor.
			{"type": "player_position", "min_x": 548,
				"message": "the hero is back on the island and not on the ferry"},
		],
	},
	{
		"name": "Ride both ferries across",
		"scene": "res://scenes/rooms/room_m3_moving.tscn",
		"out": "room_m3_moving_crossed.png",
		"input": (
			"move_right:37;-:143;move_right:17;-:76;move_right:8;move_right,jump:30;"
			"move_right:25;-:25;move_right,jump:30;-:109;move_right:10;move_right,jump:30;move_right:10"
		),
		"zoom": 1.0,
		"centre": (780, 270),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the crossing killed a run that should have made it"},
		],
	},
	{
		"name": "Ride a jet out of a lava moat",
		"scene": "res://scenes/rooms/room_m3_geysers.tscn",
		"out": "room_m3_geysers.png",
		"input": "move_right:110;-:75;move_right:90",
		"zoom": 1.0,
		"centre": (430, 200),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the crossing killed a run that should have made it"},
			# 508 is RoomM3Geysers.FAR_BANK_START and 224 is the lip it was
			# reached from. Past one and above the other is the far bank.
			{"type": "player_position", "min_x": 508, "max_y": 224,
				"message": "the hero is not up on the far bank"},
		],
	},
	{
		"name": "Step off the lip with nothing coming up",
		"scene": "res://scenes/rooms/room_m3_geysers.tscn",
		"out": "room_m3_geysers_respawn.png",
		"input": "move_right:110;-:157;move_right:170",
		"zoom": 1.0,
		"centre": (500, 180),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: 1 death\(s\)",
				"message": "either the quiet moat did not kill anybody, or the respawn missed the jet"},
			{"type": "player_position", "min_x": 508,
				"message": "the hero is short of the far bank"},
		],
	},
	{
		"name": "Screenshot the enemy bench",
		"scene": "res://scenes/rooms/room_m4_enemies.tscn",
		"out": "room_m4_enemies.png",
		"input": "-:12",
		"zoom": 0.34,
		"centre": (500, 220),
		"checks": [],
	},
	{
		"name": "Walk into an enemy and die",
		"scene": "res://scenes/rooms/room_m4_enemies.tscn",
		"out": "room_m4_touch.png",
		"input": "move_right:80;-:200",
		"zoom": 1.0,
		"centre": (280, 300),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: [1-9][0-9]* death",
				"message": "standing in the scorpion's patrol did not kill anybody"},
		],
	},
	{
		"name": "Kill the scorpion from behind",
		"scene": "res://scenes/rooms/room_m4_enemies.tscn",
		"out": "room_m4_scorpion_behind.png",
		"input": "move_right:45;throw:6;-:40",
		"zoom": 1.0,
		"centre": (280, 300),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the hero should not have died throwing from a safe distance"},
			{"type": "not_contains", "pattern": "scorpion alive",
				"message": "a hit from behind should have killed the scorpion"},
		],
	},
	{
		"name": "Bounce a sword off the scorpion's front",
		"scene": "res://scenes/rooms/room_m4_enemies.tscn",
		"out": "room_m4_scorpion_front.png",
		"input": "-:150;move_right:45;throw:6;-:30",
		"zoom": 1.0,
		"centre": (280, 300),
		"checks": [
			{"type": "contains", "pattern": "scorpion alive",
				"message": "a front hit should have bounced off the armour, not killed it"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the hero should not have died throwing from a safe distance"},
		],
	},
	{
		"name": "Screenshot the dragon's arena",
		"scene": "res://scenes/rooms/room_m4_dragon.tscn",
		"out": "room_m4_dragon.png",
		"input": "debug_toggle_overlay:1;-:12",
		"zoom": 0.7,
		"centre": (280, 260),
		"checks": [],
	},
	{
		"name": "Bounce the only sword off the dragon's body",
		"scene": "res://scenes/rooms/room_m4_dragon.tscn",
		"out": "room_m4_dragon_bounce.png",
		"input": "move_right:18;move_right,jump:8;move_right:24;move_right:20;-:5;throw:6;-:30",
		"zoom": 1.0,
		"centre": (280, 280),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "throwing from a safe distance should not have killed the hero"},
			{"type": "contains_regex", "pattern": r"dragon.*alive",
				"message": "a fresh throw should have bounced off the dragon, not killed it"},
		],
	},
	{
		"name": "Get caught by the dragon's breath",
		"scene": "res://scenes/rooms/room_m4_dragon.tscn",
		"out": "room_m4_dragon_breath.png",
		"input": "move_right:18;move_right,jump:8;move_right:25;-:3;move_right:4;-:230",
		"zoom": 1.0,
		"centre": (220, 280),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: [1-9][0-9]* death",
				"message": "standing where the breath reaches did not kill anybody over a full period"},
		],
	},
	{
		"name": "Embed past the dragon and recall it home through the body",
		"scene": "res://scenes/rooms/room_m4_dragon.tscn",
		"out": "room_m4_dragon_recall.png",
		"input": (
			"move_right:18;move_right,jump:8;move_right:24;throw:6;-:40;move_right:20;-:5;"
			"throw:25;-:20"
		),
		"zoom": 1.0,
		"centre": (280, 280),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the hero should not have died pulling this off"},
			{"type": "contains", "pattern": "capture: no enemies remaining",
				"message": "the recall should have killed the dragon"},
			{"type": "contains", "pattern": "1 sword(s) held",
				"message": (
					"BUILD_PLAN.md's M11 done-when is beating the dragon without spending a "
					"sword: it should have come home"
				)},
		],
	},
	{
		"name": "Screenshot the floor plate bench",
		"scene": "res://scenes/rooms/room_m4_plate.tscn",
		"out": "room_m4_plate.png",
		"input": "-:5",
		"zoom": 1.0,
		"centre": (250, 260),
		"checks": [],
	},
	{
		"name": "Stand on the plate and open the gate",
		"scene": "res://scenes/rooms/room_m4_plate.tscn",
		"out": "room_m4_plate_open.png",
		"input": "move_right:65;-:10",
		"zoom": 1.0,
		"centre": (250, 260),
		"checks": [
			{"type": "contains_regex", "pattern": r"plate at .* HELD",
				"message": "standing on the plate should have held it down"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "the gate should have opened with the plate held"},
		],
	},
	{
		"name": "Leave a sword on the plate and walk away",
		"scene": "res://scenes/rooms/room_m4_plate.tscn",
		"out": "room_m4_plate_sword.png",
		"input": (
			"move_right:65;move_left:2;-:5;throw:6;-:5;climb_up:80;climb_up,move_right:20;"
			"climb_up,move_left:20;-:30"
		),
		"zoom": 1.0,
		"centre": (250, 260),
		"checks": [
			{"type": "contains", "pattern": "sword grounded",
				"message": "the missed throw should have landed grounded, not caught or destroyed"},
			{"type": "contains_regex", "pattern": r"plate at .* HELD",
				"message": "the grounded sword should have held the plate down"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "the gate should be open with the sword weighing the plate"},
		],
	},
	{
		"name": "Screenshot the dormant bench",
		"scene": "res://scenes/rooms/room_m4_dormant.tscn",
		"out": "room_m4_dormant.png",
		"input": "-:10",
		"zoom": 1.0,
		"centre": (200, 260),
		"checks": [
			{"type": "contains", "pattern": "scorpion (dormant) alive",
				"message": "the scorpion should start dormant"},
			{"type": "contains_regex", "pattern": r"plate at .* HELD",
				"message": "the dormant scorpion's own weight should hold the plate down"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "the gate should already be open before the hero arrives"},
		],
	},
	{
		"name": "Wake the dormant scorpion by approaching it",
		"scene": "res://scenes/rooms/room_m4_dormant.tscn",
		"out": "room_m4_dormant_wake.png",
		"input": "move_right:50",
		"zoom": 1.0,
		"centre": (220, 260),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "approaching alone should not have killed the hero"},
			{"type": "contains", "pattern": "scorpion alive",
				"message": "getting this close should have woken the scorpion"},
		],
	},
]
