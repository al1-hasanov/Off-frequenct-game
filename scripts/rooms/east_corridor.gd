extends StationRoom
## Act 1.4 — the east wing. Two versions of it:
##   H  (home): dark since September, ticket #4. Mara needs a flashlight here.
##   01: lit by a caged lamp somebody wired in, Sollen asleep in his office,
##       the fire doors chained. Mara has to make it dark to get home again.

var spill: PointLight2D
var doorway: PointLight2D


func setup() -> void:
	place_name = "East wing · Halvard Radio Observatory"
	# At home Mara keeps clear of the bright doorway (it's drawn over everything).
	walk_min = 250.0 if freq == "H" else 120.0
	walk_max = 1160.0
	make_player(250.0, 1)
	add_hotspot("fire_doors", Rect2(24, 330, 196, 320), "Fire doors", 250.0 if freq == "H" else 160.0, -1)
	add_hotspot("lamp", Rect2(290, 250, 82, 96), "Caged lamp" if freq == "01" else "Capped wire", 330.0, 1)
	add_hotspot("notice", Rect2(390, 372, 90, 80), "Notice", 435.0, 1)
	add_hotspot("office_door", Rect2(512, 330, 118, 320), "Sollen's office", 570.0, 1)
	add_hotspot("basement_door", Rect2(722, 330, 108, 320), "Basement", 776.0, 1)
	add_hotspot("garage_door", Rect2(950, 330, 210, 320), "Garage", 1055.0, 1)
	if freq == "H":
		add_hotspot("axe_case", Rect2(848, 396, 92, 148), "Fire axe", 894.0, 0, func() -> bool:
			return GameState.has("act3") and not GameState.has_item("fire_axe") and not GameState.has("wall_broken"))
	if freq == "01":
		spill = add_lamp(Vector2(600, 540), 2.4, Color(1.0, 0.82, 0.55), 1.1)
	else:
		# The lit main corridor, through the propped-open fire doors.
		var col := Color(1.0, 0.45, 0.4) if GameState.emergency else Color(0.85, 0.92, 0.88)
		doorway = add_lamp(Vector2(150, 560), 2.0, col, 0.55)


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"first":
			player.position.x = 160.0
			player.face(1)
		"from_corridor":
			player.position.x = 252.0
			player.face(1)
		"from_office":
			player.position.x = 570.0
		"from_basement":
			player.position.x = 776.0
			player.face(-1)
		"from_garage":
			player.position.x = 1055.0
			player.face(-1)
		_:
			player.position.x = 300.0


func _office_open_01() -> bool:
	return freq == "01" and not GameState.has("office_closed_01")


func is_dark() -> bool:
	if freq == "01":
		return GameState.has("office_closed_01")
	return true


func current_tint() -> Color:
	if freq == "01" and GameState.has("bulb_out") and not GameState.has("office_closed_01"):
		return Color(0.14, 0.13, 0.13) * GameState.freq_tint(freq)
	return super()


func _process(delta: float) -> void:
	super(delta)
	if spill != null:
		spill.visible = GameState.has("bulb_out") and _office_open_01()


func ambience() -> void:
	super()
	if _office_open_01():
		Audio.play_loop("snore", -24.0)
	else:
		Audio.stop_loop("snore", 0.6)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	match entered_from:
		"first":
			await _first_arrival()
		"from_corridor":
			if not GameState.has("east_h_seen"):
				GameState.set_flag("east_h_seen")
				await wait(0.3)
				await mara("Same wing. Dark, like it's supposed to be.")
				await mara("I'm keeping this light on. Whatever happens.")
	objective()


func _first_arrival() -> void:
	await wait(0.7)
	await mara("...The lights are on.")
	await mara("They've been out since September. I walked in here thirty seconds ago and it was pitch black.")
	player.face(-1)
	await wait(0.5)
	await mara("And the fire doors behind me are shut. Chained.")
	player.face(1)
	await mara("And somebody's snoring.")
	GameState.set_flag("seen_01")


func on_hotspot(id: String) -> void:
	match id:
		"fire_doors":
			await _fire_doors()
		"lamp":
			await _lamp()
		"notice":
			if freq == "01":
				await narrate("\"LIGHTS FIXED OCT 3 — THANKS, M.\"")
				await mara("M. That's me. I never fixed anything in this wing. I filed a ticket.")
			else:
				await narrate("\"OUT OF ORDER. Facilities ticket #4.\"")
				await mara("My handwriting. My ticket.")
		"office_door":
			await _office_door()
		"basement_door":
			await _basement_door()
		"garage_door":
			await _garage_door()
		"axe_case":
			if not GameState.has("knows_tin"):
				await mara("BREAK GLASS IN CASE OF FIRE. No fire. Not yet.")
			else:
				Audio.sfx("lock", -8.0)
				GameState.add_item("fire_axe")
				hud.toast("Got: Fire axe")
				await mara("The case was never locked. Of course it wasn't.")
				objective()


