class_name EraVehicles
extends RefCounted
## Cars from the years Act 3 visits, drawn like the rest of the game's
## vehicles (see Vehicles): side on, facing right, `base` the ground under the
## middle, 100 units to the metre, scale `s`.
##
##   1991: sedan_1991 (a squared-off early-'90s four-door with grey plastic
##         bumpers and wraparound tail lamps), minivan_1991 (the family van,
##         woodgrain down the side, a roof rack)
##   2009: suv_2009 and sedan_2009, abandoned in the observatory lot: snow on
##         the roof, rust, a flat tyre, a cracked window
##   2031: ev_2031 (a quiet electric crossover: no grille, light bars, aero
##         wheels, a black glass roof), shuttle_2031 (the visitor center's
##         electric shuttle), charger_2031 (the post it charges from)
##
## Options common to all: body (paint), flip (facing left), snow (0..1 on the
## roof and hood), lights (head and tail lamps lit).

const BLACK_TRIM := Color("1e2024")
const GREY_PLASTIC := Color("4c4f54")


# --- 1991 -----------------------------------------------------------------------------

const SEDAN91_SHELL := [Vector2(-236, -44), Vector2(-241, -62), Vector2(-240, -82), Vector2(-226, -94), Vector2(-152, -98),
	Vector2(-112, -136), Vector2(-100, -140), Vector2(26, -140), Vector2(40, -136), Vector2(104, -100), Vector2(222, -90),
	Vector2(239, -80), Vector2(242, -62), Vector2(236, -44)]
const SEDAN91_AXLES := [Vector2(-150, -31), Vector2(150, -31)]


## An early-'90s four-door: squared off, flush composite headlamps, grey
## bumpers with a rub strip, a body-side moulding, wraparound tail lamps.
static func sedan_1991(ci: CanvasItem, base: Vector2, s: float, _t: float, o: Dictionary = {}) -> void:
	var body: Color = o.get("body", Color("6a2430"))
	var lights: bool = o.get("lights", false)
	var snow: float = o.get("snow", 0.0)
	var flip := -1.0 if o.get("flip", false) else 1.0
	ci.draw_set_transform(base, 0.0, Vector2(s * flip, s))
	ci.draw_colored_polygon(Vehicles._ellipse(Vector2(0, 1), 250.0, 8.0), Color(0.0, 0.0, 0.02, 0.32))
	var shell := PackedVector2Array(SEDAN91_SHELL)
	for axle in SEDAN91_AXLES:
		ci.draw_colored_polygon(Vehicles._car_arch(axle, 39.0), Color("0a0b0d"))
	for axle in SEDAN91_AXLES:
		_hubcap_wheel(ci, axle, 31.0, Color("b8bec4"))
	var cut := _cut_arches(shell, SEDAN91_AXLES, 40.0)
	Vehicles._shade(ci, cut, body.lightened(0.16), body.darkened(0.38))
	# Side glass in black trim, the blacked-out pillar between them.
	var rear_g := PackedVector2Array([Vector2(-140, -101), Vector2(-108, -132), Vector2(-40, -132), Vector2(-40, -101)])
	var front_g := PackedVector2Array([Vector2(-30, -101), Vector2(-30, -132), Vector2(24, -132), Vector2(36, -129), Vector2(90, -101)])
	for g in [rear_g, front_g]:
		Vehicles._glass_base(ci, g)
		Vehicles._glass_top(ci, g)
	ci.draw_rect(Rect2(-40, -132, 10, 31), BLACK_TRIM)
	ci.draw_polyline(PackedVector2Array([Vector2(-148, -99), Vector2(-110, -136), Vector2(30, -136), Vector2(100, -99)]), BLACK_TRIM, 2.4, true)
	# Doors, flush handles, the moulding and the rub strips.
	var seam := body.darkened(0.55)
	for x in [-148.0, -36.0, 98.0]:
		ci.draw_line(Vector2(x, -99), Vector2(x, -50), seam, 1.3)
	for x in [-62.0, 72.0]:
		ci.draw_rect(Rect2(x, -90, 16, 4), BLACK_TRIM)
	ci.draw_rect(Rect2(-228, -72, 458, 7), GREY_PLASTIC.darkened(0.2))
	Vehicles._shade(ci, PackedVector2Array([Vector2(226, -66), Vector2(246, -66), Vector2(248, -42), Vector2(228, -40)]), GREY_PLASTIC.lightened(0.1), GREY_PLASTIC.darkened(0.3))
	Vehicles._shade(ci, PackedVector2Array([Vector2(-248, -66), Vector2(-226, -66), Vector2(-226, -40), Vector2(-246, -42)]), GREY_PLASTIC.lightened(0.1), GREY_PLASTIC.darkened(0.3))
	ci.draw_line(Vector2(-246, -58), Vector2(-226, -58), Color("6a6c70"), 2.0)
	ci.draw_line(Vector2(228, -58), Vector2(247, -58), Color("6a6c70"), 2.0)
	# Lamps: the wide flush headlamp with its amber corner, the wraparound tail.
	ci.draw_rect(Rect2(226, -88, 15, 13), Color("fff6d8") if lights else Color("c8ccc8"))
	ci.draw_rect(Rect2(222, -76, 18, 6), Color("e8a030"))
	if lights:
		ci.draw_circle(Vector2(240, -82), 14.0, Color(1.0, 0.96, 0.82, 0.22))
	ci.draw_rect(Rect2(-242, -90, 14, 16), Color("d02a26") if lights else Color("8a1c1a"))
	ci.draw_rect(Rect2(-242, -74, 14, 6), Color("e8e4dc"))
	# The licence plate and a whip aerial on the rear wing.
	ci.draw_rect(Rect2(-247, -62, 6, 14), Color("e8e6dc"))
	ci.draw_line(Vector2(-200, -94), Vector2(-188, -176), Color("2a2c30"), 1.4)
	if snow > 0.0:
		Vehicles._snow_line(ci, Vector2(-108, -140), Vector2(28, -140), 2.0 + 7.0 * snow, 131)
		Vehicles._snow_line(ci, Vector2(106, -100), Vector2(222, -90), 1.0 + 5.0 * snow, 133)
		Vehicles._snow_line(ci, Vector2(-226, -94), Vector2(-154, -98), 1.0 + 5.0 * snow, 135)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


