class_name LindHouse
extends RefCounted
## The Lind house on Ash Street: two storeys of clapboard and a porch, the lamp
## Ma leaves on in the front-room window, the porch light, the picket fence and
## the mailbox. Drawn for any station's world (see Env): its paint, its season,
## who's home. Ash Street draws it at full size; the opening's montage draws it
## closer, one spring night.

const HOUSE := Rect2(480, 330, 380, 320)
const FRONT_WIN := Rect2(504, 478, 84, 74)
const UP_WIN := [Rect2(540, 366, 70, 58), Rect2(740, 366, 70, 58)]
const PORCH_WIN := Rect2(754, 494, 74, 58)
const DOOR := Rect2(628, 474, 62, 136)
const SCONCE := Vector2(708, 500)


## A roof out of the snow: dark shingle with its courses showing.
static func shingles(cv: CanvasItem, tri: PackedVector2Array, e: Env) -> void:
	var col := Color("3a2e2a") if e.night() else e.shade(Color("5a4a44"))
	cv.draw_colored_polygon(tri, col)
	var a := tri[0]
	var p := tri[1]
	var b := tri[2]
	for k in range(1, 7):
		var u := k / 7.0
		cv.draw_line(a.lerp(p, u), b.lerp(p, u), col.darkened(0.25), 1.5)
	cv.draw_polyline(tri, col.lightened(0.15), 2.0, true)


