extends StationRoom
## Act 1.2 — the control room. After 2:14, Mara's own body is slumped against
## the console. Four things to inspect: the wrist, the watch, the pocket, and
## the transmitter's empty key slot.

const BODY_X := 700.0
const CHECKS := ["inspected_wrist", "inspected_watch", "inspected_pocket", "inspected_transmitter"]

var body: Actor
var snow: Snowfall
## Act 3.8: Eighty-One on the floor beside the body; her two radios on the console.
var eighty: Actor
## Act 3.6: the service cupboard beside the console, open while Blue hears 07.
var cupboard_open := false
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
	eighty = add_actor("eighty_one", 590.0, 1)
	eighty.seated = true
	eighty.seat_y = 24.0  # on the floor, knees up, beside the body
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
	add_hotspot("body_arm", Rect2(636, 592, 36, 24), "Her arm", 600.0, 1, here)
	var a3 := func() -> bool: return GameState.has("act3")
	add_hotspot("patch_bay", Rect2(1056, 500, 128, 116), "Patch bay", 1010.0, 1, a3)
	add_hotspot("chart", Rect2(306, 412, 134, 64), "Chart recorder", 380.0, 0, a3)
	add_hotspot("drive", Rect2(920, 412, 84, 64), "Dish drive", 900.0, 0, a3)
	add_hotspot("eighty", Rect2(556, 470, 90, 180), "Eighty-One", 480.0, 1, func() -> bool: return eighty.visible)
	add_hotspot("cupboard", Rect2(1204, 380, 66, 270), "Service cupboard", 1170.0, 1, a3)
	if GameState.has("act3"):
		walk_max = 1170.0


func _body_here() -> bool:
	return GameState.has("heard_transmission")


func _e81_here() -> bool:
	return GameState.has("red_done")


func static_key() -> String:
	var g := GameState
	return "%s|%s|%s|%s|%s|%s|%s" % [Act3.board_lines().size(), g.has("dish_parked"), g.has("lead_pulled"), g.has("patched"), _chart_marks().size(), cupboard_open, g.has("wedged")]


func enter(entry: String) -> void:
	entered_from = entry
	if entry == "from_corridor":
		player.position.x = 112.0
		player.face(1)
	elif entry == "after_red":
		player.position.x = 820.0
		player.face(-1)


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
			if GameState.has("dish_parked"):
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
			await say("EIGHTY-ONE", "I'm staying where you can see me.")
		"cupboard":
			if GameState.has("cupboard_07"):
				await mara("The service cupboard. I closed it from the outside.")
			else:
				await mara("The service cupboard. Fuses, rags, a mop nobody uses. Dark enough to stand in.")
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
			if not GameState.has("own_watch"):
				GameState.set_flag("own_watch")
				await narrate("Mara holds her own watch against her ear. Its hand shivers against the same mark. Her breathing and the chart motor go on.")
				await mara("The clocks. Not us.")
			await _check("inspected_watch")
		"body_arm":
			# Stretched out along the floor, toward the microphone stand (3.8).
			await narrate("Her arm is stretched out along the floor, toward the microphone stand.")
			await mara("She was reaching for the mic.")
			GameState.set_flag("inspected_arm")
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
		_cupboard_art()


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
	var parked := GameState.has("dish_parked")
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
		await mara("Two-fourteen. She's still here.")
		await mara("Out there the dish has swung round to face the horizon. Sollen parks it straight up every night.")
		await mara("And the chart recorder's pen is creeping up the paper. Nobody's touching it.")
		await mara("Whatever the dish is listening to, Tomas's dial can't find it. It runs out at ninety-nine.")
	elif entered_from == "after_red":
		await _eighty_one()
		return
	elif g.has("chalk_2031") and g.has("key_taken") and not g.has("board_2009"):
		g.set_flag("board_2009")
		await wait(0.4)
		await mara("The board.")
		await mara("Under my SILENCE: 2031, somebody's written 2009. In my handwriting.")
		await mara("I didn't write that. I haven't been there yet.")
	elif g.has("woke_2009") and not g.has("chalk_2009"):
		await _chalk_2009()
	elif g.has("woke_1991") and not g.has("cupboard_07"):
		await _call_07()
		return
	objective()


