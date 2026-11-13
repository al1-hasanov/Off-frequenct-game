extends Room
## Act 2.1 — Halvard's main street, the hub of Act 2. Sodium lights on snow,
## townspeople outside in coats over pajamas, and five ways to go: Ash Street,
## the Lantern diner, Pike Radio, the dark alley by the sheriff's office (where
## Mara crosses to 05), and the boarded mine tunnel at the end of the street.

var snow: Snowfall
var couple_w: Actor
var couple_h: Actor
## The other Mr. Lund, from another frequency. Gone after 1980.
var couple_h2: Actor
var townsman: Actor


func setup() -> void:
	animated_back = false
	place_name = "Main Street · Halvard"
	base_tint = Color(1.0, 0.9, 0.76)
	outdoors = true
	walk_min = 70.0
	walk_max = 1200.0
	make_player(560.0, 1)
	couple_w = add_actor("townswoman", 214.0, 1)
	couple_h = add_actor("husband", 272.0, -1)
	couple_h2 = add_actor("husband", 152.0, 1)
	couple_h2.visible = not GameState.has("choice2")
	townsman = add_actor("townsman", 1000.0, -1)
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 760)
	snow.count = 140
	snow.wind = 25.0
	add_child(snow)
	snow.follow(env())
	add_hotspot("ash_street", Rect2(8, 380, 112, 270), "Ash Street", 70.0, -1)
	add_hotspot("diner_door", Rect2(374, 480, 62, 170), "The Lantern", 404.0, 1)
	add_hotspot("diner_window", Rect2(150, 420, 200, 120), "Diner window", 330.0, -1)
	add_hotspot("couple", Rect2(120, 470, 180, 180), "The Lunds", 330.0, -1)
	add_hotspot("bell", Rect2(1140, 150, 90, 130), "Church bell", NAN)
	add_hotspot("upstairs", Rect2(196, 236, 90, 74), "Upstairs window", 330.0, -1)
	add_hotspot("pike_door", Rect2(634, 480, 60, 170), "Pike Radio", 664.0, 1)
	add_hotspot("pike_window", Rect2(476, 420, 150, 120), "Shop window", 560.0)
	add_hotspot("alley", Rect2(700, 400, 66, 250), "Alley", 732.0, 1)
	add_hotspot("sheriff_door", Rect2(870, 480, 58, 170), "Sheriff's office", 900.0, 1)
	add_hotspot("sheriff_window", Rect2(780, 430, 80, 100), "Sheriff's window", 820.0)
	add_hotspot("townsman", Rect2(970, 470, 60, 180), "Townsman", 940.0, 1)
	add_hotspot("tunnel", Rect2(1060, 380, 200, 270), "Mine tunnel", 1130.0, 1)
	add_hotspot("dish", Rect2(800, 120, 180, 90), "The dish", NAN)


