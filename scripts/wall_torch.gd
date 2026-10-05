## A torch in an iron bracket on the outer wall. Scenery: it lights the wall walk
## and changes nothing about play, which is why it is not a `Brazier`.
##
## The torch and bracket are generated art (`assets/art/act1/props/`). The flame
## is code, the way every fire in the game is (`CLAUDE.md`, atmosphere is code).
class_name WallTorch
extends Node2D

const ART: Texture2D = preload("res://assets/art/act1/props/wall_torch.png")
const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")
## Where the pitch-soaked head is in the art, from the node, which sits at the
## middle of the sprite's bottom edge. Read off the delivery, so it moves if the
## art does.
const HEAD := Vector2(7.0, -30.0)
## How the flame looks. Purely visual, like `Brazier.FLAME_HEIGHT`.
const FLAME_HEIGHT: float = 10.0
const FLAME_HALF_WIDTH: float = 4.0

var _flicker := 0.0


func _ready() -> void:
	var light := LightGlow.make(
		CONFIG.light_torch_radius, Palette.FIRE_FALLOFF,
		CONFIG.light_torch_strength, CONFIG.light_torch_flicker
	)
	light.position += HEAD + Vector2(0.0, -FLAME_HEIGHT * 0.4)
	add_child(light)
	add_child(Embers.rising(HEAD + Vector2(0.0, -FLAME_HEIGHT * 0.6), FLAME_HALF_WIDTH * 0.5, 0.5))


func _process(delta: float) -> void:
	_flicker = fmod(_flicker + delta, TAU)
	queue_redraw()


func _draw() -> void:
	draw_texture(ART, Vector2(-ART.get_width() * 0.5, -ART.get_height()))
	Flame.draw(self, HEAD, FLAME_HALF_WIDTH, FLAME_HEIGHT, _flicker)
