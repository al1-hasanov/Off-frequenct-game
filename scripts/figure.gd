class_name Figure
extends RefCounted
## Draws one person side-on, facing +x, feet on the floor at the origin.
##
## The figure is a small skeleton (hips, knees, ankles, shoulders, elbows,
## wrists, neck, head) posed by Actor every frame. Limbs are tapered,
## muscled shapes; the torso is a shaped profile (bust and waist for women,
## a broader chest and belly for men, a slight, narrow body for Tomas); faces
## are drawn in profile with eyes, brows, lips and age lines; every character
## has their own hair and clothes (see Looks). Shapes get a soft top-to-bottom
## shade and a thin outline, so people read clearly against any room.
##
## Angles: 0 points straight down, positive swings forward (towards +x).

const THIGH := 0.245
const SHIN := 0.245
const ANKLE_H := 0.04
const UPPER_ARM := 0.172
const FOREARM := 0.148
const HAND := 0.085

var look: Dictionary
var H := 188.0
var sex := "f"
## A silhouette: every shape in one flat colour, no features.
var flat := false
var flat_col := Color("070a10")

var ci: CanvasItem
var _hip := Vector2.ZERO
var _fwd := Vector2.RIGHT
var _dn := Vector2.DOWN
var _hc := Vector2.ZERO
var _ha := 0.0
var _s := 25.0


func _init(l: Dictionary) -> void:
	look = l
	H = float(l.get("height", 188.0))
	sex = str(l.get("sex", "f"))


# --- pose helpers (used by Actor) ---------------------------------------------------

static func dir(a: float) -> Vector2:
	return Vector2(sin(a), cos(a))


## How far below the hip joint the lower sole reaches, for this pose's legs.
func leg_drop(legs: Array) -> float:
	var low := 0.0
	for l in legs:
		var knee: Vector2 = dir(l[0]) * THIGH * H
		var ankle: Vector2 = knee + dir(l[0] - l[1]) * SHIN * H
		low = maxf(low, ankle.y + ANKLE_H * H)
	return low


# --- drawing -------------------------------------------------------------------------

## pose: hip (Vector2), torso, head (angles), legs [[thigh, knee bend, foot], near, far],
## arms [[upper, elbow bend], near, far], breath (0..1), blink (bool),
## extras: tape (Color), headphones ("" / "head" / "neck"), prop, cord_tape (Color), stain (bool),
## prop_col (Color), blanket (Color: one round the shoulders), buttoned (bool: a parka done up to the top).
func draw(target: CanvasItem, pose: Dictionary) -> void:
	ci = target
	_hip = pose.hip
	var t: float = pose.torso + float(look.get("stoop", 0.0))
	_fwd = Vector2(cos(t), sin(t))
	_dn = Vector2(-sin(t), cos(t))
	_s = float(look.get("head", 0.135)) * H
	_ha = t + float(pose.get("head", 0.0))
	var neck_base := _T(0.004, -0.296)
	_hc = neck_base + Vector2(0.018 * H, -0.072 * H).rotated(_ha)

	var legs: Array = pose.legs
	var arms: Array = pose.arms
	var knees := []
	var ankles := []
	for i in 2:
		var hj := _hip + (Vector2(-2.0, -1.0) if i == 1 else Vector2.ZERO)
		var k: Vector2 = hj + dir(legs[i][0]) * THIGH * H
		knees.append(k)
		ankles.append(k + dir(legs[i][0] - legs[i][1]) * SHIN * H)

	_arm(arms[1], true, pose)
	_leg(_hip + Vector2(-2.0, -1.0), knees[1], ankles[1], float(legs[1][2]), true)
	_leg(_hip, knees[0], ankles[0], float(legs[0][2]), false)
	_hair_back()
	_lower_garment(knees, pose)
	_torso(pose)
	_neck(neck_base)
	_head(pose)
	_braid()
	_scarf_front()
	_arm(arms[0], false, pose)
	_blanket(pose)
	_prop(pose)


func _T(x: float, y: float) -> Vector2:
	return _hip + _fwd * (x * H) + _dn * (y * H)


func _HP(x: float, y: float) -> Vector2:
	return _hc + Vector2(x, y).rotated(_ha) * _s


func _col(c: Color) -> Color:
	return flat_col if flat else c


# --- primitives ----------------------------------------------------------------------

## A smooth closed outline through the given points (Catmull-Rom).
static func smooth(src: PackedVector2Array, steps: int = 3, closed: bool = true) -> PackedVector2Array:
	var p := PackedVector2Array()
	for q in src:
		if p.is_empty() or p[p.size() - 1].distance_squared_to(q) > 0.25:
			p.append(q)
	if closed and p.size() > 2 and p[0].distance_squared_to(p[p.size() - 1]) <= 0.25:
		p.remove_at(p.size() - 1)
	var n := p.size()
	if n < 3:
		return p
	var out := PackedVector2Array()
	var last := n if closed else n - 1
	for i in last:
		var p0 := p[(i - 1 + n) % n] if closed or i > 0 else p[0]
		var p1 := p[i]
		var p2 := p[(i + 1) % n]
		var p3 := p[(i + 2) % n] if closed or i + 2 < n else p[n - 1]
		for k in steps:
			var u := float(k) / steps
			var u2 := u * u
			var u3 := u2 * u
			out.append(0.5 * ((2.0 * p1) + (p2 - p0) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * u3))
	if not closed:
		out.append(p[n - 1])
	return out


## Fills a shape with a soft vertical shade (light above, darker below).
func fill(pts: PackedVector2Array, c: Color, light: float = 0.08, dark: float = 0.16, outline: bool = true) -> void:
	if pts.size() < 3:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		pts = Geometry2D.convex_hull(pts)
		pts.remove_at(pts.size() - 1)
		if pts.size() < 3:
			return
	if flat:
		ci.draw_colored_polygon(pts, flat_col)
		return
	var miny := INF
	var maxy := -INF
	for p in pts:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span := maxf(1.0, maxy - miny)
	var top := c.lightened(light)
	var bottom := c.darkened(dark)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, (p.y - miny) / span))
	ci.draw_polygon(pts, cols)
	if outline:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, Color(0.04, 0.03, 0.03, 0.42), 1.0, true)


func line(pts: PackedVector2Array, c: Color, w: float = 1.0) -> void:
	if not flat and pts.size() >= 2:
		ci.draw_polyline(pts, c, w, true)


## A tapered limb from a (radius ra) to b (radius rb), with a muscle bulge on
## the front (bf) or back (bb) side, peaking `at` of the way along.
static func capsule(a: Vector2, b: Vector2, ra: float, rb: float, bf: float = 0.0, bb: float = 0.0, at: float = 0.35) -> PackedVector2Array:
	var d := b - a
	var length := d.length()
	if length < 0.01:
		d = Vector2(0, 0.01)
	var u := d.normalized()
	var n := Vector2(u.y, -u.x)
	var pts := PackedVector2Array()
	for i in 7:
		var t := i / 6.0
		pts.append(a + d * t + n * (lerpf(ra, rb, t) + bf * exp(-pow((t - at) / 0.3, 2.0))))
	for i in range(1, 6):
		var ang := PI * i / 6.0
		pts.append(b + (n * cos(ang) + u * sin(ang)) * rb)
	for i in 7:
		var t := 1.0 - i / 6.0
		pts.append(a + d * t - n * (lerpf(ra, rb, t) + bb * exp(-pow((t - at) / 0.3, 2.0))))
	for i in range(1, 6):
		var ang := PI * i / 6.0
		pts.append(a + (-n * cos(ang) - u * sin(ang)) * ra)
	return pts


func _map_T(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_T(p.x, p.y))
	return out


func _map_H(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_HP(p.x, p.y))
	return out


# --- body parts ----------------------------------------------------------------------

func _skin() -> Color:
	return look.skin


func _leg_col() -> Color:
	if str(look.get("bottom", "")) in ["skirt", "dress", "nightgown"]:
		return look.get("legs_col", _skin())
	return look.bottom_col


func _leg(hj: Vector2, knee: Vector2, ankle: Vector2, foot: float, far: bool) -> void:
	var c: Color = _leg_col()
	if far:
		c = c.darkened(0.22)
	var hipr := (0.056 if sex == "f" else 0.052) * H
	if sex == "boy":
		hipr = 0.047 * H
	var thigh := capsule(hj, knee, hipr, 0.031 * H, 0.009 * H, 0.004 * H, 0.35)
	var shin := capsule(knee, ankle, 0.031 * H, 0.019 * H, 0.002 * H, 0.013 * H, 0.3)
	fill(thigh, c, 0.06, 0.12)
	fill(shin, c, 0.05, 0.14)
	if not flat:
		var bottom := str(look.get("bottom", ""))
		var u := (ankle - knee).normalized()
		var n := Vector2(u.y, -u.x)
		if bottom == "jeans":
			line(PackedVector2Array([hj + Vector2(2, 4), knee + n * 3.0, ankle + n * 2.0]), c.lightened(0.18), 1.0)
			line(PackedVector2Array([knee - n * 4.0 + u * 2.0, knee + n * 4.0 + u * 4.0]), c.darkened(0.25), 1.0)
		elif bottom == "pajamas":
			for k in 7:
				var p := hj.lerp(knee, k / 3.5) if k < 4 else knee.lerp(ankle, (k - 3) / 4.0)
				var uu := (knee - hj).normalized() if k < 4 else u
				var nn := Vector2(uu.y, -uu.x)
				line(PackedVector2Array([p - nn * 0.04 * H, p + nn * 0.04 * H]), c.darkened(0.3), 2.0)
		elif bottom == "trousers":
			line(PackedVector2Array([knee - n * 3.0 + u * 3.0, knee + n * 3.0 + u * 6.0]), c.darkened(0.3), 1.0)
	_shoe(ankle, foot, far)


func _shoe(ankle: Vector2, foot: float, far: bool) -> void:
	var c: Color = look.get("shoe_col", Color("222222"))
	if far:
		c = c.darkened(0.22)
	var fw := Vector2(cos(foot), -sin(foot))
	var dv := Vector2(sin(foot), cos(foot))
	var kind := str(look.get("shoes", "boots"))
	var m := func(x: float, y: float) -> Vector2: return ankle + fw * x * H + dv * y * H
	if kind == "boots":
		fill(capsule(ankle + Vector2(0, -0.07 * H), ankle, 0.026 * H, 0.024 * H), c, 0.06, 0.1)
	var pts := PackedVector2Array([m.call(-0.036, -0.012), m.call(-0.034, 0.04), m.call(0.112, 0.04),
		m.call(0.124, 0.028), m.call(0.112, 0.012), m.call(0.05, -0.006), m.call(0.018, -0.022)])
	if kind == "slippers":
		pts = PackedVector2Array([m.call(-0.03, 0.0), m.call(-0.03, 0.04), m.call(0.11, 0.04),
			m.call(0.125, 0.025), m.call(0.105, 0.006), m.call(0.04, -0.004), m.call(0.01, -0.012)])
	elif kind == "flats":
		pts = PackedVector2Array([m.call(-0.03, 0.006), m.call(-0.03, 0.04), m.call(0.108, 0.04),
			m.call(0.118, 0.03), m.call(0.1, 0.018), m.call(0.04, 0.012), m.call(0.012, -0.004)])
	fill(smooth(pts, 2), c, 0.1, 0.12)
	if flat:
		return
	match kind:
		"boots":
			line(PackedVector2Array([m.call(-0.034, 0.033), m.call(0.116, 0.033)]), c.darkened(0.45), 2.0)
			for k in 3:
				ci.draw_circle(m.call(0.03 + k * 0.016, 0.0 + k * 0.004), 0.8, c.lightened(0.3))
		"sneakers":
			fill(PackedVector2Array([m.call(-0.035, 0.028), m.call(0.118, 0.028), m.call(0.12, 0.04), m.call(-0.034, 0.04)]),
				Color("f2efe8"), 0.0, 0.05, false)
			line(PackedVector2Array([m.call(0.0, 0.012), m.call(0.07, 0.016)]), Color("c8322a") if not far else Color("8a2a24"), 2.0)
		"slippers":
			ci.draw_circle(m.call(0.09, 0.012), 0.012 * H, c.lightened(0.15))


