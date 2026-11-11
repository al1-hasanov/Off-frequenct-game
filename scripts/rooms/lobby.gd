extends StationRoom
## Act 1 (part of 1.1, 1.3 and 1.4) — the lobby. The front doors, the
## footprints that stop mid-floor if Mara cut the power, the phone puzzle with
## three calls into three different frequencies, and the security booth's
## flashlight.

var snow_out: Snowfall
var snow_in: Snowfall


func setup() -> void:
	place_name = "Lobby"
	walk_min = 360.0
	walk_max = 1150.0
	snow_out = Snowfall.new()
	snow_out.area = Rect2(82, 282, 236, 366)
	snow_out.count = 70
	snow_out.wind = 30.0
	add_child(snow_out)
	if _door_open():
		snow_in = Snowfall.new()
		snow_in.area = Rect2(300, 360, 260, 290)
		snow_in.count = 28
		snow_in.wind = 70.0
		snow_in.speed = 70.0
		add_child(snow_in)
	make_player(1140.0, -1)

	add_hotspot("front_door", Rect2(70, 268, 262, 384), "Front doors", 370.0, -1)
	add_hotspot("footprints", Rect2(330, 640, 360, 40), "Footprints", 520.0, -1, func() -> bool: return _door_open())
	add_hotspot("board", Rect2(396, 284, 170, 132), "Bulletin board", 480.0)
	add_hotspot("bench", Rect2(392, 556, 200, 64), "Bench", 600.0, -1)
	add_hotspot("junction", Rect2(700, 372, 88, 116), "Junction box", 744.0)
	add_hotspot("booth", Rect2(850, 258, 300, 140), "Security booth", 1000.0)
	add_hotspot("phone", Rect2(962, 396, 96, 76), "Phone", 1000.0)
	add_hotspot("booth_door", Rect2(1064, 478, 78, 172), "Booth door", 1040.0, 1)
	add_hotspot("corridor_door", Rect2(1168, 330, 110, 320), "Corridor", 1150.0, 1)


func _door_open() -> bool:
	return GameState.has("choice1") and GameState.story.get("ANSWERED") == false


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 1140.0 if entry == "from_corridor" else 900.0
	player.face(-1)


func on_arrive() -> void:
	ambience()
	Audio.play_loop("wind", -30.0 if not _door_open() else -14.0)
	if _door_open() and not GameState.has("saw_open_door"):
		GameState.set_flag("saw_open_door")
		await wait(0.3)
		await mara("The front door's open.")
	if GameState.has("called_observatory"):
		objective()


func on_hotspot(id: String) -> void:
	match id:
		"corridor_door":
			Audio.stop_loop("wind", 0.4)
			Audio.sfx("door", -10.0)
			main.change_room("corridor", "from_lobby")
		"front_door":
			if not GameState.has("choice1"):
				await mara("Snowing harder. Nobody's coming up that road tonight.")
			elif _door_open():
				await mara("Wide open. The lock's fine. Somebody opened it.")
				await mara("I'm not going out there. Not a chance.")
			else:
				await mara("Closed. Locked. Whoever was knocking is gone.")
				await mara("Or wants me to think so.")
		"footprints":
			GameState.set_flag("saw_footprints")
			await mara("Wet footprints. They come in from the snow...")
			await mara("...and stop. Right there. Like whoever made them just stopped existing.")
		"board":
			await mara("Visitors welcome, nine to five. Nobody's visited since summer.")
		"bench":
			await mara("Sollen naps here when he thinks I'm not looking.")
		"booth":
			if GameState.has("booth_open"):
				await mara("Logbooks from 1979 and a dead fern. I took the only useful thing in there.")
			else:
				await mara("The security booth. We haven't had a guard since the budget cuts. Just me.")
		"booth_door":
			await _booth_door()
		"junction":
			await _junction()
		"phone":
			await _phone()


