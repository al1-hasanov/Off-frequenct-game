extends Room
## Act 2.1 — Halvard's main street, the hub of Act 2. Sodium lights on snow,
## townspeople outside in coats over pajamas, and five ways to go: Ash Street,
## the Lantern diner, Pike Radio, the dark alley by the sheriff's office (where
## Mara crosses to 05), and the boarded mine tunnel at the end of the street.

var snow: Snowfall
var couple_w: Actor
var couple_h: Actor
var townsman: Actor


func setup() -> void:
	place_name = "Main Street · Halvard"
	base_tint = Color(1.0, 0.9, 0.76)
	walk_min = 70.0
	walk_max = 1200.0
	make_player(560.0, 1)
	couple_w = add_actor("townswoman", 214.0, 1)
	couple_h = add_actor("husband", 272.0, -1)
	townsman = add_actor("townsman", 1000.0, -1)
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 760)
	snow.count = 140
	snow.wind = 25.0
	add_child(snow)
	add_hotspot("ash_street", Rect2(8, 380, 112, 270), "Ash Street", 70.0, -1)
	add_hotspot("diner_door", Rect2(374, 480, 62, 170), "The Lantern", 404.0, 1)
	add_hotspot("diner_window", Rect2(150, 420, 200, 120), "Diner window", 330.0, -1)
	add_hotspot("couple", Rect2(186, 470, 112, 180), "The Lunds", 330.0, -1)
	add_hotspot("upstairs", Rect2(196, 236, 90, 74), "Upstairs window", 330.0, -1)
	add_hotspot("pike_door", Rect2(634, 480, 60, 170), "Pike Radio", 664.0, 1)
	add_hotspot("pike_window", Rect2(476, 420, 150, 120), "Shop window", 560.0)
	add_hotspot("alley", Rect2(700, 400, 66, 250), "Alley", 732.0, 1)
	add_hotspot("sheriff_door", Rect2(870, 480, 58, 170), "Sheriff's office", 900.0, 1)
	add_hotspot("sheriff_window", Rect2(780, 430, 80, 100), "Sheriff's window", 820.0)
	add_hotspot("townsman", Rect2(970, 470, 60, 180), "Townsman", 940.0, 1)
	add_hotspot("tunnel", Rect2(1060, 380, 200, 270), "Mine tunnel", 1130.0, 1)
	add_hotspot("dish", Rect2(800, 120, 180, 90), "The dish", NAN)


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"from_ash":
			player.position.x = 80.0
			player.face(1)
		"from_diner":
			player.position.x = 404.0
		"from_pike":
			player.position.x = 664.0
		"from_alley":
			player.position.x = 732.0
			player.face(-1)
		"from_tunnel":
			player.position.x = 1120.0
			player.face(-1)
		_:
			player.position.x = 560.0


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	Audio.stop_loop("drone", 0.6)
	Audio.play_loop("wind", -22.0)
	Audio.play_loop("crowd", -19.0)  # the town outside: steps, doors, a shovel, a car
	if GameState.has("dish_turning"):
		Audio.play_loop("dish_motor", -26.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if entered_from == "arrive" and not GameState.has("a2_arrived"):
		GameState.set_flag("a2_arrived")
		await wait(0.5)
		await mara("Halvard. Every light in town is on, at two in the morning.")
		await mara("And everybody's outside. In their pajamas.")
		await mara("'Ash Street. I'll be in the one with the lights off.' Mom's house is up the hill.")
	elif _needs_call():
		await _june_calls()
	objective()


func _needs_call() -> bool:
	return GameState.has("choice2") and not GameState.has("dish_turning")


## After 1980: the dish starts turning by itself, and June calls on the Tuner.
func _june_calls() -> void:
	GameState.set_flag("dish_turning")
	ambience()
	await wait(0.6)
	Audio.sfx("powerup", -10.0)
	await mara("...The dish. Up on the mountain. It's turning.")
	await mara("Nobody's up there to turn it.")
	Audio.play_loop("static", -26.0, 0.3)
	await say("JUNE (RADIO)", "Mara? Mara, honey, it's June. Pick up.")
	await say("JUNE (RADIO)", "The dish is calling. The whole band's lit up. Whoever's up there, it's for you.")
	await mara("The road's eleven miles. I'd never make it in time.")
	await mara("But the old mine runs right under the mountain. Halvard Number 2. It comes out at the observatory.")
	Audio.stop_loop("static", 0.4)


func on_hotspot(id: String) -> void:
	match id:
		"ash_street":
			main.change_room("ash_street", "from_main")
		"diner_door":
			Audio.sfx("shopbell", -12.0)
			main.change_room("diner", "from_main")
		"diner_window":
			if GameState.has("swapped"):
				await mara("Ma's behind the counter. Three customers staring into their coffee.")
			else:
				await mara("Mom's behind the counter. Three customers staring into their coffee.")
		"couple":
			await say("MRS. LUND", "He's standing right here, Mara. And he's up there, at our kitchen window.")
			await say("MRS. LUND", "Which one do I make coffee for?")
		"upstairs":
			await mara("Mr. Lund, at his kitchen window, looking down at Mr. Lund.")
		"pike_door":
			Audio.sfx("shopbell", -12.0)
			main.change_room("pike_radio", "from_main")
		"pike_window":
			await mara("Every radio in June's window is on. Every one of them is talking.")
		"alley":
			await _alley()
		"sheriff_door":
			if GameState.has("crystal_taken"):
				await mara("Locked, and dark. Cal never knew I was in there. One of him didn't.")
			else:
				await mara("Locked. Dark. Cal's out on calls.")
				if GameState.has("june_diag"):
					await mara("The crystal's in there. And it's dark in there. Dark means a door.")
		"sheriff_window":
			await mara("Cal's desk, Cal's board, Cal's base radio on the shelf. All dark.")
		"townsman":
			await say("TOWNSMAN", "Power went out. Came back wrong.")
			await say("TOWNSMAN", "My kitchen's got two of everything. Two kettles. Both whistling.")
		"tunnel":
			await _tunnel()
		"dish":
			if GameState.has("dish_turning"):
				await mara("It's turning. Slow. Like it's looking for somebody.")
			else:
				await mara("Up the mountain, the dish. My night shift. It feels like a week ago.")


func use_item(id: String, item: String) -> bool:
	if item == "tuner" and id == "alley":
		await _alley()
		return true
	return false


func examine_item(item: String) -> bool:
	if item != "tuner" or not GameState.has("tuner_repaired") and not GameState.has("june_diag"):
		return await super(item)
	await mara(GameState.item_desc("tuner"))
	await mara("Not out here under the streetlights. I need somewhere properly dark. That alley?")
	return true


## The narrow gap between June's and the sheriff's office: the darkest place on the street.
func _alley() -> void:
	if not GameState.has("june_diag"):
		await mara("The alley. Pitch black between the buildings. I'm not walking in there for no reason.")
		return
	if GameState.has("crystal_taken"):
		await mara("I'm done with the alley. And with frequency 05.")
		return
	await player.walk_to(740.0)
	await mara("Dark enough. The sheriff's office is right through that wall.")
	await mara("Find the one where Cal's lights are on.")
	var st: String = await tuner_session(_alley_refusal, 3.0)
	if st == "05":
		await mara("Lights. Cal's lights.")
		main.cross("05", "sheriff_office", "from_alley")


func _alley_refusal(st: String) -> String:
	if st == "05":
		return ""
	if st == "H":
		return "That's here. Cal's office is dark here."
	if TunerUI.is_quiet(st):
		return "Nothing on that one. Not even the office."
	return "The office is still dark on that one."


func _tunnel() -> void:
	if not GameState.has("dish_turning"):
		await mara("Halvard Number 2. Boarded up since the collapse in '61. Kids dare each other to touch the boards.")
		return
	if not GameState.has("tunnel_open"):
		await mara("The boards... somebody's already pried them loose. Recently.")
		Audio.sfx("boards", -4.0)
		GameState.set_flag("tunnel_open")
		await mara("Somebody went this way tonight.")
	main.change_room("mine_tunnel", "from_main")


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	Kit.vgrad(self, Rect2(Kit.L, -100, Kit.R - Kit.L, 520), Color("03050c"), Color("18213a"))
	Kit.stars(self, Rect2(Kit.L, 0, Kit.R - Kit.L, 260), 90, t)
	# The mountain, with the observatory on top.
	draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 380), Vector2(300, 330), Vector2(620, 262), Vector2(880, 176), Vector2(1060, 230),
		Vector2(1300, 300), Vector2(Kit.R, 360), Vector2(Kit.R, 420), Vector2(Kit.L, 420)]), Color("0d1426"))
	draw_rect(Rect2(826, 166, 60, 20), Color("080c18"))
	draw_rect(Rect2(840, 178, 6, 5), Color("e8a54b"))
	var ang := sin(t * 0.25) * 0.5 if GameState.has("dish_turning") else 0.0
	_dish(Vector2(920, 184), ang)
	# Street level.
	Kit.vgrad(self, Rect2(Kit.L, 640, Kit.R - Kit.L, 140), Color("8e8e98"), Color("5a5e6e"))
	_diner_building()
	_pike_building()
	_alley_art()
	_sheriff_building()
	_tunnel_art()
	_ash_sign()
	for x in [120.0, 455.0, 1010.0]:
		_streetlight(x)
	draw_rect(Rect2(Kit.L, 646, Kit.R - Kit.L, 10), Color("d8dce6"))
	EnvironmentArt.street_details(self)


