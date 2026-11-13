class_name Vehicles
extends RefCounted
## The vehicles, drawn in code like the rest of the game: Sollen's snowcat (the
## garage, the road down), Mara's 1980 pickup (the opening, the snowfield),
## the county plow far down the road (the garage, on 03), and in the opening's
## aftermath the sheriff's cruiser and Ruth's sedan.
##
## Each one faces right and takes `base`, the ground under its middle, and a
## scale. They draw in their own local units through draw_set_transform (the
## snowcat at about 120 to the metre, the pickup at 100) and reset the
## transform when they're done.

# --- the snowcat's running gear (local units) -------------------------------------
const IDLER := Vector2(-178, -34)
const IDLER_R := 32.0
const SPROCKET := Vector2(180, -40)
const SPROCKET_R := 34.0
const BELT := 9.0
const BOGIES := [-118.0, -62.0, -6.0, 50.0, 106.0]
const BOGIE_R := 19.0
const ROLLERS := [Vector2(-56, -53), Vector2(56, -55)]
const CLEAT := 14.0

const CAT_SHELL := [Vector2(-198, -84), Vector2(-198, -142), Vector2(-154, -142), Vector2(-154, -226),
	Vector2(-150, -234), Vector2(-142, -240), Vector2(56, -240), Vector2(64, -236), Vector2(88, -150),
	Vector2(96, -142), Vector2(192, -138), Vector2(208, -134), Vector2(222, -118), Vector2(228, -98), Vector2(226, -84)]
const CAT_DOOR_GLASS := [Vector2(-42, -228), Vector2(50, -228), Vector2(68, -168), Vector2(-42, -168)]
const CAT_FENDER := [Vector2(-204, -74), Vector2(-204, -84), Vector2(-198, -90), Vector2(218, -90), Vector2(226, -84),
	Vector2(226, -74), Vector2(220, -74), Vector2(219, -80), Vector2(-197, -80), Vector2(-198, -74)]

# --- the pickup (local units, 100 to the metre) -------------------------------------
const AXLE_R := Vector2(-150, -38)
const AXLE_F := Vector2(150, -38)
const TYRE_R := 38.0
const ARCH_R := 47.0
const TRUCK_GLASS := [Vector2(-38, -168), Vector2(42, -168), Vector2(73, -124), Vector2(-38, -124)]

static var _belt := PackedVector2Array()
static var _belt_in := PackedVector2Array()
static var _belt_len := PackedFloat32Array()
static var _belt_total := 0.0
static var _truck_shell := PackedVector2Array()


# --- Sollen's snowcat ------------------------------------------------------------------

## Sollen's snowcat: a late-'70s tracked snowcat in observatory orange, side
## on. Options (all optional):
##   body: paint colour       moving: rolling (spray, swaying whip)
##   engine: running          lights: headlight on
##   driver: Mara at the wheel    snow: 0..1 on the roof, hood and tracks
##   travel: distance driven, in screen px (turns the tracks and wheels)
##   puddle: meltwater under it (parked indoors)
static func snowcat(ci: CanvasItem, base: Vector2, s: float, t: float, o: Dictionary = {}) -> void:
	_belt_geo()
	var body: Color = o.get("body", Color("c8642a"))
	var moving: bool = o.get("moving", false)
	var engine: bool = o.get("engine", moving)
	var lights: bool = o.get("lights", false)
	var snow: float = o.get("snow", 0.5)
	var run: float = float(o.get("travel", 0.0)) / s * 0.4
	var shake := sin(t * 43.0) * 0.5 if engine else 0.0
	ci.draw_set_transform(base, 0.0, Vector2(s, s))
	if o.get("puddle", false):
		ci.draw_colored_polygon(_ellipse(Vector2(12, 6), 252.0, 12.0), Color(0.06, 0.08, 0.1, 0.42))
		ci.draw_line(Vector2(-130, 9), Vector2(-50, 9), Color(0.62, 0.72, 0.82, 0.12), 1.5)
		ci.draw_line(Vector2(70, 11), Vector2(180, 11), Color(0.62, 0.72, 0.82, 0.1), 1.5)
	ci.draw_colored_polygon(_ellipse(Vector2(10, 1), 226.0, 9.0), Color(0.0, 0.0, 0.02, 0.38))
	# The belly, dark between the tracks and the fender.
	ci.draw_rect(Rect2(-196, -86, 418, 34), Color("121315"))
	_cat_tracks(ci, run, snow)
	ci.draw_set_transform(base + Vector2(0, shake) * s, 0.0, Vector2(s, s))
	_cat_body(ci, body, t, engine, lights, moving, snow, o)
	if engine:
		_vapour(ci, Vector2(-162, -270), t, moving, 1.0)
	ci.draw_set_transform(base, 0.0, Vector2(s, s))
	if moving:
		_spray(ci, t)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The belt's outline (convex, clockwise on screen, so the top run heads
## forward) and its inside edge, computed once.
static func _belt_geo() -> void:
	if not _belt.is_empty():
		return
	var pts := PackedVector2Array()
	for i in 40:
		var d := Vector2(cos(TAU * i / 40.0), sin(TAU * i / 40.0))
		pts.append(IDLER + d * IDLER_R)
		pts.append(SPROCKET + d * SPROCKET_R)
	pts.append(Vector2(-140, 0))
	pts.append(Vector2(140, 0))
	var hull := Geometry2D.convex_hull(pts)
	hull.remove_at(hull.size() - 1)
	var area := 0.0
	for i in hull.size():
		var a := hull[i]
		var b := hull[(i + 1) % hull.size()]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		hull.reverse()
	_belt = hull
	var inner: Array = Geometry2D.offset_polygon(hull, -BELT, Geometry2D.JOIN_ROUND)
	_belt_in = inner[0] if not inner.is_empty() else hull
	_belt_len.resize(hull.size())
	var total := 0.0
	for i in hull.size():
		_belt_len[i] = total
		total += hull[i].distance_to(hull[(i + 1) % hull.size()])
	_belt_total = total


## The point `d` along the belt, and the way the belt runs there.
static func _belt_at(d: float) -> Array:
	d = fposmod(d, _belt_total)
	var i := clampi(_belt_len.bsearch(d, false) - 1, 0, _belt.size() - 1)
	var a := _belt[i]
	var b := _belt[(i + 1) % _belt.size()]
	var u := (b - a) / maxf(0.001, a.distance_to(b))
	return [a + u * (d - _belt_len[i]), u]


