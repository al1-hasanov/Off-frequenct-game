extends StationRoom
## Prologue P2–P3 and Act 1.1 — the receiver room.
## The fuse puzzle, the 2:14 transmission, and Choice 1: answer the voice,
## or cut the power.

var snow: Snowfall
var _knock_t := 3.0
var _scratching := false


func setup() -> void:
	place_name = "Receiver room"
	walk_min = 90.0
	walk_max = 1120.0
	make_player(300.0, 1)
	snow = Snowfall.new()
	snow.area = Rect2(762, 204, 336, 192)
	snow.count = 55
	snow.wind = 20.0
	snow.speed = 40.0
	add_child(snow)

	add_hotspot("door", Rect2(22, 330, 108, 320), "Corridor", 95.0, -1)
	add_hotspot("cabinet", Rect2(164, 344, 104, 114), "Spares cabinet", 215.0)
	add_hotspot("rack1", Rect2(300, 300, 120, 340), "Receiver 1", 360.0)
	add_hotspot("receiver2", Rect2(440, 300, 120, 340), "Receiver 2", 500.0)
	add_hotspot("fuse_slot", Rect2(468, 546, 64, 50), "Fuse holder", 500.0)
	add_hotspot("rack3", Rect2(580, 300, 120, 340), "Receiver 3", 640.0)
	add_hotspot("chart", Rect2(756, 466, 152, 84), "Chart recorder", 830.0)
	add_hotspot("headphones", Rect2(914, 432, 62, 80), "Headphones", 940.0)
	add_hotspot("mic", Rect2(988, 452, 84, 98), "Talkback mic", 1020.0)
	add_hotspot("window", Rect2(760, 200, 340, 200), "Window")
	add_hotspot("breaker", Rect2(1144, 334, 102, 152), "Main breaker", 1120.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	if entry == "from_corridor":
		player.position.x = 112.0
		player.face(1)
	_scratching = GameState.has("fuse_installed") and not GameState.has("heard_transmission")


func on_arrive() -> void:
	ambience()
	if _scratching:
		Audio.play_loop("scratch", -12.0)
	if _choice_pending():
		Audio.play_loop("static", -22.0)


func _process(delta: float) -> void:
	super(delta)
	if _choice_pending():
		_knock_t -= delta
		if _knock_t <= 0.0:
			_knock_t = 7.0
			var tw := create_tween()
			for i in 3:
				tw.tween_callback(Audio.sfx.bind("knock", -9.0, 1.0))
				tw.tween_interval(0.85)


func _choice_pending() -> bool:
	return GameState.has("heard_transmission") and not GameState.has("choice1")


func on_hotspot(id: String) -> void:
	match id:
		"door":
			Audio.stop_loop("scratch", 0.3)
			Audio.sfx("door", -10.0)
			main.change_room("corridor", "from_receiver")
		"cabinet":
			Audio.sfx("click", -6.0)
			GameState.set_flag("cabinet_open")
			if GameState.has("cabinet_empty"):
				await mara("Still empty.")
			else:
				GameState.set_flag("cabinet_empty")
				await mara("Spares cabinet. Empty. Of course it's empty.")
				if not GameState.has("fuse_taken"):
					await mara("Where else in this building is there a 5-amp fuse...")
					await mara("Something small. Something that's always on and nobody needs. Like that vending machine's light.")
					GameState.set_objective("Borrow a 5-amp fuse from something nobody needs. The vending machine?")
		"rack1":
			await mara("Receiver 1. Sollen's pride and joy. Don't touch the dials.")
		"rack3":
			await mara("Receiver 3. 'Temporarily' out of service since 1979.")
		"receiver2", "fuse_slot":
			if GameState.has("fuse_installed"):
				await mara("Receiver 2. Humming like nothing's wrong.")
			else:
				await mara("Receiver 2. Dead. The fuse holder's empty, and the old fuse is black inside.")
		"chart":
			await _chart()
		"headphones":
			if GameState.has("heard_transmission"):
				await mara("I'm not putting those on again.")
			elif GameState.has("chart_checked"):
				await _transmission()
			else:
				await mara("Headphones. For when the static gets lonely.")
		"mic":
			if _choice_pending():
				await _answer()
			elif GameState.has("choice1"):
				await mara("Nothing on it now but hiss.")
			else:
				await mara("The talkback mic. We're a listening station. Nobody ever talks back.")
		"breaker":
			if _choice_pending():
				await _cut()
			elif GameState.emergency:
				await mara("Off. It stays off.")
			else:
				await mara("Main breaker. Pull that and the whole building goes dark.")
		"window":
			if GameState.has("heard_transmission"):
				await mara("The snow hung in the air. Just for a second. I saw it.")
			else:
				await mara("Snow. The dish is a ghost out there.")


func use_item(id: String, item: String) -> bool:
	if item == "fuse" and (id == "fuse_slot" or id == "receiver2"):
		await _install_fuse()
		return true
	if item == "red_tape" and (id == "fuse_slot" or id == "receiver2"):
		await mara("Tape fixes a lot of things. Not a blown fuse.")
		return true
	return false


func _install_fuse() -> void:
	GameState.remove_item("fuse")
	GameState.set_flag("fuse_installed")
	Audio.sfx("click", -4.0)
	await wait(0.3)
	Audio.sfx("powerup", -6.0)
	await wait(0.6)
	await mara("There. Back in business.")
	GameState.set_clock("2:13")
	GameState.set_objective("")
	await wait(1.0)
	_scratching = true
	Audio.play_loop("scratch", -12.0)
	await wait(0.8)
	# Two relay clicks behind the panel, the second slower: the same two the
	# recording carries (and the 2031 museum, and Act 4).
	Audio.sfx("click", -13.0)
	await wait(0.3)
	Audio.sfx("click", -13.0, 0.78)
	await wait(0.5)
	await narrate("Behind the panel, two relay clicks. The second is slower. The chart recorder's pen starts to move on its own.")
	await mara("...That's not me.")
	GameState.set_objective("Check the chart recorder.")


func _chart() -> void:
	if not GameState.has("fuse_installed"):
		await mara("Chart recorder. Flat line. Like my social life.")
	elif GameState.has("heard_transmission"):
		await mara("The pen stopped dead. Mid-stroke.")
	elif GameState.has("chart_checked"):
		await mara("Still scratching. 2.14 megahertz.")
	else:
		GameState.set_flag("chart_checked")
		await mara("It's writing by itself.")
		await mara("2.14 megahertz. We don't have a transmission scheduled there.")
		await mara("Somebody's on it.")
		GameState.set_objective("Listen on the headphones.")


## Prologue P3: the transmission, the knock, and every clock stopping at 2:14.
func _transmission() -> void:
	player.headphones = true
	Audio.sfx("click", -8.0)
	Audio.stop_loop("radio_music", 0.4)
	Audio.play_loop("static", -7.0, 0.3)
	# Every clock in the building reads 2:14.
	GameState.set_clock("2:14", true)
	snow.frozen = 1.0
	await wait(1.0)
	await say("VOICE", "Don't let her in. Whatever happens, don't open the door—")
	# Its signature, in the same places every time: a chair foot, two relay
	# clicks, a clipped breath.
	Audio.sfx("scrape", -17.0)
	await wait(0.55)
	Audio.sfx("click", -13.0)
	await wait(0.28)
	Audio.sfx("click", -13.0, 0.78)
	await wait(0.45)
	Audio.sfx("breath", -15.0, 1.1)
	await wait(0.7)
	for i in 2:
		Audio.sfx("knock", -16.0)
		await wait(0.9)
	await narrate("Under the voice: a chair foot dragging, two relay clicks, then a clipped breath. Knocking, far off, on the front door.")
	GameState.set_flag("heard_signature")
	Audio.stop_loop("static", 0.02)
	Audio.stop_loop("scratch", 0.02)
	Audio.stop_loop("hum", 0.02)
	_scratching = false
	Audio.sfx("click", -4.0)
	GameState.set_flag("radio_on", false)
	await wait(1.0)
	for i in 3:
		Audio.sfx("knock", -8.0)
		await wait(0.9)
	await wait(0.4)
	player.headphones = false
	Audio.play_loop("hum", -24.0, 1.5)
	await mara("...Somebody's knocking on the front door.")
	await mara("At two in the morning. Up a mountain.")
	Audio.sfx("scrape", -24.0)
	await narrate("In the headphones the voice starts again, looping. The same scrape, the same clicks, the same breath, in exactly the same places. The knocking doesn't stop.")
	GameState.set_flag("heard_transmission")
	_knock_t = 5.0
	Audio.play_loop("static", -22.0)
	GameState.set_objective("Answer the voice at the mic, or cut the power at the breaker.")


## Choice 1, option A: answer the voice (ANSWERED = yes).
func _answer() -> void:
	player.headphones = true
	Audio.sfx("click", -6.0)
	Audio.play_loop("static", -10.0, 0.2)
	await narrate("She keys the microphone. The repeated warning stops in the middle of a breath. The woman who answers is breathing differently.")
	await mara("Who is this?")
	await say("VOICE", "Oh God. Which one are you?")
	await say("VOICE", "Prove it. What did you say to Tomas? Last thing, every night.")
	await mara("...\"%s\"" % Story.signoff_line())
	GameState.set_flag("voice_tested")
	await say("VOICE", "Okay. Okay, it's you.")
	await say("VOICE", "Listen. Tomas's radio. The box in the basement. The key's on Sollen's ring.")
	await say("VOICE", "Get it before she does. She'll say she's—")
	Audio.sfx("crack", -2.0)
	Audio.stop_loop("static", 0.05)
	await wait(1.3)
	player.headphones = false
	await mara("Hello? ...Hello?")
	await mara("...The knocking's stopped.")
	# Each clear burst of speech sits over a narrow rise in the trace (3.5).
	await narrate("The recorder has caught both voices. On its paper, the trace takes a small step up under each burst of speech, and does not come back down. Mara tears off the strip and folds it into her work notebook without knowing why.")
	GameState.set_flag("strip_1983")
	GameState.set_story("ANSWERED", true)
	GameState.set_flag("choice1")
	GameState.set_objective("Check the control room.")


## Choice 1, option B: cut the power (ANSWERED = no).
func _cut() -> void:
	Audio.sfx("breaker", -2.0)
	GameState.emergency = true
	Audio.stop_loop("hum", 0.05)
	Audio.stop_loop("static", 0.05)
	await wait(1.4)
	await mara("Emergency lights. Good.")
	await mara("...And the knocking's stopped.")
	GameState.set_story("ANSWERED", false)
	GameState.set_flag("choice1")
	GameState.set_objective("Check the front door. Then the control room.")


func draw_back() -> void:
	draw_shell([330.0, 930.0])
	Kit.door(cv, Rect2(30, 340, 92, 310), DOOR, "CORRIDOR")
	_cabinet()
	_rack(300.0, "RX-1", true)
	_rack(440.0, "RX-2", GameState.has("fuse_installed"))
	_rack(580.0, "RX-3", false)
	Kit.night_view(cv, Rect2(762, 204, 336, 192), 0.0, 960.0, 0.62)
	_desk()
	_breaker()


func draw_fore(ci: CanvasItem) -> void:
	Kit.window_frame(ci, Rect2(762, 204, 336, 192), 2)
	if _choice_pending():
		var a := 0.45 + 0.4 * sin(t * 4.0)
		ci.draw_arc(Vector2(1030, 500), 44.0, 0.0, TAU, 40, Color(0.62, 0.83, 0.9, a), 3.0)
		ci.draw_arc(Vector2(1195, 410), 58.0, 0.0, TAU, 40, Color(1.0, 0.5, 0.4, a), 3.0)


## Receiver 1 and 2's activity lamps blink, and the chart pen scratches.
func draw_anim(ci: CanvasItem) -> void:
	super(ci)
	for rx in [[300.0, true], [440.0, GameState.has("fuse_installed")]]:
		if rx[1]:
			var x: float = rx[0]
			ci.draw_circle(Vector2(x + 104, 398), 3.0, Color("e8a54b") if sin(t * 6.0 + x) > 0.0 else Color("6b4a1c"))
	var paper := Rect2(768, 480, 128, 44)
	var pts := PackedVector2Array()
	for i in 33:
		var y := paper.get_center().y
		if _scratching:
			y += sin(i * 1.7 + t * 18.0) * 12.0 + sin(i * 0.6 - t * 7.0) * 6.0
		elif GameState.has("fuse_installed") and not GameState.has("heard_transmission"):
			y += sin(i * 0.4 + t * 2.0) * 2.0
		pts.append(Vector2(paper.position.x + i * 4.0, y))
	ci.draw_polyline(pts, Color("b8322c"), 1.6)


## The headphones on their hook come and go with Mara.
func static_key() -> String:
	return str(player != null and player.headphones)


func _cabinet() -> void:
	var r := Rect2(168, 348, 96, 106)
	cv.draw_rect(r, Color("56626c"))
	cv.draw_rect(r, Color("2c353c"), false, 2.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 24), "SPARES", 13, Color("1c2226"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if GameState.has("cabinet_open"):
		cv.draw_rect(r.grow(-6), Color("171c20"))
		cv.draw_line(Vector2(176, 386), Vector2(256, 386), Color("3a444b"), 3.0)
		cv.draw_line(Vector2(176, 420), Vector2(256, 420), Color("3a444b"), 3.0)
		cv.draw_colored_polygon(PackedVector2Array([Vector2(168, 348), Vector2(140, 336), Vector2(140, 466), Vector2(168, 454)]), Color("4b5760"))


func _rack(x: float, label: String, on: bool) -> void:
	var r := Rect2(x, 300, 120, 340)
	cv.draw_rect(r, Color("232a31"))
	cv.draw_rect(r, Color("12171b"), false, 3.0)
	Kit.text(cv, Vector2(x, 324), label, 15, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, 120)
	for row in 4:
		var y := 340.0 + row * 50.0
		cv.draw_rect(Rect2(x + 10, y, 100, 40), Color("2c343c"))
		for k in 3:
			cv.draw_circle(Vector2(x + 28 + k * 30, y + 20), 8.0, Color("15191d"))
			cv.draw_line(Vector2(x + 28 + k * 30, y + 20), Vector2(x + 28 + k * 30 + 5, y + 14), Color("9aa3a8"), 2.0)
		if not (on and row == 1):  # that one blinks: draw_anim()
			cv.draw_circle(Vector2(x + 104, y + 8), 3.0, Color("49d17a") if on else Color("1b2a20"))
	if label == "RX-2":
		cv.draw_rect(Rect2(472, 552, 56, 38), Color("15191d"))
		cv.draw_rect(Rect2(484, 562, 32, 18), Color("cfd7d0") if on else Color("2a2f33"))
		Kit.text(cv, Vector2(472, 606), "FUSE 5A", 11, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, 56)


func _desk() -> void:
	cv.draw_rect(Rect2(732, 548, 380, 16), Color("4a3a2c"))
	cv.draw_rect(Rect2(744, 564, 10, 86), Color("3a2e24"))
	cv.draw_rect(Rect2(1090, 564, 10, 86), Color("3a2e24"))
	# Chart recorder with a paper strip and a pen trace.
	var cr := Rect2(758, 470, 148, 78)
	cv.draw_rect(cr, Color("2b3238"))
	cv.draw_rect(Rect2(768, 480, 128, 44), Color("e9e4d2"))
	Kit.text(cv, Vector2(768, 540), "2.14 MHz" if GameState.has("chart_checked") else "CHART", 12, Color("9aa3a0"))
	# Headphones on their hook.
	cv.draw_line(Vector2(944, 430), Vector2(944, 444), Color("6f777d"), 3.0)
	if not player.headphones:
		cv.draw_arc(Vector2(944, 470), 22.0, PI, TAU, 14, Color("1f2226"), 5.0)
		cv.draw_circle(Vector2(923, 478), 9.0, Color("2a2d33"))
		cv.draw_circle(Vector2(965, 478), 9.0, Color("2a2d33"))
	# Talkback mic with its red transmit key.
	cv.draw_rect(Rect2(1000, 530, 64, 18), Color("2b3238"))
	cv.draw_line(Vector2(1030, 530), Vector2(1030, 486), Color("7c858b"), 4.0)
	cv.draw_rect(Rect2(1018, 462, 24, 30), Color("3a4146"))
	cv.draw_rect(Rect2(1046, 534, 12, 10), Color("c0392b"))


func _breaker() -> void:
	var r := Rect2(1148, 338, 94, 144)
	cv.draw_rect(r, Color("596670"))
	cv.draw_rect(r, Color("2c353c"), false, 3.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 22), "MAIN", 14, Color("1c2226"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	cv.draw_rect(Rect2(1186, 370, 18, 96), Color("2a3036"))
	var lever_y := 448.0 if GameState.emergency else 386.0
	cv.draw_rect(Rect2(1176, lever_y - 8, 38, 16), Color("c0392b"))