## Arms are posed by absolute angle (0 = hanging straight down).
func _arm(a: Array, far: bool, pose: Dictionary) -> void:
	var sh := _T(-0.014, -0.266) + (Vector2(-3.0, 1.0) if far else Vector2.ZERO)
	var elbow := sh + dir(a[0]) * UPPER_ARM * H
	var wrist := elbow + dir(a[0] + a[1]) * FOREARM * H
	var sleeve: Color = look.top_col
	if str(look.get("top", "")) == "flannel":
		sleeve = look.top_col
	var skin := _skin()
	if far:
		sleeve = sleeve.darkened(0.28)
		skin = skin.darkened(0.22)
	var short_sleeve := str(look.get("top", "")) == "dress"
	var r0 := (0.036 if sex == "m" else 0.031) * H
	if sex == "boy":
		r0 = 0.03 * H
	var puffy := 0.006 * H if str(look.get("top", "")) in ["parka", "ski_jacket", "puffer"] else 0.0
	if str(look.get("top", "")) == "sweater":
		puffy = 0.003 * H
	var upper := capsule(sh, elbow, r0 + puffy, 0.025 * H + puffy, 0.004 * H, 0.0, 0.3)
	var fore := capsule(elbow, wrist, 0.025 * H + puffy, 0.019 * H + puffy * 0.6, 0.0, 0.004 * H, 0.25)
	if short_sleeve:
		fill(capsule(sh, elbow, r0 - 0.003 * H, 0.022 * H, 0.003 * H), skin, 0.06, 0.12)
		fill(fore, skin, 0.06, 0.12)
		var cap_end := sh.lerp(elbow, 0.55)
		fill(capsule(sh, cap_end, r0 + 0.002 * H, 0.027 * H), sleeve, 0.06, 0.12)
	else:
		fill(upper, sleeve, 0.08, 0.14)
		fill(fore, sleeve, 0.06, 0.16)
		if not flat:
			# A crease at the elbow and the cuff.
			var u := (wrist - elbow).normalized()
			var n := Vector2(u.y, -u.x)
			line(PackedVector2Array([elbow - n * 3.0, elbow + u * 3.0 + n * 1.0]), sleeve.darkened(0.35), 1.0)
			var cuff_a := wrist - u * 0.022 * H
			fill(capsule(cuff_a, wrist, 0.021 * H + puffy * 0.6, 0.02 * H + puffy * 0.6), sleeve.darkened(0.12), 0.04, 0.1)
	# The burned hand is the near one, unless that hand is holding the revolver.
	var gauze_far := str(pose.get("prop", "")).begins_with("revolver")
	var gauze := bool(look.get("gauze", false)) and far == gauze_far
	_hand(wrist, (wrist - elbow).normalized().rotated(-0.12), Color("e9e5da") if gauze else skin, gauze)
	var tape: Color = pose.get("tape", Color(0, 0, 0, 0))
	if not far and tape.a > 0.0 and not flat:
		var u2 := (wrist - elbow).normalized()
		var tp := wrist - u2 * 0.03 * H
		fill(capsule(tp - u2 * 0.008 * H, tp + u2 * 0.008 * H, 0.023 * H, 0.023 * H), tape, 0.12, 0.12)


func _hand(w: Vector2, d: Vector2, c: Color, gauze: bool) -> void:
	var n := Vector2(d.y, -d.x)
	var m := func(x: float, y: float) -> Vector2: return w + d * x * H + n * y * H
	var pts := PackedVector2Array([m.call(-0.004, 0.017), m.call(0.03, 0.02), m.call(0.062, 0.016), m.call(0.083, 0.007),
		m.call(0.084, -0.004), m.call(0.064, -0.013), m.call(0.032, -0.016), m.call(-0.004, -0.016)])
	fill(smooth(pts, 2), c, 0.06, 0.1)
	fill(capsule(m.call(0.02, 0.013), m.call(0.05, 0.028), 0.008 * H, 0.0065 * H), c, 0.04, 0.1)
	if flat:
		return
	line(PackedVector2Array([m.call(0.05, 0.004), m.call(0.078, 0.003)]), c.darkened(0.25), 1.0)
	if gauze:
		for k in 5:
			var x := 0.0 + k * 0.016
			line(PackedVector2Array([m.call(x, 0.018), m.call(x + 0.01, -0.017)]), Color("b9b3a4"), 1.0)


# --- torso and clothes ----------------------------------------------------------------

## The body's side profile in torso space: front points top to bottom, then
## back points bottom to top. Units of height; y = 0 at the hip joint.
func _profile(breath: float) -> Dictionary:
	var bust := float(look.get("bust", 0.5))
	var belly := float(look.get("belly", 0.0))
	var hips := float(look.get("hips", 0.5))
	var b := breath * 0.004
	var front: Array
	var back: Array
	if sex == "f":
		front = [Vector2(0.03, -0.3), Vector2(0.05, -0.289), Vector2(0.06, -0.27), Vector2(0.068 + 0.024 * bust + b, -0.236),
			Vector2(0.071 + 0.032 * bust + b, -0.212), Vector2(0.058 + 0.01 * bust, -0.186), Vector2(0.048 + 0.012 * belly, -0.15),
			Vector2(0.045 + 0.02 * belly, -0.118), Vector2(0.05 + 0.03 * belly, -0.08), Vector2(0.056 + 0.022 * belly, -0.04),
			Vector2(0.05, -0.004), Vector2(0.032, 0.034), Vector2(0.006, 0.06)]
		back = [Vector2(-0.044, 0.056), Vector2(-0.07 - 0.012 * hips, 0.03), Vector2(-0.08 - 0.02 * hips, 0.0),
			Vector2(-0.074 - 0.02 * hips, -0.036), Vector2(-0.058 - 0.012 * hips, -0.07), Vector2(-0.045, -0.106),
			Vector2(-0.047, -0.14), Vector2(-0.057, -0.184), Vector2(-0.066, -0.228), Vector2(-0.066, -0.262),
			Vector2(-0.054, -0.286), Vector2(-0.03, -0.3)]
	else:
		var k := 0.86 if sex == "boy" else 1.0
		front = [Vector2(0.035 * k, -0.3), Vector2(0.06 * k, -0.286), Vector2(0.074 * k, -0.262), Vector2(0.082 * k + b, -0.232),
			Vector2(0.081 * k + b, -0.2), Vector2(0.073 * k + 0.02 * belly, -0.165), Vector2(0.065 * k + 0.045 * belly, -0.12),
			Vector2(0.066 * k + 0.055 * belly, -0.076), Vector2(0.064 * k + 0.035 * belly, -0.036), Vector2(0.05 * k + 0.01 * belly, 0.0),
			Vector2(0.03, 0.034), Vector2(0.006, 0.058)]
		back = [Vector2(-0.044, 0.054), Vector2(-0.066 * k, 0.02), Vector2(-0.07 * k, -0.02), Vector2(-0.064 * k, -0.06),
			Vector2(-0.056 * k, -0.1), Vector2(-0.06 * k, -0.135), Vector2(-0.072 * k, -0.18), Vector2(-0.082 * k, -0.225),
			Vector2(-0.083 * k, -0.262), Vector2(-0.066 * k, -0.288), Vector2(-0.035 * k, -0.3)]
	if look.get("gaunt", false):
		for i in front.size():
			front[i].x *= 0.93
	var preg := float(look.get("pregnant", 0.0))
	if preg > 0.0 and sex == "f":
		# Six months along: a round bump from under the bust to the hips.
		for i in front.size():
			var y: float = front[i].y
			var k := clampf(1.0 - absf(y + 0.085) / 0.12, 0.0, 1.0)
			front[i].x += preg * 0.058 * sin(k * PI * 0.5)
	return {"front": front, "back": back}


## The coat, dress or shirt on the torso, down to its hem.
func _torso(pose: Dictionary) -> void:
	var prof := _profile(float(pose.get("breath", 0.0)))
	var top := str(look.get("top", "work_jacket"))
	var th: float = {"parka": 0.024, "ski_jacket": 0.016, "work_jacket": 0.011, "long_coat": 0.013, "robe": 0.012,
		"cardigan": 0.007, "flannel": 0.006, "uniform": 0.004, "dress": 0.003, "denim_jacket": 0.009,
		"sweatshirt": 0.008, "sweater": 0.013, "hoodie": 0.01, "puffer": 0.026}.get(top, 0.008)
	var hem: float = {"parka": 0.11, "ski_jacket": 0.03, "work_jacket": 0.05, "cardigan": 0.05, "flannel": 0.04,
		"uniform": -0.09, "long_coat": -0.1, "robe": -0.1, "dress": -0.1, "denim_jacket": 0.0, "sweatshirt": 0.04,
		"sweater": 0.07, "hoodie": 0.05, "puffer": 0.03}.get(top, 0.04)
	var pts: Array = []
	var last_f := Vector2.ZERO
	for p in prof.front:
		if p.y <= hem:
			pts.append(Vector2(p.x + th, p.y))
			last_f = p
	var flare := 0.012 if top == "parka" else 0.004
	pts.append(Vector2(last_f.x + th + flare, hem))
	var back_pts: Array = []
	var last_b := Vector2.ZERO
	for p in prof.back:
		if p.y <= hem:
			back_pts.append(Vector2(p.x - th, p.y))
			if last_b == Vector2.ZERO:
				last_b = p
	pts.append(Vector2((back_pts[0].x if back_pts.size() > 0 else -0.07) - flare, hem))
	pts.append_array(back_pts)
	var col: Color = look.top_col
	if top in ["uniform"]:
		# Tucked in: the trousers' seat shows below the belt.
		_seat(prof)
	var shape := smooth(_map_T(pts), 3)
	fill(shape, col, 0.1, 0.18)
	if flat:
		return
	_garment_detail(top, prof, th, hem, col, pose)
	if pose.get("stain", false):
		# The body: a dark stain spreading on the jacket. Nothing more.
		var st := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			st.append(_T(0.02, -0.17) + Vector2(cos(a), sin(a)) * (0.034 + 0.008 * sin(a * 3.0)) * H)
		ci.draw_colored_polygon(st, Color(0.22, 0.06, 0.05, 0.85))


## Trousers from the waist down to the hip joint, under a tucked-in shirt.
func _seat(prof: Dictionary) -> void:
	var pts: Array = []
	for p in prof.front:
		if p.y >= -0.11:
			pts.append(p)
	for p in prof.back:
		if p.y >= -0.11:
			pts.append(p)
	fill(smooth(_map_T(pts), 2), look.bottom_col, 0.04, 0.12)


