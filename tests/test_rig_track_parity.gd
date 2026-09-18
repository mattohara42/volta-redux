## Every rig scene in the game, checked against AnimationHygiene's rule: every
## animation on a rig's AnimationPlayer keys the same set of tracks.
##
## PR #51 was exactly this, caught by Matt playing rather than by anything in
## the suite: idle keyed a property run did not, and the crossfade floated the
## hero off the ground. This is the automated substitute for noticing it in an
## animation timeline, which CLAUDE.md's workflow does not ask Claude to open.
##
## Forward-compatible with M7's enemy rigs on purpose: any scene named
## `*_rig.tscn` is checked, so a new rig is covered the day it gets an
## AnimationPlayer, with no change needed here.
extends TestCase

const RIGS_DIR := "res://scenes"


func test_every_rig_with_an_animation_player_has_full_track_parity() -> void:
	var rig_paths := _discover_rigs()
	check(rig_paths.size() > 0, "found at least one rig scene to check")
	for path in rig_paths:
		var packed := load(path) as PackedScene
		if packed == null:
			check(false, "%s: cannot load" % path)
			continue
		var rig := packed.instantiate()
		var player := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if player == null:
			# Not every rig has animations yet (the bat has none as of M6),
			# and that is a fact about where the build is, not a failure.
			rig.free()
			continue
		var track_sets := _track_sets(player)
		var missing := AnimationHygiene.missing_tracks_per_animation(track_sets)
		for anim_name in missing:
			check(
				false,
				"%s: animation \"%s\" is missing track(s) %s that a sibling animation keys" % [
					path, anim_name, ", ".join(missing[anim_name])
				]
			)
		if missing.is_empty():
			check(true, "%s: every animation keys the same tracks" % path)
		rig.free()


func _track_sets(player: AnimationPlayer) -> Dictionary:
	var sets := {}
	for anim_name in player.get_animation_list():
		var anim := player.get_animation(anim_name)
		var paths := PackedStringArray()
		for i in anim.get_track_count():
			paths.append(str(anim.track_get_path(i)))
		sets[anim_name] = paths
	return sets


## Rigs, not the rig-test benches: `hero_rig.tscn`, not
## `hero_rig_test.tscn`. The suffix excludes the second on purpose.
func _discover_rigs() -> PackedStringArray:
	var found: PackedStringArray = []
	var directory := DirAccess.open(RIGS_DIR)
	if directory == null:
		return found
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if entry.ends_with("_rig.tscn"):
			found.append(RIGS_DIR.path_join(entry))
		entry = directory.get_next()
	directory.list_dir_end()
	found.sort()
	return found