## While the Tuner holds another station, the street behind Mara is that
## station's: its season, its weather, and none of tonight's people in it.
func on_tuning() -> void:
	snow.follow(env())
	var away := tuning != "" and tuning != freq
	couple_w.visible = not away
	couple_h.visible = not away
	couple_h2.visible = not away and not GameState.has("choice2")
	townsman.visible = not away


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"from_ash":
			player.position.x = 80.0
			player.face(1)
		"from_diner":
			player.position.x = 404.0
		"from_pike":
			player.position.x = 664.0
		"from_alley":
			player.position.x = 732.0
			player.face(-1)
		"from_tunnel":
			player.position.x = 1120.0
			player.face(-1)
		_:
			player.position.x = 560.0


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	Audio.stop_loop("drone", 0.6)
	Audio.play_loop("wind", -22.0)
	Audio.play_loop("crowd", -19.0)  # the town outside: steps, doors, a shovel, a car
	if GameState.has("dish_turning"):
		Audio.play_loop("dish_motor", -26.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if entered_from == "arrive" and not GameState.has("a2_arrived"):
		GameState.set_flag("a2_arrived")
		await wait(0.5)
		await mara("Halvard. Every light in town is on, at two in the morning.")
		await mara("And everybody's outside. In their pajamas.")
		await mara("'Ash Street. I'll be in the one with the lights off.' Mom's house is up the hill.")
	elif _needs_call():
		await _june_calls()
	objective()


func _needs_call() -> bool:
	return GameState.has("choice2") and not GameState.has("dish_turning")


## After 1980: the dish starts turning by itself, and June calls on the Tuner.
func _june_calls() -> void:
	GameState.set_flag("dish_turning")
	ambience()
	await wait(0.6)
	Audio.sfx("powerup", -10.0)
	await mara("...The dish. Up on the mountain. It's turning.")
	await mara("Nobody's up there to turn it.")
	Audio.play_loop("static", -26.0, 0.3)
	await say("JUNE (RADIO)", "Mara? Mara, honey, it's June. Pick up.")
	await say("JUNE (RADIO)", "The dish is calling. The whole band's lit up. Whoever's up there, it's for you.")
	await mara("The road's eleven miles. I'd never make it in time.")
	await mara("But the old mine runs right under the mountain. Halvard Number 2. It comes out at the observatory.")
	Audio.stop_loop("static", 0.4)
	await wait(0.4)
	hud.toast("[The church bell is swinging. No sound.]")
	await mara("St. Olaf's bell is swinging. I can't hear it. I can't hear it at all.")


func on_hotspot(id: String) -> void:
	match id:
		"ash_street":
			main.change_room("ash_street", "from_main")
		"diner_door":
			Audio.sfx("shopbell", -12.0)
			main.change_room("diner", "from_main")
		"diner_window":
			if GameState.has("swapped"):
				await mara("Ma's behind the counter. Three customers staring into their coffee.")
			else:
				await mara("Mom's behind the counter. Three customers staring into their coffee.")
		"couple":
			await _lunds()
		"upstairs":
			if GameState.has("choice2"):
				await mara("The Lunds' kitchen light is on. Nobody's in it.")
			else:
				await mara("The Lunds' kitchen window. Both of them came down for the coat.")
		"bell":
			if GameState.has("dish_turning"):
				await mara("St. Olaf's bell. Swinging hard, and not a sound. Like the air forgot how.")
			else:
				await mara("St. Olaf's. That bell hasn't rung since the parish stopped paying the ringer.")
		"pike_door":
			Audio.sfx("shopbell", -12.0)
			main.change_room("pike_radio", "from_main")
		"pike_window":
			await mara("Every radio in June's window is on. Every one of them is talking.")
		"alley":
			await _alley()
		"sheriff_door":
			if GameState.has("crystal_taken"):
				await mara("Locked, and dark. Cal never knew I was in there. One of him didn't.")
			else:
				await mara("Locked. Dark. Cal's out on calls.")
				if GameState.has("june_diag"):
					await mara("The crystal's in there. And it's dark in there. Dark means a door.")
		"sheriff_window":
			await mara("Cal's desk, Cal's board, Cal's base radio on the shelf. All dark.")
		"townsman":
			await say("TOWNSMAN", "Power went out. Came back wrong.")
			await say("TOWNSMAN", "My kitchen's got two of everything. Two kettles. Both whistling.")
		"tunnel":
			await _tunnel()
		"dish":
			if GameState.has("dish_turning"):
				await mara("It's turning. Slow. Like it's looking for somebody.")
			else:
				await mara("Up the mountain, the dish. My night shift. It feels like a week ago.")


## The Lunds: two Mr. Lunds, one spare coat. After 1980, one of them is gone.
func _lunds() -> void:
	if GameState.has("choice2"):
		await say("MRS. LUND", "Arne went upstairs for the other coat. Twenty minutes ago.")
		await say("MRS. LUND", "The kitchen light's on. He's not in it.")
		await mara("One of them's gone quiet. Just... gone quiet.")
		GameState.set_flag("lund_gone")
		return
	if not GameState.has("met_lunds"):
		GameState.set_flag("met_lunds")
		await say("MRS. LUND", "Mara. Settle something. I've got two husbands and one spare coat.")
		await say("MR. LUND", "I'm the one she married.")
		await say("MR. LUND", "We're both the one she married, Arne.")
		await say("MRS. LUND", "The one with the cold feet gets it. That's how it's always been.")
		await narrate("Both Mr. Lunds raise a hand.")
		await say("MRS. LUND", "Well. That's no help at all.")
		return
	await say("MRS. LUND", "Forty-one years, and now I have to share him with himself.")


func use_item(id: String, item: String) -> bool:
	if item == "tuner" and id == "alley":
		await _alley()
		return true
	return false


func examine_item(item: String) -> bool:
	if item != "tuner" or not GameState.has("tuner_repaired") and not GameState.has("june_diag"):
		return await super(item)
	await mara(GameState.item_desc("tuner"))
	await mara("Not out here under the streetlights. I need somewhere properly dark. That alley?")
	return true


## The narrow gap between June's and the sheriff's office: the darkest place on the street.
func _alley() -> void:
	if not GameState.has("june_diag"):
		await mara("The alley. Pitch black between the buildings. I'm not walking in there for no reason.")
		return
	if GameState.has("crystal_taken"):
		await mara("I'm done with the alley. And with frequency 05.")
		return
	await player.walk_to(740.0)
	await mara("Dark enough. The sheriff's office is right through that wall.")
	await mara("Find the one where Cal's lights are on.")
	var st: String = await tuner_session(_alley_refusal, 3.0)
	if st == "05":
		await mara("Lights. Cal's lights.")
		main.cross("05", "sheriff_office", "from_alley")


func _alley_refusal(st: String) -> String:
	if st == "05":
		return ""
	if st == "H":
		return "That's here. Cal's office is dark here."
	var e := Env.of(st)
	if e.state == "gone":
		return "Nothing on that one. Not even the office."
	if e.state == "derelict":
		return "Boarded up on that one. The whole street."
	if e.day():
		return "Broad daylight on that one. Not tonight."
	if e.season != "winter":
		return "No snow on that one. Not tonight."
	return "The office is still dark on that one."


func _tunnel() -> void:
	if not GameState.has("dish_turning"):
		await mara("Halvard Number 2. Boarded up since the collapse in '61. Kids dare each other to touch the boards.")
		return
	if not GameState.has("tunnel_open"):
		await mara("The boards... somebody's already pried them loose. Recently.")
		Audio.sfx("boards", -4.0)
		GameState.set_flag("tunnel_open")
		await mara("Somebody went this way tonight.")
	main.change_room("mine_tunnel", "from_main")


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	var e := env()
	if e.state == "gone":
		_quiet()
		return
	var sky: Array = e.sky()
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 520), sky[0], Color("18213a") if e.story() else sky[1])
	Kit.stars(cv, Rect2(Kit.L, 0, Kit.R - Kit.L, 260), 90, 0.0)
	Townscape.sky_extras(cv, e, Vector2(640, 92))
	# The mountain, with the observatory on top.
	cv.draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 380), Vector2(300, 330), Vector2(620, 262), Vector2(880, 176), Vector2(1060, 230),
		Vector2(1300, 300), Vector2(Kit.R, 360), Vector2(Kit.R, 420), Vector2(Kit.L, 420)]), e.hills())
	var ridge := Color(0.75, 0.8, 0.9, 0.25)
	if not e.story():
		ridge = Color(0.95, 0.97, 1.0, 0.5) if e.season != "summer" else Color(0.6, 0.62, 0.6, 0.18)
	cv.draw_polyline(PackedVector2Array([Vector2(560, 276), Vector2(620, 262), Vector2(700, 236), Vector2(800, 200),
		Vector2(880, 176), Vector2(960, 196), Vector2(1060, 230), Vector2(1160, 262)]), ridge, 3.0, true)
	var dark := Color("080c18") if e.night() or e.story() else e.shade(Color("4a505a"))
	cv.draw_rect(Rect2(826, 166, 60, 20), dark)
	if e.story() or (e.lit and e.windows_glow()):
		cv.draw_rect(Rect2(840, 178, 6, 5), Color("e8a54b"))
	if not GameState.has("dish_turning"):
		_dish(cv, Vector2(920, 184), 0.0)
	if e.fire:
		Townscape.fire_glow(cv, e, Vector2(1300, 330))
	# Halvard up the hillside. Tonight every light in town is on.
	Townscape.hill_houses(cv, 300.0, 392.0, 0.0)
	_wires()
	# Street level.
	var rd: Array = [Color("8e8e98"), Color("5a5e6e")] if e.story() else e.road()
	Kit.vgrad(cv, Rect2(Kit.L, 640, Kit.R - Kit.L, 140), rd[0], rd[1])
	_diner_building()
	_pike_building()
	_alley_art()
	_sheriff_building()
	_tunnel_art()
	_church()
	_ash_sign()
	for x in [120.0, 455.0, 1010.0]:
		Townscape.streetlamp(cv, x, 650.0, 330.0)
	_street()