func _garment_detail(top: String, prof: Dictionary, th: float, hem: float, col: Color, pose: Dictionary) -> void:
	var trim: Color = look.get("top_trim", col.darkened(0.3))
	var dark := col.darkened(0.32)
	match top:
		"work_jacket":
			# Shirt collar, jacket collar, the front placket and pockets.
			var shirt: Color = look.get("collar", Color("8a2f2a"))
			fill(smooth(_map_T([Vector2(0.02, -0.304), Vector2(0.052, -0.298), Vector2(0.05, -0.276), Vector2(0.026, -0.284)]), 2), shirt, 0.08, 0.1)
			fill(smooth(_map_T([Vector2(-0.05, -0.31), Vector2(0.0, -0.318), Vector2(0.046, -0.296), Vector2(0.062, -0.268),
				Vector2(0.03, -0.276), Vector2(-0.01, -0.29), Vector2(-0.058, -0.286)]), 2), trim, 0.1, 0.1)
			line(_map_T([Vector2(0.066, -0.262), Vector2(0.075, -0.2), Vector2(0.064, -0.13), Vector2(0.066, -0.02), Vector2(0.066, 0.045)]), dark, 1.2)
			for y in [-0.24, -0.19, -0.14, -0.09, -0.04]:
				ci.draw_circle(_T(0.06 if y > -0.2 else 0.07, y), 1.1, Color("b8ad8e"))
			fill(_map_T([Vector2(-0.01, -0.235), Vector2(0.04, -0.235), Vector2(0.04, -0.19), Vector2(-0.01, -0.19)]), col.darkened(0.08), 0.06, 0.08)
			line(_map_T([Vector2(-0.012, -0.235), Vector2(0.042, -0.235)]), col.lightened(0.2), 1.4)
			fill(_map_T([Vector2(-0.03, -0.03), Vector2(0.035, -0.03), Vector2(0.035, 0.03), Vector2(-0.03, 0.03)]), col.darkened(0.1), 0.04, 0.08)
			line(_map_T([Vector2(-0.072, -0.25), Vector2(-0.06, -0.12), Vector2(-0.07, 0.04)]), dark, 1.0)
			if look.get("toolbelt", false):
				fill(_map_T([Vector2(-0.092, -0.008), Vector2(0.074, -0.008), Vector2(0.074, 0.018), Vector2(-0.092, 0.018)]), Color("4b3524"), 0.08, 0.1)
				fill(_map_T([Vector2(-0.07, 0.01), Vector2(-0.025, 0.01), Vector2(-0.028, 0.075), Vector2(-0.066, 0.075)]), Color("5c4330"), 0.08, 0.12)
				ci.draw_circle(_T(0.005, 0.005), 0.004 * H, Color("c2b48a"))
				# Her roll of tape, clipped to the belt.
				var tape: Color = pose.get("tape", Color(0, 0, 0, 0))
				var roll := tape if tape.a > 0.0 else Color("c8322a")
				ci.draw_circle(_T(0.035, 0.04), 0.017 * H, roll.darkened(0.1))
				ci.draw_circle(_T(0.035, 0.04), 0.008 * H, Color("2a2420"))
		"ski_jacket":
			fill(smooth(_map_T([Vector2(-0.05, -0.31), Vector2(0.044, -0.31), Vector2(0.06, -0.27), Vector2(-0.06, -0.278)]), 2), col.darkened(0.12), 0.06, 0.08)
			fill(_map_T([Vector2(-0.085, -0.214), Vector2(0.095, -0.214), Vector2(0.094, -0.19), Vector2(-0.085, -0.19)]), trim, 0.06, 0.08)
			line(_map_T([Vector2(0.074, -0.27), Vector2(0.09, -0.2), Vector2(0.07, -0.08), Vector2(0.066, 0.03)]), dark, 1.2)
			for y in [-0.14, -0.08, -0.02]:
				line(_map_T([Vector2(-0.07, y), Vector2(0.06, y + 0.004)]), dark, 1.0)
		"parka":
			# Quilting, the zip, a pocket, and the hood's fur ruff around the neck.
			for y in [-0.24, -0.18, -0.12, -0.06, 0.0, 0.06]:
				line(_map_T([Vector2(-0.085, y), Vector2(0.0, y + 0.006), Vector2(0.075, y)]), dark, 1.0)
			line(_map_T([Vector2(0.07, -0.27), Vector2(0.088, -0.2), Vector2(0.08, -0.08), Vector2(0.08, 0.1)]), col.darkened(0.45), 1.4)
			fill(_map_T([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.06, 0.06), Vector2(0.0, 0.06)]), col.darkened(0.12), 0.04, 0.06)
			var ruff := PackedVector2Array()
			for i in 13:
				var a := PI * 1.05 + PI * 1.05 * i / 12.0
				var r := 0.046 + (0.008 if i % 2 == 0 else 0.0)
				ruff.append(_T(-0.012 + cos(a) * r, -0.292 + sin(a) * r * 0.7))
			ruff.append(_T(-0.02, -0.27))
			fill(smooth(ruff, 1), trim, 0.1, 0.12)
			if pose.get("buttoned", false):
				# Done up to the top: the storm flap closed over the throat, its button showing.
				fill(_map_T([Vector2(0.036, -0.302), Vector2(0.084, -0.296), Vector2(0.086, -0.262), Vector2(0.04, -0.266)]), col.darkened(0.08), 0.04, 0.08)
				ci.draw_circle(_T(0.066, -0.282), 0.0085 * H, Color("e2d6bc"))
				ci.draw_circle(_T(0.066, -0.282), 0.004 * H, Color("8a7a5a"))
			else:
				# Left open at the neck, the way he always wears it: a T-shirt in the V.
				fill(_map_T([Vector2(0.046, -0.304), Vector2(0.08, -0.298), Vector2(0.066, -0.262)]), Color("d9d6cc"), 0.03, 0.08)
				line(_map_T([Vector2(0.044, -0.302), Vector2(0.066, -0.258), Vector2(0.082, -0.296)]), col.darkened(0.4), 1.2)
		"long_coat":
			fill(smooth(_map_T([Vector2(-0.06, -0.33), Vector2(0.01, -0.336), Vector2(0.05, -0.31), Vector2(0.075, -0.24),
				Vector2(0.05, -0.25), Vector2(0.022, -0.284), Vector2(-0.062, -0.29)]), 2), trim, 0.08, 0.1)
			line(_map_T([Vector2(0.075, -0.24), Vector2(0.074, -0.1)]), dark, 1.2)
			for y in [-0.2, -0.15]:
				ci.draw_circle(_T(0.068, y), 1.3, Color("4a4a48"))
			fill(_map_T([Vector2(-0.085, -0.12), Vector2(0.075, -0.12), Vector2(0.075, -0.098), Vector2(-0.085, -0.098)]), col.darkened(0.15), 0.04, 0.06)
		"robe":
			fill(smooth(_map_T([Vector2(-0.05, -0.31), Vector2(0.03, -0.31), Vector2(0.07, -0.26), Vector2(0.075, -0.16),
				Vector2(0.06, -0.16), Vector2(0.052, -0.25), Vector2(0.02, -0.29), Vector2(-0.05, -0.29)]), 2), trim, 0.06, 0.08)
			for x in [-0.07, -0.04, -0.01, 0.02, 0.05]:
				line(_map_T([Vector2(x, -0.29), Vector2(x, -0.1)]), dark, 1.0)
			for y in [-0.25, -0.2, -0.15]:
				line(_map_T([Vector2(-0.085, y), Vector2(0.07, y)]), dark, 1.0)
			fill(_map_T([Vector2(-0.09, -0.12), Vector2(0.085, -0.12), Vector2(0.085, -0.1), Vector2(-0.09, -0.1)]), trim, 0.04, 0.06)
			fill(smooth(_map_T([Vector2(0.07, -0.1), Vector2(0.09, -0.06), Vector2(0.078, -0.02), Vector2(0.068, -0.06)]), 2), trim, 0.04, 0.06)
		"cardigan":
			# A white blouse collar in the V, buttons down the front.
			fill(smooth(_map_T([Vector2(0.02, -0.305), Vector2(0.06, -0.298), Vector2(0.074, -0.27), Vector2(0.05, -0.276)]), 2), trim, 0.04, 0.06)
			fill(_map_T([Vector2(0.048, -0.29), Vector2(0.076, -0.27), Vector2(0.08, -0.2), Vector2(0.06, -0.2)]), trim, 0.04, 0.06)
			for y in [-0.18, -0.13, -0.08, -0.03]:
				ci.draw_circle(_T(0.072 - 0.004 * y, y), 1.2, col.darkened(0.45))
			for y in [-0.02, 0.0, 0.02, 0.04]:
				line(_map_T([Vector2(-0.08, y), Vector2(0.07, y)]), col.darkened(0.18), 1.0)
		"flannel":
			for x in [-0.06, -0.03, 0.0, 0.03, 0.06]:
				line(_map_T([Vector2(x, -0.29), Vector2(x, hem)]), col.darkened(0.35), 1.6)
			for y in [-0.25, -0.2, -0.15, -0.1, -0.05, 0.0]:
				line(_map_T([Vector2(-0.085, y), Vector2(0.085, y)]), col.darkened(0.3), 1.2)
			fill(smooth(_map_T([Vector2(0.0, -0.31), Vector2(0.05, -0.302), Vector2(0.06, -0.28), Vector2(0.025, -0.285)]), 2), col.lightened(0.08), 0.04, 0.06)
		"uniform":
			fill(smooth(_map_T([Vector2(0.0, -0.31), Vector2(0.05, -0.302), Vector2(0.064, -0.278), Vector2(0.03, -0.284)]), 2), col.lightened(0.06), 0.04, 0.06)
			fill(_map_T([Vector2(-0.06, -0.272), Vector2(-0.01, -0.276), Vector2(-0.01, -0.262), Vector2(-0.06, -0.26)]), trim, 0.04, 0.06)
			fill(_map_T([Vector2(0.01, -0.235), Vector2(0.058, -0.235), Vector2(0.058, -0.195), Vector2(0.01, -0.195)]), col.darkened(0.08), 0.04, 0.06)
			# The badge.
			var bc := _T(0.04, -0.215)
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + TAU * i / 10.0
				star.append(bc + Vector2(cos(a), sin(a)) * (0.016 * H if i % 2 == 0 else 0.007 * H))
			fill(star, Color("d4b04a"), 0.12, 0.1, false)
			fill(_map_T([Vector2(-0.07, -0.104), Vector2(0.075, -0.104), Vector2(0.075, -0.088), Vector2(-0.07, -0.088)]), Color("2a1e14"), 0.04, 0.06)
		"dress":
			fill(smooth(_map_T([Vector2(-0.02, -0.31), Vector2(0.044, -0.3), Vector2(0.062, -0.276), Vector2(0.03, -0.27),
				Vector2(-0.03, -0.29)]), 2), trim, 0.04, 0.06)
			for y in [-0.25, -0.2, -0.15]:
				ci.draw_circle(_T(0.064 + (0.01 if y > -0.22 else 0.0), y), 1.1, trim.darkened(0.2))
		"denim_jacket":
			# 1991: a T-shirt at the neck, the jean jacket's collar and button
			# front, a flapped chest pocket, orange stitching, the waistband.
			var tee: Color = look.get("tee", Color("e8e4dc"))
			fill(_map_T([Vector2(0.03, -0.306), Vector2(0.066, -0.298), Vector2(0.07, -0.262), Vector2(0.04, -0.27)]), tee, 0.03, 0.06)
			fill(smooth(_map_T([Vector2(-0.056, -0.316), Vector2(0.0, -0.322), Vector2(0.044, -0.3), Vector2(0.06, -0.266),
				Vector2(0.03, -0.276), Vector2(-0.01, -0.292), Vector2(-0.06, -0.29)]), 2), col.darkened(0.12), 0.08, 0.1)
			var stitch := Color("d8a05a")
			line(_map_T([Vector2(0.068, -0.262), Vector2(0.074, -0.2), Vector2(0.07, -0.1), Vector2(0.068, -0.004)]), dark, 1.2)
			for y in [-0.23, -0.17, -0.11, -0.05]:
				ci.draw_circle(_T(0.066, y), 1.3, Color("c8b890"))
			fill(_map_T([Vector2(0.0, -0.238), Vector2(0.05, -0.238), Vector2(0.05, -0.214), Vector2(0.0, -0.214)]), col.darkened(0.15), 0.04, 0.06)
			line(_map_T([Vector2(-0.002, -0.242), Vector2(0.052, -0.242)]), stitch, 1.0)
			fill(_map_T([Vector2(-0.08, -0.03), Vector2(0.074, -0.03), Vector2(0.074, 0.0), Vector2(-0.08, 0.0)]), col.darkened(0.08), 0.04, 0.06)
			line(_map_T([Vector2(-0.08, -0.03), Vector2(0.074, -0.03)]), stitch, 1.0)
			line(_map_T([Vector2(-0.07, -0.26), Vector2(-0.062, -0.12), Vector2(-0.07, -0.03)]), stitch, 1.0)
		"sweatshirt":
			# A crew neck, ribbed cuffs and hem.
			fill(smooth(_map_T([Vector2(-0.05, -0.31), Vector2(0.0, -0.318), Vector2(0.046, -0.304), Vector2(0.058, -0.286),
				Vector2(0.04, -0.29), Vector2(-0.052, -0.294)]), 2), col.darkened(0.14), 0.04, 0.08)
			fill(_map_T([Vector2(-0.082, 0.012), Vector2(0.072, 0.012), Vector2(0.072, 0.04), Vector2(-0.082, 0.04)]), col.darkened(0.14), 0.04, 0.06)
			for x in [-0.07, -0.05, -0.03, -0.01, 0.01, 0.03, 0.05]:
				line(_map_T([Vector2(x, 0.014), Vector2(x, 0.038)]), col.darkened(0.3), 1.0)
			line(_map_T([Vector2(0.06, -0.25), Vector2(0.066, -0.15), Vector2(0.058, -0.04)]), col.darkened(0.2), 1.0)
		"sweater":
			# An oversized knit with a band of zigzags across the chest and cables down the front.
			var band: Color = col.lerp(look.get("top_trim", col.darkened(0.3)), 0.6)
			fill(smooth(_map_T([Vector2(-0.056, -0.32), Vector2(0.0, -0.33), Vector2(0.05, -0.312), Vector2(0.064, -0.29),
				Vector2(0.044, -0.296), Vector2(-0.058, -0.3)]), 2), col.darkened(0.1), 0.04, 0.08)
			var zz := PackedVector2Array()
			for i in 13:
				zz.append(_T(-0.088 + i * 0.0135, -0.236 + (0.008 if i % 2 == 0 else -0.002)))
			ci.draw_polyline(zz, band, 1.6, true)
			line(_map_T([Vector2(-0.09, -0.252), Vector2(0.074, -0.252)]), band, 1.2)
			for x in [-0.04, 0.02]:
				var cable := PackedVector2Array()
				for i in 9:
					cable.append(_T(x + sin(i * 1.4) * 0.008, -0.17 + i * 0.026))
				ci.draw_polyline(cable, col.darkened(0.2), 1.2, true)
			fill(_map_T([Vector2(-0.088, 0.04), Vector2(0.076, 0.04), Vector2(0.074, 0.07), Vector2(-0.088, 0.07)]), col.darkened(0.12), 0.04, 0.06)
		"hoodie":
			# The hood bunched behind the neck, drawstrings, the front pocket.
			fill(smooth(_map_T([Vector2(-0.1, -0.32), Vector2(-0.06, -0.352), Vector2(0.0, -0.346), Vector2(0.03, -0.32),
				Vector2(-0.02, -0.3), Vector2(-0.09, -0.29)]), 2), col.darkened(0.08), 0.06, 0.1)
			var cord: Color = look.get("top_trim", Color("e8e4dc"))
			line(_map_T([Vector2(0.05, -0.3), Vector2(0.058, -0.25)]), cord, 1.4)
			line(_map_T([Vector2(0.042, -0.3), Vector2(0.046, -0.24)]), cord.darkened(0.15), 1.4)
			fill(_map_T([Vector2(-0.02, -0.08), Vector2(0.07, -0.08), Vector2(0.074, 0.0), Vector2(-0.02, 0.0)]), col.darkened(0.1), 0.04, 0.06)
			line(_map_T([Vector2(0.07, -0.08), Vector2(0.074, 0.0)]), col.darkened(0.3), 1.0)
			fill(_map_T([Vector2(-0.082, 0.02), Vector2(0.074, 0.02), Vector2(0.074, 0.05), Vector2(-0.082, 0.05)]), col.darkened(0.12), 0.04, 0.06)
		"puffer":
			# Quilted baffles, each with its own sheen, and a stand-up collar.
			for i in 7:
				var y := -0.27 + i * 0.044
				line(_map_T([Vector2(-0.1, y), Vector2(-0.01, y + 0.004), Vector2(0.09, y)]), dark, 1.2)
				line(_map_T([Vector2(-0.06, y - 0.024), Vector2(0.05, y - 0.022)]), col.lightened(0.22), 1.6)
			fill(smooth(_map_T([Vector2(-0.06, -0.33), Vector2(0.0, -0.336), Vector2(0.052, -0.32), Vector2(0.06, -0.29),
				Vector2(0.0, -0.3), Vector2(-0.064, -0.296)]), 2), col.darkened(0.06), 0.06, 0.08)
			line(_map_T([Vector2(0.08, -0.29), Vector2(0.092, -0.2), Vector2(0.088, -0.08), Vector2(0.086, 0.03)]), col.darkened(0.45), 1.4)
	var apron: Color = look.get("apron", Color(0, 0, 0, 0))
	if apron.a > 0.0:
		fill(smooth(_map_T([Vector2(0.03, -0.235), Vector2(0.074, -0.24), Vector2(0.084, -0.2), Vector2(0.07, -0.12),
			Vector2(0.03, -0.12)]), 2), apron, 0.04, 0.08)
		line(_map_T([Vector2(0.034, -0.236), Vector2(-0.01, -0.3)]), apron.darkened(0.08), 2.0)
		fill(smooth(_map_T([Vector2(-0.07, -0.118), Vector2(-0.1, -0.1), Vector2(-0.098, -0.082), Vector2(-0.072, -0.1)]), 2), apron, 0.04, 0.06)
	if look.get("patched", false):
		# Years of wear: patches sewn over the holes, in whatever was to hand.
		var pc := col.lerp(Color("6a5a3a"), 0.55)
		for p: Vector2 in [Vector2(-0.05, -0.2), Vector2(0.025, -0.07), Vector2(-0.035, 0.05)]:
			fill(_map_T([p + Vector2(-0.02, -0.018), p + Vector2(0.022, -0.02), p + Vector2(0.02, 0.02), p + Vector2(-0.021, 0.017)]), pc, 0.04, 0.06)
			for k in 4:
				var q := p + Vector2(-0.02 + k * 0.013, -0.019)
				line(_map_T([q, q + Vector2(0.004, 0.006)]), pc.lightened(0.35), 1.0)
	if look.get("paint", false):
		# Flecks of yellow: he's been trying out the nursery colour.
		for i in 10:
			var p := Vector2(-0.07 + Townscape.h(i * 7 + 3) * 0.14, -0.26 + Townscape.h(i * 11 + 5) * 0.28)
			ci.draw_circle(_T(p.x, p.y), 0.0028 * H + 0.002 * H * Townscape.h(i), Color("f2d24a"))
	if look.get("badge", false):
		# A volunteer's lanyard and name badge.
		var lan: Color = look.get("badge_col", Color("2a5a8a"))
		line(_map_T([Vector2(-0.02, -0.3), Vector2(0.03, -0.22), Vector2(0.05, -0.165)]), lan, 2.0)
		line(_map_T([Vector2(0.03, -0.302), Vector2(0.058, -0.24), Vector2(0.058, -0.165)]), lan.darkened(0.2), 2.0)
		fill(_map_T([Vector2(0.03, -0.166), Vector2(0.078, -0.166), Vector2(0.078, -0.106), Vector2(0.03, -0.106)]), Color("f2f0ea"), 0.02, 0.06)
		fill(_map_T([Vector2(0.03, -0.166), Vector2(0.078, -0.166), Vector2(0.078, -0.15), Vector2(0.03, -0.15)]), lan, 0.02, 0.04, false)
		line(_map_T([Vector2(0.038, -0.134), Vector2(0.07, -0.134)]), Color("4a4a4a"), 1.0)
		line(_map_T([Vector2(0.038, -0.122), Vector2(0.062, -0.122)]), Color("8a8a8a"), 1.0)
	var sr: Color = pose.get("strap_radio", Color(0, 0, 0, 0))
	if sr.a > 0.0:
		# Somebody else's field radio, slung on a strap: a strip of tape on its handle.
		line(_map_T([Vector2(-0.05, -0.29), Vector2(0.0, -0.18), Vector2(0.06, -0.05)]), Color("2a2620"), 2.4)
		fill(_map_T([Vector2(0.0, -0.045), Vector2(0.092, -0.045), Vector2(0.092, 0.03), Vector2(0.0, 0.03)]), Color("4a5a3a"), 0.1, 0.14)
		fill(_map_T([Vector2(0.008, -0.036), Vector2(0.048, -0.036), Vector2(0.048, -0.014), Vector2(0.008, -0.014)]), Color("c8c39f"), 0.02, 0.04, false)
		ci.draw_circle(_T(0.07, -0.004), 0.009 * H, Color("1e2420"))
		fill(_map_T([Vector2(0.02, -0.058), Vector2(0.072, -0.058), Vector2(0.072, -0.045), Vector2(0.02, -0.045)]), sr, 0.04, 0.04, false)