func _dish(base: Vector2, ang: float) -> void:
	var c := Color("080c18")
	draw_line(base, base + Vector2(0, -26), c, 5.0)
	draw_set_transform(base + Vector2(0, -26), ang, Vector2.ONE)
	draw_arc(Vector2.ZERO, 30.0, PI * 0.9, PI * 2.1, 16, c, 5.0)
	draw_line(Vector2.ZERO, Vector2(0, -26), c, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _diner_building() -> void:
	EnvironmentArt.brick(self, Rect2(140, 200, 310, 450), Color("4a3a36"))
	draw_rect(Rect2(140, 200, 310, 12), Color("2a201e"))
	# Upstairs: the Lunds' kitchen window (lit, on the glow layer).
	draw_rect(Rect2(196, 236, 90, 74), Color("1a1412"))
	draw_rect(Rect2(330, 236, 90, 74), Color("1a1412"))
	# Ground floor: the diner's big windows and door.
	draw_rect(Rect2(150, 420, 210, 130), Color("e8c890"))
	draw_rect(Rect2(150, 420, 210, 130), Color("2a201e"), false, 4.0)
	draw_line(Vector2(255, 420), Vector2(255, 550), Color("2a201e"), 3.0)
	for k in 3:
		draw_rect(Rect2(170 + k * 60, 500, 30, 40), Color(0.25, 0.18, 0.15, 0.7))
	draw_rect(Rect2(374, 480, 62, 170), Color("6a4a3a"))
	draw_rect(Rect2(384, 492, 42, 60), Color("e8c890"))
	draw_rect(Rect2(150, 372, 290, 36), Color("2a201e"))
	Kit.text(self, Vector2(150, 398), "THE LANTERN", 24, Color("ff9a4a"), HORIZONTAL_ALIGNMENT_CENTER, 290)


func _pike_building() -> void:
	EnvironmentArt.brick(self, Rect2(466, 300, 236, 350), Color("3a4044"), true)
	draw_rect(Rect2(466, 300, 236, 10), Color("22272a"))
	# The ham antenna on the roof.
	draw_line(Vector2(600, 300), Vector2(600, 190), Color("2a2f33"), 3.0)
	for k in 4:
		var w := 60.0 - k * 12.0
		draw_line(Vector2(600 - w * 0.5, 210 + k * 18), Vector2(600 + w * 0.5, 210 + k * 18), Color("2a2f33"), 2.0)
	draw_rect(Rect2(476, 420, 150, 120), Color("c8d0a0"))
	draw_rect(Rect2(476, 420, 150, 120), Color("22272a"), false, 4.0)
	for k in 6:
		var x := 490.0 + (k % 3) * 44.0
		var y := 440.0 + (k / 3) * 46.0
		draw_rect(Rect2(x, y, 34, 26), Color("3a3020"))
		draw_rect(Rect2(x + 4, y + 4, 18, 8), Color("e8a54b"))
	draw_rect(Rect2(634, 480, 60, 170), Color("4a5258"))
	draw_rect(Rect2(644, 492, 40, 50), Color("c8d0a0"))
	draw_rect(Rect2(476, 372, 216, 34), Color("22272a"))
	Kit.text(self, Vector2(476, 395), "PIKE RADIO & REPAIR", 16, Color("c8e0c0"), HORIZONTAL_ALIGNMENT_CENTER, 216)


func _alley_art() -> void:
	draw_rect(Rect2(702, 330, 64, 320), Color("030406"))


func _sheriff_building() -> void:
	EnvironmentArt.brick(self, Rect2(766, 320, 250, 330), Color("3e3a34"), false)
	draw_rect(Rect2(766, 320, 250, 10), Color("24211d"))
	# While the Tuner is locked on a station, the windows show that version of
	# the office: only in 05 is anyone home with the lights on.
	var win := Color("e8d8a0") if tuning == "05" else Color("0e1012")
	draw_rect(Rect2(780, 430, 80, 100), win)
	draw_rect(Rect2(780, 430, 80, 100), Color("24211d"), false, 4.0)
	draw_rect(Rect2(940, 430, 64, 100), win)
	draw_rect(Rect2(940, 430, 64, 100), Color("24211d"), false, 4.0)
	# Upper windows: these stay visible above the Tuner panel.
	for wx in [796.0, 950.0]:
		draw_rect(Rect2(wx, 334, 44, 32), win)
		draw_rect(Rect2(wx, 334, 44, 32), Color("24211d"), false, 3.0)
	if tuning != "" and TunerUI.is_quiet(tuning):
		draw_rect(Rect2(766, 320, 250, 330), Color(0.85, 0.88, 0.95, 0.85))
	draw_rect(Rect2(870, 480, 58, 170), Color("3a2e24"))
	draw_rect(Rect2(880, 492, 38, 50), Color("0e1012"))
	draw_rect(Rect2(786, 376, 220, 36), Color("24211d"))
	Kit.text(self, Vector2(786, 400), "COUNTY SHERIFF", 18, Color("c9b48a"), HORIZONTAL_ALIGNMENT_CENTER, 220)
	draw_circle(Vector2(896, 352), 14.0, Color("c9a332"))


func _tunnel_art() -> void:
	# The mountainside meets the street; the old mine mouth is cut into it.
	draw_colored_polygon(PackedVector2Array([
		Vector2(1030, 650), Vector2(1030, 360), Vector2(1140, 300), Vector2(Kit.R, 260), Vector2(Kit.R, 650)]), Color("2a2a30"))
	var m := Rect2(1080, 420, 140, 230)
	draw_rect(m, Color("050506"))
	draw_rect(Rect2(m.position.x - 12, m.position.y - 14, m.size.x + 24, 18), Color("5a4430"))
	draw_rect(Rect2(m.position.x - 12, m.position.y, 14, m.size.y), Color("5a4430"))
	draw_rect(Rect2(m.end.x - 2, m.position.y, 14, m.size.y), Color("5a4430"))
	var open := GameState.has("tunnel_open")
	for k in 5:
		var y := m.position.y + 24 + k * 42
		if open and k % 2 == 1:
			draw_colored_polygon(PackedVector2Array([Vector2(m.position.x, y), Vector2(m.position.x + 40, y + 6),
				Vector2(m.position.x + 40, y + 20), Vector2(m.position.x, y + 14)]), Color("6a5236"))
		else:
			draw_rect(Rect2(m.position.x - 4, y, m.size.x + 8, 16), Color("6a5236"))
	draw_rect(Rect2(1090, 350, 120, 30), Color("c9b48a"))
	Kit.text(self, Vector2(1090, 371), "HALVARD No.2", 15, Color("3a2a1a"), HORIZONTAL_ALIGNMENT_CENTER, 120)


func _ash_sign() -> void:
	draw_line(Vector2(60, 650), Vector2(60, 470), Color("3a3a3a"), 5.0)
	draw_rect(Rect2(14, 470, 100, 30), Color("2e5a3a"))
	Kit.text(self, Vector2(14, 491), "ASH ST ↑", 16, Color("e8e8e0"), HORIZONTAL_ALIGNMENT_CENTER, 100)


func _streetlight(x: float) -> void:
	draw_line(Vector2(x, 650), Vector2(x, 330), Color("2a2a2e"), 6.0)
	draw_line(Vector2(x, 334), Vector2(x + 34, 334), Color("2a2a2e"), 5.0)
	draw_rect(Rect2(x + 22, 334, 26, 10), Color("3a3a3e"))


func draw_glow(ci: CanvasItem) -> void:
	for x in [120.0, 455.0, 1010.0]:
		var c := Vector2(x + 35, 346)
		ci.draw_circle(c, 46.0, Color(1.0, 0.62, 0.25, 0.08))
		ci.draw_circle(c, 18.0, Color(1.0, 0.7, 0.35, 0.25))
		ci.draw_circle(c, 6.0, Color("ffd8a0"))
	# The Lunds' kitchen window: Mr. Lund looking down at the street.
	var w := Rect2(196, 236, 90, 74)
	ci.draw_rect(w, Color(1.0, 0.85, 0.55, 0.9))
	var s := Color(0.12, 0.1, 0.1, 0.9)
	ci.draw_circle(Vector2(240, 262), 11.0, s)
	ci.draw_rect(Rect2(224, 274, 32, 36), s)
	ci.draw_rect(w, Color("2a201e"), false, 4.0)
	ci.draw_line(Vector2(241, 236), Vector2(241, 310), Color("2a201e"), 3.0)