func use_item(id: String, item: String) -> bool:
	if id == "junction" and item == "red_tape":
		if not GameState.has("phone_dead"):
			await mara("Nothing in there needs fixing. Yet.")
		elif GameState.has("phone_fixed"):
			await mara("It's already taped.")
		else:
			GameState.set_flag("junction_open")
			Audio.sfx("click", -6.0)
			await mara("Strip, twist, wrap. Wrap again.")
			GameState.set_flag("phone_fixed")
			await mara("Red tape. Not pretty, but it'll hold.")
			GameState.set_objective("Try the phone again.")
		return true
	if id == "phone" and item == "note":
		await mara("Who would I even read it to?")
		return true
	if id == "booth_door" and item == "keys":
		await _booth_door()
		return true
	return false


func _booth_door() -> void:
	if GameState.has("booth_open"):
		await mara("Nothing else in there worth taking.")
		return
	if not GameState.has_item("keys"):
		await mara("Locked. Sollen keeps the booth key on his ring, and his ring stays in his coat.")
		return
	Audio.sfx("keys", -8.0)
	await wait(0.5)
	Audio.sfx("lock", -8.0)
	GameState.set_flag("booth_open")
	await mara("Third key on the ring. There.")
	await mara("The booth flashlight. Heavy, steel, older than me.")
	Audio.sfx("click", -8.0)
	await wait(0.3)
	Audio.sfx("click", -8.0)
	await mara("And dead. The batteries have turned to green crust.")
	GameState.add_item("flashlight_dead")
	hud.toast("Got: Flashlight (dead)")
	objective()


func _junction() -> void:
	if not GameState.has("phone_dead"):
		await mara("Junction box. Phone lines for the whole building.")
	elif GameState.has("phone_fixed"):
		await mara("Red tape. Not pretty, but it holds.")
	else:
		GameState.set_flag("junction_open")
		Audio.sfx("click", -6.0)
		await mara("One pair's been cut. Clean, like somebody used snips.")
		await mara("I could splice it if I had something to hold it together.")
		GameState.set_objective("Splice the cut wire: tap your red tape, then the junction box.")


func _phone() -> void:
	if not GameState.has("body_done"):
		await mara("The security phone. Nobody to call at this hour.")
		return
	if GameState.has("called_observatory"):
		await mara("I'm not calling anyone else tonight.")
		return
	if not GameState.has("phone_fixed"):
		Audio.sfx("click", -6.0)
		await narrate("No dial tone. Nothing.")
		if not GameState.has("phone_dead"):
			GameState.set_flag("phone_dead")
			await mara("Dead. The line's dead.")
			GameState.set_objective("The phone's dead. Check the junction box on the lobby wall.")
		return
	var options: Array[String] = []
	var calls: Array[String] = []
	if not GameState.has("called_sheriff"):
		options.append("Call the sheriff's office")
		calls.append("sheriff")
	if not GameState.has("called_home"):
		options.append("Call home")
		calls.append("home")
	if GameState.has("called_sheriff") and GameState.has("called_home"):
		options.append("Call the observatory's own number")
		calls.append("observatory")
	options.append("Hang up")
	calls.append("")
	Audio.sfx("click", -6.0)
	await narrate("A dial tone. Finally.")
	var pick: int = await hud.choose(options)
	match calls[pick]:
		"sheriff":
			await _call_sheriff()
		"home":
			await _call_home()
		"observatory":
			await _call_observatory()


func _ring_out() -> void:
	Audio.sfx("dial", -6.0)
	await wait(1.7)
	Audio.sfx("ringback", -10.0)
	await wait(2.3)
	Audio.sfx("click", -8.0)


func _call_sheriff() -> void:
	await _ring_out()
	await say("CAL", "Ostrander.")
	await mara("Cal, it's Mara. I'm up at the observatory. There's a—")
	await narrate("Silence on the line.")
	await say("CAL", "Whoever this is, that's not funny.")
	await say("CAL", "I buried her Tuesday.")
	Audio.sfx("hangup", -6.0)
	await mara("...Cal?")
	GameState.set_flag("called_sheriff")
	_after_call()