## Skirts, dresses, nightgowns and the long coats' skirts: they hang from
## the waist past the knees and follow the legs.
func _lower_garment(knees: Array, pose: Dictionary) -> void:
	var top := str(look.get("top", ""))
	var bottom := str(look.get("bottom", ""))
	var layers: Array = []
	if bottom in ["skirt", "dress", "nightgown"]:
		layers.append([look.bottom_col, float(look.get("skirt_len", 0.32))])
	if top in ["long_coat", "robe"]:
		layers.append([look.top_col, 0.27 if top == "long_coat" else 0.24])
	if layers.is_empty():
		return
	# A nightgown under a coat hangs lower: draw longest first.
	layers.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	for layer in layers:
		var c: Color = layer[0]
		var length: float = layer[1]
		var seated: bool = pose.get("seated", false)
		var waist_f := _T(0.06, -0.11)
		var waist_b := _T(-0.075, -0.11)
		var pts := PackedVector2Array([waist_f, waist_b, _T(-0.095, -0.02), _T(-0.09, 0.04)])
		var r := 0.045 * H
		var flare := 0.03 * H
		for k in knees:
			var kp: Vector2 = k
			if seated:
				pts.append(kp + Vector2(r, -r * 0.8))
				pts.append(kp + Vector2(r * 1.1, length * H * 0.35))
				pts.append(kp + Vector2(-r * 0.5, length * H * 0.35))
			else:
				var hem_y := maxf(_hip.y + length * H, kp.y + 0.02 * H)
				pts.append(kp + Vector2(r, 0))
				pts.append(Vector2(kp.x + r + flare * 0.5, hem_y))
				pts.append(Vector2(kp.x - r - flare, hem_y))
		var hull := Geometry2D.convex_hull(pts)
		if hull.size() > 1:
			hull.remove_at(hull.size() - 1)
		fill(hull, c, 0.06, 0.18)
		if flat:
			continue
		# Folds, and the pattern.
		var bottom_y := -INF
		for p in hull:
			bottom_y = maxf(bottom_y, p.y)
		for i in 3:
			var x := lerpf(waist_b.x, waist_f.x, 0.25 + 0.25 * i)
			line(PackedVector2Array([Vector2(x, waist_f.y + 0.06 * H), Vector2(x + (i - 1) * 3.0, bottom_y - 3.0)]), c.darkened(0.2), 1.0)
		if look.get("plaid", false) and c == look.bottom_col:
			for k in 4:
				var y := lerpf(waist_f.y + 6.0, bottom_y - 4.0, k / 3.0)
				line(PackedVector2Array([Vector2(waist_b.x - 6.0, y), Vector2(waist_f.x + 8.0, y)]), c.lightened(0.18), 1.4)
		if look.has("apron") and c == look.bottom_col:
			var ap := PackedVector2Array([waist_f + Vector2(-0.04 * H, 0), waist_f + Vector2(0.006 * H, 0),
				Vector2(waist_f.x + 0.02 * H, bottom_y - 0.05 * H), Vector2(waist_f.x - 0.05 * H, bottom_y - 0.06 * H)])
			fill(ap, look.apron, 0.04, 0.08)


func _neck(base: Vector2) -> void:
	var r := (0.035 if sex == "m" else 0.027) * H
	if sex == "boy":
		r = 0.026 * H
	var top := _HP(-0.06, 0.3)
	fill(capsule(base, top, r, r * 0.92), _skin().darkened(0.12), 0.0, 0.1, false)
	if not flat and sex == "m":
		line(PackedVector2Array([_HP(0.22, 0.42), _HP(0.2, 0.56)]), _skin().darkened(0.3), 1.0)
	if not flat and float(look.get("age", 30)) >= 75.0:
		# Loose skin under the jaw.
		line(PackedVector2Array([_HP(0.2, 0.46), _HP(0.13, 0.54), _HP(0.1, 0.62)]), _skin().darkened(0.3), 1.0)
		line(PackedVector2Array([_HP(0.14, 0.47), _HP(0.06, 0.58)]), _skin().darkened(0.24), 1.0)


# --- the head ------------------------------------------------------------------------

const HEAD_F := [Vector2(-0.04, -0.57), Vector2(0.2, -0.5), Vector2(0.35, -0.36), Vector2(0.41, -0.19), Vector2(0.395, -0.115),
	Vector2(0.462, 0.012), Vector2(0.452, 0.058), Vector2(0.395, 0.078), Vector2(0.415, 0.15), Vector2(0.39, 0.19),
	Vector2(0.405, 0.228), Vector2(0.36, 0.29), Vector2(0.368, 0.355), Vector2(0.3, 0.435), Vector2(0.12, 0.43),
	Vector2(-0.04, 0.335), Vector2(-0.2, 0.22), Vector2(-0.38, 0.12), Vector2(-0.48, -0.1), Vector2(-0.39, -0.4)]
const HEAD_M := [Vector2(-0.04, -0.57), Vector2(0.2, -0.5), Vector2(0.36, -0.36), Vector2(0.44, -0.19), Vector2(0.405, -0.11),
	Vector2(0.5, 0.02), Vector2(0.49, 0.064), Vector2(0.405, 0.085), Vector2(0.42, 0.15), Vector2(0.395, 0.19),
	Vector2(0.405, 0.226), Vector2(0.37, 0.28), Vector2(0.39, 0.345), Vector2(0.35, 0.445), Vector2(0.13, 0.45),
	Vector2(-0.02, 0.4), Vector2(-0.18, 0.24), Vector2(-0.38, 0.12), Vector2(-0.49, -0.1), Vector2(-0.4, -0.41)]
const HEAD_BOY := [Vector2(-0.06, -0.6), Vector2(0.2, -0.53), Vector2(0.37, -0.36), Vector2(0.4, -0.18), Vector2(0.385, -0.11),
	Vector2(0.44, 0.02), Vector2(0.43, 0.06), Vector2(0.385, 0.08), Vector2(0.4, 0.15), Vector2(0.375, 0.19),
	Vector2(0.385, 0.225), Vector2(0.34, 0.285), Vector2(0.34, 0.34), Vector2(0.26, 0.41), Vector2(0.1, 0.4),
	Vector2(-0.06, 0.31), Vector2(-0.2, 0.22), Vector2(-0.4, 0.12), Vector2(-0.52, -0.12), Vector2(-0.42, -0.44)]


