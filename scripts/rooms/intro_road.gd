extends Room
## The opening, part 2: up the mountain. Mara's truck climbs the service road
## through the trees, its headlights find the sign, and she parks by the outer
## gate. Tomas waits in the heated cab while she goes in to finish the repair:
## tools on a workbench, a receiver lighting up at last, snow collecting on
## the windscreen. When she comes back out, it's after two.
## A short film: no taps needed.

const SPEED := 230.0
const GRADE := 0.06
## Where the sign stands along the road (px of scroll).
const SIGN_AT := 2350.0

var shot := ""
var scroll := 0.0
var _shot_t := 0.0
var _truck_x := 0.0
var _truck_v := 0.0
var _flakes := PackedVector3Array()
var mara_out: Actor
var snow: Snowfall


func setup() -> void:
	shows_hud = false
	is_story_room = false
	place_name = ""
	base_tint = Color(0.86, 0.9, 1.0)
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 790)
	snow.count = 160
	snow.wind = -60.0
	snow.speed = 70.0
	add_child(snow)
	mara_out = add_actor("mara_1980", 170.0, 1)
	mara_out.visible = false
	mara_out.step_sound = "step_snow"


func score_quiet() -> bool:
	return true


func on_arrive() -> void:
	Audio.stop_all(0.2)
	Audio.play_loop("truck_idle", -18.0, 0.6)
	Audio.set_loop_pitch("truck_idle", 1.32, 0.0)
	Audio.play_loop("wind", -22.0)
	# The climb, and the sign in the headlights.
	_cut("climb")
	await wait(9.2)
	# The outer gate: she parks, and goes in.
	await _fade_cut("gate")
	_truck_x = -620.0
	_truck_v = 300.0
	Audio.set_loop_pitch("truck_idle", 1.1, 2.4)
	await wait(2.6)
	Audio.set_loop_pitch("truck_idle", 1.0, 0.8)
	await wait(0.6)
	Audio.sfx("door", -12.0)
	mara_out.position.x = _truck_x + 120.0
	mara_out.visible = true
	hud.caption("Mara parks beside the outer gate. Tomas waits in the heated cab while she goes in to finish the repair.", 5.0)
	mara_out.walk_to(1380.0)
	await wait(5.4)
	# Inside: the workbench, receiver 2.
	Audio.stop_loop("truck_idle", 0.6)
	Audio.stop_loop("wind", 0.6)
	await _fade_cut("bench")
	Audio.play_loop("hum", -26.0)
	await wait(1.6)
	Audio.sfx("powerup", -10.0)
	await wait(2.4)
	# Out in the cab, the snow piling up on the glass.
	Audio.stop_loop("hum", 0.5)
	await _fade_cut("windscreen")
	Audio.play_loop("truck_idle", -30.0, 0.4)
	Audio.play_loop("wind", -26.0, 0.4)
	Audio.play_loop("static", -34.0, 0.4)
	await wait(5.0)
	await hud.fade_out(0.9)
	Audio.stop_all(0.6)
	await hud.card("A little after two", "", 1.4)
	main.change_room("snowfield_1980", "intro")


func _cut(s: String) -> void:
	shot = s
	_shot_t = 0.0
	_flakes.clear()
	snow.visible = s in ["climb", "gate"]
	# The bench and the windscreen keep their picture; only what moves redraws.
	animated_back = s in ["climb", "gate", ""]


func static_key() -> String:
	return "%s|%s" % [shot, shot == "bench" and _shot_t > 1.6]


func _fade_cut(s: String) -> void:
	await hud.fade_out(0.45)
	_cut(s)
	await hud.fade_in(0.45)


func _process(delta: float) -> void:
	super(delta)
	_shot_t += delta
	match shot:
		"climb":
			scroll += SPEED * delta
		"gate":
			if _truck_x < 50.0:
				_truck_v = maxf(26.0, _truck_v - delta * 95.0)
				_truck_x = minf(50.0, _truck_x + _truck_v * delta)
		"windscreen":
			# Flakes land on the glass and stay.
			if _flakes.size() < 260 and randf() < delta * 60.0:
				_flakes.append(Vector3(randf_range(200, 1080), randf_range(150, 540), randf_range(1.2, 3.2)))


func draw_back() -> void:
	match shot:
		"climb":
			_draw_climb()
		"gate":
			IntroArt.clearing(cv)
			IntroArt.gate(cv)
			IntroArt.mast_lights(cv, t)
			var parked := _truck_x >= 50.0
			Vehicles.pickup(cv, Vector2(_truck_x, 646), 1.0, t, {"engine": true, "lights": true, "beam": 560.0 if parked else 360.0,
				"snow": 0.4, "travel": _truck_x, "cab": ["tomas"] if mara_out.visible else ["mara", "tomas"]})
		"bench":
			_draw_bench()
		"windscreen":
			_draw_windscreen()
		_:
			cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 900), Color.BLACK)


