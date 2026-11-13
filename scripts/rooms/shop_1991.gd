extends Room
## Act 3.6 — October 14, 1991, the back room of Pike & Lind Radio, where Tomas
## calls on 2.14 every year at 2:14. Tomas's call was the loudest thing the
## dish could hear, so Mara comes out of the dark into the room he calls from.
##
## Which Tomas depends on Choice 2. Taken: H's 1991, Tomas is 21 and runs the
## shop with June, who's 78 and asleep in the armchair. Left: 12's 1991, he's
## 24, Lise is expecting in December, and there's a crib in a flat box and two
## cans of yellow paint for tomorrow.
##
## The room: a 1991 workshop. Fluorescent tube, pegboard, televisions with wood
## cabinets, a beige PC with a dot-matrix printer, VHS boxes, QSL cards from
## all over the world, a calendar, a hot plate with the coffee on, the ham rig,
## and over it eighty strips of electrical tape, one for each name, and a blank
## one with a question mark.

const RIG_X := 1010.0
const WIN := Rect2(560, 200, 150, 150)

var tomas: Actor
var other: Actor
## The reveal: the close-up of her wrist (0..1), and the tells flashing past.
var closeup := 0.0
var replay := ""
## The white at the end of the street, then in the window (0..1).
var white := 0.0
var snow: Snowfall
## For screenshot runs: the moment on screen (see autotest _watch_shots).
var shot := ""


func env() -> Env:
	return Env.of("F1991")


func _taken() -> bool:
	return GameState.story.get("TOMAS") == "taken"


