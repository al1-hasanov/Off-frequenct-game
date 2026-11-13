extends StationRoom
## Act 1.7 — the garage and Sollen's snowcat.
##   H : dark. The tank is empty and a pine has fallen across the road. Mara
##       tapes her wrist and uses Tomas's radio for the first time.
##   03: the work lamp is on, the tank is full, the road is plowed.

const ROAD_DOOR := Rect2(866, 300, 372, 350)
## The county plow on 03, heading away down the plowed road.
const PLOW := Vector2(1128, 522)


func setup() -> void:
	place_name = "Garage"
	walk_min = 120.0
	walk_max = 840.0
	make_player(130.0, 1)
	add_hotspot("door", Rect2(30, 330, 110, 320), "East wing", 120.0, -1)
	add_hotspot("cans", Rect2(160, 560, 110, 90), "Fuel cans", 220.0, -1)
	add_hotspot("snowcat", Rect2(330, 420, 450, 230), "Snowcat", 600.0, 1)
	add_hotspot("work_lamp", Rect2(520, 110, 80, 90), "Work lamp", 560.0)
	add_hotspot("road_doors", ROAD_DOOR, "Garage doors", 830.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"tuned":
			player.position.x = 800.0
			player.face(-1)
		_:
			player.position.x = 130.0
			player.face(1)


func _doors_open() -> bool:
	return freq == "03" or GameState.has("road_seen")


func is_dark() -> bool:
	return freq == "H"


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	Audio.stop_loop("snore", 0.4)
	Audio.stop_loop("drone", 0.6)
	if _doors_open():
		Audio.play_loop("wind", -18.0)
	else:
		Audio.play_loop("wind", -32.0)
	if freq == "03":
		Audio.play_loop("plow", -30.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if entered_from == "tuned":
		await _arrive_03()
	elif not GameState.has("garage_seen"):
		GameState.set_flag("garage_seen")
		await wait(0.3)
		await mara("Sollen's snowcat. Eleven miles of switchbacks to town, and this is the only thing that makes it in winter.")
	objective()


func _arrive_03() -> void:
	await wait(0.8)
	await mara("...Light.")
	await mara("The work lamp's on. The doors are open. And the road...")
	player.face(1)
	await wait(0.4)
	await mara("Plowed. Somebody plowed it.")
	await mara("No tree. The hum's lower in here. Colder. This isn't home.")
	await mara("It doesn't have to be. It just has to have a road.")


func on_hotspot(id: String) -> void:
	match id:
		"door":
			if freq == "03":
				await mara("No. I'm not wandering around this one. Ash Street.")
			else:
				Audio.sfx("door", -10.0)
				main.change_room("east_corridor", "from_garage")
		"cans":
			if freq == "03":
				await mara("Full. All of them. This Sollen fills his tanks.")
			else:
				GameState.set_flag("cans_checked")
				await mara("Empty. Empty. Empty. Of course.")
		"snowcat":
			await _snowcat()
		"work_lamp":
			if freq == "03":
				await mara("Somebody left the work lamp on. Somebody always does, in this one.")
			else:
				await mara("The work lamp. Dead bulb. Naturally.")
		"road_doors":
			await _road_doors()


func use_item(id: String, item: String) -> bool:
	if item == "keys" and id == "snowcat":
		await _snowcat_key()
		return true
	if item == "tuner":
		await examine_item("tuner")
		return true
	return false


func _snowcat() -> void:
	if freq == "03":
		GameState.set_flag("cat03_seen")
		await mara("Same snowcat. The gauge says full.")
		await mara("No key in it, though.")
		return
	if not GameState.has("knock_done"):
		await mara("Sollen's pride and joy. I've got nowhere to drive it at two in the morning.")
		return
	await _snowcat_key()


func _snowcat_key() -> void:
	if freq == "03":
		Audio.sfx("keys", -8.0)
		await mara("Sollen's key. Same snowcat, same key.")
		await _drive()
		return
	if not GameState.has("knock_done"):
		await mara("Not now. Where would I even go?")
		return
	if GameState.has("tank_checked"):
		await mara("The tank's empty. Turning the key won't change that.")
		return
	Audio.sfx("keys", -8.0)
	await wait(0.4)
	Audio.sfx("starter", -8.0)
	await wait(2.2)
	await mara("Nothing. Not even a cough.")
	await mara("Fuel gauge... empty. He's been meaning to fill it since October.")
	GameState.set_flag("tank_checked")
	await _check_stuck()


func _road_doors() -> void:
	if freq == "03":
		await mara("Plowed all the way down. I can hear the plow, way off.")
		return
	if GameState.has("road_seen"):
		await mara("Thirty tons of pine across the road. Nobody's driving down tonight.")
		return
	Audio.sfx("thunk", -4.0)
	await wait(0.3)
	GameState.set_flag("road_seen")
	ambience()
	await wait(0.6)
	await mara("Oh, come on.")
	await mara("A pine. Right across the road. Thirty tons of tree.")
	await _check_stuck()


## No fuel and no road: there's only one way down now.
func _check_stuck() -> void:
	if not (GameState.has("tank_checked") and GameState.has("road_seen")) or GameState.has("garage_checked"):
		objective()
		return
	GameState.set_flag("garage_checked")
	await mara("No fuel. No road. Eleven miles on foot, in this.")
	await mara("...Tomas's radio. 'Same tins. Different labels.'")
	await mara("Somewhere out there, the road's clear and the tank's full.")
	objective()


func can_tune() -> bool:
	return freq == "H" and GameState.has_item("tuner") and GameState.has("garage_checked")


func tune_refusal() -> String:
	if freq == "03":
		return "No. I'm done with it for now. Just drive."
	if GameState.has_item("tuner") and GameState.has("knock_done"):
		return "Not unless I have to. Let's see if the snowcat will get me down the mountain first."
	return super()


func tune() -> void:
	if not GameState.has("wrist_tape") and GameState.has_item("red_tape"):
		await mara("Wait.")
		Audio.sfx("tape_rip", -4.0)
		await wait(0.6)
		GameState.set_flag("wrist_tape")
		player.wrist_tape = Color("b8322c")
		await mara("If there's going to be more than one of me, I want to know which one is me.")
		# The flashlight rides on the Tuner's strap from here (2.4: they go together).
		await narrate("She winds a band of red tape tight around her left wrist, then clips the flashlight loop to the Tuner's carry strap to free a hand for the snowcat keys.")
		GameState.set_flag("light_on_strap")
	await mara("It changed for him in the dark. His lamp stopped it. So: light off.")
	await mara("Somewhere out there, the road's clear. Listen for a plow.")
	if not GameState.has("saw_detent"):
		GameState.set_flag("saw_detent")
		# The dial is printed to 99 but the wheel won't go past 9 (June frees it in 2.2).
		await narrate("The thumbwheel stops short of ten. A hairline crack catches the garage light inside the set.")
		await mara("Numbers printed to ninety-nine. Nine's as far as it will turn tonight.")
	if not GameState.has("pencil_h"):
		# The red pencil H under the strap (Blue finds it in 1991).
		GameState.set_flag("pencil_h")
		await narrate("In the unmarked gap between six and seven, a hum.")
		await mara("That hum is the one I'm standing in. I'm already home. Call it H.")
		await narrate("She pencils H beneath the carry strap, beside the unmarked part of the dial.")
	var st: String = await tuner_session(_garage_refusal, 1.4)
	if st == "03":
		await mara("A plow. Okay. Okay. Step into the dark...")
		await player.walk_to(820.0)
		GameState.set_flag("crossed_03")
		main.cross("03", "garage", "tuned")


func _garage_refusal(st: String) -> String:
	match st:
		"03":
			return ""
		"H":
			return "That hum is the one I'm standing in. I'm already home."
		"00":
			return "Nothing there. Just that flat tone."
		"01":
			return "Sollen asleep, and fire doors chained from the wrong side. No."
		"02":
			return "Rain on the road. Rain freezes. No."
		"04":
			return "Music a beat behind. Something about that one's wrong."
		"05":
			return "A police scanner. Not that one."
		"06":
			return "Wind through an open door. Whose door? No."
		"07":
			return "Something breathing right next to the radio. No. No."
		"08":
			return "Knocking. I'm not going anywhere near knocking."
		"09":
			return "A phone ringing and nobody picking up. No."
	return "No."


func _drive() -> void:
	await player.walk_to(600.0)
	Audio.sfx("door", -12.0)
	await mara("Ash Street. Eleven miles. Mom's house, and her porch light.")
	Audio.sfx("engine_start", -6.0)
	main.change_room("road_down")


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(cv, floor_y, Color("3f4446"), Color("323739"), Color("1a1d1e"))
	EnvironmentArt.wall_props(cv, str(name))
	cv.draw_rect(Rect2(Kit.L, floor_y, Kit.R - Kit.L, 400), Color("2c2f30"))
	cv.draw_rect(Rect2(300, floor_y + 20, 520, 14), Color("1f2223"))
	Kit.door(cv, Rect2(40, 340, 90, 310), Color("4a5258"), "EAST WING")
	_cans()
	_work_lamp()
	Vehicles.snowcat(cv, Vector2(552, 650), 1.0, t, {"body": Color("c8642a") if freq == "H" else Color("c86a34"), "snow": 0.3, "puddle": true})
	_road_doors_art()


func _cans() -> void:
	for i in 3:
		var x := 168.0 + i * 34.0
		cv.draw_rect(Rect2(x, 590, 30, 60), Color("a8322a"))
		cv.draw_rect(Rect2(x + 8, 582, 14, 8), Color("5a1a16"))
		cv.draw_line(Vector2(x + 4, 600), Vector2(x + 26, 640), Color("8a2620"), 2.0)


func _work_lamp() -> void:
	cv.draw_line(Vector2(560, 0), Vector2(560, 140), Color("1a1a1a"), 3.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(536, 170), Vector2(584, 170), Vector2(572, 140), Vector2(548, 140)]), Color("3a3f42"))
	if freq == "03":
		cv.draw_colored_polygon(PackedVector2Array([Vector2(536, 170), Vector2(584, 170), Vector2(800, 650), Vector2(320, 650)]), Color(1.0, 0.95, 0.8, 0.07))


