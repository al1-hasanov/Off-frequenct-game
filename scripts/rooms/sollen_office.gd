extends StationRoom
## Act 1.4 — Henrik Sollen's office.
##   01: his lamp on, Sollen asleep on the couch, his coat (keys) and scarf on
##       the stand, and a photo of Mara as employee of the year.
##   H : dark and empty. The phone's receiver off the hook and still warm, the
##       1980 station log, Tomas's tape, and the garage key in the drawer.

var moon: PointLight2D


func setup() -> void:
	place_name = "Sollen's office"
	walk_min = 110.0
	walk_max = 1120.0
	make_player(130.0, 1)
	if freq == "01":
		var s := add_actor("sollen_asleep", 312.0, 1)
		s.position.y = 598.0
	else:
		moon = add_lamp(Vector2(680, 330), 2.2, Color(0.55, 0.65, 0.9), 0.35)
	add_hotspot("door", Rect2(30, 330, 110, 320), "Door", 110.0, -1)
	add_hotspot("couch", Rect2(168, 500, 266, 150), "Couch", 300.0)
	if freq == "01":
		add_hotspot("sollen", Rect2(186, 522, 244, 64), "Sollen", 300.0)
		add_hotspot("coat", Rect2(428, 410, 56, 170), "Sollen's coat", 470.0, 1)
		add_hotspot("scarf", Rect2(484, 392, 42, 116), "Scarf", 470.0, 1, func() -> bool: return not GameState.has("scarf_taken"))
	else:
		add_hotspot("coat", Rect2(440, 390, 70, 260), "Coat stand", 470.0, 1)
	add_hotspot("photo", Rect2(262, 320, 78, 90), "Photo", 300.0)
	add_hotspot("window", Rect2(570, 210, 220, 220), "Window", 680.0)
	add_hotspot("desk", Rect2(814, 520, 304, 130), "Desk", 960.0)
	add_hotspot("lamp", Rect2(824, 432, 60, 90), "Desk lamp", 880.0)
	add_hotspot("phone", Rect2(888, 484, 62, 40), "Phone", 915.0)
	add_hotspot("logbook", Rect2(954, 490, 66, 34), "Station log", 985.0)
	if freq == "H":
		add_hotspot("cassette", Rect2(1028, 480, 70, 44), "Cassette player", 1060.0)
		add_hotspot("drawer", Rect2(950, 540, 124, 46), "Drawer", 1010.0)
	add_hotspot("shelf", Rect2(1134, 294, 124, 356), "Bookshelf", 1120.0, 1)
	add_hotspot("book", Rect2(1212, 444, 38, 64), "Black textbook", 1120.0, 1)
	if freq == "H":
		add_hotspot("desk_leg", Rect2(826, 594, 48, 56), "Desk leg", 880.0, -1, func() -> bool:
			return GameState.has("knows_key") and not GameState.has("key_taken"))


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 130.0
	player.face(1)


func _lamp_on() -> bool:
	return freq == "01" or GameState.has("office_lamp")


func is_dark() -> bool:
	return not _lamp_on()


func _process(delta: float) -> void:
	super(delta)
	if moon != null:
		moon.visible = is_dark()