const VAN91_SHELL := [Vector2(-222, -42), Vector2(-227, -60), Vector2(-228, -150), Vector2(-218, -166), Vector2(-196, -170),
	Vector2(62, -170), Vector2(80, -164), Vector2(134, -108), Vector2(204, -96), Vector2(224, -84), Vector2(228, -62),
	Vector2(222, -42)]
const VAN91_AXLES := [Vector2(-140, -30), Vector2(150, -30)]


## The family minivan, 1991: a short sloping nose, a long flat roof, a roof
## rack, a sliding door, and (woodgrain = true) imitation wood down the side.
static func minivan_1991(ci: CanvasItem, base: Vector2, s: float, _t: float, o: Dictionary = {}) -> void:
	var body: Color = o.get("body", Color("8a8c84"))
	var wood: bool = o.get("woodgrain", true)
	var lights: bool = o.get("lights", false)
	var snow: float = o.get("snow", 0.0)
	var flip := -1.0 if o.get("flip", false) else 1.0
	ci.draw_set_transform(base, 0.0, Vector2(s * flip, s))
	ci.draw_colored_polygon(Vehicles._ellipse(Vector2(0, 1), 236.0, 8.0), Color(0.0, 0.0, 0.02, 0.32))
	for axle in VAN91_AXLES:
		ci.draw_colored_polygon(Vehicles._car_arch(axle, 38.0), Color("0a0b0d"))
	for axle in VAN91_AXLES:
		_hubcap_wheel(ci, axle, 30.0, Color("c0c4c8"))
	var cut := _cut_arches(PackedVector2Array(VAN91_SHELL), VAN91_AXLES, 39.0)
	Vehicles._shade(ci, cut, body.lightened(0.15), body.darkened(0.35))
	if wood:
		var panel := PackedVector2Array([Vector2(-214, -100), Vector2(196, -100), Vector2(210, -64), Vector2(-214, -62)])
		for poly in Geometry2D.intersect_polygons(cut, panel):
			Vehicles._shade(ci, poly, Color("8a5a32"), Color("5a3a20"))
			for k in 6:
				var y := -96.0 + k * 6.0
				ci.draw_line(Vector2(-210, y), Vector2(194, y + 1.5), Color(0.25, 0.14, 0.06, 0.35), 1.0)
		ci.draw_line(Vector2(-214, -101), Vector2(198, -101), Color("d8c8a0"), 2.0)
		ci.draw_line(Vector2(-214, -61), Vector2(210, -61), Color("d8c8a0"), 2.0)
	# Three side windows, the sliding door's track.
	var gl := [PackedVector2Array([Vector2(-214, -110), Vector2(-212, -158), Vector2(-138, -158), Vector2(-138, -110)]),
		PackedVector2Array([Vector2(-126, -110), Vector2(-126, -158), Vector2(-28, -158), Vector2(-28, -110)]),
		PackedVector2Array([Vector2(-16, -110), Vector2(-16, -158), Vector2(58, -158), Vector2(104, -110)])]
	for g in gl:
		Vehicles._glass_base(ci, g)
		Vehicles._glass_top(ci, g)
	ci.draw_line(Vector2(-130, -104), Vector2(-24, -104), body.darkened(0.5), 2.0)
	for x in [-132.0, -22.0, 108.0]:
		ci.draw_line(Vector2(x, -160), Vector2(x, -48), body.darkened(0.55), 1.3)
	ci.draw_rect(Rect2(-40, -96, 14, 4), BLACK_TRIM)
	ci.draw_rect(Rect2(86, -96, 14, 4), BLACK_TRIM)
	# The roof rack.
	ci.draw_rect(Rect2(-190, -178, 230, 4), Color("2a2c30"))
	for x in [-180.0, -60.0, 30.0]:
		ci.draw_rect(Rect2(x, -176, 6, 8), Color("2a2c30"))
	# Bumpers and lamps.
	Vehicles._shade(ci, PackedVector2Array([Vector2(214, -66), Vector2(234, -66), Vector2(236, -42), Vector2(216, -40)]), GREY_PLASTIC.lightened(0.1), GREY_PLASTIC.darkened(0.3))
	Vehicles._shade(ci, PackedVector2Array([Vector2(-236, -66), Vector2(-214, -66), Vector2(-214, -40), Vector2(-234, -42)]), GREY_PLASTIC.lightened(0.1), GREY_PLASTIC.darkened(0.3))
	ci.draw_rect(Rect2(212, -92, 14, 12), Color("fff6d8") if lights else Color("c8ccc8"))
	ci.draw_rect(Rect2(-230, -136, 9, 40), Color("d02a26") if lights else Color("8a1c1a"))
	if snow > 0.0:
		Vehicles._snow_line(ci, Vector2(-196, -178), Vector2(60, -178), 2.0 + 7.0 * snow, 141)
		Vehicles._snow_line(ci, Vector2(136, -108), Vector2(204, -96), 1.0 + 5.0 * snow, 143)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A steel wheel under a plastic hubcap with slots: 1991.
