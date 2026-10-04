## A gem drawn riding on whatever it is a child of, for an enemy that carries
## one (`Act4Guard`). Only a picture: the enemy's `defeated` signal is what
## leaves the real `Gem` behind.
class_name CarriedGem
extends Node2D


func _draw() -> void:
	Gem.draw_gem(self, Vector2.ZERO, Gem.SIZE)
