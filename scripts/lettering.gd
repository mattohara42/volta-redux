## The game's one typeface, for every word a player reads: Jersey 10
## (`assets/fonts/`), set on its own grid with no smoothing, so a letter is
## made of art pixels like everything around it (`ART_DIRECTION.md`,
## *Lettering*). The debug panel keeps Godot's own font: it is an instrument,
## not part of the game.
##
## Smoothing is switched off here rather than in the font's import settings,
## because `*.import` is gitignored and would hold on one machine only.
class_name Lettering
extends RefCounted

const PATH := "res://assets/fonts/Jersey10-Regular.ttf"
## The font is drawn on a 10 px grid. Any other size makes its pixels uneven.
const GRID := 10
const SMALL := 10
const BODY := 20
const TITLE := 40

static var _font: FontFile = null


static func font() -> FontFile:
	if _font == null:
		_font = (load(PATH) as FontFile).duplicate() as FontFile
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _font


## `control` lettered at `size` in `colour`, with a shadow one font pixel down
## and right in a coloured dark, never a black one, so the words hold over a
## busy room.
static func apply(control: Control, size: int, colour: Color) -> void:
	var step := maxi(size / GRID, 1)
	control.add_theme_font_override("font", font())
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", colour)
	control.add_theme_color_override("font_shadow_color", Palette.STONE_DEEP.darkened(0.4))
	control.add_theme_constant_override("shadow_offset_x", step)
	control.add_theme_constant_override("shadow_offset_y", step)
	control.add_theme_constant_override("shadow_outline_size", 0)


## Whether `size` sits on the font's grid.
static func on_grid(size: int) -> bool:
	return size > 0 and size % GRID == 0
