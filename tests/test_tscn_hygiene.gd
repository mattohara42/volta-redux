## The pure rule behind the resource-file duplicate-key check. See
## test_repo_tscn_hygiene.gd for the real files; this proves the rule on text
## it controls, so the check can be trusted to fail when it should.
extends TestCase


func test_a_clean_resource_reports_nothing() -> void:
	var text := '''[gd_resource type="Resource" format=3]

[resource]
speed = 420.0
max_range = 200.0
'''
	check_eq(TscnHygiene.duplicate_keys(text), [], "distinct keys in one block report nothing")


## PR #53, restated as text: the same key declared twice in one animation
## block, the way a hand edit that forgot to delete the old lines would leave it.
func test_a_key_declared_twice_in_one_block_is_reported() -> void:
	var text := '''[sub_resource type="Animation" id="Animation_run"]
tracks/0/type = "value"
tracks/0/path = NodePath("Skeleton2D/Hip:position:y")
tracks/0/type = "value"
tracks/0/path = NodePath("Skeleton2D/Hip:position:y")
'''
	var duplicates := TscnHygiene.duplicate_keys(text)
	var keys: Array[String] = []
	for entry in duplicates:
		keys.append(entry["key"])
	check(keys.has("tracks/0/type"), "the repeated key is reported")
	check(keys.has("tracks/0/path"), "so is the other repeated key")
	check_eq(duplicates.size(), 2, "exactly the two repeated keys, no more")


func test_the_same_key_in_two_different_blocks_is_not_a_duplicate() -> void:
	var text := '''[sub_resource type="Animation" id="Animation_idle"]
tracks/0/type = "value"

[sub_resource type="Animation" id="Animation_run"]
tracks/0/type = "value"
'''
	check_eq(
		TscnHygiene.duplicate_keys(text), [],
		"each block gets its own key set, so sibling blocks reusing a key is normal"
	)


## The regression case the pattern is written against: a multi-line dictionary
## literal's own entries must never be mistaken for a second top-level key.
func test_a_multiline_dictionary_literal_is_not_mistaken_for_duplicate_keys() -> void:
	var text := '''[sub_resource type="Animation" id="Animation_idle"]
tracks/0/keys = {
"times": PackedFloat32Array(0, 1.2, 2.4),
"transitions": PackedFloat32Array(1, 1, 1),
"update": 0,
"values": [600.0, 585.0, 600.0]
}
'''
	check_eq(
		TscnHygiene.duplicate_keys(text), [],
		"the dictionary's own \"key\": value lines use a colon, not a duplicate assignment"
	)
