class_name IntroArt
extends RefCounted
## Drawing shared by the opening, 1980: the maintenance clearing below the
## observatory (the snowfield, its aftermath and the morning after), the
## service road up through the trees, footprints in the snow.
## Static, like Kit and Townscape; each takes the canvas item to draw on.

const NIGHT := "night"
const DAWN := "dawn"
const DAY := "day"


# --- the clearing ------------------------------------------------------------------------

## Everything behind the people in the clearing: the sky, the ridges, the
## observatory up the field, the treeline and the snow. The masts' red lights
## blink (mast_lights(), on a moving layer).
static func clearing(ci: CanvasItem, mood: String = NIGHT) -> void:
	match mood:
		DAWN:
			Kit.vgrad(ci, Rect2(Kit.L, -100, Kit.R - Kit.L, 580), Color("58667e"), Color("c9b8b0"))
		DAY:
			Kit.vgrad(ci, Rect2(Kit.L, -100, Kit.R - Kit.L, 580), Color("8a96a6"), Color("c4cad2"))
		_:
			Kit.vgrad(ci, Rect2(Kit.L, -100, Kit.R - Kit.L, 580), Color("03050c"), Color("1a2442"))
			Kit.stars(ci, Rect2(Kit.L, 0, Kit.R - Kit.L, 330), 110, 0.0)
	var ridge := Color("0f1528") if mood == NIGHT else (Color("3e475a") if mood == DAWN else Color("6a7484"))
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 470), Vector2(-200, 330), Vector2(80, 400), Vector2(360, 300), Vector2(640, 410),
		Vector2(860, 320), Vector2(1180, 400), Vector2(1450, 310), Vector2(Kit.R, 420), Vector2(Kit.R, 470)]), ridge)
	for seg in [[Vector2(-200, 330), Vector2(-120, 350), Vector2(-40, 368)], [Vector2(360, 300), Vector2(430, 326), Vector2(500, 352)],
			[Vector2(860, 320), Vector2(940, 344), Vector2(1010, 362)], [Vector2(1450, 310), Vector2(1520, 336), Vector2(1600, 366)]]:
		ci.draw_polyline(PackedVector2Array(seg), Color(0.7, 0.76, 0.88, 0.3 if mood == NIGHT else 0.5), 4.0, true)
	observatory(ci, mood)
	var trees := Color("080c14") if mood == NIGHT else (Color("1e2530") if mood == DAWN else Color("2a3238"))
	Kit.pines(ci, 474.0, trees)
	pine_snow(ci, 474.0, mood)
	var g0 := Color("a9b6cc") if mood == NIGHT else (Color("d8d6dc") if mood == DAWN else Color("dfe4ea"))
	var g1 := Color("6f7d96") if mood == NIGHT else (Color("9aa2b4") if mood == DAWN else Color("aeb6c4"))
	Kit.vgrad(ci, Rect2(Kit.L, 470, Kit.R - Kit.L, 320), g0, g1)
	for k in 4:
		var y := 520.0 + k * 34.0
		ci.draw_line(Vector2(Kit.L, y), Vector2(Kit.R, y - 10.0), Color(1, 1, 1, 0.07), 10.0)