func setup() -> void:
	animated_back = false
	place_name = "Pike & Lind Radio  ·  1991"
	base_tint = Color(1.0, 0.97, 0.9)
	walk_min = 100.0
	walk_max = 1140.0
	snow = Snowfall.new()
	snow.area = WIN
	snow.count = 30
	snow.wind = 10.0
	add_child(snow)
	other = add_actor("june_1991" if _taken() else "lise_1991", 222.0, 1)
	other.seated = true
	other.seat_y = 50.0
	tomas = add_actor(Act3.tomas_1991(), 790.0, -1)
	make_player(150.0, 1)
	add_layer(1, _draw_armrest)
	add_hotspot("door", Rect2(26, 330, 100, 320), "Shop front", 110.0, -1)
	add_hotspot("other", Rect2(160, 450, 130, 200), "June" if _taken() else "Lise", 320.0, -1)
	add_hotspot("pc", Rect2(316, 440, 150, 132), "Computer", 390.0)
	add_hotspot("bench", Rect2(486, 500, 210, 90), "Workbench", 560.0)
	add_hotspot("photocopy", Rect2(644, 384, 54, 72), "Photocopy", 640.0)
	add_hotspot("window", WIN, "Window", 640.0)
	add_hotspot("shelves", Rect2(724, 220, 160, 250), "Shelves", 780.0)
	add_hotspot("tomas", Rect2(746, 440, 90, 210), "Tomas", 700.0, 1, func() -> bool: return not GameState.has("roll_call"))
	add_hotspot("rig", Rect2(900, 500, 230, 100), "Ham rig", 940.0, 1)
	add_hotspot("tapes", Rect2(900, 160, 250, 270), "Tape strips", 960.0, 1)
	if not _taken():
		add_hotspot("crib", Rect2(1150, 430, 110, 220), "Flat box", 1120.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	if entry == "from_street":
		player.position.x = 140.0
		tomas.position.x = 220.0 + 80.0
		tomas.face(1)


func static_key() -> String:
	return "%s|%s|%s" % [GameState.has("held_light"), GameState.has("roll_call"), GameState.has("letgo_done")]


func ambience() -> void:
	Audio.stop_loop("wind", 0.5)
	Audio.play_loop("room_air", -28.0)
	if not GameState.has("roll_call"):
		Audio.play_loop("shortwave", -30.0)
	Audio.set_environment("pike_radio", freq)


func score_quiet() -> bool:
	return GameState.has("roll_call")


func on_arrive() -> void:
	ambience()
	match entered_from:
		"arrive":
			await _arrive()
		"from_street":
			await tomas.walk_to(790.0)
			tomas.face(-1)
	objective()


func _arrive() -> void:
	await wait(0.5)
	await narrate("Out of the dark, into a back room that smells of solder and coffee.")
	await wait(0.3)
	tomas.face(-1)
	if _taken():
		await say("TOMAS", "...Mara?")
		await say("TOMAS", "No. You can't be. You died. The night you brought me home.")
		await mara("Tomas. You're...")
		await say("TOMAS", "Twenty-one. Twenty-two in March. You look exactly the same.")
		await say("JUNE", "(waking) Who's that, honey? ...Oh. Oh, my.")
		await say("JUNE", "I'll put the kettle on. No, I won't. I'll sit right here and not say a word.")
	else:
		await say("TOMAS", "...You.")
		await say("TOMAS", "The lady at the trees. You sent me back to my sister.")
		await mara("And you went.")
		await say("TOMAS", "I went. I'm twenty-four. I've called you on two-fourteen every year since I was fifteen, to say thank you.")
		await say("LISE", "(from the armchair) Tom? Who is it?")
		await say("TOMAS", "An old friend, Lise. Go back to sleep.")
	GameState.set_flag("tomas91_met")


func on_hotspot(id: String) -> void:
	match id:
		"door":
			if GameState.has("roll_call"):
				await mara("Not now. Not with ninety seconds left.")
			elif GameState.has("coffee_1991"):
				Audio.sfx("shopbell", -10.0)
				main.change_room("main_street_1991", "from_shop")
			else:
				await mara("The shop's through there, dark. He's right here.")
		"other":
			await _other()
		"pc":
			await mara("A computer. Beige, with a screen like a little television. C, colon, backslash, and a cursor blinking.")
			await mara("Tomas has a computer.")
		"bench":
			await _bench()
		"window":
			await mara("Main Street, in the snow. Eight years on.")
			if GameState.has("roll_call"):
				await mara("And the white, at the end of it. Coming.")
		"shelves":
			if _taken():
				await mara("Radios, televisions, a stack of rental tapes somebody never took back.")
				await mara("One radio with its battery box taped shut. A ring in there, he said. Lise's.")
			else:
				await mara("Radios, televisions, a stack of rental tapes somebody never took back.")
				await mara("And a paint chart, every yellow they make. One's circled: BUTTERCUP.")
			await mara("On the boom box, a paperback read to bits: A BRIEF HISTORY OF TIME. A page turned down at \"The Arrow of Time\".")
		"photocopy":
			await _photocopy()
		"tomas":
			await _tomas()
		"rig":
			if GameState.has("roll_call"):
				await mara("The headphones are still warm.")
			else:
				await mara("His rig. Headphones on the hook. He calls on 2.14 from here, every year.")
		"tapes":
			await _tapes()
		"crib":
			await mara("A crib, in a flat box. Two cans of yellow paint on top. Tomorrow.")


func use_item(id: String, item: String) -> bool:
	if item == "flashlight" and id == "bench":
		await _bench()
		return true
	return false


func examine_item(item: String) -> bool:
	if item == "tuner":
		await mara("The needle's on 1991, and it's staying there. I'm not going anywhere till this lets me.")
		return true
	return false


func _other() -> void:
	if _taken():
		await say("JUNE", "Don't mind me, honey. I'm seventy-eight. I sleep where I sit.")
		await say("JUNE", "He's called on two-fourteen every year since he was fifteen. I taught him how.")
	else:
		await say("LISE", "(half asleep) Mm. He does this every year. Two-fourteen. I bring a blanket.")
		await narrate("One hand on the curve of her stomach.")


func _tomas() -> void:
	var g := GameState
	if not g.has("coffee_1991"):
		g.set_flag("coffee_1991")
		await narrate("He makes coffee on a hot plate, in a percolator older than either of them.")
		if _taken():
			await say("TOMAS", "June made me a partner. PIKE & LIND. Televisions, video machines, the odd satellite dish. Radios, when anyone still wants one.")
			await say("TOMAS", "Tomorrow I drive Lise to the coast. If there's still a coast.")
		else:
			await say("TOMAS", "I fix things for June, nights. Lise and me have the old Halloran house now. December, the baby.")
			await say("TOMAS", "Tomorrow we paint the nursery. She wants yellow. I want yellow too, I'm just not allowed to say so first.")
		await say("TOMAS", "Come out front. I want you to see it. All of it, while it's there.")
		objective()
		return
	if not g.has("street_done"):
		await say("TOMAS", "Out front, through the shop. Come and see.")
		return
	if not g.has("held_light"):
		await say("TOMAS", "Mrs. Halloran's kitchen set, on the bench. Loose battery contact. Hold the light for me?")
		return
	await _talk_life()


func _bench() -> void:
	var g := GameState
	if g.has("held_light"):
		await mara("Mrs. Halloran's radio, working. She'll have the farm report in the morning.")
		return
	if not g.has("street_done"):
		await mara("A customer's radio, open on the bench. A soldering iron in its stand, warming.")
		return
	await say("TOMAS", "Mrs. Halloran's kitchen set. Loose battery contact. Hold the light?")
	await tomas.walk_to(620.0)
	tomas.face(-1)
	await player.walk_to(520.0)
	player.face(1)
	player.prop = "flashlight"
	await narrate("Mara holds the light. He solders.")
	Audio.sfx("click", -10.0)
	await wait(0.5)
	Audio.sfx("static", -14.0)
	await wait(0.6)
	Audio.sfx("powerup", -10.0)
	Audio.play_loop("radio_music", -24.0, 0.4)
	await wait(0.6)
	await mara("You fixed it.")
	await say("TOMAS", "Mostly. That means yes, I know.")
	Audio.stop_loop("radio_music", 1.2)
	player.prop = ""
	g.set_flag("held_light")
	await tomas.walk_to(790.0)
	tomas.face(-1)
	objective()


## A 1988 physics paper pinned over the bench, read soft: how a wormhole
## could be made into a time machine. Tomas's notes down the side.
func _photocopy() -> void:
	var g := GameState
	await narrate("Pinned to the pegboard, a photocopy out of a physics journal, gone soft with handling.")
	await hud.read_doc("PHYSICAL REVIEW LETTERS  ·  SEPTEMBER 1988", [
		"WORMHOLES, TIME MACHINES, AND THE WEAK ENERGY CONDITION\n\nMichael S. Morris, Kip S. Thorne, Ulvi Yurtsever\n\n[\"Time machine\" is underlined twice.]\n\nAt the top, in Tomas's capitals: THORNE. SAME THORNE AS DAD'S BIG BLACK BOOK.",
		"Down the margin, in Tomas's hand:\n\n\"A wormhole is a short cut through space. Move one mouth and it's a short cut through TIME.\"\n\n\"The catch: something has to hold the throat open. Exotic matter. Energy that pushes instead of pulls.\"\n\n\"Dad's thin places push.\"",
	])
	if g.has("wormhole_paper"):
		return
	g.set_flag("wormhole_paper")
	await mara("He reads physics journals now. Of course he does.")
	await mara("A short cut through time, if something holds it open. Something like Dad's thin places.")
	objective()


func _tapes() -> void:
	if GameState.has("roll_call"):
		await mara("Eighty strips. Eighty of me. And one blank, with a question mark.")
		return
	await narrate("Over the rig, eighty strips of electrical tape in rows, every colour, each labelled underneath in his handwriting. One is blank, with a question mark.")
	await mara("Grey. Red. Green. Blue...")


## He asks about her life; she has to invent some of it. Then it's 2:14.
func _talk_life() -> void:
	await say("TOMAS", "So. Tell me about you. Whatever your life is now.")
	await narrate("She tells him. She finds she has to invent some of it.")
	if _taken():
		await say("TOMAS", "I call her too, some years. The other you. The one I left at the gate, in 1980.")
		await say("TOMAS", "I don't think she can hear.")
	else:
		await say("TOMAS", "My sister's asleep across town. I never told her about you. About the trees.")
	await say("TOMAS", "Somebody has to keep calling.")
	await wait(0.3)
	await _roll_call()


## 2:14: the call, and what always answers it.
func _roll_call() -> void:
	var g := GameState
	g.set_clock("2:14", false)
	await say("TOMAS", "Two-fourteen.")
	await tomas.walk_to(RIG_X)
	tomas.face(1)
	tomas.headphones_mode = "head"
	await player.walk_to(880.0)
	player.face(1)
	Audio.stop_loop("shortwave", 0.4)
	Audio.play_loop("static", -18.0, 0.4)
	await say("TOMAS", "This is Tomas Lind, Halvard, on two-fourteen. Like every year. I'm still here.")
	await wait(0.8)
	await say("TOMAS", "It's you. Older. Every year at two-fourteen she reads them out.")
	await say("TOMAS", "I used to think you were counting the dead.")
	tomas.face(-1)
	await say("EIGHTY-ONE (SPEAKER)", "...Grey. Thirty-one. Stopped at the dish.")
	await say("EIGHTY-ONE (SPEAKER)", "Red. H. Alive. Lost in the dark at Ash Street.")
	await say("EIGHTY-ONE (SPEAKER)", "Blue. Zero-seven. Alive. Took Red's place at Ash Street. Doesn't know.")
	await say("EIGHTY-ONE (SPEAKER)", "Control room, H...")
	await narrate("She stops where a word should be.")
	g.set_flag("roll_call")
	await _reveal()


## The camera on her wrist, for the first time. The music drops out.
func _reveal() -> void:
	Audio.stop_all(0.2)
	shot = "wrist"
	var tw := create_tween()
	tw.tween_property(self, "closeup", 1.0, 0.6)
	await tw.finished
	Audio.sfx("sting", -6.0)
	await wait(1.6)
	for line in ["The match going out.", "\"Ma.\"", "Biscuit.", "Up, then down.", "\"Her girl used red tape.\""]:
		replay = line
		Audio.sfx("click", -8.0)
		await wait(0.75)
	replay = ""
	await wait(0.6)
	tw = create_tween()
	tw.tween_property(self, "closeup", 0.0, 0.6)
	await tw.finished
	await mara("When did I—")
	await narrate("Tomas sees the tape and understands before she does. He doesn't let go of her hand.")
	await _letgo()


func _letgo() -> void:
	var g := GameState
	Audio.play_loop("static", -22.0, 2.0)
	var tw := create_tween()
	tw.tween_property(self, "white", 0.5, 2.0)
	shot = "white"
	await narrate("The white is at the end of the street. About ninety seconds.")
	var bless := "\"Go to the coast. Ask her.\"" if _taken() else "\"Paint the nursery. Something yellow.\""
	var pick: int = await hud.choose([bless, "\"Come with me. Right now.\""])
	if pick == 0:
		g.set_story("LETGO", "blessed")
		await mara(bless.trim_prefix("\"").trim_suffix("\""))
		await say("TOMAS", Story.signoff_reply(1))
	else:
		g.set_story("LETGO", "asked")
		await mara("Come with me. Right now.")
		if _taken():
			await say("TOMAS", "You did that once already. Let me keep it.")
		else:
			await say("TOMAS", "You told me to go home once. I went.")
		await narrate("He holds her hand until the white.")
	g.set_flag("letgo_done")
	tw = create_tween()
	tw.tween_property(self, "white", 1.0, 1.6)
	await narrate("The white takes the street. Then the shop.")
	Audio.stop_all(0.3)
	Audio.sfx("silence_hit", -3.0)
	await hud.whiteout(1.6)
	# ...and cuts to black. The black doesn't end.
	hud.fade_rect.color = Color(0, 0, 0, 1)
	await wait(1.8)
	Act3.become_red()
	main.change_room("red_dark", "start")


# --- drawing --------------------------------------------------------------------------------

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
	_tape_wall()
	if not _taken():
		_nursery_things()


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


func _tape_wall() -> void:
	var cols := [Color("2f63c9"), Color("b8322c"), Color("8a8e92"), Color("3a8a4a"), Color("e0c040"), Color("e8e8e0"),
		Color("1a1a1c"), Color("c86a2a"), Color("7a4a9a"), Color("5ab0c8")]
	for i in 81:
		var row := i / 10
		var c := i % 10
		var p := Vector2(904 + c * 24, 168 + row * 30)
		if i == 80:
			p = Vector2(904 + 10 * 24, 168)
			cv.draw_rect(Rect2(p, Vector2(18, 7)), Color("f2efe6"))
			Kit.text(cv, p + Vector2(4, 20), "?", 11, Color("2a2a2a"))
			continue
		cv.draw_rect(Rect2(p, Vector2(18, 7)), cols[int(Townscape.h(i * 13) * 10.0) % 10])
		cv.draw_line(p + Vector2(2, 14), p + Vector2(16, 14), Color(0.15, 0.15, 0.15, 0.6), 1.0)


func _nursery_things() -> void:
	# A crib in a flat box against the wall; two cans of yellow paint on top; a roller.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1160, 650), Vector2(1258, 650), Vector2(1272, 440), Vector2(1186, 432)]), Color("c8b088"))
	Kit.text(cv, Vector2(1186, 540), "CRIB", 16, Color("5a4a30"))
	for k in 2:
		cv.draw_rect(Rect2(1170 + k * 34, 614, 28, 34), Color("e8e4dc"))
		cv.draw_rect(Rect2(1170 + k * 34, 622, 28, 12), Color("f0c830"))
	cv.draw_line(Vector2(1240, 648), Vector2(1240, 610), Color("6a6a6a"), 2.0)
	cv.draw_rect(Rect2(1230, 600, 24, 10), Color("f0c830"))


func draw_glow(ci: CanvasItem) -> void:
	if not GameState.has("roll_call"):
		Kit.soft_glow(ci, Vector2(975, 528), 40.0, Color(0.4, 1.0, 0.6, 0.18))
	if white > 0.0:
		var r := WIN
		ci.draw_rect(Rect2(r.end.x - r.size.x * white, r.position.y, r.size.x * white, r.size.y), Color(0.96, 0.97, 1.0, 0.95))
		Kit.soft_glow(ci, r.get_center(), 200.0 * white, Color(1, 1, 1, 0.35 * white))
	Act3.draw_wrist(ci, Color("2f63c9"), closeup)
	if replay != "":
		ci.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color(0.01, 0.01, 0.02, 0.9))
		var a := 0.8 + 0.2 * sin(t * 40.0)
		Kit.text(ci, Vector2(0, 380), replay, 44, Color(0.93, 0.92, 0.88, a), HORIZONTAL_ALIGNMENT_CENTER, 1280)
