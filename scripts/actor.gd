class_name Actor
extends Node2D
## A character drawn from flat shapes: Mara, Tomas, Sollen, June, Ruth, Cal,
## Eighty-One, townspeople, the body, or a silhouette. The origin is between
## the feet, on the floor.

var kind := "mara"
var facing := 1
var walking := false
var speed := 280.0
var headphones := false
## Red tape around Mara's wrist once she starts crossing (transparent = none).
var wrist_tape := Color(0, 0, 0, 0)
## Mara holds the flashlight out in front of her.
var holding_light := false
## Sitting on a chair (the chair itself is the room's to draw).
var seated := false
var step_sound := "step"
var _phase := 0.0
var _t := 0.0
var _step_acc := 0.0
var _tween: Tween


func face(dir: int) -> void:
	if dir != 0:
		facing = 1 if dir > 0 else -1


## Walks horizontally to x. Awaitable; a newer walk_to cancels an older one.
func walk_to(x: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var dist := absf(x - position.x)
	if dist < 3.0:
		walking = false
		return
	face(1 if x > position.x else -1)
	walking = true
	_tween = create_tween()
	_tween.tween_property(self, "position:x", x, dist / speed)
	await _tween.finished
	walking = false


func _process(delta: float) -> void:
	_t += delta
	if walking:
		_phase += delta * 8.5
		_step_acc += delta
		if _step_acc >= 0.37:
			_step_acc = 0.0
			Audio.sfx(step_sound, -15.0, randf_range(0.9, 1.1))
	else:
		_phase = 0.0
		_step_acc = 0.3
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	match kind:
		"mara":
			_person(_colors(false), true)
		"mara_1980":
			_person(_colors(true), false)
		"silhouette":
			_person(_flat(Color("070a10")), false)
		"tomas":
			_tomas()
		"body":
			_body()
		"sollen_asleep":
			_sollen_asleep()
		"june":
			_person(_june(), false)
		"ruth":
			_person(_ruth(false), false)
		"ruth_1980":
			_person(_ruth(true), false)
		"eighty_one":
			_person(_eighty_one(), false)
		"cal_asleep":
			_cal_asleep()
		"townsman":
			_person(_townsman(Color("4a3a2e"), Color("8aa0c8")), false)
		"husband":
			_person(_townsman(Color("2e3a4a"), Color("c8b48a")), false)
		"townswoman":
			_person(_townswoman(), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _colors(year_1980: bool) -> Dictionary:
	return {
		"skin": Color("d8a688"),
		"hair": Color("3b2a22"),
		"eye": Color("1d1512"),
		"pants": Color("2a3242"),
		"boots": Color("17181c"),
		"jacket": Color("2f4c70") if year_1980 else Color("5d5a3b"),
		"sleeve": Color("2a4566") if year_1980 else Color("55523a"),
		"belt": Color("4b3524"),
	}


func _june() -> Dictionary:
	return {
		"skin": Color("e0b8a0"), "hair": Color("c9c6c0"), "eye": Color("1d1512"),
		"pants": Color("3a3440"), "boots": Color("2a221c"), "jacket": Color("7a6a2e"),
		"sleeve": Color("6e5f28"), "belt": Color("4b3524"),
		"style": "bun", "glasses": true, "skirt": Color("3a3440"),
	}


func _ruth(young: bool) -> Dictionary:
	return {
		"skin": Color("dcab8e"), "hair": Color("4a3428") if young else Color("7d6a5e"), "eye": Color("1d1512"),
		"pants": Color("d9c7b0"), "boots": Color("1d1d22"), "jacket": Color("8fb0c4"),
		"sleeve": Color("86a6ba"), "belt": Color("4b3524"),
		"style": "bob", "skirt": Color("8fb0c4"), "apron": Color("efece4"),
	}


func _eighty_one() -> Dictionary:
	return {
		"skin": Color("d2a084"), "hair": Color("3b2a22"), "hair2": Color("8a8580"), "eye": Color("1d1512"),
		"pants": Color("23262e"), "boots": Color("17181c"), "jacket": Color("2c2e33"),
		"sleeve": Color("26282d"), "belt": Color("4b3524"),
		"style": "long", "gauze": true, "long_coat": true,
	}


func _townsman(coat: Color, pj: Color) -> Dictionary:
	return {
		"skin": Color("d9a98a"), "hair": Color("4a3e36"), "eye": Color("1d1512"),
		"pants": pj, "boots": Color("5a4a40"), "jacket": coat, "sleeve": coat.darkened(0.08),
		"belt": coat, "style": "short", "stripes": pj.darkened(0.3), "long_coat": true, "mustache": true,
	}


func _townswoman() -> Dictionary:
	return {
		"skin": Color("e0b29a"), "hair": Color("6a4a3a"), "eye": Color("1d1512"),
		"pants": Color("d8c8d8"), "boots": Color("6a5a5a"), "jacket": Color("5a3a4a"),
		"sleeve": Color("52354a"), "belt": Color("5a3a4a"),
		"style": "bob", "skirt": Color("d8c8d8"), "long_coat": true,
	}


func _flat(c: Color) -> Dictionary:
	return {"skin": c, "hair": c, "eye": c, "pants": c, "boots": c, "jacket": c, "sleeve": c, "belt": c}


func _leg(hip: Vector2, ang: float, length: float, col: Color, boot: Color) -> void:
	var dir := Vector2(sin(ang), cos(ang))
	var knee := hip + dir * length * 0.5 + Vector2(2.0, 0.0)
	var foot := hip + dir * length
	draw_line(hip, knee, col, 15.0)
	draw_line(knee, foot, col, 13.0)
	draw_circle(knee, 6.5, col)
	draw_rect(Rect2(foot.x - 7.0, foot.y - 9.0, 21.0, 10.0), boot)


func _arm(shoulder: Vector2, ang: float, sleeve: Color, hand: Color, tape: Color = Color(0, 0, 0, 0), torch: bool = false) -> void:
	var dir := Vector2(sin(ang), cos(ang))
	var tip := shoulder + dir * 56.0
	draw_line(shoulder, tip, sleeve, 12.0)
	draw_circle(shoulder, 6.0, sleeve)
	if tape.a > 0.0:
		draw_line(shoulder + dir * 43.0, shoulder + dir * 51.0, tape, 13.0)
	if torch:
		draw_line(tip - dir * 4.0, tip + dir * 20.0, Color("2b2d31"), 9.0)
		draw_line(tip + dir * 18.0, tip + dir * 24.0, Color("4a4d52"), 12.0)
		draw_circle(tip + dir * 25.0, 5.0, Color("fff2c8"))
	draw_circle(tip, 6.0, hand)


func _person(c: Dictionary, toolbelt: bool) -> void:
	var swing := sin(_phase) * 0.42
	var bob := absf(sin(_phase)) * 3.0 if walking else sin(_t * 1.8) * 0.8
	# Seated: the upper body drops by `drop` and the legs bend at the knee.
	var drop := 38.0 if seated else 0.0
	var hip := Vector2(0.0, -88.0 + drop)
	var sh := Vector2(0.0, -146.0 - bob + drop)
	var y0 := drop - bob
	var skirt: Color = c.get("skirt", Color(0, 0, 0, 0))
	if seated:
		_seated_leg(hip + Vector2(-3, 0), c.pants.darkened(0.25), c.boots)
	else:
		_leg(hip + Vector2(-3, 0), -swing, 88.0, c.pants.darkened(0.25), c.boots)
	_arm(sh + Vector2(-5, 0), swing * 0.8, c.sleeve.darkened(0.25), c.skin.darkened(0.2))
	if c.get("long_coat", false) and not seated:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-21, -40 + y0), Vector2(21, -40 + y0), Vector2(19, -90 + y0), Vector2(-20, -90 + y0)]), c.jacket.darkened(0.1))
	var torso := PackedVector2Array([
		Vector2(-19, -86 + y0), Vector2(19, -86 + y0), Vector2(16, -152 + y0), Vector2(-17, -152 + y0)])
	draw_colored_polygon(torso, c.jacket)
	draw_line(Vector2(9, -90 + y0), Vector2(8, -150 + y0), c.jacket.darkened(0.22), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -152 + y0), Vector2(12, -152 + y0), Vector2(6, -140 + y0), Vector2(-6, -140 + y0)]), c.jacket.lightened(0.12))
	if c.has("apron"):
		draw_colored_polygon(PackedVector2Array([
			Vector2(-4, -126 + y0), Vector2(18, -126 + y0), Vector2(20, -88 + y0), Vector2(-6, -88 + y0)]), c.apron)
	if toolbelt:
		draw_rect(Rect2(-20, -99 + y0, 40, 8), c.belt)
		draw_rect(Rect2(6, -99 + y0, 11, 15), c.belt.darkened(0.15))
	if seated:
		_seated_leg(hip + Vector2(3, 0), c.pants, c.boots)
	else:
		_leg(hip + Vector2(3, 0), swing, 88.0, c.pants, c.boots)
	if skirt.a > 0.0 and not seated:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-19, -88 + y0), Vector2(19, -88 + y0), Vector2(25, -38 + y0), Vector2(-24, -38 + y0)]), skirt)
		if c.has("apron"):
			draw_colored_polygon(PackedVector2Array([
				Vector2(-4, -88 + y0), Vector2(20, -88 + y0), Vector2(22, -46 + y0), Vector2(-6, -46 + y0)]), c.apron)
	if c.has("stripes") and not seated:
		for k in 4:
			var yy := -30.0 - k * 14.0
			draw_line(Vector2(-12, yy), Vector2(14, yy), c.stripes, 3.0)
	draw_rect(Rect2(-5, -163 + y0, 10, 13), c.skin)
	var hc := Vector2(2, -175 + y0)
	_hair_back(hc, c)
	draw_circle(hc + Vector2(3, 1), 13.5, c.skin)
	_hair_front(hc, c)
	draw_circle(hc + Vector2(10, -1), 1.8, c.eye)
	if c.get("glasses", false):
		draw_arc(hc + Vector2(9, -1), 4.5, 0.0, TAU, 10, Color("3a3a3a"), 1.5)
		draw_line(hc + Vector2(4, -2), hc + Vector2(-4, -3), Color("3a3a3a"), 1.2)
	if c.get("mustache", false):
		draw_line(hc + Vector2(8, 7), hc + Vector2(15, 7), c.hair, 2.5)
	if headphones:
		draw_arc(hc + Vector2(-2, 0), 17.0, PI * 1.08, PI * 1.92, 14, Color("23262b"), 4.0)
		draw_rect(Rect2(hc.x - 11, hc.y - 3, 9, 13), Color("2c3036"))
	var gauze: bool = c.get("gauze", false)
	var front_hand: Color = Color("ece9e0") if gauze else c.skin
	if holding_light:
		_arm(sh + Vector2(5, 0), 1.4 + sin(_t * 1.6) * 0.03, c.sleeve, c.skin, wrist_tape, true)
	else:
		_arm(sh + Vector2(5, 0), -swing * 0.8, c.sleeve, front_hand, wrist_tape)
		if gauze:
			var dir := Vector2(sin(-swing * 0.8), cos(-swing * 0.8))
			draw_line(sh + Vector2(5, 0) + dir * 40.0, sh + Vector2(5, 0) + dir * 56.0, Color("ece9e0"), 12.0)


