extends Room
## Act 2.4 — Ash Street, up the hill. The Lind house.
##   H : Mom's at work. She left the lamp on, and the porch light, like every night.
##   14: the house is dark, empty, and for sale. Eighty-One is waiting inside.
## The broken streetlight out front is the one dark spot on the street: Mara
## tunes there, and while the Tuner holds a station the whole street behind
## her is that station's: its season, its hour, its weather, and its version of
## the house (see Env).

var snow: Snowfall


func setup() -> void:
	animated_back = false
	place_name = "Ash Street"
	base_tint = Color(0.86, 0.88, 1.0)
	outdoors = true
	walk_min = 70.0
	walk_max = 1200.0
	make_player(90.0, 1)
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 760)
	snow.count = 120
	add_child(snow)
	snow.follow(env())
	add_hotspot("main_street", Rect2(8, 400, 90, 250), "Main Street", 60.0, -1)
	add_hotspot("streetlight", Rect2(300, 300, 90, 350), "Broken streetlight", 350.0, 1)
	add_hotspot("house", Rect2(470, 230, 400, 420), "The Lind house", 640.0)
	add_hotspot("front_door", Rect2(626, 470, 70, 180), "Front door", 660.0, 1)
	add_hotspot("window", FRONT_WIN.grow(8), "Front window", 612.0, -1)
	add_hotspot("sign", Rect2(880, 520, 90, 130), "For sale sign", 860.0, 1, func() -> bool: return freq == "14")
	add_hotspot("neighbors", Rect2(960, 300, 300, 350), "The Halvorsens'", 1000.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"from_main":
			player.position.x = 90.0
			player.face(1)
		"from_house":
			player.position.x = 660.0
			player.face(-1)
		_:
			player.position.x = 350.0


## The weather follows the station on screen.
func on_tuning() -> void:
	snow.follow(env())


func is_dark() -> bool:
	return false


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	Audio.stop_loop("crowd", 0.6)
	Audio.stop_loop("dish_motor", 0.6)
	Audio.play_loop("wind", -16.0 if freq == "14" else -20.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if freq == "H" and not GameState.has("ash_seen"):
		GameState.set_flag("ash_seen")
		await wait(0.4)
		await mara("Mom's house. Every light she owns, on. And the porch light. For Tomas. Every night, three years.")
		await mara("'I'll be in the one with the lights off.' Not this one.")
		await mara("That streetlight's been broken since summer. It's the only dark spot on the street.")
	elif freq == "14" and entered_from == "tuned":
		await wait(0.5)
		await mara("Dark. Empty. For sale.")
		await mara("Mom doesn't live here, in this one. Maybe nobody does.")
	elif freq == "14" and entered_from == "from_house" and GameState.has("swapped") and not GameState.has("left_14"):
		await wait(0.4)
		await mara("Ma's house, for sale. I need to get home.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"main_street":
			if freq == "14":
				await mara("Not down there. Not in this one. Back to the streetlight, and home.")
			else:
				main.change_room("main_street", "from_ash")
		"streetlight":
			await _streetlight()
		"house":
			if freq == "14":
				await mara("Dark, top to bottom. FOR SALE.")
			else:
				await mara("Mom's house. The lamp in the front window, the porch light. She never turns them off.")
		"front_door":
			await _front_door()
		"window":
			if freq == "14":
				await mara("No curtains. No furniture. Just a kitchen table, and a match burning.")
			else:
				Audio.sfx("bark", -12.0)
				if GameState.has("swapped"):
					await mara("Pepper, barking at the window. At me. He's never barked at me.")
				else:
					await mara("Pepper, barking at the window. Hi, boy.")
		"sign":
			await narrate("\"FOR SALE. Halvard Realty.\" The paint on the sign has had three winters.")
		"neighbors":
			await mara("The Halvorsens'. Every light on, and both of them on the porch in their bathrobes.")


func use_item(id: String, item: String) -> bool:
	if item == "tuner" and id == "streetlight":
		await _streetlight()
		return true
	return false


func examine_item(item: String) -> bool:
	if item != "tuner":
		return await super(item)
	await mara(GameState.item_desc("tuner"))
	await mara("Under the broken streetlight. That's the only dark spot on this street.")
	return true


func _front_door() -> void:
	if freq == "H":
		Audio.sfx("bark", -10.0)
		await mara("Locked. Pepper's going crazy in there. Mom's at the diner.")
		await mara("And this isn't the house with the lights off.")
		return
	if GameState.has("swapped"):
		await mara("No. I'm not going back in there.")
		return
	Audio.sfx("door", -10.0)
	main.change_room("ash_kitchen", "from_street")


func _streetlight() -> void:
	await player.walk_to(350.0)
	if freq == "14":
		if not GameState.has("swapped"):
			await mara("She's in there. I came all this way.")
			return
		await mara("The streetlight. Dark. Find home.")
		var st: String = await tuner_session(_home_refusal, 6.0)
		if st == "H":
			GameState.set_flag("left_14")
			main.cross("H", "ash_street", "back_home")
		return
	if GameState.has("swapped"):
		await mara("I've done Ash Street. Tomas is in 12, three years back. I need somewhere dark... and Ma's truck keys.")
		return
	await mara("Dark enough. Light off. Find the one with the lights off.")
	var band := 1 if GameState.has("tuner_repaired") else 0
	var st2: String = await tuner_session(_house_refusal, 0.0, band)
	if st2 == "14":
		await mara("Dark. Every window. And a sign in the yard.")
		main.cross("14", "ash_street", "tuned")
	elif not GameState.has("tuner_repaired"):
		GameState.set_flag("ash_tried")
		await mara("Every one of them, lit. And Tomas's dial stops at 09.")
		await mara("June Pike can fix anything with a tube in it. Her shop's on Main Street.")
		objective()


func _house_refusal(st: String) -> String:
	if st == "14":
		return ""
	if st == "H":
		return "That's home. Mom's lamp is on."
	var e := Env.of(st)
	match e.state:
		"gone":
			return "No house at all on that one. No street. Nothing."
		"derelict":
			return "Boarded up. Nobody's lived there in years. Not that one."
	if e.day():
		return "Daylight. That's not even tonight."
	match e.season:
		"spring":
			return "Spring on that one. The snow's gone grey. Wrong night."
		"summer":
			return "Summer on that one. Wrong night."
		"autumn":
			return "It hasn't snowed on that one yet. Wrong night."
	if not e.lit:
		return "Dark, but there's no sign in the yard. Not that one."
	return "The lights are on in that one."


func _home_refusal(st: String) -> String:
	if st == "H":
		return ""
	if st == "14":
		return "That's here."
	return "Not mine. Find the hum."


# --- drawing --------------------------------------------------------------------

## The Lind house and the windows in it.
const HOUSE := LindHouse.HOUSE
const FRONT_WIN := LindHouse.FRONT_WIN
const PORCH_WIN := LindHouse.PORCH_WIN
const SCONCE := LindHouse.SCONCE
const LAMP_X := 340.0
const NEIGHBORS := [Rect2(-260, 340, 220, 310), Rect2(980, 340, 260, 310)]
const TREES := [Vector2(172, 636), Vector2(1352, 640)]


func draw_back() -> void:
	var e := env()
	if e.state == "gone":
		_quiet()
		return
	var sky: Array = e.sky()
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 520), sky[0], sky[1])
	Kit.stars(cv, Rect2(Kit.L, 0, Kit.R - Kit.L, 260), 100, 0.0)
	Townscape.sky_extras(cv, e, Vector2(880, 92))
	cv.draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 420), Vector2(-100, 330), Vector2(300, 360), Vector2(700, 300), Vector2(1100, 340),
		Vector2(Kit.R, 300), Vector2(Kit.R, 460), Vector2(Kit.L, 460)]), e.hills())
	if e.fire:
		Townscape.fire_glow(cv, e, Vector2(1240, 390))
	Townscape.hill_houses(cv, 372.0, 420.0, 0.0, shown() != "14")
	Kit.pines(cv, 440.0, Color("070b14"))
	# The yards, then the street.
	var g: Array = e.ground()
	Kit.vgrad(cv, Rect2(Kit.L, 438, Kit.R - Kit.L, 190), g[0], g[1])
	var rd: Array = e.road()
	Kit.vgrad(cv, Rect2(Kit.L, 620, Kit.R - Kit.L, 160), rd[0], rd[1])
	for p in TREES:
		Townscape.tree(cv, p, 300.0, int(p.x))
	_neighbor(NEIGHBORS[0], Color("4e5a6a"), 0)
	_neighbor(NEIGHBORS[1], Color("6a5a5e"), 1)
	LindHouse.draw(cv, e, shown() == "14")
	LindHouse.yard(cv, e)
	_streetlight_art()
	cv.draw_rect(Rect2(Kit.L, 646, Kit.R - Kit.L, 10), e.kerb())
	_street_wet(e)
	Townscape.snowbank(cv, Kit.L, 300, 660, 14.0, 4)
	Townscape.snowbank(cv, 880, Kit.R, 660, 16.0, 8)


