extends Room
## Act 3.6 — October 14, 1991: PIKE AND LIND RADIO, the painted LIND newer
## than the rest. June on a high stool, Tomas with both hands inside a cassette
## deck. Lise and the baby behind the partition. Then June's box: a roster of
## overnight radio checks from October 1983, and the note that names Blue.
##
## Which Tomas depends on Choice 2. Taken: he came to 1983 at thirteen and is
## twenty-one. Sent back: he lived three more years at home, crossed at
## sixteen, and is twenty-four. Same scene; the marked memories change.

const RIG_X := 1010.0
const WIN := Rect2(560, 200, 150, 150)

var tomas: Actor
var june: Actor
var lise: Actor
## The street losing its shadows, in the window (0..1).
var white := 0.0
var snow: Snowfall
## June's box down off the shelf, the roster open on the bench.
var roster := false
## For screenshot runs: the moment on screen (see autotest _watch_shots).
var shot := ""


func env() -> Env:
	return Env.of("F1991")


func _taken() -> bool:
	return GameState.story.get("TOMAS") == "taken"


func setup() -> void:
	animated_back = false
	place_name = "Pike and Lind Radio  ·  1991"
	base_tint = Color(1.0, 0.97, 0.9)
	walk_min = 100.0
	walk_max = 1140.0
	snow = Snowfall.new()
	snow.area = WIN
	snow.count = 30
	snow.wind = 10.0
	add_child(snow)
	june = add_actor("june_1991", 640.0, -1)
	june.seated = true
	june.seat_y = 30.0
	lise = add_actor("lise_1991", 1180.0, -1)
	lise.prop = "baby"
	lise.visible = GameState.has("lise_out")
	tomas = add_actor(Act3.tomas_1991(), 560.0, 1)
	tomas.arm_pose = [[0.85, 0.55], [0.75, 0.65]]
	make_player(150.0, 1)
	add_layer(1, _draw_bench_top)
	add_hotspot("door", Rect2(26, 330, 100, 320), "Shop front", 110.0, -1)
	add_hotspot("photo", Rect2(318, 232, 74, 98), "Photograph", 360.0)
	add_hotspot("shelves", Rect2(724, 220, 160, 250), "Shelves", 780.0)
	add_hotspot("rig", Rect2(900, 500, 230, 100), "Spare receiver", 940.0, 1)


func enter(entry: String) -> void:
	entered_from = entry


func static_key() -> String:
	return "%s|%s" % [roster, GameState.has("named_blue")]


func ambience() -> void:
	Audio.stop_loop("wind", 0.5)
	Audio.play_loop("room_air", -28.0)
	Audio.play_loop("radio_music", -32.0)
	Audio.set_environment("pike_radio", freq)


func on_arrive() -> void:
	ambience()
	if entered_from == "arrive":
		await _arrive()
	objective()