## The quiet ones: no town. White, and the shapes of where the buildings would be.
func _quiet() -> void:
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 880), Color("d4d8e0"), Color("f2f3f6"))
	var ghost := Color(0.55, 0.6, 0.7, 0.14)
	for r in [Rect2(140, 200, 310, 450), Rect2(466, 300, 236, 350), Rect2(766, 320, 250, 330), Rect2(1080, 420, 140, 230)]:
		cv.draw_rect(r, ghost, false, 2.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 380), Vector2(300, 330), Vector2(620, 262), Vector2(880, 176),
		Vector2(1060, 230), Vector2(1300, 300), Vector2(Kit.R, 360), Vector2(Kit.R, 420), Vector2(Kit.L, 420)]), Color(0.78, 0.8, 0.86, 0.3))


## What moves on Main Street: the Lantern's chasing bulbs, and once the dish
## turns, the dish on the mountain and St. Olaf's silent bell.
func draw_anim(ci: CanvasItem) -> void:
	super(ci)
	var e := env()
	if e.state == "gone":
		return
	var chase := _open(e) and not e.day()
	for k in 12:
		var on := chase and (k + int(t * 2.0)) % 4 != 0
		ci.draw_rect(Rect2(159.5 + k * 24.0, 365.5, 5, 5), Color("ffd890") if on else Color("a86a3a"))
	Townscape.snow_ledge(ci, 148, 442, 372, 5.0, 23)
	if GameState.has("dish_turning"):
		_dish(ci, Vector2(920, 184), sin(t * 0.25) * 0.5)
		Townscape.church_bell(ci, CHURCH, sin(t * 2.4) * 0.5)