## The quiet ones: no town at all. White, and nothing in it but the streetlight
## and where the house should be.
func _quiet() -> void:
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 880), Color("d4d8e0"), Color("f2f3f6"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 430), Vector2(-100, 360), Vector2(300, 380), Vector2(700, 330),
		Vector2(1100, 360), Vector2(Kit.R, 330), Vector2(Kit.R, 440), Vector2(Kit.L, 440)]), Color(0.78, 0.8, 0.86, 0.35))
	cv.draw_rect(HOUSE, Color(0.55, 0.6, 0.7, 0.16), false, 2.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(456, 334), Vector2(670, 214), Vector2(884, 334)]), Color(0.55, 0.6, 0.7, 0.06))
	Townscape.streetlamp(cv, LAMP_X, 650.0, 300.0)
	cv.draw_rect(Rect2(LAMP_X + 29, 314, 12, 4), Color("1a1a1e"))


## The neighbours' chimneys smoke, on a cold night.
func draw_anim(ci: CanvasItem) -> void:
	super(ci)
	var e := env()
	if e.state == "gone" or not e.chimney_smoke():
		return
	var c := Color(0.7, 0.75, 0.85, 0.08) if not e.day() else Color(0.9, 0.92, 0.95, 0.18)
	for r in NEIGHBORS:
		var chimney := Rect2(r.position.x + r.size.x * 0.68, r.position.y - 80, 22, 50)
		for k in 4:
			var sp := chimney.position + Vector2(11 + sin(t * 0.6 + k) * 6.0 + k * 4.0, -12 - k * 16 - fposmod(t * 8.0, 16.0))
			ci.draw_circle(sp, 6.0 + k * 3.0, c)