func use_item(id: String, item: String) -> bool:
	if id == "lamp" and item == "scarf" and freq == "01":
		await _unscrew()
		return true
	if item == "keys" and freq == "H" and id in ["office_door", "basement_door", "garage_door"]:
		await on_hotspot(id)
		return true
	if id == "lamp" and item == "flashlight":
		await mara("I'm not taking my light apart. Not in here.")
		return true
	return false


func _fire_doors() -> void:
	if freq == "H":
		Audio.sfx("door", -10.0)
		main.change_room("corridor", "from_east")
		return
	if not GameState.has("office_closed_01"):
		await mara("Chained. From this side. Who chains a fire door from this side?")
		if not GameState.has("doors_01_tried"):
			GameState.set_flag("doors_01_tried")
			await mara("I walked through these in the dark. They were open. There was no chain.")
			await mara("It happened in the dark. So... make it dark again?")
		return
	# Dark: the chain is still there, but it doesn't matter any more.
	await mara("Dark. Okay. Hand on the door.")
	await mara("The hum's wrong in here. It's been wrong since I came through. Find the right one...")
	await player.walk_to(60.0)
	main.cross("H", "corridor", "from_01")


func _lamp() -> void:
	if freq == "H":
		await mara("Two screw holes and a capped wire. Somebody meant to put a lamp up here.")
		if GameState.has("seen_01"):
			await mara("In the other one, somebody did.")
		return
	if GameState.has("bulb_out"):
		await mara("Empty socket. The bulb's on the floor, wrapped in Sollen's scarf.")
		return
	if not GameState.has("lamp_burned"):
		await mara("A caged lamp, wired straight into the conduit. No switch.")
		await mara("Whoever put it up didn't want it turned off.")
		Audio.sfx("click", -10.0)
		await mara("The cage just pops off... ow! Ow. Hot.")
		GameState.set_flag("lamp_burned")
		await mara("Too hot to touch. I need something to hold it with.")
		objective()
	elif GameState.has_item("scarf"):
		await _unscrew()
	else:
		await mara("Still too hot to touch bare-handed.")


func _unscrew() -> void:
	if GameState.has("bulb_out"):
		await mara("It's already out.")
		return
	await mara("Scarf around the bulb. Quarter turn...")
	Audio.sfx("squeak", -6.0)
	await wait(0.6)
	Audio.sfx("squeak", -6.0, 0.9)
	GameState.set_flag("bulb_out")
	GameState.remove_item("scarf")
	await mara("There.")
	if _office_open_01():
		await mara("Still light, though. It's spilling out of Sollen's office.")
	objective()


func _office_door() -> void:
	if freq == "01":
		if GameState.has("office_closed_01"):
			await mara("Let him sleep. I'm not opening that again.")
		elif GameState.has("bulb_out") and GameState.has_item("keys"):
			Audio.sfx("door", -18.0)
			GameState.set_flag("office_closed_01")
			Audio.stop_loop("snore", 0.4)
			await mara("Sleep tight, Henrik.")
			await wait(0.5)
			await mara("Dark. Properly dark.")
			objective()
		else:
			if GameState.has("bulb_out"):
				await mara("Before I shut this... his keys. If I'm going back, I want every lock on the mountain.")
			Audio.sfx("door", -14.0)
			main.change_room("sollen_office", "from_corridor")
		return
	if GameState.has("office_h_open"):
		Audio.sfx("door", -10.0)
		main.change_room("sollen_office", "from_corridor")
	elif GameState.has_item("keys"):
		Audio.sfx("keys", -8.0)
		await wait(0.5)
		Audio.sfx("lock", -8.0)
		GameState.set_flag("office_h_open")
		await mara("His key. Let's see who answered his phone.")
		main.change_room("sollen_office", "from_corridor")
	else:
		await mara("Locked. Sollen's phone rang in there. Somebody picked it up.")


func _basement_door() -> void:
	if freq == "01":
		await mara("Locked. Not my problem in this one.")
		return
	if GameState.has("basement_open"):
		Audio.sfx("door", -10.0)
		main.change_room("basement", "from_corridor")
	elif GameState.has_item("keys"):
		Audio.sfx("keys", -8.0)
		await wait(0.5)
		Audio.sfx("lock", -8.0)
		GameState.set_flag("basement_open")
		await mara("The basement. Lost and found, the boiler, and twenty years of junk.")
		main.change_room("basement", "from_corridor")
	else:
		await mara("Basement. Locked. Sollen keeps the key on his ring.")