## The observatory up the field: the low control building, the radio masts,
## the dish on its lattice pedestal.
static func observatory(ci: CanvasItem, mood: String = NIGHT) -> void:
	var b := Color("0e1320") if mood == NIGHT else Color("2a3140")
	var hi := Color("2a3450") if mood == NIGHT else Color("56607a")
	ci.draw_rect(Rect2(900, 392, 270, 84), b)
	ci.draw_rect(Rect2(900, 392, 270, 4), hi)
	Townscape.snow_ledge(ci, 896, 1174, 392, 5.0, 101)
	ci.draw_rect(Rect2(930, 352, 124, 42), b)
	Townscape.snow_ledge(ci, 926, 1058, 352, 5.0, 103)
	for k in 7:
		var lit := (k == 1 or k == 4) and mood == NIGHT
		ci.draw_rect(Rect2(912 + k * 36, 414, 20, 14), Color("e8a54b") if lit else Color("141a28"))
	ci.draw_rect(Rect2(950, 366, 22, 14), Color("e8a54b") if mood == NIGHT else Color("141a28"))
	ci.draw_rect(Rect2(1110, 432, 24, 44), Color("060910"))
	ci.draw_line(Vector2(1122, 430), Vector2(1122, 420), Color("1a2030"), 2.0)
	ci.draw_circle(Vector2(1122, 420), 3.0, Color("ffe8b0") if mood == NIGHT else Color("8a8a80"))
	for mx in [880.0, 1200.0]:
		ci.draw_line(Vector2(mx, 476), Vector2(mx, 250), b, 3.0)
		for k in 6:
			ci.draw_line(Vector2(mx - 4, 470 - k * 38), Vector2(mx + 4, 452 - k * 38), b, 1.0)
		ci.draw_line(Vector2(mx, 270), Vector2(mx - 60, 476), Color(b, 0.6), 1.0)
		ci.draw_line(Vector2(mx, 270), Vector2(mx + 60, 476), Color(b, 0.6), 1.0)
	var base := Vector2(1090, 392)
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-26, 0), base + Vector2(-8, -48), base + Vector2(8, -48), base + Vector2(26, 0)]), b)
	for k in 4:
		ci.draw_line(base + Vector2(-22 + k * 4, -k * 12), base + Vector2(22 - k * 4, -(k + 1) * 12), hi, 1.0)
	Kit.dish(ci, base + Vector2(0, -10), 1.2, b)


## The red lights on the masts, blinking.
static func mast_lights(ci: CanvasItem, t: float) -> void:
	for mx in [880.0, 1200.0]:
		var blink := 0.5 + 0.5 * sin(t * 2.2 + mx)
		ci.draw_circle(Vector2(mx, 248), 3.0, Color(1.0, 0.2, 0.15, 0.4 + 0.6 * blink))


static func pine_snow(ci: CanvasItem, base_y: float, mood: String = NIGHT) -> void:
	var x := Kit.L
	var i := 0
	var c := Color(0.75, 0.82, 0.92, 0.35 if mood == NIGHT else 0.6)
	while x < Kit.R:
		var hh := 40.0 + 34.0 * Townscape.h(i * 3)
		for k in 3:
			var y := base_y - hh * (0.25 + 0.27 * k)
			var w := 14.0 * (1.0 - 0.28 * k)
			ci.draw_line(Vector2(x - w, y + 4), Vector2(x + w * 0.6, y), c, 2.0)
		x += 22.0 + 18.0 * Townscape.h(i * 7)
		i += 1


## The vehicle gate across the service road, its chain-link panel and padlock.
static func gate(ci: CanvasItem) -> void:
	var post := Color("2b3240")
	ci.draw_rect(Rect2(326, 470, 9, 185), post)
	ci.draw_rect(Rect2(466, 470, 9, 185), post)
	ci.draw_line(Vector2(330, 476), Vector2(470, 476), post, 4.0)
	for i in 12:
		var x := 330.0 + i * 12.0
		ci.draw_line(Vector2(x, 478), Vector2(x + 60, 650), Color(0.25, 0.3, 0.38, 0.45), 1.0)
		ci.draw_line(Vector2(x + 60, 478), Vector2(x, 650), Color(0.25, 0.3, 0.38, 0.45), 1.0)
	ci.draw_rect(Rect2(360, 492, 80, 156), post, false, 4.0)
	Townscape.snow_ledge(ci, 324, 478, 474, 4.0, 121)
	ci.draw_rect(Rect2(392, 558, 17, 15), Color("a9a48e"))
	ci.draw_arc(Vector2(400.5, 558), 6.0, PI, TAU, 10, Color("a9a48e"), 3.0)


