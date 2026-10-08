## The sword counter: the one piece of HUD the game has, and Act 4's gems
## under it. `SPEC.md` makes the
## count the difficulty dial, and a dial you cannot see is not one.
##
## A small upright sword per sword you own, top right, drawn pixel by pixel in
## the sword's own gold so it reads as the thing it counts. A sword in hand is
## solid; one that is out (flying, embedded, on the floor) is a dim silhouette,
## because it can still come back and the player needs to know that without
## looking for it. Top right rather than top left so the debug overlay never
## sits on it.
##
## Reads the player it belongs to and the "swords" group each frame, and only
## redraws when the tally changes. Sizes are design pixels, not tuning.
class_name SwordCounter
extends Node2D

const MARGIN := Vector2(8.0, 8.0)
const ICON_SIZE := Vector2(5.0, 13.0)
const SPACING: float = 7.0
const GEM_SIZE := Vector2(6.0, 8.0)
const GEM_SPACING: float = 9.0

var _player: Player
var _icons: Array[bool] = []
var _gems := 0


func _ready() -> void:
	_player = _find_player()


func _find_player() -> Player:
	var node := get_parent()
	while node != null:
		if node is Player:
			return node
		node = node.get_parent()
	return null


func _process(_delta: float) -> void:
	if _player == null:
		return
	var out := 0
	for node in get_tree().get_nodes_in_group("swords"):
		var sword := node as Sword
		# One lying where the level put it is not yours until you find it.
		if sword != null and not sword.placed and sword.state != SwordFlight.State.CAUGHT and sword.state != SwordFlight.State.DESTROYED:
			out += 1
	var icons := SwordTally.icons(_player.swords_held, out, _player.sword_config.max_swords)
	if icons != _icons or _player.gems_held != _gems:
		_icons = icons
		_gems = _player.gems_held
		queue_redraw()


func _draw() -> void:
	var width := get_viewport_rect().size.x
	var count := _icons.size()
	var left := width - MARGIN.x - ICON_SIZE.x - SPACING * float(maxi(count - 1, 0))
	for i in count:
		_draw_icon(Vector2(left + SPACING * float(i), MARGIN.y), _icons[i])
	# Act 4's gems, a row below the swords, only once there are any.
	for i in _gems:
		var centre := Vector2(width - MARGIN.x - 3.0 - GEM_SPACING * float(i), MARGIN.y + ICON_SIZE.y + 9.0)
		Gem.draw_gem(self, centre, GEM_SIZE)


## Point up: a 1 px tip, a 2 px blade, a crossguard wider on one side (the
## asymmetric hilt the sword already has), a grip and a pommel. Everything sits
## on a 1 px coloured-dark border so it reads over lava glow as well as stone.
func _draw_icon(at: Vector2, in_hand: bool) -> void:
	var parts: Array[Rect2] = [
		Rect2(2, 0, 1, 1),  # tip
		Rect2(1, 1, 2, 7),  # blade
		Rect2(0, 8, 5, 1),  # crossguard, longer to the left
		Rect2(1, 9, 2, 3),  # grip
		Rect2(1, 12, 2, 1),  # pommel
	]
	for part in parts:
		draw_rect(Rect2(at + part.position - Vector2.ONE, part.size + Vector2(2, 2)), Palette.STONE_DEEP)
	for i in parts.size():
		var part := parts[i]
		var rect := Rect2(at + part.position, part.size)
		if in_hand:
			draw_rect(rect, Palette.GOLD_FACE if i <= 1 else Palette.GOLD_SHADE)
		else:
			draw_rect(rect, Palette.STONE_LIT)