func _head(pose: Dictionary) -> void:
	var shape: Array = HEAD_F
	if sex == "m":
		shape = HEAD_M
	elif sex == "boy":
		shape = HEAD_BOY
	var nose := str(look.get("nose", "straight"))
	shape = shape.duplicate()
	if nose == "aquiline":
		shape[4] = shape[4] + Vector2(0.03, -0.01)
		shape[5] = shape[5] + Vector2(0.02, 0.01)
	elif nose == "button":
		shape[5] = shape[5] + Vector2(-0.02, -0.01)
	elif nose == "broad":
		shape[6] = shape[6] + Vector2(0.01, 0.02)
	var skin := _skin()
	var head := smooth(_map_H(shape), 3)
	fill(head, skin, 0.06, 0.12)
	if flat:
		_hair_front()
		return
	# Ear.
	var ear := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		ear.append(_HP(-0.07 + cos(a) * 0.085, 0.03 + sin(a) * 0.13))
	fill(ear, skin.darkened(0.06), 0.04, 0.1)
	line(PackedVector2Array([_HP(-0.05, -0.05), _HP(-0.11, 0.0), _HP(-0.1, 0.08), _HP(-0.05, 0.11)]), skin.darkened(0.3), 1.0)
	var lines := float(look.get("lines", 0.0))
	var fem := sex == "f"
	# Cheek colour.
	if fem or sex == "boy":
		ci.draw_circle(_HP(0.2, 0.12), 0.1 * _s, Color(0.85, 0.42, 0.4, 0.12))
	# Beard / moustache.
	var beard := str(look.get("beard", ""))
	var hair: Color = look.get("beard_col", look.hair)
	if beard == "full":
		fill(smooth(_map_H([Vector2(-0.02, 0.06), Vector2(0.12, 0.17), Vector2(0.3, 0.21), Vector2(0.41, 0.25), Vector2(0.43, 0.34),
			Vector2(0.37, 0.5), Vector2(0.2, 0.55), Vector2(0.04, 0.48), Vector2(-0.08, 0.34), Vector2(-0.1, 0.16)]), 2), hair.darkened(0.05), 0.06, 0.1)
	elif beard == "trim":
		# Kept short and neat along the jaw: the modern kind.
		fill(smooth(_map_H([Vector2(-0.04, 0.1), Vector2(0.12, 0.2), Vector2(0.3, 0.22), Vector2(0.4, 0.26), Vector2(0.41, 0.33),
			Vector2(0.35, 0.45), Vector2(0.2, 0.48), Vector2(0.06, 0.44), Vector2(-0.06, 0.32), Vector2(-0.08, 0.18)]), 2), hair.darkened(0.08), 0.04, 0.08)
	elif beard == "scruff":
		# Years of not bothering: ragged at the edges, grey coming through.
		var ragged: Array = []
		var outline := [Vector2(-0.04, 0.04), Vector2(0.12, 0.16), Vector2(0.3, 0.2), Vector2(0.42, 0.24), Vector2(0.45, 0.36),
			Vector2(0.4, 0.56), Vector2(0.26, 0.66), Vector2(0.08, 0.6), Vector2(-0.06, 0.44), Vector2(-0.12, 0.2)]
		for i in outline.size():
			ragged.append(outline[i])
			var nxt: Vector2 = outline[(i + 1) % outline.size()]
			if i >= 3 and i <= 7:
				var mid: Vector2 = (outline[i] + nxt) * 0.5
				ragged.append(mid + (mid - Vector2(0.18, 0.3)).normalized() * 0.05)
		fill(smooth(_map_H(ragged), 1), hair.darkened(0.04), 0.06, 0.1)
		var grey: Color = look.get("hair_hi", hair.lightened(0.4))
		for k in 5:
			line(_map_H([Vector2(0.1 + k * 0.06, 0.3 + k * 0.02), Vector2(0.06 + k * 0.06, 0.56 - k * 0.02)]), grey, 1.0)
	elif beard == "stubble":
		# A day or two's shadow along the jaw and over the lip.
		ci.draw_colored_polygon(smooth(_map_H([Vector2(-0.02, 0.12), Vector2(0.14, 0.2), Vector2(0.32, 0.22), Vector2(0.41, 0.27),
			Vector2(0.4, 0.4), Vector2(0.3, 0.44), Vector2(0.12, 0.44), Vector2(-0.04, 0.34)]), 2), Color(hair.darkened(0.2), 0.22))
		ci.draw_colored_polygon(smooth(_map_H([Vector2(0.32, 0.12), Vector2(0.43, 0.11), Vector2(0.44, 0.15), Vector2(0.34, 0.16)]), 1),
			Color(hair.darkened(0.2), 0.2))
	if beard in ["full", "moustache", "trim", "scruff"]:
		fill(smooth(_map_H([Vector2(0.3, 0.11), Vector2(0.44, 0.105), Vector2(0.46, 0.15), Vector2(0.41, 0.18), Vector2(0.33, 0.17)]), 2),
			hair.darkened(0.1), 0.06, 0.08, false)
	# Mouth and lips.
	var lips: Color = look.get("lips", skin.darkened(0.22))
	if fem or sex == "boy":
		fill(smooth(_map_H([Vector2(0.38, 0.135), Vector2(0.418, 0.152), Vector2(0.4, 0.188), Vector2(0.36, 0.19)]), 2), lips, 0.06, 0.06, false)
		fill(smooth(_map_H([Vector2(0.36, 0.195), Vector2(0.402, 0.196), Vector2(0.405, 0.226), Vector2(0.37, 0.238)]), 2), lips.lightened(0.05), 0.06, 0.06, false)
	if beard in ["", "stubble"]:
		line(PackedVector2Array([_HP(0.398, 0.19), _HP(0.33, 0.193)]), skin.darkened(0.45), 1.0)
	# Nostril.
	line(PackedVector2Array([_HP(0.405, 0.06), _HP(0.43, 0.065), _HP(0.44, 0.045)]), skin.darkened(0.4), 1.0)
	# Eye: white, iris, lid, lashes; a blink now and then.
	var blink: bool = pose.get("blink", false)
	if blink:
		line(PackedVector2Array([_HP(0.25, -0.07), _HP(0.31, -0.058), _HP(0.385, -0.07)]), Color(0.18, 0.12, 0.1), 1.4)
	else:
		fill(smooth(_map_H([Vector2(0.255, -0.07), Vector2(0.33, -0.105), Vector2(0.385, -0.08), Vector2(0.34, -0.048)]), 2),
			Color("f2ece2"), 0.0, 0.04, false)
		var eye_c := _HP(0.335, -0.075)
		ci.draw_circle(eye_c, (0.05 if sex == "boy" else 0.042) * _s, look.get("eyes", Color("3b2a1e")))
		ci.draw_circle(eye_c + Vector2(0.006 * _s, 0).rotated(_ha), 0.022 * _s, Color(0.05, 0.04, 0.04))
		ci.draw_circle(eye_c + Vector2(0.015 * _s, -0.018 * _s).rotated(_ha), 0.009 * _s, Color(1, 1, 1, 0.8))
		line(PackedVector2Array([_HP(0.245, -0.075), _HP(0.32, -0.112), _HP(0.39, -0.08)]), Color(0.16, 0.1, 0.08), 1.5)
		if fem:
			line(PackedVector2Array([_HP(0.375, -0.09), _HP(0.42, -0.115)]), Color(0.12, 0.08, 0.06), 1.0)
			line(PackedVector2Array([_HP(0.355, -0.1), _HP(0.39, -0.13)]), Color(0.12, 0.08, 0.06), 1.0)
		line(PackedVector2Array([_HP(0.27, -0.045), _HP(0.35, -0.04)]), skin.darkened(0.2), 1.0)
	# Brow.
	var brow_w := (0.075 if sex == "m" else 0.05) * _s
	var brow_c: Color = hair.darkened(0.15) if hair.v < 0.6 else hair.darkened(0.35)
	line(PackedVector2Array([_HP(0.21, -0.185), _HP(0.31, -0.215 if fem else -0.2), _HP(0.415, -0.18)]), brow_c, maxf(1.2, brow_w))
	# Age.
	if lines > 0.0:
		var lc := Color(skin.darkened(0.42), 0.25 + 0.45 * lines)
		line(PackedVector2Array([_HP(0.24, -0.06), _HP(0.2, -0.04)]), lc, 1.0)
		line(PackedVector2Array([_HP(0.24, -0.04), _HP(0.21, -0.01)]), lc, 1.0)
		line(PackedVector2Array([_HP(0.37, 0.085), _HP(0.335, 0.15), _HP(0.335, 0.215)]), lc, 1.0)
		if lines > 0.5:
			line(PackedVector2Array([_HP(0.16, -0.34), _HP(0.32, -0.33)]), lc, 1.0)
			line(PackedVector2Array([_HP(0.06, 0.38), _HP(0.2, 0.47)]), lc, 1.0)
		if lines > 0.75:
			# The later decades: a second line across the forehead, crow's feet,
			# a bag under the eye, the lines from the mouth to the jaw, a jowl.
			line(PackedVector2Array([_HP(0.19, -0.285), _HP(0.3, -0.275)]), lc, 1.0)
			line(PackedVector2Array([_HP(0.245, -0.085), _HP(0.2, -0.075)]), lc, 1.0)
			line(PackedVector2Array([_HP(0.265, -0.03), _HP(0.3, -0.012), _HP(0.35, -0.022)]), lc, 1.0)
			line(PackedVector2Array([_HP(0.335, 0.225), _HP(0.322, 0.29), _HP(0.3, 0.34)]), lc, 1.0)
			line(PackedVector2Array([_HP(0.27, 0.37), _HP(0.17, 0.41), _HP(0.06, 0.39)]), lc, 1.2)
			# The cheek has fallen a little: a soft shadow under the bone.
			ci.draw_circle(_HP(0.2, 0.2), 0.11 * _s, Color(skin.darkened(0.3), 0.12))
		if float(look.get("age", 30)) >= 75.0:
			# Age spots at the temple and on the cheek.
			for p in [Vector2(0.06, -0.22), Vector2(0.12, -0.15), Vector2(0.02, -0.12), Vector2(0.16, 0.06)]:
				ci.draw_circle(_HP(p.x, p.y), 0.024 * _s, Color(skin.darkened(0.3), 0.32))
	elif float(look.get("age", 30)) < 30.0 and sex != "boy":
		# Young: a little more colour in the face.
		ci.draw_circle(_HP(0.22, 0.1), 0.09 * _s, Color(0.88, 0.45, 0.42, 0.08))
	_hair_front()
	if look.get("glasses", false):
		var gc := Color("3a3a3c")
		var lens := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			lens.append(_HP(0.345 + cos(a) * 0.085, -0.065 + sin(a) * 0.068))
		lens.append(lens[0])
		ci.draw_polyline(lens, gc, 1.1, true)
		ci.draw_colored_polygon(lens.slice(0, 16), Color(0.8, 0.9, 1.0, 0.1))
		line(PackedVector2Array([_HP(0.262, -0.07), _HP(-0.06, -0.05)]), gc, 1.1)
	var phones := str(pose.get("headphones", ""))
	if phones == "head":
		line(_map_H([Vector2(-0.08, -0.04), Vector2(-0.12, -0.36), Vector2(-0.04, -0.66), Vector2(0.08, -0.68)]), Color("26292e"), 0.09 * _s)
		var cup := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			cup.append(_HP(-0.07 + cos(a) * 0.14, 0.03 + sin(a) * 0.17))
		fill(cup, Color("2c3036"), 0.1, 0.1)
		ci.draw_circle(_HP(-0.07, 0.03), 0.07 * _s, Color("3e434a"))
	elif phones == "neck":
		var cup2 := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			cup2.append(_T(0.05, -0.3) + Vector2(cos(a), sin(a) * 1.2) * 0.022 * H)
		fill(cup2, Color("2c3036"), 0.1, 0.1)
		line(PackedVector2Array([_T(0.05, -0.3), _T(-0.02, -0.33), _T(-0.07, -0.3)]), Color("26292e"), 2.5)


# --- hair ------------------------------------------------------------------------------

const CAP := [Vector2(0.36, -0.36), Vector2(0.3, -0.47), Vector2(0.12, -0.6), Vector2(-0.12, -0.63), Vector2(-0.35, -0.55),
	Vector2(-0.5, -0.36), Vector2(-0.55, -0.1), Vector2(-0.49, 0.12), Vector2(-0.36, 0.22), Vector2(-0.22, 0.18),
	Vector2(-0.16, 0.02), Vector2(-0.07, -0.13), Vector2(0.1, -0.24), Vector2(0.23, -0.31)]


## Hair that hangs behind the head and body: ponytails, long hair, the bun.
func _hair_back() -> void:
	var c: Color = look.hair
	match str(look.get("style", "")):
		"ponytail":
			fill(smooth(_map_H([Vector2(-0.5, -0.1), Vector2(-0.66, 0.08), Vector2(-0.72, 0.42), Vector2(-0.66, 0.8),
				Vector2(-0.58, 1.02), Vector2(-0.53, 0.8), Vector2(-0.55, 0.45), Vector2(-0.47, 0.12), Vector2(-0.42, 0.0)]), 3), c, 0.12, 0.1)
			line(_map_H([Vector2(-0.6, 0.15), Vector2(-0.65, 0.5), Vector2(-0.6, 0.85)]), look.hair_hi, 1.0)
		"ponytail_long":
			# The same ponytail, grown out: it reaches between her shoulder blades.
			fill(smooth(_map_H([Vector2(-0.5, -0.1), Vector2(-0.67, 0.1), Vector2(-0.74, 0.5), Vector2(-0.7, 0.98),
				Vector2(-0.64, 1.36), Vector2(-0.56, 1.5), Vector2(-0.52, 1.24), Vector2(-0.54, 0.8), Vector2(-0.53, 0.4),
				Vector2(-0.46, 0.12), Vector2(-0.42, 0.0)]), 3), c, 0.12, 0.1)
			line(_map_H([Vector2(-0.6, 0.15), Vector2(-0.66, 0.6), Vector2(-0.62, 1.1), Vector2(-0.58, 1.34)]), look.hair_hi, 1.0)
		"long":
			fill(smooth(_map_H([Vector2(-0.3, -0.52), Vector2(-0.56, -0.3), Vector2(-0.63, 0.1), Vector2(-0.67, 0.6),
				Vector2(-0.72, 1.15), Vector2(-0.64, 1.55), Vector2(-0.42, 1.62), Vector2(-0.3, 1.2), Vector2(-0.24, 0.72),
				Vector2(-0.2, 0.3)]), 3), c, 0.12, 0.12)
			for x in [-0.5, -0.4]:
				line(_map_H([Vector2(x, 0.0), Vector2(x - 0.08, 0.6), Vector2(x - 0.04, 1.3)]), look.hair_hi, 1.0)
		"bun":
			var bun := PackedVector2Array()
			for i in 14:
				var a := TAU * i / 14.0
				bun.append(_HP(-0.55 + cos(a) * 0.2, -0.2 + sin(a) * 0.19))
			fill(bun, c.darkened(0.05), 0.12, 0.14)
			for k in 3:
				line(_map_H([Vector2(-0.7, -0.24 + k * 0.06), Vector2(-0.55, -0.34 + k * 0.08), Vector2(-0.4, -0.22 + k * 0.06)]), look.hair_hi, 1.0)
		"perm":
			_perm(true)
		"high_pony":
			# 1991: pulled up high from the crown in a scrunchie, falling past the shoulders.
			fill(smooth(_map_H([Vector2(-0.3, -0.66), Vector2(-0.5, -0.68), Vector2(-0.7, -0.52), Vector2(-0.82, -0.2),
				Vector2(-0.85, 0.22), Vector2(-0.78, 0.6), Vector2(-0.66, 0.72), Vector2(-0.6, 0.42), Vector2(-0.62, 0.02),
				Vector2(-0.55, -0.3), Vector2(-0.4, -0.52)]), 3), c, 0.12, 0.1)
			line(_map_H([Vector2(-0.62, -0.42), Vector2(-0.75, 0.0), Vector2(-0.72, 0.5)]), look.hair_hi, 1.0)
			line(_map_H([Vector2(-0.56, -0.2), Vector2(-0.68, 0.2), Vector2(-0.66, 0.56)]), c.darkened(0.15), 1.0)
		"bob":
			# A blunt bob to the jaw.
			fill(smooth(_map_H([Vector2(-0.18, -0.62), Vector2(-0.5, -0.5), Vector2(-0.66, -0.14), Vector2(-0.66, 0.26),
				Vector2(-0.54, 0.46), Vector2(-0.24, 0.48), Vector2(-0.1, 0.24)]), 3), c, 0.12, 0.12)


