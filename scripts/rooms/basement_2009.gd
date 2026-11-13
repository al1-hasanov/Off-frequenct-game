extends "res://scripts/rooms/basement.gd"
## Act 3.4 — 2009, the stone wing's basement: the same basement as tonight's,
## twenty-six years on. Its stairs are bricked up (a dark room: the Rules), so
## Tomas comes and goes by the old coal chute. Mara keeps inside the circle of
## his lamp, because light holds you where you are. The shelves have fallen,
## Mara's crate has rotted to slats, the boiler is cold, and behind it the
## plaster has crumbled: a rusted biscuit tin with "T.L." scratched in the lid.

const STOPS := [300.0, 650.0, 880.0]

var tomas: Actor
var lamp: PointLight2D
## Where Tomas has led her: 0 the chute, 1 the crate, 2 the boiler.
var stage := 0


func env() -> Env:
	return Env.of("F2009")


func setup() -> void:
	place_name = "Under the stone wing  ·  2009"
	walk_min = 160.0
	walk_max = 1000.0
	make_player(200.0, 1)
	light_off = true
	tomas = add_actor("tomas_2009", STOPS[0], 1)
	tomas.prop = "lamp"
	lamp = add_lamp(Vector2(STOPS[0], 520), 3.1, Color(1.0, 0.78, 0.45), 1.3)
	add_hotspot("chute", Rect2(40, 250, 170, 230), "Coal chute", 190.0, -1)
	add_hotspot("light", Rect2(STOPS[0] - 45, 440, 90, 210), "His light", NAN)
	add_hotspot("crate", Rect2(566, 560, 162, 90), "Crate", 600.0, 1, func() -> bool: return stage >= 1)
	add_hotspot("boiler", Rect2(770, 300, 160, 250), "Boiler", 820.0, 1, func() -> bool: return stage >= 1)
	add_hotspot("cavity", Rect2(938, 326, 82, 140), "Behind the boiler", 900.0, 1, func() -> bool: return stage >= 2)


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 200.0
	player.face(1)


func is_dark() -> bool:
	return true


func ambience() -> void:
	Audio.stop_loop("hum", 0.4)
	Audio.stop_loop("wind", 0.6)
	Audio.play_loop("drone", -28.0)
	Audio.play_loop("drip", -26.0)
	Audio.set_environment("basement", freq)


func _process(delta: float) -> void:
	super(delta)
	if tomas == null:
		return
	lamp.position = tomas.position + Vector2(-24.0 * tomas.facing, -128.0)
	# Inside his light: Mara won't step out of it.
	walk_min = maxf(150.0, tomas.position.x - 170.0)
	walk_max = minf(1010.0, tomas.position.x + 170.0)
	var h := get_hotspot("light")
	h.rect = Rect2(tomas.position.x - 45.0, 440.0, 90.0, 210.0)


func on_arrive() -> void:
	ambience()
	if not GameState.has("chute_seen"):
		GameState.set_flag("chute_seen")
		Audio.sfx("scrape", -6.0)
		await narrate("Down the chute in a slide of old coal. Then dark, except his lamp.")
		await say("TOMAS", "Torch off. Bright light down here wakes things. Lamp light's enough.")
		await say("TOMAS", "Stay in it. Light holds you where you are.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"chute":
			if GameState.has("knows_tin"):
				await _up()
			else:
				await mara("Not yet. He brought me down here for something.")
		"light":
			await _follow()
		"crate":
			await mara("A crate rotted to slats. TOMAS, in marker, nearly gone.")
			await mara("My handwriting. My box. Twenty-six years down here.")
		"boiler":
			await mara("Cold. Rusted through. Nobody's fed it since the winter it went.")
		"cavity":
			await _tin()


func use_item(id: String, item: String) -> bool:
	if item == "flashlight":
		await say("TOMAS", "Leave it off. Please.")
		return true
	return false


func examine_item(item: String) -> bool:
	if item == "flashlight":
		await say("TOMAS", "Leave it off. Please.")
		return true
	return await super(item)


## He goes on a few steps; Mara keeps inside his light.
func _follow() -> void:
	match stage:
		0:
			await say("TOMAS", "This was somebody's basement. They bricked up the stairs the first winter. Dark room.")
			stage = 1
			await _lead(STOPS[1])
			await say("TOMAS", "Somebody's box. TOMAS, it says. Not mine. I looked.")
		1:
			stage = 2
			await _lead(STOPS[2])
			await say("TOMAS", "Behind the boiler. Go on. I'll hold the light.")
		_:
			await say("TOMAS", "Behind the boiler.")
	objective()


func _lead(x: float) -> void:
	tomas.walk_to(x)  # not awaited: Mara follows while he walks
	await wait(0.35)
	await player.walk_to(x - 90.0)
	while tomas.walking:
		await get_tree().process_frame


func _tin() -> void:
	var g := GameState
	if g.has("knows_tin"):
		await mara("T.L. Behind the boiler. I've got it.")
		return
	await narrate("Behind the boiler the plaster has crumbled away. In the cavity sits a rusted biscuit tin, \"T.L.\" scratched in the lid.")
	await say("TOMAS", "I've known it was there for years. Never opened it.")
	await mara("Why not?")
	await say("TOMAS", "I'm T.L. too. Doesn't make it mine.")
	await narrate("The tin is rusted shut. And nothing comes back from a future.")
	await mara("Behind the boiler. Under the stone wing. Our basement. That fresh plaster tonight.")
	g.set_flag("knows_tin")
	await say("TOMAS", "Up we go. It's nearly time.")
	await _up()


func _up() -> void:
	Audio.sfx("scrape", -8.0)
	main.change_room("dish", "from_chute")


# --- drawing: tonight's basement, twenty-six years on --------------------------------------

func _stairs() -> void:
	# The stairwell bricked up, and the old coal chute coming down beside it.
	super()
	EnvironmentArt.brick(cv, Rect2(30, 200, 140, 120), Color("4a3a32"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(60, 250), Vector2(150, 250), Vector2(260, 560), Vector2(196, 572)]), Color("2c2e32"))
	cv.draw_line(Vector2(60, 250), Vector2(196, 572), Color("4a4c50"), 3.0)
	cv.draw_line(Vector2(150, 250), Vector2(260, 560), Color("4a4c50"), 3.0)
	cv.draw_rect(Rect2(54, 236, 102, 18), Color("1a1c20"))
	for i in 26:
		var p := Vector2(180 + Townscape.h(i) * 120.0, 600 + Townscape.h(i * 3) * 46.0)
		cv.draw_circle(p, 5.0 + Townscape.h(i * 7) * 6.0, Color("141416"))


