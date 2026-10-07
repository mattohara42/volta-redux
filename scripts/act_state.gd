## Act state, the one place that knows how rooms connect (`CLAUDE.md`: rooms are
## scenes, and a room never reaches into another room). An autoload, `ActState`.
##
## A room ends at a `RoomExit`, which hands the hero over here. This finds the
## room in its act, carries the swords in hand into the next room, and at the
## end of an act shows its card and moves on to the next act's first room, or
## after the last act shows the ending and starts a new game. Rooms loaded any other way (F2, a bench,
## `tools/dev.sh play`) start as they always did.
##
## It also keeps the save (`SavePoint`): the act and room you are in, the
## last brazier you lit there, what you carry, and the run's tally, written as
## each act begins, at each exit and at each brazier. Launching the game picks
## up at that brazier (Matt, 2026-10-07), or at the room's start.
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
## Where the save picks up inside the act: the room (empty for its first),
## the brazier last lit there, and what was carried at that point.
var _save_room := ""
var _save_brazier := Vector2.ZERO
var _save_has_brazier := false
var _save_swords := -1
var _save_gems := -1
## A resumed game's brazier, waiting for its room to load.
var _resume_at := Vector2.ZERO
var _resume_pending := false
## Off under a tool or the tests (`SavePoint.enabled`).
var _saving := SavePoint.enabled(OS.get_cmdline_args())
## The room being played, for `PlayLog`: where, since when, what it has
## cost, and the swords the hero arrived with. Empty outside an act's rooms.
var _room_path := ""
var _room_act := -1
var _room_seconds := 0.0
var _room_deaths := 0
var _room_causes := {}
var _room_restarts := 0
var _room_swords_in := 0
var _room_scene: Node = null
var _arrived_with := 0
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
		_room_seconds += delta
	_follow_the_room()


## Counted by the hero, once per death, with what killed them.
func record_death(cause: int = DeathMessages.Cause.ANY) -> void:
	run_deaths += 1
	if _room_path != "":
		_room_deaths += 1
		_room_causes[cause] = _room_causes.get(cause, 0) + 1


## A new room starts a new line in the play log; the same room loaded again
## (the pause menu's START THE ROOM AGAIN) is a restart of it.
func _follow_the_room() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _room_scene:
		return
	_room_scene = scene
	var path := scene.scene_file_path
	if _resume_pending and path == _save_room:
		_resume_pending = false
		_put_the_hero_at(_resume_at)
	if path == _room_path:
		_room_restarts += 1
		return
	var act := act_of(path)
	if act == null or not _saving:
		return
	_room_path = path
	_room_act = ACTS.find(act)
	_room_seconds = 0.0
	_room_deaths = 0
	_room_causes = {}
	_room_restarts = 0
	_room_swords_in = _arrived_with


## A resumed game's hero, at the brazier the save was made at. Standing in it
## lights it, as walking past it did.
func _put_the_hero_at(base: Vector2) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player != null:
			player.light_checkpoint(base)
			player.global_position = player.spawn_point


## Ends the room's line in the play log and appends it.
func _log_room(swords_out: int, ended: String) -> void:
	if _room_path == "" or not _saving:
		return
	var line := PlayLog.row(
		Time.get_datetime_string_from_system(false, true), _room_act, _room_path, _room_seconds,
		_room_deaths, _room_causes, _room_swords_in, swords_out, _room_restarts, ended
	)
	_room_path = ""
	var exists := FileAccess.file_exists(PlayLog.PATH)
	var file := FileAccess.open(PlayLog.PATH, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		return
	if exists:
		file.seek_end()
	else:
		file.store_line(PlayLog.HEADER)
	file.store_line(line)


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
	var room: String = saved["room"]
	if not act.rooms.has(room):
		room = act.rooms[0]
	_save_room = room
	_save_swords = saved["swords"]
	_save_gems = saved["gems"]
	_save_has_brazier = saved["has_brazier"]
	_save_brazier = saved["brazier"]
	_carried = _save_swords
	_carried_gems = _save_gems
	if _save_has_brazier:
		_resume_at = _save_brazier
		_resume_pending = true
	if room != scene.scene_file_path:
		# Deferred again, so the first room finishes its own deferred setup
		# before it is swapped out.
		get_tree().change_scene_to_file.call_deferred(room)
	get_tree().root.add_child(OpeningCard.make(act.title, act.card_font_size))


## Starts the game again from Act 1 with nothing carried and the run's tally
## at nothing, and saves that. The pause menu's NEW GAME, and the ending.
func new_game() -> void:
	_log_room(-1, "new game")
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
	var act: ActConfig = ACTS[index]
	_save_room = act.rooms[0]
	_save_has_brazier = false
	_save_swords = swords
	_save_gems = -1
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
	var data := SavePoint.make(
		_act_now, _save_swords, _act_start_deaths, run_deaths, run_seconds,
		_save_room, _save_brazier, _save_has_brazier, _save_gems
	)
	for key: String in data:
		file.set_value(SavePoint.SECTION, key, data[key])
	file.save(SAVE)


## The tally since the last exit is kept when the game is closed mid-room.
func _exit_tree() -> void:
	_log_room(-1, "quit")
	_write_save()


## What the hero arriving in a room starts with. Called by `Player._ready`.
func arriving_swords(default: int) -> int:
	var count := _carried if _carried >= 0 else default
	_arrived_with = count
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
	_log_room(swords_held, "exit")
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
		_save_room = next
		_save_has_brazier = false
		_save_swords = _carried
		_save_gems = _carried_gems
		_write_save()
		get_tree().change_scene_to_file.call_deferred(next)
	else:
		_finish(act, swords_held, max_swords)


## The hero lit the brazier at `base` in `room_path`, holding `swords` and
## `gems`: the point a save picks up from. Called by `Player`.
func checkpoint_lit(room_path: String, base: Vector2, swords: int, gems: int) -> void:
	var act := act_of(room_path)
	if act == null or ACTS.find(act) != _act_now:
		return
	_save_room = room_path
	_save_brazier = base
	_save_has_brazier = true
	_save_swords = swords
	_save_gems = gems
	_write_save()


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
