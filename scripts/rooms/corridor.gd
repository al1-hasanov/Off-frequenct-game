extends StationRoom
## Prologue P2 — the main corridor. Mara's locker, the vending machine with
## the spare fuse, Sollen's note, and the dark east wing, where Mara first
## crosses (Act 1.4). The clock's batteries end up in the booth flashlight.
##
## The opening ends here: October 14, 1983, Mara at her locker with Tomas's
## photograph inside the door, and their song on the radio down the corridor.

## The locker stands open for the opening's last beat.
var _intro_locker := false


func setup() -> void:
	place_name = "Main corridor · Halvard Radio Observatory"
	walk_min = 80.0
	walk_max = 1130.0
	make_player(345.0, 1)
	add_hotspot("lobby_door", Rect2(22, 330, 108, 320), "Lobby", 95.0, -1)
	add_hotspot("mop", Rect2(150, 548, 72, 102), "Mop and bucket", 236.0, -1)
	add_hotspot("locker", Rect2(250, 370, 80, 272), "My locker", 292.0, 1)
	add_hotspot("receiver_door", Rect2(454, 330, 112, 320), "Receiver room", 510.0)
	add_hotspot("clock", Rect2(606, 246, 68, 68), "Wall clock")
	add_hotspot("radio", Rect2(610, 500, 88, 56), "Transistor radio", 652.0)
	add_hotspot("control_door", Rect2(760, 330, 112, 320), "Control room", 815.0)
	add_hotspot("note", Rect2(792, 418, 46, 48), "Sollen's note", 815.0)
	add_hotspot("vending", Rect2(930, 368, 114, 278), "Vending machine", 985.0)
	add_hotspot("east_wing", Rect2(1110, 300, 210, 350), "East wing", 1130.0, 1)


func enter(entry: String) -> void:
	if entry == "load" and not GameState.has("p2_intro"):
		entry = "intro"  # quit during the opening's last beat: play it again
	entered_from = entry
	match entry:
		"intro":
			player.position.x = 352.0
			player.face(-1)
			_intro_locker = true
		"start":
			player.position.x = 345.0
		"from_lobby":
			player.position.x = 112.0
			player.face(1)
		"from_receiver":
			player.position.x = 510.0
		"from_control":
			player.position.x = 815.0
		"from_east", "from_01":
			player.position.x = 1120.0
			player.face(-1)
		_:
			player.position.x = 400.0


func music_db() -> float:
	return -17.0


func static_key() -> String:
	return str(_intro_locker)


func on_arrive() -> void:
	if entered_from == "intro" and not GameState.has("p2_intro"):
		await _opening_locker()
	ambience()
	if entered_from in ["start", "intro"] and not GameState.has("p2_intro"):
		GameState.set_flag("p2_intro")
		await wait(0.5)
		await mara("Twenty to two. Floors done, coffee cold, and Sollen's left me a note. Again.")
	if entered_from == "from_01" and not GameState.has("back_home"):
		GameState.set_flag("back_home")
		await wait(0.8)
		await mara("...The doors are open. No chain.")
		await mara("And the hum's right again. That's ours. That's home.")
		await mara("Okay. Rule one: no more walking into the dark without a light.")
	if GameState.has("called_observatory"):
		objective()


func on_hotspot(id: String) -> void:
	match id:
		"lobby_door":
			Audio.sfx("door", -10.0)
			main.change_room("lobby", "from_corridor")
		"receiver_door":
			Audio.sfx("door", -10.0)
			main.change_room("receiver_room", "from_corridor")
		"control_door":
			Audio.sfx("door", -10.0)
			main.change_room("control_room", "from_corridor")
		"mop":
			await mara("Floors are done. Sollen won't notice either way.")
		"locker":
			await _locker()
		"clock":
			if GameState.has_item("flashlight_dead") and not GameState.has("batteries_taken"):
				await _take_batteries()
			elif GameState.has("batteries_taken"):
				await mara("2:14, and no batteries. It wasn't going anywhere anyway.")
			elif GameState.clock_frozen:
				await mara("2:14. The second hand isn't moving. None of them are.")
			elif GameState.clock_text == "2:13":
				await mara("2:13. The longest hour of the night shift.")
			else:
				await mara("1:40. The longest hour of the night shift.")
		"radio":
			await _radio()
		"note":
			await narrate("\"Mara — receiver 2 fuse blew again. Spares are in the cabinet. H.S.\"")
			if not GameState.has("read_note"):
				GameState.set_flag("read_note")
				await mara("Of course it did.")
				if not GameState.has("fuse_installed"):
					GameState.set_objective("Replace the fuse in receiver 2. Spares are in the Receiver Room cabinet.")
		"vending":
			await _vending()
		"east_wing":
			await _east_wing_door()


