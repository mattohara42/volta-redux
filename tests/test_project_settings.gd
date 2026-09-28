## The engine settings in `project.godot`, which nothing had ever checked.
##
## Opening the project rewrites this file, and an editor holding state older
## than the checkout writes that older state back. One such save dropped the
## whole `[physics]` and `[rendering]` sections: engine gravity would have gone
## from 0 to the default 980, and the renderer would have flipped to
## forward_plus in a project whose `config/features` says GL Compatibility.
##
## Nothing would have failed. `test_input_map.gd` guards the actions and
## `test_palette.gd` guards the clear colour, so two sections of this file were
## defended and the rest was not. This is the rest.
##
## Every value here is one the game is wrong without. Change one on purpose and
## change it here in the same commit.
extends TestCase

## Names as the editor shows them, so a dropped section reads as a missing name
## rather than as a number nobody can place.
const PHYSICS_LAYERS := {
	1: "world",
	2: "ladders",
	3: "player",
	4: "swords",
	5: "sword_ledges",
}


## ART_DIRECTION.md governs every visual choice and the art is tuned against
## this renderer. The engine default, forward_plus, is a different one.
func test_the_renderer_is_the_one_config_features_declares() -> void:
	check_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"gl_compatibility",
		"the renderer is gl_compatibility"
	)


## A 640x360 viewport scaled whole into the window is what keeps a pixel a
## pixel. The default for stretch/mode is "disabled", which scales nothing, so
## losing this line is the difference between pixel art and a small picture in
## the corner.
func test_the_viewport_scales_as_pixel_art() -> void:
	check_eq(
		ProjectSettings.get_setting("display/window/size/viewport_width"), 640,
		"the viewport is 640 wide"
	)
	check_eq(
		ProjectSettings.get_setting("display/window/size/viewport_height"), 360,
		"the viewport is 360 tall"
	)
	check_eq(
		ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items",
		"the viewport stretches as canvas_items"
	)
	check_eq(
		ProjectSettings.get_setting("display/window/stretch/aspect"), "keep",
		"the aspect ratio is kept rather than stretched"
	)
	check_eq(
		ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer",
		"the viewport scales by whole numbers only"
	)


## Pixel art at 1x is sampled nearest, never filtered (`ART.md`, Godot import
## settings). The engine default is linear, which blurs every sprite.
func test_canvas_textures_are_sampled_nearest() -> void:
	check_eq(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0,
		"canvas textures default to nearest filtering"
	)


## The engine must not pull anything downward on its own. `config/movement.tres`
## owns the hero's fall through `Motion.gravity_for` and `config/sword.tres`
## owns the sword's, which is CLAUDE.md's rule that no number deciding how the
## game feels lives outside `config/`. A default of 980 here would be a second
## opinion, applied to anything that has not hand rolled its own.
func test_the_engine_supplies_no_gravity_of_its_own() -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	check_near(gravity, 0.0, 0.0001, "engine 2D gravity is 0, because config/ owns falling")


## Every tuning number in `config/` was settled by feel at this tick rate, so
## changing it silently retunes M0. This one cannot catch the rewrite that
## prompted this file, since 60 is also the engine default, but the invariant is
## worth stating where the others are.
func test_physics_runs_at_the_rate_the_tuning_assumes() -> void:
	check_eq(
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 60,
		"physics runs at 60 ticks per second"
	)


## Five named layers, and the names are how a scene says what it collides with.
## They survive as numbers when the names go, which is why losing them is quiet.
func test_every_physics_layer_is_named() -> void:
	for layer: int in PHYSICS_LAYERS:
		check_eq(
			ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % layer),
			PHYSICS_LAYERS[layer],
			"2D physics layer %d is named" % layer
		)