func _call_home() -> void:
	await _ring_out()
	await say("RUTH", "Hello?")
	await mara("Mom? It's me.")
	await say("RUTH", "...Who is this?")
	await say("RUTH", "My daughter died in 1980. Please don't call here again.")
	Audio.sfx("hangup", -6.0)
	await mara("Mom...")
	GameState.set_flag("called_home")
	_after_call()


func _after_call() -> void:
	if GameState.has("called_sheriff") and GameState.has("called_home"):
		GameState.set_objective("There's one number left to try: the observatory's own.")
	else:
		GameState.set_objective("Try another number.")


func _call_observatory() -> void:
	await mara("The observatory's own line. Just to prove I'm not losing my mind.")
	Audio.sfx("dial", -6.0)
	await wait(1.7)
	Audio.sfx("ring", -15.0)
	await wait(1.6)
	Audio.sfx("ring", -15.0)
	await wait(1.6)
	Audio.sfx("click", -12.0)
	Audio.sfx("breath", -6.0)
	await wait(2.4)
	await say("VOICE", "Don't.")
	Audio.sfx("hangup", -6.0)
	await wait(0.8)
	await mara("That phone was ringing inside the building.")
	await mara("In Sollen's office. And Sollen's office is locked.")
	await mara("Somebody's in there. Somebody picked up.")
	GameState.set_flag("called_observatory")
	objective()


func draw_back() -> void:
	Kit.wall(self, floor_y, Color("3a3f3a"), Color("2d322e"), TRIM)
	Kit.floor_tiles(self, floor_y, Color("26292a"), Color("2e3233"))
	for x in [520.0, 1000.0]:
		Kit.ceiling_light(self, x, floor_y, not GameState.emergency)
	if GameState.emergency:
		Kit.emergency_lamp(self, Vector2(1222, 262), t)
	_front_doors()
	_board()
	_bench()
	_junction_box()
	_booth()
	Kit.door(self, Rect2(1176, 340, 92, 310), DOOR, "LABS")
	if _door_open():
		for i in 12:
			var x := 340.0 + i * 30.0
			var y := 662.0 + (5.0 if i % 2 == 0 else -1.0)
			draw_set_transform(Vector2(x, y), 0.0, Vector2(1.0, 0.42))
			draw_circle(Vector2.ZERO, 8.0, Color(0.55, 0.62, 0.72, 0.55))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _front_doors() -> void:
	var r := Rect2(82, 282, 236, 366)
	Kit.night_view(self, r, t, -1.0, 1.0)
	draw_rect(r.grow(12), Color("15191b"), false, 24.0)
	if _door_open():
		draw_rect(Rect2(82, 282, 116, 366), Color("8fa0b4", 0.12))
		draw_line(Vector2(200, 282), Vector2(200, 648), Color("15191b"), 8.0)
		draw_colored_polygon(PackedVector2Array([Vector2(318, 282), Vector2(360, 300), Vector2(360, 640), Vector2(318, 648)]), Color("1d2427"))
		draw_colored_polygon(PackedVector2Array([Vector2(318, 648), Vector2(330, 652), Vector2(470, 672), Vector2(318, 680)]), Color("cdd6e4"))
	else:
		draw_rect(Rect2(82, 282, 236, 366), Color("8fa0b4", 0.1))
		draw_line(Vector2(200, 282), Vector2(200, 648), Color("15191b"), 8.0)
		draw_rect(Rect2(180, 450, 6, 50), Color("9aa3a8"))
		draw_rect(Rect2(214, 450, 6, 50), Color("9aa3a8"))
	Kit.plate(self, Vector2(200, 244), "HALVARD RADIO OBSERVATORY", 14)


