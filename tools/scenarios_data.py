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
    at         -- optional (x, y): the hero's feet start there, lit as a
                  checkpoint, for a scenario partway through a big level
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

# Act 3's toll room up to the moment the gate lifts: drop to the yard, one
# throw from the floor and one from each step of the stair.
TOLL_PAID = (
	"move_right:157;-:40;move_left:2;-:10;throw:4;-:40;move_right,jump:14;-:30;"
	"move_left:2;-:10;throw:4;-:40;move_right,jump:14;-:30;move_left:2;-:10;throw:4;-:40"
)

# Act 3's rungs room from the start to the high tier: crate, dead rung, tier,
# crate, dead rung, tier.
RUNGS_UP = (
	"move_right:60;move_right,jump:14;-:30;throw:4;-:40;move_right:6;-:4;move_right,jump:14;-:30;"
	"move_right,jump:16;-:30;move_right,jump:10;-:30;throw:4;-:40;move_right:8;-:4;"
	"move_right,jump:14;-:30;move_right,jump:16;-:30"
)
RUNGS_RECALLED = RUNGS_UP + ";move_right:70;-:20;throw:40;-:90"

# The generator's three breaks, the same throws as the toll's: the yard, then
# each step of the stair. The arcs are timed so none lands on this route.
GENERATOR_LOOP = TOLL_PAID

