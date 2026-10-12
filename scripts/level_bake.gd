## A level's still parts, drawn once into textures and shown as sprites (N2):
## the back wall, the stone and its edges, the dark of its interiors and the
## decoration. Nothing in them moves, so drawing them every frame was work for
## nothing, and a level five screens wide was thousands of tiles a frame.
##
## Each chunk of the level is a `SubViewport` that renders once and keeps its
## picture. Each layer is drawn into every chunk by a callable taking the
## canvas to draw on, in level coordinates; a chunk just looks at its own part.
## Headless, nothing renders and nothing needs to: the solids are the room's,
## not these.
class_name LevelBake
extends Node2D

## A chunk's side, art px. Small enough that a tall level never asks for a
## texture bigger than a GPU will take, big enough to be a handful of sprites.
const CHUNK := 1024

var _layers: Array[Dictionary] = []


## A layer, drawn after the ones before it. `draw` takes the `CanvasItem` to
## draw on. `filter` is how its textures are read: nearest for art, linear for
## a texture that is a field rather than a picture.
func add_layer(draw: Callable, material: Material = null, filter := CanvasItem.TEXTURE_FILTER_NEAREST) -> void:
	_layers.append({"draw": draw, "material": material, "filter": filter})


## Cuts a level `size` px into chunks and renders each one once.
func build(size: Vector2) -> void:
	var across := ceili(size.x / CHUNK)
	var down := ceili(size.y / CHUNK)
	for cy in down:
		for cx in across:
			var origin := Vector2(cx, cy) * CHUNK
			var extent := Vector2i(mini(CHUNK, ceili(size.x - origin.x)), mini(CHUNK, ceili(size.y - origin.y)))
			_add_chunk(origin, extent)


## How many chunks this level is shown in.
func chunk_count() -> int:
	return get_children().filter(func(n: Node) -> bool: return n is Sprite2D).size()


func _add_chunk(origin: Vector2, extent: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = extent
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var root := Node2D.new()
	root.position = -origin
	viewport.add_child(root)
	for layer in _layers:
		var canvas := Node2D.new()
		canvas.texture_filter = layer["filter"]
		canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		canvas.material = layer["material"]
		var draw: Callable = layer["draw"]
		canvas.draw.connect(func() -> void: draw.call(canvas))
		root.add_child(canvas)
	add_child(viewport)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.position = origin
	sprite.texture = viewport.get_texture()
	add_child(sprite)