func _board() -> void:
	var r := Rect2(400, 288, 162, 124)
	draw_rect(r.grow(5), Color("4a3a2c"))
	draw_rect(r, Color("8a6a45"))
	var papers := [Rect2(410, 298, 46, 56), Rect2(466, 304, 40, 40), Rect2(514, 296, 38, 62), Rect2(430, 362, 60, 40)]
	for p in papers:
		draw_rect(p, Color("e6dfc8"))
	Kit.text(self, Vector2(430, 384), "VISITORS", 10, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, 60)
	Kit.text(self, Vector2(430, 396), "9 – 5", 10, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, 60)


func _bench() -> void:
	draw_rect(Rect2(396, 570, 192, 14), Color("5a4532"))
	draw_rect(Rect2(406, 584, 10, 66), Color("2a2f33"))
	draw_rect(Rect2(568, 584, 10, 66), Color("2a2f33"))


func _junction_box() -> void:
	draw_rect(Rect2(736, 26, 14, 350), Color("4a545b"))
	var r := Rect2(704, 376, 80, 108)
	draw_rect(r, Color("6a747b"))
	draw_rect(r, Color("2c353c"), false, 2.0)
	if GameState.has("junction_open"):
		draw_rect(r.grow(-6), Color("1a1f22"))
		draw_line(Vector2(720, 384), Vector2(720, 476), Color("3a7bbf"), 3.0)
		draw_line(Vector2(732, 384), Vector2(732, 476), Color("e8e0c0"), 3.0)
		if GameState.has("phone_fixed"):
			draw_line(Vector2(752, 384), Vector2(752, 476), Color("6aa84f"), 3.0)
			draw_line(Vector2(766, 384), Vector2(766, 476), Color("c9a332"), 3.0)
			draw_rect(Rect2(744, 424, 30, 16), Color("b8322c"))
		else:
			draw_line(Vector2(752, 384), Vector2(752, 422), Color("6aa84f"), 3.0)
			draw_line(Vector2(752, 440), Vector2(752, 476), Color("6aa84f"), 3.0)
			draw_line(Vector2(766, 384), Vector2(766, 424), Color("c9a332"), 3.0)
			draw_line(Vector2(766, 442), Vector2(766, 476), Color("c9a332"), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(704, 376), Vector2(680, 366), Vector2(680, 494), Vector2(704, 484)]), Color("5d676e"))
	else:
		draw_circle(Vector2(774, 430), 4.0, Color("2c353c"))
		Kit.text(self, Vector2(704, 404), "PHONE", 11, Color("2c353c"), HORIZONTAL_ALIGNMENT_CENTER, 80)


func _booth() -> void:
	var r := Rect2(852, 262, 296, 388)
	draw_rect(r, Color("2f3534"))
	draw_rect(r, Color("161b1c"), false, 4.0)
	var win := Rect2(868, 286, 264, 150)
	draw_rect(win, Color("0f171b"))
	draw_rect(Rect2(880, 400, 240, 34), Color("3a3027"))
	draw_rect(Rect2(982, 404, 56, 26), Color("2a2a2e"))
	draw_rect(Rect2(988, 398, 44, 10), Color("1b1b1f"))
	draw_circle(Vector2(1010, 418), 8.0, Color("c8c3b0"))
	draw_rect(win, Color(0.6, 0.75, 0.85, 0.08))
	draw_rect(win, Color("161b1c"), false, 6.0)
	draw_rect(Rect2(852, 450, 296, 26), Color("4a3a2c"))
	Kit.plate(self, Vector2(1000, 236), "SECURITY")
	var d := Rect2(1070, 484, 66, 166)
	if GameState.has("booth_open"):
		draw_rect(d, Color("0e1214"))
		draw_colored_polygon(PackedVector2Array([d.position, Vector2(d.position.x - 30, d.position.y + 10),
			Vector2(d.position.x - 30, d.end.y - 4), Vector2(d.position.x, d.end.y)]), Color("3a4142"))
	else:
		draw_rect(d, Color("3a4142"))
		draw_rect(d, Color("161b1c"), false, 3.0)
		draw_circle(Vector2(d.position.x + 12, d.position.y + 86), 4.0, Color("9aa3a8"))