static func _cat_tracks(ci: CanvasItem, run: float, snow: float) -> void:
	ci.draw_colored_polygon(_belt, Color("1b1d20"))
	ci.draw_colored_polygon(_belt_in, Color("0e0f11"))
	for r in ROLLERS:
		_wheel(ci, r, 7.0, run / 7.0, Color("222427"), Color("4b5055"), 3)
	_wheel(ci, IDLER, IDLER_R - BELT - 1.0, run / 22.0, Color("25282c"), Color("5c6268"), 6)
	for x in BOGIES:
		_wheel(ci, Vector2(x, -BELT - BOGIE_R), BOGIE_R, run / BOGIE_R, Color("25282c"), Color("646a70"), 5)
	_sprocket(ci, SPROCKET, SPROCKET_R - BELT - 1.0, run / 24.0, Color("3a3e43"))
	# Steel grousers across the rubber, and the joints between the links.
	var n := int(_belt_total / CLEAT)
	var step := _belt_total / n
	var off := fposmod(run, step)
	var cleats := PackedVector2Array()
	var joints := PackedVector2Array()
	for k in n:
		var pu := _belt_at(off + k * step)
		var p: Vector2 = pu[0]
		var u: Vector2 = pu[1]
		var out := Vector2(u.y, -u.x)
		cleats.append(p - out * 0.6)
		cleats.append(p + out * 3.0)
		joints.append(p - out * 1.0)
		joints.append(p - out * (BELT - 1.0))
	ci.draw_multiline(joints, Color("2d3034"), 1.0)
	ci.draw_multiline(cleats, Color("3e4247"), 4.2)
	if snow <= 0.0:
		return
	# Snow packed on the belt between the bogies, and lying on the top run.
	for k in BOGIES.size() - 1:
		var x: float = (BOGIES[k] + BOGIES[k + 1]) * 0.5
		_snow_line(ci, Vector2(x - 11, -BELT + 0.5), Vector2(x + 11, -BELT + 0.5), 2.0 + 3.5 * snow, 31 + k * 7)
	_snow_line(ci, Vector2(-170, -67), Vector2(172, -75), 1.0 + 2.5 * snow, 41)