const CHURCH := Vector2(1190, 298)


func _dish(ci: CanvasItem, base: Vector2, ang: float) -> void:
	var c := Color("080c18")
	ci.draw_line(base, base + Vector2(0, -26), c, 5.0)
	ci.draw_set_transform(base + Vector2(0, -26), ang, Vector2.ONE)
	ci.draw_arc(Vector2.ZERO, 30.0, PI * 0.9, PI * 2.1, 16, c, 5.0)
	ci.draw_line(Vector2.ZERO, Vector2(0, -26), c, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Power lines strung across the town, behind the rooftops.
func _wires() -> void:
	for k in 3:
		var pts := PackedVector2Array()
		for i in 31:
			var x := lerpf(-300.0, 1500.0, i / 30.0)
			pts.append(Vector2(x, 238.0 + k * 9.0 + sin(PI * fposmod(i / 10.0, 1.0)) * 16.0))
		cv.draw_polyline(pts, Color(0.02, 0.03, 0.05, 0.9), 1.5, true)
	for x in [-300.0, 300.0, 900.0, 1500.0]:
		cv.draw_line(Vector2(x, 232), Vector2(x, 420), Color("0a0d14"), 5.0)
		cv.draw_line(Vector2(x - 16, 238), Vector2(x + 16, 238), Color("0a0d14"), 3.0)


## Somebody's home on this station: the shops are open, the lights are on.
func _open(e: Env) -> bool:
	return e.story() or (e.state == "home" and e.lit)


## Boards nailed over a shop window, on the derelict stations.
func _boards(r: Rect2) -> void:
	cv.draw_rect(r, Color("0e1014"))
	for i in 5:
		var y := r.position.y + (i + 0.5) * r.size.y / 5.0
		var tilt := (Townscape.h(int(r.position.x) + i * 7) - 0.5) * 12.0
		cv.draw_line(Vector2(r.position.x - 4, y - tilt), Vector2(r.end.x + 4, y + tilt), Color("6a5a46").darkened(0.2 * Townscape.h(i)), 16.0)


func _diner_building() -> void:
	var e := env()
	Townscape.wall(cv, Rect2(140, 200, 310, 450), Color("5a3a30") if e.night() or e.story() else e.shade(Color("8a5a48")), "brick")
	Townscape.cornice(cv, 140, 450, 200, Color("3a2a24"))
	# Upstairs: the Lunds' kitchen (its glass is on the glow layer) and their front room.
	var up := e.story() or (e.lit and e.windows_glow())
	Townscape.window(cv, Rect2(196, 236, 90, 74), up, Color("2a201e"), true, false)
	Townscape.window(cv, Rect2(330, 236, 90, 74), up, Color("2a201e"), true)
	cv.draw_rect(Rect2(140, 352, 310, 8), Color("7a6a5e"))
	Townscape.snow_ledge(cv, 138, 452, 352, 5.0, 11)
	# The sign: painted letters on a dark board, a row of bulbs under it.
	cv.draw_rect(Rect2(150, 372, 290, 36), Color("2a201e"))
	cv.draw_rect(Rect2(150, 372, 290, 36), Color("8a6a3a"), false, 2.0)
	Kit.text(cv, Vector2(150, 398), "THE LANTERN", 24, Color("ff9a4a") if _open(e) and not e.day() else Color("c87a46"), HORIZONTAL_ALIGNMENT_CENTER, 290)
	Townscape.snow_ledge(cv, 148, 442, 372, 5.0, 23)  # its bulbs chase: draw_anim()
	# The diner through its big front window: booths, lamps, the counter.
	var r := Rect2(150, 420, 210, 130)
	if e.state == "derelict":
		_boards(r)
	else:
		var lit_in := _open(e) and not e.day()
		if lit_in:
			Kit.vgrad(cv, r, Color("f6d39a"), Color("d8985a"))
		elif e.day():
			Kit.vgrad(cv, r, e.shade(Color("8a8070")), e.shade(Color("5a5048")))
		else:
			Kit.vgrad(cv, r, Color("1a1c24"), Color("0c0e12"))
		cv.draw_rect(Rect2(150, 500, 210, 50), Color(0.55, 0.18, 0.14, 0.55 if lit_in or e.day() else 0.25))
		for k in 3:
			cv.draw_rect(Rect2(162 + k * 66, 486, 40, 30), Color(0.45, 0.12, 0.1, 0.8 if lit_in or e.day() else 0.3))
			cv.draw_line(Vector2(182 + k * 66, 420), Vector2(182 + k * 66, 440), Color(0.3, 0.2, 0.15), 1.0)
			cv.draw_circle(Vector2(182 + k * 66, 444), 7.0, Color(1.0, 0.95, 0.75) if lit_in else Color(0.5, 0.48, 0.42))
		if _open(e):
			cv.draw_circle(Vector2(250, 476), 8.0, Color(0.3, 0.2, 0.18, 0.75))
			cv.draw_rect(Rect2(242, 484, 16, 26), Color(0.3, 0.2, 0.18, 0.75))
		if e.day() and e.state == "home":
			cv.draw_line(r.position + Vector2(20, r.size.y), r.position + Vector2(90, 0), Color(1, 1, 1, 0.1), 30.0)
	Townscape.storefront_frame(cv, r, Color("4a2e26"))
	Townscape.awning(cv, 144, 366, 412, 16, Color("8a2a24"), Color("e8dcc4"))
	Townscape.door(cv, Rect2(374, 480, 62, 170), Color("6a4a3a"), Color("e8c890") if _open(e) and not e.day() else Color("2a2c30"))
	cv.draw_line(Vector2(443, 210), Vector2(443, 640), Color("282e30"), 4.0)
	cv.draw_line(Vector2(444, 210), Vector2(444, 640), Color("707976"), 1.0)


func _pike_building() -> void:
	Townscape.wall(cv, Rect2(466, 300, 236, 350), Color("4e5a54"), "siding")
	# A false-front parapet, the old way of making a shop look bigger.
	cv.draw_rect(Rect2(460, 290, 248, 14), Color("2e3634"))
	cv.draw_rect(Rect2(500, 280, 168, 12), Color("2e3634"))
	Townscape.snow_ledge(cv, 500, 668, 280, 6.0, 31)
	Townscape.snow_ledge(cv, 458, 710, 290, 5.0, 37)
	# The ham antenna on the roof.
	cv.draw_line(Vector2(600, 280), Vector2(600, 190), Color("2a2f33"), 3.0)
	for k in 4:
		var w := 60.0 - k * 12.0
		cv.draw_line(Vector2(600 - w * 0.5, 210 + k * 18), Vector2(600 + w * 0.5, 210 + k * 18), Color("2a2f33"), 2.0)
	cv.draw_line(Vector2(600, 196), Vector2(540, 284), Color(0.1, 0.12, 0.14, 0.8), 1.0)
	cv.draw_line(Vector2(600, 196), Vector2(664, 284), Color(0.1, 0.12, 0.14, 0.8), 1.0)
	# The shop window: every radio in it switched on.
	var e := env()
	if e.state == "derelict":
		_boards(Rect2(476, 420, 150, 120))
	else:
		_pike_window(e)
	Townscape.storefront_frame(cv, Rect2(476, 420, 150, 120), Color("2e3634"))
	_pike_sign(e)


func _pike_window(e: Env) -> void:
	var on := _open(e) and not e.day()
	cv.draw_rect(Rect2(476, 420, 150, 120), Color("c8d0a0") if on else (e.shade(Color("8a9078")) if e.day() else Color("1a1e1c")))
	if not _open(e):
		return
	for k in 6:
		var x := 490.0 + (k % 3) * 44.0
		var y := 440.0 + (k / 3) * 46.0
		cv.draw_rect(Rect2(x, y, 34, 26), Color("3a3020"))
		cv.draw_rect(Rect2(x + 4, y + 4, 18, 8), Color("e8a54b"))
		for bar in 4:
			cv.draw_line(Vector2(x + 4 + bar * 3, y + 16), Vector2(x + 4 + bar * 3, y + 22), Color("998559"), 1.0)
		cv.draw_circle(Vector2(x + 27, y + 17), 2, Color("bda671"))


func _pike_sign(e: Env) -> void:
	cv.draw_rect(Rect2(476, 372, 216, 34), Color("22272a"))
	cv.draw_rect(Rect2(476, 372, 216, 34), Color("6a7a6e"), false, 2.0)
	Kit.text(cv, Vector2(476, 395), "PIKE RADIO & REPAIR", 16, Color("c8e0c0"), HORIZONTAL_ALIGNMENT_CENTER, 216)
	Townscape.snow_ledge(cv, 474, 694, 372, 4.0, 41)
	Townscape.door(cv, Rect2(634, 480, 60, 170), Color("4a5258"), Color("c8d0a0") if _open(e) and not e.day() else Color("2a2e2c"))
	if _open(e):
		Kit.text(cv, Vector2(646, 520), "OPEN", 10, Color("3a5a3a"))
	cv.draw_rect(Rect2(624, 466, 80, 8), Color("2e3634"))
	Townscape.snow_ledge(cv, 622, 706, 466, 5.0, 43)
	Townscape.icicles(cv, 624, 704, 474, 5)


func _alley_art() -> void:
	var e := env()
	cv.draw_rect(Rect2(702, 330, 64, 320), Color("030406") if e.night() or e.story() else e.shade(Color("2a2c32")))
	# An old service cable sagging across the alley, and a trash can.
	var wire := PackedVector2Array()
	for i in 19:
		wire.append(Vector2(690 + i * 5, 360 + sin(i / 18.0 * PI) * 13))
	cv.draw_polyline(wire, Color("161e26"), 2.0, true)
	cv.draw_rect(Rect2(716, 600, 28, 46), Color("303a3c"))
	cv.draw_rect(Rect2(713, 596, 34, 5), Color("8b9897"))
	for i in 4:
		cv.draw_line(Vector2(720 + i * 6, 606), Vector2(720 + i * 6, 642), Color("485659"), 1.0)
	Townscape.snow_ledge(cv, 713, 747, 596, 5.0, 51)


func _sheriff_building() -> void:
	Townscape.wall(cv, Rect2(766, 320, 250, 330), Color("5c564c"), "stone")
	Townscape.cornice(cv, 766, 1016, 320, Color("3a3630"), false)
	# While the Tuner is locked on a station, the windows show that version of
	# the office: only in 05 is anyone home with the lights on.
	var lit := shown() == "05"
	Townscape.window(cv, Rect2(780, 430, 80, 100), lit, Color("24211d"), false, false)
	Townscape.window(cv, Rect2(940, 430, 64, 100), lit, Color("24211d"), false, false)
	if not lit and (env().night() or env().story()):
		for k in 6:
			cv.draw_line(Vector2(782, 440 + k * 14), Vector2(858, 440 + k * 14), Color(0.2, 0.22, 0.26, 0.6), 2.0)
	# Upper windows: these stay visible above the Tuner panel.
	for wx in [796.0, 950.0]:
		Townscape.window(cv, Rect2(wx, 334, 44, 32), lit, Color("24211d"), false, false)
	# A little pediment over the door, and the steps.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(860, 474), Vector2(899, 452), Vector2(938, 474)]), Color("4a4640"))
	Townscape.snow_ledge(cv, 858, 940, 474, 4.0, 61)
	Townscape.door(cv, Rect2(870, 480, 58, 170), Color("3a2e24"), Color("0e1012"))
	Kit.text(cv, Vector2(880, 520), "SHERIFF", 8, Color("8a8d81"))
	cv.draw_rect(Rect2(786, 376, 220, 36), Color("24211d"))
	cv.draw_rect(Rect2(786, 376, 220, 36), Color("8a7a52"), false, 2.0)
	Kit.text(cv, Vector2(786, 400), "COUNTY SHERIFF", 18, Color("c9b48a"), HORIZONTAL_ALIGNMENT_CENTER, 220)
	cv.draw_circle(Vector2(896, 352), 14.0, Color("c9a332"))
	cv.draw_circle(Vector2(896, 352), 9.0, Color("a8862a"))
	# The flag, limp in the cold.
	cv.draw_line(Vector2(1008, 420), Vector2(1040, 380), Color("2a2a2e"), 3.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1038, 382), Vector2(1036, 410), Vector2(1030, 412), Vector2(1030, 390)]), Color("5a6e8a"))


