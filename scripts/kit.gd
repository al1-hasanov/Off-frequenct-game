class_name Kit
extends RefCounted
## Shared drawing helpers for the flat night-time look.
## Rooms are drawn wider than 1280 px (L to R) so wide phones never show an edge.

const L := -440.0
const R := 1720.0


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, align, width, size, col)


static func text_width(s: String, size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Einstein's field equation with his cosmological constant, written out with
## its subscripts: G_μν + Λg_μν = 8πG T_μν. `pos` is the left end of the
## baseline. Returns the width drawn.
static func field_equation(ci: CanvasItem, pos: Vector2, size: int, col: Color) -> float:
	var sub := maxi(8, int(size * 0.55))
	var drop := size * 0.28
	var x := pos.x
	for part in [["G", false], ["μν", true], [" + Λg", false], ["μν", true], [" = 8πG T", false], ["μν", true]]:
		var s: String = part[0]
		var k := sub if part[1] else size
		text(ci, Vector2(x, pos.y + (drop if part[1] else 0.0)), s, k, col)
		x += text_width(s, k)
	return x - pos.x


static var _soft: ImageTexture


## A soft round glow of colour `col` and radius r at c (a lamp, a porch light).
static func soft_glow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(soft_tex(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


## A white dot that fades to nothing at its edge (glows, snowflakes, fireflies).
static func soft_tex() -> ImageTexture:
	if _soft == null:
		var n := 64
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
				img.set_pixel(x, y, Color(1, 1, 1, pow(clampf(1.0 - d, 0.0, 1.0), 2.2)))
		_soft = ImageTexture.create_from_image(img)
	return _soft


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
	var bright := Env.now().stars()
	if bright <= 0.0:
		return
	if bright < 1.0:
		n = int(n * 0.3)
	for i in n:
		var x := r.position.x + fposmod(i * 263.7, r.size.x)
		var y := r.position.y + fposmod(i * 97.31 + i * i * 0.37, r.size.y)
		var a := (0.35 + 0.3 * sin(t * 1.3 + i * 1.7)) * bright
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
	var e := Env.now()
	col = e.pine(col)
	# Out of the dark, snow shows on their branches.
	var snow := e.snowy() and not (e.night() or e.story())
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
			if snow:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x, tip), Vector2(x + spread * 0.55, tip + h * 0.2),
					Vector2(x, tip + h * 0.14), Vector2(x - spread * 0.55, tip + h * 0.2)]), e.shade(Color("e8eef6")))
		x += 30.0 + 14.0 * absf(sin(i * 3.1))
		i += 1


## The view through a window at night: sky, mountains, the dish, a snowy field.
static func night_view(ci: CanvasItem, r: Rect2, t: float, dish_x: float, dish_s: float) -> void:
	var e := Env.now()
	if not e.story():
		_station_view(ci, r, t, dish_x, dish_s, e)
		return
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


## The view through a window on another station: its sky, its season.
static func _station_view(ci: CanvasItem, r: Rect2, t: float, dish_x: float, dish_s: float, e: Env) -> void:
	var sk: Array = e.sky()
	vgrad(ci, r, sk[0], sk[1])
	stars(ci, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.55)), int(r.size.x / 9.0), t)
	var horizon := r.position.y + r.size.y * 0.72
	var m := PackedVector2Array([Vector2(r.position.x, horizon)])
	var steps := 8
	for i in steps + 1:
		var x := r.position.x + r.size.x * i / steps
		m.append(Vector2(x, horizon - 18.0 - 26.0 * absf(sin(i * 1.9 + r.position.x * 0.01))))
	m.append(Vector2(r.end.x, horizon))
	ci.draw_colored_polygon(m, e.hills())
	var g: Array = e.ground()
	if e.state == "gone":
		g = [Color("e8ebf0"), Color("f4f6f8")]
	vgrad(ci, Rect2(r.position.x, horizon, r.size.x, r.end.y - horizon), g[1], g[0])
	if dish_x >= 0.0 and e.state != "gone":
		dish(ci, Vector2(dish_x, horizon + 4.0), dish_s, Color("0a0e18") if e.night() else e.shade(Color("5a606a")))


static func window_frame(ci: CanvasItem, r: Rect2, panes: int) -> void:
	var frame := Color("1b2124")
	# Quiet glass sheen and frost along the lower edge; never obscure the view.
	ci.draw_colored_polygon(PackedVector2Array([r.position+Vector2(12,0),r.position+Vector2(40,0),Vector2(r.position.x+90,r.end.y),Vector2(r.position.x+65,r.end.y)]),Color(0.64,0.82,0.9,0.055))
	for i in int(r.size.x/18):
		var p := Vector2(r.position.x+9+i*18,r.end.y)
		ci.draw_line(p,p+Vector2(-4,-6-i%4),Color(0.7,0.84,0.9,0.2),1.0)
	# The frame sits just outside the opening: 12 px, plus a 14 px sill. Keep
	# other wall objects at least 16 px clear of the opening.
	ci.draw_rect(r.grow(6), frame, false, 12.0)
	ci.draw_rect(r.grow(1), Color("0d1113"), false, 2.0)
	for i in range(1, panes):
		var x := r.position.x + r.size.x * i / panes
		ci.draw_rect(Rect2(x - 5, r.position.y, 10, r.size.y), frame)
	ci.draw_rect(Rect2(r.position.x - 14, r.end.y + 6, r.size.x + 28, 9), Color("2a3134"))
	ci.draw_line(Vector2(r.position.x-12,r.end.y+7),Vector2(r.end.x+12,r.end.y+7),Color("4b5557"),1.0)


## Sollen's snowcat, side view, facing right. `base` is the ground under its
## middle. Kept for older callers: Vehicles.snowcat() takes the full options.
static func snowcat(ci: CanvasItem, base: Vector2, s: float, t: float, moving: bool, body: Color = Color("c8642a")) -> void:
	Vehicles.snowcat(ci, base, s, t, {"moving": moving, "body": body})