func _garage_door() -> void:
	if freq == "01":
		await mara("Chained, like the fire doors.")
		return
	if GameState.has("garage_open"):
		Audio.sfx("door", -10.0)
		main.change_room("garage", "from_corridor")
	elif GameState.has("garage_key"):
		Audio.sfx("lock", -8.0)
		GameState.set_flag("garage_open")
		await mara("The tag says GARAGE. And it works.")
		main.change_room("garage", "from_corridor")
	elif GameState.has_item("keys"):
		Audio.sfx("keys", -8.0)
		await wait(0.4)
		await mara("None of Sollen's keys fit. The garage key's somewhere else.")
	else:
		await mara("The garage. Locked.")


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(cv, floor_y, WALL, WALL_LOW, TRIM)
	EnvironmentArt.wall_props(cv, str(name))
	Kit.floor_tiles(cv, floor_y, FLOOR, FLOOR_LINE)
	for x in [420.0, 900.0]:
		Kit.ceiling_light(cv, x, floor_y, false)
	_fire_doors_art()
	_lamp_art()
	_notice_art()
	_office_door_art()
	Kit.door(cv, Rect2(730, 340, 92, 310), DOOR, "BASEMENT")
	cv.draw_rect(Rect2(744, 520, 64, 30), Color("c9a332"))
	Kit.text(cv, Vector2(744, 540), "WATCH STEP", 10, Color("1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER, 64)
	if freq == "H":
		_axe_case()
	_garage_art()


## The fire-axe case between the basement and garage doors.
func _axe_case() -> void:
	var r := Rect2(852, 400, 84, 140)
	cv.draw_rect(r, Color("8a1e1a"))
	cv.draw_rect(r.grow(-6), Color("1a1c1e"))
	if not GameState.has_item("fire_axe") and not GameState.has("wall_broken"):
		cv.draw_line(Vector2(870, 520), Vector2(916, 424), Color("6a4a2a"), 6.0)
		cv.draw_colored_polygon(PackedVector2Array([Vector2(902, 418), Vector2(930, 430), Vector2(924, 448), Vector2(906, 436)]), Color("b8bcc0"))
		cv.draw_colored_polygon(PackedVector2Array([Vector2(902, 418), Vector2(910, 410), Vector2(916, 424)]), Color("8a2a24"))
	cv.draw_rect(r.grow(-6), Color(0.7, 0.85, 0.95, 0.12))
	cv.draw_line(r.position + Vector2(14, 10), r.position + Vector2(30, 120), Color(1, 1, 1, 0.12), 6.0)
	cv.draw_rect(Rect2(r.position.x, r.end.y + 4, r.size.x, 14), Color("e8e2cc"))
	Kit.text(cv, Vector2(r.position.x, r.end.y + 15), "BREAK GLASS", 9, Color("8a1e1a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _fire_doors_art() -> void:
	var r := Rect2(30, 340, 180, 310)
	cv.draw_rect(r.grow(8), Color("15191b"))
	Kit.plate(cv, Vector2(120, 306), "MAIN CORRIDOR")
	if freq == "H":
		# Propped open: the main corridor's light shows through (drawn on the glow layer).
		cv.draw_rect(r, Color("0b0d0e"))
		cv.draw_colored_polygon(PackedVector2Array([Vector2(30, 340), Vector2(62, 352), Vector2(62, 640), Vector2(30, 650)]), DOOR.darkened(0.2))
		cv.draw_colored_polygon(PackedVector2Array([Vector2(210, 340), Vector2(178, 352), Vector2(178, 640), Vector2(210, 650)]), DOOR.darkened(0.2))
		return
	for i in 2:
		var leaf := Rect2(30 + i * 90, 340, 90, 310)
		cv.draw_rect(leaf, DOOR)
		cv.draw_rect(leaf, Color("262d30"), false, 2.0)
		cv.draw_rect(Rect2(leaf.position.x + 22, 380, 46, 70), Color("0d1316"))
	cv.draw_rect(Rect2(40, 506, 160, 10), Color("9aa3a8"))
	# The chain and padlock.
	for k in 12:
		var p := Vector2(44 + k * 13, 512 + sin(k * 0.5) * 7.0)
		cv.draw_arc(p, 6.0, 0.0, TAU, 8, Color("b9b6aa"), 2.0)
	cv.draw_rect(Rect2(108, 520, 24, 20), Color("8a7a3a"))
	cv.draw_arc(Vector2(120, 520), 8.0, PI, TAU, 8, Color("9aa3a8"), 3.0)


func _lamp_art() -> void:
	if freq == "H":
		cv.draw_circle(Vector2(322, 300), 3.0, Color("101314"))
		cv.draw_circle(Vector2(338, 300), 3.0, Color("101314"))
		cv.draw_line(Vector2(330, 120), Vector2(330, 286), Color("4a545b"), 6.0)
		cv.draw_rect(Rect2(322, 284, 16, 10), Color("b8322c"))
		return
	cv.draw_line(Vector2(330, 120), Vector2(330, 280), Color("4a545b"), 6.0)
	cv.draw_rect(Rect2(312, 276, 36, 14), Color("2a2f33"))
	cv.draw_rect(Rect2(322, 290, 16, 10), Color("6a6f73"))


func _notice_art() -> void:
	var r := Rect2(398, 380, 74, 62)
	cv.draw_rect(r, Color("e6dfc8"))
	cv.draw_rect(Rect2(420, 374, 30, 10), Color(0.8, 0.8, 0.75, 0.6))
	if freq == "01":
		Kit.text(cv, Vector2(r.position.x, 400), "LIGHTS", 11, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(cv, Vector2(r.position.x, 414), "FIXED", 11, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(cv, Vector2(r.position.x, 432), "thanks, M.", 10, Color("3a4a8a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	else:
		Kit.text(cv, Vector2(r.position.x, 404), "OUT OF", 11, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(cv, Vector2(r.position.x, 418), "ORDER", 11, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(cv, Vector2(r.position.x, 434), "ticket #4", 10, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _office_door_art() -> void:
	var r := Rect2(522, 340, 96, 310)
	if not _office_open_01():
		Kit.door(cv, r, DOOR, "H. SOLLEN · DIRECTOR")
		return
	cv.draw_rect(r.grow(8), Color("15191b"))
	cv.draw_rect(r, Color("1a1410"))
	Kit.plate(cv, Vector2(r.get_center().x, r.position.y - 30), "H. SOLLEN · DIRECTOR")
	# The leaf swung inward, a warm gap of lamplight beside it. Once the corridor
	# lamp is out, the `spill` light keeps this bright.
	cv.draw_rect(Rect2(580, 362, 38, 274), Color(1.0, 0.84, 0.56))
	cv.draw_colored_polygon(PackedVector2Array([r.position, Vector2(r.position.x + 58, r.position.y + 22),
		Vector2(r.position.x + 58, r.end.y - 14), Vector2(r.position.x, r.end.y)]), DOOR.darkened(0.1))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(580, 650), Vector2(618, 650), Vector2(720, 712), Vector2(560, 712)]),
		Color(1.0, 0.84, 0.56, 0.3))


func _garage_art() -> void:
	var r := Rect2(960, 344, 190, 306)
	cv.draw_rect(r.grow(8), Color("15191b"))
	cv.draw_rect(r, Color("4a5258"))
	for i in 9:
		cv.draw_line(Vector2(r.position.x, r.position.y + 30 + i * 32), Vector2(r.end.x, r.position.y + 30 + i * 32), Color("3a4146"), 3.0)
	cv.draw_rect(Rect2(r.position.x + 70, r.position.y + 150, 50, 12), Color("2a2f33"))
	Kit.plate(cv, Vector2(r.get_center().x, r.position.y - 34), "GARAGE")
	if freq == "01":
		cv.draw_line(Vector2(r.position.x + 20, 500), Vector2(r.end.x - 20, 520), Color("b9b6aa"), 4.0)
		cv.draw_rect(Rect2(r.get_center().x - 12, 504, 24, 20), Color("8a7a3a"))


func draw_glow(ci: CanvasItem) -> void:
	if freq == "H":
		var opening := Rect2(62, 352, 116, 288)
		var col := Color(0.62, 0.2, 0.18) if GameState.emergency else Color(0.5, 0.58, 0.56)
		Kit.vgrad(ci, opening, col.darkened(0.2), col)
		ci.draw_rect(Rect2(62, 600, 116, 40), col.darkened(0.35))
		return
	if not GameState.has("bulb_out"):
		var c := Vector2(330, 308)
		ci.draw_circle(c, 70.0, Color(1.0, 0.9, 0.6, 0.06))
		ci.draw_circle(c, 30.0, Color(1.0, 0.9, 0.6, 0.12))
		ci.draw_circle(c, 13.0, Color("fff3c4"))
		for k in 5:
			var x := 314.0 + k * 8.0
			ci.draw_line(Vector2(x, 292), Vector2(x, 326), Color("2a2f33"), 2.0)
		ci.draw_arc(c, 17.0, 0.0, PI, 12, Color("2a2f33"), 2.0)