## Through the dark cabin, down the dry path, to the light over June's door.
func _arrive() -> void:
	await wait(0.5)
	await narrate("The feed cabin is dark. When Mara opens it, the mountain path is dry. Down in town, the light over June's door is still on.")
	await narrate("PIKE AND LIND RADIO. The painted LIND is newer than the rest. In the window are radios and a television playing a recording of the first anniversary of German reunification.")
	await narrate("A cassette case beside it is marked RECORDED 3 OCTOBER 1991. Someone has taped a repair price over half the screen.")
	await narrate("Inside, June is sitting on a high stool. Tomas has both hands inside a cassette deck.")
	await say("JUNE", "You're covering the light.")
	await say("TOMAS", "You're holding it in the wrong place.")
	await say("JUNE", "Seventy-eight years I've been holding things. Now I find out.")
	await narrate("Mara laughs before she can stop herself. Both of them turn.")
	tomas.arm_pose = []
	tomas.face(-1)
	june.face(-1)
	await narrate("Tomas puts the screwdriver down carefully.")
	await say("TOMAS", "You took your time.")
	await tomas.walk_to(250.0)
	await narrate("He crosses the shop. This time he is taller. Mara is the one whose feet nearly leave the floor.")
	await mara("You're real.")
	await say("TOMAS", "Very annoying, according to June.")
	await narrate("June looks down at the cassette deck and gives them the minute.")
	if _taken():
		await say("TOMAS", "June let me sleep behind the bench for a week. Then Ruth said if I was going to grow another inch I could do it in a bed.")
		await mara("You stayed with her.")
		await say("TOMAS", "For a while. I never stopped asking about the other one.")
		await narrate("He sees Mara look at his hands.")
		await say("TOMAS", "What's wrong with them?")
		await mara("Nothing. They're fine.")
	else:
		await say("TOMAS", "I stayed home. Got three years older. Then I went looking for the woman who'd found me.")
		await mara("I sent you back so you'd be safe.")
		await say("TOMAS", "You did. You didn't tell me I had to stay thirteen.")
	GameState.set_flag("tomas91_met")
	await player.walk_to(470.0)
	await tomas.walk_to(760.0)
	tomas.prop = "mug"
	await tomas.walk_to(540.0)
	tomas.face(-1)
	await narrate("He puts her by the bench and brings her coffee in June's chipped mug. She watches him do each ordinary thing.")
	tomas.prop = "none"
	player.prop = "mug"
	await say("TOMAS", "You keep looking at me like I'm going to do a trick.")
	await mara("You made coffee.")
	await say("TOMAS", "I've been practising.")
	await narrate("Behind the partition, a woman asks whether anyone has seen the blue blanket. Tomas lifts it off June's spare receiver and passes it through.")
	lise.visible = true
	GameState.set_flag("lise_out")
	await lise.walk_to(820.0)
	await narrate("Lise appears with a baby asleep against her shoulder. She looks from him to Mara and understands enough not to ask in front of him.")
	await say("LISE", "So you're the one.")
	await mara("Depends who you ask.")
	await say("LISE", "He said you'd say something like that.")
	await tomas.walk_to(760.0)
	tomas.face(1)
	await narrate("Tomas touches the baby's foot with one finger. Mara has not seen him this gentle with anything except a broken radio.")
	var pick: int = await hud.choose(["Ask about his life", "Ask him to come with you"])
	if pick == 0:
		GameState.set_story("LETGO", "life")
		await mara("Tell me something I don't know.")
		tomas.face(-1)
		await say("TOMAS", "I hate cherry pie.")
		await mara("No, you don't.")
		await say("TOMAS", "I liked getting it for free. Took me years to work out those were different things.")
		await narrate("He points to a photograph behind the till: Lise and Tomas on a windy beach, both laughing.")
		await mara("What was funny?")
		await say("TOMAS", "I asked if she'd marry me. She thought I asked if she'd carry me.")
		await say("LISE", "Your boots were full of water. It seemed a fair question.")
		await narrate("Mara laughs. Nobody reaches for a radio.")
	else:
		GameState.set_story("LETGO", "asked")
		await mara("Come with me.")
		await narrate("She already knows what happened to Ruth's cassette. She asks anyway.")
		tomas.face(-1)
		if _taken():
			await say("TOMAS", "You did that once already. Let me keep it.")
		else:
			await say("TOMAS", "You let me go home once. Don't ask me to leave her now.")
		tomas.face(1)
		await narrate("He looks toward Lise. Mara does too.")
		await mara("All right.")
	await _roster()