## The neighbours' houses: clapboard, a steep roof (deep in snow in winter),
## windows with their shades half down, a chimney.
func _neighbor(r: Rect2, wall: Color, seed: int) -> void:
	var e := env()
	var lit: bool = (shown() != "14" or seed == 0) if e.story() else (e.lit and e.windows_glow() and (seed == 0 or bool(e.windows[1])))
	Townscape.wall(cv, r, wall if e.night() or e.story() else e.shade(wall.lightened(0.35)), "siding")
	var peak := Vector2(r.position.x + r.size.x * 0.5, r.position.y - 96)
	cv.draw_colored_polygon(PackedVector2Array([r.position + Vector2(-22, 4), peak, Vector2(r.end.x + 22, r.position.y + 4)]), Color("2a2428"))
	if e.roof_snow():
		cv.draw_colored_polygon(PackedVector2Array([r.position + Vector2(-22, 4), peak, Vector2(r.end.x + 22, r.position.y + 4),
			Vector2(r.end.x + 6, r.position.y - 4), peak + Vector2(0, 12), r.position + Vector2(-6, -4)]), Color("d6dde8"))
		cv.draw_polyline(PackedVector2Array([r.position + Vector2(-22, 4), peak, Vector2(r.end.x + 22, r.position.y + 4)]), Color("f2f5fa"), 2.0, true)
	else:
		LindHouse.shingles(cv, PackedVector2Array([r.position + Vector2(-22, 4), peak, Vector2(r.end.x + 22, r.position.y + 4)]), e)
	var chimney := Rect2(r.position.x + r.size.x * 0.68, r.position.y - 80, 22, 50)
	cv.draw_rect(chimney, Color("4a3a36"))
	Townscape.snow_ledge(cv, chimney.position.x - 2, chimney.end.x + 2, chimney.position.y, 5.0, seed * 11)
	for k in 2:
		var w := Rect2(r.position.x + 30 + k * (r.size.x - 120), r.position.y + 60, 60, 70)
		Townscape.window(cv, w, lit, Color("2a2420"))
		cv.draw_rect(Rect2(w.position.x - 14, w.position.y, 10, w.size.y), wall.darkened(0.3))
		cv.draw_rect(Rect2(w.end.x + 4, w.position.y, 10, w.size.y), wall.darkened(0.3))
	Townscape.window(cv, Rect2(r.position.x + r.size.x * 0.5 - 18, r.position.y - 50, 36, 32), lit, Color("2a2420"), false, false)