## 3.1: Dad's 2.14 chain. Three cables, six jacks: the Tuner into receiver 2.
func _patch_bay() -> void:
	var g := GameState
	if g.has("lead_pulled"):
		await mara("Red's lead, out of its jack. I pulled it.")
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
	await narrate("Inside Tomas's radio, a relay he never used clicks shut: Dad's modification.")
	await mara("The display's got a fourth digit. The needle's swinging past ninety-nine on its own.")
	await mara("Tomas didn't build this. He finished it.")
	await narrate("The needle settles: 2031.")
	await say("JUNE (TUNER)", "Whatever you're doing up there, honey, don't do it twice. My needle just went over like a tree.")
	if g.story.get("TOMAS") == "taken":
		await say("TOMAS (TUNER)", "It jumped, Mara. Right when you plugged something in. June says that was you.")
	await mara("The loudest future it can hear. And the darkest place on the mountain is the feed cabin. Up on the dish.")
	objective()


## 3.3: Mara writes the year she saw in Sollen's empty corner, and ticks the chart.
func _chalk() -> void:
	var g := GameState
	if g.has("been_2031") and not g.has("chalk_2031"):
		Audio.sfx("chalk", -6.0)
		await narrate("In the corner of the chalkboard Sollen keeps empty for discoveries, she chalks: SILENCE: 2031.")
		g.set_flag("chalk_2031")
		g.set_flag("saw_oct25")
		await mara("Beside his schedule. Its last line: 2.14 RUN, OCT 25.")
		await player.walk_to(380.0)
		Audio.sfx("scratch", -18.0)
		await narrate("The chart recorder. The pen is higher than when she left. She ticks the paper beside it, a maintenance habit, and writes 2031 next to the tick.")
		g.set_flag("chart_2031")
		await mara("Now. Sollen's desk. The hollow left rear leg.")
		objective()
		return
	if g.has("woke_2009") and not g.has("chalk_2009"):
		await _chalk_2009()
		return
	var lines := Act3.board_lines()
	g.set_flag("saw_oct25")
	if lines.is_empty():
		await mara("Sollen's survey schedule. And at the bottom: 2.14 RUN, OCT 25. His next run on the frequency.")
		await mara("He always leaves that corner empty. Says it's for discoveries.")
		if not g.has("saw_chalk_lambda"):
			await _old_chalk()
	else:
		await mara("%s. In my handwriting." % ", ".join(lines))
		if g.has("chalk_2009"):
			await mara("The broken chalk's still on the ledge.")


## 3.5: beneath 2031 she writes 2009, and knows the crooked last digit.
func _chalk_2009() -> void:
	var g := GameState
	await wait(0.3)
	await player.walk_to(240.0)
	player.face(-1)
	Audio.sfx("chalk", -6.0)
	await narrate("Beneath 2031, Mara writes 2009. She recognises the crooked last digit she saw before leaving. The chalk breaks in her fingers.")
	g.set_flag("chalk_2009")
	await mara("I wrote it. Later than I read it.")
	await narrate("She leaves the broken chalk on the ledge. Beside the second, higher mark on the chart, she writes 2009 too.")
	g.set_flag("chart_2009")
	objective()


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


## The years she has marked beside the pen, and the two words.
func _chart_marks() -> Array:
	var out: Array = []
	for y in ["2031", "2009", "1991"]:
		if GameState.has("chart_" + y):
			out.append(y)
	return out


func _chart() -> void:
	var g := GameState
	var marks := _chart_marks()
	if marks.is_empty():
		await mara("The chart recorder. Signal on 2.14, in red ink. The pen's climbing, and nobody's touching it.")
		return
	if g.has("held_here"):
		await mara("My ticks: %s. And the flat stretch, HELD HERE." % ", ".join(marks))
	else:
		await mara("My ticks beside the pen: %s. Every one higher than the last." % ", ".join(marks))


