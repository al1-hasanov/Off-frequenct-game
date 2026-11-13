extends StationRoom
## Act 1.2 — the control room. After 2:14, Mara's own body is slumped against
## the console. Four things to inspect: the wrist, the watch, the pocket, and
## the transmitter's empty key slot.

const BODY_X := 700.0
const CHECKS := ["inspected_wrist", "inspected_watch", "inspected_pocket", "inspected_transmitter"]

var body: Actor
var snow: Snowfall
## Act 3.8: Eighty-One by the chalkboard, Sollen's revolver in her good hand
## and Red's Tuner on her strap.
var eighty: Actor
## Act 3.9: the white cresting the ridge in the window, Halvard's lights going out.
var white := 0.0
var lights_out := 0.0
var shot := ""

## The big window onto the dish, clear of the chalkboard and the transmitter.
const WIN := Rect2(330, 166, 686, 236)


func setup() -> void:
	place_name = "Control room"
	walk_min = 110.0
	walk_max = 1010.0
	snow = Snowfall.new()
	snow.area = WIN
	snow.count = 110
	snow.wind = 24.0
	add_child(snow)
	body = add_actor("body", BODY_X, 1)
	body.visible = _body_here()
	eighty = add_actor("eighty_one", 360.0, -1)
	eighty.prop = "revolver"
	eighty.carried_radio = Color("b8322c")
	eighty.visible = _e81_here()
	make_player(300.0, 1)

	var here := func() -> bool: return _body_here()
	add_hotspot("door", Rect2(22, 330, 108, 320), "Corridor", 95.0, -1)
	add_hotspot("chalkboard", Rect2(128, 222, 164, 258), "Chalkboard", 230.0)
	add_hotspot("old_chalk", Rect2(226, 282, 44, 44), "Old chalk", 230.0)
	add_hotspot("window", WIN.grow(12), "Window")
	add_hotspot("console", Rect2(300, 470, 700, 132), "Console", 470.0)
	add_hotspot("transmitter", Rect2(1044, 296, 152, 350), "Transmitter", 1010.0, 1)
	add_hotspot("body", Rect2(612, 520, 216, 136), "Her", 600.0, 1, here)
	add_hotspot("body_face", Rect2(646, 536, 52, 52), "Her face", 600.0, 1, here)
	add_hotspot("body_wrist", Rect2(618, 616, 58, 42), "Her wrist", 600.0, 1, here)
	add_hotspot("body_pocket", Rect2(676, 590, 36, 34), "Her jacket pocket", 600.0, 1, here)
	add_hotspot("body_watch", Rect2(712, 608, 48, 40), "Her watch", 600.0, 1, here)
	var a3 := func() -> bool: return GameState.has("act3")
	add_hotspot("patch_bay", Rect2(1056, 500, 128, 116), "Patch bay", 1010.0, 1, a3)
	add_hotspot("chart", Rect2(306, 412, 134, 64), "Chart recorder", 380.0, 0, a3)
	add_hotspot("drive", Rect2(920, 412, 84, 64), "Dish drive", 900.0, 0, a3)
	add_hotspot("eighty", Rect2(318, 440, 84, 210), "Eighty-One", 220.0, 1, func() -> bool: return eighty.visible)


func _body_here() -> bool:
	return GameState.has("heard_transmission")


func _e81_here() -> bool:
	return GameState.has("red_done") and not GameState.has("e81_done")


func static_key() -> String:
	var g := GameState
	return "%s|%s|%s|%s" % [Act3.board_lines().size(), g.has("dish_parked") and not g.has("dish_released"), g.has("bank_burst"), g.has("patched")]


func enter(entry: String) -> void:
	entered_from = entry
	if entry == "from_corridor":
		player.position.x = 112.0
		player.face(1)


func on_arrive() -> void:
	ambience()
	if _body_here() and not GameState.has("body_seen"):
		GameState.set_flag("body_seen")
		await player.walk_to(560.0)
		Audio.sfx("sting", -4.0)
		await wait(0.5)
		await mara("Oh—")
		await mara("No. No, no, no.")
		await wait(0.3)
		await mara("That's... that's me.")
		GameState.set_objective("Look at her closely: her wrist, her watch, her pocket. And the transmitter.")
	elif GameState.has("act3"):
		await _act3_arrive()