## October 14, 1983. Mara comes in to work, opens her locker, and while she
## pulls on her work coat the radio down the corridor plays their song.
func _opening_locker() -> void:
	hud.set_gameplay_visible(false)
	player.prop = "coat"
	player.prop_col = Color("5f5c3c")
	Audio.play_loop("hum", -24.0)
	Audio.play_loop("radio_music", music_db())
	Audio.set_environment(str(name), freq)
	await wait(0.8)
	await hud.caption("Mara comes in to work. Inside her locker door, a photograph of Tomas in his headphones.", 3.4)
	player.prop = "none"
	await hud.caption("She looks at it while she pulls on her work coat.", 2.6)
	Audio.stop_loop("radio_music", 1.2)
	Audio.play_loop("song_radio", -16.0, 1.4)
	await hud.caption("Down the corridor, the radio is playing. A few notes of the same music.", 3.6)
	await wait(1.2)
	await hud.caption("Mara stops.", 1.6)
	Audio.play_loop("song_radio", -60.0, 2.4)
	Audio.play_loop("radio_music", music_db(), 2.4)
	await wait(1.0)
	Audio.sfx("door", -12.0, 1.3)
	_intro_locker = false
	await hud.caption("Then she closes the locker.", 1.6)
	Audio.stop_loop("song_radio", 0.2)
	await hud.fade_out(0.8)
	await hud.card("OFF FREQUENCY", "", 3.2, true)
	hud.set_gameplay_visible(true)
	await hud.fade_in(0.8)


func _locker() -> void:
	if GameState.has("locker_opened"):
		await mara("Tomas. He'd be sixteen now.")
		return
	GameState.set_flag("locker_opened")
	Audio.sfx("click", -6.0)
	await mara("Tomas. Thirteen forever, taped inside a locker door.")
	await mara("The missing-person flyer. Three years, and I still can't throw it out.")
	await mara("And my red tape. It held his posters up all that winter. Never leave home without it.")
	GameState.add_item("red_tape")
	hud.toast("Got: Red tape")


func use_item(id: String, item: String) -> bool:
	if item == "flashlight_dead" and id == "clock":
		await _take_batteries()
		return true
	if item == "flashlight_dead" and id == "radio":
		await mara("It takes a nine-volt. Wrong size.")
		return true
	if item == "flashlight" and id == "east_wing":
		await _east_wing_door()
		return true
	return false


func _take_batteries() -> void:
	if GameState.has("batteries_taken"):
		await mara("I already took them.")
		return
	Audio.sfx("click", -8.0)
	await mara("Two D cells in the back of the clock.")
	await mara("It's 2:14 forever anyway. You won't be needing these.")
	GameState.set_flag("batteries_taken")
	GameState.add_item("batteries")
	hud.toast("Got: Clock batteries")
	objective()


func _east_wing_door() -> void:
	var g := GameState
	if g.has("dish_parked") and not g.has("dish_released") and not g.has("crossed_parked"):
		await _experiment_crossings()
		return
	if not GameState.has("called_observatory"):
		await mara("Still out. That's facilities ticket number four.")
		return
	if not GameState.has("crossed_once"):
		# Act 1.4: the first crossing.
		await mara("Pitch black. Ticket number four.")
		await mara("Sollen's office is twenty steps in. Hand on the wall. I've done it a thousand times.")
		await player.walk_to(1250.0)
		GameState.set_flag("crossed_once")
		main.cross("01", "east_corridor", "first")
		return
	if not GameState.has_item("flashlight"):
		await mara("Not without a light. Not again.")
		return
	Audio.sfx("click", -8.0)
	main.change_room("east_corridor", "from_corridor")