static func _hubcap_wheel(ci: CanvasItem, c: Vector2, r: float, cap: Color) -> void:
	ci.draw_circle(c, r, Color("141518"))
	ci.draw_circle(c, r * 0.68, cap.darkened(0.25))
	ci.draw_circle(c, r * 0.62, cap)
	for i in 10:
		var a := TAU * i / 10.0
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * r * 0.3, c + d * r * 0.56, cap.darkened(0.4), 2.0)
	ci.draw_circle(c, r * 0.2, cap.lightened(0.15))


# --- 2009: abandoned in the lot -----------------------------------------------------------------

const SUV09_SHELL := [Vector2(-232, -46), Vector2(-238, -70), Vector2(-238, -170), Vector2(-226, -184), Vector2(-196, -188),
	Vector2(64, -188), Vector2(84, -180), Vector2(132, -122), Vector2(214, -112), Vector2(234, -98), Vector2(238, -66),
	Vector2(232, -46)]
const SUV09_AXLES := [Vector2(-148, -38), Vector2(152, -38)]


## A mid-2000s SUV, left in the observatory lot years ago: faded paint, rust
## blooming along the sills and wheel arches, one window cracked, the front
## tyre flat, snow on the roof and drifted up the side.
static func suv_2009(ci: CanvasItem, base: Vector2, s: float, _t: float, o: Dictionary = {}) -> void:
	var body: Color = o.get("body", Color("7a8086"))
	var snow: float = o.get("snow", 0.8)
	var flip := -1.0 if o.get("flip", false) else 1.0
	ci.draw_set_transform(base, 0.0, Vector2(s * flip, s))
	ci.draw_colored_polygon(Vehicles._ellipse(Vector2(0, 1), 250.0, 9.0), Color(0.0, 0.0, 0.02, 0.32))
	for axle in SUV09_AXLES:
		ci.draw_colored_polygon(Vehicles._car_arch(axle, 46.0), Color("0a0b0d"))
	_alloy_wheel(ci, SUV09_AXLES[0], 38.0, false)
	_alloy_wheel(ci, SUV09_AXLES[1], 38.0, true)
	var cut := _cut_arches(PackedVector2Array(SUV09_SHELL), SUV09_AXLES, 47.0)
	Vehicles._shade(ci, cut, body.lightened(0.08), body.darkened(0.35))
	_rust(ci, cut, [Rect2(-232, -74, 464, 26), Rect2(-200, -110, 60, 30), Rect2(110, -112, 70, 24)], 201)
	var gl := [PackedVector2Array([Vector2(-226, -126), Vector2(-224, -174), Vector2(-150, -176), Vector2(-150, -126)]),
		PackedVector2Array([Vector2(-138, -126), Vector2(-138, -176), Vector2(-26, -176), Vector2(-26, -126)]),
		PackedVector2Array([Vector2(-14, -126), Vector2(-14, -176), Vector2(60, -176), Vector2(112, -126)])]
	for g in gl:
		Vehicles._glass_base(ci, g)
		Vehicles._glass_top(ci, g)
	_cracks(ci, Vector2(-80, -150), 211)
	ci.draw_rect(Rect2(-196, -196, 240, 5), Color("2a2c30"))
	for x in [-144.0, -20.0, 106.0]:
		ci.draw_line(Vector2(x, -178), Vector2(x, -52), body.darkened(0.5), 1.3)
	ci.draw_rect(Rect2(214, -110, 16, 14), Color("8a8c84"))
	ci.draw_rect(Rect2(-240, -150, 8, 34), Color("5a2420"))
	if snow > 0.0:
		Vehicles._snow_line(ci, Vector2(-206, -196), Vector2(58, -196), 4.0 + 16.0 * snow, 221)
		Vehicles._snow_line(ci, Vector2(134, -122), Vector2(214, -112), 2.0 + 8.0 * snow, 223)
		# Drifted up against the near side.
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-250, 2), Vector2(-240, -30), Vector2(-160, -46), Vector2(-60, -40),
			Vector2(40, -54), Vector2(140, -34), Vector2(250, -20), Vector2(260, 2)]), Color("dfe6f0"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


const SEDAN09_SHELL := [Vector2(-230, -44), Vector2(-236, -64), Vector2(-232, -96), Vector2(-212, -106), Vector2(-150, -112),
	Vector2(-104, -146), Vector2(-60, -156), Vector2(20, -156), Vector2(56, -148), Vector2(118, -106), Vector2(214, -94),
	Vector2(234, -80), Vector2(238, -62), Vector2(230, -44)]
const SEDAN09_AXLES := [Vector2(-146, -33), Vector2(148, -33)]


## A 2000s family sedan, rounded everywhere, abandoned like the SUV.
static func sedan_2009(ci: CanvasItem, base: Vector2, s: float, _t: float, o: Dictionary = {}) -> void:
	var body: Color = o.get("body", Color("3a4a5a"))
	var snow: float = o.get("snow", 0.8)
	var flip := -1.0 if o.get("flip", false) else 1.0
	ci.draw_set_transform(base, 0.0, Vector2(s * flip, s))
	ci.draw_colored_polygon(Vehicles._ellipse(Vector2(0, 1), 244.0, 8.0), Color(0.0, 0.0, 0.02, 0.32))
	for axle in SEDAN09_AXLES:
		ci.draw_colored_polygon(Vehicles._car_arch(axle, 41.0), Color("0a0b0d"))
	_alloy_wheel(ci, SEDAN09_AXLES[0], 33.0, true)
	_alloy_wheel(ci, SEDAN09_AXLES[1], 33.0, false)
	var cut := _cut_arches(PackedVector2Array(SEDAN09_SHELL), SEDAN09_AXLES, 42.0)
	Vehicles._shade(ci, cut, body.lightened(0.12), body.darkened(0.38))
	_rust(ci, cut, [Rect2(-230, -70, 460, 22), Rect2(150, -108, 60, 20)], 301)
	var gl := [PackedVector2Array([Vector2(-140, -114), Vector2(-104, -146), Vector2(-36, -150), Vector2(-36, -114)]),
		PackedVector2Array([Vector2(-26, -114), Vector2(-26, -150), Vector2(18, -150), Vector2(50, -144), Vector2(104, -110)])]
	for g in gl:
		Vehicles._glass_base(ci, g)
		Vehicles._glass_top(ci, g)
	_cracks(ci, Vector2(20, -132), 311)
	for x in [-144.0, -32.0, 108.0]:
		ci.draw_line(Vector2(x, -112), Vector2(x, -50), body.darkened(0.5), 1.3)
	ci.draw_rect(Rect2(218, -92, 16, 12), Color("8a8c84"))
	ci.draw_rect(Rect2(-236, -96, 10, 16), Color("5a2420"))
	if snow > 0.0:
		Vehicles._snow_line(ci, Vector2(-98, -156), Vector2(54, -150), 4.0 + 14.0 * snow, 321)
		Vehicles._snow_line(ci, Vector2(-226, -106), Vector2(-152, -112), 2.0 + 8.0 * snow, 323)
		Vehicles._snow_line(ci, Vector2(120, -106), Vector2(214, -94), 2.0 + 8.0 * snow, 325)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-244, 2), Vector2(-230, -24), Vector2(-120, -40), Vector2(0, -30),
			Vector2(120, -44), Vector2(240, -22), Vector2(252, 2)]), Color("dfe6f0"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A five-spoke alloy, dull with years of weather; `flat` sits the tyre down
## on its rim.
static func _alloy_wheel(ci: CanvasItem, c: Vector2, r: float, flat: bool) -> void:
	var tyre := Color("16171a")
	if flat:
		ci.draw_colored_polygon(Vehicles._ellipse(c + Vector2(0, r * 0.18), r * 1.08, r * 0.82), tyre)
		c = c + Vector2(0, r * 0.2)
	else:
		ci.draw_circle(c, r, tyre)
	ci.draw_circle(c, r * 0.64, Color("6a6e72"))
	for i in 5:
		var a := TAU * i / 5.0 + 0.3
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * r * 0.16, c + d * r * 0.6, Color("8a8e92"), r * 0.16)
	ci.draw_circle(c, r * 0.16, Color("5a5e62"))
	ci.draw_circle(c + Vector2(r * 0.2, r * 0.25), r * 0.14, Color(0.45, 0.25, 0.12, 0.45))