func _road_doors_art() -> void:
	var r := ROAD_DOOR
	cv.draw_rect(r.grow(10), Color("1a1d1e"))
	if not _doors_open():
		cv.draw_rect(r, Color("5a6066"))
		for i in 11:
			cv.draw_line(Vector2(r.position.x, r.position.y + 28 + i * 30), Vector2(r.end.x, r.position.y + 28 + i * 30), Color("4a5056"), 3.0)
		cv.draw_rect(Rect2(r.get_center().x - 30, r.end.y - 40, 60, 10), Color("2a2f33"))
		return
	_outside(cv, 1.0)
	cv.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 26), Color("5a6066"))


## The night outside the open doors. Drawn on the room layer, then again on the
## glow layer at home, so moonlit snow stays brighter than the dark garage.
## While the Tuner holds a station, it's that station's road out there.
func _outside(ci: CanvasItem, a: float) -> void:
	var r := ROAD_DOOR
	var e := env()
	var st := shown()
	var ground := r.position.y + 170.0
	if e.state == "gone":
		Kit.vgrad(ci, r, Color(0.84, 0.86, 0.9, a), Color(0.95, 0.96, 0.97, a))
		return
	if e.story():
		Kit.vgrad(ci, Rect2(r.position, Vector2(r.size.x, 170)), Color(0.02, 0.03, 0.06, a), Color(0.1, 0.13, 0.22, a))
	else:
		var sky: Array = e.sky()
		Kit.vgrad(ci, Rect2(r.position, Vector2(r.size.x, 170)), Color(sky[0], a), Color(sky[1], a))
	Kit.stars(ci, Rect2(r.position, Vector2(r.size.x, 120)), 30, t)
	var g: Array = e.ground()
	ci.draw_rect(Rect2(r.position.x, ground, r.size.x, r.end.y - ground), Color(0.62, 0.68, 0.78, a) if e.story() else Color(g[1], a))
	# The road, curving away downhill.
	var road := Color(0.36, 0.38, 0.44, a) if st == "03" else Color(0.7, 0.75, 0.84, a)
	if not e.story():
		road = Color(e.road()[0], a)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y),
		Vector2(r.end.x, ground + 40), Vector2(r.position.x + 120, ground + 10)]), road)
	var pine := Color(0.03, 0.05, 0.07, a) if e.story() else Color(e.pine(Color(0.03, 0.05, 0.07)), a)
	for i in 6:
		var x := r.position.x + 20 + i * 64.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 18, ground + 4), Vector2(x + 18, ground + 4), Vector2(x, ground - 60)]), pine)
		if e.snowy() and not e.story() and not e.night():
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, ground - 30), Vector2(x + 8, ground - 30), Vector2(x, ground - 60)]),
				Color(0.92, 0.94, 0.97, a))
	if st == "H":
		# The fallen pine across the road.
		ci.draw_line(Vector2(r.position.x + 30, ground + 110), Vector2(r.end.x - 10, ground + 50), Color(0.2, 0.14, 0.1, a), 22.0)
		for k in 9:
			var px := r.position.x + 60 + k * 34.0
			var py := ground + 104 - k * 6.6
			ci.draw_line(Vector2(px, py), Vector2(px + 16, py - 34), Color(0.06, 0.12, 0.08, a), 8.0)
			ci.draw_line(Vector2(px, py), Vector2(px + 20, py + 26), Color(0.06, 0.12, 0.08, a), 8.0)
	elif st == "03":
		# Plow banks either side, and the plow itself far down the road.
		ci.draw_line(Vector2(r.position.x + 110, ground + 8), Vector2(r.end.x, ground + 34), Color(0.86, 0.9, 0.96, a), 6.0)
		Vehicles.plow_far(ci, PLOW, 0.55, a)
	elif e.fall == "leaves":
		for k in 18:
			ci.draw_rect(Rect2(r.position.x + 20 + Townscape.h(k * 3) * (r.size.x - 40), ground + 20 + Townscape.h(k * 7) * 150, 5, 3),
				Color(0.8, 0.45, 0.2, a))


func draw_glow(ci: CanvasItem) -> void:
	if freq == "03" and shown() == "03":
		var c := Vector2(560, 172)
		ci.draw_circle(c, 12.0, Color("fff3c4"))
		ci.draw_circle(c, 26.0, Color(1.0, 0.92, 0.6, 0.2))
		Vehicles.plow_lights(ci, PLOW, 0.55, t)
	elif _doors_open():
		_outside(ci, 0.3)
