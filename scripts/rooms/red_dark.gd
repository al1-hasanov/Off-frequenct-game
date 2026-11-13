extends Room
## Act 3.7 — Red. The white in 1991 cut to black, and the black doesn't end.
##
## The player is Red Mara now: the Mara swept out of the Ash Street kitchen at
## the switch (2.4). Eighty-One took her Tuner in the scuffle; her flashlight
## is on a kitchen floor in some other station. She has no light and no dial,
## only the red tape on her wrist and the dark that every station shares. For
## her it is still 2:14.
##
## She comes to at the foot of her father's basement stairs, and finds her way
## by ear: every station's sounds come through the walls. Walk toward one, away
## from the others. A wrong one walks her in a circle back to the stairs.

## At each turning: [left, ahead, right], the right one, and the loops to play.
const TURNINGS := [
	{"names": ["The Lunds, arguing about a coat", "A farm report, on a kitchen radio", "A jukebox: the Lantern's"],
		"right": 1, "loops": [["voice", -26.0], ["voice_short", -18.0], ["radio_music", -24.0]]},
	{"names": ["The farm report, fainter", "A plow, scraping", "A dog, barking"],
		"right": 0, "loops": [["voice_short", -22.0], ["plow", -24.0], ["barking", -26.0]]},
	{"names": ["A phone ringing in an empty room", "A typewriter", "The farm report, and June's voice"],
		"right": 2, "loops": [["ring", -28.0], ["typewriter", -26.0], ["voice_short", -16.0]]},
]
const SIDES := ["left", "ahead", "right"]
const SPOTS := [Vector2(150, 470), Vector2(640, 330), Vector2(1130, 470)]
const WHERE := ["on the left", "ahead, in the middle", "on the right"]


## The ? button at turning n (1..3): exactly where the farm report is.
static func hint_for(n: int) -> String:
	if n < 1 or n > TURNINGS.size():
		return ""
	var tn: Dictionary = TURNINGS[n - 1]
	var i := int(tn.right)
	return "Turning %d of 3. Follow the farm report: it's %s. Tap \"%s\"." % [n, WHERE[i], tn.names[i]]

## 0: the basement, by touch. 1..3: the turnings in the dark.
var stage := 0
## The flicker that lights her wrist, once.
var closeup := 0.0
var shot := ""


func setup() -> void:
	animated_back = false
	shows_hud = true
	place_name = "The dark"
	walk_min = 100.0
	walk_max = 1180.0
	make_player(640.0, 1)
	player.wrist_tape = Color("b8322c")
	GameState.red_turning = 0
	add_hotspot("stairs", Rect2(1030, 300, 230, 350), "Stairs", 1040.0, 1, func() -> bool: return stage == 0)
	add_hotspot("coats", Rect2(170, 300, 170, 300), "Coats", 300.0, -1, func() -> bool: return stage == 0)
	add_hotspot("bench", Rect2(470, 470, 300, 120), "Workbench", 620.0, 1, func() -> bool: return stage == 0)
	add_hotspot("gap", Rect2(840, 330, 150, 90), "Shelf", 900.0, 1, func() -> bool: return stage == 0)
	add_hotspot("listen", Rect2(560, 250, 160, 160), "Listen", NAN, 0, func() -> bool: return stage == 0 and GameState.has("red_coats"))
	for i in 3:
		add_hotspot(SIDES[i], Rect2(SPOTS[i] - Vector2(110, 120), Vector2(220, 240)), "", NAN, 0, func() -> bool: return stage > 0)


func enter(entry: String) -> void:
	entered_from = entry


func is_dark() -> bool:
	return true


func score_quiet() -> bool:
	return true


func static_key() -> String:
	return str(stage)


func ambience() -> void:
	Audio.play_loop("breath", -22.0)
	Audio.play_loop("drone", -30.0)
	Audio.set_environment("basement", freq)