func _draw_climb() -> void:
	IntroArt.road(cv, scroll, GRADE)
	var sx := SIGN_AT - scroll + 640.0
	var road_y := 600.0 - (sx - 640.0) * tan(GRADE)
	# Lit while it's in the beam ahead of the truck.
	var lit := clampf(1.0 - absf(sx - 1030.0) / 300.0, 0.0, 1.0)
	IntroArt.service_sign(cv, Vector2(sx, road_y - 6.0), lit)
	var bob := sin(t * 9.0) * 1.2
	Vehicles.pickup(cv, Vector2(560, 600.0 + 14.0 + bob), 1.0, t, {"engine": true, "lights": true, "beam": 520.0,
		"snow": 0.3, "tilt": GRADE, "travel": scroll, "cab": ["mara", "tomas"]})


## Receiver 2 on the workshop bench with its cover off, under the bench lamp,
## Mara's tools round it. At 1.6 s it comes on: the tubes glow, the dial lights
## up, the meters wake.
const RX := Rect2(352, 214, 576, 250)


func _draw_bench() -> void:
	var on := _shot_t > 1.6
	# The workshop wall: painted block, a pegboard of tools.
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 900), Color("18201f"), Color("2a3431"))
	for row in 12:
		var y := -60.0 + row * 46.0
		cv.draw_line(Vector2(Kit.L, y), Vector2(Kit.R, y), Color(0, 0, 0, 0.18), 2.0)
		var off := 0.0 if row % 2 == 0 else 60.0
		for k in 20:
			var x := Kit.L + off + k * 120.0
			cv.draw_line(Vector2(x, y), Vector2(x, y + 46), Color(0, 0, 0, 0.12), 2.0)
	var peg := Rect2(110, 30, 1060, 250)
	cv.draw_rect(peg.grow(6), Color("3a2e22"))
	Kit.vgrad(cv, peg, Color("7a6448"), Color("5e4c36"))
	for row in 9:
		for k in 38:
			cv.draw_rect(Rect2(peg.position.x + 14 + k * 28, peg.position.y + 14 + row * 27, 3, 3), Color(0.12, 0.09, 0.06, 0.8))
	_pegboard_tools(peg)
	# The lamp hanging over the bench, and its light.
	cv.draw_line(Vector2(640, -100), Vector2(640, 40), Color("101414"), 2.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(640, 40), Vector2(724, 94), Vector2(556, 94)]), Color("2e4a3e"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(640, 40), Vector2(724, 94), Vector2(700, 94)]), Color("3e5e50"))
	cv.draw_rect(Rect2(626, 32, 28, 12), Color("1e2a26"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(566, 94), Vector2(714, 94), Vector2(1060, 520), Vector2(220, 520)]), Color(1.0, 0.92, 0.72, 0.07))
	Kit.soft_glow(cv, Vector2(640, 96), 70.0, Color(1.0, 0.94, 0.78, 0.8))
	cv.draw_circle(Vector2(640, 96), 12.0, Color("fff6dc"))
	_receiver(on)
	# The bench: a thick top worn pale along the front, the shadow under the set.
	cv.draw_rect(Rect2(Kit.L, 470, Kit.R - Kit.L, 28), Color("8a6440"))
	for k in 9:
		var y2 := 474.0 + k * 2.6
		cv.draw_line(Vector2(Kit.L, y2 + sin(k) * 1.5), Vector2(Kit.R, y2 - sin(k * 1.7) * 1.5), Color(0.36, 0.24, 0.14, 0.35), 1.0)
	cv.draw_line(Vector2(Kit.L, 471), Vector2(Kit.R, 471), Color("b08a5e"), 2.0)
	Kit.vgrad(cv, Rect2(Kit.L, 498, Kit.R - Kit.L, 300), Color("3a2818"), Color("1c140c"))
	cv.draw_set_transform(Vector2(640, 472), 0.0, Vector2(1.0, 0.08))
	Kit.soft_glow(cv, Vector2.ZERO, 340.0, Color(0, 0, 0, 0.5))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_bench_tools(on)