## June's box: OVERNIGHT RADIO CHECKS, OCTOBER 1983. Two rows, two dogs, two
## goodbyes. And the note under the roster.
func _roster() -> void:
	var g := GameState
	await narrate("June reaches for a box high on a shelf. Mara gets it down for her. Inside are twenty years of repair slips and a folded sheet headed OVERNIGHT RADIO CHECKS — OCTOBER 1983. June has never thrown a paper away if someone might need it again.")
	roster = true
	await say("JUNE", "You two used to come in on top of each other. Same voice. Different complaints. Had to keep a list.")
	await hud.read_doc("OVERNIGHT RADIO CHECKS — OCTOBER 1983", [
		"H  —  PEPPER  —  MOM  —  %s        [a red pencil dash]\n\n07  —  BISCUIT  —  MA  —  %s        [a blue pencil dash]\n\nThe ink has gone brown." % [Story.roster_signoff(false), Story.roster_signoff(true)],
	])
	player.prop = "none"
	await narrate("Mara sets the mug down.")
	var blue := Story.blue_signoff()
	await mara(blue.replace(", Tomas", ""))
	await say("TOMAS", "That's yours.")
	await mara("Mine?")
	await say("TOMAS", "The woman who came for me. In the snow. The other one said something else.")
	await narrate("June unfolds the last corner. There is a short note under the roster: AFTER ASH STREET, H'S SET ANSWERED AS 07. SHE DIDN'T KNOW.")
	# From here the script names her: Blue.
	g.set_flag("named_blue")
	shot = "roster"
	await mara("I was at the back door.")
	await narrate("She looks down at the radio. Beneath its carry strap, a red pencil H. She did not write it.")
	await mara("There was someone beside the table. I saw her. I thought the house had changed around me.")
	await say("JUNE", "A house can change a lot before you'll believe you're in the wrong one.")
	await mara("The woman at the table. The one with red tape. Where did she go?")
	await narrate("June's hand rests on the roster. She does not have that answer.")
	await narrate("Tomas reaches for the mug before Blue can knock it over. A young man's hands. She lets him steady it.")
	await mara("I've been trying to get back to a place I was already in.")
	Audio.sfx("click", -10.0)
	Audio.play_loop("static", -24.0, 0.3)
	await narrate("The spare receiver clicks on. Eighty-One's voice, aged by distance rather than years.")
	await say("EIGHTY-ONE (RADIO)", "I told you you'd find him. Look at him, love. Is there anything else you need to see?")
	await narrate("Blue pulls the set toward her.")
	await mara("What did you do to her?")
	await say("EIGHTY-ONE (RADIO)", "Come back to the control room.")
	Audio.stop_loop("static", 0.4)
	await narrate("The line goes quiet. No instructions follow it.")
	shot = "white"
	var tw := create_tween()
	tw.tween_property(self, "white", 0.6, 2.0)
	lise.face(-1)
	await narrate("Lise looks out of the window. The street has lost its shadows. June puts one hand on Tomas's shoulder and one on Blue's sleeve.")
	await say("JUNE", "You've got a way back. Use it.")
	await mara("I don't want this to be the last time.")
	await say("TOMAS", "Then don't spend it looking at the door.")
	await tomas.walk_to(520.0)
	tomas.face(-1)
	g.set_flag("roster_done")
	await narrate("She holds him. He smells of solder and coffee. When the sound begins to go, she keeps her face against his coat until she cannot hear her own breathing.")
	tw = create_tween()
	tw.tween_property(self, "white", 1.0, 1.2)
	await Act3.silence(self)


func on_hotspot(id: String) -> void:
	match id:
		"door":
			await mara("Not yet. He's right here.")
		"photo":
			await mara("Lise and Tomas on a windy beach, both laughing. His boots full of water.")
		"shelves":
			await mara("Radios, televisions, a stack of rental tapes somebody never took back. June's box of repair slips, up on top.")
		"rig":
			await mara("June's spare receiver. The blue blanket used to live on it.")


func use_item(id: String, item: String) -> bool:
	return false


func examine_item(item: String) -> bool:
	if item == "tuner":
		await mara("The needle's on 1991, and it's staying there. Red pencil under the strap: H.")
		return true
	return false


func draw_back() -> void:
	# Walls: wood panelling to the dado, pegboard and paint above.
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 760), Color("4a5246"), Color("5c6656"))
	Kit.vgrad(cv, Rect2(Kit.L, 540, Kit.R - Kit.L, 110), Color("6a4a30"), Color("553a24"))
	for i in 46:
		cv.draw_line(Vector2(Kit.L + i * 48.0, 540), Vector2(Kit.L + i * 48.0, 650), Color(0, 0, 0, 0.18), 2.0)
	cv.draw_rect(Rect2(Kit.L, 536, Kit.R - Kit.L, 6), Color("3a2a1c"))
	# Floor: worn boards, a rag rug.
	Kit.vgrad(cv, Rect2(Kit.L, 650, Kit.R - Kit.L, 120), Color("5a4430"), Color("3e2e20"))
	for i in 8:
		cv.draw_line(Vector2(Kit.L, 660 + i * 14.0), Vector2(Kit.R, 662 + i * 14.0), Color(0, 0, 0, 0.16), 2.0)
	cv.draw_set_transform(Vector2(640, 690), 0.0, Vector2(1.0, 0.18))
	cv.draw_circle(Vector2.ZERO, 200.0, Color("7a3a3a"))
	cv.draw_circle(Vector2.ZERO, 160.0, Color("5a6a7a"))
	cv.draw_circle(Vector2.ZERO, 110.0, Color("8a6a3a"))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The fluorescent tube.
	cv.draw_rect(Rect2(420, 36, 420, 14), Color("2a2c2e"))
	cv.draw_rect(Rect2(428, 40, 404, 6), Color("f2f6ee"))
	Kit.door(cv, Rect2(30, 340, 92, 310), Color("5a5048"), "SHOP")
	_armchair()
	_pc_desk()
	_calendar()
	_window_art()
	_bench_art()
	_shelves_art()
	_hot_plate()
	_rig_art()
	_photo_wall()
	_stool()