## 3.5, both paths: one test. Dad's card beside the recorder, the key in the
## console, AUTO to PARK. The pen levels; let go and it climbs; hold it, and
## it holds. Then: one more.
func _drive() -> void:
	var g := GameState
	if g.has("e81_done"):
		if g.has("dish_parked"):
			await mara("Wedged in PARK. The dish is still.")
		else:
			await mara("AUTO. I left it running. She's still on the line.")
		return
	if g.has("call_1991"):
		await mara("AUTO. The screwdriver's out. One more, I said.")
		return
	if not g.has("tin_open"):
		await mara("The dish drive. PARK, AUTO, and two readouts. Sollen's the only one who touches it.")
		await mara("Nobody's touched it tonight. The dish turned anyway.")
		return
	if not g.has("reunion_done"):
		await mara("June first. She said somebody's there.")
		return
	if not g.has_item("transmit_key"):
		await mara("PARK needs the console key. Sollen's key.")
		return
	await _park_test()


func _park_test() -> void:
	var g := GameState
	await player.walk_to(900.0)
	player.face(1)
	await narrate("She puts Dad's service card beside the recorder. The transmitter key turns the console from AUTO to PARK.")
	Audio.sfx("click", -6.0)
	Audio.stop_loop("dish_motor", 1.6)
	g.set_flag("dish_parked")
	await narrate("Outside, the dish begins lifting its face away from the valley.")
	await say("JUNE (TUNER)", "Oh. That's better. Keep doing that.")
	Audio.sfx("voice_short", -18.0, 1.15)
	await narrate("Just before the dish leaves the horizon, an older Tomas laughs through the Tuner. A woman's voice tells him to stop it, he'll wake her.")
	await narrate("The display briefly finds 1991. Then that channel fades. June's local shop radio stays clear.")
	await narrate("As the dish comes to rest, the chart pen levels. Mara marks the point.")
	await hud.choose(["Let PARK go"])
	g.set_flag("dish_parked", false)
	Audio.play_loop("dish_motor", -22.0, 0.6)
	Audio.sfx("voice_short", -18.0, 1.15)
	await narrate("She watches it long enough to be sure. When she lets the spring-loaded PARK control return to AUTO, the distant laughter returns and the pen starts climbing again.")
	await hud.choose(["Catch PARK"])
	g.set_flag("dish_parked")
	Audio.stop_loop("dish_motor", 1.0)
	await narrate("She catches PARK once more. The rise stops. She writes only two words beside the flat section: HELD HERE.")
	g.set_flag("held_here")
	hud.toast("On the chart: HELD HERE")
	await mara("Dad left it broken. I put it back on the air.")
	await say("RUTH (TUNER)", "Mara, you fixed what was in front of you.")
	await mara("I know what's in front of me now.")
	Audio.sfx("thunk", -10.0, 1.3)
	g.set_flag("wedged")
	await narrate("She wedges the control in PARK with her screwdriver. The dish stays still.")
	await player.walk_to(420.0)
	player.face(-1)
	await narrate("She heads toward the outside ladder, notebook open at her drawing of the coupling. On the way, she stops beside the Tuner. There is no laughter now. The last year it found is still on its display.")
	await narrate("Mara's thumb rests on the power switch.")
	await mara("One more. I need to know he got more than this.")
	await player.walk_to(900.0)
	player.face(1)
	Audio.sfx("thunk", -12.0, 1.1)
	g.set_flag("wedged", false)
	g.set_flag("dish_parked", false)
	Audio.play_loop("dish_motor", -22.0, 0.6)
	await narrate("She takes the screwdriver out. The dish starts moving. The laughter clears.")
	g.set_flag("call_1991")
	await narrate("June hears the change. She does not say I told you.")
	await say("JUNE (TUNER)", "I'll be here when you come back.")
	objective()


