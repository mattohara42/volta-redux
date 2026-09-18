## Finds a GDScript `var` declaration with an initializer and no type
## information at all: `var x = 5` rather than `var x: int = 5` or the
## inferred `var x := 5`.
##
## Substitutes for Godot's own `debug/gdscript/warnings/untyped_declaration`
## and `treat_warnings_as_errors` project settings, which were tried and do
## not surface through this project's actual pipeline: neither `--check-only`
## nor a real scene load under `--headless` printed a warning for either
## setting, tried against this exact Godot 4.7.2 build. A text-level check
## found what the engine's own warning system would not.
##
## Not a parser: it is a line-level pattern, in the same spirit as
## test_house_style.gd's em-dash scan. It catches the case that matters
## (`var name = value`) and does not try to be a full type-checker.
class_name UntypedDeclarations

## `var`, an identifier, then `=` directly, with nothing else between them.
## `var x: int = 5` has a colon in that gap and does not match. `var x := 5`
## has a colon immediately before the `=` and does not match either: `\s*=`
## requires only whitespace between the identifier and the `=`.
const PATTERN := "\\bvar\\s+([A-Za-z_]\\w*)\\s*="


## Returns the trimmed line text of every untyped declaration found, in order.
## A comment line is skipped outright: a doc comment showing `var x = 5` as an
## example is not a declaration.
static func find(text: String) -> PackedStringArray:
	var regex := RegEx.new()
	regex.compile(PATTERN)
	var offenders := PackedStringArray()
	for line in text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#"):
			continue
		if regex.search(trimmed) != null:
			offenders.append(trimmed)
	return offenders
