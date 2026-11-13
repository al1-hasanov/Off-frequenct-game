extends Room
## Act 2.5 — The Lantern diner, where Mara's mother works nights.
##   H : 1983. Ma behind the counter. The pantry is the only room in town dark
##       enough to cross, but Ma always leaves its bulb burning. Tomas's poster
##       is taped in the front window: she put up a new one today.
##   12: 1980, the night Tomas vanished. A younger Ma, lower prices, and the
##       truck keys on the hook by the pantry door.
## The opening (intro_diner.gd) is this diner in our own 1980, an hour and a
## half earlier; is_1980() gives it the 1980 look.

## The front window over the corner booth.
const WIN := Rect2(152, 268, 146, 188)

var ruth: Actor
var tomas: Actor
var trucker: Actor
var window_snow: Snowfall
## Daylight through the front window (the opening's montage).
var window_day := false
## ...and in spring: no snow out there any more.
var window_spring := false


func is_1980() -> bool:
	return freq == "12"


## Snow falling past the front window (added before anyone, so it's behind them).
func add_window_snow() -> void:
	window_snow = Snowfall.new()
	window_snow.area = WIN
	window_snow.count = 28
	window_snow.wind = 16.0
	window_snow.speed = 40.0
	add_child(window_snow)


## The weather past the front window follows the station on screen.
func on_tuning() -> void:
	if window_snow != null:
		window_snow.follow(env())