static func _cat_body(ci: CanvasItem, body: Color, t: float, engine: bool, lights: bool, moving: bool, snow: float, o: Dictionary) -> void:
	var shell := PackedVector2Array(CAT_SHELL)
	var seam := body.darkened(0.45)
	var dark := Color("1b1d20")
	# The rear deck: a jerrycan strapped behind a rail, and the exhaust stack.
	var can := Rect2(-196, -170, 20, 28)
	_shade(ci, _rrect(can, 2.0), Color("5a744c"), Color("33442c"))
	ci.draw_line(can.position + Vector2(3, 5), can.end - Vector2(3, 4), Color("2a3824"), 1.2)
	ci.draw_line(Vector2(can.end.x - 3, can.position.y + 5), Vector2(can.position.x + 3, can.end.y - 4), Color("2a3824"), 1.2)
	ci.draw_rect(Rect2(can.position.x + 3, can.position.y - 4, 14, 4), Color("2a3824"))
	ci.draw_line(Vector2(-166, -140), Vector2(-166, -266), Color("2b2d30"), 8.0)
	ci.draw_line(Vector2(-168.6, -140), Vector2(-168.6, -266), Color("4c5055"), 1.2)
	var guard := Rect2(-171, -216, 10, 46)
	_shade(ci, _rect_pts(guard), Color("80858a"), Color("5a5f64"))
	for gy in 6:
		for gx in 2:
			ci.draw_circle(guard.position + Vector2(3.0 + gx * 4.0, 5.0 + gy * 7.0), 1.1, Color("373b3f"))
	var flap := 0.55 + 0.14 * sin(t * 17.0) if engine else 0.0
	ci.draw_line(Vector2(-171, -266), Vector2(-171, -266) + Vector2(11, 0).rotated(-flap), Color("232528"), 2.6, true)

	# The shell, lit from above, the grime creeping up from the tracks, and the
	# cream pinstripe down the flank.
	_shade(ci, shell, body.lightened(0.12), body.darkened(0.24))
	_clip_grad(ci, shell, Rect2(-200, -124, 432, 40), Color(0.05, 0.04, 0.03, 0.0), Color(0.05, 0.04, 0.03, 0.42))
	for poly in Geometry2D.intersect_polygons(shell, _rect_pts(Rect2(-200, -134, 432, 5))):
		ci.draw_colored_polygon(poly, Color("e6dcc4"))
	ci.draw_polyline(PackedVector2Array([Vector2(-154, -226), Vector2(-150, -234), Vector2(-142, -240), Vector2(56, -240), Vector2(64, -236)]),
		body.lightened(0.42), 1.6, true)
	ci.draw_polyline(PackedVector2Array([Vector2(96, -142), Vector2(192, -138), Vector2(208, -134)]), body.lightened(0.36), 1.6, true)
	ci.draw_line(Vector2(-198, -142), Vector2(-154, -142), body.lightened(0.3), 1.4)
	ci.draw_line(Vector2(-152, -233), Vector2(60, -233), body.darkened(0.35), 1.6, true)
	# Panel seams: the door, the hood, the cab's back corner.
	ci.draw_polyline(PackedVector2Array([Vector2(-50, -90), Vector2(-50, -233), Vector2(58, -233), Vector2(78, -160), Vector2(78, -90)]), seam, 1.4, true)
	ci.draw_line(Vector2(96, -141), Vector2(96, -91), seam, 1.4, true)
	ci.draw_line(Vector2(-154, -141), Vector2(-154, -91), seam, 1.0, true)

	# Windows: the rear quarter light and the door glass, Mara behind it.
	var rear := _rrect(Rect2(-146, -228, 84, 60), 6.0)
	_glass_base(ci, rear)
	ci.draw_colored_polygon(_rrect(Rect2(-138, -200, 42, 32), 5.0), Color("0f1114"))
	_glass_top(ci, rear)
	var glass := PackedVector2Array(CAT_DOOR_GLASS)
	_glass_base(ci, glass)
	if engine:
		ci.draw_polygon(PackedVector2Array([Vector2(16, -182), Vector2(64, -182), Vector2(68, -168), Vector2(16, -168)]),
			PackedColorArray([Color(1.0, 0.6, 0.28, 0.0), Color(1.0, 0.6, 0.28, 0.0), Color(1.0, 0.6, 0.28, 0.4), Color(1.0, 0.6, 0.28, 0.4)]))
	if o.get("driver", false):
		_cat_driver(ci, engine)
	else:
		ci.draw_colored_polygon(_rrect(Rect2(-20, -204, 16, 36), 4.0), Color("101215"))
		ci.draw_line(Vector2(48, -190), Vector2(57, -170), Color("141619"), 3.0, true)
	_glass_top(ci, glass)
	# The windscreen, edge on: its frame, the glass, a wiper.
	ci.draw_line(Vector2(64, -236), Vector2(88, -150), Color("0f1215"), 4.0, true)
	ci.draw_line(Vector2(60.5, -232), Vector2(83.5, -152), Color(0.56, 0.7, 0.8, 0.42), 1.4, true)
	ci.draw_line(Vector2(88, -151), Vector2(76, -194), Color("0d0f11"), 1.4, true)
	# Mirror on its arms.
	ci.draw_line(Vector2(82, -197), Vector2(104, -205), dark, 2.0, true)
	ci.draw_line(Vector2(84, -176), Vector2(104, -200), dark, 2.0, true)
	ci.draw_colored_polygon(_rrect(Rect2(100, -228, 9, 30), 2.0), Color("16181b"))
	ci.draw_line(Vector2(107.5, -225), Vector2(107.5, -201), Color(0.6, 0.72, 0.84, 0.5), 1.2)
	# Handle, hinges, a grab bar, and the observatory's dish on the door.
	ci.draw_rect(Rect2(-44, -152, 14, 4), Color("c5c9cd"))
	ci.draw_line(Vector2(-44, -147.4), Vector2(-30, -147.4), Color(0, 0, 0, 0.35), 1.0)
	for y in [-150.0, -114.0]:
		ci.draw_rect(Rect2(74, y, 5, 10), body.darkened(0.5))
	ci.draw_line(Vector2(-56, -208), Vector2(-56, -176), Color("aeb3b8"), 2.4, true)
	var em := Vector2(16, -150)
	ci.draw_circle(em, 9.5, Color("e6dcc4"))
	ci.draw_arc(em + Vector2(1, -1), 5.5, PI * 0.55, PI * 1.45, 10, body.darkened(0.25), 2.2, true)
	ci.draw_line(em + Vector2(-2, 3), em + Vector2(-2, 7), body.darkened(0.25), 1.6)
	ci.draw_line(em + Vector2(-5, 7.5), em + Vector2(1, 7.5), body.darkened(0.25), 1.4)
	Kit.text(ci, Vector2(-146, -140), "HRO 03", 13, Color("efe6d0"))

	# The engine bay: louvres, the latch, the headlight, a marker lamp, the
	# push bar and tow hook; the tail lamp and hitch at the back.
	ci.draw_colored_polygon(_rrect(Rect2(110, -126, 70, 22), 3.0), body.darkened(0.34))
	for k in 5:
		var y := -122.0 + k * 4.0
		ci.draw_line(Vector2(113, y), Vector2(177, y), body.darkened(0.62), 1.8)
		ci.draw_line(Vector2(113, y + 1.6), Vector2(177, y + 1.6), body.lightened(0.14), 0.8)
	ci.draw_rect(Rect2(198, -131, 6, 3), Color("1a1b1d"))
	ci.draw_line(Vector2(209, -127), Vector2(219, -113), body.darkened(0.45), 1.2, true)
	var hl := Vector2(204, -100)
	ci.draw_circle(hl, 11.0, Color("16181a"))
	ci.draw_circle(hl, 9.5, Color("c9cdd1"))
	ci.draw_circle(hl, 7.6, Color("fff4d2") if lights else Color("b9b4a2"))
	ci.draw_circle(hl + Vector2(-2.4, -2.6), 2.3, Color(1, 1, 1, 0.75))
	ci.draw_arc(hl, 12.2, PI * 1.12, PI * 1.88, 8, Color("16181a"), 2.6, true)
	if lights:
		ci.draw_circle(hl, 16.0, Color(1.0, 0.95, 0.8, 0.16))
	ci.draw_rect(Rect2(214, -118, 6, 5), Color("ffb347") if lights else Color("9a6a2c"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(219, -101), Vector2(236, -101), Vector2(238, -86), Vector2(222, -84)]), Color("1d1f22"))
	ci.draw_line(Vector2(219, -101), Vector2(236, -101), Color("50555a"), 1.2)
	ci.draw_arc(Vector2(233, -80), 4.0, -PI * 0.5, PI * 0.6, 8, Color("2a2c2f"), 2.2, true)
	ci.draw_rect(Rect2(-203, -138, 6, 14), Color("e83a2c") if engine else Color("7a1c18"))
	ci.draw_rect(Rect2(-203, -120, 5, 6), Color("b0461e"))
	ci.draw_rect(Rect2(-211, -101, 13, 8), Color("1d1f22"))
	if engine:
		ci.draw_circle(Vector2(-201, -131), 10.0, Color(1.0, 0.2, 0.14, 0.14))

	# Fender over the tracks.
	_shade(ci, PackedVector2Array(CAT_FENDER), Color("34373b"), Color("1a1c1e"))
	ci.draw_line(Vector2(-198, -90), Vector2(218, -90), Color("565b60"), 1.2)
	# The deck rail in front of the jerrycan.
	ci.draw_line(Vector2(-198, -160), Vector2(-157, -160), dark, 2.6)
	for x in [-196.0, -159.0]:
		ci.draw_line(Vector2(x, -141), Vector2(x, -161), dark, 2.6)

	# Snow, then what stands up out of it: the roof rack, work lamps, beacon
	# and the radio whip.
	if snow > 0.0:
		_snow_line(ci, Vector2(-148, -240), Vector2(60, -240), 2.0 + 7.0 * snow, 7)
		_snow_line(ci, Vector2(98, -142), Vector2(196, -138), 1.5 + 4.0 * snow, 3)
		_snow_line(ci, Vector2(-198, -142), Vector2(-157, -142), 1.5 + 3.0 * snow, 5)
		_snow_line(ci, Vector2(-196, -90), Vector2(216, -90), 1.0 + 2.5 * snow, 11)
		_snow_line(ci, Vector2(100, -228), Vector2(109, -228), 1.0 + 2.0 * snow, 13)
	ci.draw_line(Vector2(-144, -253), Vector2(50, -253), dark, 3.0)
	for x in [-138.0, -46.0, 42.0]:
		ci.draw_line(Vector2(x, -239), Vector2(x, -253), dark, 2.6)
	ci.draw_colored_polygon(_rrect(Rect2(44, -266, 12, 11), 2.0), Color("202226"))
	ci.draw_line(Vector2(56.6, -264), Vector2(56.6, -257), Color("d8d4c4"), 1.6)
	var lit: bool = o.get("beacon", false)
	ci.draw_rect(Rect2(-100, -246, 16, 6), Color("1c1e21"))
	var dome := _ellipse(Vector2(-92, -246), 7.0, 7.0, 16).slice(8, 16)
	dome.append(Vector2(-85, -246))
	ci.draw_colored_polygon(dome, Color("ffae3a") if lit and sin(t * 9.0) > 0.0 else Color("8c5a22"))
	var sway := sin(t * 2.3) * 3.0 + sin(t * 7.1) * 0.8 if moving else (sin(t * 23.0) * 0.4 if engine else 0.0)
	var tip := Vector2(-136 + sway, -332)
	ci.draw_polyline(PackedVector2Array([Vector2(-126, -240), Vector2(-129 + sway * 0.15, -270), Vector2(-132 + sway * 0.5, -302), tip]),
		Color("141618"), 1.5, true)
	ci.draw_circle(tip, 1.8, Color("141618"))
	ci.draw_rect(Rect2(-129, -244, 6, 5), Color("2a2c2f"))


## Mara at the wheel: a dark shape against the glass, ponytail, both hands on
## the wheel; the instrument lights catch the side of her face.
static func _cat_driver(ci: CanvasItem, engine: bool) -> void:
	var dark := Color("07090b")
	ci.draw_colored_polygon(_rrect(Rect2(-26, -206, 14, 38), 4.0), Color("121417"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-18, -168), Vector2(-16, -180), Vector2(-5, -186), Vector2(14, -186),
		Vector2(26, -181), Vector2(33, -168)]), dark)
	ci.draw_line(Vector2(22, -179), Vector2(50, -179), dark, 6.0, true)
	ci.draw_rect(Rect2(2, -193, 9, 9), dark)
	ci.draw_colored_polygon(_ellipse(Vector2(6, -202), 10.5, 13.0, 18), dark)
	ci.draw_polyline(PackedVector2Array([Vector2(-3, -207), Vector2(-9, -201), Vector2(-12, -192), Vector2(-11, -182)]), dark, 4.5, true)
	ci.draw_line(Vector2(48, -191), Vector2(57, -170), Color("141619"), 3.0, true)
	if engine:
		ci.draw_arc(Vector2(6, -202), 10.0, -0.95, 0.9, 8, Color(0.96, 0.64, 0.34, 0.6), 1.6, true)
		ci.draw_line(Vector2(26, -180), Vector2(48, -180), Color(0.96, 0.64, 0.34, 0.25), 1.2)