## A line of footprints in the snow from x0 to x1 (either direction), along
## the floor at y. Each print is a pair of ovals: sole and heel.
static func footprints(ci: CanvasItem, x0: float, x1: float, y: float, col: Color = Color(0.33, 0.39, 0.5, 0.7), step: float = 26.0) -> void:
	var dir := 1.0 if x1 >= x0 else -1.0
	var n := int(absf(x1 - x0) / step)
	for i in n + 1:
		var x := x0 + dir * i * step
		var yy := y + (4.0 if i % 2 == 0 else -3.0)
		ci.draw_set_transform(Vector2(x, yy), 0.0, Vector2(1.0, 0.38))
		ci.draw_circle(Vector2(dir * 3.0, 0), 6.0, col)
		ci.draw_circle(Vector2(-dir * 6.0, 0), 4.2, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The clearing the morning after: boots, dogs and tyres everywhere.
static func trampled(ci: CanvasItem, seed: int = 0) -> void:
	var col := Color(0.42, 0.46, 0.56, 0.55)
	for k in 14:
		var y := 600.0 + 60.0 * Townscape.h(seed + k * 5)
		var x0 := -200.0 + 1500.0 * Townscape.h(seed + k * 11)
		var x1 := x0 + (Townscape.h(seed + k * 3) - 0.5) * 900.0
		footprints(ci, x0, x1, y, col, 22.0 + 8.0 * Townscape.h(k))
	for k in 3:
		var y := 628.0 + k * 34.0
		ci.draw_rect(Rect2(Kit.L, y, Kit.R - Kit.L, 6), Color(0.36, 0.4, 0.5, 0.35))
		ci.draw_rect(Rect2(Kit.L, y + 22, Kit.R - Kit.L, 5), Color(0.36, 0.4, 0.5, 0.25))
	for k in 30:
		var p := Vector2(-100 + 1400.0 * Townscape.h(seed + 300 + k), 610.0 + 90.0 * Townscape.h(seed + 400 + k))
		ci.draw_circle(p, 2.2, Color(0.4, 0.44, 0.52, 0.5))
		ci.draw_circle(p + Vector2(5, -3), 1.6, Color(0.4, 0.44, 0.52, 0.5))


## The flashlight lying in the snow where Tomas was, and the light it throws
## along the ground. `beam` 0..1.
static func dropped_flashlight(ci: CanvasItem, p: Vector2, beam: float) -> void:
	if beam > 0.0:
		var warm := Color(1.0, 0.94, 0.72)
		ci.draw_polygon(PackedVector2Array([p + Vector2(10, -2), p + Vector2(230, -40), p + Vector2(250, 26), p + Vector2(10, 4)]),
			PackedColorArray([Color(warm, 0.55 * beam), Color(warm, 0.0), Color(warm, 0.0), Color(warm, 0.55 * beam)]))
		ci.draw_set_transform(p + Vector2(120, 4), 0.0, Vector2(1.0, 0.18))
		ci.draw_circle(Vector2.ZERO, 110.0, Color(warm, 0.08 * beam))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_line(p + Vector2(-16, 2), p + Vector2(8, -1), Color("2b2d31"), 7.0)
	ci.draw_line(p + Vector2(4, -1), p + Vector2(11, -2), Color("4a4d52"), 9.0)
	ci.draw_circle(p + Vector2(12, -2), 4.0, Color("fff2c8") if beam > 0.0 else Color("8a8678"))
	# Half sunk: snow over its tail.
	ci.draw_circle(p + Vector2(-14, 4), 6.0, Color("c8d2e2"))


# --- the service road ----------------------------------------------------------------------

## The service road up through the trees, seen side on, the camera riding
## along with a vehicle: `scroll` is how far it has come (px). The road climbs
## at `grade` (radians) toward the right. Trees in two depths, snowbanks.
static func road(ci: CanvasItem, scroll: float, grade: float, mood: String = NIGHT) -> void:
	var sky_top := Color("02040a") if mood == NIGHT else Color("8f9aa8")
	var sky_low := Color("141c34") if mood == NIGHT else Color("cfd4da")
	Kit.vgrad(ci, Rect2(Kit.L, -100, Kit.R - Kit.L, 640), sky_top, sky_low)
	if mood == NIGHT:
		Kit.stars(ci, Rect2(Kit.L, 0, Kit.R - Kit.L, 200), 60, 0.0)
	var slope := tan(grade)
	var road_y := func(x: float) -> float: return 600.0 - (x - 640.0) * slope
	# Far trees (slow), near trees (fast): the parallax tells you it's moving.
	var far := Color("0b1220") if mood == NIGHT else Color("56606c")
	var near := Color("05080e") if mood == NIGHT else Color("2c343c")
	_tree_row(ci, scroll * 0.35, 470.0, 0.75, far, road_y, 0.6, 90.0, 11)
	# The ground falling away below the road, and the bank above it.
	var bank := PackedVector2Array()
	for i in 13:
		var x := Kit.L + (Kit.R - Kit.L) * i / 12.0
		bank.append(Vector2(x, road_y.call(x) - 12.0))
	bank.append(Vector2(Kit.R, 800))
	bank.append(Vector2(Kit.L, 800))
	ci.draw_colored_polygon(bank, Color("8794ac") if mood == NIGHT else Color("dfe3e8"))
	# The road surface, ploughed, with tyre tracks along it.
	var surf := PackedVector2Array([Vector2(Kit.L, road_y.call(Kit.L) - 6.0), Vector2(Kit.R, road_y.call(Kit.R) - 6.0),
		Vector2(Kit.R, road_y.call(Kit.R) + 50.0), Vector2(Kit.L, road_y.call(Kit.L) + 50.0)])
	ci.draw_colored_polygon(surf, Color("5d6880") if mood == NIGHT else Color("9aa2ae"))
	for k in 2:
		var dy := 12.0 + k * 22.0
		ci.draw_line(Vector2(Kit.L, road_y.call(Kit.L) + dy), Vector2(Kit.R, road_y.call(Kit.R) + dy), Color(0.2, 0.24, 0.32, 0.45), 5.0)
	# Snow stakes along the edge, going by.
	var stake_gap := 260.0
	var off := fposmod(scroll, stake_gap)
	var x := Kit.L - off
	while x < Kit.R:
		var y: float = road_y.call(x) - 8.0
		ci.draw_line(Vector2(x, y), Vector2(x, y - 62.0), Color("c8a02a") if mood != NIGHT else Color("8a7428"), 3.0)
		ci.draw_rect(Rect2(x - 2, y - 62, 5, 9), Color("c0392b") if mood != NIGHT else Color("6a2420"))
		x += stake_gap
	_tree_row(ci, scroll, 560.0, 1.0, near, road_y, 1.0, 150.0, 23)


static func _tree_row(ci: CanvasItem, scroll: float, _base: float, scale: float, col: Color, road_y: Callable, depth: float, gap: float, seed: int) -> void:
	var span := Kit.R - Kit.L + 400.0
	var n := int(span / gap) + 2
	for i in n:
		var x := Kit.L - 200.0 + fposmod(i * gap - scroll + Townscape.h(seed + i) * gap * 0.5, span)
		var foot: float = road_y.call(x) - 40.0 * depth - 30.0
		var hh := (150.0 + 120.0 * Townscape.h(seed + i * 7)) * scale
		var w := hh * 0.32
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w, foot), Vector2(x + w, foot), Vector2(x, foot - hh)]), col)
		for k in 3:
			var y := foot - hh * (0.25 + 0.25 * k)
			var ww := w * (0.85 - 0.25 * k)
			ci.draw_line(Vector2(x - ww, y + 6), Vector2(x + ww * 0.5, y), Color(0.8, 0.86, 0.94, 0.28 if depth >= 1.0 else 0.18), 2.0)