func _armchair() -> void:
	# A wing chair, true size: seat at the knee, back at the shoulder of whoever's in it.
	var c := Color("7a5a3a")
	cv.draw_rect(Rect2(168, 520, 124, 84), c.darkened(0.1))
	cv.draw_rect(Rect2(174, 594, 112, 26), c)
	cv.draw_line(Vector2(182, 620), Vector2(182, 650), Color("2a1e14"), 6.0)
	cv.draw_line(Vector2(278, 620), Vector2(278, 650), Color("2a1e14"), 6.0)
	# A crocheted blanket over the back.
	for k in 6:
		cv.draw_rect(Rect2(176 + k * 18, 520, 16, 30), [Color("c8603a"), Color("e8c060"), Color("5a8a6a")][k % 3])


func _draw_armrest(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(158, 570, 22, 52), Color("6a4a2e"))
	ci.draw_rect(Rect2(280, 570, 22, 52), Color("6a4a2e"))


## A desk at desk height, the beige computer on it: the box, the monitor on
## the box, the keyboard, a dot-matrix printer with its paper.
func _pc_desk() -> void:
	var top := 566.0
	cv.draw_rect(Rect2(312, top, 160, 10), Color("8a7a5a"))
	cv.draw_line(Vector2(320, top + 10), Vector2(320, 650), Color("4a3a2a"), 5.0)
	cv.draw_line(Vector2(464, top + 10), Vector2(464, 650), Color("4a3a2a"), 5.0)
	cv.draw_rect(Rect2(330, top - 36, 104, 36), Color("d8d0b8"))
	cv.draw_rect(Rect2(340, top - 26, 30, 6), Color("1a1a1a"))
	cv.draw_rect(Rect2(400, top - 26, 6, 6), Color("3aff6a"))
	cv.draw_rect(Rect2(340, top - 120, 84, 80), Color("d4ccb2"))
	cv.draw_rect(Rect2(348, top - 112, 68, 54), Color("0e140e"))
	Kit.text(cv, Vector2(352, top - 98), "C:\\>_", 9, Color("8aff9a"))
	Kit.text(cv, Vector2(352, top - 84), "QSL.DBF", 8, Color("5ac06a"))
	cv.draw_rect(Rect2(340, top - 40, 84, 4), Color("b8b098"))
	cv.draw_rect(Rect2(326, top - 8, 100, 8), Color("e0d8c0"))
	cv.draw_rect(Rect2(436, top - 22, 30, 22), Color("cfc8b0"))
	for k in 4:
		cv.draw_line(Vector2(440, top - 36 - k * 6), Vector2(462, top - 36 - k * 6), Color("f2efe6"), 2.0)


func _calendar() -> void:
	var r := Rect2(318, 232, 74, 98)
	cv.draw_rect(r, Color("f2efe6"))
	cv.draw_rect(Rect2(r.position, Vector2(r.size.x, 40)), Color("4a6a8a"))
	Kit.text(cv, r.position + Vector2(4, 54), "OCTOBER", 9, Color("2a2a2a"))
	Kit.text(cv, r.position + Vector2(4, 66), "1991", 9, Color("8a2a24"))
	for row in 3:
		for c in 6:
			cv.draw_rect(Rect2(r.position.x + 6 + c * 11, r.position.y + 72 + row * 8, 8, 5), Color("c8c4b8"))
	cv.draw_circle(Vector2(r.position.x + 28, r.position.y + 81), 5.0, Color(0.8, 0.1, 0.1, 0.6), false, 1.5)
	# QSL cards from everywhere, pinned round it.
	for k in 7:
		var p := Vector2(402 + (k % 4) * 36, 232 + (k / 4) * 46)
		cv.draw_rect(Rect2(p, Vector2(30, 40)), [Color("e8d8a0"), Color("a8c8e8"), Color("e8b0a0"), Color("c8e0b0")][k % 4])
		cv.draw_rect(Rect2(p + Vector2(4, 6), Vector2(22, 6)), Color("4a4a4a"))