## Snow thrown up behind the tracks, and a little off the front.
static func _spray(ci: CanvasItem, t: float) -> void:
	for k in 16:
		var ph := fposmod(t * 1.3 + k / 16.0, 1.0)
		var j := float(k) * 1.7
		var p := Vector2(-198.0 - 160.0 * ph - 18.0 * sin(j), -8.0 - 70.0 * ph * (1.0 - ph) * (1.0 + 0.45 * sin(j * 2.3)))
		ci.draw_circle(p, 2.0 + 8.0 * ph, Color(0.9, 0.93, 0.98, 0.45 * (1.0 - ph)))
	for k in 6:
		var ph := fposmod(t * 1.7 + k / 6.0, 1.0)
		ci.draw_circle(Vector2(214.0 + 28.0 * ph, -6.0 - 18.0 * ph * (1.2 - ph)), 1.5 + 3.0 * ph, Color(0.9, 0.93, 0.98, 0.32 * (1.0 - ph)))


# --- Mara's pickup -----------------------------------------------------------------------

## Mara's truck: an early-'80s full-size pickup, two-tone, chrome bumpers and
## mirrors, a CB whip on the bed rail. Options:
##   body, trim: the two tones      engine: idling (exhaust, lit tail lamps)
##   lights: headlights on          beam: headlight beam length (local units)
##   snow: 0..1                     ruts: length of its tyre tracks behind it
##   flip: facing left              tilt: nose up (radians), on a grade
##   travel: distance driven, in screen px (turns the wheels)
##   cab: who's inside, ["mara"] or ["mara", "tomas"]
##   vapour: false to leave the exhaust to pickup_exhaust()
static func pickup(ci: CanvasItem, base: Vector2, s: float, t: float, o: Dictionary = {}) -> void:
	_truck_geo()
	var body: Color = o.get("body", Color("7c2a25"))
	var trim: Color = o.get("trim", Color("d8ccb0"))
	var engine: bool = o.get("engine", false)
	var lights: bool = o.get("lights", false)
	var snow: float = o.get("snow", 0.6)
	var beam: float = o.get("beam", 0.0)
	var ruts: float = o.get("ruts", 0.0)
	var flip := -1.0 if o.get("flip", false) else 1.0
	var tilt: float = o.get("tilt", 0.0) * flip
	var spin: float = float(o.get("travel", 0.0)) / (TYRE_R * s)
	var chrome := Color("c3c9cf")
	var shake := sin(t * 38.0) * 0.35 if engine else 0.0
	ci.draw_set_transform(base, -tilt, Vector2(s * flip, s))
	if ruts > 0.0:
		# The tracks it made coming up the access road.
		ci.draw_rect(Rect2(-150 - ruts, -3, ruts, 5), Color(0.18, 0.23, 0.34, 0.3))
		ci.draw_rect(Rect2(-130 - ruts, -17, ruts, 4), Color(0.18, 0.23, 0.34, 0.2))
	ci.draw_colored_polygon(_ellipse(Vector2(0, 1), 264.0, 9.0), Color(0.0, 0.0, 0.02, 0.34))
	if lights and beam > 0.0:
		var warm := Color(1.0, 0.9, 0.64)
		var from := Vector2(262, -94)
		ci.draw_polygon(PackedVector2Array([from + Vector2(0, -7), from + Vector2(beam, -beam * 0.14), from + Vector2(beam, beam * 0.17), from + Vector2(0, 7)]),
			PackedColorArray([Color(warm, 0.22), Color(warm, 0.0), Color(warm, 0.0), Color(warm, 0.22)]))
		ci.draw_colored_polygon(_ellipse(Vector2(from.x + beam * 0.42, -2), beam * 0.3, 9.0), Color(warm, 0.06))
	# Wheel wells, then the tyres.
	for axle in [AXLE_R, AXLE_F]:
		ci.draw_colored_polygon(_arch(axle, ARCH_R - 1.0), Color("0a0b0d"))
		_tyre(ci, axle, chrome, spin)
	ci.draw_set_transform(base + Vector2(0, shake) * s, -tilt, Vector2(s * flip, s))
	_truck_body(ci, body, trim, chrome, t, engine, lights, snow, o.get("cab", []))
	if engine and o.get("vapour", true):
		_vapour(ci, Vector2(-258, -30), t, false, 0.8)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The pickup's exhaust on its own, for a room that keeps the truck in its
## still picture (pickup(..., {"vapour": false})) and animates only this.
static func pickup_exhaust(ci: CanvasItem, base: Vector2, s: float, t: float, flip: bool = false) -> void:
	ci.draw_set_transform(base, 0.0, Vector2(s * (-1.0 if flip else 1.0), s))
	_vapour(ci, Vector2(-258, -30), t, false, 0.8)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _truck_geo() -> void:
	if not _truck_shell.is_empty():
		return
	var p := PackedVector2Array([Vector2(-258, -50), Vector2(-260, -112), Vector2(-48, -112), Vector2(-48, -166),
		Vector2(-44, -174), Vector2(-34, -179), Vector2(46, -179), Vector2(54, -175), Vector2(92, -122), Vector2(102, -118),
		Vector2(248, -114), Vector2(256, -108), Vector2(258, -62), Vector2(252, -50)])
	for axle in [AXLE_F, AXLE_R]:
		p.append_array(_arch(axle, ARCH_R))
	_truck_shell = p


## A wheel opening: the arc over the axle, front to back, between the points
## where it meets the rocker line (y -50). As a polygon it closes along that line.
static func _arch(axle: Vector2, r: float) -> PackedVector2Array:
	var a0 := asin(clampf((axle.y + 50.0) / r, -1.0, 1.0))
	var pts := PackedVector2Array()
	for i in 15:
		var a := lerpf(-a0, -PI + a0, i / 14.0)
		pts.append(axle + Vector2(cos(a), sin(a)) * r)
	return pts


static func _tyre(ci: CanvasItem, c: Vector2, chrome: Color, spin: float = 0.0) -> void:
	var rubber := Color("141518")
	ci.draw_circle(c, TYRE_R, rubber)
	for i in 22:
		var a := TAU * i / 22.0 + spin
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * (TYRE_R - 5.0), c + d * (TYRE_R - 0.5), Color("232529"), 2.2)
	ci.draw_arc(c, TYRE_R - 7.0, PI * 1.05, PI * 1.65, 10, Color("2c2f33"), 2.0, true)
	ci.draw_circle(c, 22.0, Color("5d646b"))
	ci.draw_circle(c, 20.0, chrome)
	ci.draw_arc(c, 20.0, 0.0, TAU, 28, chrome.darkened(0.4), 1.2, true)
	ci.draw_circle(c, 13.0, chrome.lightened(0.16))
	ci.draw_arc(c, 13.0, PI * 0.1, PI * 0.9, 10, chrome.darkened(0.35), 1.2, true)
	ci.draw_circle(c + Vector2(-4, -4), 3.5, Color(1, 1, 1, 0.55))