## Rust blooming through the paint inside the given areas.
static func _rust(ci: CanvasItem, shape: PackedVector2Array, areas: Array, seed: int) -> void:
	var i := 0
	for r: Rect2 in areas:
		for k in 9:
			var p := r.position + Vector2(Townscape.h(seed + i * 17 + k * 3) * r.size.x, Townscape.h(seed + i * 29 + k * 7) * r.size.y)
			var blob := Vehicles._ellipse(p, 4.0 + 8.0 * Townscape.h(seed + k), 2.0 + 4.0 * Townscape.h(seed + k * 5), 10)
			for poly in Geometry2D.intersect_polygons(shape, blob):
				ci.draw_colored_polygon(poly, Color(0.36, 0.2, 0.11, 0.4 + 0.3 * Townscape.h(seed + k * 11)))
		i += 1


## A star of cracks across a pane.
static func _cracks(ci: CanvasItem, c: Vector2, seed: int) -> void:
	for k in 7:
		var a := TAU * Townscape.h(seed + k * 3)
		var l := 14.0 + 26.0 * Townscape.h(seed + k * 7)
		var mid := c + Vector2(cos(a), sin(a)) * l * 0.5 + Vector2(sin(a), -cos(a)) * 4.0
		ci.draw_polyline(PackedVector2Array([c, mid, c + Vector2(cos(a), sin(a)) * l]), Color(0.86, 0.9, 0.95, 0.5), 1.0, true)
	ci.draw_circle(c, 3.0, Color(0.86, 0.9, 0.95, 0.4))


