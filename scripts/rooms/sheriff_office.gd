extends Room
## Act 2.3 — the sheriff's office in frequency 05, where it is already
## October 17. Cal is asleep at his desk beside his board for the murder of
## Mara Lind. The crystal is in his base radio, which is switched on: Mara has
## to pull its plug from behind a steel filing cabinet without waking him.

var cal: Actor


func setup() -> void:
	place_name = "County Sheriff · October 17, 1983"
	base_tint = Color(0.92, 0.9, 0.82)
	walk_min = 110.0
	walk_max = 1170.0
	make_player(120.0, 1)
	cal = add_actor("cal_asleep", 600.0, 1)
	add_layer(1, _draw_desk)
	add_hotspot("side_door", Rect2(26, 330, 100, 320), "Side door", 110.0, -1)
	add_hotspot("board", Rect2(160, 240, 270, 200), "Evidence board", 300.0)
	add_hotspot("calendar", Rect2(450, 270, 70, 80), "Calendar", 480.0)
	add_hotspot("cal", Rect2(560, 470, 110, 90), "Cal", 500.0, 1)
	add_hotspot("lamp", Rect2(700, 470, 50, 80), "Desk lamp", 500.0, 1)
	add_hotspot("radio", Rect2(860, 450, 120, 80), "Base radio", 920.0)
	add_hotspot("cabinet", Rect2(996, 380, 80, 270), "Filing cabinet", 960.0, 1)
	add_hotspot("plug", Rect2(1010, 556, 54, 54), "Plug", 990.0, 1, func() -> bool:
		return GameState.has("cabinet_moved") and not GameState.has("unplugged"))
	add_hotspot("doormat", Rect2(1110, 630, 120, 30), "Doormat", 1150.0, 1, func() -> bool:
		return not GameState.has("doormat_taken"))
	add_hotspot("front_door", Rect2(1150, 330, 110, 300), "Front door", 1150.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 120.0
	player.face(1)


func ambience() -> void:
	Audio.stop_all(0.4)
	Audio.play_loop("snore", -20.0)
	if not GameState.has("unplugged"):
		Audio.play_loop("scanner", -18.0)


func on_arrive() -> void:
	ambience()
	if not GameState.has("in_05"):
		GameState.set_flag("in_05")
		await wait(0.6)
		await mara("Lights on. Heat on. And Cal, asleep at his desk.")
		await mara("Don't wake him. Whatever this version of him knows, I don't want to hear it.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"side_door":
			await _leave()
		"board":
			await _board()
		"calendar":
			await mara("October 17th. Three days after. In this one, time kept going.")
		"cal":
			await mara("Cal. Twenty-five years of being my friend, asleep in his uniform.")
			if GameState.has("read_board"):
				await mara("In this one, he buried me on Tuesday.")
		"lamp":
			await mara("If that goes off, he'll wake up. Cal always wakes up when it gets dark.")
		"radio":
			await _radio()
		"cabinet":
			await _cabinet()
		"plug":
			await _unplug()
		"doormat":
			GameState.set_flag("doormat_taken")
			GameState.add_item("doormat")
			hud.toast("Got: Doormat")
			await mara("WELCOME, mostly. Rubber underneath. Nice and soft.")
			objective()
		"front_door":
			await mara("Not out there. It's three days later out there. Somebody's me is dead.")


func use_item(id: String, item: String) -> bool:
	if item == "doormat" and id == "cabinet":
		await _slide_cabinet()
		return true
	if item == "doormat":
		await mara("It's a doormat. It goes under things.")
		return true
	return false


func _board() -> void:
	await hud.read_doc("CASE BOARD — LIND, MARA (DECEASED)", [
		"A photo: a body under a sheet against the transmitter console. Halvard Observatory control room.\n\nCause of death: gunshot. Time of death: approx. 02:14, Oct 14.",
		"A witness sketch. A woman's face: Mara's face, older.\n\n\"Female, 35 to 45, bandaged left hand. Seen on Ash St. 03:00. Strongly resembles victim.\"",
		"Cal's handwriting, on an index card:\n\n\"Twin? No record. Sister? None.\"\n\nThe word SISTER is circled three times.",
	])
	if not GameState.has("read_board"):
		GameState.set_flag("read_board")
		await mara("Someone killed me. In this one, someone killed me, and she had my face.")
		await mara("A bandaged left hand.")


func _radio() -> void:
	if GameState.has("crystal_taken"):
		await mara("Gutted. Cal's going to have a confusing Monday.")
	elif not GameState.has("unplugged"):
		GameState.set_flag("radio_seen")
		await mara("Cal's base radio. It's on. If I open the panel live, it'll squeal and wake him.")
		await mara("The cord runs down behind that filing cabinet. To the wall socket.")
		objective()
	else:
		Audio.sfx("squeak", -10.0)
		await mara("Four screws. My screwdriver. Quiet, quiet...")
		Audio.sfx("click", -12.0)
		GameState.set_flag("crystal_taken")
		GameState.add_item("crystal")
		hud.toast("Got: Quartz crystal")
		await mara("The crystal. Same can, same stamp as Tomas's.")
		objective()


func _cabinet() -> void:
	if GameState.has("cabinet_moved"):
		await mara("It moved without a sound. Bless that doormat.")
		return
	if GameState.has_item("doormat"):
		await _slide_cabinet()
		return
	Audio.sfx("scrape", -2.0)
	await wait(0.2)
	await say("CAL", "Mmh... Lorraine?")
	await narrate("Mara freezes. Cal settles. The snoring starts again.")
	GameState.set_flag("cabinet_tried")
	await mara("Too loud. Steel feet on a bare floor. It needs something soft underneath.")
	objective()


func _slide_cabinet() -> void:
	if GameState.has("cabinet_moved"):
		await mara("It's already out of the way.")
		return
	await mara("Tip it, doormat under the feet...")
	GameState.remove_item("doormat")
	Audio.sfx("hush", -6.0)
	await wait(0.6)
	GameState.set_flag("cabinet_moved")
	await mara("...and slide. Not a sound.")
	await mara("There's the plug.")
	objective()


func _unplug() -> void:
	Audio.sfx("plug", -6.0)
	GameState.set_flag("unplugged")
	Audio.stop_loop("scanner", 0.1)
	await wait(0.6)
	await narrate("The radio dies mid-crackle. Cal snores on.")
	objective()


func _leave() -> void:
	if not GameState.has("crystal_taken"):
		await mara("Not without the crystal.")
		return
	await mara("The alley. Dark. Light off, and find home.")
	var st: String = await tuner_session(_home_only, 6.0)
	if st == "H":
		await mara("That hum. Home.")
		main.cross("H", "main_street", "from_alley")


func _home_only(st: String) -> String:
	if st == "H":
		return ""
	if st == "05":
		return "That's here. I need home."
	return "Not mine. Find the hum."


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(self, floor_y, Color("6a6248"), Color("524c3a"), Color("2a2620"))
	Kit.floor_tiles(self, floor_y, Color("4a4a42"), Color("3a3a34"))
	Kit.ceiling_light(self, 420.0, floor_y, true)
	Kit.ceiling_light(self, 900.0, floor_y, true)
	Kit.door(self, Rect2(30, 340, 92, 310), Color("4a4038"), "SIDE")
	_board_art()
	_calendar()
	_radio_art()
	_cabinet_art()
	_front_door()


func _board_art() -> void:
	var r := Rect2(160, 240, 270, 200)
	draw_rect(r.grow(6), Color("5a4430"))
	draw_rect(r, Color("b89a6a"))
	draw_rect(Rect2(178, 256, 80, 60), Color("e8e4dc"))
	draw_rect(Rect2(184, 262, 68, 40), Color("2a2c30"))
	draw_rect(Rect2(196, 286, 46, 10), Color("c8c8c8"))
	draw_rect(Rect2(290, 252, 70, 86), Color("f0ece0"))
	draw_circle(Vector2(325, 284), 14.0, Color("8a8a8a"), false, 2.0)
	draw_line(Vector2(310, 300), Vector2(340, 300), Color("8a8a8a"), 2.0)
	draw_rect(Rect2(372, 262, 46, 34), Color("f0ece0"))
	draw_rect(Rect2(196, 350, 90, 60), Color("f0ece0"))
	draw_ellipse_outline(Vector2(240, 380), 36, 14)
	draw_line(Vector2(218, 286), Vector2(325, 300), Color("b8322c"), 2.0)
	draw_line(Vector2(325, 300), Vector2(240, 380), Color("b8322c"), 2.0)
	draw_line(Vector2(395, 280), Vector2(325, 300), Color("b8322c"), 2.0)
	for p in [Vector2(218, 258), Vector2(325, 254), Vector2(395, 264), Vector2(240, 352)]:
		draw_circle(p, 4.0, Color("b8322c"))


func draw_ellipse_outline(c: Vector2, rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, Color("b8322c"), 2.0)


func _calendar() -> void:
	draw_rect(Rect2(450, 270, 70, 80), Color("f0ece0"))
	draw_rect(Rect2(450, 270, 70, 18), Color("8a1d1d"))
	Kit.text(self, Vector2(450, 284), "OCT 1983", 11, Color("f0ece0"), HORIZONTAL_ALIGNMENT_CENTER, 70)
	for i in 17:
		var x := 456.0 + (i % 7) * 9.0
		var y := 296.0 + (i / 7) * 12.0
		draw_line(Vector2(x, y), Vector2(x + 6, y + 8), Color("3a3a3a"), 1.5)


func _radio_art() -> void:
	draw_rect(Rect2(850, 530, 140, 120), Color("4a3a2a"))
	draw_rect(Rect2(860, 452, 120, 78), Color("3a3c40"))
	var on := not GameState.has("unplugged")
	draw_rect(Rect2(872, 464, 60, 22), Color(1.0, 0.7, 0.3) if on else Color("2a2a2a"))
	draw_circle(Vector2(956, 476), 12.0, Color("1a1a1a"))
	for k in 5:
		draw_line(Vector2(872, 496 + k * 6), Vector2(940, 496 + k * 6), Color("1a1a1a"), 2.0)
	if GameState.has("crystal_taken"):
		draw_rect(Rect2(950, 498, 26, 26), Color("15161a"))
	# The power cord, down behind the cabinet.
	draw_line(Vector2(980, 520), Vector2(1000, 540), Color("1a1a1a"), 3.0)
	draw_line(Vector2(1000, 540), Vector2(1030, 584), Color("1a1a1a"), 3.0)


func _cabinet_art() -> void:
	var x := 1000.0 if not GameState.has("cabinet_moved") else 1074.0
	# Wall socket, hidden behind the cabinet until it moves.
	draw_rect(Rect2(1022, 568, 30, 34), Color("e8e4dc"))
	if not GameState.has("unplugged"):
		draw_rect(Rect2(1028, 578, 18, 14), Color("1a1a1a"))
	else:
		draw_rect(Rect2(1000, 626, 18, 12), Color("1a1a1a"))
	draw_rect(Rect2(x, 384, 76, 266), Color("7a8288"))
	for k in 4:
		draw_rect(Rect2(x + 6, 394 + k * 64, 64, 56), Color("6a7278"))
		draw_rect(Rect2(x + 28, 416 + k * 64, 20, 6), Color("c8ccd0"))
	if GameState.has("cabinet_moved"):
		draw_rect(Rect2(x - 6, 644, 90, 8), Color("5a4430"))


func _front_door() -> void:
	Kit.door(self, Rect2(1160, 340, 92, 300), Color("3a2e24"), "FRONT")
	if not GameState.has("doormat_taken"):
		draw_rect(Rect2(1112, 638, 116, 16), Color("5a4430"))
		Kit.text(self, Vector2(1112, 651), "WELCOME", 11, Color("c9b48a"), HORIZONTAL_ALIGNMENT_CENTER, 116)


func _draw_desk(ci: CanvasItem) -> void:
	# In front of Cal: the desk top, his lamp, a coffee mug.
	ci.draw_rect(Rect2(520, 548, 300, 14), Color("6a4a30"))
	ci.draw_rect(Rect2(530, 562, 280, 88), Color("54392a"))
	ci.draw_rect(Rect2(700, 536, 36, 12), Color("2a2f33"))
	ci.draw_line(Vector2(718, 536), Vector2(718, 498), Color("2a2f33"), 4.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(698, 502), Vector2(742, 502), Vector2(732, 474), Vector2(708, 474)]), Color("2e5a3a"))
	ci.draw_rect(Rect2(712, 502, 16, 6), Color("fff0c0"))
	ci.draw_rect(Rect2(770, 526, 18, 22), Color("e8e4dc"))
	ci.draw_rect(Rect2(560, 540, 70, 8), Color("e8e4dc"))