## The sign at the bottom of the service road. `lit` 0..1: caught in the
## headlights.
static func service_sign(ci: CanvasItem, foot: Vector2, lit: float) -> void:
	var post := Color("2a2a2a")
	ci.draw_line(foot, foot + Vector2(0, -120), post, 6.0)
	ci.draw_line(foot + Vector2(150, 0), foot + Vector2(150, -120), post, 6.0)
	var board := Rect2(foot + Vector2(-20, -170), Vector2(190, 74))
	var face := Color("1c3a2c").lerp(Color("2f6a4c"), lit)
	ci.draw_rect(board, face)
	ci.draw_rect(board, Color("d8dccc").lerp(Color("f4f6ea"), lit), false, 3.0)
	var ink := Color("9aa496").lerp(Color("f4f6ea"), lit)
	Kit.text(ci, board.position + Vector2(0, 26), "HALVARD OBSERVATORY", 15, ink, HORIZONTAL_ALIGNMENT_CENTER, board.size.x)
	Kit.text(ci, board.position + Vector2(0, 50), "SERVICE ACCESS", 14, ink, HORIZONTAL_ALIGNMENT_CENTER, board.size.x)
	Kit.text(ci, board.position + Vector2(0, 67), "NO THROUGH ROAD", 10, ink.darkened(0.2), HORIZONTAL_ALIGNMENT_CENTER, board.size.x)
	Townscape.snow_ledge(ci, board.position.x - 2, board.end.x + 2, board.position.y, 5.0, 61)
	if lit > 0.0:
		ci.draw_rect(board.grow(6), Color(1.0, 0.95, 0.8, 0.1 * lit))