func _tunnel_art() -> void:
	# The mountainside meets the street; the old mine mouth is cut into it.
	var rock := Color("2a2a30") if env().night() or env().story() else env().shade(Color("6a6670"))
	cv.draw_colored_polygon(PackedVector2Array([
		Vector2(1030, 650), Vector2(1030, 360), Vector2(1140, 300), Vector2(Kit.R, 260), Vector2(Kit.R, 650)]), rock)
	for k in 9:
		var y := 330.0 + k * 34.0
		cv.draw_line(Vector2(1036, y + 10), Vector2(Kit.R, y - 18 + 8 * Townscape.h(k)), Color(0.12, 0.12, 0.15, 0.8), 2.0)
	for k in 7:
		var bx := 1040.0 + Townscape.h(k * 5) * 300.0
		var by := 380.0 + Townscape.h(k * 9) * 240.0
		cv.draw_circle(Vector2(bx, by), 6.0 + 8.0 * Townscape.h(k), rock.lightened(0.08))
	# Snow lying on the slope (grass, out of winter).
	var e := env()
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1030, 362), Vector2(1140, 302), Vector2(Kit.R, 262),
		Vector2(Kit.R, 276), Vector2(1140, 314), Vector2(1030, 372)]), Color("cfd8e6") if e.snowy() else (e.ground()[0] as Color))
	var m := Rect2(1080, 420, 140, 230)
	cv.draw_rect(m, Color("050506"))
	cv.draw_rect(Rect2(m.position.x - 12, m.position.y - 14, m.size.x + 24, 18), Color("5a4430"))
	cv.draw_rect(Rect2(m.position.x - 12, m.position.y, 14, m.size.y), Color("5a4430"))
	cv.draw_rect(Rect2(m.end.x - 2, m.position.y, 14, m.size.y), Color("5a4430"))
	for k in 6:
		cv.draw_line(Vector2(m.position.x - 12, m.position.y + 20 + k * 36), Vector2(m.position.x + 2, m.position.y + 20 + k * 36), Color("3e2e20"), 1.0)
	Townscape.snow_ledge(cv, m.position.x - 14, m.end.x + 14, m.position.y - 14, 6.0, 71)
	var open := GameState.has("tunnel_open")
	for k in 5:
		var y := m.position.y + 24 + k * 42
		if open and k % 2 == 1:
			cv.draw_colored_polygon(PackedVector2Array([Vector2(m.position.x, y), Vector2(m.position.x + 40, y + 6),
				Vector2(m.position.x + 40, y + 20), Vector2(m.position.x, y + 14)]), Color("6a5236"))
		else:
			cv.draw_rect(Rect2(m.position.x - 4, y, m.size.x + 8, 16), Color("6a5236"))
			cv.draw_line(Vector2(m.position.x - 4, y + 3), Vector2(m.end.x + 4, y + 3), Color("7a6246"), 1.0)
	# Rails running into the dark.
	cv.draw_line(Vector2(1100, 650), Vector2(1112, 600), Color("4a4644"), 3.0)
	cv.draw_line(Vector2(1200, 650), Vector2(1188, 600), Color("4a4644"), 3.0)
	for k in 4:
		cv.draw_line(Vector2(1098 + k * 3, 640 - k * 12), Vector2(1202 - k * 3, 640 - k * 12), Color("3a2c22"), 4.0)
	cv.draw_rect(Rect2(1090, 350, 120, 30), Color("c9b48a"))
	Kit.text(cv, Vector2(1090, 371), "HALVARD No.2", 15, Color("3a2a1a"), HORIZONTAL_ALIGNMENT_CENTER, 120)
	Townscape.snow_ledge(cv, 1088, 1212, 350, 4.0, 73)