## End of 3.6, back from 1991: the third mark, and 07 on the Tuner. Her own
## kitchen. She stops with one foot over the threshold.
func _call_07() -> void:
	var g := GameState
	await wait(0.3)
	await player.walk_to(380.0)
	await narrate("She writes 1991 beside the third mark on the chart. The marks are closer together. Above them, the line keeps rising.")
	g.set_flag("chart_1991")
	g.set_flag("board_1991")
	await wait(0.4)
	await narrate("She turns the Tuner to 07.")
	Audio.play_loop("static", -30.0, 0.3)
	Audio.play_loop("kettle", -26.0, 0.6)
	Audio.sfx("scrape", -24.0, 1.6)
	await narrate("A kitchen. A dog scratching the same place on a door. Her mother's voice: Biscuit, leave it. A kettle rattles on the stove.")
	await mara("Ma?")
	await say("RUTH FROM 07 (TUNER)", "Where are you? You went out without your gloves.")
	await narrate("Blue presses her hand against her mouth. The ordinary impatience undoes her.")
	await mara("I know. I know, I'm sorry.")
	await say("RUTH FROM 07 (TUNER)", "Are you coming home?")
	await player.walk_to(1170.0)
	player.face(1)
	Audio.sfx("door", -16.0)
	cupboard_open = true
	await narrate("Blue opens the service cupboard beside the console. It is dark enough inside. She can hear the kitchen more clearly as she steps toward it. Her mother's light lies across the bottom of the door, where no light should reach.")
	await mara("I want to.")
	Audio.sfx("voice_short", -22.0, 0.95)
	await narrate("Through the Tuner, under the kettle, another woman is trying to say a word.")
	await narrate("Blue stops with one foot over the threshold.")
	await mara("There's someone else here, Ma. She's waiting too.")
	await say("RUTH FROM 07 (TUNER)", "Bring her in, then. You're letting all the cold through.")
	Audio.sfx("door", -14.0)
	cupboard_open = false
	g.set_flag("cupboard_07")
	await narrate("Blue closes the cupboard from the outside. She has not gone home. It remains a choice she could have made.")
	Audio.stop_loop("kettle", 1.0)
	Audio.stop_loop("static", 1.0)
	await wait(0.6)
	Audio.stop_all(1.2)
	await hud.fade_out(1.2)
	Act3.become_red()
	main.change_room("red_dark", "start")


