## Whether every animation on a rig keys the same set of tracks.
##
## PR #51's bug: `idle` keyed `Hip:position:y` and `run` did not. Godot's
## AnimationTree blends per property during a crossfade, so a property only
## one side touches blends toward an undefined value the moment the other
## side's weight hits zero, which read as the hero floating. A rig where
## every animation defines every track cannot have that failure, so this is
## the rule to hold the rig to rather than a specific property to remember.
class_name AnimationHygiene


## `track_sets` is {animation_name: PackedStringArray of track paths it keys}.
## Returns {animation_name: PackedStringArray of paths some sibling keys and
## this one does not}. Empty means every animation keys the same set.
static func missing_tracks_per_animation(track_sets: Dictionary) -> Dictionary:
	var union: Dictionary = {}
	for anim_name in track_sets:
		for path in track_sets[anim_name]:
			union[path] = true

	var missing: Dictionary = {}
	for anim_name in track_sets:
		var have: Dictionary = {}
		for path in track_sets[anim_name]:
			have[path] = true
		var gaps := PackedStringArray()
		for path in union:
			if not have.has(path):
				gaps.append(path)
		if not gaps.is_empty():
			missing[anim_name] = gaps
	return missing