## St. Olaf's on the slope above the mine. Once the dish turns, its bell
## swings, and there's no sound.
func _church() -> void:
	Townscape.church(cv, CHURCH, 0.0, not GameState.has("dish_turning"))


func _ash_sign() -> void:
	cv.draw_line(Vector2(60, 650), Vector2(60, 470), Color("3a3a3a"), 5.0)
	cv.draw_rect(Rect2(14, 470, 100, 30), Color("2e5a3a"))
	cv.draw_rect(Rect2(14, 470, 100, 30), Color("e8e8e0"), false, 1.5)
	Kit.text(cv, Vector2(14, 491), "ASH ST ↑", 16, Color("e8e8e0"), HORIZONTAL_ALIGNMENT_CENTER, 100)
	Townscape.snow_ledge(cv, 12, 116, 470, 5.0, 81)


## The sidewalk and the street: kerb, banks of ploughed snow, tyre ruts,
## footprints, gutter grates, a hydrant, light spilling from the shops.
func _street() -> void:
	cv.draw_rect(Rect2(Kit.L, 646, Kit.R - Kit.L, 10), Color("d8dce6"))
	cv.draw_line(Vector2(Kit.L, 656), Vector2(Kit.R, 656), Color("7a7e8a"), 2.0)
	for k in 5:
		var y := 676.0 + k * 9.0
		cv.draw_line(Vector2(Kit.L, y), Vector2(Kit.R, y + 2.0), Color(0.3, 0.32, 0.38, 0.35), 5.0)
	for i in 34:
		var p := Vector2(-180 + i * 48, 664 + (i % 3) * 8)
		cv.draw_line(p, p + Vector2(13, 1), Color(0.18, 0.23, 0.27, 0.32), 3.0)
	for x in [76.0, 708.0, 1190.0]:
		cv.draw_rect(Rect2(x, 685, 48, 9), Color("454b4c"))
		for i in 7:
			cv.draw_line(Vector2(x + 3 + i * 6, 686), Vector2(x + 3 + i * 6, 693), Color("88918d"), 1.0)
	Townscape.snowbank(cv, Kit.L, 60, 720, 22.0, 3)
	Townscape.snowbank(cv, 1240, Kit.R, 720, 26.0, 9)
	Townscape.snowbank(cv, 140, 372, 652, 8.0, 5)
	Townscape.snowbank(cv, 940, 1016, 652, 10.0, 7)
	# A hydrant at the corner.
	cv.draw_rect(Rect2(1016, 618, 14, 30), Color("9a2a24"))
	cv.draw_rect(Rect2(1012, 622, 22, 6), Color("7a1e1a"))
	cv.draw_circle(Vector2(1023, 616), 7.0, Color("9a2a24"))
	Townscape.snow_ledge(cv, 1015, 1031, 611, 4.0, 91)
	# Warm light from the shop windows on the snow (or the wet street).
	var e := env()
	if _open(e) and not e.day():
		var a := 0.14 if e.fall != "rain" else 0.24
		for r in [Rect2(150, 420, 210, 130), Rect2(476, 420, 150, 120)]:
			Kit.vgrad(cv, Rect2(r.position.x, 657, r.size.x, 48 if e.fall != "rain" else 110), Color(1, 0.72, 0.37, a), Color(1, 0.72, 0.37, 0))
	if _lamps_on(e):
		for x in [155.0, 490.0, 1045.0]:
			cv.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 351), Vector2(x + 6, 351), Vector2(x + 82, 646), Vector2(x - 82, 646)]),
				Color(1, 0.7, 0.4, 0.025))


