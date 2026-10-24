## The game's lettering (`Lettering`): one pixel font, never smoothed, and
## only ever set at sizes on its own grid, where its pixels stay square.
extends TestCase


func test_the_font_loads_unsmoothed() -> void:
	var font := Lettering.font()
	check(font != null, "%s loads" % Lettering.PATH)
	check_eq(font.antialiasing, TextServer.FONT_ANTIALIASING_NONE, "with no smoothing")
	check_eq(font.subpixel_positioning, TextServer.SUBPIXEL_POSITIONING_DISABLED, "and whole-pixel placing")


func test_the_licence_travels_with_it() -> void:
	check(FileAccess.file_exists("res://assets/fonts/OFL.txt"), "the font's licence is beside it")


func test_every_size_a_player_reads_is_on_the_grid() -> void:
	for size in [Lettering.SMALL, Lettering.BODY, Lettering.TITLE, PauseMenu.TITLE_SIZE, PauseMenu.ITEM_SIZE]:
		check(Lettering.on_grid(size), "%d px is on the font's %d px grid" % [size, Lettering.GRID])
	var death: DeathConfig = load("res://config/death.tres")
	check(Lettering.on_grid(death.message_font_size), "the death message, %d px" % death.message_font_size)
	for path in ["res://config/act1.tres", "res://config/act2.tres", "res://config/act3.tres", "res://config/act4.tres"]:
		var act: ActConfig = load(path)
		check(Lettering.on_grid(act.card_font_size), "%s's card, %d px" % [path, act.card_font_size])
		# The opening card sets the game's name at twice the act's size.
		check(Lettering.on_grid(act.card_font_size * 2), "and the game's name over it")
