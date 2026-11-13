extends StationRoom
## Act 1.5–1.6 — the basement, at home, in the dark. Tomas's box, a patch of
## fresh plaster nobody ordered, and the delivery door where she knocks.

var her_glass := 0.0
var her_shape := 0.0


func setup() -> void:
	place_name = "Basement"
	walk_min = 170.0
	walk_max = 1010.0
	make_player(250.0, 1)
	add_hotspot("stairs", Rect2(30, 300, 236, 350), "Stairs up", 200.0, -1)
	add_hotspot("shelves", Rect2(316, 330, 214, 320), "Shelves", 420.0)
	add_hotspot("crate", Rect2(566, 548, 162, 102), "Crate", 645.0)
	add_hotspot("tuner", Rect2(576, 494, 68, 60), "Radio", 645.0, 0, func() -> bool:
		return GameState.has("crate_open") and not GameState.has_item("tuner"))
	add_hotspot("walkman", Rect2(644, 500, 44, 54), "Walkman", 660.0, 0, func() -> bool: return GameState.has("crate_open"))
	add_hotspot("gap", Rect2(688, 500, 44, 54), "Dust", 690.0, 0, func() -> bool: return GameState.has("crate_open"))
	add_hotspot("boiler", Rect2(770, 300, 160, 350), "Boiler", 850.0)
	add_hotspot("plaster", Rect2(938, 326, 82, 140), "Wall", 960.0, 1)
	add_hotspot("delivery_door", Rect2(1050, 330, 140, 320), "Delivery door", 1010.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 250.0 if entry != "from_tunnel" else 860.0
	player.face(1 if entry != "from_tunnel" else -1)


func is_dark() -> bool:
	return true


func ambience() -> void:
	super()
	Audio.play_loop("drone", -30.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if entered_from == "from_tunnel":
		await _from_tunnel()
		return
	if not GameState.has("basement_seen"):
		GameState.set_flag("basement_seen")
		await wait(0.3)
		await mara("The basement light's been out since summer too. Of course.")
	objective()


## Act 2 ends and Act 3 begins: up the utility shaft behind the boiler, back
## at Tomas's box, with the dish turning overhead.
func _from_tunnel() -> void:
	Audio.play_loop("dish_motor", -22.0)
	await wait(0.8)
	await mara("The utility shaft. The basement. Behind the boiler.")
	await mara("Back where I started. Tomas's box. The dust where his notebook used to be.")
	await mara("And over my head, through three floors of concrete, the dish is turning.")
	GameState.set_flag("act2_done")
	GameState.set_flag("act3")
	await hud.card("ACT 3", "The futures", 2.0)
	await mara("And my flashlight's dead again. The batteries froze in the mine.")
	await mara("The boiler's warm. Cold batteries come back if you warm them. Dad used to say that.")
	objective()


## Act 3.5: the wall behind the boiler, the tin, Tomas's notebook.
func _break_wall() -> void:
	var g := GameState
	await mara("This plaster's still wet. Somebody sealed this tonight.")
	for i in 3:
		Audio.sfx("crack", -6.0 - i)
		hud.glitch(0.15)
		await wait(0.45)
	g.set_flag("wall_broken")
	await narrate("Behind the plaster, in the cavity: a biscuit tin. \"T.L.\" scratched in the lid. Not rusted. Not yet.")
	await mara("Twenty-six years from rusting shut.")
	Audio.sfx("thunk", -8.0)
	g.add_item("station_log")
	hud.toast("Got: Tomas's notebook")
	await narrate("Inside, wrapped in a bread bag: a notebook. STATION LOG, in Tomas's handwriting.")
	await _read_notebook()


func _read_notebook() -> void:
	var g := GameState
	await hud.read_doc("STATION LOG  ·  T. LIND", [
		"Day 1. Found Dad's field set behind his coats in the basement. Ma says leave it.\n\nInside the lid, in Dad's writing:  Λ   LIGHT = BALLAST.\n\nGot it working.\n\nOn 2.14 there's a whistle. Two notes, down then up. Dad's.",
		"Day 12. Every station has a Mara. Some are sad. Some are angry.",
		"Day 17. Henrik's away, dish parked all night. Crossed six times through the coal cellar. Chart flat.\n\n[A strip of chart paper, taped in. Flat.]\n\nDay 18. Henrik's 2.14 run, dish listening one till three. Didn't cross once. Chart climbing.\n\n[A second strip. Climbing.]\n\nIt's not us crossing. It's the dish listening.",
		"Day 30. The 2.14 voice isn't Mara. It sounds like her. It's from AFTER. Way after. It learned to talk from us.\n\nDay 38. HOME = 00. Our station isn't 00. None of them are. There's no Mara in 00.",
		"Oct 14, 1980. It's talking back. It says if I go to the trees, she'll come for me.\n\nI'm going to answer it.",
		"Mara —\n\nI'm not lost. I'm looking for Dad, and for you.\n\n%s\n\n— T." % Story.signoff_reply(),
	])
	if g.has("notebook_read"):
		return
	g.set_flag("notebook_read")
	await mara("The notebook missing from his crate. Somebody walled it up behind the boiler. Tonight.")
	await mara("Dad's field set. The Tuner was Dad's. Tomas didn't build it. He found it.")
	await mara("Day 17 and Day 18. I can do that. The control room has a chart recorder of its own.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"stairs":
			Audio.sfx("step", -10.0)
			main.change_room("east_corridor", "from_basement")
		"shelves":
			await mara("Lost and found. Twenty years of mittens nobody came back for.")
		"crate":
			await _crate()
		"tuner":
			await _take_tuner()
		"walkman":
			await _walkman()
		"gap":
			GameState.set_flag("saw_gap")
			await mara("A clean rectangle in the dust. Something notebook-sized was sitting here until...")
			await mara("Recently. Somebody's been in Tomas's box. Tonight.")
		"boiler":
			if GameState.has("act3") and not GameState.has("batteries_warm"):
				await mara("Warm. Warm enough for a pair of frozen batteries. If I hold the flashlight against it.")
			else:
				await mara("The boiler. Ticking, like it's thinking about something.")
		"plaster":
			GameState.set_flag("saw_plaster")
			if GameState.has("wall_broken"):
				await mara("The hole I made. Wet plaster on the floor.")
			elif GameState.has("knows_tin"):
				await mara("Behind the boiler. Fresh plaster, still damp, and the tin's in there. I need something to break it with.")
			else:
				await mara("Fresh plaster. The edges are still damp.")
				await mara("Facilities hasn't fixed anything in this building since summer.")
		"delivery_door":
			if GameState.has("knock_done"):
				await mara("She's gone. I'm not opening it to check.")
			else:
				await mara("The delivery door. Frosted glass, bolted. Nobody's delivered anything since the budget cuts.")


func use_item(id: String, item: String) -> bool:
	if id == "boiler" and item == "flashlight_cold":
		GameState.remove_item("flashlight_cold")
		await narrate("She props the batteries against the boiler's warm flank for a minute, then back in.")
		Audio.sfx("click", -6.0)
		GameState.add_item("flashlight")
		GameState.set_flag("batteries_warm")
		hud.toast("Got: Flashlight")
		await mara("Light. Okay. Dad was right about something.")
		await mara("The dish is turning. Whatever's happening, it's happening in the control room.")
		objective()
		return true
	if id == "plaster" and item == "fire_axe":
		if not GameState.has("knows_tin"):
			await mara("Break open a wall because it's damp? Not without a reason.")
		elif GameState.has("wall_broken"):
			await mara("It's open.")
		else:
			await _break_wall()
		return true
	if id == "crate" and item == "station_log":
		await mara("Not yet. I'm keeping it with me.")
		return true
	return false


func _crate() -> void:
	if GameState.has("knock_done"):
		await mara("Tomas's things. I'll come back for the rest. I promise.")
		return
	if GameState.has("crate_open"):
		await mara("His things. His radio, his Walkman, his blanket.")
		return
	await narrate("A wooden crate. TOMAS, in marker. My handwriting.")
	await mara("I brought it down here because I couldn't stand it at home. I haven't opened it since.")
	Audio.sfx("thunk", -6.0)
	GameState.set_flag("crate_open")
	await wait(0.4)
	await mara("His radio. His Walkman. The blanket from his bed.")


func _walkman() -> void:
	if GameState.has("heard_day41"):
		await mara("Day 41. I don't want to hear it again.")
		return
	await narrate("A yellow Walkman. The tape inside says \"DAY 41\" in marker.")
	Audio.sfx("click", -6.0)
	Audio.play_loop("tape_hiss", -16.0, 0.3)
	await wait(0.7)
	await say("TOMAS (TAPE)", "Day 41.")
	await say("TOMAS (TAPE)", "Station 12 has a version of me where nothing happened. Mara's there too. She looks happier.")
	await say("TOMAS (TAPE)", "And the lady on 2.14 is back. She says she's stuck somewhere dark. She sounds like Mara.")
	await say("TOMAS (TAPE)", "Going to check something tonight.")
	Audio.stop_loop("tape_hiss", 0.4)
	Audio.sfx("click", -6.0)
	GameState.set_flag("heard_day41")
	await mara("Forty-one days. He was doing this for forty-one days, and I never knew.")
	if GameState.has_item("tuner"):
		await mara("Station 12. His dial stops at 09.")


func _take_tuner() -> void:
	GameState.add_item("tuner")
	hud.toast("Got: Tomas's radio")
	Audio.sfx("click", -8.0)
	await mara("Tomas's radio. He built it in his room. He'd never let me touch it.")
	await mara("'HOME = 00' on the back. In his handwriting.")
	await _knock()


## Act 1.6: someone at the delivery door who sounds exactly like Mara.
func _knock() -> void:
	await wait(0.8)
	for i in 3:
		Audio.sfx("knock", -6.0)
		await wait(0.55)
	player.face(1)
	await wait(0.4)
	create_tween().tween_property(self, "her_glass", 1.0, 1.2)
	await wait(0.6)
	create_tween().tween_property(self, "her_shape", 1.0, 1.4)
	await wait(1.0)
	await say("HER", "Mara.")
	await mara("...Who's there?")
	await say("HER", "You found his radio. You'll need me to use it.")
	if GameState.story.get("ANSWERED") == true:
		await say("HER", "She told you not to let me in. She tells everyone that.")
	else:
		await say("HER", "You cut the power on me. Smart. It didn't help.")
	await mara("That's my voice. Why is that my voice?")
	await mara("I'm not opening that door. Not a chance.")
	await say("HER", "Ash Street. Your mother's house. I'll be in the one with the lights off.")
	for i in 5:
		Audio.sfx("step_snow", -10.0 - i * 3.0)
		await wait(0.5)
	create_tween().tween_property(self, "her_shape", 0.0, 1.0)
	await wait(0.6)
	create_tween().tween_property(self, "her_glass", 0.0, 1.5)
	await wait(1.0)
	GameState.set_flag("knock_done")
	await mara("Her wrist was bandaged. Right where...")
	await mara("The one with the lights off. Mom never turns her lights off. She leaves the porch light on for Tomas. Every night, three years.")
	await mara("I have to get down there before she does.")
	objective()


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(cv, floor_y, Color("3a3a36"), Color("2e2e2b"), Color("1b1b19"))
	EnvironmentArt.wall_props(cv, str(name))
	cv.draw_rect(Rect2(Kit.L, floor_y, Kit.R - Kit.L, 400), Color("2a2926"))
	for i in 12:
		cv.draw_line(Vector2(Kit.L + i * 190.0, 30), Vector2(Kit.L + i * 190.0 + 40, floor_y - 130), Color(0, 0, 0, 0.08), 2.0)
	_stairs()
	_shelves()
	_crate_art()
	_boiler()
	_plaster()
	_delivery_door()


func _stairs() -> void:
	var col := Color("4a4038")
	for i in 9:
		var x := 40.0 + i * 26.0
		var y := 300.0 + i * 39.0
		cv.draw_rect(Rect2(x, y, 60, 10), col)
		cv.draw_rect(Rect2(x, y + 10, 8, 29), col.darkened(0.3))
	cv.draw_line(Vector2(40, 290), Vector2(270, 640), Color("2a241f"), 8.0)
	cv.draw_line(Vector2(60, 230), Vector2(290, 580), Color("6a6f73"), 3.0)


func _shelves() -> void:
	var r := Rect2(320, 340, 206, 310)
	cv.draw_rect(Rect2(r.position.x, r.position.y, 8, r.size.y), Color("5a5048"))
	cv.draw_rect(Rect2(r.end.x - 8, r.position.y, 8, r.size.y), Color("5a5048"))
	for i in 4:
		var y := r.position.y + 20 + i * 76
		cv.draw_rect(Rect2(r.position.x, y + 56, r.size.x, 6), Color("5a5048"))
		var cols := [Color("8a7a5a"), Color("6a5a48"), Color("7a6a50")]
		cv.draw_rect(Rect2(r.position.x + 14, y + 16, 70, 40), cols[i % 3])
		cv.draw_rect(Rect2(r.position.x + 96, y + 26, 54, 30), cols[(i + 1) % 3])
		cv.draw_rect(Rect2(r.position.x + 156, y + 10, 36, 46), cols[(i + 2) % 3])


func _crate_art() -> void:
	var r := Rect2(570, 550, 154, 100)
	cv.draw_rect(r, Color("7a6040"))
	for i in 3:
		cv.draw_line(Vector2(r.position.x, r.position.y + 30 + i * 30), Vector2(r.end.x, r.position.y + 30 + i * 30), Color("5a4430"), 3.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 62), "TOMAS", 18, Color("2a2018"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if not GameState.has("crate_open"):
		cv.draw_rect(Rect2(r.position.x - 4, r.position.y - 8, r.size.x + 8, 10), Color("6a5236"))
		return
	# Lid leaning against the crate; Tomas's things on top.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(724, 650), Vector2(736, 650), Vector2(770, 560), Vector2(758, 556)]), Color("6a5236"))
	cv.draw_rect(Rect2(574, 536, 146, 16), Color("4a5a6a"))
	if not GameState.has_item("tuner"):
		cv.draw_rect(Rect2(582, 508, 56, 32), Color("4a5a3a"))
		cv.draw_rect(Rect2(588, 514, 32, 10), Color("8a6a3a"))
		cv.draw_line(Vector2(630, 508), Vector2(642, 482), Color("9aa0a6"), 2.0)
		cv.draw_rect(Rect2(586, 530, 20, 6), Color("e6dfc8"))
	cv.draw_rect(Rect2(650, 516, 30, 22), Color("d8b830"))
	cv.draw_rect(Rect2(656, 520, 18, 10), Color("2a2a2a"))
	cv.draw_rect(Rect2(694, 524, 28, 14), Color("5a6a7a"))
	cv.draw_rect(Rect2(696, 526, 24, 10), Color("6e7e8e"))


func _boiler() -> void:
	cv.draw_rect(Rect2(780, 360, 140, 290), Color("5a4a40"))
	cv.draw_circle(Vector2(850, 360), 70.0, Color("5a4a40"))
	cv.draw_rect(Rect2(830, 540, 40, 30), Color("2a1f1a"))
	cv.draw_line(Vector2(850, 290), Vector2(850, 20), Color("4a4038"), 18.0)
	cv.draw_line(Vector2(780, 420), Vector2(700, 420), Color("4a4038"), 10.0)
	cv.draw_line(Vector2(700, 420), Vector2(700, 20), Color("4a4038"), 10.0)
	cv.draw_circle(Vector2(850, 470), 14.0, Color("c8c3b0"))
	cv.draw_line(Vector2(850, 470), Vector2(858, 462), Color("8a1d1d"), 2.0)


func _plaster() -> void:
	var r := Rect2(944, 332, 70, 128)
	cv.draw_rect(r, Color("8a8a80"))
	cv.draw_rect(r, Color("5a5a50"), false, 3.0)
	cv.draw_line(r.position + Vector2(8, 20), r.position + Vector2(40, 18), Color("9a9a90"), 2.0)
	cv.draw_line(r.position + Vector2(14, 70), r.position + Vector2(60, 74), Color("9a9a90"), 2.0)


func _delivery_door() -> void:
	var r := Rect2(1060, 340, 120, 310)
	cv.draw_rect(r.grow(8), Color("15191b"))
	cv.draw_rect(r, Color("4a5258"))
	cv.draw_rect(Rect2(1074, 380, 92, 120), Color("1d2427"))
	cv.draw_rect(Rect2(1070, 560, 100, 10), Color("9aa3a8"))
	cv.draw_rect(Rect2(1150, 470, 22, 10), Color("6a6f73"))


## The frosted glass lights up from outside; her shape presses against it.
func draw_glow(ci: CanvasItem) -> void:
	if her_glass <= 0.01:
		return
	var g := Rect2(1074, 380, 92, 120)
	ci.draw_rect(g, Color(0.62, 0.7, 0.82, 0.75 * her_glass))
	ci.draw_rect(g, Color(0.82, 0.88, 0.95, 0.25 * her_glass), false, 3.0)
	if her_shape <= 0.01:
		return
	# Frosted glass: the shape is drawn several times, growing and fading, so its
	# edges blur. Only the hand pressed flat to the pane is sharp.
	for k in range(4, -1, -1):
		var grow := k * 3.0
		var a := her_shape * (0.85 if k == 0 else 0.13)
		var dark := Color(0.06, 0.07, 0.1, a)
		ci.draw_circle(Vector2(1118, 422), 17.0 + grow, dark)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(1086 - grow, 500), Vector2(1150 + grow, 500),
			Vector2(1140 + grow, 448 - grow), Vector2(1096 - grow, 448 - grow)]), dark)
	var hand := Color(0.05, 0.06, 0.09, 0.95 * her_shape)
	ci.draw_line(Vector2(1146, 470), Vector2(1150, 420), hand, 9.0)
	ci.draw_circle(Vector2(1150, 412), 8.0, hand)
	for f in 4:
		ci.draw_line(Vector2(1144 + f * 4, 408), Vector2(1143 + f * 5, 396), hand, 3.0)
	# The wrist wrapped in a pale bandage.
	ci.draw_line(Vector2(1147, 448), Vector2(1148, 434), Color(0.9, 0.9, 0.86, 0.7 * her_shape), 11.0)
