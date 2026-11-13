class_name Townscape
extends RefCounted
## Building parts for Halvard's streets: brick, clapboard and stone walls;
## cornices with brackets; windows with lintels, sills and curtains;
## storefronts, doors, awnings; snow on every ledge, icicles and banks; a
## hillside of lit houses and the church. Everything is drawn in code.

## A stable pseudo-random number in 0..1 for an integer seed.
static func h(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 78.233) * 43758.5453, 1.0)


# --- walls ----------------------------------------------------------------------------

## A wall: "brick" (each brick a slightly different tone), "siding"
## (clapboard with shadow lines) or "stone" (large dressed blocks).
static func wall(ci: CanvasItem, r: Rect2, base: Color, kind: String = "brick") -> void:
	Kit.vgrad(ci, r, base.lightened(0.04), base.darkened(0.16))
	match kind:
		"brick":
			var bh := 9.0
			var bw := 24.0
			var rows := int(r.size.y / bh)
			for row in rows:
				var y := r.position.y + row * bh
				var off := (bw * 0.5) if row % 2 == 1 else 0.0
				var x := r.position.x - off
				var k := 0
				while x < r.end.x:
					var x0 := maxf(x + 1.0, r.position.x)
					var x1 := minf(x + bw - 1.0, r.end.x)
					var n := h(row * 131 + k * 17 + int(r.position.x))
					if x1 > x0 and (n > 0.55 or n < 0.12):
						var c := base.lightened(0.08) if n > 0.8 else (base.darkened(0.12) if n < 0.12 else base.lightened(0.02))
						ci.draw_rect(Rect2(x0, y + 1.0, x1 - x0, bh - 2.0), c)
					x += bw
					k += 1
				ci.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), base.darkened(0.3), 1.0)
		"siding":
			var bh2 := 12.0
			for row in int(r.size.y / bh2):
				var y2 := r.position.y + row * bh2
				ci.draw_rect(Rect2(r.position.x, y2, r.size.x, 3.0), base.darkened(0.22))
				ci.draw_line(Vector2(r.position.x, y2 + 3.0), Vector2(r.end.x, y2 + 3.0), base.lightened(0.12), 1.0)
		"stone":
			var bh3 := 22.0
			for row in int(r.size.y / bh3):
				var y3 := r.position.y + row * bh3
				ci.draw_line(Vector2(r.position.x, y3), Vector2(r.end.x, y3), base.darkened(0.28), 1.5)
				var x3 := r.position.x + (20.0 if row % 2 == 1 else 0.0)
				var k3 := 0
				while x3 < r.end.x:
					ci.draw_line(Vector2(x3, y3), Vector2(x3, y3 + bh3), base.darkened(0.28), 1.5)
					if h(row * 7 + k3) > 0.6:
						ci.draw_rect(Rect2(x3 + 2, y3 + 2, minf(36.0, r.end.x - x3 - 2), bh3 - 4), base.lightened(0.04))
					x3 += 40.0 + 12.0 * h(row * 3 + k3)
					k3 += 1
	# Soot under the roofline and salt-stain at the foot of the wall.
	Kit.vgrad(ci, Rect2(r.position.x, r.position.y, r.size.x, 40), Color(0, 0, 0, 0.22), Color(0, 0, 0, 0))
	Kit.vgrad(ci, Rect2(r.position.x, r.end.y - 30, r.size.x, 30), Color(0.8, 0.82, 0.86, 0), Color(0.8, 0.82, 0.86, 0.1))
	# The corners: a little shadow on the right, a lit edge on the left.
	ci.draw_rect(Rect2(r.end.x - 6, r.position.y, 6, r.size.y), Color(0, 0, 0, 0.22))
	ci.draw_rect(Rect2(r.position.x, r.position.y, 3, r.size.y), Color(1, 1, 1, 0.05))