static func _truck_body(ci: CanvasItem, body: Color, trim: Color, chrome: Color, t: float, engine: bool, lights: bool, snow: float, cab: Array = []) -> void:
	var shell := _truck_shell
	var seam := body.darkened(0.5)
	_shade(ci, shell, body.lightened(0.16), body.darkened(0.3))
	# The two-tone band between chrome mouldings, broken by the wheel arches.
	for poly in Geometry2D.intersect_polygons(shell, _rect_pts(Rect2(-272, -86, 544, 26))):
		_shade(ci, poly, trim.lightened(0.06), trim.darkened(0.18))
		var closed: PackedVector2Array = poly.duplicate()
		closed.append(poly[0])
		ci.draw_polyline(closed, chrome, 1.4, true)
	# Wheel-opening mouldings.
	for axle in [AXLE_R, AXLE_F]:
		ci.draw_polyline(_arch(axle, ARCH_R), chrome.darkened(0.1), 2.0, true)
	# Beltline crease, hood line, the roof and its drip rail.
	ci.draw_line(Vector2(-256, -104), Vector2(254, -104), body.lightened(0.28), 1.2)
	ci.draw_line(Vector2(-256, -102.6), Vector2(254, -102.6), body.darkened(0.3), 1.0)
	ci.draw_polyline(PackedVector2Array([Vector2(102, -118), Vector2(248, -114), Vector2(256, -108)]), body.lightened(0.4), 1.5, true)
	ci.draw_line(Vector2(108, -109), Vector2(250, -107), body.lightened(0.18), 0.8)
	ci.draw_polyline(PackedVector2Array([Vector2(-48, -166), Vector2(-44, -174), Vector2(-34, -179), Vector2(46, -179)]), body.lightened(0.42), 1.5, true)
	ci.draw_polyline(PackedVector2Array([Vector2(-44, -171), Vector2(46, -172), Vector2(53, -169)]), seam, 1.6, true)
	# Bed: the rail cap, stake pockets, the gap behind the cab, tailgate edge,
	# fuel door.
	ci.draw_line(Vector2(-259, -111), Vector2(-50, -111), body.darkened(0.15), 3.0)
	ci.draw_line(Vector2(-259, -112.6), Vector2(-50, -112.6), body.lightened(0.35), 1.0)
	for x in [-236.0, -150.0, -66.0]:
		ci.draw_rect(Rect2(x, -111, 7, 3), Color("141517"))
	ci.draw_line(Vector2(-48, -112), Vector2(-48, -51), Color("0e0f11"), 2.6)
	ci.draw_line(Vector2(-252, -110), Vector2(-252, -52), seam, 1.2)
	_outline(ci, _rrect(Rect2(-128, -100, 16, 13), 2.0), seam, 1.0)
	# Door: seams, handle and lock.
	ci.draw_polyline(PackedVector2Array([Vector2(-36, -172), Vector2(-36, -54), Vector2(96, -54), Vector2(96, -120)]), seam, 1.3, true)
	ci.draw_rect(Rect2(-30, -118, 14, 4), chrome)
	ci.draw_circle(Vector2(-12, -116), 1.6, chrome.darkened(0.3))
	# Glass: the side window with its vent wing, the bench seat and the wheel
	# inside, the dash lights if she's running.
	var glass := PackedVector2Array(TRUCK_GLASS)
	_glass_base(ci, glass)
	ci.draw_line(Vector2(-38, -137), Vector2(28, -137), Color("111316"), 5.0)
	ci.draw_line(Vector2(44, -151), Vector2(55, -130), Color("121417"), 3.0, true)
	if "tomas" in cab:
		_cab_person(ci, Vector2(-8, -124), 0.86, Color("0c0e11"), false)
	if "mara" in cab:
		_cab_person(ci, Vector2(18, -124), 1.0, Color("07090b"), engine)
	if engine:
		ci.draw_polygon(PackedVector2Array([Vector2(26, -136), Vector2(64, -136), Vector2(73, -124), Vector2(26, -124)]),
			PackedColorArray([Color(1.0, 0.62, 0.3, 0.0), Color(1.0, 0.62, 0.3, 0.0), Color(1.0, 0.62, 0.3, 0.42), Color(1.0, 0.62, 0.3, 0.42)]))
	_glass_top(ci, glass)
	ci.draw_line(Vector2(52, -125), Vector2(41, -166), Color("0d0f11"), 2.0, true)
	ci.draw_line(Vector2(54, -175), Vector2(92, -122), Color("101215"), 3.0, true)
	ci.draw_line(Vector2(50.5, -172), Vector2(87, -123), Color(0.56, 0.7, 0.82, 0.4), 1.3, true)
	# West Coast mirror.
	ci.draw_line(Vector2(78, -149), Vector2(100, -151), chrome.darkened(0.2), 1.6, true)
	ci.draw_line(Vector2(84, -128), Vector2(100, -131), chrome.darkened(0.2), 1.6, true)
	ci.draw_colored_polygon(_rrect(Rect2(99, -160, 7, 36), 1.5), Color("16181b"))
	_outline(ci, _rrect(Rect2(99, -160, 7, 36), 1.5), chrome, 1.0)
	# Front: grille edge, headlight, turn lamp, badge, marker lamps, bumpers.
	ci.draw_rect(Rect2(254, -107, 4, 44), Color("1a1c1e"))
	ci.draw_rect(Rect2(255.5, -103, 3, 15), Color("fff1c8") if lights else Color("aaa490"))
	ci.draw_rect(Rect2(255.5, -84, 3, 8), Color("ffad42") if lights else Color("8a6a30"))
	if lights:
		ci.draw_circle(Vector2(259, -95), 13.0, Color(1.0, 0.95, 0.78, 0.22))
		ci.draw_circle(Vector2(259, -95), 5.0, Color(1.0, 0.98, 0.9, 0.8))
	ci.draw_rect(Rect2(206, -97, 22, 4), chrome)
	ci.draw_rect(Rect2(240, -81, 8, 6), Color("e09a3c") if lights else Color("8a5e2a"))
	ci.draw_rect(Rect2(-251, -97, 7, 6), Color("c0302a") if lights else Color("6e1a18"))
	_shade(ci, PackedVector2Array([Vector2(250, -66), Vector2(268, -66), Vector2(271, -46), Vector2(250, -44)]), chrome.lightened(0.25), chrome.darkened(0.35))
	_shade(ci, PackedVector2Array([Vector2(-272, -64), Vector2(-252, -64), Vector2(-252, -46), Vector2(-270, -46)]), chrome.lightened(0.25), chrome.darkened(0.35))
	ci.draw_line(Vector2(250, -64), Vector2(268, -64), Color(1, 1, 1, 0.6), 1.0)
	# Tail lamp; it glows while she idles.
	ci.draw_rect(Rect2(-263, -106, 7, 30), Color("e2332a") if engine else Color("7c1a18"))
	if engine:
		ci.draw_circle(Vector2(-260, -91), 14.0, Color(1.0, 0.18, 0.12, 0.16))
	# Mud flaps; slush thrown on the rockers.
	ci.draw_rect(Rect2(-207, -58, 6, 42), Color("121315"))
	ci.draw_rect(Rect2(98, -54, 5, 32), Color("121315"))
	for k in 6:
		var x := -100.0 + k * 9.0
		ci.draw_line(Vector2(x, -52), Vector2(x - 14, -58 - (k % 3) * 3.0), Color(0.75, 0.8, 0.88, 0.22), 1.6)
	# Snow on the roof, hood and bed rail, packed in the wheel arches.
	if snow > 0.0:
		_snow_line(ci, Vector2(-42, -179), Vector2(48, -179), 2.0 + 8.0 * snow, 21)
		_snow_line(ci, Vector2(104, -118), Vector2(247, -114), 1.0 + 4.0 * snow, 23)
		_snow_line(ci, Vector2(-257, -113), Vector2(-52, -113), 1.0 + 4.0 * snow, 25)
		for axle in [AXLE_R, AXLE_F]:
			ci.draw_arc(axle, ARCH_R - 4.0, -PI * 0.88, -PI * 0.14, 14, Color(0.84, 0.88, 0.94, 0.85), 2.0 + 4.0 * snow, true)
	# CB whip on the front of the bed rail, rocking a little at idle.
	var sway := sin(t * 6.0) * 0.8 if engine else 0.0
	ci.draw_line(Vector2(-56, -112), Vector2(-57, -124), Color("1c1e21"), 3.2)
	ci.draw_polyline(PackedVector2Array([Vector2(-57, -124), Vector2(-61 + sway * 0.3, -170), Vector2(-67 + sway * 0.7, -220), Vector2(-74 + sway, -268)]),
		Color("15171a"), 1.4, true)
	# Exhaust pipe under the back bumper.
	ci.draw_line(Vector2(-232, -30), Vector2(-258, -31), Color("202225"), 4.0)