func on_arrive() -> void:
	ambience()
	if not GameState.has("red_woke"):
		GameState.set_flag("red_woke")
		await wait(1.2)
		await narrate("Somebody breathes in the dark.")
		await mara("...Hello?")
		await mara("Let go of me— She had my radio. She had my face, and my radio, and the light went...")
		await wait(0.4)
		Audio.sfx("match", -10.0)
		shot = "wrist"
		var tw := create_tween()
		tw.tween_property(self, "closeup", 1.0, 0.25)
		await tw.finished
		await wait(1.9)
		tw = create_tween()
		tw.tween_property(self, "closeup", 0.0, 0.5)
		await tw.finished
		await mara("Red. My tape. I'm still me.")
		await mara("Stairs under my hand. Wood. The fourth one creaks.")
		await mara("This is Dad's basement. On Ash Street. I'd know it blind.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"stairs":
			await mara("Up is the kitchen. And the kitchen's where she is.")
		"coats":
			GameState.set_flag("red_coats")
			await mara("Wool. His coats, still on their hooks. The big one smells of pipe and oil.")
			await mara("Dad's coat. Oh, Ma. You never could.")
			await mara("Listen. If I can't see, I can listen.")
			objective()
		"bench":
			await mara("His workbench. The vise. A jar of screws I sorted when I was six.")
		"gap":
			await mara("The shelf over the bench, and a gap in the dust where his field set sat.")
			await mara("Until Tomas found it.")
		"listen":
			await _listen()
		"left", "ahead", "right":
			await _choose(SIDES.find(id))


func use_item(_id: String, _item: String) -> bool:
	return false


func _listen() -> void:
	await narrate("Every station's sounds come through the walls. Walk toward one, away from the others.")
	await mara("June's shop. If anybody in any Halvard has a radio on, it's June. Follow the farm report.")
	await _turning(1)


func _turning(n: int) -> void:
	stage = n
	GameState.red_turning = n
	var tn: Dictionary = TURNINGS[n - 1]
	for loop in ["voice", "voice_short", "radio_music", "plow", "barking", "ring", "typewriter"]:
		Audio.stop_loop(loop, 0.5)
	for l in tn.loops:
		Audio.play_loop(l[0], l[1], 0.8)
	for i in 3:
		var h := get_hotspot(SIDES[i])
		h.label = str(tn.names[i])
	if n == 3 and not GameState.has("red_whistle"):
		GameState.set_flag("red_whistle")
		await wait(0.8)
		Audio.sfx("whistle", -4.0)
		await narrate("A whistle, out of the dark ahead of her. Two notes: down, then up.")
		await mara("...Dad?")
		await wait(1.0)
		await narrate("It doesn't come again.")
	await narrate("Left: %s. Ahead: %s. Right: %s." % [tn.names[0], tn.names[1], tn.names[2]])
	objective()


func _choose(i: int) -> void:
	var tn: Dictionary = TURNINGS[stage - 1]
	await player.walk_to(SPOTS[i].x)
	if i != int(tn.right):
		Audio.sfx("step", -10.0)
		await narrate("The sound slides round behind her, and the floor under her feet is wood again. The foot of the stairs.")
		await mara("Wrong one. Again. Listen properly, Mara.")
		player.position.x = 640.0
		await _turning(1)
		return
	if stage < 3:
		await mara("Closer. Keep going.")
		player.position.x = 640.0
		await _turning(stage + 1)
		return
	# Into Pike Radio, in a station where the power's out.
	for loop in ["voice", "voice_short", "radio_music", "plow", "barking", "ring", "typewriter", "breath"]:
		Audio.stop_loop(loop, 0.6)
	GameState.set_flag("red_found_june")
	GameState.red_turning = 0
	await mara("A shop. Radios on shelves, under my hands. Pike Radio. But nobody's here, and the power's out.")
	main.cross("44", "pike_dark", "from_dark", true)


# --- drawing --------------------------------------------------------------------------

func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("07080a"))
	if stage > 0:
		# Nothing but the dark every station shares.
		for i in 60:
			var p := Vector2(Kit.L + Townscape.h(i * 7) * (Kit.R - Kit.L), Townscape.h(i * 13) * 720.0)
			cv.draw_circle(p, 1.0 + Townscape.h(i) * 1.5, Color(0.3, 0.32, 0.4, 0.15))
		return
	# The Lind basement, as her hands find it.
	var c := Color("2a2622")
	cv.draw_rect(Rect2(Kit.L, 650, Kit.R - Kit.L, 120), Color("161412"))
	for k in 9:
		var x := 1040.0 + k * 24.0
		cv.draw_rect(Rect2(x, 640 - k * 38.0, 70, 10), c)
	for k in 4:
		var x := 190.0 + k * 40.0
		cv.draw_line(Vector2(x, 300), Vector2(x, 316), Color("4a4440"), 3.0)
		cv.draw_colored_polygon(PackedVector2Array([Vector2(x - 18, 316), Vector2(x + 18, 316), Vector2(x + 24, 560), Vector2(x - 24, 560)]),
			[Color("3a3428"), Color("2a2a30"), Color("3a2a24"), Color("30302a")][k])
	cv.draw_rect(Rect2(470, 500, 300, 16), Color("3a2e24"))
	cv.draw_line(Vector2(480, 516), Vector2(480, 650), c, 6.0)
	cv.draw_line(Vector2(760, 516), Vector2(760, 650), c, 6.0)
	cv.draw_rect(Rect2(600, 470, 40, 30), Color("4a4440"))
	cv.draw_rect(Rect2(840, 380, 150, 8), c)
	cv.draw_rect(Rect2(850, 350, 30, 30), Color("3a3428"))
	cv.draw_rect(Rect2(950, 356, 30, 24), Color("3a3428"))


func draw_glow(ci: CanvasItem) -> void:
	if stage > 0:
		# Where each sound comes from: rings spreading out of the dark.
		var tn: Dictionary = TURNINGS[stage - 1]
		for i in 3:
			var c: Vector2 = SPOTS[i]
			var loud: float = 1.0 if i == int(tn.right) else 0.7
			for k in 3:
				var r := fposmod(t * 40.0 + k * 40.0, 120.0)
				var a := (1.0 - r / 120.0) * 0.3 * loud
				ci.draw_arc(c, r + 10.0, 0.0, TAU, 32, Color(0.75, 0.8, 0.95, a), 2.0)
			# What she hears from there, written in the middle of its rings.
			var w := 320.0
			var x0 := clampf(c.x - w * 0.5, 8.0, 1272.0 - w)
			Kit.text(ci, Vector2(x0, c.y - 18), str(SIDES[i]).to_upper(), 13, Color(0.75, 0.8, 0.95, 0.55), HORIZONTAL_ALIGNMENT_CENTER, w)
			Kit.text(ci, Vector2(x0 + 1, c.y + 35), str(tn.names[i]), 18, Color(0, 0, 0, 0.8), HORIZONTAL_ALIGNMENT_CENTER, w)
			Kit.text(ci, Vector2(x0, c.y + 34), str(tn.names[i]), 18, Color(0.86, 0.89, 0.98, 0.9), HORIZONTAL_ALIGNMENT_CENTER, w)
	Act3.draw_wrist(ci, Color("b8322c"), closeup)