func setup() -> void:
	animated_back = false
	add_window_snow()
	place_name = "The Lantern · October 14, 1980" if freq == "12" else "The Lantern"
	base_tint = Color(1.0, 0.95, 0.86)
	walk_min = 110.0
	walk_max = 1150.0
	make_player(130.0, 1)
	ruth = add_actor("ruth_1980" if freq == "12" else "ruth", 880.0, -1)
	if GameState.has("pie_sent") and freq == "H" and not GameState.has("in_12"):
		ruth.position.x = 620.0
	trucker = add_actor("dahl_1980" if freq == "12" else "dahl", 300.0, 1)
	trucker.seated = true
	# Mr. Dahl's booth: in H, after Mara comes back from 1980, it's empty.
	trucker.visible = not (freq == "H" and GameState.has("back_from_12"))
	tomas = add_actor("tomas", 1000.0, -1)
	tomas.visible = false
	add_layer(1, _draw_counter)
	add_hotspot("front_door", Rect2(26, 330, 100, 320), "Front door", 110.0, -1)
	add_hotspot("booths", Rect2(150, 470, 330, 180), "Booths", 330.0)
	add_hotspot("window", WIN.grow(8), "Front window", 230.0)
	add_hotspot("ruth", Rect2(560, 440, 400, 120), "Ma" if GameState.has("swapped") else "Mom", 540.0, 1)
	add_hotspot("pie_case", Rect2(566, 500, 90, 60), "Pie case", 540.0, 1)
	add_hotspot("menu", Rect2(600, 240, 360, 100), "Menu board", 760.0)
	add_hotspot("pantry", Rect2(1030, 340, 90, 310), "Pantry", 1070.0, 1)
	add_hotspot("keys", Rect2(1124, 420, 30, 50), "Truck keys", 1120.0, 1, func() -> bool:
		return freq == "12" and not GameState.has_item("truck_keys") and not GameState.has("choice2"))
	add_hotspot("back_door", Rect2(1160, 330, 100, 320), "Back door", 1150.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"from_pantry":
			player.position.x = 1070.0
			player.face(-1)
		"return":
			player.position.x = 1150.0
			player.face(-1)
		_:
			player.position.x = 130.0
			player.face(1)
	var with_tomas: bool = GameState.story.get("TOMAS") == "taken" and entry in ["return", "from_pantry"]
	tomas.visible = with_tomas
	if with_tomas:
		tomas.position.x = player.position.x + 50.0


func is_dark() -> bool:
	return false


func ambience() -> void:
	Audio.stop_all(0.4)
	Audio.play_loop("radio_music", -24.0)
	if freq == "12":
		Audio.play_loop("truck_idle", -34.0)  # Ma's truck, idling out back
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	match entered_from:
		"from_pantry":
			if freq == "12":
				await _arrive_1980()
			else:
				await _back_in_1983()
				return
		"return":
			await _return_to_pantry()
			return
		_:
			if not GameState.has("diner_seen"):
				GameState.set_flag("diner_seen")
				await wait(0.3)
				if GameState.has("swapped"):
					await mara("The Lantern. Ma's on the night shift.")
				else:
					await mara("The Lantern. Mom's on the night shift. Coffee, pie, and three customers staring at nothing.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"front_door":
			if freq == "12":
				await mara("Not out the front. It's 1980 out there, and half this town knows my face.")
			else:
				Audio.sfx("shopbell", -12.0)
				main.change_room("main_street", "from_diner")
		"booths":
			if freq == "12":
				await mara("Mr. Dahl, in his booth. Three years younger and he still hasn't paid his tab.")
			elif not trucker.visible:
				await mara("Mr. Dahl's booth is empty. His coffee's still steaming.")
				await say("RUTH", "He went to wash his hands. That was an hour ago, I think. Was it an hour?")
			else:
				await mara("Mr. Dahl, in his booth, holding his coffee with both hands. He keeps looking at the window.")
		"ruth", "pie_case":
			if freq == "12":
				await say("RUTH", "Go on, Mara. Your brother's waiting.")
			else:
				await _talk_ma(id == "pie_case")
		"window":
			if freq == "12":
				await mara("Snow. It was raining when I came down the mountain. It's still 1980 out there.")
			else:
				await mara("Ma's poster. A new one, taped up today, every corner smoothed flat.")
				await mara("The old one went almost white in the sun. Three years of sun.")
		"menu":
			if freq == "12":
				await narrate("\"COFFEE 35¢ · PIE 85¢ · SPECIAL: MEATLOAF\"")
				await mara("Thirty-five cents. 1980.")
			else:
				await narrate("\"COFFEE 50¢ · PIE $1.25 · SPECIAL: MEATLOAF\"")
		"pantry":
			await _pantry()
		"keys":
			GameState.add_item("truck_keys")
			hud.toast("Got: Truck keys")
			await mara("Ma's truck keys. The rabbit's foot still has fur on it, in this one.")
			objective()
		"back_door":
			await _back_door()


func _talk_ma(at_pie: bool) -> void:
	if not GameState.has("swapped"):
		if not GameState.has("talked_mom"):
			GameState.set_flag("talked_mom")
			await say("RUTH", "Mara! What are you doing down here? The whole town's out in the street.")
			await mara("Mom. Are you okay?")
			await say("RUTH", "Mrs. Lund says there's two of her husband. Two! I told her one's plenty.")
			await mara("Stay in here, okay? Stay where it's light.")
			await say("RUTH", "Where else would I be? I'm on till six.")
		else:
			await say("RUTH", "Coffee, honey? You look frozen.")
		return
	if GameState.has("pie_sent") and not GameState.has("in_12"):
		await say("RUTH", "Hold your horses, I'm cutting it.")
		return
	if not GameState.has("talked_ma"):
		GameState.set_flag("talked_ma")
		await say("RUTH", "Mara? You look like you've seen a ghost.")
		await mara("Ma.")
		await say("RUTH", "Your brother used to say the radio was full of people. I told him to turn it down.")
		await say("RUTH", "Tonight I'd believe him.")
		await mara("Ma... who's feeding Biscuit?")
		await say("RUTH", "Pepper's fine, honey. He's got the heater.")
		# The one spoken mismatch before 1991: the dog. No music sting.
		GameState.set_flag("dog_wrong")
		await narrate("Mara waits a beat, then looks toward the pantry.")
	if GameState.has("in_12"):
		if not GameState.has("ate_pie"):
			GameState.set_flag("ate_pie")
			await say("RUTH", "Sit. Eat. I mean it, Mara. You're not leaving here on an empty stomach.")
			await narrate("Mara sits at the counter and eats the pie. It's the first thing she's eaten since yesterday. It's very good.")
			await say("RUTH", "There. Now you look like somebody's daughter.")
		else:
			await say("RUTH", "More coffee, honey?")
		return
	await mara("Can I get a slice of pie?")
	await say("RUTH", "Cherry. Sit down, I'll bring it.")
	GameState.set_flag("pie_sent")
	ruth.walk_to(620.0)
	await wait(0.5)
	await mara("She's at the front. The pantry's right behind me.")
	objective()


func _pantry() -> void:
	if freq == "12":
		await mara("Not yet. Keys first, then the mountain.")
		return
	if not GameState.has("swapped"):
		await mara("Mom's pantry. She keeps that bulb burning day and night. Keeps the mice honest, she says.")
		return
	if GameState.has("in_12"):
		await mara("I've been. I'm done with that pantry.")
		return
	if not GameState.has("pie_sent"):
		await say("RUTH", "Not in my pantry, honey. What do you need?")
		await mara("Nothing, Ma.")
		await mara("I need her looking the other way.")
		return
	await player.walk_to(1070.0)
	Audio.sfx("door", -14.0)
	await narrate("The pantry. Shelves of cans, flour sacks, and one bare bulb.")
	await mara("Warm, not hot. Quarter turn...")
	Audio.sfx("squeak", -8.0)
	await wait(0.4)
	Audio.sfx("door", -16.0)
	await narrate("The door clicks shut. Black.")
	await mara("In 1980 Ma kept her truck keys on the hook right outside this door.")
	await mara("Twelve. Listen for 1980.")
	var st: String = await tuner_session(_pantry_refusal, 0.0, 1)
	if st == "12":
		await mara("An engine idling. A boy laughing.")
		GameState.set_flag("in_12")
		main.cross("12", "diner", "from_pantry")
	else:
		Audio.sfx("door", -16.0)
		await mara("Not yet. I'll put the bulb back in a second.")


func _pantry_refusal(st: String) -> String:
	if st == "12":
		return ""
	if st == "H":
		return "That's here. That's now."
	if TunerUI.is_quiet(st):
		return "Nothing. One of the quiet ones."
	return "That's not 1980. Twelve. Listen for the truck."


## Out of the pantry, three years back.
func _arrive_1980() -> void:
	await wait(0.6)
	await say("RUTH", "Mara? Did you cut your hair?")
	await mara("...Yeah. Yeah, I did.")
	await mara("Twelve's 1980. Their night, not mine. Their Tomas is still up the mountain.")
	await say("RUTH", "Where's your brother? You said straight back.")
	await mara("He's still up at the dish. I'm going back for him. Right now.")
	await mara("Her truck keys are on the hook. Same hook.")


func _back_door() -> void:
	if freq == "H":
		await mara("The back door. The alley behind Main Street. Nothing out there but trash cans.")
		return
	if GameState.has("choice2"):
		await mara("The pantry. Now. Before she sees.")
		return
	if not GameState.has_item("truck_keys"):
		await mara("Keys first. The truck's out back.")
		return
	await mara("The truck. The mountain. The snowfield.")
	await mara("I know exactly where he'll be standing.")
	Audio.sfx("door", -10.0)
	await hud.fade_out(0.8)
	Audio.sfx("truck_start", -8.0)
	await hud.card("October 14, 1980", "2:11 AM", 2.2)
	main.change_room("snowfield_1980", "from_truck")


## Back down the mountain, in by the back door, straight into the pantry.
func _return_to_pantry() -> void:
	await wait(0.5)
	if tomas.visible:
		await mara("Keep your head down. Don't let her see you.")
		await say("TOMAS", "That's Mom. Why can't she see me?")
		await mara("Because she'd never let go. Come on.")
	else:
		await mara("Back door. Pantry. Before anybody sees me twice.")
	await player.walk_to(1070.0)
	if tomas.visible:
		tomas.walk_to(1100.0)
	Audio.sfx("door", -16.0)
	await narrate("The pantry door clicks shut. Black.")
	if tomas.visible:
		await say("TOMAS", "It's dark. Mara, it only works in the dark.")
		await mara("I know. Hold my hand.")
	await mara("Home. Find the hum.")
	var st := ""
	while st != "H":
		st = await tuner_session(_home_refusal, 4.0, 0)
		if st == "":
			await mara("No. I can't stay in 1980. Find home.")
	main.cross("H", "diner", "from_pantry")


func _home_refusal(st: String) -> String:
	if st == "H":
		return ""
	if st == "12":
		return "That's here. 1980."
	return "Not mine. Find the hum."


## Out of the pantry in 1983, after 1980.
func _back_in_1983() -> void:
	GameState.set_flag("back_from_12")
	trucker.visible = false  # while she was in 1980, Mr. Dahl's booth went quiet
	ruth.position.x = 880.0
	await wait(0.5)
	if tomas.visible:
		Audio.play_loop("radio_music", -26.0, 0.4)
		await narrate("Through the pantry door, 1983: a jukebox, a coffee pot, Ruth's voice at the counter.")
		await say("TOMAS", "That's Mom again.")
		await mara("That one's left a porch light on for you for three years.")
		await say("TOMAS", "Can I—")
		await mara("Not yet. Not like this. Out the back. June's is two doors down.")
		Audio.sfx("door", -10.0)
		main.change_room("pike_radio", "with_tomas")
		return
	await say("RUTH", "Mara? Where'd you go? Your pie's getting cold.")
	await mara("Sorry, Ma.")
	await mara("I left him. I left him with her. With me.")
	await mara("Mr. Dahl's booth is empty. His coffee's still steaming.")
	await say("RUTH", "He went to wash his hands. That was an hour ago, I think. Was it an hour?")
	await say("RUTH", "Sit. Eat. I mean it, Mara. You're not leaving here on an empty stomach.")
	GameState.set_flag("ate_pie")
	await player.walk_to(700.0)
	await narrate("Mara sits at the counter and eats the pie. It's the first thing she's eaten since yesterday. It's very good.")
	await say("RUTH", "There. Now you look like somebody's daughter.")
	# Outside, the dish on the mountain is turning; June calls on the Tuner.
	GameState.set_flag("dish_turning")
	Audio.sfx("powerup", -10.0)
	await wait(0.4)
	await narrate("Outside, the dish on the mountain is turning.")
	await mara("...The dish. Up on the mountain. It's turning. Nobody's up there to turn it.")
	Audio.play_loop("static", -26.0, 0.3)
	await say("JUNE (TUNER)", "Mara? Mara, honey, it's June. Pick up. The dish is calling. The whole band's lit up.")
	await say("JUNE (TUNER)", "Whoever's up there, it's for you. Stop by the shop first.")
	Audio.stop_loop("static", 0.4)
	await mara("The road's eleven miles. I'd never make it in time.")
	await mara("But the old mine runs right under the mountain. Halvard Number 2. It comes out at the observatory.")
	objective()


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	var y1980 := is_1980()
	Kit.wall(cv, floor_y, Color("7a5a48") if y1980 else Color("6a4e44"), Color("5a4036"), Color("2a1e1a"))
	EnvironmentArt.wall_props(cv, "diner")
	# Checkerboard floor.
	for i in 30:
		for j in 3:
			var x := Kit.L + i * 80.0
			var y := floor_y + j * 30.0
			cv.draw_rect(Rect2(x + (40.0 if j % 2 == 1 else 0.0), y, 40, 30), Color("d8d0c0") if (i + j) % 2 == 0 else Color("2a2a2e"))
	Kit.ceiling_light(cv, 380.0, floor_y, true)
	Kit.ceiling_light(cv, 860.0, floor_y, true)
	Kit.door(cv, Rect2(30, 340, 92, 310), Color("8a6a4a"), "")
	cv.draw_rect(Rect2(46, 360, 60, 80), Color("101828"))
	_front_window()
	_booths()
	_menu(y1980)
	_pantry_door()
	Kit.door(cv, Rect2(1166, 340, 90, 310), Color("5a4a3a"), "")
	# A calendar by the back door.
	cv.draw_rect(Rect2(1170, 250, 60, 70), Color("f0ece0"))
	cv.draw_rect(Rect2(1170, 250, 60, 16), Color("8a1d1d"))
	Kit.text(cv, Vector2(1170, 263), "1980" if y1980 else "1983", 11, Color("f0ece0"), HORIZONTAL_ALIGNMENT_CENTER, 60)


## The street through the front window: the building across the way, a
## streetlamp, the snowbank; the frame and sill. (Snow falls past it.)
func _front_window() -> void:
	var r := WIN
	if window_day:
		Kit.vgrad(cv, r, Color("7aa0c8") if window_spring else Color("9aa6b6"), Color("dce8ee") if window_spring else Color("d8dde2"))
		cv.draw_rect(Rect2(r.position.x, r.position.y + 70, r.size.x, 90), Color("6a6460"))
		for k in 3:
			cv.draw_rect(Rect2(r.position.x + 14 + k * 44, r.position.y + 92, 24, 30), Color("3a4250"))
		if window_spring:
			# A tree in new leaf across the street, the road wet and clear.
			cv.draw_line(Vector2(r.end.x - 30, r.end.y - 26), Vector2(r.end.x - 34, r.position.y + 70), Color("4a3a30"), 5.0)
			for k in 7:
				cv.draw_circle(Vector2(r.end.x - 34 + (Townscape.h(k) - 0.5) * 50.0, r.position.y + 50 + Townscape.h(k * 3) * 40.0),
					16.0, Color("7aaa5a").lerp(Color("9ac46a"), Townscape.h(k * 5)))
	elif not env().story():
		_window_station(r, env())
	else:
		Kit.vgrad(cv, r, Color("060a16"), Color("1c2640"))
		cv.draw_rect(Rect2(r.position.x, r.position.y + 70, r.size.x, 90), Color("0d121e"))
		for k in 3:
			var lit := k != 1
			cv.draw_rect(Rect2(r.position.x + 14 + k * 44, r.position.y + 92, 24, 30), Color("d8a65a") if lit else Color("141a26"))
		cv.draw_circle(Vector2(r.end.x - 26, r.position.y + 54), 16.0, Color(1.0, 0.75, 0.4, 0.18))
		cv.draw_circle(Vector2(r.end.x - 26, r.position.y + 54), 4.0, Color("ffd9a0"))
	if window_day or env().story():
		cv.draw_rect(Rect2(r.position.x, r.end.y - 26, r.size.x, 26), Color("6a7062") if window_spring and window_day else Color("8a96ac"))
	cv.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.3, r.size.x, 5), Color("2a201c"))
	Kit.window_frame(cv, r, 1)