## Silhouettes on the pegboard: wrench, pliers, screwdrivers, a coil of wire,
## a clipboard.
func _pegboard_tools(peg: Rect2) -> void:
	var c := Color(0.14, 0.12, 0.1)
	var x := peg.position.x + 50.0
	# Spanners, largest to smallest.
	for k in 4:
		var l := 120.0 - k * 18.0
		var p := Vector2(x + k * 34.0, peg.position.y + 40)
		cv.draw_line(p, p + Vector2(0, l), Color("8a8e92"), 7.0 - k)
		cv.draw_arc(p, 11.0 - k, PI * 0.2, PI * 1.8, 10, Color("8a8e92"), 5.0)
	# Pliers.
	var pl := Vector2(peg.position.x + 230, peg.position.y + 36)
	cv.draw_line(pl, pl + Vector2(-14, 110), Color("b8322c"), 7.0)
	cv.draw_line(pl, pl + Vector2(14, 110), Color("b8322c"), 7.0)
	cv.draw_line(pl + Vector2(-3, -26), pl + Vector2(3, 0), Color("8a8e92"), 6.0)
	# Screwdrivers.
	for k in 5:
		var sp := Vector2(peg.position.x + 300 + k * 26, peg.position.y + 30)
		cv.draw_line(sp, sp + Vector2(0, 46), [Color("d8b830"), Color("2a5a9a"), Color("b8322c"), Color("2a7a4a"), Color("d8b830")][k], 9.0)
		cv.draw_line(sp + Vector2(0, 46), sp + Vector2(0, 104 - k * 6), Color("a8acb0"), 3.0)
	# A coil of red wire and one of black.
	for k in 2:
		var cc := Vector2(peg.position.x + 520 + k * 96, peg.position.y + 96)
		for r in 5:
			cv.draw_arc(cc, 34.0 - r * 3.0, 0.0, TAU, 28, Color("9a2a22") if k == 0 else Color("1e1e1e"), 3.0)
		cv.draw_line(cc + Vector2(0, -36), cc + Vector2(0, -60), c, 2.0)
	# The clipboard: the repair log, ticked.
	var cb := Rect2(peg.position.x + 760, peg.position.y + 26, 120, 160)
	cv.draw_rect(cb, Color("8a6a3a"))
	cv.draw_rect(Rect2(cb.position + Vector2(8, 18), Vector2(104, 134)), Color("e8e2d0"))
	cv.draw_rect(Rect2(cb.position + Vector2(40, -6), Vector2(40, 16)), Color("9aa0a6"))
	Kit.text(cv, cb.position + Vector2(14, 36), "RX-2 LOG", 11, Color("3a3a3a"))
	for k in 7:
		var ly := cb.position.y + 50 + k * 14
		cv.draw_line(Vector2(cb.position.x + 30, ly), Vector2(cb.position.x + 100 - (k % 3) * 14, ly), Color(0.25, 0.25, 0.3, 0.7), 1.0)
		cv.draw_line(Vector2(cb.position.x + 16, ly - 3), Vector2(cb.position.x + 20, ly + 1), Color("2a4a8a"), 1.5)
		cv.draw_line(Vector2(cb.position.x + 20, ly + 1), Vector2(cb.position.x + 26, ly - 7), Color("2a4a8a"), 1.5)
	# A hand drill.
	var dr := Vector2(peg.position.x + 960, peg.position.y + 60)
	cv.draw_rect(Rect2(dr, Vector2(60, 26)), Color("4a5258"))
	cv.draw_line(dr + Vector2(60, 13), dr + Vector2(84, 13), Color("a8acb0"), 4.0)
	cv.draw_colored_polygon(PackedVector2Array([dr + Vector2(12, 26), dr + Vector2(34, 26), dr + Vector2(30, 90), dr + Vector2(10, 90)]), Color("2a2e32"))