## 3.8: Eighty-One on the floor beside the dead Mara. Her confession, the lead
## that holds Red's channel open, and Choice 3.
func _eighty_one() -> void:
	var g := GameState
	await wait(0.4)
	Audio.play_loop("static", -26.0, 0.4)
	await narrate("Eighty-One is sitting on the control-room floor beside the dead Mara. Her two radios are on the console. One still has the strap Blue remembers carrying into the kitchen. The other has the tally counter. It reads 81.")
	await mara("Give me my set.")
	Audio.sfx("scrape", -14.0, 1.2)
	await narrate("Eighty-One pushes it across the floor. Blue catches it with her boot. She keeps using Red's; that is where Red's voice is.")
	g.add_item("blue_set")
	hud.toast("Got: My own radio")
	await mara("You took hers off her shoulder. Put it in my hands. Sent me to her mother.")
	await say("EIGHTY-ONE", "I turned it to sixty-one while she still had it. Caught the strap when she fell. By the time I struck the match, she'd followed the carrier. I put the set back on H. Gave it to you.")
	await say("EIGHTY-ONE", "I sent you to the boy.")
	await mara("You told me the hum would take me home.")
	await say("EIGHTY-ONE", "I needed you to come here.")
	await narrate("Blue looks at the corpse. Eighty-One has covered the wound with a folded station towel. One corner is dark through.")
	await mara("You needed her too?")
	await narrate("Eighty-One says nothing. Blue kneels.")
	await player.walk_to(660.0)
	await narrate("The woman has Blue's uneven thumbnail, the same old solder burn. In her coat is a photograph: Biscuit under the kitchen table, Ruth laughing above him, Blue's gloved hand covering half the lens.")
	await narrate("Blue has that photograph at home. On the back, in her own handwriting: MA IS STILL THERE. GO BACK FOR THE OTHER ONE.")
	g.set_flag("saw_photo")
	await mara("That's my kitchen.")
	await say("EIGHTY-ONE", "She went home first.")
	await mara("Then came back.")
	await say("EIGHTY-ONE", "She wouldn't leave the caller.")
	await narrate("Blue looks at the outstretched hand beside the microphone.")
	await mara("You shot her.")
	await say("EIGHTY-ONE", "Yes.")
	await mara("Not because there were two of her. Because she said no to you.")
	await narrate("Eighty-One looks down.")
	await say("EIGHTY-ONE", "She'd parked it. The voice was nearly gone. Then somebody on the line said her brother's name and she reached to put it back.")
	await narrate("Blue touches the dead woman's tape. Same colour, same ordinary overlap where it sticks to itself. It could be a few hours ahead of her own hand.")
	await mara("You don't get to call this saving anyone.")
	await narrate("Eighty-One takes the pistol from inside her coat, slowly, holding it by the barrel. She sets it on the floor between them and pushes it away from herself. Blue moves it beyond her reach.")
	g.set_flag("pistol_away")
	# The console replays the opening warning: the chair, the two relay clicks.
	Audio.sfx("scrape", -12.0)
	await wait(0.55)
	Audio.sfx("click", -12.0)
	await wait(0.28)
	Audio.sfx("click", -12.0, 0.78)
	await narrate("The console replays the opening warning. Chair scrape. Two relay clicks. Eighty-One nods toward the fallen chair.")
	await say("EIGHTY-ONE", "That was her. She saw me coming back up the stairs. She'd locked the front door.")
	await say("EIGHTY-ONE", "I came through the basement.")
	await narrate("She looks toward the lobby handset, repaired by Red earlier that night.")
	await say("EIGHTY-ONE", "She was ringing everyone. Other houses. Other us. Every answer moved the pen. I cut the pair at the board. Folded the ends away so they wouldn't touch.")
	await mara("And so nobody could help her.")
	await say("EIGHTY-ONE", "That too.")
	await say("EIGHTY-ONE", "Later, the one I left in the kitchen fixed the pair. Called the office while I was sitting in it. I picked up. Said don't. One word. Then I couldn't think of anything else to say.")
	g.set_flag("e81_confessed")
	await say("RED (TUNER)", "The light's going. Whoever's there, please—")
	Audio.sfx("voice_short", -22.0, 0.9)
	await narrate("Far underneath: TOMAS. TREES.")
	await narrate("Eighty-One flinches at the boy's name. The chart pen climbs another notch.")
	await say("EIGHTY-ONE", "That's what I needed you for. This lead. It holds her channel open. Pull it and she stops reaching him. The rise slows. We get time to park the dish and get to the coupling.")
	await mara("You put her in the dark.")
	await say("EIGHTY-ONE", "I'd already heard her calling. On his tape. Before I ever found that kitchen. Somebody was going to make the call.")
	await mara("You made sure it was her.")
	await say("EIGHTY-ONE", "I thought if I knew where she was, if I chose who was at this end, I could stop it after the first few words. Before he got to the trees.")
	await mara("So you made the caller. Then you went looking for someone who'd leave her there.")
	await narrate("Eighty-One cannot look toward the body.")
	await mara("Why not give us our radios? Send us home?")
	await say("EIGHTY-ONE", "She would have gone after him. You would have gone after yours. I'd spent eleven days hearing one boy ask for a house I'd taken him out of. I wanted one of you at a switch, for once. Not another hand on a dial.")
	await mara("You could have asked.")
	await say("EIGHTY-ONE", "I did.")
	await narrate("She looks at the body now. Blue waits until she looks away again.")
	if g.story.get("TOMAS") == "taken":
		await mara("Two of us were alive in your kitchen. Neither of us disappeared until you put your hands on us. At June's there's a woman holding a boy she didn't give birth to. They're still there. Your rules didn't kill this woman. You did.")
	else:
		await mara("Two of us were alive in your kitchen. Neither of us disappeared until you put your hands on us. The two Lunds were standing in the street together. One vanished later, with the dish running. You never saw a number decide it. Your rules didn't kill this woman. You did.")
	await say("EIGHTY-ONE", "And your looking? What did that do?")
	await narrate("She points at the chalkboard.")
	await say("EIGHTY-ONE", "When you first climbed that ladder, the Silence was in 2031. Then 2009. Then 1991. Three trips. Look outside.")
	player.face(1)
	shot = "white"
	var tw := create_tween()
	tw.tween_property(self, "white", 0.35, 2.0)
	tw.parallel().tween_property(self, "lights_out", 0.25, 2.0)
	await narrate("Below the window, the last house on the switchback road has no shadow. The streetlight beyond it is visible through its wall.")
	await say("EIGHTY-ONE", "It's tonight, Mara.")
	await narrate("Blue looks at the PARK control. At her screwdriver on the desk. She had stopped it. She started it again to hear him laugh.")
	await mara("I know.")
	await say("EIGHTY-ONE", "Then tell me I'm wrong about the wire.")
	await narrate("Blue does not. She reaches toward PARK, then stops. She remembers the laughter fading when the dish turned away.")
	await mara("If I park it, I lose her anyway.")
	await say("EIGHTY-ONE", "Yes.")
	var trusted: bool = g.story.get("JUNE") == "trusted"
	if trusted:
		await say("JUNE (TUNER)", "I've got her door lined up with your pen. She can hear you there. Give me a little longer and I can keep her on it.")
	else:
		await say("JUNE (TUNER)", "I keep losing which one she is. There's a door in there somewhere. She's doing it herself, Mara. I can hear her trying.")
	if g.story.get("TOMAS") == "taken":
		await say("TOMAS (LOCAL RADIO)", "Was she talking to me? The woman in the trees?")
		await mara("Someone used what she said.")
		await say("TOMAS (LOCAL RADIO)", "She sounds scared.")
		await say("EIGHTY-ONE", "I told mine to stay under the kitchen lamp. He kept asking me to come upstairs.")
		await narrate("Ruth takes the set, not to silence him but to hold it steady. He keeps his hand beside hers.")
		await say("RUTH (LOCAL RADIO)", "We're at the truck. Tell June when we move.")
	else:
		await say("RUTH (LOCAL RADIO)", "June's got her lantern. I've got the keys. We can leave now if you need us to.")
	var pick: int = await hud.choose(["Cut Red's channel and buy the town time", "Keep Red's channel open and stay with her"])
	if pick == 0:
		await _cut_channel()
	else:
		await _keep_channel(trusted)
	await _three_knocks()


