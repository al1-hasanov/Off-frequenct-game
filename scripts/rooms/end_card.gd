extends Room
## End of the build (the prologue and Acts 1 to 3): what Mara chose, how many
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
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("040507"))
	for i in 40:
		var y := fposmod(i * 37.0 + t * 60.0, 720.0)
		cv.draw_line(Vector2(Kit.L, y), Vector2(Kit.R, y), Color(1, 1, 1, 0.015), 2.0)
	var white := Color("e7e3d6")
	var dim := Color("9aa3a0")
	var g := GameState
	var act3 := g.has("act3_done")
	var answered: Variant = g.story.get("ANSWERED")
	var tomas: Variant = g.story.get("TOMAS")
	var c1 := "You answered the voice." if answered == true else "You cut the power."
	var c2 := "You took Tomas with you." if tomas == "taken" else "You left Tomas in 1980, with his sister."
	var c3: String = {"confront": "In the dark kitchen, you confronted Eighty-One.",
		"confide": "You told June what happened in the dark.",
		"conceal": "You kept what happened in the dark to yourself."}.get(g.story.get("SWITCH"), "")
	var c4: String = {"blessed": "In 1991 you let him go on with his life.",
		"asked": "In 1991 you asked him to come with you. He held your hand until the white."}.get(g.story.get("LETGO"), "")
	var c5: String = {"follow": "You pulled the 2.14 cable. Red stopped calling.",
		"expose": "You showed Eighty-One the notebook. She walked into the dark.",
		"force": "You fought her for the revolver. Dad's chain burst: no more futures."}.get(g.story.get("EIGHTY"), "")
	var fracture := int(g.story.get("FRACTURE", 0))
	var crossings := int(g.story.get("CROSSINGS", 0))
	var theories := 0
	for id in Notebook.LINKS.values():
		if g.has("theory_" + id):
			theories += 1
	Kit.text(cv, Vector2(0, 92), "OFF FREQUENCY", 56, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(cv, Vector2(0, 136), ("End of Act 3" if act3 else "End of Act 2") + "  ·  v0.6", 28, Color("e8a54b"), HORIZONTAL_ALIGNMENT_CENTER, 1280)
	var y := 192.0
	for line in ["Choice 1: " + c1, "Choice 2: " + c2, c3, c4, ("Choice 3: " + c5) if c5 != "" else ""]:
		if line == "":
			continue
		Kit.text(cv, Vector2(0, y), line, 24, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
		y += 34.0
	Kit.text(cv, Vector2(0, y + 6), "\"%s\" - what you always said to Tomas." % Story.signoff_line(), 21, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(cv, Vector2(0, y + 40), "You crossed %d times. %d of them frayed you (FRACTURE %d)." % [crossings, fracture, fracture], 21, white, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(cv, Vector2(0, y + 72), "Theories you worked out in the notebook: %d of %d." % [theories, Notebook.LINKS.size()], 19, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	if act3:
		Kit.text(cv, Vector2(0, y + 124), "Next: Act 4. Three knocks at the front door,", 22, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
		Kit.text(cv, Vector2(0, y + 152), "the transmit key in your pocket, and the white on the ridge.", 22, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Kit.text(cv, Vector2(0, 690), "Thanks for playing.", 22, dim, HORIZONTAL_ALIGNMENT_CENTER, 1280)
