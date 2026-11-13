extends Room
## Act 3.6 — Main Street, October 14, 1991, half past one in the morning:
## the street eight years on, half erased like a torn photograph.
##
## Drawn to the people's scale (about 110 px to the metre): three shopfronts
## fill the picture, their upper floors running up out of it. The Lantern is
## dark (it opens at six now); Pike Radio is PIKE & LIND RADIO, televisions in
## the window and a satellite dish on the wall; the sheriff has moved out and
## Halvard Video has moved in. A payphone and a newspaper box on the
## sidewalk, his car or their van parked at the kerb, full size, in front of
## everything. The street ends in white, and at its edge the snow falls up.

const WHITE_X := 1190.0
const PIKE_DOOR := Rect2(676, 410, 110, 240)

var tomas: Actor
var snow: Snowfall
var up_snow: Snowfall


func env() -> Env:
	return Env.of("F1991")


func _taken() -> bool:
	return GameState.story.get("TOMAS") == "taken"


func setup() -> void:
	animated_back = false
	place_name = "Main Street  ·  1991"
	base_tint = Color(1.0, 0.9, 0.76)
	outdoors = true
	walk_min = 150.0
	walk_max = 1060.0
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, WHITE_X - Kit.L, 760)
	snow.count = 130
	snow.wind = 18.0
	add_child(snow)
	up_snow = Snowfall.new()
	up_snow.area = Rect2(WHITE_X - 150, -30, 170, 760)
	up_snow.count = 60
	up_snow.speed = -42.0
	up_snow.wind = -6.0
	up_snow.color = Color(0.85, 0.88, 0.95, 0.7)
	add_child(up_snow)
	make_player(640.0, 1)
	tomas = add_actor(Act3.tomas_1991(), 760.0, -1)
	# The cars at the kerb are nearer than the sidewalk: they're drawn in front.
	add_layer(3, _draw_cars)
	add_hotspot("pike_door", PIKE_DOOR, "Back inside", 730.0, 1)
	if _taken():
		add_hotspot("car", Rect2(0, 560, 300, 156), "His car", 330.0, -1)
	else:
		add_hotspot("car", Rect2(880, 540, 300, 176), "The van", 1040.0, 1)
	add_hotspot("white", Rect2(WHITE_X + 10, 100, 330, 550), "The end of the street", 1060.0, 1)
	add_hotspot("lantern", Rect2(0, 270, 290, 130), "The Lantern", 330.0, -1)
	add_hotspot("window", Rect2(330, 384, 310, 206), "Shop window", 480.0)
	add_hotspot("video", Rect2(900, 270, 290, 120), "Halvard Video", 1000.0)
	add_hotspot("payphone", Rect2(268, 452, 58, 120), "Payphone", 330.0, -1)
	add_hotspot("news", Rect2(800, 528, 64, 122), "Newspaper box", 790.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 640.0
	player.face(1)


func ambience() -> void:
	Audio.stop_loop("hum", 0.4)
	Audio.play_loop("wind", -24.0)
	Audio.play_loop("street_air", -26.0)
	Audio.set_environment("main_street", freq)


func on_arrive() -> void:
	ambience()
	if not GameState.has("street_1991_seen"):
		GameState.set_flag("street_1991_seen")
		await say("TOMAS", "Main Street. What's left of it.")
		await mara("The Lantern's dark.")
		if _taken():
			await say("TOMAS", "Ma doesn't do nights any more. Not since you.")
		else:
			await say("TOMAS", "Ruth opens at six. She'd skin me if she knew I was up.")
		await mara("And the end of the street is...")
		await say("TOMAS", "White. Since spring. A street a month. Nobody says it out loud.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"pike_door":
			Audio.sfx("shopbell", -10.0)
			main.change_room("shop_1991", "from_street")
		"car":
			await _car()
		"white":
			await mara("The street doesn't turn, or stop at a wall. It just ends, in white.")
			await mara("And the snow at its edge is falling up.")
		"lantern":
			await mara("THE LANTERN, dark. A card in the door: OPEN 6 AM.")
			await mara("Ma's still in there, somewhere in this. Eight years older.")
		"window":
			await mara("Three televisions, a video recorder, a boom box with two tape decks. SALE, on a star.")
		"video":
			await mara("HALVARD VIDEO, where the sheriff's office was. You can still read COUNTY SHERIFF in the stone.")
			await mara("Cal moved out. Somebody's renting films in his cells.")
		"payphone":
			await mara("A payphone. A dial tone, in 1991.")
			await mara("Everyone I could call is asleep, or eight years older, or both.")
		"news":
			await narrate("HALVARD COURIER, October 13, 1991. NORTH RIDGE ROAD CLOSED \"UNTIL FURTHER NOTICE.\" STATE SAYS: WEATHER.")
			await mara("Weather.")


func use_item(_id: String, _item: String) -> bool:
	return false


func examine_item(item: String) -> bool:
	if item == "tuner":
		await mara("The needle's on 1991, and staying there. I'm not going anywhere till it lets me.")
		return true
	return false


func _car() -> void:
	if _taken():
		await say("TOMAS", "That's the coast car. Tomorrow. If there's still a coast.")
		await say("TOMAS", "There's a ring in the battery box of a radio on the shelf. Don't tell June. Don't tell Lise.")
		await mara("Lise Dahl? Mr. Dahl's granddaughter, from the diner?")
		await say("TOMAS", "She laughs at my jokes. Both of them.")
	else:
		await say("TOMAS", "The van. Lise picked it. Room for a car seat.")
		await say("TOMAS", "December, they say. Tomorrow we paint the nursery.")
		await mara("Lise Dahl. Mr. Dahl's granddaughter.")
		await say("TOMAS", "She married me anyway.")
	GameState.set_flag("street_done")
	await say("TOMAS", "Come on. It's cold, and there's a radio inside with a loose contact.")
	objective()


# --- drawing ---------------------------------------------------------------------------------

func draw_back() -> void:
	# What sky there is: above Pike's false front and the old sheriff's parapet,
	# the mountain, with the observatory's light on top.
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 420), Color("03050c"), Color("1a2240"))
	Kit.stars(cv, Rect2(Kit.L, -60, Kit.R - Kit.L, 180), 50, 0.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(260, 200), Vector2(520, 90), Vector2(700, 30), Vector2(800, 46),
		Vector2(1000, 96), Vector2(1260, 170), Vector2(1260, 300), Vector2(260, 300)]), Color("0d1426"))
	cv.draw_rect(Rect2(690, 22, 26, 10), Color("080c18"))
	cv.draw_rect(Rect2(698, 25, 4, 3), Color("e8a54b"))
	Kit.dish(cv, Vector2(742, 36), 0.22, Color("080c18"))
	_lantern()
	_pike()
	_video()
	_sidewalk()
	_payphone()
	_news_box()
	_lamp_post(40.0, 1)
	_lamp_post(866.0, 1)


