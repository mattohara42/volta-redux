## Act state, the one place that knows how rooms connect (`CLAUDE.md`: rooms are
## scenes, and a room never reaches into another room). An autoload, `ActState`.
##
## A room ends at a `RoomExit`, which hands the hero over here. This finds the
## room in its act, carries the swords in hand into the next room, and at the
## end of the act shows the act-complete card and starts the act again: the
## placeholder for Act 2's first room. Rooms loaded any other way (F2, a bench,
## `tools/dev.sh play`) start as they always did.
extends Node

const ACTS: Array[ActConfig] = [preload("res://config/act1.tres")]

## Swords to arrive with, or -1 for none carried. Read once, by the next hero.
var _carried := -1
## Set between an exit and the next room, so an exit cannot fire twice.
var _leaving := false


## What the hero arriving in a room starts with. Called by `Player._ready`.
func arriving_swords(default: int) -> int:
	var count := _carried if _carried >= 0 else default
	_carried = -1
	_leaving = false
	return count


## The hero walked into the exit of `room_path` holding `swords_held`.
func leave_room(room_path: String, swords_held: int, max_swords: int) -> void:
	if _leaving:
		return
	var act := act_of(room_path)
	if act == null:
		return
	_leaving = true
	var next := ActRoute.next_room(act.rooms, room_path)
	if next != "":
		_carried = ActRoute.carried(swords_held, max_swords)
		get_tree().change_scene_to_file.call_deferred(next)
	else:
		_finish(act)


## The act `room_path` belongs to, or null for a bench.
func act_of(room_path: String) -> ActConfig:
	for act in ACTS:
		if act.rooms.has(room_path):
			return act
	return null


## The act-complete card: the room freezes under it, then the act starts over
## from its first room with a fresh hero.
func _finish(act: ActConfig) -> void:
	var card := CanvasLayer.new()
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	card.layer = 100
	var backdrop := ColorRect.new()
	backdrop.color = Palette.BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(backdrop)
	var label := Label.new()
	label.text = act.title
	label.add_theme_font_size_override("font_size", act.card_font_size)
	label.add_theme_color_override("font_color", Palette.FIRE_HOT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(label)
	get_tree().root.add_child(card)
	get_tree().paused = true
	await get_tree().create_timer(act.complete_card_seconds, true).timeout
	get_tree().paused = false
	card.queue_free()
	_carried = -1
	get_tree().change_scene_to_file(act.rooms[0])