## The Lind house: two storeys of clapboard and a porch. In H, Ma left the lamp
## and the porch light on; in 14 it's dark, empty, and for sale. On every other
## station it's somebody else's version of the house: another colour, another
## season, nobody home, boarded up.
static func draw(cv: CanvasItem, e: Env, for_sale: bool) -> void:
	var r := HOUSE
	var wall := e.paint
	if e.state == "derelict":
		wall = wall.lerp(Color("6a665e"), 0.5)
	if not (e.night() or e.story()):
		wall = e.shade(wall.lightened(0.18))
	Townscape.wall(cv, r, wall, "siding")
	if e.state == "derelict":
		# Peeling paint, a stain from a broken gutter.
		for k in 14:
			var px := r.position.x + 20 + Townscape.h(k * 3) * (r.size.x - 40)
			var py := r.position.y + 20 + Townscape.h(k * 5 + 1) * (r.size.y - 60)
			cv.draw_rect(Rect2(px, py, 6 + 14 * Townscape.h(k), 3), wall.darkened(0.35))
		Kit.vgrad(cv, Rect2(842, 340, 14, 260), Color(0.1, 0.12, 0.1, 0.35), Color(0.1, 0.12, 0.1, 0.0))
	# Corner boards and the foundation.
	cv.draw_rect(Rect2(480, 330, 10, 320), wall.lightened(0.18))
	cv.draw_rect(Rect2(850, 330, 10, 320), wall.lightened(0.1))
	cv.draw_rect(Rect2(474, 618, 392, 32), Color("5a5650"))
	# The roof (deep in snow in winter), the gable vent, the chimney.
	var roof := PackedVector2Array([Vector2(456, 334), Vector2(670, 214), Vector2(884, 334)])
	if e.roof_snow():
		cv.draw_colored_polygon(roof, Color("3a2a24"))
		cv.draw_colored_polygon(PackedVector2Array([Vector2(456, 334), Vector2(670, 214), Vector2(884, 334), Vector2(866, 326),
			Vector2(670, 228), Vector2(474, 326)]), Color("d6dde8"))
		cv.draw_polyline(roof, Color("f2f5fa"), 3.0, true)
	else:
		shingles(cv, roof, e)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(650, 290), Vector2(670, 270), Vector2(690, 290)]), wall.darkened(0.35))
	Townscape.icicles(cv, 470, 870, 336, 3)
	cv.draw_rect(Rect2(780, 232, 24, 64), Color("4a3a36"))
	Townscape.snow_ledge(cv, 778, 806, 232, 5.0, 17)
	# Who's home: which windows are lit.
	var glow := e.windows_glow()
	var curtains := e.state == "home"
	for k in 2:
		var w: Rect2 = UP_WIN[k]
		var on: bool = e.lit and glow and e.windows[k]
		if e.story():
			on = e.lit
		Townscape.window(cv, w, on, Color("2a2420"), false, curtains)
		var shutter := Color("2e3e2e") if e.night() or e.story() else e.shade(Color("3e5a3e"))
		cv.draw_rect(Rect2(w.position.x - 13, w.position.y, 9, w.size.y), shutter)
		cv.draw_rect(Rect2(w.end.x + 4, w.position.y, 9, w.size.y), shutter)
	# The front room: the lamp Ma leaves on, in the window left of the porch.
	var front_on: bool = e.lit and glow and e.windows[2]
	Townscape.window(cv, FRONT_WIN, front_on, Color("2a2420"), false, curtains)
	if front_on:
		_table_lamp(cv, Vector2(FRONT_WIN.position.x + 30, FRONT_WIN.end.y - 4))
	# The porch window, behind the rail.
	Townscape.window(cv, PORCH_WIN, e.lit and glow and e.windows[3], Color("2a2420"), false, curtains)
	# The door; the light over it.
	_door(cv, e)
	_sconce(cv, e)
	# The porch: roof on posts, the rail, the steps.
	cv.draw_rect(Rect2(600, 452, 250, 12), Color("3a2a24"))
	Townscape.snow_ledge(cv, 598, 852, 452, 6.0, 29)
	Townscape.icicles(cv, 600, 850, 464, 9)
	var post := Color("d8d0c0") if e.night() or e.story() else e.shade(Color("eae4d8"))
	if e.state == "derelict":
		post = post.darkened(0.3)
	for px in [606.0, 724.0, 842.0]:
		cv.draw_rect(Rect2(px - 4, 464, 8, 154), post)
	cv.draw_rect(Rect2(700, 560, 150, 6), post)
	for k in 12:
		if e.state == "derelict" and k in [2, 3, 7, 10]:
			continue
		cv.draw_line(Vector2(706 + k * 12, 566), Vector2(706 + k * 12, 610), post, 2.0)
	Townscape.snow_ledge(cv, 698, 852, 560, 4.0, 33)
	var step := Color("6a6056") if e.night() or e.story() else e.shade(Color("8a8076"))
	cv.draw_rect(Rect2(610, 610, 100, 10), step)
	cv.draw_rect(Rect2(604, 620, 112, 10), step)
	cv.draw_rect(Rect2(598, 630, 124, 12), step)
	if for_sale:
		# FOR SALE: a banner on the porch rail, and a sign on a post in the yard.
		cv.draw_rect(Rect2(722, 572, 110, 24), Color("e8e4dc"))
		cv.draw_rect(Rect2(722, 572, 110, 24), Color("8a1d1d"), false, 2.0)
		Kit.text(cv, Vector2(722, 590), "FOR SALE", 15, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 110)
		cv.draw_line(Vector2(925, 650), Vector2(925, 560), Color("4a3a2a"), 5.0)
		cv.draw_rect(Rect2(886, 530, 80, 44), Color("e8e4dc"))
		Kit.text(cv, Vector2(886, 548), "FOR", 13, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 80)
		Kit.text(cv, Vector2(886, 566), "SALE", 13, Color("8a1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 80)
		# Nobody's shovelled the path.
		cv.draw_rect(Rect2(480, 600, 380, 50), Color(0.85, 0.88, 0.95, 0.5))


## A table lamp behind the glass: a pleated shade and its pool of light.
static func _table_lamp(cv: CanvasItem, base: Vector2) -> void:
	Kit.soft_glow(cv, base + Vector2(0, -34), 44.0, Color(1.0, 0.92, 0.7, 0.55))
	cv.draw_rect(Rect2(base.x - 2, base.y - 24, 4, 20), Color("6a4a2e"))
	cv.draw_rect(Rect2(base.x - 9, base.y - 6, 18, 6), Color("5a3a24"))
	cv.draw_colored_polygon(PackedVector2Array([base + Vector2(-8, -42), base + Vector2(8, -42), base + Vector2(14, -24), base + Vector2(-14, -24)]),
		Color("fff2c8"))
	cv.draw_line(base + Vector2(-14, -24), base + Vector2(14, -24), Color("e8c890"), 1.5)


## The front door: lit through its glass when someone's home; banging open in
## the wind on 06; boarded on the derelict ones.
static func _door(cv: CanvasItem, e: Env) -> void:
	var lit_glass := Color("f0d090") if e.lit and e.windows_glow() else Color("101116")
	if e.st == "06":
		# Open. The dark hall behind it.
		cv.draw_rect(Rect2(DOOR.position.x - 6, DOOR.position.y - 8, DOOR.size.x + 12, DOOR.size.y + 8), Color("3a2a22"))
		cv.draw_rect(DOOR, Color("07080a"))
		cv.draw_colored_polygon(PackedVector2Array([DOOR.position, DOOR.position + Vector2(18, 10), Vector2(DOOR.position.x + 18, DOOR.end.y - 6),
			Vector2(DOOR.position.x, DOOR.end.y)]), Color("4a3428"))
		cv.draw_rect(Rect2(DOOR.position.x - 10, DOOR.end.y - 4, DOOR.size.x + 20, 6), Color("6a6862"))
		return
	Townscape.door(cv, DOOR, Color("4a3428") if e.state != "derelict" else Color("3a3430"), lit_glass)
	if e.state == "derelict":
		for k in 2:
			var y := DOOR.position.y + 40 + k * 56
			cv.draw_line(Vector2(DOOR.position.x - 6, y), Vector2(DOOR.end.x + 6, y + 18), Color("7a6a54"), 11.0)


## The porch light: a little lantern on the wall right of the door.
static func _sconce(cv: CanvasItem, e: Env) -> void:
	var on: bool = e.lit if e.story() else (e.porch_light and e.lit and e.windows_glow())
	cv.draw_rect(Rect2(SCONCE.x - 2, SCONCE.y - 14, 4, 6), Color("2a2622"))
	cv.draw_colored_polygon(PackedVector2Array([SCONCE + Vector2(-6, -8), SCONCE + Vector2(6, -8), SCONCE + Vector2(5, 8), SCONCE + Vector2(-5, 8)]),
		Color("fff0c0") if on else Color("3a3a3e"))
	cv.draw_rect(Rect2(SCONCE.x - 7, SCONCE.y - 10, 14, 3), Color("2a2622"))
	cv.draw_rect(Rect2(SCONCE.x - 5, SCONCE.y + 8, 10, 3), Color("2a2622"))


## The front yard: a picket fence, the path, the mailbox, and whatever the
## season has left in the grass.
static func yard(cv: CanvasItem, e: Env) -> void:
	var picket := Color("d8d4cc") if e.night() or e.story() else e.shade(Color("eeeae2"))
	if e.state == "derelict":
		picket = picket.darkened(0.3)
	for x in range(300, 1000, 14):
		if x > 590 and x < 730:
			continue
		if e.state == "derelict" and Townscape.h(x) > 0.75:
			continue
		var lean := 0.0 if e.state != "derelict" else (Townscape.h(x * 3) - 0.5) * 8.0
		cv.draw_colored_polygon(PackedVector2Array([Vector2(x, 650), Vector2(x + 8, 650), Vector2(x + 8 + lean, 616),
			Vector2(x + 4 + lean, 610), Vector2(x + lean, 616)]), picket)
	cv.draw_rect(Rect2(300, 626, 290, 4), picket.darkened(0.06))
	cv.draw_rect(Rect2(730, 626, 270, 4), picket.darkened(0.06))
	Townscape.snowbank(cv, 300, 590, 652, 12.0, 41)
	Townscape.snowbank(cv, 730, 1000, 652, 12.0, 43)
	_garden(cv, e)
	cv.draw_rect(Rect2(574, 590, 6, 60), Color("3a3a3a"))
	cv.draw_rect(Rect2(560, 574, 34, 18), Color("2e4a6a"))
	Kit.text(cv, Vector2(560, 588), "LIND", 9, Color("e8e8e0"), HORIZONTAL_ALIGNMENT_CENTER, 34)
	Townscape.snow_ledge(cv, 558, 596, 574, 4.0, 47)


## What's growing (or fallen) along the fence.
static func _garden(cv: CanvasItem, e: Env) -> void:
	match e.season:
		"spring":
			for k in 26:
				var x := 304.0 + k * 26.0 + 8.0 * Townscape.h(k)
				if x > 586 and x < 734:
					continue
				var c: Color = [Color("e8d84a"), Color("b48ad8"), Color("f2f2ee")][k % 3]
				cv.draw_line(Vector2(x, 652), Vector2(x, 640), e.shade(Color("4a7a3a")), 2.0)
				cv.draw_circle(Vector2(x, 638), 3.5, e.shade(c))
		"summer":
			for k in 34:
				var x2 := 302.0 + k * 20.0 + 6.0 * Townscape.h(k * 3)
				if x2 > 586 and x2 < 734:
					continue
				cv.draw_circle(Vector2(x2, 644), 9.0, e.shade(Color("3a6e30")))
				if k % 2 == 0:
					var c2: Color = [Color("e84a5a"), Color("f2c03a"), Color("e86ab0"), Color("f4f0e8")][k % 4]
					cv.draw_circle(Vector2(x2 + 2, 638), 3.2, e.shade(c2))
		"autumn":
			for k in 9:
				var x3 := 310.0 + k * 78.0 + 20.0 * Townscape.h(k * 5)
				if x3 > 560 and x3 < 740:
					continue
				var c3: Color = [Color("c8642a"), Color("b8422a"), Color("d8a03a")][k % 3]
				cv.draw_set_transform(Vector2(x3, 650), 0.0, Vector2(1.0, 0.32))
				cv.draw_circle(Vector2.ZERO, 26.0 + 10.0 * Townscape.h(k), e.shade(c3.darkened(0.15)))
				cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for k in 40:
				var p := Vector2(Kit.L + Townscape.h(k * 7) * (Kit.R - Kit.L), 600 + Townscape.h(k * 11) * 60.0)
				var c4: Color = [Color("c8642a"), Color("b8422a"), Color("d8a03a")][k % 3]
				cv.draw_rect(Rect2(p, Vector2(5, 3)), e.shade(c4))
