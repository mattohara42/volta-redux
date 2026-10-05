## The game's name over the first room of a new game, fading as soon as the
## player moves. It asks nothing and holds nothing up: the room is live
## underneath it from the first frame, so a player who already knows the game
## is running before the title has gone.
##
## Shown by `ActState` when a game starts: at launch, in the act the save
## picks up in, after the ending, and on the pause menu's NEW GAME.
## A room loaded any other way (a bench, F2, the capture tool) never shows it.
class_name OpeningCard
extends CanvasLayer

const TITLE := "VOLTA REDUX"
const SUBTITLE := "LOTHAR OF THE HILL PEOPLE"
## Over the room and the HUD, under an act card.
const LAYER := 90
## How long the title holds if nobody moves, and how long it takes to go.
const HOLD_SECONDS: float = 4.0
const FADE_SECONDS: float = 1.2
const MOVES: PackedStringArray = ["move_left", "move_right", "jump", "throw", "climb_up", "climb_down"]

var _box: VBoxContainer
var _clock := 0.0
var _leaving := false


## `act_title` is the act the game is starting in, under the name.
static func make(act_title: String, title_size: int) -> OpeningCard:
	var card := OpeningCard.new()
	card.layer = LAYER
	card._box = VBoxContainer.new()
	card._box.set_anchors_preset(Control.PRESET_FULL_RECT)
	card._box.alignment = BoxContainer.ALIGNMENT_CENTER
	card._box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card._box)
	card._line(TITLE, title_size * 2, Palette.FIRE_HOT)
	card._line(SUBTITLE, title_size / 2, Palette.STONE_LIT)
	card._line("", title_size / 2, Palette.STONE_LIT)
	card._line(act_title, title_size / 2 + 2, Palette.FIRE_CORE)
	return card


func _line(text: String, size: int, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	# A coloured dark under the letters, never a black one (`ART_DIRECTION.md`).
	label.add_theme_color_override("font_outline_color", Palette.STONE_DEEP.darkened(0.4))
	label.add_theme_constant_override("outline_size", maxi(size / 6, 2))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(label)


func _process(delta: float) -> void:
	_clock += delta
	if not _leaving:
		for action in MOVES:
			if Input.is_action_pressed(action):
				_leaving = true
		if _clock >= HOLD_SECONDS:
			_leaving = true
		if _leaving:
			_clock = 0.0
		return
	_box.modulate.a = 1.0 - clampf(_clock / FADE_SECONDS, 0.0, 1.0)
	if _clock >= FADE_SECONDS:
		queue_free()
