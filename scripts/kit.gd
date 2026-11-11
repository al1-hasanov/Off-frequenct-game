class_name Kit
extends RefCounted
## Shared drawing helpers for the flat night-time look.
## Rooms are drawn wider than 1280 px (L to R) so wide phones never show an edge.

const L := -440.0
const R := 1720.0


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, align, width, size, col)


static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	ci.draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


static func wall(ci: CanvasItem, floor_y: float, wall_col: Color, low_col: Color, trim: Color) -> void:
	vgrad(ci, Rect2(L, -100, R - L, floor_y + 100), wall_col.darkened(0.32), wall_col.lightened(0.04))
	vgrad(ci, Rect2(L, floor_y - 120, R - L, 120), low_col, low_col.darkened(0.22))
	# Fixed plaster marks and panel joints: stable when the camera or light moves.
	for i in 110:
		var x := L + fposmod(i * 193.71, R - L)
		var y := 60.0 + fposmod(i * 77.39, floor_y - 200)
		ci.draw_line(Vector2(x,y),Vector2(x+4+ i%9,y+1),Color(0.02,0.03,0.03,0.09),1.0)
	for x in range(-400, 1800, 180):
		ci.draw_line(Vector2(x,floor_y-116),Vector2(x,floor_y-10),low_col.darkened(0.2),1.0)
	ci.draw_rect(Rect2(L, floor_y - 124, R - L, 5), trim)
	ci.draw_rect(Rect2(L, -100, R - L, 126), trim.lightened(0.04))
	ci.draw_rect(Rect2(L, floor_y - 10, R - L, 10), trim)
	ci.draw_line(Vector2(L,floor_y-8),Vector2(R,floor_y-8),trim.lightened(0.17),1.0)
	vgrad(ci,Rect2(L,26,R-L,65),Color(0,0,0,0.24),Color(0,0,0,0))


static func floor_tiles(ci: CanvasItem, floor_y: float, base: Color, line: Color) -> void:
	vgrad(ci,Rect2(L, floor_y, R - L, 400),base.darkened(0.22),base.lightened(0.08))
	var vanish := Vector2(640, floor_y - 1100)
	for i in range(-14, 32):
		var top := Vector2(float(i) * 90.0, floor_y)
		var dir := (top - vanish).normalized()
		ci.draw_line(top, top + dir * 300.0, line, 2.0)
	var y := floor_y + 12.0
	var step := 14.0
	while y < 780.0:
		ci.draw_line(Vector2(L, y), Vector2(R, y), line, 2.0)
		y += step
		step *= 1.45
	for i in 28:
		var p := Vector2(L+fposmod(i*119.3,R-L),floor_y+14+fposmod(i*17.31,100))
		ci.draw_line(p,p+Vector2(12+i%13,1),Color(0.6,0.67,0.66,0.05),1.0)


static func ceiling_light(ci: CanvasItem, x: float, floor_y: float, on: bool) -> void:
	var w := 190.0
	var y := 38.0
	ci.draw_rect(Rect2(x - w / 2, y - 7, w, 14), Color("1a1f22"))
	if on:
		ci.draw_rect(Rect2(x - w / 2 + 8, y - 3, w - 16, 6), Color("eef4e8"))
		var glow := PackedVector2Array([
			Vector2(x - w / 2, y + 7), Vector2(x + w / 2, y + 7), Vector2(x + w * 1.15, floor_y), Vector2(x - w * 1.15, floor_y)])
		ci.draw_colored_polygon(glow, Color(0.9, 0.97, 0.88, 0.05))
	else:
		ci.draw_rect(Rect2(x - w / 2 + 8, y - 3, w - 16, 6), Color("293033"))


static func emergency_lamp(ci: CanvasItem, p: Vector2, t: float) -> void:
	ci.draw_rect(Rect2(p.x - 22, p.y - 9, 44, 18), Color("2a1010"))
	var a := 0.75 + 0.25 * sin(t * 3.0)
	ci.draw_rect(Rect2(p.x - 18, p.y - 6, 36, 12), Color(1.0, 0.25, 0.2, a))
	ci.draw_circle(p, 90.0, Color(1.0, 0.2, 0.15, 0.05 * a))