func _seated_leg(hip: Vector2, col: Color, boot: Color) -> void:
	var knee := hip + Vector2(40.0, 0.0)
	var foot := Vector2(knee.x + 4.0, 0.0)
	draw_line(hip, knee, col, 15.0)
	draw_line(knee, foot, col, 13.0)
	draw_circle(knee, 7.0, col)
	draw_rect(Rect2(foot.x - 7.0, foot.y - 9.0, 21.0, 10.0), boot)


func _hair_back(hc: Vector2, c: Dictionary) -> void:
	var style: String = c.get("style", "mara")
	match style:
		"bun":
			draw_circle(hc + Vector2(-3, -2), 15.0, c.hair)
			draw_circle(hc + Vector2(-12, -12), 8.0, c.hair)
		"bob":
			draw_circle(hc + Vector2(-2, 0), 16.5, c.hair)
			draw_rect(Rect2(hc.x - 17, hc.y - 2, 22, 18), c.hair)
		"long":
			draw_circle(hc + Vector2(-3, -1), 16.0, c.hair)
			draw_colored_polygon(PackedVector2Array([
				hc + Vector2(-17, -2), hc + Vector2(4, -2), hc + Vector2(2, 34), hc + Vector2(-19, 30)]), c.hair)
			if c.has("hair2"):
				draw_line(hc + Vector2(-10, -12), hc + Vector2(-14, 26), c.hair2, 3.0)
		"short":
			draw_circle(hc + Vector2(-2, -2), 14.5, c.hair)
		_:
			draw_circle(hc + Vector2(-3, -2), 15.5, c.hair)