## Across the street, on another station: its sky, its season, its lights.
func _window_station(r: Rect2, e: Env) -> void:
	if e.state == "gone":
		Kit.vgrad(cv, r, Color("d8dce4"), Color("f0f2f5"))
		return
	var sky: Array = e.sky()
	Kit.vgrad(cv, r, sky[0], sky[1])
	Kit.stars(cv, Rect2(r.position, Vector2(r.size.x, 60)), 14, 0.0)
	var wall := Color("0d121e") if e.night() else e.shade(Color("7a6a60"))
	cv.draw_rect(Rect2(r.position.x, r.position.y + 70, r.size.x, 90), wall)
	for k in 3:
		var on: bool = e.lit and e.windows_glow() and bool(e.windows[k])
		var c := Color("d8a65a") if on else (e.shade(Color("6a8098")) if e.day() else Color("141a26"))
		if e.state == "derelict":
			c = Color("5a4a3a")
		cv.draw_rect(Rect2(r.position.x + 14 + k * 44, r.position.y + 92, 24, 30), c)
	if not e.day() and e.state != "derelict":
		cv.draw_circle(Vector2(r.end.x - 26, r.position.y + 54), 16.0, Color(1.0, 0.75, 0.4, 0.18))
		cv.draw_circle(Vector2(r.end.x - 26, r.position.y + 54), 4.0, Color("ffd9a0"))
	var g: Array = e.road() if e.snowy() else e.ground()
	cv.draw_rect(Rect2(r.position.x, r.end.y - 26, r.size.x, 26), g[0])