func _shelves() -> void:
	# Fallen: the uprights leaning, the boards and boxes on the floor.
	cv.draw_line(Vector2(330, 650), Vector2(380, 360), Color("4a4038"), 8.0)
	cv.draw_line(Vector2(520, 650), Vector2(548, 380), Color("4a4038"), 8.0)
	for k in 3:
		cv.draw_line(Vector2(330 + k * 30, 640 - k * 40), Vector2(520 + k * 10, 630 - k * 60), Color("5a4a3a"), 6.0)
	for k in 5:
		cv.draw_rect(Rect2(340 + k * 36, 618 - (k % 2) * 10, 30, 22), Color("5a4a38").darkened(Townscape.h(k) * 0.3))


func _crate_art() -> void:
	var r := Rect2(570, 560, 154, 90)
	for i in 5:
		if i == 2:
			continue
		cv.draw_rect(Rect2(r.position.x + i * 31, r.position.y + (i % 2) * 8, 26, r.size.y - (i % 2) * 8), Color("4a3a28"))
	Kit.text(cv, Vector2(r.position.x, r.position.y + 54), "TOM S", 16, Color(0.2, 0.15, 0.1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	cv.draw_rect(Rect2(600, 640, 70, 10), Color("3a4048"))  # the blanket, rotted grey


func _boiler() -> void:
	var rust := Color("4a3428")
	cv.draw_rect(Rect2(780, 360, 140, 290), rust)
	cv.draw_circle(Vector2(850, 360), 70.0, rust)
	cv.draw_rect(Rect2(830, 540, 40, 30), Color("1a1410"))
	cv.draw_line(Vector2(850, 290), Vector2(850, 20), Color("3a2e26"), 18.0)
	for i in 14:
		var p := Vector2(790 + Townscape.h(i) * 120.0, 380 + Townscape.h(i * 5) * 250.0)
		cv.draw_line(p, p + Vector2(0, 10 + Townscape.h(i * 3) * 30.0), Color(0.5, 0.26, 0.12, 0.6), 3.0)
	cv.draw_circle(Vector2(850, 470), 14.0, Color("6a6458"))


func _plaster() -> void:
	# Crumbled away: the cavity, and the tin in it.
	var r := Rect2(944, 332, 70, 128)
	cv.draw_rect(r, Color("0c0a08"))
	cv.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(70, 0), r.position + Vector2(62, 18),
		r.position + Vector2(30, 10), r.position + Vector2(8, 26)]), Color("6a6a60"))
	for i in 8:
		cv.draw_circle(Vector2(950 + Townscape.h(i) * 70.0, 646 - Townscape.h(i * 3) * 6.0), 4.0 + Townscape.h(i * 9) * 4.0, Color("7a7a70"))
	var tin := Rect2(956, 420, 46, 30)
	cv.draw_rect(tin, Color("6a3a20"))
	cv.draw_rect(Rect2(tin.position + Vector2(-2, -4), Vector2(50, 7)), Color("7a4628"))
	Kit.text(cv, tin.position + Vector2(10, 20), "T.L.", 12, Color("c8a080"))


func _delivery_door() -> void:
	var r := Rect2(1060, 340, 120, 310)
	cv.draw_rect(r.grow(8), Color("15191b"))
	EnvironmentArt.brick(cv, r, Color("4a3a32"))
