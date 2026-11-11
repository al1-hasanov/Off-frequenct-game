extends Room
## End of the v0.3 build (the prologue, Act 1 and Act 2): what Mara chose,
## how many times she crossed, then back to the menu.


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
	var tomas: Variant = GameState.story.get("TOMAS")
	var c1 := "You answered the voice." if answered == true else "You cut the power."
	var c2 := "You took Tomas with you." if tomas == "taken" else "You left Tomas in 1980, with his sister."
	var fracture := int(GameState.story.get("FRACTURE", 0))
	Kit.text(self, Vector2(0, 130), "OFF FREQUENCY", 60, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 180), "End of Act 2  ·  v0.3", 30, Color("e8a54b"), HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 248), "Choice 1: " + c1, 28, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 288), "Choice 2: " + c2, 28, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 328), "You crossed %d times." % fracture, 26, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 364), "ANSWERED = %s   ·   TOMAS = %s   ·   FRACTURE = %d" % [
		"yes" if answered == true else "no", str(tomas), fracture], 20, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 432), "Next, in v0.4: Act 3. The dish, three possible futures,", 24, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 464), "and a chalkboard that writes the next date by itself.", 24, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(self, Vector2(0, 520), "Thanks for playing.", 24, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