## Tomas's poster, taped inside the glass facing the street: from in here, its
## back, the print showing through. Over the snow beyond the glass.
func draw_fore(ci: CanvasItem) -> void:
	if is_1980() or freq != "H":
		return
	draw_poster_back(ci, 1.0)


func draw_poster_back(ci: CanvasItem, fresh: float) -> void:
	var p := Rect2(WIN.position + Vector2(30, 22), Vector2(86, 112))
	ci.draw_rect(p, Color("eee8d6"))
	ci.draw_set_transform(Vector2(p.end.x, 0), 0.0, Vector2(-1, 1))
	var ink := 0.3 * fresh
	Kit.text(ci, Vector2(0, p.position.y + 18), "MISSING", 13, Color(0.55, 0.15, 0.12, ink + 0.05), HORIZONTAL_ALIGNMENT_CENTER, p.size.x)
	ci.draw_rect(Rect2(20, p.position.y + 26, 46, 44), Color(0.3, 0.3, 0.3, ink * 0.75))
	Kit.text(ci, Vector2(0, p.position.y + 86), "TOMAS LIND", 11, Color(0.1, 0.1, 0.1, ink), HORIZONTAL_ALIGNMENT_CENTER, p.size.x)
	Kit.text(ci, Vector2(0, p.position.y + 100), "AGE 13", 10, Color(0.1, 0.1, 0.1, ink), HORIZONTAL_ALIGNMENT_CENTER, p.size.x)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for c in [p.position, Vector2(p.end.x, p.position.y), p.end, Vector2(p.position.x, p.end.y)]:
		ci.draw_rect(Rect2(c - Vector2(7, 4), Vector2(14, 8)), Color(0.85, 0.85, 0.8, 0.7))


