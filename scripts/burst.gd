## A puff of particles that says something happened: wood chips off a plank a
## sword just bit, a sword's pieces, dust off a landing, a brazier catching.
## One shot, and it frees itself once the last particle is gone.
##
## Atmosphere is code (`CLAUDE.md`): no texture, every particle a square of
## whole art pixels in `Palette`'s colours. The numbers in `RECIPES` decide
## only how a burst looks, never what anything does, so they sit here beside
## the shapes rather than in `config/` with the numbers that decide feel (the
## same call `Brazier.FLAME_HEIGHT` makes).
##
## Bursts that are light (sparks, embers, glints) draw over the room's dark
## (`LightField.emissive`); bursts that are stuff (chips, dust, shards) stay
## under it and are lit like everything else.
class_name Burst
extends CPUParticles2D

enum Kind {
	CHIPS, SPARKS, SHARDS, GLINT, DUST, EMBERS, KINDLE, FLARE, CHITIN, SPARKLE,
	ARC_SPARKS, DEBRIS, SPRAY,
}

## Per kind: how many, how long they live, how fast and in what spread they
## leave, which way they fall, how big, which colours (a ramp over each
## particle's life, the last fading out), and whether they are light.
const RECIPES: Dictionary = {
	Kind.CHIPS: {"amount": 9, "life": 0.45, "speed": Vector2(40.0, 110.0), "spread": 50.0,
		"up": 0.6, "gravity": 420.0, "size": Vector2(1.0, 2.0),
		"colours": [Palette.WOOD_FACE, Palette.WOOD_DEEP], "light": false},
	Kind.SPARKS: {"amount": 10, "life": 0.3, "speed": Vector2(60.0, 160.0), "spread": 70.0,
		"up": 0.4, "gravity": 300.0, "size": Vector2(1.0, 1.0),
		"colours": [Palette.FIRE_HOT, Palette.FIRE_CORE], "light": true},
	Kind.SHARDS: {"amount": 12, "life": 0.55, "speed": Vector2(50.0, 140.0), "spread": 180.0,
		"up": 0.0, "gravity": 380.0, "size": Vector2(1.0, 2.0),
		"colours": [Palette.GOLD_FACE, Palette.GOLD_SHADE], "light": false},
	Kind.GLINT: {"amount": 7, "life": 0.25, "speed": Vector2(25.0, 55.0), "spread": 180.0,
		"up": 0.0, "gravity": 0.0, "size": Vector2(1.0, 1.0),
		"colours": [Palette.GOLD_FACE, Palette.FIRE_HOT], "light": true},
	Kind.DUST: {"amount": 7, "life": 0.4, "speed": Vector2(12.0, 40.0), "spread": 25.0,
		"up": 0.15, "gravity": -12.0, "size": Vector2(1.0, 2.0),
		"colours": [Palette.STONE_LIT, Palette.STONE_MID], "light": false, "both_ways": true},
	Kind.EMBERS: {"amount": 18, "life": 0.75, "speed": Vector2(20.0, 75.0), "spread": 60.0,
		"up": 1.0, "gravity": -30.0, "size": Vector2(1.0, 2.0),
		"colours": [Palette.FIRE_HOT, Palette.FIRE_FALLOFF], "light": true},
	Kind.KINDLE: {"amount": 14, "life": 0.5, "speed": Vector2(10.0, 30.0), "spread": 30.0,
		"up": 1.0, "gravity": -40.0, "size": Vector2(1.0, 1.0), "ring": 12.0,
		"colours": [Palette.FIRE_CORE, Palette.FIRE_HOT], "light": true},
	Kind.FLARE: {"amount": 18, "life": 0.6, "speed": Vector2(40.0, 120.0), "spread": 35.0,
		"up": 1.0, "gravity": 120.0, "size": Vector2(1.0, 2.0),
		"colours": [Palette.FIRE_HOT, Palette.FIRE_FALLOFF], "light": true},
	Kind.CHITIN: {"amount": 14, "life": 0.5, "speed": Vector2(40.0, 120.0), "spread": 180.0,
		"up": 0.5, "gravity": 400.0, "size": Vector2(1.0, 3.0),
		"colours": [Palette.ENEMY_CHITIN, Palette.LAVA_CRUST], "light": false},
	Kind.SPARKLE: {"amount": 10, "life": 0.6, "speed": Vector2(10.0, 30.0), "spread": 40.0,
		"up": 1.0, "gravity": -20.0, "size": Vector2(1.0, 1.0), "box": Vector2(10.0, 4.0),
		"colours": [Palette.GOLD_FACE, Palette.FIRE_HOT], "light": true},
	Kind.ARC_SPARKS: {"amount": 12, "life": 0.35, "speed": Vector2(50.0, 140.0), "spread": 180.0,
		"up": 0.3, "gravity": 200.0, "size": Vector2(1.0, 1.0),
		"colours": [Palette.ARC_CORE, Palette.ARC], "light": true},
	Kind.DEBRIS: {"amount": 10, "life": 0.6, "speed": Vector2(10.0, 40.0), "spread": 40.0,
		"up": -1.0, "gravity": 500.0, "size": Vector2(1.0, 2.0), "box": Vector2(16.0, 2.0),
		"colours": [Palette.STONE_MID, Palette.STONE_DEEP], "light": false},
	Kind.SPRAY: {"amount": 14, "life": 0.5, "speed": Vector2(40.0, 90.0), "spread": 50.0,
		"up": 1.0, "gravity": 260.0, "size": Vector2(1.0, 2.0), "box": Vector2(6.0, 1.0),
		"colours": [Palette.STEAM_CORE, Palette.STEAM_BODY], "light": false},
}