# --- 2031 ------------------------------------------------------------------------------

const EV31_SHELL := [Vector2(-218, -44), Vector2(-224, -68), Vector2(-222, -112), Vector2(-206, -128), Vector2(-150, -150),
	Vector2(-40, -158), Vector2(20, -154), Vector2(110, -118), Vector2(196, -98), Vector2(222, -84), Vector2(226, -60),
	Vector2(218, -44)]
const EV31_AXLES := [Vector2(-138, -37), Vector2(140, -37)]


## A quiet electric crossover, 2031: one smooth wedge, no grille, a light bar
## across the nose and another across the tail, flush handles, aero discs,
## the whole glasshouse dark glass. charging: its cable plugged in at the
## front wing (charger_2031 draws the post).
static func ev_2031(ci: CanvasItem, base: Vector2, s: float, t: float, o: Dictionary = {}) -> void:
	var body: Color = o.get("body", Color("e6e8ea"))
	var lights: bool = o.get("lights", true)
	var flip := -1.0 if o.get("flip", false) else 1.0
	ci.draw_set_transform(base, 0.0, Vector2(s * flip, s))
	ci.draw_colored_polygon(Vehicles._ellipse(Vector2(0, 1), 236.0, 8.0), Color(0.0, 0.0, 0.02, 0.28))
	for axle in EV31_AXLES:
		ci.draw_colored_polygon(Vehicles._car_arch(axle, 44.0), Color("0a0b0d"))
	for axle in EV31_AXLES:
		_aero_wheel(ci, axle, 37.0, t)
	var cut := _cut_arches(PackedVector2Array(EV31_SHELL), EV31_AXLES, 45.0)
	Vehicles._shade(ci, cut, body.lightened(0.1), body.darkened(0.3))
	# The glasshouse: one dark band from the windscreen to the tail.
	var glass := PackedVector2Array([Vector2(-196, -120), Vector2(-150, -144), Vector2(-40, -151), Vector2(16, -148),
		Vector2(98, -116), Vector2(-196, -114)])
	Vehicles._shade(ci, glass, Color("2a3442"), Color("0c1016"))
	Vehicles._glass_top(ci, glass)
	ci.draw_line(Vector2(-40, -150), Vector2(-40, -115), Color("0c0e12"), 4.0)
	# The black lower cladding, the flush handles, a sharp crease along the side.
	Vehicles._shade(ci, PackedVector2Array([Vector2(-224, -62), Vector2(226, -62), Vector2(224, -44), Vector2(-220, -44)]), Color("2a2c30"), Color("141518"))
	ci.draw_line(Vector2(-210, -92), Vector2(200, -86), body.darkened(0.25), 1.4)
	for x in [-88.0, 30.0]:
		ci.draw_rect(Rect2(x, -104, 22, 3), body.darkened(0.4))
	ci.draw_line(Vector2(-40, -114), Vector2(-40, -62), body.darkened(0.35), 1.2)
	ci.draw_line(Vector2(84, -112), Vector2(90, -62), body.darkened(0.35), 1.2)
	# Light bars, front and rear.
	ci.draw_line(Vector2(196, -98), Vector2(224, -86), Color("f4fbff") if lights else Color("9aa4ac"), 3.0)
	ci.draw_line(Vector2(-222, -112), Vector2(-206, -126), Color("ff3a40") if lights else Color("6a1c20"), 3.0)
	ci.draw_line(Vector2(-224, -100), Vector2(-224, -76), Color("ff3a40") if lights else Color("6a1c20"), 2.0)
	if lights:
		ci.draw_circle(Vector2(222, -88), 10.0, Color(0.9, 0.97, 1.0, 0.2))
	if o.get("charging", false):
		# The port door open on the front wing, the cable down to the post.
		ci.draw_rect(Rect2(150, -100, 16, 12), Color("101214"))
		ci.draw_circle(Vector2(158, -94), 3.0, Color("3adc8a"))
		var cable := PackedVector2Array([Vector2(160, -92), Vector2(196, -40), Vector2(250, -8), Vector2(320, -30)])
		ci.draw_polyline(Figure.smooth(cable, 4, false), Color("1a1c20"), 4.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A flat aero disc on a thin tyre.
static func _aero_wheel(ci: CanvasItem, c: Vector2, r: float, _t: float) -> void:
	ci.draw_circle(c, r, Color("141518"))
	ci.draw_circle(c, r * 0.8, Color("3a3e44"))
	ci.draw_circle(c, r * 0.76, Color("4a4f56"))
	for i in 6:
		var a := TAU * i / 6.0
		ci.draw_arc(c, r * 0.5, a, a + 0.7, 6, Color("6a7078"), 2.0, true)
	ci.draw_circle(c, r * 0.14, Color("2a2c30"))


## The visitor center's electric shuttle: a rounded box on four small wheels,
## glass nearly all the way round, the livery along its side.
static func shuttle_2031(ci: CanvasItem, base: Vector2, s: float, _t: float, o: Dictionary = {}) -> void:
	var body: Color = o.get("body", Color("eef0f2"))
	var flip := -1.0 if o.get("flip", false) else 1.0
	ci.draw_set_transform(base, 0.0, Vector2(s * flip, s))
	ci.draw_colored_polygon(Vehicles._ellipse(Vector2(0, 1), 270.0, 9.0), Color(0.0, 0.0, 0.02, 0.28))
	var axles := [Vector2(-180, -30), Vector2(180, -30)]
	for axle in axles:
		ci.draw_colored_polygon(Vehicles._car_arch(axle, 38.0), Color("0a0b0d"))
		_aero_wheel(ci, axle, 30.0, 0.0)
	var shell := Vehicles._rrect(Rect2(-262, -258, 524, 212), 46.0, 5)
	var cut := _cut_arches(shell, axles, 39.0)
	Vehicles._shade(ci, cut, body.lightened(0.05), body.darkened(0.2))
	var glass := Vehicles._rrect(Rect2(-240, -236, 480, 112), 30.0, 4)
	Vehicles._shade(ci, glass, Color("2a3442"), Color("0e1218"))
	Vehicles._glass_top(ci, glass)
	for x in [-120.0, 0.0, 120.0]:
		ci.draw_line(Vector2(x, -236), Vector2(x, -124), Color("101418"), 4.0)
	# The livery stripe, the name, the door.
	ci.draw_rect(Rect2(-262, -112, 524, 18), Color("c4502e"))
	Kit.text(ci, Vector2(-240, -78), "HALVARD SIGNAL  ·  SHUTTLE", 17, Color("2a3442"))
	ci.draw_rect(Rect2(40, -232, 2, 186), Color("9aa0a8"))
	ci.draw_rect(Rect2(-262, -252, 524, 6), Color("f4fbff"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## An EV charging post: a slim pillar, its screen, the cable in its holster
## (or out to a car: the car draws the cable).
static func charger_2031(ci: CanvasItem, base: Vector2, s: float, t: float, o: Dictionary = {}) -> void:
	var in_use: bool = o.get("in_use", false)
	ci.draw_set_transform(base, 0.0, Vector2(s, s))
	ci.draw_colored_polygon(Vehicles._ellipse(Vector2(0, 1), 30.0, 4.0), Color(0.0, 0.0, 0.02, 0.3))
	Vehicles._shade(ci, Vehicles._rrect(Rect2(-18, -150, 36, 150), 8.0), Color("e8eaec"), Color("9aa0a8"))
	ci.draw_rect(Rect2(-12, -134, 24, 30), Color("0e1218"))
	var pulse := 0.6 + 0.4 * sin(t * 2.0)
	ci.draw_rect(Rect2(-9, -124, 18 * (0.64 if in_use else 1.0), 4), Color(0.25, 0.9, 0.55, pulse))
	ci.draw_rect(Rect2(-18, -96, 36, 6), Color("2a8a5a"))
	if not in_use:
		ci.draw_arc(Vector2(18, -60), 14.0, -PI * 0.5, PI * 0.6, 8, Color("1a1c20"), 4.0, true)
		ci.draw_rect(Rect2(14, -84, 10, 16), Color("1a1c20"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- helpers -----------------------------------------------------------------------------

## The body cut away at the wheel openings.
static func _cut_arches(shell: PackedVector2Array, axles: Array, r: float) -> PackedVector2Array:
	var cut := shell
	for axle in axles:
		var hole := Vehicles._car_arch(axle, r)
		var parts := Geometry2D.clip_polygons(cut, hole)
		if parts.size() > 0:
			var best := parts[0]
			for p in parts:
				if Vehicles._bounds(p).get_area() > Vehicles._bounds(best).get_area():
					best = p
			cut = best
	return cut