## Choice 3, A: pull Red's lead. The rise eases; the white stops gaining. It does not retreat.
func _cut_channel() -> void:
	var g := GameState
	g.set_story("EIGHTY", "cut")
	await mara("June. Stay with Ruth. Get them moving.")
	await player.walk_to(1010.0)
	player.face(1)
	await narrate("She puts her hand on the lead.")
	await mara("Red. There's a door. Keep your foot against it. Don't follow another voice.")
	await say("RED (TUNER)", "Please don't—")
	Audio.sfx("plug", -4.0)
	Audio.stop_loop("static", 0.05)
	g.set_flag("lead_pulled")
	await narrate("Blue pulls the lead. No clean end to the sentence. The chart pen's climb eases. Through the window, the white stops gaining on the next street. It does not retreat.")
	await hud.fade_out(0.6)
	await wait(0.4)
	await narrate("At the door in the dark, Red's lamp goes out. Her hand finds the strip of tape she has tied around the mesh beside the hinge. She does not vanish.")
	await hud.fade_in(0.6)
	await say("JUNE (LOCAL RADIO)", "I've lost her.")
	await mara("I know.")
	Audio.sfx("thunk", -10.0, 1.3)
	g.set_flag("dish_parked")
	g.set_flag("wedged")
	Audio.stop_loop("dish_motor", 1.2)
	await narrate("Blue wedges the control in PARK. The dish stops; the chart levels. Red's lead stays disconnected.")