## Hair over the head: caps, fringes, curls, hats.
func _hair_front() -> void:
	var c: Color = look.hair
	var hi: Color = look.get("hair_hi", c.lightened(0.2))
	match str(look.get("style", "")):
		"ponytail", "ponytail_long":
			fill(smooth(_map_H(CAP), 3), c, 0.12, 0.1)
			# A side-swept fringe and a loose strand by the ear.
			fill(smooth(_map_H([Vector2(0.04, -0.62), Vector2(0.3, -0.52), Vector2(0.43, -0.34), Vector2(0.41, -0.24),
				Vector2(0.33, -0.28), Vector2(0.18, -0.36), Vector2(0.06, -0.42)]), 3), c, 0.12, 0.08)
			line(_map_H([Vector2(0.05, -0.55), Vector2(0.25, -0.46), Vector2(0.38, -0.3)]), hi, 1.0)
			line(_map_H([Vector2(-0.3, -0.5), Vector2(-0.46, -0.2)]), hi, 1.0)
			line(_map_H([Vector2(0.04, -0.2), Vector2(0.08, 0.1), Vector2(0.04, 0.3)]), c, 1.4)
			ci.draw_circle(_HP(-0.5, -0.06), 0.06 * _s, Color("1a1412"))
		"long":
			fill(smooth(_map_H(CAP), 3), c, 0.12, 0.1)
			fill(smooth(_map_H([Vector2(-0.1, -0.2), Vector2(0.06, -0.3), Vector2(0.12, 0.0), Vector2(0.07, 0.36),
				Vector2(-0.04, 0.58), Vector2(-0.22, 0.48), Vector2(-0.24, 0.0)]), 3), c, 0.08, 0.12)
			fill(smooth(_map_H([Vector2(0.18, -0.56), Vector2(0.38, -0.42), Vector2(0.41, -0.3), Vector2(0.27, -0.34),
				Vector2(0.14, -0.44)]), 2), c, 0.12, 0.08)
			line(_map_H([Vector2(0.0, -0.58), Vector2(-0.3, -0.5), Vector2(-0.48, -0.26)]), hi, 1.0)
		"braid":
			fill(smooth(_map_H(CAP), 3), c, 0.1, 0.1)
			# The grey streak, and strands that have come loose.
			fill(smooth(_map_H([Vector2(0.26, -0.44), Vector2(0.06, -0.6), Vector2(-0.2, -0.6), Vector2(-0.3, -0.5),
				Vector2(-0.08, -0.52), Vector2(0.18, -0.4)]), 2), hi, 0.1, 0.06, false)
			line(_map_H([Vector2(0.3, -0.42), Vector2(0.42, -0.22), Vector2(0.38, -0.05)]), c, 1.2)
			line(_map_H([Vector2(-0.4, -0.5), Vector2(-0.58, -0.4)]), c, 1.2)
			line(_map_H([Vector2(0.0, -0.2), Vector2(0.06, 0.15), Vector2(0.02, 0.36)]), hi, 1.0)
		"bun":
			var cap := CAP.duplicate()
			cap[1] = Vector2(0.3, -0.45)
			fill(smooth(_map_H(cap), 3), c, 0.12, 0.08)
			for k in 4:
				line(_map_H([Vector2(0.3 - k * 0.03, -0.42 + k * 0.04), Vector2(0.0, -0.56 + k * 0.05), Vector2(-0.4, -0.38 + k * 0.06)]), c.darkened(0.12), 1.0)
			line(_map_H([Vector2(-0.6, -0.36), Vector2(-0.46, -0.1)]), Color("8a7a5a"), 1.2)
		"perm":
			_perm(false)
		"rollers":
			fill(smooth(_map_H(CAP), 3), c, 0.12, 0.1)
			for p in [Vector2(0.18, -0.56), Vector2(-0.06, -0.66), Vector2(-0.3, -0.59), Vector2(-0.48, -0.4), Vector2(-0.55, -0.14)]:
				var outward: Vector2 = (p - Vector2(-0.08, -0.12)).normalized()
				var along := Vector2(-outward.y, outward.x)
				var a := _HP(p.x - along.x * 0.11, p.y - along.y * 0.11)
				var b := _HP(p.x + along.x * 0.11, p.y + along.y * 0.11)
				fill(capsule(a, b, 0.075 * _s, 0.075 * _s), Color("e48aa6"), 0.12, 0.12)
				ci.draw_circle(b, 0.035 * _s, Color("b8607c"))
			for k in 3:
				ci.draw_circle(_HP(-0.4 + k * 0.08, 0.16 + k * 0.03), 0.06 * _s, c)
		"tousled":
			var spikes := [Vector2(0.4, -0.27), Vector2(0.44, -0.38), Vector2(0.33, -0.44), Vector2(0.38, -0.56), Vector2(0.2, -0.58),
				Vector2(0.17, -0.72), Vector2(0.02, -0.67), Vector2(-0.06, -0.78), Vector2(-0.19, -0.67), Vector2(-0.33, -0.72),
				Vector2(-0.4, -0.58), Vector2(-0.55, -0.53), Vector2(-0.54, -0.37), Vector2(-0.62, -0.24), Vector2(-0.53, -0.1),
				Vector2(-0.5, 0.06), Vector2(-0.4, 0.15), Vector2(-0.3, 0.18), Vector2(-0.19, 0.12), Vector2(-0.14, 0.0),
				Vector2(-0.05, -0.14), Vector2(0.1, -0.22), Vector2(0.22, -0.2), Vector2(0.3, -0.18)]
			fill(smooth(_map_H(spikes), 2), c, 0.14, 0.1)
			for k in 3:
				line(_map_H([Vector2(0.2 - k * 0.2, -0.6), Vector2(0.1 - k * 0.2, -0.4)]), hi, 1.0)
		"horseshoe":
			fill(smooth(_map_H([Vector2(0.05, -0.2), Vector2(-0.03, -0.36), Vector2(-0.28, -0.47), Vector2(-0.48, -0.35),
				Vector2(-0.55, -0.08), Vector2(-0.47, 0.14), Vector2(-0.34, 0.22), Vector2(-0.22, 0.16), Vector2(-0.16, 0.02),
				Vector2(-0.08, -0.1)]), 2), c, 0.1, 0.1)
			line(_map_H([Vector2(-0.05, -0.56), Vector2(0.12, -0.54)]), Color(1, 1, 1, 0.35), 2.0)
		"short":
			fill(smooth(_map_H([Vector2(0.36, -0.4), Vector2(0.3, -0.52), Vector2(0.1, -0.62), Vector2(-0.14, -0.64), Vector2(-0.37, -0.56),
				Vector2(-0.51, -0.36), Vector2(-0.53, -0.1), Vector2(-0.46, 0.08), Vector2(-0.36, 0.14), Vector2(-0.22, 0.1),
				Vector2(-0.14, 0.02), Vector2(-0.04, 0.06), Vector2(0.02, 0.04), Vector2(0.06, -0.14), Vector2(0.18, -0.26),
				Vector2(0.3, -0.34)]), 2), c, 0.1, 0.1)
			line(_map_H([Vector2(0.2, -0.54), Vector2(-0.1, -0.58)]), hi, 1.0)
		"cap":
			fill(smooth(_map_H([Vector2(-0.46, -0.32), Vector2(-0.54, -0.05), Vector2(-0.45, 0.1), Vector2(-0.3, 0.14),
				Vector2(-0.2, 0.06), Vector2(-0.16, -0.3)]), 2), c, 0.08, 0.1)
			var hat: Color = look.get("hat_col", Color("2e4a6a"))
			fill(smooth(_map_H([Vector2(0.38, -0.36), Vector2(0.3, -0.58), Vector2(0.05, -0.7), Vector2(-0.26, -0.66),
				Vector2(-0.47, -0.5), Vector2(-0.52, -0.3), Vector2(0.36, -0.3)]), 2), hat, 0.12, 0.12)
			fill(PackedVector2Array([_HP(0.3, -0.37), _HP(0.66, -0.33), _HP(0.67, -0.28), _HP(0.3, -0.29)]), hat.darkened(0.2), 0.04, 0.06)
			fill(smooth(_map_H([Vector2(0.24, -0.6), Vector2(0.36, -0.4), Vector2(0.1, -0.38), Vector2(0.05, -0.62)]), 2), Color("e6e2d6"), 0.04, 0.06, false)
		"beanie":
			var hat2: Color = look.get("hat_col", Color("7a2a2a"))
			fill(smooth(_map_H([Vector2(0.38, -0.3), Vector2(0.35, -0.52), Vector2(0.13, -0.69), Vector2(-0.18, -0.72),
				Vector2(-0.43, -0.6), Vector2(-0.56, -0.38), Vector2(-0.58, -0.12), Vector2(0.38, -0.2)]), 2), hat2, 0.12, 0.12)
			fill(PackedVector2Array([_HP(0.4, -0.34), _HP(0.4, -0.18), _HP(-0.59, -0.08), _HP(-0.58, -0.24)]), hat2.darkened(0.18), 0.04, 0.06)
			for k in 6:
				var x := 0.28 - k * 0.15
				line(_map_H([Vector2(x, -0.36 + absf(x) * 0.1), Vector2(x * 0.8, -0.62 + absf(x) * 0.1)]), hat2.darkened(0.25), 1.0)
		"bald_fringe":
			fill(smooth(_map_H([Vector2(-0.1, -0.12), Vector2(-0.3, -0.32), Vector2(-0.49, -0.22), Vector2(-0.53, 0.0),
				Vector2(-0.45, 0.14), Vector2(-0.3, 0.2), Vector2(-0.2, 0.12), Vector2(-0.14, 0.0)]), 2), c, 0.1, 0.1)
			line(_map_H([Vector2(-0.1, -0.56), Vector2(0.1, -0.53)]), Color(1, 1, 1, 0.3), 2.0)
		"shaggy":
			# Grown out past the collar, the fringe falling forward to the brows:
			# a twenty-one-year-old in 1991.
			fill(smooth(_map_H([Vector2(0.43, -0.2), Vector2(0.41, -0.42), Vector2(0.25, -0.62), Vector2(0.0, -0.72),
				Vector2(-0.28, -0.68), Vector2(-0.5, -0.5), Vector2(-0.61, -0.2), Vector2(-0.61, 0.12), Vector2(-0.53, 0.38),
				Vector2(-0.41, 0.44), Vector2(-0.3, 0.3), Vector2(-0.2, 0.12), Vector2(-0.1, 0.07), Vector2(-0.03, -0.08),
				Vector2(0.12, -0.21), Vector2(0.27, -0.2)]), 2), c, 0.14, 0.1)
			for k in 4:
				line(_map_H([Vector2(0.3 - k * 0.2, -0.58 + k * 0.02), Vector2(0.37 - k * 0.22, -0.27 + k * 0.05)]), hi, 1.0)
		"side_part":
			# Short and tidy, parted on the side.
			fill(smooth(_map_H([Vector2(0.37, -0.36), Vector2(0.3, -0.54), Vector2(0.1, -0.66), Vector2(-0.16, -0.66),
				Vector2(-0.38, -0.56), Vector2(-0.52, -0.34), Vector2(-0.54, -0.08), Vector2(-0.46, 0.1), Vector2(-0.34, 0.16),
				Vector2(-0.22, 0.1), Vector2(-0.14, 0.0), Vector2(-0.04, -0.06), Vector2(0.1, -0.22), Vector2(0.26, -0.3)]), 2), c, 0.1, 0.1)
			line(_map_H([Vector2(0.16, -0.6), Vector2(-0.2, -0.63)]), c.darkened(0.35), 1.2)
			line(_map_H([Vector2(0.3, -0.5), Vector2(0.04, -0.57)]), hi, 1.0)
		"receding":
			# White, thin, the hairline long gone back: a few strands combed over.
			fill(smooth(_map_H([Vector2(-0.02, -0.5), Vector2(-0.2, -0.62), Vector2(-0.4, -0.55), Vector2(-0.53, -0.32),
				Vector2(-0.55, -0.06), Vector2(-0.47, 0.12), Vector2(-0.34, 0.18), Vector2(-0.22, 0.12), Vector2(-0.15, 0.0),
				Vector2(-0.12, -0.2), Vector2(-0.07, -0.38)]), 2), c, 0.08, 0.1)
			line(_map_H([Vector2(0.18, -0.52), Vector2(0.0, -0.6), Vector2(-0.2, -0.63)]), c, 2.0)
			line(_map_H([Vector2(0.12, -0.5), Vector2(-0.06, -0.57)]), c.darkened(0.1), 1.2)
			line(_map_H([Vector2(-0.02, -0.57), Vector2(0.14, -0.55)]), Color(1, 1, 1, 0.3), 2.0)
		"high_pony":
			fill(smooth(_map_H(CAP), 3), c, 0.12, 0.1)
			# Big curled bangs, the way everyone wore them.
			fill(smooth(_map_H([Vector2(0.0, -0.68), Vector2(0.24, -0.63), Vector2(0.42, -0.47), Vector2(0.48, -0.3),
				Vector2(0.41, -0.22), Vector2(0.3, -0.26), Vector2(0.18, -0.32), Vector2(0.06, -0.42)]), 3), c, 0.14, 0.08)
			for k in 3:
				ci.draw_arc(_HP(0.2 + k * 0.08, -0.34 + k * 0.025), 0.05 * _s, 0.2, 2.6, 6, hi, 1.0, true)
			var scr: Color = look.get("scrunchie", Color("c84a7a"))
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_circle(_HP(-0.42 + cos(a) * 0.075, -0.64 + sin(a) * 0.055), 0.055 * _s, scr.darkened(0.12 * (k % 2)))
		"bob":
			fill(smooth(_map_H(CAP), 3), c, 0.12, 0.1)
			fill(smooth(_map_H([Vector2(0.0, -0.64), Vector2(0.26, -0.56), Vector2(0.42, -0.37), Vector2(0.43, -0.25),
				Vector2(0.22, -0.25), Vector2(0.04, -0.34)]), 2), c, 0.12, 0.08)
			# The side, straight down past the ear to the jaw.
			fill(smooth(_map_H([Vector2(-0.12, -0.32), Vector2(0.06, -0.3), Vector2(0.1, 0.08), Vector2(0.05, 0.44),
				Vector2(-0.16, 0.47), Vector2(-0.2, 0.02)]), 2), c, 0.08, 0.12)
			line(_map_H([Vector2(0.02, -0.25), Vector2(0.06, 0.4)]), hi, 1.0)