func _hair_front(hc: Vector2, c: Dictionary) -> void:
	var style: String = c.get("style", "mara")
	match style:
		"bun", "short":
			draw_colored_polygon(PackedVector2Array([
				hc + Vector2(-14, -5), hc + Vector2(-3, -15), hc + Vector2(12, -11), hc + Vector2(13, -7), hc + Vector2(-4, -9)]), c.hair)
		"bob", "long":
			draw_colored_polygon(PackedVector2Array([
				hc + Vector2(-15, -5), hc + Vector2(-3, -16), hc + Vector2(13, -11), hc + Vector2(15, -2), hc + Vector2(4, -8)]), c.hair)
			if c.has("hair2"):
				draw_line(hc + Vector2(-2, -14), hc + Vector2(8, -10), c.hair2, 3.0)
		_:
			draw_colored_polygon(PackedVector2Array([
				hc + Vector2(-15, -5), hc + Vector2(-3, -16), hc + Vector2(13, -11), hc + Vector2(14, -5), hc + Vector2(-4, -8)]), c.hair)
			draw_colored_polygon(PackedVector2Array([
				hc + Vector2(-14, -3), hc + Vector2(-27, 9), hc + Vector2(-23, 17), hc + Vector2(-11, 5)]), c.hair)



func _tomas() -> void:
	var parka := Color("b4352b")
	var jeans := Color("3a4d70")
	var boots := Color("1b1c20")
	var skin := Color("d9aa8c")
	var bob := sin(_t * 2.2) * 0.8
	var hip := Vector2(0, -64)
	_leg(hip + Vector2(-3, 0), 0.0, 64.0, jeans.darkened(0.25), boots)
	_leg(hip + Vector2(3, 0), 0.0, 64.0, jeans, boots)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-19, -60 - bob), Vector2(19, -60 - bob), Vector2(16, -114 - bob), Vector2(-16, -114 - bob)]), parka)
	draw_line(Vector2(-18, -80 - bob), Vector2(18, -80 - bob), parka.darkened(0.18), 2.0)
	var hc := Vector2(2, -128 - bob)
	draw_circle(hc, 17.0, Color("d8ccb2"))
	draw_circle(hc + Vector2(2, 1), 12.0, skin)
	draw_colored_polygon(PackedVector2Array([
		hc + Vector2(-11, -4), hc + Vector2(-2, -13), hc + Vector2(11, -9), hc + Vector2(12, -4)]), Color("5a3b28"))
	draw_circle(hc + Vector2(9, 0), 1.6, Color("1d1512"))
	draw_arc(hc + Vector2(-2, 0), 15.0, PI * 1.08, PI * 1.92, 12, Color("202226"), 4.0)
	draw_rect(Rect2(hc.x - 10, hc.y - 3, 8, 12), Color("2a2d33"))
	draw_line(Vector2(0, -108 - bob), Vector2(22, -88 - bob), parka.darkened(0.1), 11.0)
	draw_rect(Rect2(16, -100 - bob, 32, 21), Color("4a5a3a"))
	draw_circle(Vector2(26, -90 - bob), 4.0, Color("c8c39f"))
	draw_line(Vector2(44, -100 - bob), Vector2(56, -146 - bob), Color("9aa0a6"), 2.0)
	draw_circle(Vector2(24, -86 - bob), 5.5, skin)