## The streetlamps burn after dark, unless the town's been abandoned.
func _lamps_on(e: Env) -> bool:
	return e.story() or (not e.day() and e.state != "derelict")


func draw_glow(ci: CanvasItem) -> void:
	var e := env()
	if e.state == "gone":
		return
	if _lamps_on(e):
		for x in [120.0, 455.0, 1010.0]:
			var c := Vector2(x + 35, 348)
			ci.draw_circle(c, 46.0, Color(1.0, 0.62, 0.25, 0.08))
			ci.draw_circle(c, 18.0, Color(1.0, 0.7, 0.35, 0.25))
			ci.draw_circle(c, 6.0, Color("ffd8a0"))
	if not e.story():
		return
	# The Lunds' kitchen window: lit, and empty (both Mr. Lunds are down on the street).
	var w := Rect2(196, 236, 90, 74)
	ci.draw_rect(w, Color(1.0, 0.85, 0.55, 0.9))
	var s := Color(0.32, 0.22, 0.14, 0.55)
	ci.draw_rect(Rect2(204, 286, 74, 24), s)  # the kitchen counter, a kettle on it
	ci.draw_circle(Vector2(226, 282), 6.0, s)
	ci.draw_rect(w, Color("2a201e"), false, 4.0)
	ci.draw_line(Vector2(241, 236), Vector2(241, 310), Color("2a201e"), 3.0)