## Choice 3, B: keep the channel open and stay with her. The pen climbs; the
## white takes the corner; June takes Ruth down the steep lower track.
func _keep_channel(trusted: bool) -> void:
	var g := GameState
	g.set_story("EIGHTY", "keep")
	await mara("June. Take them downhill. Keep your set on. I'm staying with her.")
	await say("EIGHTY-ONE", "You watched what happened to the last one.")
	await mara("Yes.")
	await narrate("She holds the talk button.")
	await mara("Red. I can hear the recorder. Tap when you hear it scrape.")
	await say("RED (TUNER)", "You sound like me.")
	await mara("I know. Keep your foot there.")
	Audio.sfx("voice_short", -22.0, 0.9)
	var tw := create_tween()
	tw.tween_property(self, "white", 0.7, 2.0)
	tw.parallel().tween_property(self, "lights_out", 0.6, 2.0)
	await narrate("Another clipped fragment reaches the boy in 1980. Tomas. Over here. The pen climbs. Outside, the white takes the corner where the streetlight stood. June has to turn Ruth away from the usual road and take the steep lower track.")
	g.set_flag("white_corner")
	for i in 2:
		Audio.sfx("knock", -20.0, 1.6)
		await wait(0.4)
	if trusted:
		await narrate("With June's help, Blue finds the live taps.")
	else:
		await narrate("Without June, Blue loses time answering two copied taps first.")
	await narrate("Red's lamp goes out while Blue is still speaking. Red keeps her foot against the door. She is frightened. She is not alone.")
	await narrate("Blue holds the key but leaves AUTO running. She can still hear Red. The pen keeps rising.")


## The end of Act 3: one knock from the service door, then a second, a third.
## The handle does not turn.
func _three_knocks() -> void:
	var g := GameState
	g.set_flag("e81_done")
	eighty.seated = false
	eighty.seat_y = 54.0
	await narrate("Eighty-One stands.")
	await player.walk_to(820.0)
	player.face(-1)
	await mara("You stay where I can see you.")
	await narrate("Eighty-One stays.")
	await wait(0.8)
	Audio.sfx("knock", -4.0)
	await wait(0.6)
	player.face(1)
	await narrate("From the service door behind the console: one knock.")
	await narrate("Blue turns. In that wall there was only a cupboard when she called 07.")
	Audio.sfx("knock", -4.0)
	await wait(1.1)
	Audio.sfx("knock", -4.0)
	if g.story.get("EIGHTY") == "keep":
		await wait(0.2)
		for i in 3:
			Audio.sfx("knock", -20.0, 1.2)
			await wait(0.35)
		await narrate("A second knock. A third. Red's open channel carries the same three knocks a fraction later.")
	else:
		await narrate("A second knock. A third. They are the first sound Blue has had from that side since she pulled the lead.")
	await wait(0.6)
	await narrate("The handle does not turn.")
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
	var parked := GameState.has("dish_parked")
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
	if GameState.has("lead_pulled"):
		# Red's lead, out of its jack, hanging.
		cv.draw_rect(Rect2(1120, 578, 22, 20), Color("2a3036"))
		cv.draw_polyline(PackedVector2Array([Vector2(1162, 520), Vector2(1172, 560), Vector2(1166, 610), Vector2(1150, 640)]), Color("2f63c9"), 3.0, true)
		cv.draw_circle(Vector2(1150, 640), 4.0, Color("9aa3a8"))