func _body() -> void:
	# Slumped against the console: legs out to the right, torso leaning back to the left.
	var c := _colors(false)
	draw_line(Vector2(-6, -14), Vector2(56, -10), c.pants.darkened(0.2), 15.0)
	draw_line(Vector2(56, -10), Vector2(94, -6), c.pants.darkened(0.2), 13.0)
	draw_rect(Rect2(92, -18, 10, 18), c.boots)
	draw_line(Vector2(-2, -8), Vector2(64, -5), c.pants, 15.0)
	draw_line(Vector2(64, -5), Vector2(104, -2), c.pants, 13.0)
	draw_rect(Rect2(102, -14, 10, 14), c.boots)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -10), Vector2(16, -10), Vector2(-4, -74), Vector2(-34, -66)]), c.jacket)
	draw_rect(Rect2(-17, -22, 34, 8), c.belt)
	draw_circle(Vector2(-8, -44), 8.0, Color(0.2, 0.07, 0.06, 0.9))
	draw_circle(Vector2(-3, -38), 5.0, Color(0.2, 0.07, 0.06, 0.8))
	var hc := Vector2(-29, -86)
	draw_circle(hc + Vector2(-3, -2), 15.0, c.hair)
	draw_circle(hc + Vector2(2, 2), 13.0, c.skin)
	draw_line(hc + Vector2(6, 0), hc + Vector2(11, 1), c.eye, 1.5)
	draw_arc(Vector2(-21, -70), 12.0, 0.2, PI - 0.2, 10, Color("23262b"), 4.0)
	# Left arm on the floor, blue tape at the wrist.
	var sh := Vector2(-26, -66)
	var elbow := Vector2(-44, -30)
	var hand := Vector2(-60, -4)
	draw_line(sh, elbow, c.sleeve.darkened(0.15), 12.0)
	draw_line(elbow, hand, c.sleeve.darkened(0.15), 11.0)
	draw_line(elbow.lerp(hand, 0.62), elbow.lerp(hand, 0.82), Color("2f63c9"), 13.0)
	draw_circle(hand, 6.0, c.skin)
	# Right arm in the lap, watch at the wrist.
	var sh2 := Vector2(-8, -70)
	var hand2 := Vector2(30, -18)
	draw_line(sh2, hand2, c.sleeve, 12.0)
	draw_rect(Rect2(17, -32, 10, 10), Color("c7c2b0"))
	draw_circle(hand2, 6.0, c.skin)