## The broken streetlight, the one dark spot on the street (on most stations).
func _streetlight_art() -> void:
	var e := env()
	var x := LAMP_X
	Townscape.streetlamp(cv, x, 650.0, 300.0)
	if e.lamp_fixed:
		if not e.day():
			_light_pool(Vector2(375, 650), Color(1.0, 0.8, 0.45, 0.16))
		return
	cv.draw_rect(Rect2(x + 29, 314, 12, 4), Color("1a1a1e"))
	if e.day():
		return
	# The dark pool on the ground where the light should be.
	cv.draw_set_transform(Vector2(352, 650), 0.0, Vector2(1.0, 0.16))
	cv.draw_circle(Vector2.ZERO, 110.0, Color(0, 0, 0, 0.28))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A pool of light on the ground.
func _light_pool(c: Vector2, col: Color) -> void:
	cv.draw_set_transform(c, 0.0, Vector2(1.0, 0.18))
	Kit.soft_glow(cv, Vector2.ZERO, 150.0, col)
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Rain on the street: the lights doubled in the wet.
func _street_wet(e: Env) -> void:
	if e.fall != "rain":
		return
	for x in [FRONT_WIN.get_center().x, PORCH_WIN.get_center().x, 175.0, 1060.0]:
		Kit.vgrad(cv, Rect2(x - 14, 660, 28, 90), Color(1.0, 0.8, 0.5, 0.12 if e.lit else 0.04), Color(1.0, 0.8, 0.5, 0.0))
	for k in 30:
		var p := Vector2(Kit.L + Townscape.h(k * 13) * (Kit.R - Kit.L), 664 + Townscape.h(k * 17) * 100.0)
		cv.draw_line(p, p + Vector2(30 + 40 * Townscape.h(k), 0), Color(0.75, 0.82, 0.95, 0.12), 1.5)


func draw_glow(ci: CanvasItem) -> void:
	var e := env()
	if e.state == "gone":
		return
	if shown() == "14":
		if freq == "14" and not GameState.has("swapped"):
			# One match burning, deep inside the dark front room.
			var f := 0.7 + 0.3 * sin(t * 13.0) * sin(t * 5.0)
			var m := FRONT_WIN.get_center() + Vector2(4, 8)
			ci.draw_circle(m, 4.0, Color(1.0, 0.8, 0.4, 0.9 * f))
			ci.draw_circle(m, 12.0, Color(1.0, 0.7, 0.3, 0.2 * f))
		return
	if e.windows_glow():
		var porch: bool = e.lit if e.story() else (e.porch_light and e.lit)
		if porch:
			# The porch light, on for Tomas.
			ci.draw_circle(SCONCE, 4.0, Color("fff0c0"))
			ci.draw_circle(SCONCE, 18.0, Color(1.0, 0.85, 0.5, 0.18))
		if e.lamp_fixed:
			var c := Vector2(LAMP_X + 35, 318)
			ci.draw_circle(c, 40.0, Color(1.0, 0.62, 0.25, 0.08))
			ci.draw_circle(c, 14.0, Color(1.0, 0.7, 0.35, 0.25))
			ci.draw_circle(c, 5.0, Color("ffd8a0"))
