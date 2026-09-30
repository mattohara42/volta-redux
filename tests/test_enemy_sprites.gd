## Every enemy's sprite scene, checked the way the hero's is (`test_hero_sprite.gd`),
## plus the two facts about a sprite that only a measurement settles: its feet
## land on the bottom edge of the killing box, and it is centred on it. A
## regenerated sheet that shifts a creature a pixel used to be invisible to the
## suite, and `ART.md` says "draw the thing you measured".
extends TestCase

const SPRITES := {
	"bat": "res://scenes/bat_sprite.tscn",
	"scorpion": "res://scenes/scorpion_sprite.tscn",
	"ant": "res://scenes/ant_sprite.tscn",
	"eyeball": "res://scenes/eyeball_sprite.tscn",
	"dragon": "res://scenes/dragon_sprite.tscn",
	"generator": "res://scenes/generator_sprite.tscn",
}
const ENEMIES := "res://config/enemies.tres"


func _sprite(name: String) -> Node:
	return (load(SPRITES[name]) as PackedScene).instantiate()


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func test_every_enemy_animation_shows_real_frames_of_its_own_name() -> void:
	for name in SPRITES:
		var sprite := _sprite(name)
		var player := sprite.get_node("AnimationPlayer") as AnimationPlayer
		var machine := (sprite.get_node("AnimationTree") as AnimationTree).tree_root as AnimationNodeStateMachine
		var frames := (sprite.get_node("AnimatedSprite2D") as AnimatedSprite2D).sprite_frames
		var animations := player.get_animation_list()
		check(animations.size() > 0, "%s has an animation" % name)
		for anim_name in animations:
			check(machine.has_node(anim_name), "%s: %s has a state-machine node" % [name, anim_name])
			check(frames.has_animation(anim_name), "%s: %s has frames" % [name, anim_name])
			if not frames.has_animation(anim_name):
				continue
			var anim := player.get_animation(anim_name)
			for i in anim.get_track_count():
				var path := str(anim.track_get_path(i))
				if path == "AnimatedSprite2D:animation":
					check_eq(str(anim.track_get_key_value(i, 0)), str(anim_name), "%s: %s shows its own frames" % [name, anim_name])
				elif path == "AnimatedSprite2D:frame":
					for k in anim.track_get_key_count(i):
						var index := int(anim.track_get_key_value(i, k))
						check(
							index >= 0 and index < frames.get_frame_count(anim_name)
							and frames.get_frame_texture(anim_name, index) != null,
							"%s: %s frame %d exists and has a texture" % [name, anim_name, index]
						)
		sprite.free()


## The last row with a solid pixel, counted from the top of the frame.
func _feet_row(texture: Texture2D) -> int:
	var image := texture.get_image()
	for y in range(image.get_height() - 1, -1, -1):
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.5:
				return y + 1
	return 0


## A creature stands on the bottom edge of its killing box and is centred on
## the box's middle, so what the player sees standing is what can touch them.
func test_ground_enemies_stand_on_their_killing_box_and_are_centred_on_it() -> void:
	var half_heights := {
		"scorpion": RoomM4Enemies.SCORPION_SIZE.y * 0.5,
		"ant": RoomM4Enemies.ANT_SIZE.y * 0.5,
		"dragon": RoomM4Dragon.DRAGON_SIZE.y * 0.5,
	}
	for name in half_heights:
		var sprite := _sprite(name)
		var animated := sprite.get_node("AnimatedSprite2D") as AnimatedSprite2D
		var texture := animated.sprite_frames.get_frame_texture(animated.animation, 0)
		var feet := float(_feet_row(texture)) + animated.offset.y
		check_near(feet, half_heights[name], 1.0, "%s's feet are on its killing box's bottom edge" % name)
		check_near(
			animated.offset.x, -texture.get_width() * 0.5, 0.01,
			"%s is centred on its killing box" % name
		)
		sprite.free()