## A projecting cornice along the top of a facade: lip, frieze, brackets,
## and snow lying on top.
static func cornice(ci: CanvasItem, x0: float, x1: float, y: float, col: Color, brackets: bool = true) -> void:
	ci.draw_rect(Rect2(x0 - 8, y - 4, x1 - x0 + 16, 8), col.lightened(0.08))
	ci.draw_rect(Rect2(x0 - 5, y + 4, x1 - x0 + 10, 5), col.darkened(0.15))
	ci.draw_rect(Rect2(x0 - 2, y + 9, x1 - x0 + 4, 12), col)
	ci.draw_line(Vector2(x0 - 8, y + 4), Vector2(x1 + 8, y + 4), Color(0, 0, 0, 0.4), 1.0)
	if brackets:
		var n := int((x1 - x0) / 34.0)
		for i in n + 1:
			var bx := x0 + (x1 - x0) * i / maxf(1.0, n)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 4, y + 9), Vector2(bx + 4, y + 9),
				Vector2(bx + 3, y + 24), Vector2(bx - 3, y + 24)]), col.darkened(0.22))
	# Dentils.
	var x := x0
	while x < x1 - 4:
		ci.draw_rect(Rect2(x, y + 21, 4, 4), col.darkened(0.25))
		x += 8.0
	snow_ledge(ci, x0 - 9, x1 + 9, y - 4, 7.0, int(x0))


# --- snow ----------------------------------------------------------------------------

## A lumpy line of snow lying on a ledge whose top is at y.
static func snow_ledge(ci: CanvasItem, x0: float, x1: float, y: float, thick: float, seed: int = 0) -> void:
	if not Env.now().snowy():
		return
	var pts := PackedVector2Array([Vector2(x0, y + 1)])
	var n := maxi(3, int((x1 - x0) / 14.0))
	for i in n + 1:
		var x := lerpf(x0 + 2, x1 - 2, float(i) / n)
		pts.append(Vector2(x, y - thick * (0.55 + 0.45 * h(seed + i * 13))))
	pts.append(Vector2(x1, y + 1))
	ci.draw_colored_polygon(pts, Color("dfe6f0"))
	ci.draw_polyline(pts.slice(1, pts.size() - 1), Color("f6f8fc"), 1.5, true)
	ci.draw_line(Vector2(x0, y + 1), Vector2(x1, y + 1), Color(0.55, 0.62, 0.74, 0.5), 1.0)


static func icicles(ci: CanvasItem, x0: float, x1: float, y: float, seed: int = 0) -> void:
	if not Env.now().snowy():
		return
	var x := x0 + 4
	var i := 0
	while x < x1 - 2:
		var length := 4.0 + 16.0 * h(seed + i * 7)
		if h(seed + i * 3) > 0.35:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, y), Vector2(x + 2, y), Vector2(x, y + length)]),
				Color(0.85, 0.92, 1.0, 0.75))
		x += 6.0 + 8.0 * h(seed + i)
		i += 1


## A snowbank along the foot of a wall or kerb.
static func snowbank(ci: CanvasItem, x0: float, x1: float, base_y: float, height: float, seed: int = 0) -> void:
	var e := Env.now()
	var body := Color("cdd6e4")
	var top := Color("eef2f8")
	if e.thaw():
		# What's left in spring: low, grey, gritty.
		height *= 0.45
		body = e.shade(Color("9aa0a6"))
		top = e.shade(Color("b4b8bc"))
	elif not e.snowy():
		return
	elif not (e.story() or e.night()):
		body = e.shade(Color("e2e8f0"))
		top = e.shade(Color("fafcff"))
	var pts := PackedVector2Array([Vector2(x0, base_y)])
	var n := maxi(3, int((x1 - x0) / 22.0))
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / n)
		var hh := height * (0.4 + 0.6 * sin(PI * float(i) / n)) * (0.75 + 0.25 * h(seed + i))
		pts.append(Vector2(x, base_y - hh))
	pts.append(Vector2(x1, base_y))
	ci.draw_colored_polygon(pts, body)
	ci.draw_polyline(pts.slice(1, pts.size() - 1), top, 2.0, true)