## The receiver: a rack set with its lid off, so the tubes show above the
## panel; a brushed panel with the tuning dial, two meters, five knobs and the
## power lamp. Its needles and the glow of its tubes are on the moving layer.
func _receiver(on: bool) -> void:
	var r := RX
	# The chassis top, seen over the panel: the lid's off.
	var top := PackedVector2Array([r.position + Vector2(20, -46), Vector2(r.end.x - 20, r.position.y - 46), Vector2(r.end.x, r.position.y), r.position])
	cv.draw_colored_polygon(top, Color("3a4246"))
	for k in 6:
		var tx := r.position.x + 80 + k * 84.0
		var ty := r.position.y - 20.0
		_tube(Vector2(tx, ty), on, k)
	cv.draw_rect(Rect2(r.end.x - 120, r.position.y - 34, 80, 26), Color("5a6066"))
	Kit.text(cv, Vector2(r.end.x - 116, r.position.y - 16), "TRANSFMR", 9, Color("2a2e32"))
	# The panel.
	Kit.vgrad(cv, r, Color("b4bab8"), Color("858c8a"))
	for k in 60:
		cv.draw_line(Vector2(r.position.x, r.position.y + 2 + k * 4.1), Vector2(r.end.x, r.position.y + 2 + k * 4.1), Color(1, 1, 1, 0.05 if k % 2 else 0.0), 1.0)
	cv.draw_rect(r, Color("4a5052"), false, 3.0)
	# Rack ears with their handles and screws.
	for side in [-1, 1]:
		var ex := r.position.x - 30.0 if side < 0 else r.end.x
		cv.draw_rect(Rect2(ex, r.position.y, 30, r.size.y), Color("9aa0a0"))
		cv.draw_rect(Rect2(ex + 8, r.position.y + 30, 14, r.size.y - 60), Color("70777a"))
		for y in [r.position.y + 16, r.end.y - 16]:
			cv.draw_circle(Vector2(ex + 15, y), 5.0, Color("5a6062"))
			cv.draw_line(Vector2(ex + 11, y), Vector2(ex + 19, y), Color("2a2e30"), 1.5)
	# The tuning dial: a long window, its scale lit from behind.
	var dial := Rect2(r.position.x + 24, r.position.y + 22, 330, 74)
	cv.draw_rect(dial.grow(5), Color("2a2e30"))
	Kit.vgrad(cv, dial, Color("f2c878") if on else Color("3a3426"), Color("d89a48") if on else Color("2a2620"))
	for k in 31:
		var dx := dial.position.x + 14 + k * 10.0
		var tall := k % 5 == 0
		cv.draw_line(Vector2(dx, dial.position.y + 10), Vector2(dx, dial.position.y + (30 if tall else 20)), Color(0.1, 0.08, 0.05, 0.85), 1.5 if tall else 1.0)
		if tall:
			Kit.text(cv, Vector2(dx - 8, dial.position.y + 48), str(k / 5 * 2 + 4), 12, Color(0.12, 0.09, 0.05, 0.9))
	Kit.text(cv, Vector2(dial.position.x + 8, dial.end.y - 8), "MHz", 10, Color(0.12, 0.09, 0.05, 0.8))
	cv.draw_rect(Rect2(dial.position.x, dial.position.y, dial.size.x, 8), Color(1, 1, 1, 0.12))
	# Two meters.
	for k in 2:
		var m := Rect2(r.position.x + 384 + k * 92, r.position.y + 22, 80, 74)
		cv.draw_rect(m.grow(4), Color("2a2e30"))
		Kit.vgrad(cv, m, Color("f4eedc") if on else Color("8e8a7c"), Color("e2d8bc") if on else Color("7a7668"))
		var pivot := Vector2(m.get_center().x, m.end.y - 10)
		cv.draw_arc(pivot, 44.0, -PI * 0.8, -PI * 0.2, 16, Color(0.15, 0.15, 0.15), 1.5)
		cv.draw_arc(pivot, 44.0, -PI * 0.33, -PI * 0.2, 6, Color("b8322c"), 3.0)
		for j in 7:
			var a := lerpf(-PI * 0.8, -PI * 0.2, j / 6.0)
			cv.draw_line(pivot + Vector2(cos(a), sin(a)) * 40.0, pivot + Vector2(cos(a), sin(a)) * 47.0, Color(0.15, 0.15, 0.15), 1.2)
		Kit.text(cv, Vector2(m.position.x, m.end.y - 22), "VU" if k == 0 else "S", 10, Color(0.2, 0.2, 0.2), HORIZONTAL_ALIGNMENT_CENTER, m.size.x)
	# The knobs, with their names stamped under them.
	var names := ["RF GAIN", "BFO", "AGC", "BAND", "AF GAIN"]
	for k in 5:
		var c := Vector2(r.position.x + 70 + k * 96, r.position.y + 168)
		cv.draw_circle(c + Vector2(2, 3), 27.0, Color(0, 0, 0, 0.3))
		cv.draw_circle(c, 27.0, Color("c8ccca"))
		cv.draw_circle(c, 21.0, Color("1a1c1e"))
		cv.draw_circle(c + Vector2(-5, -6), 9.0, Color("34383a"))
		var a2 := -PI * 0.75 + k * 0.9
		cv.draw_line(c, c + Vector2(cos(a2), sin(a2)) * 19.0, Color("e8e4d8"), 2.5)
		Kit.text(cv, Vector2(c.x - 40, c.y + 46), names[k], 10, Color("2a2e30"), HORIZONTAL_ALIGNMENT_CENTER, 80)
	# Toggle switches and the power lamp.
	for k in 2:
		var sw := Vector2(r.end.x - 120 + k * 34, r.position.y + 150)
		cv.draw_circle(sw, 9.0, Color("6a7072"))
		cv.draw_line(sw, sw + Vector2(0, -20 if on else 20), Color("d8dcdc"), 4.0)
	var lamp := Vector2(r.end.x - 52, r.position.y + 200)
	cv.draw_circle(lamp, 13.0, Color("3a3e40"))
	cv.draw_circle(lamp, 9.0, Color("5ae08a") if on else Color("1e3426"))
	cv.draw_circle(lamp + Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.5))
	Kit.text(cv, Vector2(lamp.x - 34, lamp.y + 30), "POWER", 10, Color("2a2e30"), HORIZONTAL_ALIGNMENT_CENTER, 68)
	# Its name, on a plate under the meters.
	var plate := Rect2(r.position.x + 384, r.position.y + 106, 172, 30)
	cv.draw_rect(plate, Color("1e2224"))
	Kit.text(cv, Vector2(plate.position.x + 10, plate.position.y + 22), "RX-2", 18, Color("d8dcd8"))
	Kit.text(cv, Vector2(plate.position.x + 60, plate.position.y + 19), "HALVARD RADIO OBS.", 8, Color("9aa0a0"))
	if on:
		Kit.soft_glow(cv, lamp, 30.0, Color(0.35, 1.0, 0.55, 0.35))