func on_hotspot(id: String) -> void:
	match id:
		"door":
			Audio.sfx("door", -10.0)
			main.change_room("corridor", "from_control")
		"chalkboard":
			if GameState.has("act3"):
				await _chalk()
			else:
				await mara("Sollen's survey schedule. Hydrogen line, every clear night until Christmas.")
				await mara("He always leaves that corner empty. Says it's for discoveries.")
				if not GameState.has("saw_chalk_lambda"):
					await _old_chalk()
		"old_chalk":
			await _old_chalk()
		"window":
			if GameState.has("dish_parked") and not GameState.has("dish_released"):
				await mara("The dish, parked straight up at the zenith. Not listening to anything.")
			elif GameState.has("act3"):
				await mara("The dish, swung round to the horizon. Listening on 2.14, all by itself.")
			else:
				await mara("The dish. Pointed at nothing, listening to everything.")
		"patch_bay":
			await _patch_bay()
		"chart":
			await _chart()
		"drive":
			await _drive()
		"eighty":
			await say("EIGHTY-ONE", "Not yet, love. Sit with it a minute.")
		"console":
			if _body_here():
				await mara("I can't look at the console. I can only look at her.")
			else:
				await mara("Sollen's console. Every knob labeled in his tiny capitals.")
		"transmitter":
			if GameState.has("key_taken"):
				await mara("TX-1. The key's in my pocket. I'm not putting it in. I don't know what I'd be sending.")
			elif _body_here():
				await mara("The transmit key's gone. The slot's empty. Sollen never lets it out of his sight.")
				await _check("inspected_transmitter")
			else:
				await mara("The transmitter. Only Sollen has the key, and he takes it home.")
		"body":
			await mara("I can't stop looking at her.")
		"body_face":
			await mara("Same face. Same jacket. Same scar on the chin from when I was nine.")
		"body_wrist":
			await mara("Blue electrical tape, wrapped around her wrist. Neat. The way I'd do it.")
			await mara("I don't own blue tape.")
			await _check("inspected_wrist")
		"body_watch":
			await mara("Her watch stopped at 2:14. Same as every clock in the building.")
			await _check("inspected_watch")
		"body_pocket":
			if GameState.has("inspected_pocket"):
				await mara("Keys. Gum. My gum.")
			else:
				await mara("There's something in her pocket.")
				GameState.add_item("note")
				hud.toast("Got: Folded note")
				await narrate("\"THE KNOCK IS HER. SHE'LL SAY SHE'S ME. 81.\"")
				await mara("That's my handwriting. I never wrote this.")
				await _check("inspected_pocket")


func use_item(id: String, item: String) -> bool:
	if item == "red_tape" and id.begins_with("body"):
		await mara("No. I'm not touching her.")
		return true
	if item == "note" and id == "transmitter":
		await mara("Whatever '81' means, it isn't a frequency on this dial.")
		return true
	if item == "chain_sheet" and id == "patch_bay":
		await _patch_bay()
		return true
	if item == "transmit_key" and id == "transmitter":
		await mara("Not yet. I don't know what I'd be sending. Or to whom.")
		return true
	if item == "tuner" and id == "patch_bay":
		await _patch_bay()
		return true
	return false


func _check(flag: String) -> void:
	GameState.set_flag(flag)
	if GameState.has("body_done"):
		return
	for f in CHECKS:
		if not GameState.has(f):
			return
	GameState.set_flag("body_done")
	await wait(0.4)
	await mara("Okay. Okay. You're having a stroke, Mara. That's all this is.")
	await mara("A very detailed stroke.")
	await mara("I need to call someone. The phone's in the lobby.")
	GameState.set_objective("Call for help from the phone in the lobby.")


func draw_back() -> void:
	draw_shell([420.0, 920.0])
	Kit.door(cv, Rect2(30, 340, 92, 310), DOOR, "CORRIDOR")
	_chalkboard()
	Kit.night_view(cv, WIN, 0.0, -1.0, 1.25)
	_window_dish()
	_console()
	_transmitter()
	if GameState.has("act3"):
		_patch_bay_art()
		_chart_art()
		_drive_art()


