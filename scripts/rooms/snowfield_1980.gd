extends Room
## Prologue P1 — the snowfield, October 14, 1980.
## Mara turns her back for three seconds to lock the gate, and Tomas is gone.

var tomas: Actor
var figure: Actor
var snow: Snowfall


func setup() -> void:
	place_name = "Halvard Observatory · October 14, 1980"
	base_tint = Color(0.82, 0.87, 1.0)
	walk_min = 150.0
	walk_max = 760.0
	walk_top = 470.0
	figure = add_actor("silhouette", 1188.0, -1)
	figure.position.y = 486.0
	figure.scale = Vector2(0.42, 0.42)
	figure.visible = false
	tomas = add_actor("tomas", 1010.0, 1)
	make_player(230.0, 1, "mara_1980")
	player.step_sound = "step_snow"
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 790)
	snow.count = 230
	snow.wind = 42.0
	add_child(snow)

	add_hotspot("tomas", Rect2(962, 470, 100, 190), "Tomas", 760.0, 1, func() -> bool: return tomas.visible)
	add_hotspot("padlock", Rect2(370, 528, 64, 64), "Gate padlock", 420.0, -1)
	add_hotspot("truck", Rect2(10, 480, 235, 170), "The truck", 250.0, -1)
	add_hotspot("observatory", Rect2(880, 230, 330, 240), "The observatory")


func enter(_entry: String) -> void:
	GameState.set_clock("2:12")


func on_arrive() -> void:
	Audio.stop_all(0.3)
	Audio.play_loop("wind", -10.0)
	if tomas.visible:
		Audio.play_loop("static", -30.0)
	if GameState.has("p1_started"):
		return
	GameState.set_flag("p1_started")
	GameState.set_objective("Get Tomas into the truck.")
	await wait(0.7)
	await mara("Tomas!")


func on_hotspot(id: String) -> void:
	match id:
		"tomas":
			if not GameState.has("p1_talked"):
				tomas.face(-1)
				await say("TOMAS", "Mara. It's talking back.")
				await mara("It's two in the morning. Get in the truck.")
				await say("TOMAS", "Two more minutes. It knows my name.")
				await mara("Two minutes. I'm locking the gate.")
				tomas.face(1)
				GameState.set_flag("p1_talked")
				GameState.set_objective("Lock the gate.")
			else:
				await say("TOMAS", "Shh. It's saying something.")
		"padlock":
			if not GameState.has("p1_talked"):
				await mara("I'm not locking him out here.")
			else:
				await _vanish()
		"truck":
			await mara("Engine's running, heater's on. He'll come. He always comes.")
		"observatory":
			await mara("The dish never sleeps. Neither does Tomas, apparently.")


func _vanish() -> void:
	player.face(-1)
	Audio.sfx("lock", -4.0)
	await mara("Come on, you stupid thing...")
	await wait(1.0)
	Audio.stop_loop("static", 0.05)
	tomas.visible = false
	await wait(0.45)
	# One frame at the treeline that almost nobody will see. Ending E explains it.
	figure.visible = true
	await wait(0.07)
	figure.visible = false
	await wait(1.2)
	player.face(1)
	await wait(0.6)
	await mara("Tomas?")
	player.walk_to(700.0)
	await wait(0.9)
	await mara("TOMAS!")
	await narrate("His footprints run halfway across the snow, and stop.")
	GameState.set_flag("p1_done")
	GameState.set_objective("")
	Audio.stop_all(2.5)
	await hud.fade_out(2.2)
	await hud.card("OFF FREQUENCY", "", 3.2, true)
	await hud.card("October 14, 1983", "Three years later", 2.6)
	GameState.set_clock("1:40")
	GameState.set_flag("radio_on")
	GameState.set_objective("Read Sollen's note on the control-room door.")
	main.change_room("corridor", "start")


func draw_back() -> void:
	Kit.vgrad(self, Rect2(Kit.L, -100, Kit.R - Kit.L, 580), Color("03050c"), Color("1a2442"))
	Kit.stars(self, Rect2(Kit.L, 0, Kit.R - Kit.L, 330), 110, t)
	draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 470), Vector2(-200, 330), Vector2(80, 400), Vector2(360, 300), Vector2(640, 410),
		Vector2(860, 320), Vector2(1180, 400), Vector2(1450, 310), Vector2(Kit.R, 420), Vector2(Kit.R, 470)]), Color("0f1528"))
	var b := Color("0b0f1a")
	draw_rect(Rect2(900, 380, 260, 95), b)
	draw_rect(Rect2(930, 342, 120, 40), b)
	draw_rect(Rect2(950, 410, 22, 16), Color("e8a54b"))
	Kit.dish(self, Vector2(1090, 382), 1.2, b)
	Kit.pines(self, 474.0, Color("080c14"))
	Kit.vgrad(self, Rect2(Kit.L, 470, Kit.R - Kit.L, 320), Color("a9b6cc"), Color("6f7d96"))
	_truck()
	_fence()
	for i in 27:
		var x := 300.0 + i * 26.0
		var y := 654.0 + (4.0 if i % 2 == 0 else -2.0)
		draw_set_transform(Vector2(x, y), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 6.5, Color(0.33, 0.39, 0.5, 0.75))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _truck() -> void:
	var c := Color("1a2230")
	draw_colored_polygon(PackedVector2Array([Vector2(-60, 618), Vector2(-60, 560), Vector2(120, 560), Vector2(150, 512),
		Vector2(214, 512), Vector2(232, 560), Vector2(236, 618)]), c)
	draw_rect(Rect2(160, 520, 46, 32), Color("2a3a52"))
	draw_circle(Vector2(30, 622), 23.0, Color("0b0e14"))
	draw_circle(Vector2(190, 622), 23.0, Color("0b0e14"))
	draw_circle(Vector2(230, 578), 6.0, Color("ffe2a8"))
	draw_colored_polygon(PackedVector2Array([Vector2(234, 570), Vector2(234, 588), Vector2(600, 660), Vector2(600, 510)]),
		Color(1.0, 0.86, 0.55, 0.07))


func _fence() -> void:
	var post := Color("2b3240")
	draw_rect(Rect2(326, 470, 9, 185), post)
	draw_rect(Rect2(466, 470, 9, 185), post)
	draw_line(Vector2(330, 476), Vector2(470, 476), post, 4.0)
	for i in 12:
		var x := 330.0 + i * 12.0
		draw_line(Vector2(x, 478), Vector2(x + 60, 650), Color(0.25, 0.3, 0.38, 0.45), 1.0)
		draw_line(Vector2(x + 60, 478), Vector2(x, 650), Color(0.25, 0.3, 0.38, 0.45), 1.0)
	draw_rect(Rect2(360, 492, 80, 156), post, false, 4.0)
	draw_rect(Rect2(392, 558, 17, 15), Color("a9a48e"))
	draw_arc(Vector2(400.5, 558), 6.0, PI, TAU, 10, Color("a9a48e"), 3.0)