## The Lantern: two storeys of brick, the big window dark, chairs up on the
## tables, the sign unlit, a card in the door.
func _lantern() -> void:
	var r := Rect2(Kit.L, -100, 300 - Kit.L, 750)
	Townscape.wall(cv, r, Color("5a3a30"), "brick")
	for x in [-262.0, -62.0, 152.0]:
		Townscape.window(cv, Rect2(x, 70, 90, 140), x > 100.0, Color("2a201e"), true, true)
	cv.draw_rect(Rect2(Kit.L, 236, 300 - Kit.L, 10), Color("7a6a5e"))
	Townscape.snow_ledge(cv, Kit.L, 300, 236, 5.0, 11)
	# The sign, unlit.
	cv.draw_rect(Rect2(-40, 268, 330, 70), Color("2a201e"))
	cv.draw_rect(Rect2(-40, 268, 330, 70), Color("8a6a3a"), false, 3.0)
	Kit.text(cv, Vector2(-40, 316), "THE LANTERN", 34, Color("6a4a32"), HORIZONTAL_ALIGNMENT_CENTER, 330)
	for k in 13:
		cv.draw_circle(Vector2(-28 + k * 25, 346), 3.5, Color("a86a3a"))
	Townscape.snow_ledge(cv, -42, 292, 268, 6.0, 23)
	# The window: chairs up on the tables, one light left on over the pie case.
	var w := Rect2(-300, 384, 430, 206)
	Kit.vgrad(cv, w, Color("161820"), Color("0c0d12"))
	for k in 5:
		var x := -280.0 + k * 86.0
		cv.draw_rect(Rect2(x, 512, 60, 8), Color("2a2224"))
		cv.draw_line(Vector2(x + 8, 512), Vector2(x + 8, 482), Color("2a2224"), 3.0)
		cv.draw_line(Vector2(x + 52, 512), Vector2(x + 52, 482), Color("2a2224"), 3.0)
		cv.draw_line(Vector2(x + 30, 520), Vector2(x + 30, 590), Color("1e1a1c"), 4.0)
	cv.draw_rect(Rect2(40, 450, 80, 50), Color(1.0, 0.82, 0.5, 0.3))
	Townscape.storefront_frame(cv, w, Color("4a2e26"))
	Townscape.awning(cv, -310, 290, 384, 26, Color("8a2a24"), Color("e8dcc4"))
	Townscape.door(cv, Rect2(160, 410, 110, 240), Color("6a4a3a"), Color("101216"))
	cv.draw_rect(Rect2(180, 470, 66, 34), Color("e8e2d0"))
	Kit.text(cv, Vector2(180, 484), "OPEN", 12, Color("8a2a24"), HORIZONTAL_ALIGNMENT_CENTER, 66)
	Kit.text(cv, Vector2(180, 498), "6 AM", 12, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, 66)
	cv.draw_line(Vector2(296, -100), Vector2(296, 650), Color("282e30"), 6.0)