# --- windows, doors, storefronts ---------------------------------------------------------

## A sash window with a brick or stone lintel, a sill with snow on it, and
## either warm light and curtains (lit) or the night reflected in the glass.
static func window(ci: CanvasItem, r: Rect2, lit: bool, frame: Color = Color("2a2420"), arch: bool = false, curtains: bool = true) -> void:
	# Lintel.
	if arch:
		var c := r.get_center()
		ci.draw_arc(Vector2(c.x, r.position.y + 6), r.size.x * 0.5 + 5, PI, TAU, 16, Color("6a4a3e"), 9.0)
		ci.draw_arc(Vector2(c.x, r.position.y + 6), r.size.x * 0.5 + 5, PI + 0.05, TAU - 0.05, 16, Color("7a5a4c"), 2.0)
	else:
		ci.draw_rect(Rect2(r.position.x - 6, r.position.y - 10, r.size.x + 12, 9), Color("8a8478"))
		ci.draw_rect(Rect2(r.position.x - 6, r.position.y - 2, r.size.x + 12, 2), Color(0, 0, 0, 0.35))
	# Glass.
	var e := Env.now()
	if e.state == "derelict":
		_boarded(ci, r, frame)
		return
	if e.day():
		# Daylight: the sky in the glass, the room behind it dim.
		var sk: Array = e.sky()
		Kit.vgrad(ci, r, (sk[0] as Color).lerp(Color("3a4048"), 0.45), (sk[1] as Color).lerp(Color("2a2e34"), 0.6))
		ci.draw_line(r.position + Vector2(r.size.x * 0.2, r.size.y), r.position + Vector2(r.size.x * 0.7, 0), Color(1, 1, 1, 0.12), r.size.x * 0.2)
		if curtains and e.state == "home":
			ci.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x * 0.22, 0),
				r.position + Vector2(r.size.x * 0.14, r.size.y), r.position + Vector2(0, r.size.y)]), Color(0.82, 0.78, 0.7, 0.8))
			ci.draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x * 0.78, 0),
				r.position + Vector2(r.size.x * 0.86, r.size.y), r.end]), Color(0.82, 0.78, 0.7, 0.8))
	elif lit:
		Kit.vgrad(ci, r, Color("ffd99a"), Color("e8a85a"))
		if curtains:
			ci.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x * 0.24, 0),
				r.position + Vector2(r.size.x * 0.15, r.size.y * 0.7), r.position + Vector2(r.size.x * 0.2, r.size.y),
				r.position + Vector2(0, r.size.y)]), Color(0.75, 0.35, 0.25, 0.55))
			ci.draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x * 0.76, 0),
				r.position + Vector2(r.size.x * 0.85, r.size.y * 0.7), r.position + Vector2(r.size.x * 0.8, r.size.y),
				r.end]), Color(0.75, 0.35, 0.25, 0.55))
	elif e.night() or e.story():
		Kit.vgrad(ci, r, Color("1c2638"), Color("0b0f18"))
		ci.draw_line(r.position + Vector2(r.size.x * 0.2, r.size.y), r.position + Vector2(r.size.x * 0.7, 0), Color(0.6, 0.7, 0.9, 0.08), r.size.x * 0.18)
	else:
		# Dusk or dawn in a dark window.
		var sk2: Array = e.sky()
		Kit.vgrad(ci, r, (sk2[0] as Color).darkened(0.35), Color("14161c"))
		ci.draw_line(r.position + Vector2(r.size.x * 0.2, r.size.y), r.position + Vector2(r.size.x * 0.7, 0), Color(1, 0.85, 0.75, 0.1), r.size.x * 0.18)
	# Frame and sash bars.
	ci.draw_rect(r, frame, false, 4.0)
	ci.draw_line(Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), frame, 3.0)
	ci.draw_line(Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), frame, 3.0)
	# Sill, with snow.
	ci.draw_rect(Rect2(r.position.x - 7, r.end.y + 1, r.size.x + 14, 6), Color("8a8478"))
	ci.draw_rect(Rect2(r.position.x - 7, r.end.y + 7, r.size.x + 14, 2), Color(0, 0, 0, 0.35))
	snow_ledge(ci, r.position.x - 8, r.end.x + 8, r.end.y + 1, 4.0, int(r.position.x * 3))