## A burst of `kind` at `at` (canvas coordinates), added to `parent` so it
## outlives whatever made it. `facing` tilts the bursts that leave one way: a
## chip flies back off the face the sword hit, toward where it came from.
static func emit(parent: Node, at: Vector2, kind: Kind, facing: float = 0.0) -> Burst:
	var burst := Burst.new()
	burst._shape(RECIPES[kind], facing)
	parent.add_child(burst)
	burst.global_position = at
	burst.emitting = true
	return burst


func _shape(recipe: Dictionary, facing: float) -> void:
	one_shot = true
	explosiveness = 1.0
	amount = recipe["amount"]
	lifetime = recipe["life"]
	var speed: Vector2 = recipe["speed"]
	initial_velocity_min = speed.x
	initial_velocity_max = speed.y
	spread = recipe["spread"]
	var up: float = recipe["up"]
	# Straight up at 1, straight down at -1, sideways along `facing` between.
	direction = Vector2(facing * (1.0 - absf(up)), -up).normalized() if not (is_zero_approx(facing) and is_zero_approx(up)) else Vector2.UP
	if recipe.get("both_ways", false):
		# Out to both sides along the floor, the way a landing kicks dust.
		direction = Vector2.RIGHT
		spread = 180.0 - float(recipe["spread"])
	gravity = Vector2(0.0, recipe["gravity"])
	var size: Vector2 = recipe["size"]
	scale_amount_min = size.x
	scale_amount_max = size.y
	if recipe.has("ring"):
		emission_shape = EMISSION_SHAPE_RING
		emission_ring_radius = recipe["ring"]
		emission_ring_inner_radius = float(recipe["ring"]) - 1.0
	elif recipe.has("box"):
		emission_shape = EMISSION_SHAPE_RECTANGLE
		emission_rect_extents = recipe["box"]
	var colours: Array = recipe["colours"]
	var ramp := Gradient.new()
	ramp.set_color(0, colours[0])
	ramp.set_color(1, Color(colours[colours.size() - 1], 0.0))
	if colours.size() > 1:
		ramp.add_point(0.6, colours[colours.size() - 1])
	color_ramp = ramp
	if recipe["light"]:
		LightField.emissive(self)
	finished.connect(queue_free)