## Someone in the truck's cab, seen through the side glass: head and
## shoulders against the dash glow. `seat` is where they sit (local units).
static func _cab_person(ci: CanvasItem, seat: Vector2, k: float, dark: Color, lit: bool) -> void:
	var head := seat + Vector2(0, -32) * k
	ci.draw_colored_polygon(PackedVector2Array([seat + Vector2(-18, 0) * k, seat + Vector2(-16, -14) * k, seat + Vector2(-6, -20) * k,
		seat + Vector2(10, -20) * k, seat + Vector2(20, -13) * k, seat + Vector2(24, 0) * k]), dark)
	ci.draw_rect(Rect2(head + Vector2(-3, 6) * k, Vector2(8, 8) * k), dark)
	ci.draw_colored_polygon(_ellipse(head, 9.5 * k, 11.5 * k, 16), dark)
	if lit:
		ci.draw_arc(head, 9.0 * k, -0.95, 0.9, 8, Color(0.96, 0.64, 0.34, 0.55), 1.5, true)


# --- the sheriff's cruiser and Ruth's sedan ----------------------------------------------------

const CAR_AXLE_R := Vector2(-158, -34)
const CAR_AXLE_F := Vector2(150, -34)
const CAR_TYRE_R := 33.0
const CAR_SHELL := [Vector2(-268, -50), Vector2(-271, -86), Vector2(-262, -95), Vector2(-152, -98), Vector2(-112, -139),
	Vector2(-100, -144), Vector2(34, -144), Vector2(46, -140), Vector2(106, -99), Vector2(256, -94), Vector2(268, -86),
	Vector2(271, -55), Vector2(262, -48)]
const CAR_REAR_GLASS := [Vector2(-138, -101), Vector2(-106, -134), Vector2(-42, -134), Vector2(-42, -101)]
const CAR_FRONT_GLASS := [Vector2(-34, -101), Vector2(-34, -134), Vector2(34, -134), Vector2(42, -131), Vector2(92, -101)]


