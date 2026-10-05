## Act state, the one place that knows how rooms connect (`CLAUDE.md`: rooms are
## scenes, and a room never reaches into another room). An autoload, `ActState`.
##
## A room ends at a `RoomExit`, which hands the hero over here. This finds the
## room in its act, carries the swords in hand into the next room, and at the
## end of an act shows its card and moves on to the next act's first room, or
## after the last act shows the ending and starts a new game. Rooms loaded any other way (F2, a bench,
## `tools/dev.sh play`) start as they always did.
##
## It also keeps the save (`SavePoint`): the act you are in and the run's
## tally, written as each act begins and at each exit. Launching the game
## picks up at the start of the act it was left in.
extends Node

const AUDIO: AudioConfig = preload("res://config/audio.tres")
const ATMOSPHERE: AtmosphereConfig = preload("res://config/atmosphere.tres")
const ACTS: Array[ActConfig] = [preload("res://config/act1.tres"), preload("res://config/act2.tres"), preload("res://config/act3.tres"), preload("res://config/act4.tres")]
const SWORD: SwordConfig = preload("res://config/sword.tres")
const SAVE := "user://save.cfg"

## Swords to arrive with, or -1 for none carried. Read once, by the next hero.
var _carried := -1
## Gems to arrive with, or -1 for none carried. Read once, by the next hero.
var _carried_gems := -1
## The room being left, between its exit and the next room, so an exit cannot
## fire twice. Kept per room rather than as a flag the next hero clears,
## because a room with no hero in it (the ending's flight) must still be able
## to leave.
var _leaving_from := ""
## The run so far, for the end card: deaths, and seconds played while the
## game was not paused. A new game starts both again.
var run_deaths := 0
var run_seconds := 0.0
## `run_deaths` when the current act began, for the act's own card.
var _act_start_deaths := 0
## The act being played, by index, and the swords carried into it (-1 for the
## room's own count), which is what a save starts the act again with.
var _act_now := 0
var _act_swords := -1
## Off under a tool or the tests (`SavePoint.enabled`).
var _saving := SavePoint.enabled(OS.get_cmdline_args())
## Whether an act is being played at all, so a bench opened and closed never
## overwrites the save with a game it was not part of.
var _in_game := false


func _ready() -> void:
	# Launched straight into the first room: that is a game starting, and it
	# opens with the title, in the act the save left off in. Deferred, so the
	# main scene is in the tree to be read.
	_start_or_resume.call_deferred()


func _process(delta: float) -> void:
	if not get_tree().paused:
		run_seconds += delta


## Counted by the hero, once per death.
func record_death() -> void:
	run_deaths += 1


func _start_or_resume() -> void:
	# Through a variable: indexing the constant folds it at parse time, before
	# the act's resource has its rooms, and fails to compile.
	var first: ActConfig = ACTS[0]
	var scene := get_tree().current_scene
	if scene == null or first.rooms.size() == 0 or scene.scene_file_path != first.rooms[0]:
		return
	_in_game = true
	var saved := _read_save()
	if saved.is_empty():
		get_tree().root.add_child(OpeningCard.make(first.title, first.card_font_size))
		return
	run_deaths = saved["deaths"]
	run_seconds = saved["seconds"]
	_act_start_deaths = saved["act_deaths_before"]
	_act_now = saved["act"]
	_act_swords = saved["swords"]
	var act: ActConfig = ACTS[_act_now]
	if _act_now > 0:
		_carried = _act_swords
		# Deferred again, so the first room finishes its own deferred setup
		# before it is swapped out.
		get_tree().change_scene_to_file.call_deferred(act.rooms[0])
	get_tree().root.add_child(OpeningCard.make(act.title, act.card_font_size))


## Starts the game again from Act 1 with nothing carried and the run's tally
## at nothing, and saves that. The pause menu's NEW GAME, and the ending.
func new_game() -> void:
	run_deaths = 0
	run_seconds = 0.0
	_carried = -1
	_carried_gems = -1
	_leaving_from = ""
	_begin_act(0, -1)
	var first: ActConfig = ACTS[0]
	get_tree().change_scene_to_file(first.rooms[0])
	get_tree().root.add_child(OpeningCard.make(first.title, first.card_font_size))


## Act `index` begins, with `swords` carried into it: the point a save
## starts again from.
func _begin_act(index: int, swords: int) -> void:
	_in_game = true
	_act_now = index
	_act_swords = swords
	_act_start_deaths = run_deaths
	_write_save()


func _read_save() -> Dictionary:
	if not _saving:
		return {}
	var file := ConfigFile.new()
	if file.load(SAVE) != OK or not file.has_section(SavePoint.SECTION):
		return {}
	var data := {}
	for key in file.get_section_keys(SavePoint.SECTION):
		data[key] = file.get_value(SavePoint.SECTION, key)
	return SavePoint.resume(data, ACTS.size(), SWORD.max_swords)


func _write_save() -> void:
	if not _saving or not _in_game:
		return
	var file := ConfigFile.new()
	var data := SavePoint.make(_act_now, _act_swords, _act_start_deaths, run_deaths, run_seconds)
	for key: String in data:
		file.set_value(SavePoint.SECTION, key, data[key])
	file.save(SAVE)


## The tally since the last exit is kept when the game is closed mid-room.
func _exit_tree() -> void:
	_write_save()


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
	# A room launched on its own (`tools/dev.sh play`) is in an act the save
	# did not know about, carried into with nothing it can name.
	var index := ACTS.find(act)
	_in_game = true
	if index != _act_now:
		_act_now = index
		_act_swords = -1
		_act_start_deaths = run_deaths
	var next := ActRoute.next_room(act.rooms, room_path)
	if next != "":
		_carried = ActRoute.carried(swords_held, max_swords)
		_carried_gems = gems_held
		_write_save()
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
	# The dark comes up over the frozen room, then the words over the dark.
	var curtain := Dissolve.cover(card, ATMOSPHERE.card_cover_seconds, card.layer - 1)
	var label := Label.new()
	var index := ACTS.find(act)
	var ending := ActRoute.is_ending(index, ACTS.size())
	var act_deaths := run_deaths - _act_start_deaths
	label.text = act.title + ("\n\nThe end.\n\n" + ActRoute.tally(run_deaths, run_seconds) if ending else "\n\n" + ActRoute.act_tally(act_deaths))
	label.modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(label, "modulate:a", 1.0, ATMOSPHERE.card_cover_seconds).set_delay(ATMOSPHERE.card_cover_seconds * 0.6)
	label.add_theme_font_size_override("font_size", act.card_font_size)
	label.add_theme_color_override("font_color", Palette.FIRE_HOT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(label)
	# The act ends on three low notes, heard over the frozen room.
	var sting := AudioStreamPlayer.new()
	sting.stream = AUDIO.card
	sting.bus = Sfx.BUS
	sting.process_mode = Node.PROCESS_MODE_ALWAYS
	card.add_child(sting)
	get_tree().root.add_child(card)
	if sting.stream != null:
		sting.play()
	# The act's music gives way to the card; the next act's room starts its own.
	var audio := get_node_or_null("/root/Audio")
	if audio != null:
		audio.fade_out()
	get_tree().paused = true
	await get_tree().create_timer(act.complete_card_seconds, true).timeout
	get_tree().paused = false
	curtain.queue_free()
	card.queue_free()
	if ending:
		new_game()
		return
	var next_index := ActRoute.act_after(index, ACTS.size())
	var next := ACTS[next_index]
	_carried = ActRoute.carried(swords_held, max_swords)
	_begin_act(next_index, _carried)
	get_tree().change_scene_to_file(next.rooms[0])