## The console's traces and the transmitter's needles move.
func draw_anim(ci: CanvasItem) -> void:
	super(ci)
	var top := 470.0
	for i in 3:
		var scr := Rect2(330.0 + i * 230.0, top + 34, 120, 62)
		var pts := PackedVector2Array()
		for k in 31:
			var amp := 0.0 if GameState.emergency else 16.0
			pts.append(Vector2(scr.position.x + k * 4.0, scr.get_center().y + sin(k * 0.5 + t * (2.0 + i)) * amp * (0.4 + 0.2 * i)))
		ci.draw_polyline(pts, Color(0.3, 1.0, 0.55, 0.85), 1.5)
	for i in 2:
		var m := Rect2(1064 + i * 62, 344, 50, 40)
		var a := -2.4 + 0.3 * sin(t * 0.7 + i)
		ci.draw_line(m.get_center() + Vector2(0, 14), m.get_center() + Vector2(0, 14) + Vector2(cos(a), sin(a)) * 22.0, Color("1c1c1c"), 1.5)
	if GameState.has("act3"):
		_chart_pen(ci)
		_window_valley(ci)


## The pen on the chart: flat while the dish is parked, climbing while it listens.
func _chart_pen(ci: CanvasItem) -> void:
	var r := Rect2(320, 426, 80, 38)
	var parked := GameState.has("dish_parked") and not GameState.has("dish_released")
	var pts := PackedVector2Array()
	for k in 21:
		var x := r.position.x + k * 4.0
		var y := r.end.y - 8.0 + sin(k * 1.7 + t * 6.0) * 0.8
		if not parked:
			y = r.end.y - 6.0 - (k / 20.0) * 26.0 + sin(k * 2.3 + t * 9.0) * 1.6
		pts.append(Vector2(x, y))
	ci.draw_polyline(pts, Color("b8322c"), 1.5)


## Halvard's lights across the valley, through the window; in 3.9 they go out
## a street at a time, and the white comes over the ridge.
func _window_valley(ci: CanvasItem) -> void:
	var r := WIN
	var horizon := r.position.y + r.size.y * 0.72
	for i in 30:
		if float(i) / 30.0 < lights_out:
			continue
		var x := r.position.x + 14.0 + Townscape.h(i * 7) * (r.size.x - 28.0)
		ci.draw_rect(Rect2(x, horizon + 4.0 + Townscape.h(i * 3) * 10.0, 3, 2), Color(1.0, 0.8, 0.45, 0.85))
	if white > 0.0:
		var top := horizon - 20.0 - white * 70.0
		var pts := PackedVector2Array([Vector2(r.position.x, horizon)])
		for i in 15:
			pts.append(Vector2(r.position.x + i * r.size.x / 14.0, top + 12.0 * sin(i * 1.7 + t * 0.6)))
		pts.append(Vector2(r.end.x, horizon))
		ci.draw_colored_polygon(pts, Color(0.93, 0.95, 1.0, 0.9 * white))


## The frame goes over the snow falling past the glass (the window is above
## head height, so it never crosses a character).
func draw_fore(ci: CanvasItem) -> void:
	Kit.window_frame(ci, WIN, 3)


func _chalkboard() -> void:
	var r := Rect2(132, 226, 156, 250)
	cv.draw_rect(r.grow(6), Color("5a4532"))
	cv.draw_rect(r, Color("1c2a24"))
	_old_chalk_art()
	var chalk := Color(0.9, 0.92, 0.88, 0.75)
	Kit.text(cv, Vector2(142, 252), "H-LINE SURVEY", 14, chalk)
	Kit.text(cv, Vector2(142, 280), "NOV  2 · 9 · 16", 13, chalk)
	Kit.text(cv, Vector2(142, 304), "NOV 23 · 30", 13, chalk)
	Kit.text(cv, Vector2(142, 328), "DEC  7 · 14 · 21", 13, chalk)
	Kit.text(cv, Vector2(142, 352), "1420.4 MHz", 13, chalk)
	Kit.text(cv, Vector2(142, 376), "2.14 RUN · OCT 25", 12, chalk)
	# The corner Sollen keeps empty for discoveries.
	var lines := Act3.board_lines()
	var mine := Color(0.95, 0.96, 0.92, 0.9)
	for i in lines.size():
		var y := 410.0 + i * 17.0
		Kit.text(cv, Vector2(150, y), lines[i], 13 if lines[i] != "TONIGHT" else 15, mine)
		if lines[i] == "TONIGHT":
			cv.draw_line(Vector2(150, y + 3), Vector2(222, y + 4), mine, 2.0)
	# Old sums rubbed out with the heel of a hand.
	for k in 3:
		cv.draw_line(Vector2(206 + k * 9, 270), Vector2(250 + k * 9, 236), Color(0.9, 0.92, 0.88, 0.06), 7.0)


