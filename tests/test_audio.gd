## The sound effects and how they are wired (`assets/audio/README.md`). What a
## test can hold is that every sound named is there, that the ones meant to
## loop do, and that the sword's four state sounds are four different sounds.
## What they sound like is a person's to judge.
extends TestCase

const AUDIO := "res://config/audio.tres"
const AUDIO_SCRIPT: GDScript = preload("res://scripts/audio.gd")
const SWORD := "res://config/sword.tres"
const AUDIO_FIELDS: PackedStringArray = [
	"jump", "land", "flip", "die", "respawn", "brazier", "chest", "kill", "gem", "gem_set",
	"switch", "gate", "zap", "geyser", "crumble", "roar", "short", "bolt", "pull", "card",
	"lava_loop", "arc_loop",
]
const SWORD_FIELDS: PackedStringArray = [
	"throw_sound", "catch_sound", "embed_sound", "recall_sound",
	"fly_sound", "break_sound", "clatter_sound", "fry_sound",
]


func test_every_sound_the_game_names_is_there() -> void:
	var audio: AudioConfig = load(AUDIO)
	check(audio != null, "config/audio.tres loads")
	for field in AUDIO_FIELDS:
		check(audio.get(field) is AudioStream, "audio.tres %s is a sound" % field)
	var sword: SwordConfig = load(SWORD)
	for field in SWORD_FIELDS:
		check(sword.get(field) is AudioStream, "sword.tres %s is a sound" % field)


## M15: "the throw, the catch, the embed and the recall need four
## distinguishable sounds". Four different files is the least of that.
func test_the_sword_states_are_four_different_sounds() -> void:
	var sword: SwordConfig = load(SWORD)
	var paths := {}
	for field in ["throw_sound", "catch_sound", "embed_sound", "recall_sound"]:
		var stream: AudioStream = sword.get(field)
		paths[stream.resource_path] = true
	check_eq(paths.size(), 4, "four files for four states")


## The fly loop is what says where a sword is while it is in the air, so it
## has to keep going for as long as the sword does.
func test_the_fly_sound_loops() -> void:
	var sword: SwordConfig = load(SWORD)
	var fly := sword.fly_sound as AudioStreamWAV
	check(fly != null, "the fly sound is a WAV")
	if fly != null:
		check(fly.loop_mode == AudioStreamWAV.LOOP_FORWARD, "and it loops")


## The two buses the mix is set on, read from the layout Godot loads.
func test_the_music_and_effects_buses_exist() -> void:
	var text := FileAccess.get_file_as_string("res://default_bus_layout.tres")
	check(text.contains("&\"%s\"" % "Music"), "a Music bus")
	check(text.contains("&\"%s\"" % "Sfx"), "an Sfx bus")
	check(text.contains("&\"%s\"" % "Ambience"), "an Ambience bus")
	check(text.contains("AudioEffectLowPassFilter"), "the Music bus can be muffled")


## Every act has a loop of its own, and every loop loops once `Audio` plays
## it: a track that stops after ninety seconds leaves a player in a silent
## castle. Played through `looping`, the way `Audio` plays it, because the
## loop flag is not in anything this repo commits.
func test_every_act_has_music_that_loops() -> void:
	var tracks := {}
	for n in 4:
		var act: ActConfig = load("res://config/act%d.tres" % (n + 1))
		var music := AUDIO_SCRIPT.looping(act.music) as AudioStreamOggVorbis
		check(music != null, "act %d has music" % (n + 1))
		if music != null:
			check(music.loop, "act %d's music loops" % (n + 1))
			tracks[music.resource_path] = true
	check_eq(tracks.size(), 4, "four acts, four tracks")


## The ride out is the one room that plays its own track, and it loops in case
## the flight takes longer than the track does.
func test_the_flight_plays_its_own_music() -> void:
	var flight := AUDIO_SCRIPT.looping(Act4Flight.FLIGHT_MUSIC) as AudioStreamOggVorbis
	check(flight != null, "the flight has music")
	if flight != null:
		check(flight.loop, "and it loops")
		var act4: ActConfig = load("res://config/act4.tres")
		check(flight != act4.music, "and it is not the hall's")


## Each act has a bed of its own under the music, and the loops that sit on
## things loop from their own files (`smpl`), as the fly sound does.
func test_every_act_has_an_ambience_and_the_room_loops_loop() -> void:
	var beds := {}
	for n in 4:
		var act: ActConfig = load("res://config/act%d.tres" % (n + 1))
		var bed := AUDIO_SCRIPT.looping(act.ambience) as AudioStreamOggVorbis
		check(bed != null, "act %d has an ambience" % (n + 1))
		if bed != null:
			check(bed.loop, "act %d's ambience loops" % (n + 1))
			beds[bed.resource_path] = true
	check_eq(beds.size(), 4, "four acts, four beds")
	var audio: AudioConfig = load(AUDIO)
	for field in ["lava_loop", "arc_loop"]:
		var wav := audio.get(field) as AudioStreamWAV
		check(wav != null and wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s loops" % field)
