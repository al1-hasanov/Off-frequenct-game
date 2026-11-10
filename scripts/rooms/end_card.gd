extends Room
## End of the v0.2 build (the prologue and Act 1): what Mara chose, how many
## times she crossed, then back to the menu.


func setup() -> void:
	shows_hud = false
	is_story_room = false
	base_tint = Color(1, 1, 1)


func on_arrive() -> void:
	Audio.play_loop("drone", -14.0)
	GameState.meta["slices_completed"] = int(GameState.meta.get("slices_completed", 0)) + 1
	GameState.save_meta()
	GameState.delete_save()
	if GameState.test_mode:
		return  # the automated test checks this screen, then quits
	await wait(1.2)
	await hud.choose(["Back to the main menu"], 0.86)
	main.change_room("menu")


func draw_back() -> void:
	draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("040507"))
	for i in 40:
		var y := fposmod(i * 37.0 + t * 60.0, 720.0)
		draw_line(Vector2(Kit.L, y), Vector2(Kit.R, y), Color(1, 1, 1, 0.015), 2.0)
	var white := Color("e7e3d6")
	var dim := Color("9aa3a0")
	var answered: Variant = GameState.story.get("ANSWERED")
	var choice := "You answered the voice." if answered == true else "You cut the power."
	var fracture := int(GameState.story.get("FRACTURE", 0))
	Kit.text(self, Vector2(0, 140), "OFF FREQUENCY", 60, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 190), "End of Act 1  ·  v0.2", 30, Color("e8a54b"), HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 262), "Choice 1: " + choice, 28, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 302), "You crossed %d times. There's red tape on your wrist." % fracture, 26, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 340), "ANSWERED = %s   ·   FRACTURE = %d" % ["yes" if answered == true else "no", fracture],
		20, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 410), "Next, in v0.3: Act 2. Ash Street, the house with the lights off,", 24, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 442), "and the woman who sounds exactly like you.", 24, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 500), "Thanks for playing.", 24, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
