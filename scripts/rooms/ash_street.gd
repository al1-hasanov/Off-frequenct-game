extends Room
## Act 2.4 — Ash Street, up the hill. The Lind house.
##   H : Mom's at work. She left the lamp on, and the porch light, like every night.
##   14: the house is dark, empty, and for sale. Eighty-One is waiting inside.
## The broken streetlight out front is the one dark spot on the street: Mara
## tunes there, and the house behind the Tuner shows each station's version.

var snow: Snowfall


func setup() -> void:
	place_name = "Ash Street"
	base_tint = Color(0.86, 0.88, 1.0)
	walk_min = 70.0
	walk_max = 1200.0
	make_player(90.0, 1)
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 760)
	snow.count = 120
	add_child(snow)
	add_hotspot("main_street", Rect2(8, 400, 90, 250), "Main Street", 60.0, -1)
	add_hotspot("streetlight", Rect2(300, 300, 90, 350), "Broken streetlight", 350.0, 1)
	add_hotspot("house", Rect2(470, 230, 400, 420), "The Lind house", 640.0)
	add_hotspot("front_door", Rect2(626, 470, 70, 180), "Front door", 660.0, 1)
	add_hotspot("window", Rect2(500, 400, 100, 90), "Front window", 612.0, -1)
	add_hotspot("sign", Rect2(880, 520, 90, 130), "For sale sign", 860.0, 1, func() -> bool: return freq == "14")
	add_hotspot("neighbors", Rect2(960, 300, 300, 350), "The Halvorsens'", 1000.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"from_main":
			player.position.x = 90.0
			player.face(1)
		"from_house":
			player.position.x = 660.0
			player.face(-1)
		_:
			player.position.x = 350.0


## Which version of the house is on screen: the room's own, or a glimpse of
## the station the Tuner is locked on.
func _shown() -> String:
	return tuning if tuning != "" else freq


func is_dark() -> bool:
	return false


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	Audio.stop_loop("crowd", 0.6)
	Audio.stop_loop("dish_motor", 0.6)
	Audio.play_loop("wind", -16.0 if freq == "14" else -20.0)


func on_arrive() -> void:
	ambience()
	if freq == "H" and not GameState.has("ash_seen"):
		GameState.set_flag("ash_seen")
		await wait(0.4)
		await mara("Mom's house. Every light she owns, on. And the porch light. For Tomas. Every night, three years.")
		await mara("'I'll be in the one with the lights off.' Not this one.")
		await mara("That streetlight's been broken since summer. It's the only dark spot on the street.")
	elif freq == "14" and entered_from == "tuned":
		await wait(0.5)
		await mara("Dark. Empty. For sale.")
		await mara("Mom doesn't live here, in this one. Maybe nobody does.")
	elif freq == "14" and entered_from == "from_house" and GameState.has("swapped") and not GameState.has("left_14"):
		await wait(0.4)
		await mara("Ma's house, for sale. I need to get home.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"main_street":
			if freq == "14":
				await mara("Not down there. Not in this one. Back to the streetlight, and home.")
			else:
				main.change_room("main_street", "from_ash")
		"streetlight":
			await _streetlight()
		"house":
			if freq == "14":
				await mara("Dark, top to bottom. FOR SALE.")
			else:
				await mara("Mom's house. The lamp in the front window, the porch light. She never turns them off.")
		"front_door":
			await _front_door()
		"window":
			if freq == "14":
				await mara("No curtains. No furniture. Just a kitchen table, and a match burning.")
			else:
				Audio.sfx("bark", -12.0)
				if GameState.has("swapped"):
					await mara("Pepper, barking at the window. At me. He's never barked at me.")
				else:
					await mara("Pepper, barking at the window. Hi, boy.")
		"sign":
			await narrate("\"FOR SALE. Halvard Realty.\" The paint on the sign has had three winters.")
		"neighbors":
			await mara("The Halvorsens'. Every light on, and both of them on the porch in their bathrobes.")


func use_item(id: String, item: String) -> bool:
	if item == "tuner" and id == "streetlight":
		await _streetlight()
		return true
	return false


func examine_item(item: String) -> bool:
	if item != "tuner":
		return await super(item)
	await mara(GameState.item_desc("tuner"))
	await mara("Under the broken streetlight. That's the only dark spot on this street.")
	return true


func _front_door() -> void:
	if freq == "H":
		Audio.sfx("bark", -10.0)
		await mara("Locked. Pepper's going crazy in there. Mom's at the diner.")
		await mara("And this isn't the house with the lights off.")
		return
	if GameState.has("swapped"):
		await mara("No. I'm not going back in there.")
		return
	Audio.sfx("door", -10.0)
	main.change_room("ash_kitchen", "from_street")


func _streetlight() -> void:
	await player.walk_to(350.0)
	if freq == "14":
		if not GameState.has("swapped"):
			await mara("She's in there. I came all this way.")
			return
		await mara("The streetlight. Dark. Find home.")
		var st: String = await tuner_session(_home_refusal, 6.0)
		if st == "H":
			GameState.set_flag("left_14")
			main.cross("H", "ash_street", "back_home")
		return
	if GameState.has("swapped"):
		await mara("I've done Ash Street. Tomas is in 12, three years back. I need somewhere dark... and Ma's truck keys.")
		return
	await mara("Dark enough. Light off. Find the one with the lights off.")
	var band := 1 if GameState.has("tuner_repaired") else 0
	var st2: String = await tuner_session(_house_refusal, 0.0, band)
	if st2 == "14":
		await mara("Dark. Every window. And a sign in the yard.")
		main.cross("14", "ash_street", "tuned")
	elif not GameState.has("tuner_repaired"):
		GameState.set_flag("ash_tried")
		await mara("Every one of them, lit. And Tomas's dial stops at 09.")
		await mara("June Pike can fix anything with a tube in it. Her shop's on Main Street.")
		objective()


func _house_refusal(st: String) -> String:
	if st == "14":
		return ""
	if st == "H":
		return "That's home. Mom's lamp is on."
	if TunerUI.is_quiet(st):
		return "No house at all on that one. Just snow."
	return "The lights are on in that one."


func _home_refusal(st: String) -> String:
	if st == "H":
		return ""
	if st == "14":
		return "That's here."
	return "Not mine. Find the hum."


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	Kit.vgrad(self, Rect2(Kit.L, -100, Kit.R - Kit.L, 520), Color("03050c"), Color("1a2240"))
	Kit.stars(self, Rect2(Kit.L, 0, Kit.R - Kit.L, 260), 100, t)
	draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 420), Vector2(-100, 330), Vector2(300, 360), Vector2(700, 300), Vector2(1100, 340),
		Vector2(Kit.R, 300), Vector2(Kit.R, 460), Vector2(Kit.L, 460)]), Color("0d1426"))
	Kit.pines(self, 440.0, Color("070b14"))
	# Snowy yards under the night sky, then the plowed street.
	Kit.vgrad(self, Rect2(Kit.L, 438, Kit.R - Kit.L, 190), Color("3a4458"), Color("6a768c"))
	Kit.vgrad(self, Rect2(Kit.L, 620, Kit.R - Kit.L, 160), Color("b4bed0"), Color("7a869c"))
	_neighbor(Rect2(-260, 340, 220, 310))
	_neighbor(Rect2(980, 340, 260, 310))
	_house()
	_streetlight_art()
	draw_rect(Rect2(Kit.L, 646, Kit.R - Kit.L, 10), Color("d8dce6"))