## A window nobody has lived behind for years: boards nailed across it.
static func _boarded(ci: CanvasItem, r: Rect2, frame: Color) -> void:
	ci.draw_rect(r, Color("0e1014"))
	var n := maxi(2, int(r.size.y / 18.0))
	for i in n:
		var y := r.position.y + (i + 0.5) * r.size.y / n
		var tilt := (h(int(r.position.x) + i * 7) - 0.5) * 10.0
		var c := Color("6a5a46").darkened(0.25 * h(i * 13 + int(r.position.y)))
		ci.draw_line(Vector2(r.position.x - 4, y - tilt), Vector2(r.end.x + 4, y + tilt), c, minf(14.0, r.size.y / n - 3.0))
		ci.draw_circle(Vector2(r.position.x + 3, y - tilt * 0.8), 1.4, Color("2a2a2a"))
		ci.draw_circle(Vector2(r.end.x - 3, y + tilt * 0.8), 1.4, Color("2a2a2a"))
	ci.draw_rect(r, frame, false, 4.0)
	ci.draw_rect(Rect2(r.position.x - 7, r.end.y + 1, r.size.x + 14, 6), Color("6a6458"))


## A storefront: bulkhead below, transom above, a big pane of glass.
## The room draws what's inside; this draws the frame around it.
static func storefront_frame(ci: CanvasItem, r: Rect2, col: Color) -> void:
	ci.draw_rect(Rect2(r.position.x - 6, r.position.y - 12, r.size.x + 12, 12), col.darkened(0.1))
	for k in 4:
		var x := r.position.x + r.size.x * (0.125 + 0.25 * k)
		ci.draw_line(Vector2(x, r.position.y - 11), Vector2(x, r.position.y - 1), col.darkened(0.4), 2.0)
	ci.draw_rect(Rect2(r.position.x - 6, r.end.y, r.size.x + 12, 44), col)
	for k in 3:
		ci.draw_rect(Rect2(r.position.x + 6 + k * (r.size.x - 12) / 3.0, r.end.y + 8, (r.size.x - 12) / 3.0 - 8, 28), col.darkened(0.15), false, 2.0)
	ci.draw_rect(r, col.darkened(0.25), false, 5.0)
	ci.draw_line(r.position + Vector2(8, 8), r.position + Vector2(r.size.x * 0.3, r.size.y - 8), Color(1, 1, 1, 0.08), 10.0)


## A street door: casing, panels, a glass light, a brass handle and a step.
static func door(ci: CanvasItem, r: Rect2, col: Color, glass: Color = Color(0, 0, 0, 0)) -> void:
	ci.draw_rect(Rect2(r.position.x - 6, r.position.y - 8, r.size.x + 12, r.size.y + 8), col.darkened(0.35))
	Kit.vgrad(ci, r, col.lightened(0.06), col.darkened(0.12))
	if glass.a > 0.0:
		ci.draw_rect(Rect2(r.position.x + 8, r.position.y + 10, r.size.x - 16, r.size.y * 0.36), glass)
		ci.draw_rect(Rect2(r.position.x + 8, r.position.y + 10, r.size.x - 16, r.size.y * 0.36), col.darkened(0.35), false, 2.0)
	ci.draw_rect(Rect2(r.position.x + 8, r.position.y + r.size.y * 0.5, r.size.x - 16, r.size.y * 0.42), col.darkened(0.1), false, 2.0)
	ci.draw_circle(Vector2(r.end.x - 9, r.position.y + r.size.y * 0.52), 3.0, Color("c8a24a"))
	ci.draw_rect(Rect2(r.position.x - 10, r.end.y - 4, r.size.x + 20, 6), Color("6a6862"))
	snow_ledge(ci, r.position.x - 10, r.position.x + 6, r.end.y - 4, 5.0, int(r.position.x))