func _booths() -> void:
	for k in 2:
		var x := 160.0 + k * 170.0
		cv.draw_rect(Rect2(x, 520, 26, 130), Color("8a2a2a"))
		cv.draw_rect(Rect2(x + 120, 520, 26, 130), Color("8a2a2a"))
		cv.draw_rect(Rect2(x + 30, 570, 86, 10), Color("c8c0b0"))
		cv.draw_line(Vector2(x + 73, 580), Vector2(x + 73, 650), Color("6a6a6a"), 5.0)
		cv.draw_rect(Rect2(x + 50, 556, 16, 14), Color("e8e4dc"))
		for i in 5:
			cv.draw_line(Vector2(x+4,530+i*20),Vector2(x+22,530+i*20),Color("a34a40"),1.0)
		cv.draw_rect(Rect2(x+81,549,8,20),Color("8d382d"))
		cv.draw_rect(Rect2(x+82,545,6,5),Color("dad3bf"))


func _menu(y1980: bool) -> void:
	var r := Rect2(600, 240, 360, 100)
	cv.draw_rect(r, Color("1a1a1a"))
	cv.draw_rect(r, Color("5a4430"), false, 4.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 30), "COFFEE " + ("35¢" if y1980 else "50¢") + "   PIE " + ("85¢" if y1980 else "$1.25"), 20, Color("f0ece0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 62), "SPECIAL: MEATLOAF", 18, Color("e8a54b"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 88), "OPEN ALL NIGHT", 14, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _pantry_door() -> void:
	var r := Rect2(1034, 340, 84, 310)
	cv.draw_rect(r.grow(6), Color("2a1e1a"))
	var bulb_out := GameState.has("in_12") and freq == "H"
	cv.draw_rect(r, Color("1a1410") if bulb_out else Color("e8d0a0"))
	cv.draw_colored_polygon(PackedVector2Array([r.position, Vector2(r.position.x + 56, r.position.y + 18),
		Vector2(r.position.x + 56, r.end.y - 10), Vector2(r.position.x, r.end.y)]), Color("6a5040"))
	Kit.plate(cv, Vector2(r.get_center().x, r.position.y - 28), "PANTRY", 13)
	# The key hook.
	cv.draw_rect(Rect2(1126, 410, 24, 6), Color("6a6a6a"))
	if freq == "12" and not GameState.has_item("truck_keys") and not GameState.has("choice2"):
		cv.draw_line(Vector2(1136, 416), Vector2(1136, 440), Color("c9a332"), 3.0)
		cv.draw_circle(Vector2(1136, 452), 7.0, Color("e8e0d0"))


func _draw_counter(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(556, 548, 450, 16), Color("c8c0b0"))
	ci.draw_rect(Rect2(566, 564, 430, 86), Color("8a2a2a"))
	ci.draw_rect(Rect2(566, 600, 430, 8), Color("c8c0b0"))
	# Pie case at the front end.
	ci.draw_rect(Rect2(566, 500, 90, 48), Color(0.8, 0.9, 0.95, 0.35))
	ci.draw_rect(Rect2(566, 500, 90, 48), Color("c8c0b0"), false, 2.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(578, 540), Vector2(644, 540), Vector2(611, 514)]), Color("b8423a"))
	for k in 4:
		var x := 640.0 + k * 90.0
		ci.draw_line(Vector2(x, 600), Vector2(x, 650), Color("8a8a8a"), 4.0)
		ci.draw_rect(Rect2(x - 18, 590, 36, 10), Color("8a2a2a"))
	ci.draw_rect(Rect2(780, 530, 24, 18), Color("e8e4dc"))
	ci.draw_rect(Rect2(900, 520, 40, 28), Color("3a3a3e"))