func _neighbor(r: Rect2) -> void:
	draw_rect(r, Color("4a4448"))
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(-20, 0), r.position + Vector2(r.size.x * 0.5, -90),
		Vector2(r.end.x + 20, r.position.y)]), Color("2a2428"))
	for k in 2:
		draw_rect(Rect2(r.position.x + 30 + k * (r.size.x - 120), r.position.y + 60, 60, 70), Color("e8c890"))


func _house() -> void:
	var s := _shown()
	var r := Rect2(480, 330, 380, 320)
	var lit := s != "14" and not TunerUI.is_quiet(s)
	if TunerUI.is_quiet(s) and s != "H" and tuning != "":
		# The quiet ones: no house at all, just the outline in the snow.
		draw_rect(r, Color(0.8, 0.84, 0.9, 0.15), false, 2.0)
		return
	var wall := Color("6a5a4a") if s != "14" else Color("4a4440")
	draw_rect(r, wall)
	draw_colored_polygon(PackedVector2Array([Vector2(460, 330), Vector2(670, 220), Vector2(880, 330)]), Color("3a2a24"))
	# Upstairs windows: in other stations, a different pattern of lights.
	var pattern := [true, true]
	if s != "H" and s != "14" and s != "":
		var n := int(s)
		pattern = [n % 2 == 0, n % 3 != 0]
	for k in 2:
		var w := Rect2(540 + k * 200, 360, 70, 60)
		var on: bool = lit and pattern[k]
		draw_rect(w, Color("e8c890") if on else Color("15161c"))
		draw_rect(w, Color("2a2420"), false, 3.0)
	# Front window and door.
	var fw := Rect2(500, 400, 100, 90)
	draw_rect(fw, Color("f0d090") if lit else Color("101116"))
	draw_rect(fw, Color("2a2420"), false, 4.0)
	draw_rect(Rect2(630, 474, 62, 176), Color("4a3428"))
	draw_circle(Vector2(682, 566), 4.0, Color("c9a332"))
	# Porch roof and the porch light.
	draw_rect(Rect2(600, 452, 130, 12), Color("3a2a24"))
	draw_rect(Rect2(740, 470, 90, 70), Color("f0d090") if lit else Color("101116"))
	draw_rect(Rect2(740, 470, 90, 70), Color("2a2420"), false, 3.0)
	if s == "14":
		# FOR SALE, on the porch rail and on a post in the yard.
		draw_rect(Rect2(604, 430, 120, 22), Color("e8e4dc"))
		Kit.text(self, Vector2(604, 447), "FOR SALE", 15, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 120)
		draw_line(Vector2(925, 650), Vector2(925, 560), Color("4a3a2a"), 5.0)
		draw_rect(Rect2(886, 530, 80, 44), Color("e8e4dc"))
		Kit.text(self, Vector2(886, 548), "FOR", 13, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 80)
		Kit.text(self, Vector2(886, 566), "SALE", 13, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 80)
		draw_rect(Rect2(480, 600, 380, 50), Color(0.85, 0.88, 0.95, 0.5))