## PIKE & LIND RADIO: a false front, the sign, televisions in the window, a
## mesh satellite dish on the wall and June's old ham antenna on the roof.
func _pike() -> void:
	Townscape.wall(cv, Rect2(300, 130, 580, 520), Color("5a6a62"), "siding")
	cv.draw_rect(Rect2(294, 118, 592, 16), Color("2e3634"))
	Townscape.snow_ledge(cv, 292, 888, 118, 7.0, 31)
	cv.draw_line(Vector2(800, 118), Vector2(800, -100), Color("2a2f33"), 5.0)
	for k in 3:
		var w := 110.0 - k * 26.0
		cv.draw_line(Vector2(800 - w * 0.5, 30 + k * 30), Vector2(800 + w * 0.5, 30 + k * 30), Color("2a2f33"), 3.0)
	# The satellite dish on its wall bracket, and the loft window.
	cv.draw_line(Vector2(450, 250), Vector2(474, 222), Color("3a3e44"), 6.0)
	cv.draw_set_transform(Vector2(456, 196), -0.35, Vector2.ONE)
	cv.draw_colored_polygon(_ellipse(Vector2.ZERO, 64.0, 58.0), Color("7a8088"))
	for k in 6:
		cv.draw_line(Vector2(-60 + k * 24, -40), Vector2(-60 + k * 24, 40), Color(0.25, 0.27, 0.3, 0.6), 1.0)
	cv.draw_arc(Vector2.ZERO, 62.0, 0.0, TAU, 32, Color("4a5058"), 3.0)
	cv.draw_line(Vector2(0, 0), Vector2(70, 10), Color("4a5058"), 3.0)
	cv.draw_rect(Rect2(66, 4, 14, 12), Color("3a3e44"))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Townscape.window(cv, Rect2(640, 160, 100, 96), true, Color("2e3634"), false, true)
	# The sign.
	cv.draw_rect(Rect2(318, 282, 552, 72), Color("1e2428"))
	cv.draw_rect(Rect2(318, 282, 552, 72), Color("c8a050"), false, 3.0)
	Kit.text(cv, Vector2(318, 320), "PIKE & LIND RADIO", 32, Color("f2d890"), HORIZONTAL_ALIGNMENT_CENTER, 552)
	Kit.text(cv, Vector2(318, 343), "TV  ·  VCR  ·  CB  ·  SATELLITE", 15, Color("c8d0c0"), HORIZONTAL_ALIGNMENT_CENTER, 552)
	Townscape.snow_ledge(cv, 316, 872, 282, 5.0, 41)
	_tv_window(Rect2(330, 384, 310, 206))
	Townscape.door(cv, PIKE_DOOR, Color("4a5258"), Color("c8c09a"))
	cv.draw_rect(Rect2(702, 470, 58, 22), Color("e8e2d0"))
	Kit.text(cv, Vector2(702, 486), "CLOSED", 11, Color("8a2a24"), HORIZONTAL_ALIGNMENT_CENTER, 58)
	cv.draw_rect(Rect2(664, 396, 134, 10), Color("2e3634"))
	Townscape.snow_ledge(cv, 662, 800, 396, 5.0, 43)
	cv.draw_line(Vector2(882, -100), Vector2(882, 650), Color("23282a"), 6.0)