## A late-'70s full-size four-door, side on, facing right (100 units to the
## metre). Options:
##   police: the county sheriff's black-and-white, with the light bar
##   body, doors: paint            bar: light bar turning (red and blue)
##   lights: headlights            beam: headlight beam length (local units)
##   engine: exhaust               snow: 0..1 on the roof and hood
##   flip: facing left             travel: distance driven (turns the wheels)
static func car(ci: CanvasItem, base: Vector2, s: float, t: float, o: Dictionary = {}) -> void:
	var police: bool = o.get("police", false)
	var body: Color = o.get("body", Color("17191c") if police else Color("8a7a5a"))
	var doors: Color = o.get("doors", Color("e8e6de") if police else body)
	var lights: bool = o.get("lights", false)
	var beam: float = o.get("beam", 0.0)
	var engine: bool = o.get("engine", false)
	var snow: float = o.get("snow", 0.0)
	var flip := -1.0 if o.get("flip", false) else 1.0
	var spin: float = float(o.get("travel", 0.0)) / (CAR_TYRE_R * s)
	var chrome := Color("c3c9cf")
	ci.draw_set_transform(base, 0.0, Vector2(s * flip, s))
	ci.draw_colored_polygon(_ellipse(Vector2(0, 1), 270.0, 8.0), Color(0.0, 0.0, 0.02, 0.34))
	if lights and beam > 0.0:
		var warm := Color(1.0, 0.93, 0.74)
		var from := Vector2(268, -76)
		ci.draw_polygon(PackedVector2Array([from + Vector2(0, -6), from + Vector2(beam, -beam * 0.12), from + Vector2(beam, beam * 0.15), from + Vector2(0, 6)]),
			PackedColorArray([Color(warm, 0.24), Color(warm, 0.0), Color(warm, 0.0), Color(warm, 0.24)]))
	var shell := PackedVector2Array(CAR_SHELL)
	for axle in [CAR_AXLE_F, CAR_AXLE_R]:
		ci.draw_colored_polygon(_car_arch(axle, CAR_TYRE_R + 8.0), Color("0a0b0d"))
	for axle in [CAR_AXLE_R, CAR_AXLE_F]:
		_car_tyre(ci, axle, chrome, spin)
	# The body, cut away at the wheel openings.
	var cut := shell
	for axle in [CAR_AXLE_F, CAR_AXLE_R]:
		var hole := _car_arch(axle, CAR_TYRE_R + 9.0)
		var parts := Geometry2D.clip_polygons(cut, hole)
		if parts.size() > 0:
			cut = parts[0]
	_shade(ci, cut, body.lightened(0.18), body.darkened(0.35))
	# Doors in their own colour (the black-and-white's white doors).
	for poly in Geometry2D.intersect_polygons(cut, _rect_pts(Rect2(-146, -100, 244, 54))):
		_shade(ci, poly, doors.lightened(0.05), doors.darkened(0.22))
	var seam := body.darkened(0.55) if not police else Color("3a3c40")
	ci.draw_line(Vector2(-146, -100), Vector2(-146, -50), seam, 1.4)
	ci.draw_line(Vector2(-40, -100), Vector2(-40, -50), seam, 1.4)
	ci.draw_line(Vector2(98, -100), Vector2(98, -54), seam, 1.4)
	for x in [-60.0, 78.0]:
		ci.draw_rect(Rect2(x, -92, 12, 3), chrome)
	# Chrome: the beltline and the rocker, the bumpers.
	ci.draw_line(Vector2(-266, -95), Vector2(258, -93), chrome.darkened(0.15), 1.6)
	ci.draw_line(Vector2(-258, -52), Vector2(256, -51), chrome.darkened(0.25), 2.0)
	_shade(ci, PackedVector2Array([Vector2(258, -62), Vector2(276, -62), Vector2(278, -44), Vector2(258, -42)]), chrome.lightened(0.25), chrome.darkened(0.35))
	_shade(ci, PackedVector2Array([Vector2(-278, -62), Vector2(-258, -62), Vector2(-258, -43), Vector2(-276, -44)]), chrome.lightened(0.25), chrome.darkened(0.35))
	# Glass, and pillars.
	for g in [CAR_REAR_GLASS, CAR_FRONT_GLASS]:
		var gp := PackedVector2Array(g)
		_glass_base(ci, gp)
		_glass_top(ci, gp)
	ci.draw_line(Vector2(-38, -136), Vector2(-38, -100), Color("0e0f11"), 5.0)
	# Lamps.
	ci.draw_rect(Rect2(262, -84, 8, 16), Color("fff3cf") if lights else Color("a9a592"))
	if lights:
		ci.draw_circle(Vector2(270, -76), 12.0, Color(1.0, 0.95, 0.8, 0.25))
	ci.draw_rect(Rect2(-272, -88, 7, 22), Color("d8322a") if engine or lights else Color("6e1a18"))
	if engine:
		_vapour(ci, Vector2(-262, -28), t, false, 0.8)
	if police:
		# The county star and lettering on the front door, the spotlight, the bar.
		var star := Vector2(26, -76)
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2.0 + PI * i / 5.0
			pts.append(star + Vector2(cos(a), sin(a)) * (11.0 if i % 2 == 0 else 4.5))
		ci.draw_colored_polygon(pts, Color("b88a2c"))
		Kit.text(ci, Vector2(-30, -58), "SHERIFF", 11, Color("2a2c30"))
		ci.draw_line(Vector2(42, -139), Vector2(52, -150), Color("1a1b1d"), 3.0)
		ci.draw_colored_polygon(_ellipse(Vector2(56, -152), 7.0, 5.0, 12), Color("c3c9cf"))
		ci.draw_rect(Rect2(-70, -152, 96, 9), Color("202226"))
		var on: bool = o.get("bar", false)
		var ph := fposmod(t * 1.6, 1.0)
		ci.draw_colored_polygon(_ellipse(Vector2(-48, -156), 13.0, 9.0, 14), Color(1.0, 0.18, 0.15, 0.95 if on and ph < 0.5 else 0.45))
		ci.draw_colored_polygon(_ellipse(Vector2(4, -156), 13.0, 9.0, 14), Color(0.2, 0.4, 1.0, 0.95 if on and ph >= 0.5 else 0.45))
	if snow > 0.0:
		_snow_line(ci, Vector2(-98, -144), Vector2(34, -144), 2.0 + 6.0 * snow, 31)
		_snow_line(ci, Vector2(108, -99), Vector2(254, -95), 1.0 + 4.0 * snow, 33)
		_snow_line(ci, Vector2(-262, -96), Vector2(-154, -98), 1.0 + 4.0 * snow, 35)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The cruiser's bar lighting up the snow round it: red, then blue. Draw it on
## a glow layer. `base` and `s` as for car().
static func car_bar_glow(ci: CanvasItem, base: Vector2, s: float, t: float, flip: bool = false) -> void:
	var ph := fposmod(t * 1.6, 1.0)
	var col := Color(1.0, 0.2, 0.15) if ph < 0.5 else Color(0.25, 0.42, 1.0)
	var x := (-48.0 if ph < 0.5 else 4.0) * s * (-1.0 if flip else 1.0)
	var c := base + Vector2(x, -156.0 * s)
	var pulse := 0.5 + 0.5 * sin(fposmod(t * 1.6, 0.5) * TAU * 2.0)
	ci.draw_circle(c, 90.0 * s, Color(col, 0.10 * pulse))
	ci.draw_circle(c, 34.0 * s, Color(col, 0.22 * pulse))
	ci.draw_colored_polygon(_ellipse(base + Vector2(0, -2), 420.0 * s, 26.0 * s, 24), Color(col, 0.06 * pulse))


static func _car_arch(axle: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 17:
		var a := lerpf(0.0, -PI, i / 16.0)
		pts.append(axle + Vector2(cos(a), sin(a)) * r)
	pts.append(axle + Vector2(-r, 30))
	pts.append(axle + Vector2(r, 30))
	return pts


static func _car_tyre(ci: CanvasItem, c: Vector2, chrome: Color, spin: float) -> void:
	ci.draw_circle(c, CAR_TYRE_R, Color("141518"))
	for i in 18:
		var a := TAU * i / 18.0 + spin
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * (CAR_TYRE_R - 5.0), c + d * (CAR_TYRE_R - 0.5), Color("232529"), 2.0)
	ci.draw_circle(c, 19.0, Color("5d646b"))
	ci.draw_circle(c, 17.0, chrome.darkened(0.15))
	ci.draw_circle(c, 9.0, chrome.lightened(0.1))
	for i in 5:
		var a := TAU * i / 5.0 + spin
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * 12.5, 1.5, chrome.darkened(0.45))


# --- the county plow ---------------------------------------------------------------------

## The county plow, far down the road and heading away: the dump box, the cab
## roof beyond it, the blade's ends past both sides. `a` dims it into the
## night. plow_lights() adds its lamps on the glow layer.
static func plow_far(ci: CanvasItem, base: Vector2, s: float, a: float = 1.0) -> void:
	ci.draw_set_transform(base, 0.0, Vector2(s, s))
	var dark := Color(0.035, 0.045, 0.06, a)
	var blade := Color(0.3, 0.21, 0.08, a)
	ci.draw_colored_polygon(_ellipse(Vector2(0, -1), 40.0, 4.0, 16), Color(0.0, 0.0, 0.02, 0.35 * a))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-36, -3), Vector2(-24, -3), Vector2(-24, -14), Vector2(-35, -12)]), blade)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(24, -3), Vector2(31, -3), Vector2(30, -10), Vector2(24, -12)]), blade)
	ci.draw_rect(Rect2(-22, -10, 9, 10), dark)
	ci.draw_rect(Rect2(13, -10, 9, 10), dark)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-24, -9), Vector2(24, -9), Vector2(26, -40), Vector2(-26, -40)]), dark)
	ci.draw_rect(Rect2(-14, -48, 28, 8), dark)
	# Snow riding on the box and the cab roof.
	ci.draw_line(Vector2(-25, -41), Vector2(25, -41), Color(0.82, 0.86, 0.93, 0.8 * a), 2.5)
	ci.draw_line(Vector2(-13, -48.5), Vector2(13, -48.5), Color(0.82, 0.86, 0.93, 0.8 * a), 2.0)
	ci.draw_rect(Rect2(-5, -9, 10, 5), Color(0.12, 0.12, 0.14, a))
	# Snow the blade has thrown up the bank, settling.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, 0), Vector2(-36, -12), Vector2(-30, -4), Vector2(-52, 2)]), Color(0.78, 0.82, 0.9, 0.5 * a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The plow's tail lamps, its turning amber beacon, and its headlights