## A striped canvas awning with a scalloped valance, snow on top and
## icicles hanging off the front.
static func awning(ci: CanvasItem, x0: float, x1: float, y: float, depth: float, a: Color, b: Color) -> void:
	var stripes := int((x1 - x0) / 14.0)
	for i in stripes:
		var sx0 := lerpf(x0, x1, float(i) / stripes)
		var sx1 := lerpf(x0, x1, float(i + 1) / stripes)
		var c := a if i % 2 == 0 else b
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sx0 + 3, y), Vector2(sx1 + 3, y), Vector2(sx1 - 3, y + depth), Vector2(sx0 - 3, y + depth)]), c)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sx0 - 3, y + depth), Vector2(sx1 - 3, y + depth),
			Vector2((sx0 + sx1) * 0.5 - 3, y + depth + 6)]), c.darkened(0.12))
	Kit.vgrad(ci, Rect2(x0, y, x1 - x0, depth), Color(1, 1, 1, 0.06), Color(0, 0, 0, 0.2))
	snow_ledge(ci, x0 + 2, x1 + 4, y, 6.0, int(x0 * 7))
	icicles(ci, x0 - 2, x1 - 4, y + depth + 4, int(x0))


# --- backdrops -------------------------------------------------------------------------

## What's in a station's sky besides stars: the moon on a clear night, the sun
## by day, clouds lit by the dusk or the dawn, or a low grey lid of cloud.
static func sky_extras(ci: CanvasItem, e: Env, sun: Vector2) -> void:
	if e.state == "gone":
		return
	if e.moon:
		var m := Vector2(sun.x + 200.0, sun.y + 20.0)
		Kit.soft_glow(ci, m, 90.0, Color(0.85, 0.9, 1.0, 0.18))
		ci.draw_circle(m, 26.0, Color("e8ecf2"))
		ci.draw_circle(m + Vector2(-8, -6), 6.0, Color(0.75, 0.78, 0.84, 0.6))
		ci.draw_circle(m + Vector2(10, 10), 4.0, Color(0.75, 0.78, 0.84, 0.5))
	if e.overcast:
		var c := e.shade(Color("a8aeb8"))
		for k in 7:
			_cloud(ci, Vector2(Kit.L + 120 + k * 330.0 + 80.0 * h(k), 30 + 50 * h(k * 3)), 2.2 + 0.8 * h(k * 5), Color(c, 0.5))
		return
	if e.day():
		Kit.soft_glow(ci, sun, 170.0, Color(1.0, 0.98, 0.9, 0.45))
		ci.draw_circle(sun, 30.0, Color(1.0, 0.99, 0.94))
	if e.hour != "night":
		var cc := Color(1, 1, 1, 0.8) if e.day() else (Color(1.0, 0.7, 0.6, 0.7) if e.hour == "dusk" else Color(1.0, 0.84, 0.82, 0.6))
		for k in 5:
			_cloud(ci, Vector2(-260.0 + k * 400.0 + 120.0 * h(k * 7 + 3), 70.0 + 90.0 * h(k * 5 + 1)), 1.0 + 0.7 * h(k * 11), cc)