func _tv_window(r: Rect2) -> void:
	Kit.vgrad(cv, r, Color("2a2e30"), Color("1a1c1e"))
	# Two shelves: three televisions in wood and black, a video recorder, a boom box.
	cv.draw_rect(Rect2(r.position.x, r.position.y + 96, r.size.x, 8), Color("4a3a2a"))
	for k in 3:
		var tv := Rect2(r.position.x + 14 + k * 98, r.position.y + 22, 82, 70)
		cv.draw_rect(tv, Color("5a4632") if k != 1 else Color("2a2a2e"))
		cv.draw_rect(Rect2(tv.position + Vector2(8, 8), Vector2(54, 46)), [Color("8ab0d8"), Color("b8bcc0"), Color("9ac0a0")][k])
		cv.draw_line(tv.position + Vector2(14, 14), tv.position + Vector2(30, 26), Color(1, 1, 1, 0.25), 4.0)
		cv.draw_circle(tv.position + Vector2(72, 18), 4.0, Color("c8b890"))
		cv.draw_circle(tv.position + Vector2(72, 34), 4.0, Color("c8b890"))
	cv.draw_rect(Rect2(r.position.x + 20, r.position.y + 118, 110, 26), Color("1a1a1c"))
	cv.draw_rect(Rect2(r.position.x + 30, r.position.y + 126, 36, 6), Color("6aff9a"))
	var bb := Rect2(r.position.x + 160, r.position.y + 112, 136, 70)
	cv.draw_rect(bb, Color("2a2a2e"))
	cv.draw_circle(bb.position + Vector2(30, 38), 22.0, Color("4a4a50"))
	cv.draw_circle(bb.position + Vector2(106, 38), 22.0, Color("4a4a50"))
	cv.draw_rect(Rect2(bb.position + Vector2(56, 22), Vector2(26, 18)), Color("8a8a90"))
	cv.draw_line(bb.position + Vector2(20, 0), bb.position + Vector2(116, 0), Color("6a6a70"), 4.0)
	cv.draw_colored_polygon(_star(r.position + Vector2(270, 160), 22.0, 10.0), Color("e8c040"))
	Kit.text(cv, r.position + Vector2(254, 165), "SALE", 9, Color("8a2a24"))
	cv.draw_rect(r, Color(1.0, 0.9, 0.7, 0.06))
	Townscape.storefront_frame(cv, r, Color("2e3634"))


