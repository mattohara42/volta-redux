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

## The far layers drawn by `Backdrop` while the act has no painted background:
## 0 none, 1 the caverns, 2 the works, 3 the hall (`Backdrop.Style`).
@export_enum("None", "Cavern", "Works", "Hall") var backdrop: int = 0

@export_group("Light")
## What the dark is in this act: everything no light reaches is multiplied by
## this (`LightField`). White is no dark at all. A coloured dark, never a grey
## one (`ART_DIRECTION.md`), and `test_light_field.gd` holds it to that.
@export var ambient_light: Color = Color.WHITE
## How much darker the top of a room is than its floor, 0 to 1. Light in this
## game comes from below.
@export_range(0.0, 1.0) var ceiling_dim: float = 0.0