## Ruth's and Ma's perm: a soft bob of curls down to the jaw.
func _perm(back: bool) -> void:
	var c: Color = look.hair
	var outer := [Vector2(0.36, -0.36), Vector2(0.34, -0.56), Vector2(0.15, -0.74), Vector2(-0.15, -0.78), Vector2(-0.43, -0.68),
		Vector2(-0.63, -0.44), Vector2(-0.71, -0.12), Vector2(-0.67, 0.2), Vector2(-0.53, 0.42), Vector2(-0.32, 0.47),
		Vector2(-0.18, 0.4)]
	var inner := [Vector2(-0.1, 0.3), Vector2(0.02, 0.2), Vector2(0.06, 0.0), Vector2(0.13, -0.2), Vector2(0.27, -0.32)]
	if back:
		# Volume behind: the scalloped outer edge.
		var pts: Array = []
		for i in outer.size() - 1:
			pts.append(outer[i])
			var mid: Vector2 = (outer[i] + outer[i + 1]) * 0.5
			pts.append(mid + (mid - Vector2(-0.12, -0.15)).normalized() * 0.07)
		pts.append(outer[outer.size() - 1])
		pts.append_array(inner)
		fill(smooth(_map_H(pts), 2), c, 0.12, 0.12)
		return
	var cap: Array = outer.duplicate()
	cap.append_array(inner)
	fill(smooth(_map_H(cap), 3), c, 0.14, 0.1)
	var hi: Color = look.get("hair_hi", c.lightened(0.2))
	for i in 26:
		var a := -2.4 + 3.6 * fposmod(i * 0.618, 1.0)
		var r := 0.22 + 0.42 * fposmod(i * 0.382 + 0.1, 1.0)
		var p := Vector2(-0.12, -0.14) + Vector2(cos(a), sin(a)) * r
		if p.x > 0.12 and p.y > -0.3:
			continue
		var cc := hi if i % 3 == 0 else c.darkened(0.18)
		ci.draw_arc(_HP(p.x, p.y), (0.035 + 0.015 * (i % 3)) * _s, 0.4 + i, 3.9 + i, 7, cc, 1.0, true)


## Eighty-One's braid, over her shoulder and down the front of her coat.
func _braid() -> void:
	if str(look.get("style", "")) != "braid":
		return
	var c: Color = look.hair
	var path := [_HP(-0.12, 0.28), _T(0.0, -0.29), _T(0.05, -0.25), _T(0.072, -0.19), _T(0.078, -0.13)]
	var curve := smooth(PackedVector2Array(path), 4, false)
	for i in range(0, curve.size() - 1):
		var a := curve[i]
		var b := curve[i + 1]
		var d := (b - a).normalized()
		var n := Vector2(d.y, -d.x)
		var w := 0.022 * H * (1.0 - 0.3 * float(i) / curve.size())
		var off := n * w * 0.35 * (1.0 if i % 2 == 0 else -1.0)
		var seg := PackedVector2Array()
		for k in 10:
			var ang := TAU * k / 10.0
			seg.append(a.lerp(b, 0.5) + off + d * cos(ang) * w * 0.9 + n * sin(ang) * w * 0.6)
		fill(seg, c if i % 3 != 1 else look.hair_hi.darkened(0.2), 0.12, 0.1)
	if not flat:
		ci.draw_circle(curve[curve.size() - 1], 0.012 * H, Color("6a2f2c"))


## Eighty-One's scarf: wound at the neck, one end down the front.
func _scarf_front() -> void:
	var sc: Color = look.get("scarf", Color(0, 0, 0, 0))
	if sc.a <= 0.0:
		return
	fill(smooth(_map_T([Vector2(-0.06, -0.33), Vector2(0.0, -0.345), Vector2(0.06, -0.32), Vector2(0.07, -0.29),
		Vector2(0.0, -0.29), Vector2(-0.065, -0.3)]), 2), sc, 0.1, 0.12)
	fill(smooth(_map_T([Vector2(0.04, -0.3), Vector2(0.075, -0.3), Vector2(0.085, -0.2), Vector2(0.078, -0.14),
		Vector2(0.056, -0.14), Vector2(0.06, -0.22)]), 2), sc.darkened(0.08), 0.08, 0.12)
	if not flat:
		for k in 3:
			line(_map_T([Vector2(0.058 + k * 0.007, -0.145), Vector2(0.058 + k * 0.007, -0.125)]), sc.darkened(0.25), 1.0)


# --- props -----------------------------------------------------------------------------