func _window_art() -> void:
	var r := WIN
	var e := env()
	Kit.vgrad(cv, r, Color("06080e"), Color("1a2034"))
	# Main Street across the way: the video store's sign, a lamp, roofs in snow.
	cv.draw_rect(Rect2(r.position.x, r.position.y + 70, r.size.x, 80), Color("1c1820"))
	cv.draw_rect(Rect2(r.position.x + 20, r.position.y + 84, 70, 16), Color("c84a8a"))
	cv.draw_rect(Rect2(r.position.x + 22, r.position.y + 106, 22, 28), Color("e8b060"))
	cv.draw_rect(Rect2(r.position.x + 100, r.position.y + 106, 22, 28), Color("3a3446"))
	cv.draw_rect(Rect2(r.position.x, r.end.y - 14, r.size.x, 14), Color("b4bed0"))
	Kit.window_frame(cv, r, 2)
	if e.snowy():
		Townscape.snow_ledge(cv, r.position.x - 8, r.end.x + 8, r.end.y + 6, 4.0, 3)


func _bench_art() -> void:
	# The workbench at standing height, the pegboard over it.
	var top := 550.0
	cv.draw_rect(Rect2(480, top, 220, 12), Color("8a6a46"))
	cv.draw_rect(Rect2(488, top + 12, 204, 20), Color("6a4e34"))
	cv.draw_line(Vector2(492, top + 32), Vector2(492, 650), Color("4a3422"), 6.0)
	cv.draw_line(Vector2(688, top + 32), Vector2(688, 650), Color("4a3422"), 6.0)
	cv.draw_rect(Rect2(484, 384, 212, 120), Color("b89a6a"))
	for y in range(392, 500, 10):
		for x in range(490, 692, 10):
			cv.draw_circle(Vector2(x, y), 1.2, Color("8a6e44"))
	for k in 5:
		var x := 500.0 + k * 32.0
		cv.draw_line(Vector2(x, 396), Vector2(x + (k % 2) * 4, 444 + (k % 3) * 10), [Color("3a3a3e"), Color("c84a3a"), Color("e0b440")][k % 3], 4.0)
	# The photocopy, pinned at the end: a journal page gone soft and grey,
	# a title in bold, two columns, pencil down the margin.
	var pc := Rect2(650, 390, 42, 58)
	cv.draw_colored_polygon(PackedVector2Array([pc.position, Vector2(pc.end.x, pc.position.y + 2), pc.end + Vector2(-2, 0), Vector2(pc.position.x + 1, pc.end.y)]), Color("e4e2da"))
	cv.draw_rect(Rect2(pc.position + Vector2(4, 5), Vector2(32, 3)), Color("3a3a3a"))
	cv.draw_rect(Rect2(pc.position + Vector2(4, 10), Vector2(24, 2)), Color("5a5a5a"))
	for row in 9:
		for col in 2:
			cv.draw_line(pc.position + Vector2(4 + col * 17, 17 + row * 4), pc.position + Vector2(18 + col * 17, 17 + row * 4), Color(0.4, 0.4, 0.42, 0.6), 1.0)
	cv.draw_line(pc.position + Vector2(6, 32), pc.position + Vector2(30, 32), Color("b8322c"), 1.0)
	cv.draw_line(pc.position + Vector2(39, 16), pc.position + Vector2(40, 50), Color(0.3, 0.3, 0.32, 0.8), 1.0)
	cv.draw_circle(pc.position + Vector2(21, 2), 2.5, Color("c83a2a"))
	# Mrs. Halloran's radio, open; the iron in its stand; the solder spool.
	var fixed := GameState.has("held_light")
	cv.draw_rect(Rect2(540, top - 32, 70, 32), Color("8a5a3a"))
	cv.draw_rect(Rect2(546, top - 26, 30, 12), Color("f2c27a") if fixed else Color("4a3a2a"))
	cv.draw_rect(Rect2(586, top - 28, 18, 20), Color("2e4a3a"))
	cv.draw_line(Vector2(630, top - 4), Vector2(660, top - 30), Color("2a2a2a"), 4.0)
	cv.draw_line(Vector2(660, top - 30), Vector2(672, top - 42), Color("9aa0a6"), 2.0)
	cv.draw_circle(Vector2(678, top - 8), 8.0, Color("9aa0a6"))
	cv.draw_circle(Vector2(678, top - 8), 3.0, Color("6a6a6a"))
	# The magnifier lamp on its arm.
	cv.draw_line(Vector2(500, top), Vector2(514, top - 50), Color("2a2c30"), 3.0)
	cv.draw_line(Vector2(514, top - 50), Vector2(548, top - 58), Color("2a2c30"), 3.0)
	cv.draw_circle(Vector2(556, top - 56), 12.0, Color("d8dcd0"))
	cv.draw_circle(Vector2(556, top - 56), 8.0, Color("eef4f0"))