## The old sheriff's office: stone, COUNTY SHERIFF still cut into it, and the
## video store's sign over the top.
func _video() -> void:
	var r := Rect2(880, 110, 700, 540)
	Townscape.wall(cv, r, Color("5c564c"), "stone")
	Townscape.cornice(cv, 880, 1580, 110, Color("3a3630"), false)
	Townscape.snow_ledge(cv, 872, 1588, 106, 7.0, 51)
	Kit.text(cv, Vector2(900, 214), "COUNTY  SHERIFF", 30, Color(0.3, 0.28, 0.25, 0.55), HORIZONTAL_ALIGNMENT_CENTER, 320)
	cv.draw_rect(Rect2(900, 268, 300, 76), Color("1a1430"))
	cv.draw_rect(Rect2(900, 268, 300, 76), Color("c84a8a"), false, 4.0)
	Kit.text(cv, Vector2(900, 318), "HALVARD VIDEO", 32, Color("f0a8d0"), HORIZONTAL_ALIGNMENT_CENTER, 300)
	var w := Rect2(906, 384, 172, 206)
	Kit.vgrad(cv, w, Color("3a3050"), Color("1e1a2a"))
	for k in 2:
		var p := Rect2(w.position.x + 10 + k * 82, w.position.y + 14, 72, 106)
		cv.draw_rect(p, [Color("c84a3a"), Color("3a6a9a")][k])
		cv.draw_rect(Rect2(p.position + Vector2(6, 74), Vector2(p.size.x - 12, 22)), Color("1a1a1a"))
		cv.draw_circle(p.position + Vector2(36, 40), 18.0, Color(0, 0, 0, 0.3))
	Kit.text(cv, Vector2(w.position.x, w.position.y + 150), "NEW RELEASES", 13, Color("f2efe6"), HORIZONTAL_ALIGNMENT_CENTER, w.size.x)
	Kit.text(cv, Vector2(w.position.x, w.position.y + 176), "2 FOR $3 TUESDAYS", 11, Color("e8c040"), HORIZONTAL_ALIGNMENT_CENTER, w.size.x)
	cv.draw_rect(w, Color("24211d"), false, 6.0)
	Townscape.door(cv, Rect2(1100, 410, 110, 240), Color("3a2e24"), Color("2a2238"))
	cv.draw_rect(Rect2(1118, 556, 74, 12), Color("9aa3a8"))
	Kit.text(cv, Vector2(1104, 588), "NIGHT DROP", 10, Color("c8c0b0"), HORIZONTAL_ALIGNMENT_CENTER, 102)


## The sidewalk, the kerb, the street.
func _sidewalk() -> void:
	Kit.vgrad(cv, Rect2(Kit.L, 650, Kit.R - Kit.L, 22), Color("9aa0ac"), Color("8a909c"))
	cv.draw_rect(Rect2(Kit.L, 672, Kit.R - Kit.L, 9), Color("d8dce6"))
	Kit.vgrad(cv, Rect2(Kit.L, 681, Kit.R - Kit.L, 120), Color("8e8e98"), Color("6a6e7c"))
	for k in 4:
		cv.draw_line(Vector2(Kit.L, 700 + k * 9.0), Vector2(Kit.R, 702 + k * 9.0), Color(0.3, 0.32, 0.38, 0.35), 5.0)
	Townscape.snowbank(cv, 330, 640, 672, 10.0, 5)
	Townscape.snowbank(cv, Kit.L, -230, 682, 22.0, 3)
	Kit.vgrad(cv, Rect2(330, 652, 310, 24), Color(1, 0.72, 0.37, 0.12), Color(1, 0.72, 0.37, 0))


func _payphone() -> void:
	var x := 296.0
	cv.draw_rect(Rect2(x - 5, 540, 10, 110), Color("4a4e54"))
	cv.draw_rect(Rect2(x - 30, 456, 60, 14), Color("2a4a7a"))
	cv.draw_rect(Rect2(x - 26, 470, 52, 84), Color("8a9098"))
	cv.draw_rect(Rect2(x - 20, 478, 40, 22), Color("2a2c30"))
	for k in 12:
		cv.draw_rect(Rect2(x - 15 + (k % 3) * 11, 506 + (k / 3) * 10, 7, 7), Color("d8dce0"))
	cv.draw_rect(Rect2(x + 14, 498, 9, 40), Color("1a1a1c"))
	cv.draw_line(Vector2(x + 18, 538), Vector2(x + 24, 560), Color("1a1a1c"), 3.0)
	Kit.text(cv, Vector2(x - 30, 467), "PHONE", 10, Color("e8ecf0"), HORIZONTAL_ALIGNMENT_CENTER, 60)
	Townscape.snow_ledge(cv, x - 32, x + 32, 456, 5.0, 77)


func _news_box() -> void:
	var r := Rect2(802, 528, 60, 122)
	cv.draw_rect(r, Color("2a5a9a"))
	cv.draw_rect(Rect2(r.position + Vector2(6, 10), Vector2(48, 40)), Color("e8e6de"))
	Kit.text(cv, r.position + Vector2(8, 24), "COURIER", 9, Color("2a2a2a"))
	for k in 4:
		cv.draw_line(r.position + Vector2(10, 30 + k * 4), r.position + Vector2(50, 30 + k * 4), Color("6a6a6a"), 1.0)
	cv.draw_rect(Rect2(r.position + Vector2(16, 60), Vector2(28, 6)), Color("c8c8c8"))
	Kit.text(cv, r.position + Vector2(18, 90), "50¢", 13, Color("e8e6de"))
	cv.draw_rect(Rect2(r.position.x + 4, r.end.y - 14, r.size.x - 8, 14), Color("1e3e6a"))
	Townscape.snow_ledge(cv, 800, 864, 528, 5.0, 79)