## Act 3.5, Day 17 again: with the dish parked, two crossings through the dark
## east wing and back. Required travel: it never frays her.
func _experiment_crossings() -> void:
	await mara("Day 17. Light off. Into the dark wing and back. Twice.")
	await player.walk_to(1250.0)
	for i in 2:
		Audio.sfx("crossing", -4.0)
		hud.glitch(0.9)
		GameState.cross_to("01", true)
		await wait(1.1)
		Audio.sfx("crossing", -4.0)
		hud.glitch(0.9)
		GameState.cross_to("H", true)
		await wait(0.9)
	GameState.set_flag("crossed_parked")
	await player.walk_to(1130.0)
	await mara("Twice through and back, and home's hum both times. Now the chart.")
	objective()


func _radio() -> void:
	if GameState.has_item("flashlight_dead"):
		await mara("Dead. And it takes a nine-volt anyway. Wrong size.")
		return
	if GameState.clock_frozen:
		await mara("Dead. Not even static.")
	elif GameState.has("radio_on"):
		GameState.set_flag("radio_on", false)
		Audio.sfx("click", -6.0)
		ambience()
		await mara("KHLV, all night long. Not tonight.")
	else:
		GameState.set_flag("radio_on")
		Audio.sfx("click", -6.0)
		ambience()
		await mara("A little company.")


func _vending() -> void:
	if GameState.has("fuse_taken"):
		await mara("Dark. Sorry, pal.")
	elif not GameState.has("cabinet_empty"):
		await mara("Nobody's bought anything from this thing since August. It just glows, day and night, on its own little fuse.")
		GameState.set_flag("vending_seen")
	else:
		await mara("Wait. The display light runs on a 5-amp glass fuse. Same as the receiver.")
		Audio.sfx("click", -4.0)
		GameState.set_flag("fuse_taken")
		GameState.add_item("fuse")
		hud.toast("Got: 5-amp fuse")
		await mara("Sorry, pal.")
		if not GameState.has("fuse_installed"):
			GameState.set_objective("Put the fuse in receiver 2.")


func _machine_lit() -> bool:
	return not GameState.has("fuse_taken") and not GameState.emergency


func draw_back() -> void:
	draw_shell([240.0, 640.0, 1040.0])
	Kit.door(cv, Rect2(30, 340, 92, 310), DOOR, "LOBBY")
	# Mop and bucket.
	cv.draw_rect(Rect2(160, 600, 54, 48), Color("c9a332"))
	cv.draw_rect(Rect2(156, 596, 62, 8), Color("a88722"))
	cv.draw_line(Vector2(196, 600), Vector2(214, 470), Color("8a6a45"), 5.0)
	cv.draw_rect(Rect2(204, 470, 20, 6), Color("5a4a3a"))
	_lockers()
	Kit.door(cv, Rect2(462, 340, 96, 310), DOOR, "RECEIVER ROOM")
	_radio_table()
	Kit.door(cv, Rect2(768, 340, 96, 310), DOOR, "CONTROL")
	cv.draw_rect(Rect2(798, 424, 34, 38), Color("e6dfc8"))
	for i in 4:
		cv.draw_line(Vector2(803, 433 + i * 7), Vector2(826, 433 + i * 7), Color("6a6a70"), 1.5)
	_vending_machine()
	_east_wing()


func _lockers() -> void:
	for i in 2:
		var x := 252.0 + i * 82.0
		var r := Rect2(x, 372, 76, 270)
		cv.draw_rect(r, Color("475764"))
		cv.draw_rect(r, Color("2f3a43"), false, 2.0)
		for k in 5:
			cv.draw_line(Vector2(x + 18, 392 + k * 7), Vector2(x + 58, 392 + k * 7), Color("2f3a43"), 2.0)
		cv.draw_rect(Rect2(x + 60, 500, 6, 22), Color("9aa3a8"))
	if GameState.has("locker_opened") or _intro_locker:
		var x := 252.0
		cv.draw_rect(Rect2(x + 4, 376, 68, 262), Color("141a1f"))
		# His photograph: the red parka, the headphones on.
		cv.draw_rect(Rect2(x + 12, 410, 34, 44), Color("dcd6c4"))
		cv.draw_rect(Rect2(x + 15, 413, 28, 30), Color("6f7f92"))
		cv.draw_circle(Vector2(x + 29, 425), 5.0, Color("d9aa8c"))
		cv.draw_rect(Rect2(x + 23, 430, 12, 12), Color("b4352b"))
		cv.draw_arc(Vector2(x + 29, 424), 6.5, PI, TAU, 8, Color("26292e"), 1.6)
		cv.draw_circle(Vector2(x + 23, 426), 2.2, Color("2c3036"))
		cv.draw_circle(Vector2(x + 35, 426), 2.2, Color("2c3036"))
		cv.draw_rect(Rect2(x + 20, 470, 40, 54), Color("efeadb"))
		Kit.text(cv, Vector2(x + 20, 486), "MISSING", 9, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 40)
		cv.draw_colored_polygon(PackedVector2Array([Vector2(x - 26, 360), Vector2(x, 372), Vector2(x, 642), Vector2(x - 26, 656)]), Color("3d4b57"))


