## The pure rule behind the untyped-declaration lint. See
## test_repo_typing.gd for the real files; this proves the rule on text it
## controls, so the check can be trusted to fail when it should.
##
## Every fixture below that would itself match the pattern is built from two
## concatenated pieces rather than written as one literal, the same trick
## test_house_style.gd uses for the em-dash it scans for: this file's own
## source text must never contain the thing it is proving the scanner finds,
## or the repo-wide scan in test_repo_typing.gd would flag this file for
## containing test data rather than a real declaration.
extends TestCase


func test_a_bare_untyped_declaration_is_found() -> void:
	var line := "var speed " + "= 5"
	check_eq(
		UntypedDeclarations.find(line), PackedStringArray([line]),
		"no type hint at all is exactly what this catches"
	)


func test_an_explicit_type_hint_is_not_flagged() -> void:
	var line := "var speed: float " + "= 5.0"
	check_eq(
		UntypedDeclarations.find(line), PackedStringArray(),
		"a colon before the equals means it is typed"
	)


func test_inferred_typing_with_walrus_is_not_flagged() -> void:
	check_eq(
		UntypedDeclarations.find("var speed := 5.0"), PackedStringArray(),
		"the whole codebase leans on this form and it is not untyped, and := has no bare = to match"
	)


func test_a_declaration_with_no_initialiser_is_not_flagged() -> void:
	check_eq(
		UntypedDeclarations.find("var config: MovementConfig"), PackedStringArray(),
		"no equals sign at all, so there is nothing this pattern targets"
	)


func test_a_comment_line_is_never_flagged() -> void:
	var line := "## Usage: var speed " + "= 5"
	check_eq(
		UntypedDeclarations.find(line), PackedStringArray(),
		"a doc comment showing the pattern as an example is not a declaration"
	)


func test_finds_every_offender_across_several_lines() -> void:
	var a := "var a " + "= 1"
	var b := "var b: int " + "= 2"
	var c := "var c " + "= 3"
	var text := a + "\n" + b + "\n" + c + "\n"
	check_eq(
		UntypedDeclarations.find(text), PackedStringArray([a, c]),
		"the typed line in the middle is skipped, both untyped ones are kept"
	)