static func plate(ci: CanvasItem, center: Vector2, s: String, size: int = 15) -> void:
	var w := maxf(110.0, s.length() * size * 0.62 + 28.0)
	var r := Rect2(center.x - w / 2, center.y - 15, w, 30)
	ci.draw_rect(r, Color("1b2225"))
	ci.draw_rect(r, Color("3a4448"), false, 2.0)
	text(ci, Vector2(r.position.x, r.position.y + 21), s, size, Color("cfd7cf"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


static func door(ci: CanvasItem, r: Rect2, col: Color, label: String = "") -> void:
	ci.draw_rect(r.grow(8), Color("15191b"))
	ci.draw_rect(r, col)
	vgrad(ci,r,col.lightened(0.08),col.darkened(0.12))
	ci.draw_line(r.position+Vector2(2,2),Vector2(r.position.x+2,r.end.y-2),col.lightened(0.3),2.0)
	for y in [28.0,r.size.y-46.0]:
		ci.draw_rect(Rect2(r.position+Vector2(-3,y),Vector2(5,20)),Color("717773"))
	ci.draw_rect(Rect2(r.position + Vector2(12, 96), Vector2(r.size.x - 24, r.size.y * 0.28)), col.darkened(0.14), false, 2.0)
	ci.draw_rect(Rect2(r.position + Vector2(12, r.size.y * 0.62), Vector2(r.size.x - 24, r.size.y * 0.32)), col.darkened(0.14), false, 2.0)
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.28, 24), Vector2(r.size.x * 0.44, 56)), Color("0b1116"))
	ci.draw_circle(r.position + Vector2(r.size.x - 15, r.size.y * 0.55), 5.0, Color("9aa3a8"))
	ci.draw_line(r.position+Vector2(r.size.x-15,r.size.y*.55),r.position+Vector2(r.size.x-27,r.size.y*.55),Color("bdc5bb"),3.0,true)
	ci.draw_rect(Rect2(r.position+Vector2(8,r.size.y-24),Vector2(r.size.x-16,18)),col.darkened(0.22))
	if label != "":
		plate(ci, Vector2(r.get_center().x, r.position.y - 30), label)


static func stars(ci: CanvasItem, r: Rect2, n: int, t: float) -> void:
	for i in n:
		var x := r.position.x + fposmod(i * 263.7, r.size.x)
		var y := r.position.y + fposmod(i * 97.31 + i * i * 0.37, r.size.y)
		var a := 0.35 + 0.3 * sin(t * 1.3 + i * 1.7)
		ci.draw_circle(Vector2(x, y), 1.3 if i % 5 else 1.9, Color(0.85, 0.9, 1.0, a))


## A radio telescope silhouette standing on `base`.
static func dish(ci: CanvasItem, base: Vector2, s: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		base + Vector2(-20, 0) * s, base + Vector2(20, 0) * s, base + Vector2(8, -72) * s, base + Vector2(-8, -72) * s]), col)
	var c := base + Vector2(0, -84) * s
	var rot := -0.45
	var pts := PackedVector2Array()
	for i in 25:
		var a := PI * i / 24.0
		pts.append(c + Vector2(cos(a) * 74.0, sin(a) * 30.0).rotated(rot) * s)
	ci.draw_colored_polygon(pts, col)
	var focus := c + Vector2(0, -60).rotated(rot) * s
	ci.draw_line(c + Vector2(-74, 0).rotated(rot) * s, focus, col, 2.5 * s)
	ci.draw_line(c + Vector2(74, 0).rotated(rot) * s, focus, col, 2.5 * s)
	ci.draw_circle(focus, 5.0 * s, col)
	ci.draw_line(c, base + Vector2(0, -60) * s, col, 6.0 * s)


static func pines(ci: CanvasItem, base_y: float, col: Color) -> void:
	var x := L
	var i := 0
	while x < R:
		var h := 60.0 + 34.0 * absf(sin(i * 1.7)) + 20.0 * absf(sin(i * 0.43))
		var w := 26.0 + 8.0 * absf(sin(i * 2.3))
		ci.draw_line(Vector2(x,base_y+2),Vector2(x,base_y-h),col,4.0)
		for tier in 5:
			var tip := base_y-h+tier*h*.16
			var spread := w*(.32+tier*.17)
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(x,tip),Vector2(x+spread,tip+h*.36),Vector2(x+spread*.2,tip+h*.29),
				Vector2(x,tip+h*.32),Vector2(x-spread,tip+h*.36)]),col)
		x += 30.0 + 14.0 * absf(sin(i * 3.1))
		i += 1


## The view through a window at night: sky, mountains, the dish, a snowy field.
static func night_view(ci: CanvasItem, r: Rect2, t: float, dish_x: float, dish_s: float) -> void:
	vgrad(ci, r, Color("04060d"), Color("1b2542"))
	stars(ci, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.55)), int(r.size.x / 9.0), t)
	var horizon := r.position.y + r.size.y * 0.72
	var m := PackedVector2Array([Vector2(r.position.x, horizon)])
	var steps := 8
	for i in steps + 1:
		var x := r.position.x + r.size.x * i / steps
		m.append(Vector2(x, horizon - 18.0 - 26.0 * absf(sin(i * 1.9 + r.position.x * 0.01))))
	m.append(Vector2(r.end.x, horizon))
	ci.draw_colored_polygon(m, Color("10172b"))
	ci.draw_rect(Rect2(r.position.x, horizon, r.size.x, r.end.y - horizon), Color("7f8ca4"))
	if dish_x >= 0.0:
		dish(ci, Vector2(dish_x, horizon + 4.0), dish_s, Color("0a0e18"))