## Under the schedule, the ghost of something older: a lambda, circled, pressed
## in so hard four years of erasing never got it off, and the tail of an
## equation (Dad's, from the 2.14 study).
func _old_chalk_art() -> void:
	var ghost := Color(0.9, 0.92, 0.88, 0.13)
	Kit.text(cv, Vector2(232, 318), "Λ", 34, ghost)
	cv.draw_arc(Vector2(248, 305), 22.0, 0.0, TAU, 28, ghost, 2.0)
	Kit.field_equation(cv, Vector2(146, 394), 11, Color(0.9, 0.92, 0.88, 0.08))


func _console() -> void:
	var top := 470.0
	cv.draw_colored_polygon(PackedVector2Array([Vector2(296, top + 18), Vector2(1004, top + 18), Vector2(990, top), Vector2(310, top)]), Color("3a444b"))
	cv.draw_rect(Rect2(296, top + 18, 708, 162), Color("2a3238"))
	cv.draw_rect(Rect2(296, top + 18, 708, 162), Color("161b1f"), false, 3.0)
	for i in 3:
		var sx := 330.0 + i * 230.0
		var scr := Rect2(sx, top + 34, 120, 62)
		cv.draw_rect(scr, Color("06120c"))
		for k in 4:
			cv.draw_circle(Vector2(sx + 140 + (k % 2) * 30, top + 46 + (k / 2) * 30), 9.0, Color("15191d"))