func _chart_art() -> void:
	var r := Rect2(312, 420, 122, 50)
	cv.draw_rect(r, Color("2a3036"))
	cv.draw_rect(r, Color("12171b"), false, 2.0)
	cv.draw_rect(Rect2(r.position.x + 8, r.position.y + 6, 80, 38), Color("ece6d0"))
	for k in 5:
		cv.draw_line(Vector2(r.position.x + 8, r.position.y + 10 + k * 8), Vector2(r.position.x + 88, r.position.y + 10 + k * 8), Color(0.6, 0.7, 0.8, 0.5), 1.0)
	Kit.text(cv, Vector2(r.position.x + 92, r.position.y + 18), "2.14", 9, Color("9aa3a0"))
	cv.draw_circle(Vector2(r.position.x + 106, r.position.y + 34), 6.0, Color("15191d"))
	# Her ticks beside the pen, each higher than the last, and HELD HERE.
	var marks := _chart_marks()
	for i in marks.size():
		var y := r.position.y + 36 - i * 9
		cv.draw_line(Vector2(r.position.x + 10, y), Vector2(r.position.x + 16, y), Color("1a2a6a"), 1.5)
		Kit.text(cv, Vector2(r.position.x + 18, y + 3), str(marks[i]), 6, Color("1a2a6a"))
	if GameState.has("held_here"):
		Kit.text(cv, Vector2(r.position.x + 50, r.position.y + 40), "HELD HERE", 6, Color("1a2a6a"))


## The service cupboard beside the console, past the transmitter.
func _cupboard_art() -> void:
	var r := Rect2(1208, 386, 60, 264)
	cv.draw_rect(r.grow(4), Color("3a4248"))
	if cupboard_open:
		cv.draw_rect(r, Color("050608"))
		# Her mother's light, along the bottom of the dark, where no light should reach.
		cv.draw_rect(Rect2(r.position.x + 4, r.end.y - 8, r.size.x - 8, 5), Color(1.0, 0.78, 0.45, 0.85))
		cv.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(-26, 14), Vector2(r.position.x - 26, r.end.y - 6), Vector2(r.position.x, r.end.y)]), Color("4a545a"))
	else:
		cv.draw_rect(r, Color("4a545a"))
		cv.draw_rect(r, Color("1e2428"), false, 2.0)
		cv.draw_circle(Vector2(r.position.x + 10, r.position.y + 140), 4.0, Color("9aa3a8"))
		Kit.text(cv, Vector2(r.position.x, r.position.y + 30), "SERVICE", 8, Color("c8d0c8"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _drive_art() -> void:
	var r := Rect2(924, 418, 76, 52)
	cv.draw_rect(r, Color("2a3036"))
	cv.draw_rect(r, Color("12171b"), false, 2.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 12), "DISH DRIVE", 8, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var parked := GameState.has("dish_parked")
	cv.draw_rect(Rect2(r.position.x + 8, r.position.y + 20, 26, 14), Color("e8c040") if parked else Color("5a5030"))
	cv.draw_rect(Rect2(r.position.x + 42, r.position.y + 20, 26, 14), Color("5ac06a") if not parked else Color("2a4a30"))
	Kit.text(cv, Vector2(r.position.x + 8, r.position.y + 46), "PARK", 7, Color("c8d0c8"))
	Kit.text(cv, Vector2(r.position.x + 42, r.position.y + 46), "AUTO", 7, Color("c8d0c8"))
	if GameState.has("wedged"):
		# Her screwdriver, wedged under the PARK control.
		cv.draw_line(Vector2(r.position.x + 4, r.position.y + 38), Vector2(r.position.x + 36, r.position.y + 30), Color("c8322c"), 4.0)
		cv.draw_line(Vector2(r.position.x + 36, r.position.y + 30), Vector2(r.position.x + 50, r.position.y + 27), Color("b8bcc0"), 2.0)