static func window_frame(ci: CanvasItem, r: Rect2, panes: int) -> void:
	var frame := Color("1b2124")
	# Quiet glass sheen and frost along the lower edge; never obscure the view.
	ci.draw_colored_polygon(PackedVector2Array([r.position+Vector2(12,0),r.position+Vector2(40,0),Vector2(r.position.x+90,r.end.y),Vector2(r.position.x+65,r.end.y)]),Color(0.64,0.82,0.9,0.055))
	for i in int(r.size.x/18):
		var p := Vector2(r.position.x+9+i*18,r.end.y)
		ci.draw_line(p,p+Vector2(-4,-6-i%4),Color(0.7,0.84,0.9,0.2),1.0)
	ci.draw_rect(r.grow(10), frame, false, 20.0)
	for i in range(1, panes):
		var x := r.position.x + r.size.x * i / panes
		ci.draw_rect(Rect2(x - 5, r.position.y, 10, r.size.y), frame)
	ci.draw_rect(Rect2(r.position.x - 16, r.end.y + 8, r.size.x + 32, 10), Color("2a3134"))
	ci.draw_line(Vector2(r.position.x-14,r.end.y+9),Vector2(r.end.x+14,r.end.y+9),Color("4b5557"),1.0)


## Sollen's snowcat, side view, facing right. `base` is the ground under its middle.
static func snowcat(ci: CanvasItem, base: Vector2, s: float, t: float, moving: bool, body: Color = Color("c8642a")) -> void:
	var p := func(x: float, y: float) -> Vector2: return base + Vector2(x, y) * s
	var track := Color("1f2124")
	ci.draw_rect(Rect2(p.call(-200, -56), Vector2(400, 56) * s), track)
	ci.draw_circle(p.call(-200, -28), 28.0 * s, track)
	ci.draw_circle(p.call(200, -28), 28.0 * s, track)
	for i in 7:
		var x := -180.0 + i * 60.0
		ci.draw_circle(p.call(x, -28), 18.0 * s, Color("3a3d42"))
		ci.draw_circle(p.call(x, -28), 6.0 * s, Color("6a6f73"))
	var off := fmod(t * 60.0, 20.0) if moving else 0.0
	var x2 := -200.0 + off
	while x2 < 200.0:
		ci.draw_line(p.call(x2, -56), p.call(x2, -50), Color("4a4d52"), 3.0 * s)
		x2 += 20.0
	ci.draw_colored_polygon(PackedVector2Array([
		p.call(-190, -56), p.call(210, -56), p.call(218, -110), p.call(150, -126), p.call(-190, -126)]), body)
	ci.draw_rect(Rect2(p.call(-190, -96), Vector2(400, 8) * s), body.darkened(0.25))
	ci.draw_colored_polygon(PackedVector2Array([
		p.call(-120, -126), p.call(110, -126), p.call(90, -226), p.call(-110, -226)]), body.lightened(0.05))
	ci.draw_rect(Rect2(p.call(-100, -214), Vector2(84, 74) * s), Color("1a2430"))
	ci.draw_colored_polygon(PackedVector2Array([p.call(0, -214), p.call(84, -214), p.call(102, -140), p.call(0, -140)]), Color("1a2430"))
	ci.draw_line(p.call(-104, -230), p.call(96, -230), Color("2a2a2a"), 6.0 * s)
	ci.draw_rect(Rect2(p.call(196, -108), Vector2(16, 18) * s), Color("e8e0c0"))
	ci.draw_rect(Rect2(p.call(-170, -120), Vector2(40, 8) * s), Color("2a2a2a"))
	# Windscreen reflection, seals, access panels and a perforated engine grille.
	ci.draw_line(p.call(-96,-208),p.call(-37,-147),Color(0.55,0.72,0.8,0.18),6*s)
	ci.draw_line(p.call(8,-208),p.call(76,-146),Color(0.55,0.72,0.8,0.12),5*s)
	ci.draw_line(p.call(42,-145),p.call(72,-185),Color("111b22"),3*s)
	ci.draw_rect(Rect2(p.call(-116,-129),Vector2(104,65)*s),body.darkened(.2),false,1.5*s)
	ci.draw_rect(Rect2(p.call(-35,-120),Vector2(17,4)*s),Color("b1ada0"))
	for i in 10:
		ci.draw_line(p.call(118+i*7,-111),p.call(118+i*7,-85),body.darkened(.4),2*s)
	ci.draw_line(p.call(-104,-234),p.call(94,-234),Color("bac5be"),3*s)
	ci.draw_rect(Rect2(p.call(-176,-88),Vector2(52,18)*s),Color("d4c3a0"))
	text(ci,p.call(-170,-75),"HRO 03",int(11*s),Color("383c36"))