## A valve standing on the chassis: glass envelope, the plate inside, and
## (when the set's on) the filament's orange glow.
func _tube(base: Vector2, on: bool, k: int) -> void:
	var h := 46.0 + (k % 3) * 8.0
	cv.draw_rect(Rect2(base.x - 15, base.y - 4, 30, 8), Color("2a2a2a"))
	var glass := PackedVector2Array([Vector2(base.x - 12, base.y - 4), Vector2(base.x - 13, base.y - h + 8),
		Vector2(base.x - 8, base.y - h), Vector2(base.x + 8, base.y - h), Vector2(base.x + 13, base.y - h + 8), Vector2(base.x + 12, base.y - 4)])
	cv.draw_colored_polygon(glass, Color(0.75, 0.82, 0.86, 0.22))
	cv.draw_rect(Rect2(base.x - 7, base.y - h + 12, 14, h - 22), Color("4a4e52"))
	if on:
		cv.draw_rect(Rect2(base.x - 3, base.y - h + 18, 6, h - 32), Color(1.0, 0.55, 0.2, 0.9))
		Kit.soft_glow(cv, Vector2(base.x, base.y - h * 0.55), 26.0, Color(1.0, 0.55, 0.2, 0.45))
	cv.draw_polyline(glass, Color(0.85, 0.9, 0.95, 0.5), 1.5, true)
	cv.draw_line(Vector2(base.x - 9, base.y - h + 10), Vector2(base.x - 10, base.y - 10), Color(1, 1, 1, 0.35), 2.0)


## On the bench: the set's lid propped against the wall, the soldering iron
## in its stand, solder, a meter with its probes, a mug, screws in a tin lid,
## the schematic.
func _bench_tools(on: bool) -> void:
	# The schematic, pinned flat under the set's front edge.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(150, 488), Vector2(330, 484), Vector2(342, 512), Vector2(140, 516)]), Color("dfe6e8"))
	for k in 6:
		cv.draw_line(Vector2(160 + k * 28, 490), Vector2(156 + k * 28, 512), Color(0.2, 0.3, 0.6, 0.5), 1.0)
	cv.draw_line(Vector2(150, 500), Vector2(336, 497), Color(0.2, 0.3, 0.6, 0.5), 1.0)
	# The soldering iron in its coil stand, the tip hot.
	cv.draw_rect(Rect2(180, 452, 70, 18), Color("3a3e40"))
	for k in 6:
		cv.draw_arc(Vector2(198 + k * 8, 440), 10.0, 0, TAU, 12, Color("8a8e90"), 2.0)
	cv.draw_line(Vector2(176, 432), Vector2(262, 446), Color("2a5a9a"), 9.0)
	cv.draw_line(Vector2(262, 446), Vector2(300, 452), Color("b8bcbe"), 3.0)
	cv.draw_circle(Vector2(300, 452), 3.0, Color("ff9a4a"))
	cv.draw_line(Vector2(176, 432), Vector2(110, 470), Color("1e1e1e"), 2.0)
	# Solder.
	cv.draw_circle(Vector2(1000, 452), 20.0, Color("9aa0a4"))
	cv.draw_circle(Vector2(1000, 452), 12.0, Color("6a7074"))
	cv.draw_circle(Vector2(1000, 452), 5.0, Color("2a2420"))
	cv.draw_line(Vector2(1016, 460), Vector2(1056, 466), Color("c8ccd0"), 1.5)
	# The meter, yellow, with its probes.
	var mm := Rect2(1066, 392, 74, 78)
	cv.draw_rect(mm, Color("d8b830"))
	cv.draw_rect(mm, Color("8a7418"), false, 2.0)
	cv.draw_rect(Rect2(mm.position + Vector2(10, 10), Vector2(54, 24)), Color("9aa890") if not on else Color("b8c8a8"))
	Kit.text(cv, mm.position + Vector2(14, 30), "12.6" if on else "0.00", 16, Color("1a2418"))
	cv.draw_circle(mm.position + Vector2(37, 54), 12.0, Color("2a2a2a"))
	cv.draw_line(mm.position + Vector2(37, 54), mm.position + Vector2(44, 46), Color("d8d8d8"), 2.0)
	for k in 2:
		var lead := PackedVector2Array()
		for i in 12:
			var u := i / 11.0
			lead.append(Vector2(lerpf(1080.0 + k * 40, 930.0 - k * 60, u), 470 + sin(u * PI) * 16.0 - u * 14.0))
		cv.draw_polyline(lead, Color("b8322c") if k == 0 else Color("1e1e1e"), 2.5, true)
	# The mug, and screws in a tin lid.
	EnvironmentArt.mug(cv, Vector2(1180, 455))
	cv.draw_set_transform(Vector2(900, 466), 0.0, Vector2(1.0, 0.35))
	cv.draw_circle(Vector2.ZERO, 22.0, Color("9a9ea2"))
	cv.draw_circle(Vector2.ZERO, 18.0, Color("6e7276"))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in 5:
		cv.draw_circle(Vector2(890 + k * 5, 464 + (k % 2) * 3), 2.0, Color("c8ccd0"))