## A cumulus: soft puffs, flat underneath.
static func _cloud(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var seed := int(c.x)
	for i in 7:
		var off := Vector2((i - 3) * 30.0 * s, -absf(sin(i * 1.3 + seed)) * 14.0 * s - (14.0 * s if i in [2, 3, 4] else 0.0))
		ci.draw_set_transform(c + off, 0.0, Vector2(1.5, 1.0))
		Kit.soft_glow(ci, Vector2.ZERO, (26.0 + 12.0 * h(seed + i)) * s, Color(col, col.a * 0.55))
	ci.draw_set_transform(c + Vector2(0, 4 * s), 0.0, Vector2(4.2, 0.6))
	Kit.soft_glow(ci, Vector2.ZERO, 34.0 * s, Color(col, col.a * 0.5))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Sirens on this station: something's burning, a glow over the hill and a
## column of smoke.
static func fire_glow(ci: CanvasItem, e: Env, at: Vector2) -> void:
	Kit.soft_glow(ci, at, 380.0, Color(1.0, 0.45, 0.15, 0.45))
	Kit.soft_glow(ci, at + Vector2(0, 10), 160.0, Color(1.0, 0.65, 0.25, 0.5))
	for k in 6:
		var p := at + Vector2(k * 34.0 - k * k * 2.0, -60.0 - k * 52.0)
		Kit.soft_glow(ci, p, 70.0 + k * 14.0, Color(0.12, 0.1, 0.1, 0.35) if not e.day() else Color(0.35, 0.33, 0.32, 0.4))

## Halvard climbing the hillside behind Main Street: rows of little houses,
## snow on every roof, and (tonight) a light in every window.
static func hill_houses(ci: CanvasItem, y_top: float, y_bottom: float, t: float, all_lit: bool = true) -> void:
	for row in 3:
		var y := lerpf(y_top, y_bottom, row / 2.0)
		var s := 0.55 + 0.25 * row
		var x := Kit.L + 20.0 * h(row * 5)
		var i := 0
		var tone := Color("141b2c").lerp(Color("1e2638"), row / 2.0)
		var e := Env.now()
		var glow := all_lit if e.story() else (e.lit and e.windows_glow())
		var any_glow := e.story() or (e.windows_glow() and e.state != "derelict")
		if not (e.story() or e.night()):
			tone = e.shade(Color("8a8478").lerp(Color("9a948a"), row / 2.0))
		var roof_col := Color("aab6c8").darkened(0.15 * (2 - row)) if e.snowy() else tone.darkened(0.35)
		while x < Kit.R:
			var w := (38.0 + 26.0 * h(row * 100 + i)) * s
			var hh := (26.0 + 14.0 * h(row * 77 + i)) * s
			var roof := hh * 0.55
			ci.draw_rect(Rect2(x, y - hh, w, hh + 30), tone)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, y - hh), Vector2(x + w * 0.5, y - hh - roof),
				Vector2(x + w + 3, y - hh)]), tone.darkened(0.15))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, y - hh), Vector2(x + w * 0.5, y - hh - roof),
				Vector2(x + w + 3, y - hh), Vector2(x + w * 0.5, y - hh - roof + 4)]), roof_col)
			var wins := maxi(1, int(w / (14.0 * s)))
			for k in wins:
				if not any_glow:
					continue
				if glow or h(row * 31 + i * 7 + k) > 0.5:
					var flick := 0.85 + 0.15 * sin(t * 0.7 + i + k)
					var wx := x + (k + 0.5) * w / wins - 3.0 * s
					ci.draw_rect(Rect2(wx, y - hh * 0.62, 6.0 * s, 7.0 * s), Color(1.0, 0.78, 0.42, 0.9 * flick))
			if h(row * 13 + i) > 0.6:
				ci.draw_rect(Rect2(x + w * 0.7, y - hh - roof * 0.9, 5.0 * s, roof * 0.7), tone.darkened(0.2))
			x += w + (8.0 + 20.0 * h(row * 9 + i)) * s
			i += 1


