## The pure rule behind the rig track-parity check. See scripts/rig track
## tests for the real rigs; this proves the rule itself, on data it controls,
## so the check can be trusted to fail when it should.
extends TestCase


func test_identical_track_sets_report_nothing_missing() -> void:
	var sets := {
		"idle": PackedStringArray(["Hip:position:y", "Hip:rotation"]),
		"run": PackedStringArray(["Hip:rotation", "Hip:position:y"]),
	}
	check_eq(
		AnimationHygiene.missing_tracks_per_animation(sets), {},
		"two animations keying the same tracks in a different order report nothing missing"
	)


## PR #51, restated as data: idle keys a property run does not.
func test_a_track_only_one_animation_keys_is_reported_as_missing_from_the_other() -> void:
	var sets := {
		"idle": PackedStringArray(["Hip:position:y", "Hip:rotation"]),
		"run": PackedStringArray(["Hip:rotation"]),
	}
	var missing := AnimationHygiene.missing_tracks_per_animation(sets)
	check(missing.has("run"), "run is missing something")
	check(not missing.has("idle"), "idle keys everything run keys")
	check_eq(
		missing.get("run", PackedStringArray()), PackedStringArray(["Hip:position:y"]),
		"run is missing exactly the track idle keys and it does not"
	)


func test_three_animations_where_the_middle_one_is_short_a_track() -> void:
	var sets := {
		"idle": PackedStringArray(["a", "b"]),
		"run": PackedStringArray(["a"]),
		"jump": PackedStringArray(["a", "b"]),
	}
	var missing := AnimationHygiene.missing_tracks_per_animation(sets)
	check_eq(missing.keys(), ["run"], "only the short animation is reported")


func test_a_single_animation_is_always_complete() -> void:
	var sets := {"idle": PackedStringArray(["a", "b", "c"])}
	check_eq(
		AnimationHygiene.missing_tracks_per_animation(sets), {},
		"nothing to disagree with when there is only one animation"
	)


func test_no_animations_is_not_a_failure() -> void:
	check_eq(
		AnimationHygiene.missing_tracks_per_animation({}), {},
		"an empty rig has nothing missing, it just has nothing"
	)
