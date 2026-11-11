extends Room
## Act 2.5 — The Lantern diner, where Mara's mother works nights.
##   H : 1983. Ma behind the counter. The pantry is the only room in town dark
##       enough to cross, but Ma always leaves its bulb burning.
##   12: 1980, the night Tomas vanished. A younger Ma, lower prices, and the
##       truck keys on the hook by the pantry door.

var ruth: Actor
var tomas: Actor
var trucker: Actor


func setup() -> void:
	place_name = "The Lantern · October 14, 1980" if freq == "12" else "The Lantern"
	base_tint = Color(1.0, 0.95, 0.86)
	walk_min = 110.0
	walk_max = 1150.0
	make_player(130.0, 1)
	ruth = add_actor("ruth_1980" if freq == "12" else "ruth", 880.0, -1)
	if GameState.has("pie_sent") and freq == "H" and not GameState.has("in_12"):
		ruth.position.x = 620.0
	trucker = add_actor("townsman", 300.0, 1)
	trucker.seated = true
	tomas = add_actor("tomas", 1000.0, -1)
	tomas.visible = false
	add_layer(1, _draw_counter)
	add_hotspot("front_door", Rect2(26, 330, 100, 320), "Front door", 110.0, -1)
	add_hotspot("booths", Rect2(150, 470, 330, 180), "Booths", 330.0)
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
		Audio.play_loop("engine", -38.0)
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
			else:
				await mara("Mr. Dahl, in his booth, holding his coffee with both hands. He keeps looking at the window.")
		"ruth", "pie_case":
			if freq == "12":
				await say("RUTH", "Go on, Mara. Your brother's waiting.")
			else:
				await _talk_ma(id == "pie_case")
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
			await mara("Mom's truck keys. The rabbit's foot still has fur on it, in this one.")
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
	if GameState.has("in_12"):
		await say("RUTH", "Your pie's right there, honey. Eat something.")
		return
	var pick: int = await hud.choose(["Can I get a slice of pie?", "Never mind."])
	if pick == 0:
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
	await say("RUTH", "Weren't you taking the truck up to fetch your brother?")
	await mara("I'm going. Right now.")
	await mara("The keys are on the hook. Same hook.")


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
	Audio.sfx("engine", -8.0)
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
	ruth.position.x = 880.0
	await wait(0.5)
	if tomas.visible:
		await mara("Out the back. June's is two doors down. Come on.")
		Audio.sfx("door", -10.0)
		main.change_room("pike_radio", "with_tomas")
		return
	await say("RUTH", "Mara? Where'd you go? Your pie's getting cold.")
	await mara("Sorry, Ma.")
	await mara("I left him. I left him with her. With me.")
	objective()


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	var y1980 := freq == "12"
	Kit.wall(self, floor_y, Color("7a5a48") if y1980 else Color("6a4e44"), Color("5a4036"), Color("2a1e1a"))
	EnvironmentArt.wall_props(self, str(name))
	# Checkerboard floor.
	for i in 30:
		for j in 3:
			var x := Kit.L + i * 80.0
			var y := floor_y + j * 30.0
			draw_rect(Rect2(x + (40.0 if j % 2 == 1 else 0.0), y, 40, 30), Color("d8d0c0") if (i + j) % 2 == 0 else Color("2a2a2e"))
	Kit.ceiling_light(self, 380.0, floor_y, true)
	Kit.ceiling_light(self, 860.0, floor_y, true)
	Kit.door(self, Rect2(30, 340, 92, 310), Color("8a6a4a"), "")
	draw_rect(Rect2(46, 360, 60, 80), Color("101828"))
	_booths()
	_menu(y1980)
	_pantry_door()
	Kit.door(self, Rect2(1166, 340, 90, 310), Color("5a4a3a"), "")
	# A calendar by the back door.
	draw_rect(Rect2(1170, 250, 60, 70), Color("f0ece0"))
	draw_rect(Rect2(1170, 250, 60, 16), Color("8a1d1d"))
	Kit.text(self, Vector2(1170, 263), "1980" if y1980 else "1983", 11, Color("f0ece0"), HORIZONTAL_ALIGNMENT_CENTER, 60)


func _booths() -> void:
	for k in 2:
		var x := 160.0 + k * 170.0
		draw_rect(Rect2(x, 520, 26, 130), Color("8a2a2a"))
		draw_rect(Rect2(x + 120, 520, 26, 130), Color("8a2a2a"))
		draw_rect(Rect2(x + 30, 570, 86, 10), Color("c8c0b0"))
		draw_line(Vector2(x + 73, 580), Vector2(x + 73, 650), Color("6a6a6a"), 5.0)
		draw_rect(Rect2(x + 50, 556, 16, 14), Color("e8e4dc"))
		for i in 5:
			draw_line(Vector2(x+4,530+i*20),Vector2(x+22,530+i*20),Color("a34a40"),1.0)
		draw_rect(Rect2(x+81,549,8,20),Color("8d382d"))
		draw_rect(Rect2(x+82,545,6,5),Color("dad3bf"))


func _menu(y1980: bool) -> void:
	var r := Rect2(600, 240, 360, 100)
	draw_rect(r, Color("1a1a1a"))
	draw_rect(r, Color("5a4430"), false, 4.0)
	Kit.text(self, Vector2(r.position.x, r.position.y + 30), "COFFEE " + ("35¢" if y1980 else "50¢") + "   PIE " + ("85¢" if y1980 else "$1.25"), 20, Color("f0ece0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(self, Vector2(r.position.x, r.position.y + 62), "SPECIAL: MEATLOAF", 18, Color("e8a54b"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(self, Vector2(r.position.x, r.position.y + 88), "OPEN ALL NIGHT", 14, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _pantry_door() -> void:
	var r := Rect2(1034, 340, 84, 310)
	draw_rect(r.grow(6), Color("2a1e1a"))
	var bulb_out := GameState.has("in_12") and freq == "H"
	draw_rect(r, Color("1a1410") if bulb_out else Color("e8d0a0"))
	draw_colored_polygon(PackedVector2Array([r.position, Vector2(r.position.x + 56, r.position.y + 18),
		Vector2(r.position.x + 56, r.end.y - 10), Vector2(r.position.x, r.end.y)]), Color("6a5040"))
	Kit.plate(self, Vector2(r.get_center().x, r.position.y - 28), "PANTRY", 13)
	# The key hook.
	draw_rect(Rect2(1126, 410, 24, 6), Color("6a6a6a"))
	if freq == "12" and not GameState.has_item("truck_keys") and not GameState.has("choice2"):
		draw_line(Vector2(1136, 416), Vector2(1136, 440), Color("c9a332"), 3.0)
		draw_circle(Vector2(1136, 452), 7.0, Color("e8e0d0"))


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
