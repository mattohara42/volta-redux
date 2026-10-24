## The game's name over the first room of a new game, or an act's name over
## its first room as the act begins, fading as soon as the player moves. It asks nothing and holds nothing up: the room is live
## underneath it from the first frame, so a player who already knows the game
## is running before the title has gone.
##
## Shown by `ActState` when a game starts: at launch, in the act the save
## picks up in, after the ending, and on the pause menu's NEW GAME. And
## without the game's name as each act after the first begins, so every act
## is named on the way in and not only on the way out.
## A room loaded any other way (a bench, F2, the capture tool) never shows it.
class_name OpeningCard
extends CanvasLayer

const TITLE := "VOLTA REDUX"
const SUBTITLE := "LOTHAR OF THE HILL PEOPLE"
## Over the room and the HUD, under an act card.
const LAYER := 90
## The words sit in the top of the screen, clear of the floor the hero
## starts on, so the first steps of a room are never under them.
const TOP := 56.0
## How long the title holds if nobody moves, and how long it takes to go.
const HOLD_SECONDS: float = 4.0
const FADE_SECONDS: float = 1.2
const MOVES: PackedStringArray = ["move_left", "move_right", "jump", "throw", "climb_up", "climb_down"]

var _box: VBoxContainer
var _clock := 0.0
var _leaving := false


## `act_title` is the act the game is starting in, under the name, set at
## `size` (the act's `card_font_size`). `with_name` false is an act beginning
## mid-game: its name alone.
static func make(act_title: String, size: int, with_name: bool = true) -> OpeningCard:
	var card := OpeningCard.new()
	card.layer = LAYER
	card._box = VBoxContainer.new()
	card._box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	card._box.offset_top = TOP
	card._box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card._box)
	if with_name:
		card._line(TITLE, size * 2, Palette.FIRE_HOT)
		card._line(SUBTITLE, size, Palette.FIRE_HOT)
		card._line("", size / 2, Palette.FIRE_HOT)
	card._line(act_title.to_upper(), size, Palette.FIRE_CORE)
	return card


func _line(text: String, size: int, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Lettering.apply(label, size, colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(label)


func _process(delta: float) -> void:
	_clock += delta
	if not _leaving:
		# A fresh press, so a key still held from the act before does not
		# take an act's name away the moment it appears.
		for action in MOVES:
			if Input.is_action_just_pressed(action):
				_leaving = true
		if _clock >= HOLD_SECONDS:
			_leaving = true
		if _leaving:
			_clock = 0.0
		return
	_box.modulate.a = 1.0 - clampf(_clock / FADE_SECONDS, 0.0, 1.0)
	if _clock >= FADE_SECONDS:
		queue_free()
