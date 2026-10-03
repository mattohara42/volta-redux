## One act: its name and its rooms, in the order you walk them. The order lives
## here rather than in any room, because a room that knows what comes next
## cannot be tested or reordered (`CLAUDE.md`). Reordering an act is an edit to
## its `.tres` and nothing else.
class_name ActConfig
extends Resource

## What the act-complete card calls it. A string a player reads.
@export var title: String = ""
## Scene paths, first room first. Exits only lead forward (Matt, 2026-10-03).
@export var rooms: PackedStringArray = []
## How long the act-complete card holds before the act starts again, seconds.
@export var complete_card_seconds: float = 2.5
## The card's lettering, in the same size as the death messages.
@export var card_font_size: int = 24