## From the driver's seat: snow settling on the windscreen, the observatory
## beyond it (the dish, two lit windows, the red light on the mast), the dash
## glowing, and Tomas's radio propped against the glass, its dial lit.
const GLASS := Rect2(120, 104, 1040, 456)


func _draw_windscreen() -> void:
	# Beyond the glass: the observatory across the snow.
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 900), Color("03050b"), Color("141c34"))
	var g := GLASS
	Kit.stars(cv, Rect2(g.position, Vector2(g.size.x, 150)), 60, 0.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 470), Vector2(120, 400), Vector2(420, 430), Vector2(800, 380),
		Vector2(1200, 410), Vector2(Kit.R, 390), Vector2(Kit.R, 520), Vector2(Kit.L, 520)]), Color("0b1124"))
	Kit.dish(cv, Vector2(860, 440), 1.25, Color("070a14"))
	var bld := Rect2(380, 380, 300, 92)
	cv.draw_rect(bld, Color("0a0e18"))
	cv.draw_rect(Rect2(bld.position.x - 10, bld.position.y - 10, bld.size.x + 20, 12), Color("0e1320"))
	cv.draw_rect(Rect2(bld.position.x - 10, bld.position.y - 14, bld.size.x + 20, 5), Color(0.82, 0.86, 0.93, 0.7))
	for k in 6:
		var lit := k == 1 or k == 4
		var w := Rect2(bld.position.x + 20 + k * 46, bld.position.y + 24, 26, 18)
		cv.draw_rect(w, Color("e8a54b") if lit else Color("141a28"))
		if lit:
			Kit.soft_glow(cv, w.get_center(), 30.0, Color(1.0, 0.7, 0.35, 0.3))
	cv.draw_line(Vector2(1040, 470), Vector2(1040, 250), Color("070a14"), 4.0)
	for k in 5:
		cv.draw_line(Vector2(1030, 270 + k * 40), Vector2(1050, 290 + k * 40), Color("070a14"), 2.0)
	# Snow on the ground beyond, lit by the building.
	Kit.vgrad(cv, Rect2(Kit.L, 470, Kit.R - Kit.L, 100), Color("56627c"), Color("7a879e"))
	cv.draw_set_transform(Vector2(530, 480), 0.0, Vector2(1.0, 0.18))
	Kit.soft_glow(cv, Vector2.ZERO, 240.0, Color(1.0, 0.75, 0.45, 0.25))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The glass itself: a blue cast, a reflection, mist creeping up from the dash.
	cv.draw_rect(g, Color(0.4, 0.55, 0.75, 0.05))
	cv.draw_colored_polygon(PackedVector2Array([g.position + Vector2(160, 0), g.position + Vector2(260, 0), g.position + Vector2(120, g.size.y),
		g.position + Vector2(20, g.size.y)]), Color(1, 1, 1, 0.035))
	Kit.vgrad(cv, Rect2(g.position.x, g.end.y - 120, g.size.x, 120), Color(0.75, 0.8, 0.88, 0.0), Color(0.75, 0.8, 0.88, 0.22))
	# The cab: roof lining, visors, the mirror, the pillars.
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 204), Color("0c0e11"))
	cv.draw_line(Vector2(Kit.L, 92), Vector2(Kit.R, 92), Color("1c1f24"), 2.0)
	for side in [-1, 1]:
		var vx := 400.0 if side < 0 else 880.0
		cv.draw_colored_polygon(PackedVector2Array([Vector2(vx - 170, 98), Vector2(vx + 170, 98), Vector2(vx + 160, 150), Vector2(vx - 160, 150)]), Color("15181c"))
		cv.draw_line(Vector2(vx - 160, 150), Vector2(vx + 160, 150), Color("23272c"), 2.0)
	cv.draw_line(Vector2(640, 104), Vector2(640, 136), Color("0c0e11"), 6.0)
	var mirror := Rect2(560, 134, 160, 46)
	cv.draw_rect(mirror.grow(5), Color("0c0e11"))
	Kit.vgrad(cv, mirror, Color("1a2236"), Color("0a0e16"))
	cv.draw_line(mirror.position + Vector2(20, 40), mirror.position + Vector2(60, 6), Color(1, 1, 1, 0.08), 8.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 104), Vector2(170, 104), Vector2(70, 600), Vector2(Kit.L, 600)]), Color("0c0e11"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1110, 104), Vector2(Kit.R, 104), Vector2(Kit.R, 600), Vector2(1210, 600)]), Color("0c0e11"))
	cv.draw_line(Vector2(170, 104), Vector2(72, 598), Color("23272c"), 3.0)
	cv.draw_line(Vector2(1110, 104), Vector2(1208, 598), Color("23272c"), 3.0)
	# Wipers, resting.
	cv.draw_line(Vector2(300, 552), Vector2(640, 520), Color("0e0f11"), 5.0)
	cv.draw_line(Vector2(700, 552), Vector2(1040, 520), Color("0e0f11"), 5.0)
	# The dash: a long curve of vinyl, the defrost slots, the gauges, the heater.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 560), Vector2(Kit.R, 560), Vector2(Kit.R, 800), Vector2(Kit.L, 800)]), Color("16181c"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 572), Vector2(160, 556), Vector2(640, 548), Vector2(1120, 556), Vector2(Kit.R, 572),
		Vector2(Kit.R, 590), Vector2(Kit.L, 590)]), Color("202328"))
	cv.draw_polyline(PackedVector2Array([Vector2(Kit.L, 572), Vector2(160, 556), Vector2(640, 548), Vector2(1120, 556), Vector2(Kit.R, 572)]), Color("34383e"), 2.0, true)
	for k in 14:
		cv.draw_rect(Rect2(300 + k * 22, 562, 14, 4), Color("0a0b0d"))
		cv.draw_rect(Rect2(700 + k * 22, 562, 14, 4), Color("0a0b0d"))
	# The instrument cluster under its hood, at the left.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(150, 600), Vector2(450, 600), Vector2(470, 640), Vector2(130, 640)]), Color("0c0d10"))
	for k in 2:
		var gc := Vector2(220 + k * 160, 670)
		cv.draw_circle(gc, 52.0, Color("0a0b0d"))
		cv.draw_circle(gc, 46.0, Color("2a1a0c"))
		Kit.soft_glow(cv, gc, 46.0, Color(1.0, 0.6, 0.2, 0.35))
		for j in 9:
			var a := lerpf(PI * 0.8, PI * 2.2, j / 8.0)
			cv.draw_line(gc + Vector2(cos(a), sin(a)) * 36.0, gc + Vector2(cos(a), sin(a)) * 43.0, Color(1.0, 0.75, 0.4, 0.9), 2.0)
		var na := PI * 0.8 + (0.12 if k == 0 else 0.32)
		cv.draw_line(gc, gc + Vector2(cos(na), sin(na)) * 38.0, Color("ff5a3a"), 2.5)
		cv.draw_circle(gc, 5.0, Color("101010"))
	# The steering wheel's rim and a spoke, at the bottom left.
	cv.draw_arc(Vector2(290, 860), 250.0, PI * 1.08, PI * 1.92, 40, Color("0a0b0d"), 26.0)
	cv.draw_arc(Vector2(290, 860), 250.0, PI * 1.08, PI * 1.92, 40, Color("1e2126"), 4.0)
	cv.draw_line(Vector2(290, 860), Vector2(100, 700), Color("0a0b0d"), 22.0)
	# Heater slides glowing red in the middle.
	cv.draw_rect(Rect2(570, 610, 140, 56), Color("0e0f12"))
	for k in 3:
		cv.draw_line(Vector2(586, 624 + k * 14), Vector2(694, 624 + k * 14), Color("2a2d33"), 2.0)
		cv.draw_rect(Rect2(600 + k * 30, 619 + k * 14, 10, 10), Color("c83a2a") if k == 0 else Color("6a6e74"))
	# Ruth's paper bag, on the dash.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(470, 556), Vector2(540, 556), Vector2(534, 500), Vector2(476, 500)]), Color("a07a4a"))
	cv.draw_line(Vector2(476, 506), Vector2(534, 506), Color("7a5a34"), 2.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(476, 500), Vector2(534, 500), Vector2(526, 490), Vector2(486, 494)]), Color("b8925e"))
	# Tomas's radio, propped against the glass on his side, the dial lit; the
	# headphones on their cord, hanging off the dash.
	var rb := Rect2(840, 486, 150, 74)
	cv.draw_rect(rb, Color("4a5a3a"))
	cv.draw_rect(rb, Color("2a3420"), false, 2.0)
	cv.draw_rect(Rect2(rb.position + Vector2(12, 12), Vector2(80, 26)), Color(0.55, 0.88, 0.95))
	for k in 9:
		cv.draw_line(Vector2(rb.position.x + 18 + k * 8, rb.position.y + 16), Vector2(rb.position.x + 18 + k * 8, rb.position.y + 24), Color(0.1, 0.25, 0.3, 0.8), 1.0)
	cv.draw_line(Vector2(rb.position.x + 50, rb.position.y + 13), Vector2(rb.position.x + 50, rb.position.y + 37), Color("c8322c"), 2.0)
	cv.draw_circle(rb.position + Vector2(118, 26), 13.0, Color("1e2420"))
	cv.draw_circle(rb.position + Vector2(118, 26), 4.0, Color("8a8e90"))
	for k in 3:
		cv.draw_circle(rb.position + Vector2(26 + k * 26, 56), 6.0, Color("1e2420"))
	cv.draw_line(rb.position + Vector2(140, 0), rb.position + Vector2(196, -150), Color("9aa0a6"), 2.0)
	cv.draw_circle(rb.position + Vector2(196, -150), 3.0, Color("c8ccd0"))
	Kit.soft_glow(cv, rb.position + Vector2(52, 25), 70.0, Color(0.45, 0.85, 0.95, 0.22))
	var cord := PackedVector2Array()
	for i in 14:
		var u := i / 13.0
		cord.append(Vector2(lerpf(rb.end.x - 4, 1010.0, u), lerpf(rb.position.y + 50, 690.0, u) + sin(u * PI) * 30.0))
	cv.draw_polyline(cord, Color("101214"), 3.0, true)
	cv.draw_arc(Vector2(1010, 700), 26.0, PI * 1.1, PI * 1.9, 14, Color("2a2c30"), 8.0)
	cv.draw_circle(Vector2(988, 712), 13.0, Color("1a1c20"))
	cv.draw_circle(Vector2(1032, 712), 13.0, Color("1a1c20"))