## A maple, in the season on screen: bare in winter (snow along its branches),
## in blossom in spring, full in summer, turning in autumn. `base` is the foot
## of the trunk.
static func tree(ci: CanvasItem, base: Vector2, height: float, seed: int = 0) -> void:
	var e := Env.now()
	var bark := Color("221c1a") if e.night() or e.story() else e.shade(Color("4a3a30"))
	var leaves: Array = e.foliage()
	var crown := base + Vector2(0, -height * 0.7)
	var rx := height * 0.46
	var ry := height * 0.34
	if not leaves.is_empty():
		_crown(ci, crown, rx, ry, seed, leaves, e, true)
	# The trunk, tapering, then the limbs.
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-9, 2), base + Vector2(9, 2), base + Vector2(5, -height * 0.4),
		base + Vector2(-5, -height * 0.4)]), bark)
	var snow := e.snowy()
	for i in 3:
		var a := -PI / 2 + (i - 1) * 0.62 + (h(seed + i * 13) - 0.5) * 0.2
		_limb(ci, base + Vector2(0, -height * 0.38), a, height * 0.26, 7.0, 1, seed * 7 + i, bark, snow)
	if not leaves.is_empty():
		_crown(ci, crown, rx, ry, seed + 99, leaves, e, false)
	if e.season == "autumn":
		# Fallen leaves round its foot.
		ci.draw_set_transform(base + Vector2(0, 6), 0.0, Vector2(1.0, 0.22))
		ci.draw_circle(Vector2.ZERO, height * 0.36, Color(leaves[0], 0.55))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _limb(ci: CanvasItem, p: Vector2, ang: float, length: float, width: float, depth: int, seed: int, bark: Color, snow: bool) -> void:
	var q := p + Vector2(cos(ang), sin(ang)) * length
	ci.draw_line(p, q, bark, width)
	if snow and absf(cos(ang)) > 0.25:
		# Snow lying along the top of the branch.
		ci.draw_line(p + Vector2(0, -width * 0.55), q + Vector2(0, -width * 0.55), Color(0.87, 0.9, 0.94, 0.85), maxf(1.0, width * 0.5))
	if depth >= 4 or length < 9.0:
		return
	for i in 2:
		var spread := 0.38 + 0.3 * h(seed + depth * 17 + i * 5)
		var a := ang + (spread if i == 0 else -spread) + (h(seed + i * 31 + depth) - 0.5) * 0.25
		# Branches reach up and out, not down.
		a = clampf(a, -PI + 0.25, -0.25)
		_limb(ci, q, a, length * (0.62 + 0.14 * h(seed + i * 7 + depth * 3)), maxf(1.0, width * 0.6), depth + 1, seed * 3 + i + 1, bark, snow)


## The leaves: a dark mass, clumps of leaves over it, then a speckle of single
## leaves catching the light along the top; spring adds blossom, autumn lets
## the branches show through.
static func _crown(ci: CanvasItem, c: Vector2, rx: float, ry: float, seed: int, leaves: Array, e: Env, back: bool) -> void:
	var autumn := e.season == "autumn"
	if back:
		for i in 9:
			var a := TAU * i / 9.0 + h(seed + i) * 0.5
			var p := c + Vector2(cos(a) * rx * 0.42, sin(a) * ry * 0.38 + ry * 0.08)
			var col: Color = leaves[0]
			ci.draw_circle(p, rx * (0.36 + 0.1 * h(seed + i * 3)), col.darkened(0.32))
		return
	var n := 46 if not autumn else 34
	for i in n:
		var a2 := TAU * h(seed + i * 7)
		var d := sqrt(h(seed + i * 11))
		var p2 := c + Vector2(cos(a2) * rx * d * 0.86, sin(a2) * ry * d * 0.84)
		var col2: Color = leaves[i % leaves.size()] if autumn else leaves[0]
		# Lit from above: clumps near the top are lighter.
		var lift := clampf((c.y - p2.y) / ry, -1.0, 1.0)
		col2 = col2.lightened(0.1 * lift) if lift > 0.0 else col2.darkened(-0.18 * lift)
		ci.draw_circle(p2, rx * (0.12 + 0.07 * h(seed + i * 5)), col2)
	for k in 70:
		var a3 := TAU * h(seed + k * 23 + 5)
		var d3 := sqrt(h(seed + k * 29 + 1))
		var p3 := c + Vector2(cos(a3) * rx * d3 * 0.92, sin(a3) * ry * d3 * 0.88)
		if p3.y > c.y + ry * 0.3:
			continue
		var col3: Color = leaves[1] if e.season == "spring" else (leaves[k % leaves.size()] as Color).lightened(0.16)
		ci.draw_circle(p3, 2.4 if e.season != "spring" else 3.0, col3)