# Act 4's throne up to the dais: the gallery, the shelf's gem, three
# pedestals. Two gems ride in from the earlier rooms (the scene's
# starting_gems).
THRONE_PREFIX = (
	"move_right:40;move_right,jump:14;-:30;throw:4;-:30;move_right:4;-:2;"
	"move_right,jump:14;-:30;move_right,jump:14;-:30;move_right:30;-:6;throw:4;-:60;"
	"move_right:62;move_right,jump:14;move_right:20;move_right,jump:14;move_right:20;"
	"move_right,jump:14;move_right:30;-:4"
)
THRONE_BRIDGED = THRONE_PREFIX + ";throw:4;move_left:16"

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
			{"type": "contains", "pattern": "sound played sword_embed.wav",
				"message": "embedding should have played the embed cue, not stayed quiet"},
		],
	},
	{
		"name": "Cross the M2 gap on a sword in the hoarding",
		"scene": "res://scenes/rooms/room_m2_gap.tscn",
		"out": "room_m2_gap.png",
		"input": "-:20;throw:4;-:40;move_right,jump:14;move_right:6;-:30;move_right,jump:16;move_right:16;-:20",
		"zoom": 0.5,
		"centre": (440, 250),
		"checks": [
			{"type": "player_position", "min_x": 488.0, "max_y": 250.0,
				"message": "the hero should be standing on the far side, past the hoarding"},
			{"type": "contains", "pattern": "sword embedded",
				"message": "the step should be a sword embedded in the hoarding"},
		],
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
			{"type": "contains", "pattern": "checkpoint (470.0, 302.0)",
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
	{
		"name": "Act 1 forest: the clearing is safe to throw and catch in",
		"scene": "res://scenes/rooms/act1_forest.tscn",
		"out": "act1_forest_clearing.png",
		"input": "move_right:6;-:4;throw:4;-:70",
		"zoom": 1.0,
		"centre": (320, 700),
		"checks": [
			{"type": "contains", "pattern": "3 sword(s) held",
				"message": "a throw in the clearing should come home and be caught"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nothing in the clearing should kill"},
		],
	},
	{
		"name": "Act 1 forest: kill the scorpion asleep under the oak with a throw in its back",
		"scene": "res://scenes/rooms/act1_forest.tscn",
		"out": "act1_forest_sleeper.png",
		"at": (540, 800),
		"input": "move_right:2;-:8;throw:4;-:50",
		"zoom": 1.0,
		"centre": (600, 700),
		"checks": [
			{"type": "not_contains", "pattern": "scorpion (dormant) alive at (632.",
				"message": "a throw into the sleeping scorpion's back did not kill it"},
			{"type": "contains", "pattern": "2 sword(s) held",
				"message": "the kill should have cost exactly one sword"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died under the oak"},
		],
	},
	{
		"name": "Act 1 forest: a throw into the woken scorpion's face is lost",
		"scene": "res://scenes/rooms/act1_forest.tscn",
		"out": "act1_forest_armour.png",
		"at": (560, 800),
		"input": "move_right:12;-:250;throw:4;-:30",
		"zoom": 1.0,
		"centre": (640, 700),
		"checks": [
			{"type": "contains_regex", "pattern": r"scorpion alive at \((6|7)[0-9][0-9]\.",
				"message": "the woken scorpion should have survived a throw into its armour"},
			{"type": "contains", "pattern": "2 sword(s) held",
				"message": "the armour should have cost the sword"},
		],
	},
	{
		"name": "Act 1 forest: the first river branches, the cracked one included, can be jumped",
		"scene": "res://scenes/rooms/act1_forest.tscn",
		"out": "act1_forest_river.png",
		"at": (1080, 544),
		"input": "move_right:5;move_right,jump:14;move_right:13;move_right:12;move_right,jump:14;move_right:13;-:30",
		"zoom": 1.0,
		"centre": (1200, 480),
		"checks": [
			{"type": "player_position", "min_x": 1264, "max_x": 1376, "max_y": 530,
				"message": "the hero should be standing on the third branch"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the crossing should not kill a hero who keeps moving"},
		],
	},
	{
		"name": "Act 1 forest: from the island up onto the next cracked branch and on",
		"scene": "res://scenes/rooms/act1_forest.tscn",
		"out": "act1_forest_island.png",
		"at": (1820, 624),
		"input": "move_right:9;move_right,jump:14;move_right:13;-:30",
		"zoom": 1.0,
		"centre": (1880, 560),
		"checks": [
			{"type": "player_position", "min_x": 1904, "max_x": 1984, "max_y": 580,
				"message": "the hero should be standing on the branch past the cracked one"},
		],
	},
	{
		"name": "Act 1 forest: the island's stump brings you up in the canopy",
		"scene": "res://scenes/rooms/act1_forest.tscn",
		"out": "act1_forest_stump_up.png",
		"at": (1592, 672),
		"input": "move_right:10;move_right,jump:14;move_right:6;-:40",
		"zoom": 1.0,
		"centre": (2600, 200),
		"checks": [
			{"type": "player_position", "min_x": 2640, "max_x": 2672, "max_y": 150,
				"message": "the hero should be standing on the canopy's stump"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "a warp should not kill"},
		],
	},
	{
		"name": "Act 1 forest: the stump past the nest brings you down at the moat",
		"scene": "res://scenes/rooms/act1_forest.tscn",
		"out": "act1_forest_stump_down.png",
		"at": (4256, 544),
		"input": "jump:10;move_right:8;-:40",
		"zoom": 1.0,
		"centre": (4700, 700),
		"checks": [
			{"type": "player_position", "min_x": 4704, "max_x": 4736, "min_y": 740,
				"message": "the hero should be standing on the moat's stump"},
		],
	},
	{
		"name": "Act 1: wood holds a thrown sword, and recall brings it home",
		"scene": "res://scenes/rooms/act1_bailey.tscn",
		"out": "act1_bailey_recall.png",
		"input": "move_right:35;-:8;throw:4;-:40;throw:40;-:60",
		"zoom": 1.4,
		"centre": (240, 220),
		"checks": [
			{"type": "contains", "pattern": "3 sword(s) held",
				"message": "recall should have brought the embedded sword back to hand"},
			{"type": "contains", "pattern": "no swords in play",
				"message": "nothing should be left in the wooden block after a recall"},
		],
	},
	{
		"name": "Act 1: the bailey's switch is ahead of the yard, and a throw raises the gate",
		"scene": "res://scenes/rooms/act1_bailey.tscn",
		"out": "act1_bailey_switch.png",
		"input": (
			"move_right:56;move_right,jump:16;move_right:30;move_right,jump:18;move_right:20;"
			"move_right:80;-:30;throw:4;-:90"
		),
		"zoom": 1.0,
		"centre": (900, 220),
		"checks": [
			{"type": "player_position", "min_x": 760, "max_x": 880, "min_y": 290,
				"message": "the hero should be down in the yard"},
			{"type": "contains", "pattern": "switch at (888.0, 304.0) HELD",
				"message": "a throw straight ahead from the yard should land in the switch"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "the switch should have raised the gate"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nothing in the bailey should have killed"},
		],
	},
	{
		"name": "G2: landing on a stump brings you up out of the one on the shelf",
		"scene": "res://scenes/rooms/room_g2_stump.tscn",
		"out": "room_g2_stump.png",
		"input": "move_right:36;move_right,jump:14;move_right:8;-:40",
		"zoom": 1.0,
		"centre": (320, 180),
		"checks": [
			{"type": "player_position", "min_x": 530, "max_x": 560, "max_y": 170,
				"message": "the hero should be standing on the shelf's stump"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "a warp should not kill"},
		],
	},
	{
		"name": "Act 1: a chest refills your hand while swords are left in the wood",
		"scene": "res://scenes/rooms/act1_bailey.tscn",
		"out": "act1_bailey_chest.png",
		"input": "move_right:14;-:8;throw:4;-:30;throw:4;-:30;throw:4;-:60",
		"zoom": 1.4,
		"centre": (180, 220),
		"checks": [
			{"type": "player_position", "min_x": 86, "max_x": 106,
				"message": "the hero should be standing in the chest"},
			{"type": "contains", "pattern": "sword embedded",
				"message": "the throws should have stuck in the wooden hurdle"},
			{"type": "contains", "pattern": "3 sword(s) held",
				"message": "a chest should fill the hand whatever is left in the wood"},
		],
	},
	{
		"name": "Act 1: cross the ditch by standing on a sword in the hoarding",
		"scene": "res://scenes/rooms/act1_gate.tscn",
		"out": "act1_gate_crossing.png",
		"input": "move_right:102;-:12;throw:4;-:40;move_right,jump:14;move_right:6;-:30;move_right,jump:16;move_right:16;-:20",
		"zoom": 1.4,
		"centre": (480, 200),
		"checks": [
			{"type": "player_position", "min_x": 488.0, "max_y": 200.0,
				"message": "the hero should be standing on the far side, past the hoarding"},
			{"type": "contains", "pattern": "sword embedded",
				"message": "the step should be a sword embedded in the hoarding"},
			{"type": "contains", "pattern": "no deaths",
				"message": "nobody should have died crossing"},
		],
	},
	{
		"name": "Act 2: ride both jets up the geyser shaft",
		"scene": "res://scenes/rooms/act2_geysers.tscn",
		"out": "act2_geysers_ride.png",
		"input": "move_right:110;-:75;move_right:90",
		"zoom": 1.0,
		"centre": (430, 200),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the climb killed a run that should have made it"},
			{"type": "player_position", "min_x": 508, "max_y": 224,
				"message": "the hero is not up on the far bank"},
		],
	},
	{
		"name": "Act 2: kill the causeway bat from the island, then cross",
		"scene": "res://scenes/rooms/act2_causeway.tscn",
		"out": "act2_causeway_crossed.png",
		"input": (
			"move_right:58;move_right,jump:16;move_right:12;move_right,jump:16;move_right:12;"
			"move_right,jump:16;move_right:20;-:90;throw:4;-:70;move_right:22;move_right,jump:16;"
			"move_right:12;move_right,jump:16;move_right:12;move_right,jump:16;move_right:12;"
			"move_right,jump:16;move_right:24"
		),
		"zoom": 1.0,
		"centre": (860, 250),
		"checks": [
			{"type": "contains", "pattern": "no enemies remaining",
				"message": "a timed throw from the island should have killed the bat"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the crossing killed a run that should have made it"},
			{"type": "player_position", "min_x": 944,
				"message": "the hero is not on the far bank"},
		],
	},
	{
		"name": "Act 2: wait out a high tide on a refuge",
		"scene": "res://scenes/rooms/act2_tide.tscn",
		"out": "act2_tide_refuge.png",
		"input": "move_right:102;move_right,jump:14;move_right:4;-:200",
		"zoom": 1.0,
		"centre": (500, 250),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "a hero on the refuge should have outlasted the high tide"},
			{"type": "player_position", "min_x": 431, "max_x": 489, "max_y": 270,
				"message": "the hero should be standing on the first refuge"},
		],
	},
	{
		"name": "Act 2: a high tide kills a hero left in the passage",
		"scene": "res://scenes/rooms/act2_tide.tscn",
		"out": "act2_tide_flooded.png",
		"input": "move_right:70;-:200",
		"zoom": 1.0,
		"centre": (500, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: 1 death\(s\)",
				"message": "standing in the passage through a high tide should kill"},
		],
	},
	{
		"name": "Act 2: climb the mine on two swords, kill the eyeball, recall both",
		"scene": "res://scenes/rooms/act2_mine.tscn",
		"out": "act2_mine_climbed.png",
		"input": (
			"move_right:99;-:12;throw:4;-:40;move_right,jump:14;move_right:6;-:30;"
			"move_right,jump:16;move_right:16;-:20;-:10;throw:4;-:30;move_right:76;-:12;"
			"throw:4;-:40;move_right,jump:14;move_right:6;-:30;move_right,jump:16;"
			"move_right:16;-:20;throw:40;-:90"
		),
		"zoom": 1.0,
		"centre": (860, 200),
		"checks": [
			{"type": "player_position", "min_x": 888, "max_y": 190,
				"message": "the hero should be on the top level"},
			{"type": "contains", "pattern": "no enemies remaining",
				"message": "the throw from the landing should have killed the eyeball"},
			{"type": "contains", "pattern": "4 sword(s) held",
				"message": "recall should have brought both steps home, on top of the middle chest's three"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died on the climb"},
		],
	},
	{
		"name": "Act 2: chain the dragon with a recall and walk on past it",
		"scene": "res://scenes/rooms/act2_lair.tscn",
		"out": "act2_lair_chained.png",
		"input": (
			"move_right:18;move_right,jump:8;move_right:24;throw:6;-:40;move_right:20;-:5;"
			"throw:25;-:20;move_right:80;-:20"
		),
		"zoom": 1.6,
		"centre": (380, 260),
		"checks": [
			{"type": "contains", "pattern": "capture: no enemies remaining",
				"message": "the recall should have chained the dragon"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "a chained dragon should no longer kill on contact"},
			{"type": "player_position", "min_x": 430,
				"message": "the hero should have walked under the timber past the dragon"},
			{"type": "contains", "pattern": "3 sword(s) held",
				"message": "the fight should have cost nothing, and the chest made it three"},
		],
	},
	{
		"name": "Act 3 bench: a sword in the seam carries current to the switch",
		"scene": "res://scenes/rooms/room_m12_circuit.tscn",
		"out": "room_m12_bridged.png",
		"input": "move_left:2;-:10;throw:4;-:40",
		"zoom": 1.2,
		"centre": (240, 240),
		"checks": [
			{"type": "contains", "pattern": "sword embedded",
				"message": "the sword should have bitten the metal either side of the seam"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "current through the bridged seam should have opened the gate"},
		],
	},
	{
		"name": "Act 3 bench: recalling the bridge drops the gate",
		"scene": "res://scenes/rooms/room_m12_circuit.tscn",
		"out": "room_m12_recalled.png",
		"input": "move_left:2;-:10;throw:4;-:40;throw:30;-:60",
		"zoom": 1.0,
		"centre": (240, 240),
		"checks": [
			{"type": "contains", "pattern": "1 sword(s) held",
				"message": "the recall should have brought the only sword home"},
			{"type": "contains_regex", "pattern": r"gate at .* SHUT",
				"message": "with the bridge gone the gate should have dropped"},
		],
	},
	{
		"name": "Act 3 bench: live metal kills",
		"scene": "res://scenes/rooms/room_m12_circuit.tscn",
		"out": "room_m12_live_plate.png",
		"input": "move_left:30;-:10",
		"zoom": 1.0,
		"centre": (240, 240),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: [1-9][0-9]* death",
				"message": "stepping on the live plate should have killed"},
		],
	},
	{
		"name": "Act 3: bridge the hall's seam and the gate rises",
		"scene": "res://scenes/rooms/act3_hall.tscn",
		"out": "act3_hall_bridged.png",
		"input": "move_right:160;-:20;move_left:2;-:10;throw:4;-:40",
		"zoom": 1.2,
		"centre": (600, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "a sword across the seam should have opened the gate"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "dropping past the recessed live face should be safe"},
		],
	},
	{
		"name": "Act 3: the insulator's wooden seam carries nothing",
		"scene": "res://scenes/rooms/act3_insulator.tscn",
		"out": "act3_insulator_decoy.png",
		"input": "move_right:160;-:30;move_left:2;-:10;throw:4;-:40",
		"zoom": 1.2,
		"centre": (600, 250),
		"checks": [
			{"type": "contains", "pattern": "sword embedded",
				"message": "the sword should have bitten the copper and the wood"},
			{"type": "contains_regex", "pattern": r"gate at .* SHUT",
				"message": "copper over wood carries no current, so the gate stays shut"},
		],
	},
	{
		"name": "Act 3: the insulator's copper seam, thrown from the step, opens it",
		"scene": "res://scenes/rooms/act3_insulator.tscn",
		"out": "act3_insulator_bridged.png",
		"input": (
			"move_right:160;-:30;move_left:2;-:10;throw:4;-:40;move_right,jump:14;"
			"move_right:4;-:20;move_left:2;-:10;throw:4;-:40"
		),
		"zoom": 1.2,
		"centre": (600, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "the copper seam bridged from the step should have opened the gate"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "Act 3: bridging while standing on the copper floor kills",
		"scene": "res://scenes/rooms/act3_floor.tscn",
		"out": "act3_floor_shocked.png",
		"input": "move_right:160;-:20;move_left:2;-:10;throw:4;-:40",
		"zoom": 1.0,
		"centre": (600, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"capture: 1 death",
				"message": "the current let through should have run through the hero's feet"},
		],
	},
	{
		"name": "Act 3: step off the copper, then bridge",
		"scene": "res://scenes/rooms/act3_floor.tscn",
		"out": "act3_floor_bridged.png",
		"input": "move_right:160;-:10;move_right:30;-:20;move_left:2;-:10;throw:4;-:40",
		"zoom": 1.2,
		"centre": (620, 250),
		"checks": [
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "throwing from the stone should be safe"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "the bridged seam should have opened the gate"},
		],
	},
	{
		"name": "Act 3: one of two seams in series opens nothing",
		"scene": "res://scenes/rooms/act3_series.tscn",
		"out": "act3_series_one.png",
		"input": "move_right:160;-:30;move_left:2;-:10;throw:4;-:40",
		"zoom": 1.0,
		"centre": (600, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"gate at .* SHUT",
				"message": "one bridged seam of two should leave the gate shut"},
		],
	},
	{
		"name": "Act 3: both seams in series open the gate",
		"scene": "res://scenes/rooms/act3_series.tscn",
		"out": "act3_series_both.png",
		"input": (
			"move_right:160;-:30;move_left:2;-:10;throw:4;-:40;move_right,jump:14;"
			"move_right:4;-:20;move_left:2;-:10;throw:4;-:40"
		),
		"zoom": 1.2,
		"centre": (620, 250),
		"checks": [
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "both seams bridged should open the gate"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "Act 3: the toll takes every sword to open the gate",
		"scene": "res://scenes/rooms/act3_toll.tscn",
		"out": "act3_toll_paid.png",
		"input": TOLL_PAID,
		"zoom": 1.2,
		"centre": (640, 240),
		"checks": [
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "three bridged seams should open the gate"},
			{"type": "contains", "pattern": "0 sword(s) held",
				"message": "and leave nothing in hand"},
			{"type": "count_regex", "pattern": r"sword embedded at \(552\.0", "count": 3,
				"message": "each sword should stand out of the face, not sink through a seam"},
		],
	},
	{
		"name": "Act 3: recall past the toll and climb out",
		"scene": "res://scenes/rooms/act3_toll.tscn",
		"out": "act3_toll_out.png",
		"input": TOLL_PAID + (
			";move_right:120;-:20;throw:40;-:60;throw:4;-:40;move_right:14;-:20;"
			"move_right,jump:14;-:20;move_right,jump:14;move_right:60"
		),
		"zoom": 1.2,
		"centre": (1040, 240),
		"checks": [
			{"type": "contains_regex", "pattern": r"gate at .* SHUT",
				"message": "the recall should have dropped the gate behind the hero"},
			{"type": "player_position", "min_x": 1180.0, "max_y": 260.0,
				"message": "the hero should be up on the way out"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "Act 3: a rung in live copper kills",
		"scene": "res://scenes/rooms/act3_rungs.tscn",
		"out": "act3_rungs_live.png",
		"input": (
			"move_right:60;-:4;move_right,jump:14;move_right:30;-:30;move_left:9;-:20;"
			"move_right:1;-:10;throw:4;-:30;move_right,jump:14;-:30"
		),
		"zoom": 1.6,
		"centre": (380, 260),
		"checks": [
			{"type": "contains", "pattern": "1 death(s)",
				"message": "stepping onto a sword in live copper should kill"},
		],
	},
	{
		"name": "Act 3: recall from the bridge and every sword comes home",
		"scene": "res://scenes/rooms/act3_rungs.tscn",
		"out": "act3_rungs_bridge.png",
		"input": RUNGS_RECALLED,
		"zoom": 1.0,
		"centre": (700, 220),
		"checks": [
			{"type": "contains", "pattern": "3 sword(s) held",
				"message": "recalled from above, the rungs should fly over the barrier"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "Act 3: recall from beyond the barrier and the rungs are lost",
		"scene": "res://scenes/rooms/act3_rungs.tscn",
		"out": "act3_rungs_lost.png",
		"input": RUNGS_UP + ";move_right:110;-:40;throw:40;-:90",
		"zoom": 1.0,
		"centre": (700, 220),
		"checks": [
			{"type": "contains", "pattern": "1 sword(s) held",
				"message": "the two rungs should have crossed the live field and been destroyed"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "Act 3: two wooden steps out of the rungs room",
		"scene": "res://scenes/rooms/act3_rungs.tscn",
		"out": "act3_rungs_out.png",
		"input": RUNGS_RECALLED + (
			";move_right:40;-:40;throw:4;-:40;move_right:6;-:4;move_right,jump:14;-:30;"
			"move_right,jump:16;-:30;throw:4;-:40;move_right:8;-:4;move_right,jump:14;-:30;"
			"move_right,jump:16;move_right:40"
		),
		"zoom": 1.0,
		"centre": (900, 220),
		"checks": [
			{"type": "player_position", "min_x": 1060.0, "max_y": 190.0,
				"message": "the hero should be up on the way out"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "Act 3: a sword thrown at the generator breaks on it",
		"scene": "res://scenes/rooms/act3_generator.tscn",
		"out": "act3_generator_thrown.png",
		"input": (
			"move_right:157;-:40;move_right,jump:14;-:30;move_right,jump:14;-:30;"
			"move_right:1;-:4;throw:4;-:30"
		),
		"zoom": 1.0,
		"centre": (700, 220),
		"checks": [
			{"type": "contains", "pattern": "2 sword(s) held",
				"message": "the sword thrown at the casing should be gone"},
			{"type": "contains", "pattern": "capture: no swords in play",
				"message": "and not stuck in it"},
			{"type": "contains", "pattern": "capture: generator live",
				"message": "the generator cannot be beaten by throwing"},
		],
	},
	{
		"name": "Act 3: standing still under the generator's arc kills",
		"scene": "res://scenes/rooms/act3_generator.tscn",
		"out": "act3_generator_struck.png",
		"input": "move_right:157;-:150",
		"zoom": 1.0,
		"centre": (700, 220),
		"checks": [
			{"type": "contains", "pattern": "1 death(s)",
				"message": "the arc should strike where the hero stood"},
		],
	},
	{
		"name": "Act 3: bridge all three breaks and the generator shorts",
		"scene": "res://scenes/rooms/act3_generator.tscn",
		"out": "act3_generator_shorted.png",
		"input": GENERATOR_LOOP + ";move_right:30;-:60",
		"zoom": 1.0,
		"centre": (700, 220),
		"checks": [
			{"type": "contains", "pattern": "capture: generator SHORTED",
				"message": "closing the loop should short the generator"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "and lift the gate"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "dodging the arc after the last throw"},
		],
	},
	{
		"name": "Act 3: recall the swords and walk out past the dead generator",
		"scene": "res://scenes/rooms/act3_generator.tscn",
		"out": "act3_generator_out.png",
		"input": GENERATOR_LOOP + ";move_right:30;-:20;throw:40;-:60;move_right:80",
		"zoom": 1.0,
		"centre": (800, 220),
		"checks": [
			{"type": "contains", "pattern": "3 sword(s) held",
				"message": "a shorted loop is dead copper, so every sword comes home"},
			{"type": "player_position", "min_x": 960.0,
				"message": "the hero should be through the gate"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "M13 bench: one gem set leaves the gate shut",
		"scene": "res://scenes/rooms/room_m13_gems.tscn",
		"out": "room_m13_one_gem.png",
		"input": "move_right:120;-:10",
		"zoom": 1.0,
		"centre": (500, 220),
		"checks": [
			{"type": "contains", "pattern": "2 gem(s) held",
				"message": "three picked up, one set"},
			{"type": "count_regex", "pattern": r"holder FILLED", "count": 1,
				"message": "only the first holder should have its gem"},
			{"type": "contains_regex", "pattern": r"gate at .* SHUT",
				"message": "one break closed of three opens nothing"},
		],
	},
	{
		"name": "M13 bench: three gems close the circuit and open the gate",
		"scene": "res://scenes/rooms/room_m13_gems.tscn",
		"out": "room_m13_three_gems.png",
		"input": (
			"move_right:120;move_right,jump:14;move_right:30;move_right,jump:14;"
			"move_right:30;move_right,jump:14;move_right:60"
		),
		"zoom": 1.0,
		"centre": (500, 220),
		"checks": [
			{"type": "count_regex", "pattern": r"holder FILLED", "count": 3,
				"message": "every holder should have its gem"},
			{"type": "contains_regex", "pattern": r"gate at .* OPEN",
				"message": "and current should reach the switch"},
		],
	},
	{
		"name": "Act 4: cut the gallery's shelf down and take its gem",
		"scene": "res://scenes/rooms/act4_gallery.tscn",
		"out": "act4_gallery_gem.png",
		"input": (
			"move_right:80;move_right,jump:14;-:30;throw:4;-:30;move_right:4;-:2;"
			"move_right,jump:14;-:30;move_right,jump:14;-:30;move_right:30;-:6;throw:4;"
			"-:90;move_right:90;-:30"
		),
		"zoom": 1.0,
		"centre": (560, 220),
		"checks": [
			{"type": "contains", "pattern": "capture: shelf CUT",
				"message": "a throw from the gallery should knock the shelf away"},
			{"type": "contains", "pattern": "1 gem(s) held",
				"message": "and the fallen gem should be picked up"},
			{"type": "contains", "pattern": "2 sword(s) held",
				"message": "the shelf sword flew on and came home; the step sword is still in the wood"},
		],
	},
	{
		"name": "Act 4: kill the guard from the step and take its gem",
		"scene": "res://scenes/rooms/act4_guard.tscn",
		"out": "act4_guard_gem.png",
		"input": "move_right:100;-:540;throw:4;-:30;move_right:200;-:10",
		"zoom": 1.0,
		"centre": (600, 220),
		"checks": [
			{"type": "contains", "pattern": "capture: no enemies remaining",
				"message": "a throw from the step should kill the guard head on"},
			{"type": "contains", "pattern": "1 gem(s) held",
				"message": "and the gem it carried should be picked up"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "nobody should have died"},
		],
	},
	{
		"name": "Act 4: three gems, the dais seam, and the dragon finishes Volta",
		"scene": "res://scenes/rooms/act4_throne.tscn",
		"out": "act4_throne_won.png",
		"input": THRONE_BRIDGED + ";-:320;move_right:20;-:30",
		"zoom": 1.0,
		"centre": (900, 200),
		"checks": [
			{"type": "count_regex", "pattern": r"holder FILLED", "count": 3,
				"message": "the two carried gems and the shelf's should all be set"},
			{"type": "contains", "pattern": "capture: chains FREE",
				"message": "current held on the chains should burn them through"},
			{"type": "contains", "pattern": "capture: volta DEFEATED",
				"message": "and the dragon should put Volta in the fire"},
			{"type": "player_position", "min_x": 870.0,
				"message": "the hero should reach the dragon, which is the way out"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "the hall's current dies with him, so the dais is safe"},
		],
	},
	{
		"name": "Act 4: Volta's pull tears the bridge out and the burn starts again",
		"scene": "res://scenes/rooms/act4_throne.tscn",
		"out": "act4_throne_pulled.png",
		# Dodge bolts 0 and 1, then bridge just before cast 2, which is a pull.
		"input": THRONE_PREFIX + ";move_left:16;-:100;move_left:16;-:80;move_right:28;-:4;throw:4;-:60",
		"zoom": 1.0,
		"centre": (900, 200),
		"checks": [
			{"type": "contains", "pattern": "STRIKING (pull)",
				"message": "the cast that lands should be a pull"},
			{"type": "contains", "pattern": "capture: chains holding, burn 0.0",
				"message": "a pull mid-burn should leave the chains on, the burn started again"},
			{"type": "not_contains", "pattern": "sword embedded",
				"message": "every embedded sword should have been torn out"},
			{"type": "contains", "pattern": "capture: no deaths",
				"message": "and nobody should have died, so this is the pull and not a respawn"},
		],
	},
	{
		"name": "Act 4: ride the dragon out between the pillars",
		"scene": "res://scenes/rooms/act4_flight.tscn",
		"out": "act4_flight_out.png",
		"input": "-:205;climb_down:28;-:100;climb_up:39;-:95;climb_down:28;-:100;climb_down:14;-:300",
		"zoom": 1.0,
		"centre": (2100, 180),
		"checks": [
			{"type": "contains", "pattern": "0 crash(es), FINISHED",
				"message": "the course should be flyable with up and down alone"},
		],
	},
	{
		"name": "Act 4: a pillar sends the flight back to the start",
		"scene": "res://scenes/rooms/act4_flight.tscn",
		"out": "act4_flight_crash.png",
		"input": "climb_up:200;-:60",
		"zoom": 1.0,
		"centre": (400, 180),
		"checks": [
			{"type": "contains_regex", "pattern": r"rider at \d+, [1-9]\d* crash",
				"message": "hugging the ceiling should hit the first pillar"},
			{"type": "not_contains", "pattern": "FINISHED",
				"message": "and the flight should start again"},
		],
	},
]