## washing the snow ahead of it.
static func plow_lights(ci: CanvasItem, base: Vector2, s: float, t: float) -> void:
	ci.draw_set_transform(base, 0.0, Vector2(s, s))
	ci.draw_colored_polygon(_ellipse(Vector2(0, -2), 52.0, 6.0, 20), Color(1.0, 0.92, 0.7, 0.1))
	for x in [-19.0, 19.0]:
		ci.draw_circle(Vector2(x, -15), 2.6, Color(1.0, 0.2, 0.14, 0.95))
		ci.draw_circle(Vector2(x, -15), 7.0, Color(1.0, 0.2, 0.14, 0.18))
	var turn := pow(0.5 + 0.5 * sin(t * 5.5), 3.0)
	ci.draw_circle(Vector2(0, -53), 3.8, Color(1.0, 0.68, 0.22, 0.75 + 0.25 * turn))
	ci.draw_circle(Vector2(0, -53), 9.0, Color(1.0, 0.62, 0.18, 0.2 + 0.2 * turn))
	ci.draw_circle(Vector2(0, -53), 22.0, Color(1.0, 0.62, 0.18, 0.2 * turn))
	ci.draw_colored_polygon(_ellipse(Vector2(0, -1), 70.0, 7.0, 20), Color(1.0, 0.6, 0.15, 0.07 * turn))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- shared pieces -----------------------------------------------------------------------

static func _wheel(ci: CanvasItem, c: Vector2, r: float, ang: float, tyre: Color, rim: Color, lugs: int) -> void:
	ci.draw_circle(c, r, tyre)
	ci.draw_arc(c, r - 1.2, PI * 1.08, PI * 1.62, 8, tyre.lightened(0.24), 1.4, true)
	var rr := r * 0.6
	ci.draw_circle(c, rr, rim)
	ci.draw_arc(c, rr, 0.0, TAU, 24, rim.darkened(0.42), 1.0, true)
	ci.draw_circle(c, rr * 0.42, rim.lightened(0.18))
	for i in lugs:
		var a := ang + TAU * i / lugs
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * rr * 0.7, maxf(0.9, r * 0.065), rim.darkened(0.5))


static func _sprocket(ci: CanvasItem, c: Vector2, r: float, ang: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := ang + TAU * i / 48.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 4 < 2 else r * 0.8))
	ci.draw_colored_polygon(pts, col)
	ci.draw_circle(c, r * 0.64, col.darkened(0.28))
	ci.draw_circle(c, r * 0.52, col.lightened(0.08))
	for i in 6:
		var a := ang + TAU * i / 6.0
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.34, 1.6, col.darkened(0.45))
	ci.draw_circle(c, r * 0.16, col.lightened(0.3))


## Exhaust vapour rising from `top` into the cold, streaming back when moving.
static func _vapour(ci: CanvasItem, top: Vector2, t: float, moving: bool, rate: float) -> void:
	for k in 7:
		var ph := fposmod(t * 0.55 * rate + k / 7.0, 1.0)
		var drift := Vector2(-(190.0 if moving else 70.0) * ph, -(40.0 if moving else 80.0) * ph)
		var wob := Vector2(sin(t * 1.3 + k) * 6.0 * ph, 0.0)
		ci.draw_circle(top + drift + wob, 4.0 + 18.0 * ph, Color(0.8, 0.82, 0.86, 0.2 * (1.0 - ph) * minf(1.0, ph * 8.0)))


## Glass: dark, with the night sky reflected along its top.
static func _glass_base(ci: CanvasItem, pts: PackedVector2Array) -> void:
	_shade(ci, pts, Color("2c3f53"), Color("0a1016"))


## Reflections across the glass, and the rubber seal round it.
static func _glass_top(ci: CanvasItem, pts: PackedVector2Array) -> void:
	var r := _bounds(pts)
	for k in 2:
		var x0 := r.position.x + r.size.x * (0.1 + 0.46 * k)
		var w := r.size.x * (0.2 - 0.08 * k)
		var lean := r.size.y * 0.6
		var streak := PackedVector2Array([Vector2(x0, r.end.y), Vector2(x0 + w, r.end.y), Vector2(x0 + w + lean, r.position.y), Vector2(x0 + lean, r.position.y)])
		for poly in Geometry2D.intersect_polygons(pts, streak):
			ci.draw_colored_polygon(poly, Color(0.72, 0.84, 0.96, 0.11 - 0.04 * k))
	_outline(ci, pts, Color("0a0c0e"), 2.4)


## Snow lying along a line from a to b (left to right), lumpy, thinning at the ends.
static func _snow_line(ci: CanvasItem, a: Vector2, b: Vector2, thick: float, seed: int) -> void:
	var length := a.distance_to(b)
	if length < 1.0 or thick <= 0.0:
		return
	var u := (b - a) / length
	var up := Vector2(u.y, -u.x)
	var n := maxi(3, int(length / 12.0))
	var pts := PackedVector2Array([a - up])
	for i in n + 1:
		var f := float(i) / n
		var taper := 1.0 - pow(absf(f * 2.0 - 1.0), 6.0)
		pts.append(a.lerp(b, f) + up * thick * (0.55 + 0.45 * Townscape.h(seed + i * 13)) * taper)
	pts.append(b - up)
	ci.draw_colored_polygon(pts, Color("dfe6f0"))
	ci.draw_polyline(pts.slice(1, pts.size() - 1), Color("f6f8fc"), 1.2, true)


static func _shade(ci: CanvasItem, pts: PackedVector2Array, top: Color, bottom: Color) -> void:
	if pts.size() < 3:
		return
	var miny := INF
	var maxy := -INF
	for p in pts:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span := maxf(1.0, maxy - miny)
	var cols := PackedColorArray()
	cols.resize(pts.size())
	for i in pts.size():
		cols[i] = top.lerp(bottom, (pts[i].y - miny) / span)
	ci.draw_polygon(pts, cols)


## A vertical gradient over rect r, clipped to shape.
static func _clip_grad(ci: CanvasItem, shape: PackedVector2Array, r: Rect2, top: Color, bottom: Color) -> void:
	for poly in Geometry2D.intersect_polygons(shape, _rect_pts(r)):
		var cols := PackedColorArray()
		for p in poly:
			cols.append(top.lerp(bottom, clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)))
		ci.draw_polygon(poly, cols)


static func _outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, w, true)


static func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


static func _rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func _rrect(r: Rect2, rad: float, seg: int = 3) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var cs: Array[Vector2] = [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var pts := PackedVector2Array()
	for k in 4:
		for i in seg + 1:
			var a := -PI / 2.0 + PI / 2.0 * k + PI / 2.0 * i / seg
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func _ellipse(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
