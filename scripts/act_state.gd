## Act state, the one place that knows how rooms connect (`CLAUDE.md`: rooms are
## scenes, and a room never reaches into another room). An autoload, `ActState`.
##
## A room ends at a `RoomExit`, which hands the hero over here. This finds the
## room in its act, carries the swords in hand into the next room, and at the
## end of an act shows its card and moves on to the next act's first room, or
## after the last act shows the ending and starts a new game. Rooms loaded any other way (F2, a bench,
## `tools/dev.sh play`) start as they always did.
extends Node

const ACTS: Array[ActConfig] = [preload("res://config/act1.tres"), preload("res://config/act2.tres"), preload("res://config/act3.tres"), preload("res://config/act4.tres")]

## Swords to arrive with, or -1 for none carried. Read once, by the next hero.
var _carried := -1
## Gems to arrive with, or -1 for none carried. Read once, by the next hero.
var _carried_gems := -1
## The room being left, between its exit and the next room, so an exit cannot
## fire twice. Kept per room rather than as a flag the next hero clears,
## because a room with no hero in it (the ending's flight) must still be able
## to leave.
var _leaving_from := ""


## What the hero arriving in a room starts with. Called by `Player._ready`.
func arriving_swords(default: int) -> int:
	var count := _carried if _carried >= 0 else default
	_carried = -1
	_leaving_from = ""
	return count


## What gems the hero arriving in a room holds. Called by `Player._ready`.
func arriving_gems(default: int) -> int:
	var count := _carried_gems if _carried_gems >= 0 else default
	_carried_gems = -1
	return count


## The hero walked into the exit of `room_path` holding `swords_held` and
## `gems_held`. Gems belong to an act, so a new act starts with none.
func leave_room(room_path: String, swords_held: int, max_swords: int, gems_held: int = 0) -> void:
	if _leaving_from == room_path:
		return
	var act := act_of(room_path)
	if act == null:
		return
	_leaving_from = room_path
	var next := ActRoute.next_room(act.rooms, room_path)
	if next != "":
		_carried = ActRoute.carried(swords_held, max_swords)
		_carried_gems = gems_held
		get_tree().change_scene_to_file.call_deferred(next)
	else:
		_finish(act, swords_held, max_swords)


## The act `room_path` belongs to, or null for a bench.
func act_of(room_path: String) -> ActConfig:
	for act in ACTS:
		if act.rooms.has(room_path):
			return act
	return null


## The act-complete card: the room freezes under it, then the next act begins
## with what you held, as any exit carries it.
func _finish(act: ActConfig, swords_held: int, max_swords: int) -> void:
	var card := CanvasLayer.new()
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	card.layer = 100
	var backdrop := ColorRect.new()
	backdrop.color = Palette.BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(backdrop)
	var label := Label.new()
	var index := ACTS.find(act)
	var ending := ActRoute.is_ending(index, ACTS.size())
	label.text = act.title + ("\n\nThe end." if ending else "")
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
	var next := ACTS[ActRoute.act_after(index, ACTS.size())]
	# A new game after the ending carries nothing in.
	_carried = -1 if ending else ActRoute.carried(swords_held, max_swords)
	get_tree().change_scene_to_file(next.rooms[0])