func _shelves_art() -> void:
	var r := Rect2(724, 220, 160, 250)
	cv.draw_rect(r, Color("3a2c20"))
	for row in 3:
		var y := r.position.y + 78 + row * 82.0
		cv.draw_rect(Rect2(r.position.x, y, r.size.x, 6), Color("6a4e34"))
	# A television in a wood cabinet, VHS boxes, a radio with its battery box taped shut.
	cv.draw_rect(Rect2(732, 238, 70, 60), Color("6a4a2e"))
	cv.draw_rect(Rect2(738, 244, 46, 40), Color("2a3a4a"))
	cv.draw_line(Vector2(744, 250), Vector2(760, 262), Color(1, 1, 1, 0.15), 3.0)
	for k in 3:
		cv.draw_circle(Vector2(792, 252 + k * 12), 3.0, Color("c8b890"))
	for k in 8:
		cv.draw_rect(Rect2(810 + k * 9, 254, 8, 44), [Color("1a1a1c"), Color("c84a3a"), Color("2a4a8a"), Color("e8e2d0")][k % 4])
	for k in 3:
		cv.draw_rect(Rect2(734 + k * 48, 330, 42, 30), [Color("8a6a40"), Color("3a3a3e"), Color("2e4a3a")][k])
		cv.draw_rect(Rect2(740 + k * 48, 336, 18, 8), Color("e8a54b"))
	cv.draw_rect(Rect2(760, 352, 14, 8), Color("c8c0a0"))
	cv.draw_rect(Rect2(734, 412, 60, 40), Color("5a5a60"))
	cv.draw_rect(Rect2(800, 420, 76, 32), Color("2a2a2e"))
	cv.draw_circle(Vector2(816, 436), 10.0, Color("4a4a50"))
	cv.draw_circle(Vector2(860, 436), 10.0, Color("4a4a50"))
	# A paperback lying on the boom box, read to bits.
	cv.draw_rect(Rect2(808, 412, 50, 8), Color("16181c"))
	cv.draw_rect(Rect2(810, 414, 46, 2), Color("e8e4da"))
	cv.draw_rect(Rect2(856, 412, 2, 8), Color("c8c0a8"))


func _hot_plate() -> void:
	var top := 556.0
	cv.draw_rect(Rect2(722, top, 120, 10), Color("8a6a46"))
	cv.draw_line(Vector2(730, top + 10), Vector2(730, 650), Color("4a3422"), 5.0)
	cv.draw_line(Vector2(834, top + 10), Vector2(834, 650), Color("4a3422"), 5.0)
	cv.draw_rect(Rect2(736, top - 10, 44, 10), Color("3a3a3e"))
	cv.draw_circle(Vector2(758, top - 6), 6.0, Color("a83a2a"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(746, top - 10), Vector2(770, top - 10), Vector2(766, top - 50), Vector2(750, top - 50)]), Color("b8bcc0"))
	cv.draw_circle(Vector2(758, top - 54), 5.0, Color("8a8e92"))
	for k in 2:
		EnvironmentArt.mug(cv, Vector2(796 + k * 22, top - 14))