func _prop(pose: Dictionary) -> void:
	var prop := str(pose.get("prop", ""))
	var arms: Array = pose.arms
	var near_w := _wrist(arms[0], false)
	match prop:
		"radio":
			var far_w := _wrist(arms[1], true)
			var mid := near_w.lerp(far_w, 0.5) + Vector2(0.03 * H, 0.0)
			_radio_box(Rect2(mid - Vector2(0.075 * H, 0.05 * H), Vector2(0.16 * H, 0.1 * H)), pose, false)
			_hand(near_w, (near_w - _elbow(arms[0], false)).normalized().rotated(-0.1), _skin(), false)
		"flashlight":
			var d := (near_w - _elbow(arms[0], false)).normalized()
			var a := near_w + d * 0.02 * H
			var b := near_w + d * 0.15 * H
			fill(capsule(a, b, 0.016 * H, 0.016 * H), Color("2b2d31"), 0.14, 0.1)
			fill(capsule(b - d * 0.02 * H, b + d * 0.012 * H, 0.023 * H, 0.023 * H), Color("4a4d52"), 0.14, 0.1)
			ci.draw_circle(b + d * 0.014 * H, 0.016 * H, Color("fff2c8"))
			_hand(near_w, d.rotated(-0.1), _skin(), false)
		"coat":
			# Arne's spare coat, folded over her forearm, a sleeve hanging loose.
			var e := _elbow(arms[0], false)
			var coat: Color = pose.get("prop_col", Color("3c4a3a"))
			var a0 := e.lerp(near_w, 0.15)
			var a1 := e.lerp(near_w, 0.85)
			var fold := PackedVector2Array([a0 + Vector2(0, -5), a1 + Vector2(0, -5), a1 + Vector2(3, 0.2 * H),
				a1 + Vector2(-0.02 * H, 0.23 * H), a0 + Vector2(0.01 * H, 0.21 * H), a0 + Vector2(-3, 0.12 * H)])
			fill(smooth(fold, 2), coat, 0.12, 0.16)
			fill(capsule(a1 + Vector2(-2, 0.05 * H), a1 + Vector2(6, 0.26 * H), 0.018 * H, 0.015 * H), coat.darkened(0.12), 0.06, 0.12)
			if not flat:
				for k in 3:
					line(PackedVector2Array([a0.lerp(a1, 0.25 + k * 0.25) + Vector2(0, 0.02 * H), a0.lerp(a1, 0.2 + k * 0.25) + Vector2(0, 0.19 * H)]), coat.darkened(0.3), 1.0)
				line(PackedVector2Array([a0 + Vector2(0, -4), a1 + Vector2(0, -4)]), coat.lightened(0.2), 1.2)
			_hand(near_w, (near_w - e).normalized(), _skin(), false)
		"radio_up":
			# Held up over his head for better reception, aerial up.
			var far_w := _wrist(arms[1], true)
			var mid := near_w.lerp(far_w, 0.5) + Vector2(0.0, -0.035 * H)
			_radio_box(Rect2(mid - Vector2(0.08 * H, 0.05 * H), Vector2(0.16 * H, 0.1 * H)), pose, true)
			_hand(near_w, Vector2(0.2, -1.0).normalized(), _skin(), false)
		"radio_light":
			# The radio hanging from one hand, the flashlight in the other.
			var far_w2 := _wrist(arms[1], true)
			_radio_box(Rect2(far_w2 + Vector2(-0.07 * H, 0.0), Vector2(0.14 * H, 0.09 * H)), pose, false)
			var d2 := (near_w - _elbow(arms[0], false)).normalized()
			fill(capsule(near_w + d2 * 0.02 * H, near_w + d2 * 0.15 * H, 0.016 * H, 0.016 * H), Color("2b2d31"), 0.14, 0.1)
			ci.draw_circle(near_w + d2 * 0.165 * H, 0.017 * H, Color("fff2c8"))
			_hand(near_w, d2.rotated(-0.1), _skin(), false)
		"key":
			var kd := (near_w - _elbow(arms[0], false)).normalized()
			var kp := near_w + kd * 0.05 * H
			ci.draw_circle(kp, 0.011 * H, Color("c9b27a"))
			ci.draw_circle(kp, 0.005 * H, _skin().darkened(0.3))
			ci.draw_line(kp + kd * 0.01 * H, kp + kd * 0.045 * H, Color("c9b27a"), 0.006 * H)
			_hand(near_w, kd.rotated(-0.1), _skin(), false)
		"notebook":
			var nd := (near_w - _elbow(arms[0], false)).normalized()
			var nb := near_w + nd * 0.04 * H
			fill(PackedVector2Array([nb + Vector2(-0.03, -0.04) * H, nb + Vector2(0.035, -0.045) * H, nb + Vector2(0.04, 0.03) * H,
				nb + Vector2(-0.025, 0.035) * H]), Color("e8e2cc"), 0.04, 0.08)
			line(PackedVector2Array([nb + Vector2(-0.03, -0.04) * H, nb + Vector2(0.035, -0.045) * H]), Color("6a4a30"), 2.0)
			_hand(near_w, nd.rotated(-0.1), _skin(), false)
		"thermos":
			var td := (near_w - _elbow(arms[0], false)).normalized()
			var tp := near_w + td * 0.02 * H
			fill(capsule(tp + Vector2(0, -0.06 * H), tp + Vector2(0, 0.05 * H), 0.022 * H, 0.022 * H), Color("3e6a58"), 0.14, 0.12)
			ci.draw_rect(Rect2(tp + Vector2(-0.024 * H, -0.075 * H), Vector2(0.048 * H, 0.02 * H)), Color("b8bcc0"))
			_hand(near_w, td.rotated(-0.1), _skin(), false)
		"phone":
			# The receiver at her ear, its cord curling down.
			var ear := _HP(-0.05, 0.12)
			var rcv := ear + Vector2(0.015 * H, 0.0)
			fill(capsule(rcv + Vector2(0.0, -0.035 * H), rcv + Vector2(0.03 * H, 0.06 * H), 0.016 * H, 0.016 * H), Color("1e2023"), 0.1, 0.1)
			var coil := PackedVector2Array()
			for i in 12:
				coil.append(rcv + Vector2(0.03 * H + sin(i * 1.7) * 0.01 * H, 0.06 * H + i * 0.022 * H))
			ci.draw_polyline(coil, Color("1e2023"), 1.4, true)
			_hand(near_w, (rcv - near_w).normalized(), _skin(), false)
		"baby":
			# A baby asleep against her shoulder, swaddled in the blue blanket.
			var far_b := _wrist(arms[1], true)
			var mid_b := near_w.lerp(far_b, 0.5) + Vector2(0.01 * H, -0.015 * H)
			var bl: Color = pose.get("prop_col", Color("6a8ac8"))
			# The bundle lies across her chest, the head up at her shoulder.
			fill(capsule(mid_b + Vector2(0.04 * H, 0.03 * H), mid_b + Vector2(-0.03 * H, -0.045 * H), 0.045 * H, 0.04 * H), bl, 0.08, 0.12)
			var hd := mid_b + Vector2(-0.035 * H, -0.075 * H)
			ci.draw_circle(hd, 0.026 * H, _skin().lightened(0.08))
			ci.draw_arc(hd, 0.03 * H, PI * 1.05, PI * 1.95, 10, bl.darkened(0.1), 0.012 * H)
			_hand(near_w, Vector2(0.6, -0.8).normalized(), _skin(), false)
		"bag":
			# A paper bag from the diner, held by its rolled top.
			var bc: Color = pose.get("prop_col", Color("b58a5a"))
			var b0 := near_w + Vector2(-0.035 * H, 0.0)
			fill(PackedVector2Array([b0, b0 + Vector2(0.07 * H, 0.0), b0 + Vector2(0.075 * H, 0.1 * H), b0 + Vector2(-0.005 * H, 0.1 * H)]), bc, 0.06, 0.12)
			line(PackedVector2Array([b0 + Vector2(0.0, 0.012 * H), b0 + Vector2(0.07 * H, 0.012 * H)]), bc.darkened(0.3), 1.2)
			_hand(near_w, Vector2(0.3, 1.0).normalized(), _skin(), false)
		"headphones":
			# Tomas's headphones, lifted by the band; the cable's caught round her wrist.
			var hd := (near_w - _elbow(arms[0], false)).normalized()
			var top := near_w + hd * 0.03 * H + Vector2(0, -0.01 * H)
			line(PackedVector2Array([top + Vector2(-0.05 * H, 0.06 * H), top + Vector2(-0.03 * H, 0.0), top + Vector2(0.03 * H, 0.0),
				top + Vector2(0.05 * H, 0.06 * H)]), Color("26292e"), 0.012 * H)
			for side in [-1.0, 1.0]:
				var cup := top + Vector2(0.052 * H * side, 0.075 * H)
				fill(PackedVector2Array([cup + Vector2(-0.016, -0.022) * H, cup + Vector2(0.016, -0.022) * H, cup + Vector2(0.018, 0.022) * H,
					cup + Vector2(-0.018, 0.022) * H]), Color("2c3036"), 0.1, 0.1)
			var cable := PackedVector2Array([top + Vector2(0.052 * H, 0.1 * H), near_w + Vector2(0.01 * H, 0.04 * H)])
			for k in 8:
				var a := k * 0.9
				cable.append(near_w + Vector2(cos(a) * 0.022 * H, sin(a) * 0.012 * H - 0.02 * H))
			cable.append(near_w + Vector2(-0.01 * H, 0.16 * H))
			ci.draw_polyline(cable, Color("1a1a1c"), 1.6, true)
			_hand(near_w, hd.rotated(-0.1), _skin(), false)
		"poster":
			# A sheet held up flat against a window or a post.
			var far_w3 := _wrist(arms[1], true)
			var c3 := near_w.lerp(far_w3, 0.5) + Vector2(0.02 * H, -0.02 * H)
			var sheet := Rect2(c3 - Vector2(0.06 * H, 0.08 * H), Vector2(0.12 * H, 0.16 * H))
			ci.draw_rect(sheet, Color("efeadb"))
			ci.draw_rect(Rect2(sheet.position + Vector2(0.025 * H, 0.03 * H), Vector2(0.07 * H, 0.06 * H)), Color("9aa0a0"))
			ci.draw_rect(Rect2(sheet.position + Vector2(0.015 * H, 0.008 * H), Vector2(0.09 * H, 0.012 * H)), Color("8a1d1d"))
			_hand(near_w, Vector2(1.0, -0.4).normalized(), _skin(), false)
		"lamp":
			# A storm lantern held out low: its wire bail in the hand, the glass globe below.
			var lp := near_w + Vector2(0.0, 0.035 * H)
			line(PackedVector2Array([near_w + Vector2(-0.012 * H, 0.0), lp + Vector2(-0.021 * H, 0.0)]), Color("3a3a36"), 1.3)
			line(PackedVector2Array([near_w + Vector2(0.012 * H, 0.0), lp + Vector2(0.021 * H, 0.0)]), Color("3a3a36"), 1.3)
			fill(PackedVector2Array([lp + Vector2(-0.025, 0.0) * H, lp + Vector2(0.025, 0.0) * H, lp + Vector2(0.021, 0.013) * H,
				lp + Vector2(-0.021, 0.013) * H]), Color("5a4a2a"), 0.08, 0.1)
			var globe := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				globe.append(lp + Vector2(cos(a) * 0.021 * H, 0.042 * H + sin(a) * 0.029 * H))
			fill(globe, Color("ffd890"), 0.0, 0.12, false)
			ci.draw_circle(lp + Vector2(0, 0.046 * H), 0.009 * H, Color("fff6d8"))
			fill(PackedVector2Array([lp + Vector2(-0.027, 0.068) * H, lp + Vector2(0.027, 0.068) * H, lp + Vector2(0.027, 0.085) * H,
				lp + Vector2(-0.027, 0.085) * H]), Color("5a4a2a"), 0.08, 0.1)
			_hand(near_w, Vector2(0.15, 1.0).normalized(), _skin(), false)
		"cane":
			var foot := Vector2(near_w.x + 0.05 * H, 0.0)
			ci.draw_line(near_w + Vector2(0.004 * H, 0.0), foot, Color("4a3424"), 0.012 * H, true)
			ci.draw_arc(near_w + Vector2(-0.012 * H, -0.002 * H), 0.016 * H, PI, TAU, 8, Color("4a3424"), 0.012 * H, true)
			ci.draw_circle(foot, 0.008 * H, Color("1e1a16"))
			_hand(near_w, Vector2(0.3, 1.0).normalized(), _skin(), false)
		"smartphone":
			# A phone held up out of habit. The screen stays dark.
			var sd := (near_w - _elbow(arms[0], false)).normalized()
			var spc := near_w + sd * 0.02 * H
			fill(PackedVector2Array([spc + Vector2(-0.011, -0.046) * H, spc + Vector2(0.012, -0.046) * H, spc + Vector2(0.012, 0.03) * H,
				spc + Vector2(-0.011, 0.03) * H]), Color("16181c"), 0.06, 0.06)
			line(PackedVector2Array([spc + Vector2(-0.008, -0.042) * H, spc + Vector2(0.004, -0.042) * H]), Color(0.6, 0.7, 0.8, 0.4), 1.0)
			_hand(near_w, sd.rotated(-0.1), _skin(), false)
		"revolver", "revolver_aim":
			# Sollen's old service revolver: barrel, cylinder, the wooden grip.
			var rd := (near_w - _elbow(arms[0], false)).normalized()
			var g0 := near_w + rd * 0.012 * H
			var gn := Vector2(-rd.y, rd.x)
			var gun := Color("1c1d20")
			ci.draw_line(g0, g0 + rd * 0.095 * H, gun, 0.013 * H, true)
			ci.draw_circle(g0 + rd * 0.028 * H, 0.018 * H, gun.lightened(0.1))
			ci.draw_line(g0, g0 + gn * 0.038 * H - rd * 0.016 * H, Color("4a3020"), 0.017 * H, true)
			ci.draw_line(g0 + rd * 0.088 * H, g0 + rd * 0.088 * H - gn * 0.01 * H, gun, 2.0)
			_hand(near_w, rd.rotated(-0.1), _skin(), false)
		"clipboard":
			# The lamp-line register: who's been counted tonight.
			var cd := (near_w - _elbow(arms[0], false)).normalized()
			var cb := near_w + cd * 0.03 * H
			fill(PackedVector2Array([cb + Vector2(-0.03, -0.05) * H, cb + Vector2(0.03, -0.052) * H, cb + Vector2(0.034, 0.04) * H,
				cb + Vector2(-0.026, 0.042) * H]), Color("8a6a40"), 0.06, 0.08)
			fill(PackedVector2Array([cb + Vector2(-0.024, -0.04) * H, cb + Vector2(0.026, -0.042) * H, cb + Vector2(0.028, 0.032) * H,
				cb + Vector2(-0.022, 0.034) * H]), Color("efeadb"), 0.02, 0.04, false)
			for k in 4:
				line(PackedVector2Array([cb + Vector2(-0.018, -0.028 + k * 0.016) * H, cb + Vector2(0.018, -0.03 + k * 0.016) * H]), Color("6a6a70"), 1.0)
			_hand(near_w, cd.rotated(-0.1), _skin(), false)
		"mug":
			var m := near_w + Vector2(0.03 * H, -0.02 * H)
			fill(PackedVector2Array([m + Vector2(-0.025 * H, -0.03 * H), m + Vector2(0.025 * H, -0.03 * H),
				m + Vector2(0.022 * H, 0.03 * H), m + Vector2(-0.022 * H, 0.03 * H)]), Color("e8e2d4"), 0.08, 0.1)
			if not flat:
				ci.draw_arc(m + Vector2(0.03 * H, 0.0), 0.012 * H, -1.4, 1.4, 8, Color("e8e2d4"), 2.0, true)
				for k in 2:
					ci.draw_line(m + Vector2(-0.006 * H + k * 6, -0.05 * H), m + Vector2(-0.01 * H + k * 6, -0.09 * H), Color(1, 1, 1, 0.25), 1.2, true)
			_hand(near_w, (near_w - _elbow(arms[0], false)).normalized(), _skin(), false)


## Tomas's radio: the green field set he rebuilt, its dial, speaker and aerial,
## and the headphone cord from his ear (with any tape on it).
func _radio_box(box: Rect2, pose: Dictionary, aerial_up: bool) -> void:
	var pts := PackedVector2Array([box.position, box.position + Vector2(box.size.x, 0), box.end, box.position + Vector2(0, box.size.y)])
	fill(pts, Color("4a5a3a"), 0.12, 0.14)
	if flat:
		return
	ci.draw_rect(Rect2(box.position + Vector2(4, 4), Vector2(box.size.x * 0.5, box.size.y * 0.35)), Color("c8c39f"))
	ci.draw_circle(box.position + Vector2(box.size.x * 0.75, box.size.y * 0.55), 0.02 * H, Color("1e2420"))
	ci.draw_circle(box.position + Vector2(box.size.x * 0.3, box.size.y * 0.72), 0.012 * H, Color("1e2420"))
	var tip := box.position + Vector2(box.size.x + 0.05 * H, -0.3 * H) if not aerial_up else box.position + Vector2(box.size.x * 0.8, -0.32 * H)
	ci.draw_line(box.position + Vector2(box.size.x - 3, 0), tip, Color("9aa0a6"), 1.5, true)
	if str(pose.get("headphones", "")) == "head":
		var ear := _HP(-0.07, 0.15)
		var jack := box.position + Vector2(4, 2)
		var sag := ear.lerp(jack, 0.5) + Vector2(-0.03 * H, 0.03 * H)
		var cord := smooth(PackedVector2Array([ear, sag, jack]), 6, false)
		ci.draw_polyline(cord, Color("1a1a1c"), 1.6, true)
		var tape: Color = pose.get("cord_tape", Color(0, 0, 0, 0))
		if tape.a > 0.0:
			ci.draw_circle(cord[int(cord.size() * 0.45)], 0.012 * H, tape)


## A blanket round the shoulders, held closed at the front: over the arms.
func _blanket(pose: Dictionary) -> void:
	var c: Color = pose.get("blanket", Color(0, 0, 0, 0))
	if c.a <= 0.0:
		return
	var pts := smooth(_map_T([Vector2(-0.112, -0.302), Vector2(-0.03, -0.33), Vector2(0.05, -0.322), Vector2(0.104, -0.27),
		Vector2(0.122, -0.15), Vector2(0.118, -0.02), Vector2(0.1, 0.07), Vector2(0.0, 0.09), Vector2(-0.12, 0.075),
		Vector2(-0.138, -0.06), Vector2(-0.134, -0.2)]), 3)
	fill(pts, c, 0.12, 0.2)
	if flat:
		return
	# Folds, a striped border down the front edge, and her hand holding it shut.
	for k in 4:
		line(_map_T([Vector2(-0.1 + k * 0.05, -0.27 + k * 0.006), Vector2(-0.11 + k * 0.052, 0.06)]), c.darkened(0.28), 1.2)
	line(_map_T([Vector2(0.09, -0.29), Vector2(0.112, -0.15), Vector2(0.104, 0.06)]), c.lightened(0.35), 3.0)
	line(_map_T([Vector2(0.084, -0.29), Vector2(0.104, -0.15), Vector2(0.096, 0.06)]), c.darkened(0.45), 1.4)
	ci.draw_circle(_T(0.108, -0.2), 0.016 * H, _skin())


func _elbow(a: Array, far: bool) -> Vector2:
	var sh := _T(-0.014, -0.266) + (Vector2(-3.0, 1.0) if far else Vector2.ZERO)
	return sh + dir(a[0]) * UPPER_ARM * H


func _wrist(a: Array, far: bool) -> Vector2:
	return _elbow(a, far) + dir(a[0] + a[1]) * FOREARM * H
