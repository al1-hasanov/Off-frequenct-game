extends Room
## Title screen: the observatory at night, the title flickering like a bad signal.

var snow: Snowfall


func setup() -> void:
	shows_hud = false
	is_story_room = false
	base_tint = Color(1, 1, 1)
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 780)
	snow.count = 170
	add_child(snow)


func on_arrive() -> void:
	Audio.stop_all(0.4)
	Audio.play_loop("drone", -12.0)
	Audio.play_loop("wind", -20.0)
	while true:
		var action: String = await hud.main_menu(GameState.has_save())
		if action == "chapters":
			var pick: Dictionary = await hud.chapter_select()
			if pick.is_empty():
				continue  # Back: show the main menu again
			main.start_chapter(pick.id, pick.answered, pick.took)
		elif action == "continue":
			main.continue_game()
		elif action == "quit":
			get_tree().quit()
		else:
			main.start_new_game()
		return


func draw_back() -> void:
	Kit.vgrad(self, Rect2(Kit.L, -100, Kit.R - Kit.L, 640), Color("02040a"), Color("172038"))
	Kit.stars(self, Rect2(Kit.L, 0, Kit.R - Kit.L, 360), 120, t)
	draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 540), Vector2(-120, 400), Vector2(150, 470), Vector2(420, 380), Vector2(700, 470),
		Vector2(980, 390), Vector2(1260, 460), Vector2(1500, 380), Vector2(Kit.R, 470), Vector2(Kit.R, 540)]), Color("0d1326"))
	Kit.pines(self, 548.0, Color("070b13"))
	Kit.vgrad(self, Rect2(Kit.L, 545, Kit.R - Kit.L, 220), Color("8b98b0"), Color("4c5873"))
	var b := Color("080b14")
	draw_rect(Rect2(470, 470, 340, 80), b)
	draw_rect(Rect2(520, 430, 140, 40), b)
	draw_rect(Rect2(545, 500, 26, 16), Color("e8a54b"))
	Kit.dish(self, Vector2(760, 470), 1.55, b)


func draw_fore(ci: CanvasItem) -> void:
	var glitch := sin(t * 23.0) > 0.96 or fmod(t, 7.0) < 0.12
	var off := Vector2(randf_range(-6.0, 6.0), 0.0) if glitch else Vector2.ZERO
	if glitch:
		Kit.text(ci, Vector2(0, 228) + off * 1.6, "OFF FREQUENCY", 104, Color(0.62, 0.83, 0.9, 0.45), HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(ci, Vector2(0, 228) + off, "OFF FREQUENCY", 104, Color("e7e3d6"), HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(ci, Vector2(0, 276), "v0.3.1 · the prologue, Act 1 and Act 2", 24, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, 1280)