## The ham rig on its desk: a 1980s transceiver, its dial lit on 2.14, the
## power supply, the desk mic, and the headphones on their hook.
func _rig_art() -> void:
	var top := 566.0
	cv.draw_rect(Rect2(894, top, 250, 12), Color("8a6a46"))
	cv.draw_rect(Rect2(900, top + 12, 238, 26), Color("6a4e34"))
	cv.draw_line(Vector2(906, top + 38), Vector2(906, 650), Color("4a3422"), 6.0)
	cv.draw_line(Vector2(1132, top + 38), Vector2(1132, 650), Color("4a3422"), 6.0)
	cv.draw_rect(Rect2(930, top - 56, 130, 56), Color("2a2c30"))
	cv.draw_rect(Rect2(940, top - 48, 70, 20), Color("0e1a14"))
	Kit.text(cv, Vector2(944, top - 33), "2.1400", 12, Color("6aff9a"))
	for k in 5:
		cv.draw_circle(Vector2(944 + k * 24, top - 14), 6.0, Color("1a1a1c"))
	cv.draw_circle(Vector2(1036, top - 36), 12.0, Color("1a1a1c"))
	cv.draw_rect(Rect2(1066, top - 36, 50, 36), Color("4a4c50"))
	cv.draw_circle(Vector2(1080, top - 22), 5.0, Color("e8e2cc"))
	cv.draw_line(Vector2(912, top), Vector2(912, top - 40), Color("2a2a2a"), 3.0)
	cv.draw_rect(Rect2(904, top - 52, 16, 14), Color("3a3a3e"))
	if not GameState.has("roll_call"):
		cv.draw_arc(Vector2(1120, 470), 12.0, PI, TAU, 10, Color("1a1a1c"), 4.0)
		cv.draw_circle(Vector2(1108, 474), 6.0, Color("1a1a1c"))
		cv.draw_circle(Vector2(1132, 474), 6.0, Color("1a1a1c"))


## Over the rig: QSL cards, and behind the till a photograph of Lise and Tomas on a windy beach.
func _photo_wall() -> void:
	for k in 9:
		var p := Vector2(904 + (k % 5) * 46, 176 + (k / 5) * 60)
		cv.draw_rect(Rect2(p, Vector2(38, 50)), [Color("e8d8a0"), Color("a8c8e8"), Color("e8b0a0"), Color("c8e0b0")][k % 4])
		cv.draw_rect(Rect2(p + Vector2(5, 8), Vector2(28, 7)), Color("4a4a4a"))
	cv.draw_rect(Rect2(1150, 300, 64, 48), Color("f2efe6"))
	Kit.vgrad(cv, Rect2(1154, 304, 56, 24), Color("8ab0d0"), Color("c8d8e0"))
	cv.draw_rect(Rect2(1154, 328, 56, 16), Color("d8c8a0"))
	cv.draw_circle(Vector2(1172, 330), 4.0, Color("e8bfa4"))
	cv.draw_circle(Vector2(1192, 328), 4.0, Color("dfb093"))


## June's high stool by the bench.
func _stool() -> void:
	cv.draw_rect(Rect2(614, 596, 52, 8), Color("6a4a2e"))
	cv.draw_line(Vector2(620, 604), Vector2(612, 650), Color("3a2a1c"), 4.0)
	cv.draw_line(Vector2(660, 604), Vector2(668, 650), Color("3a2a1c"), 4.0)
	cv.draw_line(Vector2(616, 628), Vector2(664, 628), Color("3a2a1c"), 3.0)


## The cassette deck open on the bench, and later June's box and the roster.
func _draw_bench_top(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(496, 532, 40, 18), Color("2a2a2e"))
	ci.draw_rect(Rect2(502, 536, 18, 8), Color("8a8e92"))
	if roster:
		ci.draw_rect(Rect2(600, 520, 60, 30), Color("b89a6a"))
		ci.draw_rect(Rect2(540, 540, 46, 10), Color("f0e8d4"))
		ci.draw_line(Vector2(544, 543), Vector2(560, 543), Color("b8322c"), 1.5)
		ci.draw_line(Vector2(544, 547), Vector2(560, 547), Color("2f63c9"), 1.5)


func draw_glow(ci: CanvasItem) -> void:
	Kit.soft_glow(ci, Vector2(975, 528), 40.0, Color(0.4, 1.0, 0.6, 0.18))
	if white > 0.0:
		var r := WIN
		ci.draw_rect(Rect2(r.end.x - r.size.x * white, r.position.y, r.size.x * white, r.size.y), Color(0.96, 0.97, 1.0, 0.95))
		Kit.soft_glow(ci, r.get_center(), 200.0 * white, Color(1, 1, 1, 0.35 * white))

