extends StationRoom
## Act 1.2 — the control room. After 2:14, Mara's own body is slumped against
## the console. Four things to inspect: the wrist, the watch, the pocket, and
## the transmitter's empty key slot.

const BODY_X := 700.0
const CHECKS := ["inspected_wrist", "inspected_watch", "inspected_pocket", "inspected_transmitter"]

var body: Actor
var snow: Snowfall


func setup() -> void:
	place_name = "Control room"
	walk_min = 110.0
	walk_max = 1010.0
	snow = Snowfall.new()
	snow.area = Rect2(302, 158, 756, 248)
	snow.count = 110
	snow.wind = 24.0
	add_child(snow)
	body = add_actor("body", BODY_X, 1)
	body.visible = _body_here()
	make_player(300.0, 1)

	var here := func() -> bool: return _body_here()
	add_hotspot("door", Rect2(22, 330, 108, 320), "Corridor", 95.0, -1)
	add_hotspot("chalkboard", Rect2(128, 222, 164, 190), "Chalkboard", 230.0)
	add_hotspot("window", Rect2(300, 150, 760, 262), "Window")
	add_hotspot("console", Rect2(300, 470, 700, 132), "Console", 470.0)
	add_hotspot("transmitter", Rect2(1044, 296, 152, 350), "Transmitter", 1010.0, 1)
	add_hotspot("body", Rect2(612, 520, 216, 136), "Her", 600.0, 1, here)
	add_hotspot("body_face", Rect2(646, 536, 52, 52), "Her face", 600.0, 1, here)
	add_hotspot("body_wrist", Rect2(618, 616, 58, 42), "Her wrist", 600.0, 1, here)
	add_hotspot("body_pocket", Rect2(676, 590, 36, 34), "Her jacket pocket", 600.0, 1, here)
	add_hotspot("body_watch", Rect2(712, 608, 48, 40), "Her watch", 600.0, 1, here)


func _body_here() -> bool:
	return GameState.has("heard_transmission")


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
		GameState.set_objective("Look at her. Look closely.")


func on_hotspot(id: String) -> void:
	match id:
		"door":
			Audio.sfx("door", -10.0)
			main.change_room("corridor", "from_control")
		"chalkboard":
			await mara("Sollen's survey schedule. Hydrogen line, every clear night until Christmas.")
			await mara("He always leaves that corner empty. Says it's for discoveries.")
		"window":
			await mara("The dish. Pointed at nothing, listening to everything.")
		"console":
			if _body_here():
				await mara("I can't look at the console. I can only look at her.")
			else:
				await mara("Sollen's console. Every knob labeled in his tiny capitals.")
		"transmitter":
			if _body_here():
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
	Kit.door(self, Rect2(30, 340, 92, 310), DOOR, "CORRIDOR")
	_chalkboard()
	Kit.night_view(self, Rect2(302, 158, 756, 248), t, 700.0, 1.25)
	_console()
	_transmitter()


func draw_fore(ci: CanvasItem) -> void:
	Kit.window_frame(ci, Rect2(302, 158, 756, 248), 3)


func _chalkboard() -> void:
	var r := Rect2(132, 226, 156, 182)
	draw_rect(r.grow(6), Color("5a4532"))
	draw_rect(r, Color("1c2a24"))
	var chalk := Color(0.9, 0.92, 0.88, 0.75)
	Kit.text(self, Vector2(142, 252), "H-LINE SURVEY", 14, chalk)
	Kit.text(self, Vector2(142, 280), "NOV  2 · 9 · 16", 13, chalk)
	Kit.text(self, Vector2(142, 304), "NOV 23 · 30", 13, chalk)
	Kit.text(self, Vector2(142, 328), "DEC  7 · 14 · 21", 13, chalk)
	Kit.text(self, Vector2(142, 368), "1420.4 MHz", 13, chalk)
	draw_rect(Rect2(232, 238, 48, 40), Color(0.9, 0.92, 0.88, 0.12), false, 1.0)


func _console() -> void:
	var top := 470.0
	draw_colored_polygon(PackedVector2Array([Vector2(296, top + 18), Vector2(1004, top + 18), Vector2(990, top), Vector2(310, top)]), Color("3a444b"))
	draw_rect(Rect2(296, top + 18, 708, 162), Color("2a3238"))
	draw_rect(Rect2(296, top + 18, 708, 162), Color("161b1f"), false, 3.0)
	for i in 3:
		var sx := 330.0 + i * 230.0
		var scr := Rect2(sx, top + 34, 120, 62)
		draw_rect(scr, Color("06120c"))
		var pts := PackedVector2Array()
		for k in 31:
			var x := scr.position.x + k * 4.0
			var amp := 0.0 if GameState.emergency else 16.0
			pts.append(Vector2(x, scr.get_center().y + sin(k * 0.5 + t * (2.0 + i)) * amp * (0.4 + 0.2 * i)))
		draw_polyline(pts, Color(0.3, 1.0, 0.55, 0.85), 1.5)
		for k in 4:
			draw_circle(Vector2(sx + 140 + (k % 2) * 30, top + 46 + (k / 2) * 30), 9.0, Color("15191d"))


func _transmitter() -> void:
	var r := Rect2(1048, 300, 144, 342)
	draw_rect(r, Color("2b3339"))
	draw_rect(r, Color("12171b"), false, 3.0)
	Kit.text(self, Vector2(r.position.x, 326), "TX-1", 16, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for i in 2:
		var m := Rect2(1064 + i * 62, 344, 50, 40)
		draw_rect(m, Color("e8e2cc"))
		var a := -2.4 + 0.3 * sin(t * 0.7 + i)
		draw_line(m.get_center() + Vector2(0, 14), m.get_center() + Vector2(0, 14) + Vector2(cos(a), sin(a)) * 22.0, Color("1c1c1c"), 1.5)
	draw_rect(Rect2(1094, 428, 52, 30), Color("15191d"))
	draw_rect(Rect2(1110, 438, 20, 8), Color("050607"))
	Kit.text(self, Vector2(1080, 476), "TRANSMIT KEY", 11, Color("9aa3a0"), HORIZONTAL_ALIGNMENT_CENTER, 80)