## What moves: the bench's needles and the iron's wisp of smoke; the snow
## falling beyond the windscreen, the flakes landing on it, the drift growing
## along its foot, the mast's red light.
func draw_anim(ci: CanvasItem) -> void:
	match shot:
		"bench":
			var on := _shot_t > 1.6
			for k in 2:
				var m := Rect2(RX.position.x + 384 + k * 92, RX.position.y + 22, 80, 74)
				var pivot := Vector2(m.get_center().x, m.end.y - 10)
				var a := -PI * 0.78
				if on:
					var wake := clampf((_shot_t - 1.6) / 0.6, 0.0, 1.0)
					a = lerpf(-PI * 0.78, -PI * 0.42 + 0.08 * sin(t * (2.3 + k)) + 0.05 * sin(t * 7.1 + k), wake)
				ci.draw_line(pivot, pivot + Vector2(cos(a), sin(a)) * 44.0, Color("1c1c1c"), 2.0)
				ci.draw_circle(pivot, 3.0, Color("2a2a2a"))
			# The dial pointer, settling on the station.
			var dial := Rect2(RX.position.x + 24, RX.position.y + 22, 330, 74)
			var px := dial.position.x + 60 + 150.0 * clampf(_shot_t / 1.6, 0.0, 1.0)
			ci.draw_line(Vector2(px, dial.position.y + 2), Vector2(px, dial.end.y - 2), Color("c8322c"), 2.5)
			for k in 3:
				var u := fposmod(t * 0.4 + k / 3.0, 1.0)
				ci.draw_circle(Vector2(302 + sin(t * 2.0 + k) * 6.0 + u * 10.0, 446 - u * 90.0), 4.0 + u * 8.0, Color(0.8, 0.82, 0.85, 0.12 * (1.0 - u)))
		"windscreen":
			var g := GLASS
			# The red light on the mast.
			if fposmod(t, 1.6) < 0.8:
				ci.draw_circle(Vector2(1040, 250), 4.0, Color("ff3a2a"))
				Kit.soft_glow(ci, Vector2(1040, 250), 26.0, Color(1.0, 0.25, 0.2, 0.5))
			# Falling beyond the glass (never in front of the mirror, the bag
			# or the radio, which are this side of it).
			var near := [Rect2(552, 126, 176, 62), Rect2(466, 486, 78, 74), Rect2(836, 330, 210, 230), Rect2(Kit.L, 98, Kit.R - Kit.L, 54)]
			for i in 60:
				var p := Vector2(g.position.x + 60.0 + fposmod(i * 211.7 + t * 30.0, g.size.x - 120.0),
					g.position.y + fposmod(i * 97.3 + t * (50.0 + (i % 5) * 9.0), g.size.y - 10.0))
				if _behind(p, near):
					continue
				var r := 1.2 + (i % 3) * 0.6
				ci.draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), Color(1, 1, 1, 0.45))
			# Landed on the glass, and piling along the bottom.
			var tex := Kit.soft_tex()
			for f in _flakes:
				var fp := Vector2(f.x, f.y)
				if _behind(fp, near):
					continue
				var rr := f.z * 1.8
				ci.draw_texture_rect(tex, Rect2(fp - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false, Color(0.92, 0.95, 1.0, 0.85))
			var pile := clampf(_shot_t / 5.0, 0.0, 1.0) * 26.0
			for span in [Vector2(150.0, 466.0), Vector2(544.0, 836.0), Vector2(996.0, 1140.0)]:
				var pts := PackedVector2Array([Vector2(span.x, g.end.y)])
				for k in 9:
					var x := lerpf(span.x, span.y, k / 8.0)
					pts.append(Vector2(x, g.end.y - pile * (0.7 + 0.3 * Townscape.h(int(x) * 7))))
				pts.append(Vector2(span.y, g.end.y))
				ci.draw_colored_polygon(pts, Color(0.86, 0.9, 0.96, 0.9))


static func _behind(p: Vector2, rects: Array) -> bool:
	for r in rects:
		if (r as Rect2).has_point(p):
			return true
	return false
