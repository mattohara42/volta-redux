## The sound effects and how they are wired (`assets/audio/README.md`). What a
## test can hold is that every sound named is there, that the ones meant to
## loop do, and that the sword's four state sounds are four different sounds.
## What they sound like is a person's to judge.
extends TestCase

const AUDIO := "res://config/audio.tres"
const SWORD := "res://config/sword.tres"
const AUDIO_FIELDS: PackedStringArray = [
	"jump", "land", "flip", "die", "respawn", "brazier", "chest", "kill", "gem", "gem_set",
	"switch", "gate", "zap", "geyser", "crumble", "roar", "short", "bolt", "pull", "card",
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
	check(text.contains("AudioEffectLowPassFilter"), "the Music bus can be muffled")