## St. Olaf's: a white clapboard church with a steeple; the bell can swing.
## A room that keeps its picture draws the church without the bell
## (with_bell = false) and swings church_bell() on its moving layer.
static func church(ci: CanvasItem, base: Vector2, bell_angle: float, with_bell: bool = true) -> void:
	var wall_c := Color("c8ccd4").darkened(0.45) if Env.now().night() or Env.now().story() else Env.now().shade(Color("e4e6ea"))
	ci.draw_rect(Rect2(base.x - 46, base.y - 42, 92, 46), wall_c)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - 52, base.y - 42), Vector2(base.x, base.y - 70),
		Vector2(base.x + 52, base.y - 42)]), Color("3a3e48"))
	var e := Env.now()
	if e.snowy():
		ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - 52, base.y - 42), Vector2(base.x, base.y - 70),
			Vector2(base.x + 52, base.y - 42), Vector2(base.x, base.y - 64)]), Color("c4ccd8"))
	var win_c := Color(1.0, 0.78, 0.45, 0.85) if e.story() or (e.lit and e.windows_glow()) else Color(0.16, 0.18, 0.24, 0.9)
	for k in 3:
		var wx := base.x - 34 + k * 28
		ci.draw_rect(Rect2(wx, base.y - 30, 10, 18), win_c)
		ci.draw_circle(Vector2(wx + 5, base.y - 30), 5.0, win_c)
	# The steeple and its belfry.
	var sx := base.x - 14
	ci.draw_rect(Rect2(sx, base.y - 118, 28, 76), wall_c.lightened(0.05))
	var belfry := Rect2(sx + 5, base.y - 108, 18, 24)
	ci.draw_rect(belfry, Color("0c0e14"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 4, base.y - 118), Vector2(sx + 14, base.y - 168),
		Vector2(sx + 32, base.y - 118)]), Color("3a3e48"))
	ci.draw_line(Vector2(sx + 14, base.y - 168), Vector2(sx + 14, base.y - 184), Color("8a8a7a"), 2.0)
	ci.draw_line(Vector2(sx + 8, base.y - 178), Vector2(sx + 20, base.y - 178), Color("8a8a7a"), 2.0)
	snow_ledge(ci, sx - 4, sx + 32, base.y - 118, 4.0, 77)
	if with_bell:
		church_bell(ci, base, bell_angle)


## The bell, hung from the top of St. Olaf's belfry.
static func church_bell(ci: CanvasItem, base: Vector2, bell_angle: float) -> void:
	var pivot := Vector2(base.x - 14 + 5 + 9, base.y - 108 + 3)
	ci.draw_set_transform(pivot, bell_angle, Vector2.ONE)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-4, 2), Vector2(4, 2), Vector2(7, 14), Vector2(-7, 14)]), Color("b08a3a"))
	ci.draw_circle(Vector2(0, 15), 1.8, Color("6a5226"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A streetlamp: cast-iron pole, a curved arm and a sodium lantern.
static func streetlamp(ci: CanvasItem, x: float, base_y: float, top_y: float) -> void:
	var c := Color("23252b")
	ci.draw_rect(Rect2(x - 5, base_y - 16, 10, 16), c)
	ci.draw_line(Vector2(x, base_y - 16), Vector2(x, top_y + 10), c, 5.0)
	ci.draw_arc(Vector2(x + 18, top_y + 10), 18.0, PI, TAU * 0.86, 10, c, 4.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 24, top_y + 4), Vector2(x + 46, top_y + 4),
		Vector2(x + 42, top_y + 14), Vector2(x + 28, top_y + 14)]), Color("3a3c42"))
	ci.draw_rect(Rect2(x + 29, top_y + 14, 12, 4), Color("ffd8a0") if not Env.now().day() else Color("b8b4a8"))
	snow_ledge(ci, x + 23, x + 47, top_y + 4, 4.0, int(x))