func ambience() -> void:
	super()
	if freq == "01":
		Audio.play_loop("snore", -14.0)
	else:
		Audio.stop_loop("snore", 0.4)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if freq == "01" and not GameState.has("office_01_seen"):
		GameState.set_flag("office_01_seen")
		await wait(0.4)
		await mara("Sollen's office. His lamp's on, and he's...")
		await mara("Asleep. On his couch. At two in the morning.")
	elif freq == "H" and not GameState.has("office_h_seen"):
		GameState.set_flag("office_h_seen")
		await wait(0.4)
		await mara("Nobody.")
		await mara("Nobody, and it's cold in here. Like nobody's been in here for hours.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"door":
			Audio.sfx("door", -12.0)
			main.change_room("east_corridor", "from_office")
		"couch":
			if freq == "01":
				await _sollen()
			else:
				if GameState.has("couch_seen"):
					await mara("Empty. The cushion's cold.")
				else:
					GameState.set_flag("couch_seen")
					await narrate("His couch. The blanket is folded. His coat is not on its hook.")
					await mara("He sleeps here on run nights. He hasn't, tonight.")
		"sollen":
			await _sollen()
		"coat":
			await _coat()
		"scarf":
			await _scarf()
		"photo":
			await _photo()
		"window":
			if freq == "01":
				await mara("Same snow. Same dish. Everything's the same except everything.")
			else:
				await mara("Snow, and the dish. Same as always.")
		"desk":
			await mara("Sollen's desk. Tidier than mine.")
		"lamp":
			await _lamp()
		"phone":
			await _phone()
		"logbook":
			await _logbook()
		"cassette":
			await _cassette()
		"drawer":
			await _drawer()
		"shelf", "book":
			if GameState.has("act3"):
				await _dads_book()
			else:
				await mara("Radio astronomy, birdwatching, and nine copies of the station's budget report.")
				await mara("And a big black textbook that isn't his. GRAVITATION. I'd swear that was Dad's.")
		"desk_leg":
			await _desk_leg()


func _sollen() -> void:
	if not GameState.has("sollen_looked"):
		GameState.set_flag("sollen_looked")
		await mara("Henrik Sollen, asleep in his cardigan. He looks... rested.")
		await mara("Mine hasn't slept through a night since 1980.")
	else:
		await mara("Don't wake him. I wouldn't know what to say.")


func _coat() -> void:
	if freq == "H":
		await mara("No coat. He goes home at midnight, like always.")
		if GameState.has("phone_found"):
			await mara("So who was standing at his desk?")
		return
	if GameState.has_item("keys"):
		await mara("I've got his keys. I'll bring them back. Probably.")
		return
	await mara("His coat. Keys are always in the left pocket...")
	Audio.sfx("keys", -6.0)
	await narrate("The keys jingle. On the couch, Sollen stirs.")
	await say("SOLLEN", "Mm... Mara? ...Did the fuse... hold?")
	await mara("...It held. Go back to sleep, Henrik.")
	await narrate("He does.")
	GameState.add_item("keys")
	hud.toast("Got: Sollen's keys")
	await mara("Office, booth, basement, snowcat. Every lock on the mountain.")
	objective()


func _scarf() -> void:
	if not GameState.has("lamp_burned"):
		await mara("His scarf. Thick wool. He's had it since before I started.")
		await mara("I don't need a scarf. I need to get home.")
		return
	GameState.set_flag("scarf_taken")
	GameState.add_item("scarf")
	hud.toast("Got: Sollen's scarf")
	await mara("Thick wool. That'll do for a hot bulb. Sorry, Henrik.")
	objective()


func _photo() -> void:
	if freq == "01":
		GameState.set_flag("seen_01_photo")
		await narrate("A framed photo: \"Employee of the year, 1982.\"")
		await mara("That's me. Smiling.")
		await mara("I've never been employee of anything.")
	else:
		await narrate("A framed photo: \"Henrik and Greta, Lake Halvard, 1961.\"")
		if GameState.has("seen_01_photo"):
			await mara("In the other office, this frame had me in it.")


func _lamp() -> void:
	if freq == "01":
		await mara("If I switch that off, he'll wake up. He can't sleep in the dark. Never could.")
		await mara("I'll just shut his door on it when I go.")
	elif GameState.has("office_lamp"):
		await mara("Leave it on.")
	elif GameState.emergency:
		Audio.sfx("click", -10.0)
		await mara("Nothing. No power on this side of the building.")
		await mara("I did that. I pulled the breaker.")
	else:
		Audio.sfx("click", -8.0)
		GameState.set_flag("office_lamp")
		await mara("There.")


func _phone() -> void:
	if freq == "01":
		await mara("On the hook. Nobody called him tonight. Nobody in this one, anyway.")
		return
	if GameState.has("phone_found"):
		await mara("Off the hook. I'm leaving it exactly like that.")
		return
	GameState.set_flag("phone_found")
	await mara("The receiver's off the hook.")
	await mara("...It's still warm.")
	await mara("I called this phone twenty minutes ago. Somebody stood right here and picked it up.")
	await mara("Somebody said 'Don't.'")


func _logbook() -> void:
	if freq == "01":
		await narrate("\"Oct 14. Quiet night. Fuse holding. — M.\"")
		await mara("My initial. Not my night.")
		return
	if GameState.has("act3") and GameState.has("read_logbook") and not GameState.has("chain_known"):
		await _chain_sheet()
		return
	await hud.read_doc("HALVARD RADIO OBSERVATORY — STATION LOG", [
		"Oct 14, 1980. Night shift: H. Sollen.\n\n02:14  Carrier on 2.14 MHz. Unscheduled. Female voice, words: \"Don't let her in.\"\n\nNo bearing. Source appears to be INSIDE Rx-2.\n\n[In the margin, in pencil: LAMBDA RUN.]",
		"02:31  M. Lind at the door. Her brother (Tomas, 13) gone from the clearing at the outer gate. Phoned the sheriff. Search parties out.\n\n03:40  Dep. Ostrander on site. Asked about our \"beacon.\" Told him we don't have one.",
		"04:50  Air Force liaison, Maj. D. Price. Log sealed by order. All tapes from tonight surrendered.\n\n05:10  All but one.\n\n— H.S.",
	])
	if not GameState.has("read_logbook"):
		GameState.set_flag("read_logbook")
		await mara("October fourteenth, 1980. The night Tomas went missing.")
		await mara("Same voice. Same words. Same 2:14.")
		await mara("'All but one.' Sollen kept a tape.")
	if GameState.has("act3") and not GameState.has("chain_known"):
		await _chain_sheet()


## Act 3.1: a folded sheet in the back of the log. The patch-bay routing for
## receiver 2, "the 2.14 chain", and it isn't in Sollen's hand.
func _chain_sheet() -> void:
	await narrate("Folded into the back of the log, a sheet of graph paper.")
	await hud.read_doc("THE 2.14 CHAIN", [
		"Rx-2 patch routing, for the field set.\n\nDISH LO-FEED  to  jack A1\nRx-2 IF OUT  to  jack B3\nFIELD SET OUT  to  jack C2\n\nDo NOT route through the forward bank.\n\nIn the margin: \"Enable link: 5 A fast. It is meant to open. Park the drive BEFORE you replace it.\"\n\n— Λ.L.  10/79",
	])
	GameState.set_flag("chain_known")
	GameState.set_flag("meant_to_open")
	GameState.add_item("chain_sheet")
	hud.toast("Got: Dad's diagram")
	await mara("Λ.L. That's Dad's writing. October '79. A month before the road.")
	await mara("He was the Air Force's engineer on the dish. I knew that. I didn't know he'd drawn anything Tomas would need.")
	await mara("...\"It is meant to open.\" The fuse. Three years I've been putting it back.")
	objective()


## Act 3: Dad's old textbook on Sollen's shelf, and his LAMBDA notes folded
## inside it: Einstein's constant, the bridge between sheets of space, Everett's
## branches and Gödel's loop, in his hand.
func _dads_book() -> void:
	var g := GameState
	await narrate("On Sollen's shelf, between the bird books, a black textbook as thick as a phone book: GRAVITATION, by Misner, Thorne and Wheeler.")
	await narrate("Inside the cover: PROPERTY OF Λ. LIND, USAF. Folded in the back, three sheets of graph paper.")
	await hud.read_doc("LAMBDA  ·  WORKING NOTES  ·  Λ.L.", [
		"Einstein, 1917, with his constant, setting c = 1:\n\n      Gμν + Λgμν = 8πG Tμν\n\nOn the left, the shape of space and time. On the right, what's in it. Matter tells space how to curve.\n\nΛ can act like energy belonging to empty space itself. Empty does not mean nothing.",
		"It isn't a blunder. It just isn't the same everywhere.\n\nHere, Λ runs thin. Where it's thin, the geometry gives.\n\nEinstein and Rosen, 1935: a bridge in the equations.\nEverett, 1957: relative states.\nDifferent ways of thinking about more than the world we see.\n\nOn 2.14 I can hear the next sheet over.",
		"Gödel, 1949: a rotating universe whose paths can come back to their own past.\n\nSome nights the next sheet over is LATER.\n\nLIGHT = BALLAST.  [Three lines under it.]\nKeep a lamp lit and you stay where you are.\n\n— Λ.L.  6/79\n\nAt the bottom, smaller: \"If Henrik calls this proof, take my name off it.\"",
	])
	if g.has("dad_notes_read"):
		await mara("Dad's LAMBDA notes. I'm putting them back exactly where he left them.")
		return
	g.set_flag("dad_notes_read")
	await mara("Dad's notes. The same capitals he did the crossword in.")
	await mara("He wasn't listening for little green men. He was listening to empty space.")
	await mara("'Some nights the next sheet over is later.' In 1979 he already knew.")
	await mara("And LIGHT = BALLAST, with three lines under it. That one he tested.")
	await mara("'If Henrik calls this proof, take my name off it.' I wish you'd said that to Henrik.")
	objective()


## Act 3.3: the transmit key, where a museum finds it in 1998.
func _desk_leg() -> void:
	var g := GameState
	if not g.has("chalk_2031"):
		await mara("First I write it down. Before I forget what I saw. The chalkboard in the control room.")
		return
	await narrate("She kneels, and unscrews the foot cap on the left rear leg of Sollen's desk.")
	Audio.sfx("keys", -6.0)
	await narrate("The transmitter key drops out on its lanyard. A scrap of paper comes with it: \"H.S. — Lost is safer than available.\"")
	g.add_item("transmit_key")
	g.set_flag("key_taken")
	hud.toast("Got: Transmit key")
	await mara("The key. Right where 2031 said. Henrik hid it himself.")
	await narrate("She checks the dial. The needle won't settle on 2031 any more. It slides past.")
	await mara("That future needed the key lost. I took it.")
	await say("JUNE (TUNER)", "Then it's a different song now.")
	objective()


func _cassette() -> void:
	if GameState.has("heard_cassette"):
		await mara("I can't listen to it again. Not tonight.")
		return
	await narrate("A cassette in the deck. The label, in Sollen's hand: \"LIND (THE BOY'S) / 1980.\"")
	Audio.sfx("click", -6.0)
	Audio.play_loop("tape_hiss", -16.0, 0.3)
	await wait(0.8)
	await say("TOMAS (TAPE)", "Test, test. October twelfth, 1980. Tomas Lind, still no call sign.")
	await say("TOMAS (TAPE)", "Coal cellar: six steps to the shelf. Tonight it was eight. Same tins. Different labels.")
	await say("TOMAS (TAPE)", "I lit Dad's inspection lamp and it stopped changing. Tried it three times.")
	await say("TOMAS (TAPE)", "Keeping the set in my box. Don't tell Mara.")
	Audio.sfx("click", -12.0)
	await narrate("He stops the tape, then starts it again.")
	Audio.sfx("click", -12.0)
	await say("TOMAS (TAPE)", "Also. A voice can answer you and still not be talking to you. I haven't worked that one out.")
	Audio.stop_loop("tape_hiss", 0.4)
	Audio.sfx("click", -6.0)
	GameState.set_flag("heard_cassette")
	await wait(0.6)
	await mara("...Tomas.")
	await mara("His box. I put his things in the basement because I couldn't stand them at home.")
	objective()


func _drawer() -> void:
	if GameState.has("garage_key"):
		await mara("Pipe, tobacco, mints. I took the key.")
		return
	Audio.sfx("click", -8.0)
	await mara("Pipe, tobacco, mints... and a key on a tag. GARAGE.")
	GameState.set_flag("garage_key")
	hud.toast("Got: Garage key (on Sollen's ring)")
	objective()


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(cv, floor_y, Color("4a3f36"), Color("3a312b"), Color("1d1916"))
	EnvironmentArt.wall_props(cv, str(name))
	_carpet()
	Kit.door(cv, Rect2(40, 340, 90, 310), Color("5a4a3c"))
	_photo_art()
	_couch()
	_coat_stand()
	var win := Rect2(580, 220, 200, 200)
	Kit.night_view(cv, win, 0.0, 700.0, 0.5)
	Kit.window_frame(cv, win, 2)
	_desk()
	_shelf()


func _carpet() -> void:
	cv.draw_rect(Rect2(Kit.L, floor_y, Kit.R - Kit.L, 400), Color("3a2a26"))
	cv.draw_rect(Rect2(150, floor_y + 6, 1000, 60), Color("5a3530"))
	cv.draw_rect(Rect2(150, floor_y + 6, 1000, 60), Color("6e443c"), false, 3.0)


func _photo_art() -> void:
	var r := Rect2(268, 326, 66, 78)
	cv.draw_rect(r.grow(5), Color("6a5030"))
	cv.draw_rect(r, Color("c9c2b0"))
	if freq == "01":
		cv.draw_rect(Rect2(r.position.x + 6, r.position.y + 6, 54, 50), Color("7a8a9a"))
		cv.draw_circle(Vector2(r.get_center().x, r.position.y + 26), 9.0, Color("d8a688"))
		cv.draw_circle(Vector2(r.get_center().x - 2, r.position.y + 21), 9.0, Color("3b2a22"))
		cv.draw_circle(Vector2(r.get_center().x + 1, r.position.y + 27), 7.5, Color("d8a688"))
		cv.draw_rect(Rect2(r.get_center().x - 12, r.position.y + 37, 24, 19), Color("5d5a3b"))
		Kit.text(cv, Vector2(r.position.x, r.end.y - 8), "1982", 10, Color("3a3a3a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	else:
		cv.draw_rect(Rect2(r.position.x + 6, r.position.y + 6, 54, 50), Color("8aa0a8"))
		cv.draw_rect(Rect2(r.position.x + 6, r.position.y + 38, 54, 18), Color("4a6a7a"))
		cv.draw_circle(Vector2(r.position.x + 24, r.position.y + 26), 6.0, Color("d4a386"))
		cv.draw_circle(Vector2(r.position.x + 42, r.position.y + 28), 6.0, Color("d4a386"))
		Kit.text(cv, Vector2(r.position.x, r.end.y - 8), "1961", 10, Color("3a3a3a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _couch() -> void:
	var c := Color("5a3a2c")
	cv.draw_rect(Rect2(170, 500, 262, 70), c.darkened(0.1))
	cv.draw_rect(Rect2(176, 566, 250, 40), c)
	cv.draw_rect(Rect2(160, 530, 26, 80), c.darkened(0.2))
	cv.draw_rect(Rect2(416, 530, 26, 80), c.darkened(0.2))
	cv.draw_rect(Rect2(178, 606, 10, 44), Color("2a1f1a"))
	cv.draw_rect(Rect2(414, 606, 10, 44), Color("2a1f1a"))
	if freq == "H":
		cv.draw_rect(Rect2(196, 548, 70, 22), Color("6e5446"))


func _coat_stand() -> void:
	var x := 476.0
	cv.draw_line(Vector2(x, 400), Vector2(x, 646), Color("3a2a1e"), 6.0)
	cv.draw_line(Vector2(x - 26, 650), Vector2(x + 26, 650), Color("3a2a1e"), 6.0)
	cv.draw_line(Vector2(x, 404), Vector2(x - 20, 392), Color("3a2a1e"), 4.0)
	cv.draw_line(Vector2(x, 404), Vector2(x + 20, 392), Color("3a2a1e"), 4.0)
	if freq != "01":
		return
	# Coat on the left hook.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(x - 22, 396), Vector2(x - 4, 404), Vector2(x - 2, 572), Vector2(x - 46, 576), Vector2(x - 40, 420)]), Color("54452e"))
	cv.draw_line(Vector2(x - 34, 470), Vector2(x - 12, 470), Color("3e3322"), 3.0)
	# Scarf on the right hook, until Mara takes it.
	if not GameState.has("scarf_taken"):
		cv.draw_line(Vector2(x + 20, 394), Vector2(x + 22, 498), Color("3e5a46"), 12.0)
		cv.draw_line(Vector2(x + 30, 394), Vector2(x + 34, 470), Color("3e5a46"), 10.0)
		for k in 4:
			cv.draw_line(Vector2(x + 15, 420 + k * 20), Vector2(x + 27, 420 + k * 20), Color("8a2f2a"), 4.0)


func _desk() -> void:
	cv.draw_rect(Rect2(816, 518, 304, 12), Color("6a4a30"))
	cv.draw_rect(Rect2(824, 530, 288, 120), Color("54392a"))
	cv.draw_rect(Rect2(958, 546, 108, 34), Color("4a3224"))
	cv.draw_rect(Rect2(1002, 560, 22, 6), Color("c9a332"))
	# Lamp.
	var on := _lamp_on()
	cv.draw_rect(Rect2(840, 508, 36, 10), Color("2a2f33"))
	cv.draw_line(Vector2(858, 508), Vector2(858, 470), Color("2a2f33"), 4.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(836, 474), Vector2(880, 474), Vector2(870, 444), Vector2(846, 444)]), Color("2e5a3a"))
	if on:
		cv.draw_colored_polygon(PackedVector2Array([Vector2(836, 474), Vector2(880, 474), Vector2(930, 518), Vector2(800, 518)]), Color(1.0, 0.9, 0.6, 0.18))
		cv.draw_rect(Rect2(850, 474, 16, 6), Color("fff0c0"))
	# Phone: off the hook at home.
	cv.draw_rect(Rect2(894, 500, 48, 18), Color("1f1f22"))
	if freq == "H":
		cv.draw_line(Vector2(930, 498), Vector2(950, 516), Color("1f1f22"), 8.0)
		cv.draw_rect(Rect2(946, 512, 12, 8), Color("1f1f22"))
		cv.draw_arc(Vector2(920, 512), 14.0, 0.2, 2.6, 10, Color("2a2a2e"), 2.0)
	else:
		cv.draw_rect(Rect2(892, 490, 52, 10), Color("1f1f22"))
	# Logbook.
	cv.draw_rect(Rect2(958, 504, 58, 14), Color("6a2a22"))
	cv.draw_rect(Rect2(960, 502, 54, 4), Color("e6dfc8"))
	# Cassette deck.
	if freq == "H":
		cv.draw_rect(Rect2(1032, 494, 62, 24), Color("2a2c30"))
		cv.draw_rect(Rect2(1040, 498, 34, 14), Color("101114"))
		cv.draw_circle(Vector2(1049, 505), 3.0, Color("6a6f73"))
		cv.draw_circle(Vector2(1065, 505), 3.0, Color("6a6f73"))
		cv.draw_rect(Rect2(1078, 500, 10, 4), Color("b8322c"))


func _shelf() -> void:
	var r := Rect2(1140, 300, 112, 350)
	cv.draw_rect(r, Color("3a2a1e"))
	for i in 5:
		var y := r.position.y + 10 + i * 68
		cv.draw_rect(Rect2(r.position.x + 6, y + 56, r.size.x - 12, 6), Color("2a1f16"))
		var x := r.position.x + 10
		var k := 0
		# The middle shelf ends in Dad's GRAVITATION, a black brick of a book.
		var stop := r.end.x - (44.0 if i == 2 else 16.0)
		while x < stop:
			var w := 8.0 + float((i * 7 + k * 3) % 9)
			var h := 36.0 + float((i * 5 + k * 11) % 18)
			var cols := [Color("6a2a22"), Color("2e4a5a"), Color("5a5a3a"), Color("8a7a5a")]
			cv.draw_rect(Rect2(x, y + 56 - h, w, h), cols[(i + k) % 4])
			x += w + 2.0
			k += 1
		if i == 2:
			var b := Rect2(r.end.x - 34, y + 4, 26, 52)
			cv.draw_rect(b, Color("141416"))
			cv.draw_rect(Rect2(b.position.x + 3, b.position.y + 8, b.size.x - 6, 4), Color("e8e4da"))
			cv.draw_rect(Rect2(b.position.x + 3, b.position.y + 14, b.size.x - 6, 2), Color("b8322c"))
			cv.draw_rect(Rect2(b.position.x + 3, b.end.y - 9, b.size.x - 6, 3), Color("8a867c"))