func _sollen_asleep() -> void:
	# Lying on his back along the couch, head to the left, a blanket to the chest.
	var breath := sin(_t * 1.1) * 1.6
	var skin := Color("d4a386")
	var beard := Color("b9b4ab")
	var cardigan := Color("6b4f36")
	var blanket := Color("4a5a48")
	draw_rect(Rect2(-92, -38 - breath * 0.4, 70, 26), cardigan)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30, -40 - breath), Vector2(118, -34), Vector2(124, -10), Vector2(-30, -10)]), blanket)
	draw_line(Vector2(-28, -40 - breath), Vector2(120, -34), blanket.lightened(0.12), 3.0)
	draw_rect(Rect2(118, -26, 16, 16), Color("1b1c20"))
	var hc := Vector2(-108, -34)
	draw_circle(hc, 15.0, skin)
	draw_circle(hc + Vector2(-6, -6), 11.0, beard)
	draw_colored_polygon(PackedVector2Array([
		hc + Vector2(-2, 6), hc + Vector2(14, 4), hc + Vector2(16, 14), hc + Vector2(2, 16)]), beard)
	draw_line(hc + Vector2(4, -8), hc + Vector2(13, -6), Color("2a2a2a"), 2.0)
	draw_arc(hc + Vector2(8, -6), 4.0, 0.0, TAU, 10, Color("8a8f96"), 1.5)
	# One arm hanging off the couch.
	draw_line(Vector2(-70, -26), Vector2(-62, 4), cardigan.darkened(0.15), 10.0)
	draw_circle(Vector2(-62, 6), 5.5, skin)


func _cal_asleep() -> void:
	# Deputy Cal, slumped forward in his chair, head on his folded arms on the desk.
	# The desk top is the room's, about 96 px above the floor, in front of him.
	var breath := sin(_t * 1.0) * 1.4
	var shirt := Color("b49a6a")
	var pants := Color("4a3a2a")
	var skin := Color("d9a98a")
	var hair := Color("3a2a1e")
	_seated_leg(Vector2(-24, -50), pants.darkened(0.2), Color("17181c"))
	_seated_leg(Vector2(-18, -50), pants, Color("17181c"))
	# His back rises above the desk top; arms folded on it, head on his arms.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-36, -48), Vector2(-4, -48), Vector2(34, -104 - breath), Vector2(-2, -130 - breath)]), shirt)
	draw_rect(Rect2(-12, -110 - breath, 8, 8), Color("c9a332"))
	draw_line(Vector2(10, -112 - breath), Vector2(60, -108), shirt.darkened(0.1), 12.0)
	draw_line(Vector2(18, -118 - breath), Vector2(64, -114), shirt, 12.0)
	draw_circle(Vector2(64, -111), 6.0, skin)
	var hc := Vector2(42, -124 - breath * 0.6)
	draw_circle(hc, 14.0, hair)
	draw_circle(hc + Vector2(6, 4), 10.0, skin)
	draw_line(hc + Vector2(8, 10), hc + Vector2(15, 10), hair, 2.5)