func _streetlight_art() -> void:
	var x := 340.0
	draw_line(Vector2(x, 650), Vector2(x, 300), Color("2a2a2e"), 6.0)
	draw_line(Vector2(x, 304), Vector2(x + 34, 304), Color("2a2a2e"), 5.0)
	draw_rect(Rect2(x + 22, 304, 26, 10), Color("1a1a1e"))
	# The dark pool on the snow where the light should be.
	draw_set_transform(Vector2(352, 650), 0.0, Vector2(1.0, 0.16))
	draw_circle(Vector2.ZERO, 110.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_glow(ci: CanvasItem) -> void:
	var s := _shown()
	if s == "14" or TunerUI.is_quiet(s):
		if freq == "14" and not GameState.has("swapped"):
			# One match burning, deep inside the dark kitchen.
			var f := 0.7 + 0.3 * sin(t * 13.0) * sin(t * 5.0)
			ci.draw_circle(Vector2(548, 452), 4.0, Color(1.0, 0.8, 0.4, 0.9 * f))
			ci.draw_circle(Vector2(548, 452), 12.0, Color(1.0, 0.7, 0.3, 0.2 * f))
		return
	# The porch light, on for Tomas.
	var c := Vector2(735, 468)
	ci.draw_circle(c, 5.0, Color("fff0c0"))
	ci.draw_circle(c, 22.0, Color(1.0, 0.85, 0.5, 0.2))