## The wall clock: its second hand sweeps, so it's drawn every frame.
func draw_anim(ci: CanvasItem) -> void:
	super(ci)
	_clock(ci)


func _clock(ci: CanvasItem) -> void:
	var c := Vector2(640, 280)
	ci.draw_circle(c, 30.0, Color("1c2225"))
	ci.draw_circle(c, 26.0, Color("e9e6da"))
	var parts := GameState.clock_text.split(":")
	var hours := float(parts[0]) if parts.size() > 1 else 2.0
	var minutes := float(parts[1]) if parts.size() > 1 else 14.0
	var sec := 7.0 if GameState.clock_frozen else fmod(t, 60.0)
	var hand := func(frac: float, length: float, width: float, col: Color) -> void:
		var a := frac * TAU - PI / 2.0
		ci.draw_line(c, c + Vector2(cos(a), sin(a)) * length, col, width)
	hand.call((hours + minutes / 60.0) / 12.0, 14.0, 4.0, Color("1c1c1c"))
	hand.call(minutes / 60.0, 20.0, 3.0, Color("1c1c1c"))
	hand.call(sec / 60.0, 22.0, 1.5, Color("b8322c"))


func _radio_table() -> void:
	cv.draw_rect(Rect2(600, 556, 108, 10), Color("4a3a2c"))
	cv.draw_rect(Rect2(608, 566, 8, 84), Color("3a2e24"))
	cv.draw_rect(Rect2(692, 566, 8, 84), Color("3a2e24"))
	cv.draw_rect(Rect2(614, 506, 80, 50), Color("7a2b26"))
	cv.draw_rect(Rect2(620, 514, 40, 34), Color("3a1614"))
	for k in 5:
		cv.draw_line(Vector2(624, 518 + k * 6), Vector2(656, 518 + k * 6), Color("5a2420"), 2.0)
	var on := GameState.has("radio_on") and not GameState.clock_frozen
	cv.draw_circle(Vector2(677, 531), 9.0, Color("e8a54b") if on else Color("3a3027"))
	cv.draw_line(Vector2(690, 506), Vector2(722, 456), Color("9aa0a6"), 2.0)


func _vending_machine() -> void:
	var r := Rect2(934, 372, 106, 274)
	cv.draw_rect(r, Color("4c2c33"))
	cv.draw_rect(r, Color("2a171b"), false, 3.0)
	var panel := Rect2(946, 388, 70, 170)
	if _machine_lit():
		cv.draw_rect(panel, Color("c9d8c8"))
		var snack := [Color("c0392b"), Color("e1a63b"), Color("3a7bbf"), Color("6aa84f")]
		for row in 5:
			for col in 3:
				cv.draw_rect(Rect2(952 + col * 21, 396 + row * 32, 16, 22), snack[(row + col) % 4])
		cv.draw_colored_polygon(PackedVector2Array([Vector2(934, 646), Vector2(1040, 646), Vector2(1110, 700), Vector2(880, 700)]),
			Color(0.8, 0.95, 0.85, 0.06))
	else:
		cv.draw_rect(panel, Color("141a1c"))
	cv.draw_rect(Rect2(1022, 400, 12, 60), Color("2a2f33"))
	cv.draw_rect(Rect2(950, 580, 62, 36), Color("1a1012"))


func _east_wing() -> void:
	cv.draw_rect(Rect2(1112, 322, 200, 330), Color("15191b"))
	cv.draw_rect(Rect2(1120, 330, 200, 320), Color("020304"))
	Kit.plate(cv, Vector2(1215, 296), "EAST WING")
	cv.draw_rect(Rect2(1150, 380, 56, 40), Color("e6dfc8"))
	Kit.text(cv, Vector2(1150, 397), "OUT OF", 10, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, 56)
	Kit.text(cv, Vector2(1150, 410), "ORDER", 10, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, 56)
