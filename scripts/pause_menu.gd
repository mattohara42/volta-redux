## The pause menu, an autoload (`Pause`). Escape or a pad's Start freezes the
## room and offers: go on, start the room again, the music's and the effects'
## levels (kept between sessions by `Audio`), a new game, and leave.
##
## Every colour is `Palette`'s and every box is drawn here, because Godot's
## default theme is neutral grey, which `ART_DIRECTION.md` does not allow.
## It never opens over an act's card, which has paused the room itself.
class_name PauseMenu
extends CanvasLayer

## Over the room, the HUD and the opening card; under an act's card.
const LAYER := 95
const LEVEL_STEPS := 10
const TITLE_SIZE := 28
const ITEM_SIZE := 14
const NEW_GAME := "NEW GAME"
## A new game throws the saved one away, so it asks twice.
const NEW_GAME_SURE := "NEW GAME? PRESS AGAIN"

var is_open := false
var _box: VBoxContainer
var _music: Button
var _effects: Button
var _new_game: Button


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(Palette.BACKDROP, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 4)
	centre.add_child(_box)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.add_theme_color_override("font_color", Palette.FIRE_HOT)
	_box.add_child(title)
	_item("GO ON", close)
	_item("START THE ROOM AGAIN", _restart)
	_music = _item("", func() -> void: _step(Audio.MUSIC_BUS, 1))
	_effects = _item("", func() -> void: _step(Audio.SFX_BUS, 1))
	_new_game = _item(NEW_GAME, _ask_new_game)
	_new_game.focus_exited.connect(func() -> void: _new_game.text = NEW_GAME)
	_item("LEAVE", func() -> void: get_tree().quit())
	_refresh()


func _item(text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = false
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", ITEM_SIZE)
	button.add_theme_color_override("font_color", Palette.STONE_LIT)
	button.add_theme_color_override("font_hover_color", Palette.FIRE_HOT)
	button.add_theme_color_override("font_focus_color", Palette.FIRE_HOT)
	button.add_theme_color_override("font_pressed_color", Palette.FIRE_CORE)
	var plain := StyleBoxFlat.new()
	plain.bg_color = Color(Palette.STONE_DEEP, 0.0)
	plain.content_margin_left = 12.0
	plain.content_margin_right = 12.0
	var lit := plain.duplicate() as StyleBoxFlat
	lit.bg_color = Color(Palette.STONE_DEEP, 0.9)
	lit.border_color = Palette.FIRE_FALLOFF
	lit.set_border_width_all(1)
	for state in ["normal", "disabled"]:
		button.add_theme_stylebox_override(state, plain)
	for state in ["hover", "pressed", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, lit)
	button.pressed.connect(pressed)
	_box.add_child(button)
	return button


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("pause"):
		if is_open:
			_step_focused_level()
		return
	if is_open:
		close()
	elif _can_open():
		open()


## Only over a room being played, and never over a card that has frozen it.
func _can_open() -> bool:
	return get_tree().current_scene != null and not get_tree().paused


func open() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	_new_game.text = NEW_GAME
	_refresh()
	(_box.get_child(1) as Control).grab_focus()


func close() -> void:
	is_open = false
	visible = false
	get_tree().paused = false


func _restart() -> void:
	close()
	get_tree().reload_current_scene()


func _ask_new_game() -> void:
	if _new_game.text != NEW_GAME_SURE:
		_new_game.text = NEW_GAME_SURE
		return
	_new_game.text = NEW_GAME
	close()
	ActState.new_game()


## Left and right on a level change it, the way a pad expects a setting to.
func _step_focused_level() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var bus := &""
	if focused == _music:
		bus = Audio.MUSIC_BUS
	elif focused == _effects:
		bus = Audio.SFX_BUS
	if bus == &"":
		return
	if Input.is_action_just_pressed("ui_right"):
		_step(bus, 1)
	elif Input.is_action_just_pressed("ui_left"):
		_step(bus, -1)


## One step of `bus`'s level, wrapping from full back to nothing when a press
## on the row itself goes past the top.
func _step(bus: StringName, by: int) -> void:
	var now := roundi(Audio.levels[bus] * LEVEL_STEPS)
	var next := now + by
	if next > LEVEL_STEPS:
		next = 0
	Audio.set_level(bus, clampf(float(next) / LEVEL_STEPS, 0.0, 1.0))
	_refresh()


func _refresh() -> void:
	if _music == null:
		return
	_music.text = "MUSIC    %s" % level_bar(Audio.levels[Audio.MUSIC_BUS])
	_effects.text = "EFFECTS  %s" % level_bar(Audio.levels[Audio.SFX_BUS])


## A level drawn as text: `[=======---]` for 0.7.
static func level_bar(level: float) -> String:
	var filled := clampi(roundi(level * LEVEL_STEPS), 0, LEVEL_STEPS)
	return "[%s%s]" % ["=".repeat(filled), "-".repeat(LEVEL_STEPS - filled)]