func _transmitter() -> void:
	var r := Rect2(1048, 300, 144, 342)
	cv.draw_rect(r, Color("2b3339"))
	cv.draw_rect(r, Color("12171b"), false, 3.0)
	Kit.text(cv, Vector2(r.position.x, 326), "TX-1", 16, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for i in 2:
		var m := Rect2(1064 + i * 62, 344, 50, 40)
		cv.draw_rect(m, Color("e8e2cc"))
	cv.draw_rect(Rect2(1094, 428, 52, 30), Color("15191d"))
	cv.draw_rect(Rect2(1110, 438, 20, 8), Color("050607"))
	Kit.text(cv, Vector2(1080, 476), "TRANSMIT KEY", 11, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, 80)


# --- Act 3 ---------------------------------------------------------------------------------

func _act3_arrive() -> void:
	var g := GameState
	if not g.has("cr3_seen"):
		g.set_flag("cr3_seen")
		await wait(0.3)
		await mara("Two-fourteen. She's still here, against the console.")
		await mara("Out there the dish has swung round to face the horizon. Sollen parks it straight up every night.")
		await mara("And the chart recorder's pen is creeping up the paper. Nobody's touching it.")
		await mara("Whatever the dish is listening to, Tomas's dial can't find it. It runs out at ninety-nine.")
	elif _e81_here():
		await _eighty_one()
		return
	elif g.has("chalk_2031") and g.has("key_taken") and not g.has("board_2009"):
		g.set_flag("board_2009")
		await wait(0.4)
		await mara("The board.")
		await mara("Under my SILENCE: 2031, somebody's written 2009. In my handwriting.")
		await mara("I didn't write that. I haven't been there yet.")
	objective()


## 3.1: Dad's 2.14 chain. Three cables, six jacks: the Tuner into receiver 2.
func _patch_bay() -> void:
	var g := GameState
	if g.has("bank_burst"):
		await mara("The forward bank's black and split. The fourth digit's dark. No more futures.")
		return
	if g.has("patched"):
		await mara("Dad's chain. Three cables, six jacks. Still holding.")
		return
	if not g.has("chain_known"):
		g.set_flag("patch_tried")
		await mara("The patch bay. To get Tomas's radio into receiver 2 I'd need the routing. Three cables, six jacks, and a hundred wrong ways.")
		await mara("Sollen writes everything down. The station log, in his office.")
		objective()
		return
	await mara("Dad's diagram. Three cables, six jacks.")
	var cables := [["DISH LO-FEED", 0], ["Rx-2 IF OUT", 1], ["FIELD SET OUT", 2]]
	for c in cables:
		while true:
			await narrate("%s goes to..." % c[0])
			var pick: int = await hud.choose(["Jack A1", "Jack B3", "Jack C2"])
			if pick == int(c[1]):
				Audio.sfx("plug", -6.0)
				break
			Audio.sfx("static", -14.0)
			await mara("No. That's not what he drew.")
	g.set_flag("patched")
	await wait(0.4)
	Audio.sfx("click", -2.0)
	await narrate("Inside Tomas's radio, a relay he never used clicks shut. Dad's modification.")
	await mara("The display's got a fourth digit. The needle's swinging past ninety-nine on its own.")
	await mara("Tomas didn't build this. He finished it.")
	await narrate("The needle settles: 2031.")
	await say("JUNE (TUNER)", "Whatever you're doing up there, honey, don't do it twice.")
	await mara("The loudest future it can hear. And the darkest place on the mountain is the feed cabin. Up on the dish.")
	objective()


## 3.3: Mara writes the year she saw in Sollen's empty corner.
func _chalk() -> void:
	var g := GameState
	if g.has("been_2031") and not g.has("chalk_2031"):
		Audio.sfx("chalk", -6.0)
		await narrate("In the corner Sollen keeps empty for discoveries, she chalks: SILENCE: 2031.")
		g.set_flag("chalk_2031")
		g.set_flag("saw_oct25")
		await mara("Beside his schedule. Its last line: 2.14 RUN, OCT 25.")
		await mara("Now. Sollen's desk. The hollow left rear leg.")
		objective()
		return
	var lines := Act3.board_lines()
	g.set_flag("saw_oct25")
	if lines.is_empty():
		await mara("Sollen's survey schedule. And at the bottom: 2.14 RUN, OCT 25. His next run on the frequency.")
		await mara("He always leaves that corner empty. Says it's for discoveries.")
		if not g.has("saw_chalk_lambda"):
			await _old_chalk()
	elif lines.has("TONIGHT"):
		await mara("SILENCE: 2031. 2009. 1991. TONIGHT. Every line in my handwriting.")
	else:
		await mara("%s. In my handwriting. I wrote one of them." % ", ".join(lines))


## The lambda nobody could rub off Sollen's board.
func _old_chalk() -> void:
	var g := GameState
	if g.has("dad_notes_read"):
		await mara("Dad's Λ. And under the schedule, so faint you have to tilt your head: the tail of Einstein's equation.")
		await mara("He stood here and worked on LAMBDA while Sollen counted hydrogen.")
	elif g.has("saw_chalk_lambda"):
		await mara("The Λ that won't rub off. Dad's lambda.")
	else:
		await mara("Under the rubbing-out, something older. A big Λ, circled, pressed in so hard it scored the board.")
		await mara("Lambda. Dad made his A's like that. On birthday cards. On the shopping list.")
	g.set_flag("saw_chalk_lambda")


## 3.5, Days 17 and 18 again: the chart recorder.
func _chart() -> void:
	var g := GameState
	if not g.has("notebook_read"):
		await mara("The chart recorder. Signal on 2.14, in red ink. The pen's climbing, and nobody's touching it.")
		return
	if g.has("experiment_done"):
		await mara("Still climbing.")
		return
	if not g.has("dish_parked"):
		await mara("Days 17 and 18. First, park the dish. The drive panel, on the right of the console.")
		return
	if not g.has("crossed_parked"):
		await mara("Flat, with the dish parked. Now cross: twice, through the dark east wing and back.")
		return
	if not g.has("strip_flat"):
		Audio.sfx("tape_rip", -8.0)
		await narrate("She tears off the strip. Two crossings, and the line is flat.")
		g.set_flag("strip_flat")
		await mara("Flat. Like his Day 17. Now let the dish go.")
		objective()
		return
	if not g.has("dish_released"):
		await mara("Release the dish first. Day 18.")
		return
	Audio.sfx("tape_rip", -8.0)
	await narrate("She tears off the second strip. She hasn't crossed once, and the line climbs.")
	g.add_item("chart_strips")
	g.set_flag("experiment_done")
	hud.toast("Got: Chart strips  ·  a new theory in the notebook")
	await mara("They match his. Flat with the dish parked. Climbing while it listens.")
	await mara("It isn't the crossings. It's the dish, listening.")
	player.face(-1)
	await mara("Every trip I took rode the dish. I've been pulling it in myself.")
	await _park_for_good()


## The dish won't stay parked, and the needle has found 1991.
func _park_for_good() -> void:
	var g := GameState
	await mara("Then it's parked. For good.")
	Audio.sfx("click", -6.0)
	Audio.stop_loop("dish_motor", 0.4)
	await narrate("PARK. The dish swings up to the zenith, and stops.")
	await wait(1.4)
	Audio.play_loop("dish_motor", -18.0)
	await narrate("Within a minute its drive engages on its own, and the dish swings back to the horizon.")
	await mara("It won't stay parked.")
	Audio.play_loop("static", -18.0, 0.4)
	await narrate("On Tomas's dial the needle has already settled: 1991. And through the hiss on receiver 2, a man is calling.")
	await say("TOMAS (RECEIVER)", "Mara? It's two-fourteen. I'm still here. I'll keep calling.")
	Audio.stop_loop("static", 0.8)
	await mara("Tomas. All grown up.")
	await mara("One more. Then I park it for good.")
	g.set_flag("call_1991")
	await wait(0.5)
	g.set_flag("board_1991")
	await mara("And on the board, under 2009, in my handwriting: 1991.")
	objective()


## 3.5: the dish drive, PARK and RELEASE.
func _drive() -> void:
	var g := GameState
	if not g.has("notebook_read"):
		await mara("The dish drive. PARK, RELEASE, and two readouts. Sollen's the only one who touches it.")
		await mara("Nobody's touched it tonight. The dish turned anyway.")
		return
	if not g.has("dish_parked"):
		Audio.stop_loop("dish_motor", 0.5)
		Audio.sfx("click", -6.0)
		g.set_flag("dish_parked")
		await narrate("PARK. Out of the window the dish swings up to the zenith, and stops.")
		await mara("Day 17: dish parked. Now cross, twice, through the dark east wing and back.")
		objective()
		return
	if not g.has("strip_flat"):
		await mara("Not yet. Cross twice with it parked, then tear off the strip.")
		return
	if not g.has("dish_released"):
		Audio.sfx("click", -6.0)
		Audio.play_loop("dish_motor", -18.0)
		g.set_flag("dish_released")
		await narrate("RELEASE. The dish swings back down to the horizon by itself, and points at 2.14.")
		await mara("Day 18. Don't cross. Stand still, in the light, and watch the pen.")
		await wait(1.6)
		await mara("It's climbing.")
		objective()
		return
	await mara("Released. Listening. It does that whether I like it or not.")


## 3.8, Choice 3: Eighty-One, the revolver, and Red still calling.
func _eighty_one() -> void:
	var g := GameState
	g.set_flag("board_tonight")
	await wait(0.4)
	Audio.play_loop("static", -24.0, 0.4)
	await mara("The board. Under 1991, in my handwriting: TONIGHT.")
	await narrate("Eighty-One stands beside it with chalk on her gauze. Sollen's old service revolver in her good hand, and a second Tuner on her strap, red tape round the handle.")
	await say("RED (RECEIVER)", "...anyone on two-fourteen... somebody in my house...")
	await say("EIGHTY-ONE", "Somebody had to tell you the order. I've watched it nineteen times.")
	await mara("Blue. Zero-seven. Doesn't know.")
	await say("EIGHTY-ONE", "You know now. I'm sorry it was him who told you.")
	await mara("Eighty of me.")
	await say("EIGHTY-ONE", "Every one of them would have done the same, if they'd seen what I've seen.")
	await say("EIGHTY-ONE", "Station twenty-three. My home. I brought him back from twelve, the way you might have.")
	await say("EIGHTY-ONE", "At two-fourteen there were two of us at the dish, and the white was on the ridge. She had the mic. I pulled her off it, and Sollen's revolver went off between us.")
	await say("EIGHTY-ONE", "And the white went back over the ridge. I watched it go.")
	await say("EIGHTY-ONE", "Eleven days. On the twenty-fifth it came back and took twenty-three, with him in it. I was down in the dark, or it would have had me too.")
	await say("EIGHTY-ONE", "Every station I've seen go quiet had one too many of somebody.")
	await say("EIGHTY-ONE", "One Mara, one world. Red stays in the dark. You keep the dish quiet at two-fourteen, I walk into the dark when it's done, and the loop closes.")
	g.set_flag("e81_told")
	await say("RED (RECEIVER)", "...somebody in my house...")
	await say("EIGHTY-ONE", "There she is. Every night she calls, and every night some boy answers.")
	await say("EIGHTY-ONE", "Pull the two-fourteen cable, love. She stops calling, and he stays home.")
	var pick: int = await hud.choose(["Pull the cable", "Refuse"])
	if pick == 0:
		await _follow()
	else:
		await say("EIGHTY-ONE", "Then I will.")
		await narrate("She raises the revolver at the receiver. Her hand shakes. She's never shot a Mara who was looking at her.")
		var how: int = await hud.choose(["Show her the notebook", "Grab the revolver"])
		if how == 0:
			await _expose()
		else:
			await _force()
	g.set_flag("e81_done")
	await _three_knocks()


func _follow() -> void:
	var g := GameState
	g.set_story("EIGHTY", "follow")
	Audio.sfx("plug", -4.0)
	await narrate("Mara pulls the two-fourteen cable.")
	Audio.stop_loop("static", 0.1)
	await say("RED (RECEIVER)", "...somebody in my h—")
	await narrate("The chart pen dips. Then it goes on climbing. TONIGHT stays on the board.")
	await say("EIGHTY-ONE", "Here.")
	await narrate("She turns the revolver round and hands it over, handle first.")
	await say("EIGHTY-ONE", "In case I lose my nerve.")
	eighty.prop = "none"
	g.add_item("revolver")
	hud.toast("Got: Sollen's revolver")
	await eighty.walk_to(620.0)
	eighty.seated = true
	await narrate("She sits down by the body to wait.")


func _expose() -> void:
	var g := GameState
	g.set_story("EIGHTY", "expose")
	await player.walk_to(470.0)
	player.face(-1)
	await narrate("Mara steps between the revolver and the receiver. She opens Tomas's notebook on the console and lays her two chart strips beside his.")
	await mara("Flat with the dish parked. Climbing while it listens. And the board: 2.14 RUN, OCT 25.")
	await mara("It's not us. It's the listening. You read this tonight, and you walled it up.")
	await say("EIGHTY-ONE", "...Then what was it all for?")
	await narrate("She lowers the revolver, and walks out into the dark corridor with it, and with Red's Tuner.")
	await eighty.walk_to(40.0)
	eighty.visible = false
	Audio.sfx("door", -12.0)
	await say("RED (RECEIVER)", "...anyone on two-fourteen...")


func _force() -> void:
	var g := GameState
	g.set_story("EIGHTY", "force")
	await narrate("Mara lunges for her wrist.")
	await player.walk_to(400.0)
	Audio.sfx("thunk", -2.0)
	hud.glitch(0.4)
	await wait(0.3)
	Audio.sfx("crack", 0.0)
	hud.glitch(0.8)
	g.set_flag("bank_burst")
	await narrate("They crash into the patch bay. The shot goes into it, and Dad's forward bank bursts in sparks under her gauzed hand.")
	await say("EIGHTY-ONE", "Ah—!")
	await narrate("She tears free, burned again, and runs into the dark corridor. The revolver skids under the console.")
	await eighty.walk_to(40.0)
	eighty.visible = false
	Audio.sfx("door", -12.0)
	await narrate("On the Tuner, the fourth digit goes dark. There will be no more futures.")
	await say("RED (RECEIVER)", "...anyone on two-fourteen...")


## 3.9: the white crests the ridge, Halvard's lights go out a street at a time,
## and three slow knocks sound at the front door.
func _three_knocks() -> void:
	var g := GameState
	Audio.play_loop("scratch", -14.0, 0.3)
	await narrate("The chart recorder starts scratching on its own. The signal on 2.14 is climbing toward the moment it was first heard.")
	player.face(1)
	shot = "white"
	var tw := create_tween()
	tw.tween_property(self, "white", 1.0, 3.0)
	tw.parallel().tween_property(self, "lights_out", 1.0, 4.0)
	await narrate("Through the window, the white wall crests the ridge. Across the valley, Halvard's lights begin going out, one street at a time.")
	await tw.finished
	Audio.stop_loop("scratch", 0.5)
	await wait(1.0)
	for i in 3:
		Audio.sfx("knock", -2.0)
		await wait(1.1)
	await wait(0.6)
	await player.walk_to(150.0)
	player.face(-1)
	await narrate("Three slow knocks at the front door. As at the start of the night.")
	await mara("...")
	g.set_flag("act3_done")
	Audio.stop_all(1.5)
	await hud.fade_out(1.2)
	await hud.card("END OF ACT 3", "Act 4 opens on the knocks.", 3.0)
	main.change_room("end_card")


# --- Act 3 drawing --------------------------------------------------------------------------

## The dish through the window: swung to the horizon on the 2.14 run, or parked at the zenith.
func _window_dish() -> void:
	var base := Vector2(700, WIN.end.y - 52)
	var col := Color("0a0e18")
	cv.draw_colored_polygon(PackedVector2Array([base + Vector2(-26, 0), base + Vector2(26, 0), base + Vector2(9, -86), base + Vector2(-9, -86)]), col)
	var parked := GameState.has("dish_parked") and not GameState.has("dish_released")
	var aim := -PI / 2 if parked else (-0.2 if GameState.has("act3") else -1.1)
	var d := Vector2(cos(aim), sin(aim))
	var n := Vector2(-d.y, d.x)
	var v := base + Vector2(0, -92) + d * 8.0
	var pts := PackedVector2Array()
	for i in 17:
		var u := -1.0 + i / 8.0
		pts.append(v + n * (64.0 * u) + d * (22.0 * u * u))
	cv.draw_colored_polygon(pts, col)
	var f := v + d * 60.0
	cv.draw_line(v + d * 22.0 + n * 64.0, f, col, 2.5)
	cv.draw_line(v + d * 22.0 - n * 64.0, f, col, 2.5)
	cv.draw_circle(f, 5.0, col)


func _patch_bay_art() -> void:
	var r := Rect2(1060, 504, 120, 108)
	cv.draw_rect(r, Color("1a1e22"))
	cv.draw_rect(r, Color("0a0c0e"), false, 2.0)
	for row in 3:
		Kit.text(cv, Vector2(r.position.x + 4, r.position.y + 20 + row * 32), ["A", "B", "C"][row], 10, Color("9aa3a0"))
		for c in 6:
			cv.draw_circle(Vector2(r.position.x + 22 + c * 16, r.position.y + 16 + row * 32), 4.0, Color("050607"))
			cv.draw_circle(Vector2(r.position.x + 22 + c * 16, r.position.y + 16 + row * 32), 4.0, Color("6a7074"), false, 1.0)
	if GameState.has("patched"):
		var cols := [Color("c8322c"), Color("e8c040"), Color("2f63c9")]
		var ends := [[Vector2(1082, 520), Vector2(1114, 552)], [Vector2(1146, 552), Vector2(1098, 584)], [Vector2(1130, 584), Vector2(1162, 520)]]
		for i in 3:
			var a: Vector2 = ends[i][0]
			var b: Vector2 = ends[i][1]
			var mid := (a + b) * 0.5 + Vector2(0, 26)
			cv.draw_polyline(PackedVector2Array([a, a.lerp(mid, 0.5) + Vector2(0, 8), mid, b.lerp(mid, 0.5) + Vector2(0, 8), b]), cols[i], 3.0, true)
	if GameState.has("bank_burst"):
		cv.draw_rect(Rect2(1062, 506, 60, 104), Color(0.05, 0.04, 0.03, 0.85))
		for k in 6:
			cv.draw_line(Vector2(1070 + k * 8, 520), Vector2(1066 + k * 9, 600), Color("2a1a10"), 2.0)


func _chart_art() -> void:
	var r := Rect2(312, 420, 122, 50)
	cv.draw_rect(r, Color("2a3036"))
	cv.draw_rect(r, Color("12171b"), false, 2.0)
	cv.draw_rect(Rect2(r.position.x + 8, r.position.y + 6, 80, 38), Color("ece6d0"))
	for k in 5:
		cv.draw_line(Vector2(r.position.x + 8, r.position.y + 10 + k * 8), Vector2(r.position.x + 88, r.position.y + 10 + k * 8), Color(0.6, 0.7, 0.8, 0.5), 1.0)
	Kit.text(cv, Vector2(r.position.x + 92, r.position.y + 18), "2.14", 9, Color("9aa3a0"))
	cv.draw_circle(Vector2(r.position.x + 106, r.position.y + 34), 6.0, Color("15191d"))


func _drive_art() -> void:
	var r := Rect2(924, 418, 76, 52)
	cv.draw_rect(r, Color("2a3036"))
	cv.draw_rect(r, Color("12171b"), false, 2.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 12), "DISH DRIVE", 8, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var parked := GameState.has("dish_parked") and not GameState.has("dish_released")
	cv.draw_rect(Rect2(r.position.x + 8, r.position.y + 20, 26, 14), Color("e8c040") if parked else Color("5a5030"))
	cv.draw_rect(Rect2(r.position.x + 42, r.position.y + 20, 26, 14), Color("5ac06a") if not parked else Color("2a4a30"))
	Kit.text(cv, Vector2(r.position.x + 8, r.position.y + 46), "PARK", 7, Color("c8d0c8"))
	Kit.text(cv, Vector2(r.position.x + 40, r.position.y + 46), "RELEASE", 7, Color("c8d0c8"))