## A sodium streetlamp at the kerb, full size: a five-metre pole and a cobra head.
func _lamp_post(x: float, dir: int) -> void:
	var c := Color("23252b")
	cv.draw_rect(Rect2(x - 10, 640, 20, 34), c)
	cv.draw_rect(Rect2(x - 6, 110, 12, 540), c)
	cv.draw_line(Vector2(x, 122), Vector2(x + 58 * dir, 102), c, 7.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(x + 50 * dir, 92), Vector2(x + 122 * dir, 94), Vector2(x + 114 * dir, 114), Vector2(x + 56 * dir, 114)]), Color("3a3c42"))
	cv.draw_rect(Rect2(x + (60 if dir > 0 else -106), 114, 46, 6), Color("ffd8a0"))
	Townscape.snow_ledge(cv, x + (50 if dir > 0 else -122), x + (122 if dir > 0 else -50), 93, 6.0, int(x))


## His car, or their van, at the kerb: full size, nearer than the sidewalk.
func _draw_cars(ci: CanvasItem) -> void:
	EraVehicles.sedan_1991(ci, Vector2(40, 716), 1.12, 0.0, {"snow": 0.5, "body": Color("6a2430")})
	EraVehicles.minivan_1991(ci, Vector2(1130, 718), 1.12, 0.0, {"snow": 0.6})


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _star(c: Vector2, r0: float, r1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := -PI / 2 + TAU * i / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r0 if i % 2 == 0 else r1))
	return pts


func draw_glow(ci: CanvasItem) -> void:
	for x in [40.0, 866.0]:
		var c := Vector2(x + 83, 120)
		Kit.soft_glow(ci, c, 90.0, Color(1.0, 0.62, 0.25, 0.14))
		ci.draw_rect(Rect2(x + 60, 114, 46, 6), Color("ffd8a0"))
	Kit.soft_glow(ci, Vector2(485, 470), 120.0, Color(0.6, 0.75, 1.0, 0.16))
	Kit.soft_glow(ci, Vector2(1050, 306), 150.0, Color(1.0, 0.5, 0.8, 0.18))
	_torn(ci)


## The torn photograph: the end of the street gone to white, bites out of the
## corners. Drawn on the glow layer, so the white stays white under the sodium
## light. The edges have the grey of torn paper.
func _torn(ci: CanvasItem) -> void:
	var edge := PackedVector2Array()
	for i in 27:
		var y := -100.0 + i * 34.0
		var x := WHITE_X + 22.0 * sin(i * 1.9) + 24.0 * Townscape.h(i * 7) - (40.0 if y < 260.0 else 0.0)
		edge.append(Vector2(x, y))
	var pts := edge.duplicate()
	pts.append(Vector2(Kit.R, edge[edge.size() - 1].y))
	pts.append(Vector2(Kit.R, -100))
	_tear(ci, pts, edge)
	_bite(ci, Vector2(880, 106), 90.0, 60.0, 5)
	_bite(ci, Vector2(-160, 236), 120.0, 90.0, 7)


## A bite out of a corner: a ragged quarter-circle of white.
func _bite(ci: CanvasItem, corner: Vector2, rx: float, ry: float, seed: int) -> void:
	var edge := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var a := PI * 0.5 * i / steps
		var k := 0.8 + 0.25 * Townscape.h(seed * 11 + i)
		edge.append(corner + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	var pts := PackedVector2Array([corner])
	pts.append_array(edge)
	_tear(ci, pts, edge)


func _tear(ci: CanvasItem, pts: PackedVector2Array, edge: PackedVector2Array) -> void:
	ci.draw_colored_polygon(pts, Color("f1f3f7"))
	ci.draw_polyline(edge, Color(0.62, 0.65, 0.72, 0.9), 3.0, true)
	ci.draw_polyline(edge, Color(1, 1, 1, 0.95), 1.0, true)
