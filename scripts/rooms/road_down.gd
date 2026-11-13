extends Room
## Act 1.7 (end) — the drive down. Halvard's windows breathing below her, the
## underpass, the engine and the headlights dying, and Mara finding home on
## Tomas's dial in total darkness. Then the v0.2 end card.

var speed := 240.0
var scroll := 0.0
var lights := true
var bridge_x := INF
var arrived := false
var leaving := false


func setup() -> void:
	shows_hud = false
	is_story_room = false
	place_name = "The road down"
	base_tint = Color(0.82, 0.87, 1.0)
	# The sky and the mountains are kept; the road, the pines and the snowcat
	# move (draw_anim).
	animated_back = false


func is_dark() -> bool:
	return not lights


func _process(delta: float) -> void:
	super(delta)
	scroll += speed * delta
	if bridge_x < INF and not leaving:
		bridge_x = maxf(620.0, bridge_x - speed * delta)
		if bridge_x <= 900.0:
			speed = move_toward(speed, 0.0, 140.0 * delta)
		arrived = bridge_x <= 620.0 or speed <= 0.0
		# The tracks quieten as she slows into the underpass.
		Audio.loop_volume("tracks", lerpf(-44.0, -15.0, clampf(speed / 240.0, 0.0, 1.0)))
	elif leaving:
		bridge_x -= speed * delta


func on_arrive() -> void:
	Audio.stop_all(0.5)
	Audio.play_loop("engine", -10.0, 0.8)
	Audio.play_loop("tracks", -15.0, 0.8)
	Audio.play_loop("wind", -24.0)
	await wait(1.6)
	await mara("Switchbacks all the way down. Don't think. Just drive.")
	await narrate("Halvard spreads out below. Half its windows lit, half dark, and the pattern shifts, slowly. Like breathing.")
	await mara("Don't look at it. Just drive.")
	await wait(1.0)
	await mara("The underpass. Halfway.")
	bridge_x = 1700.0
	while not arrived:
		await get_tree().process_frame
	speed = 0.0
	Audio.sfx("engine_stop", -4.0)
	Audio.stop_loop("engine", 0.2)
	Audio.stop_loop("tracks", 0.2)
	lights = false
	await wait(1.4)
	await mara("No. No, no, no.")
	await narrate("The engine's dead. The headlights are dead. Under the bridge it's the darkest dark she has ever seen.")
	await mara("I can feel it. Like the floor's tilting. I'm sliding.")
	await mara("Tomas's radio. Find the hum. Find home.")
	var st := ""
	while st != "H":
		st = await tuner_session(_home_refusal, 2.0)
		if st == "":
			await mara("No. I can't just sit here in the dark, sliding. Find home.")
			await mara("There's no number for it on his dial. It's in the gap between six and seven, where the dial says nothing.")
	await mara("That hum. That's mine.")
	Audio.sfx("crossing", -4.0)
	hud.glitch(1.4)
	GameState.cross_to("H")
	freq = "H"
	await wait(1.4)
	# She turns the key, and this time it catches.
	Audio.sfx("engine_start", -6.0)
	await wait(0.85)
	lights = true
	light_off = false
	Audio.play_loop("engine", -10.0, 1.4)
	Audio.play_loop("wind", -24.0)
	await wait(0.8)
	await mara("...The engine caught. The lights are back.")
	await mara("And the hum is right. I'm home. I'm home, and I'm on my way.")
	await mara("Hold on, Mom. Keep your light on.")
	GameState.set_flag("road_done")
	leaving = true
	speed = 260.0
	Audio.play_loop("tracks", -15.0, 0.6)
	await wait(2.0)
	Audio.stop_all(2.0)
	await hud.fade_out(2.0)
	await hud.card("ACT 2", "The overlap", 2.6)
	main.change_room("main_street", "arrive")


func _home_refusal(st: String) -> String:
	match st:
		"H":
			return ""
		"00":
			if not GameState.has("saw_stencil"):
				GameState.set_flag("saw_stencil")
				return "Nothing there. 'HOME = 00,' Tomas wrote. Then why does home sound like nothing?|NARR|Under his masking tape, an older stencil on the case is almost rubbed away. A word, then two zeros. Tomas copied a label that was already there."
			return "Nothing there. 'HOME = 00,' Tomas wrote. Then why does home sound like nothing?"
		"03":
			return "The plow. That's where I just came from. That's not home."
		_:
			return "Not mine. That's not my hum."


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 620), Color("02040a"), Color("16203a"))
	Kit.stars(cv, Rect2(Kit.L, 0, Kit.R - Kit.L, 300), 110, 0.0)
	# The observatory on the ridge behind her; the town in the valley below
	# (its windows are on the glow layer).
	cv.draw_colored_polygon(PackedVector2Array([
		Vector2(Kit.L, 470), Vector2(-200, 250), Vector2(80, 170), Vector2(360, 290), Vector2(640, 380),
		Vector2(1000, 330), Vector2(Kit.R, 420), Vector2(Kit.R, 520), Vector2(Kit.L, 520)]), Color("0b1122"))
	cv.draw_rect(Rect2(20, 136, 130, 40), Color("05080f"))
	cv.draw_rect(Rect2(46, 116, 60, 20), Color("05080f"))
	Kit.dish(cv, Vector2(170, 176), 0.5, Color("05080f"))
	Kit.vgrad(cv, Rect2(Kit.L, 556, Kit.R - Kit.L, 220), Color("8b98b0"), Color("56637d"))
	cv.draw_rect(Rect2(Kit.L, 610, Kit.R - Kit.L, 40), Color("6c7890"))


## Everything that scrolls past: the near pines, the snow stakes, the bank of
## plowed snow, the trail behind her, and Mara at the wheel.
func draw_anim(ci: CanvasItem) -> void:
	var off := fmod(scroll * 0.6, 120.0)
	var x := Kit.L - off
	var i := int(scroll * 0.6 / 120.0)
	while x < Kit.R + 120:
		var h := 70.0 + 30.0 * absf(sin(i * 1.7))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 34, 558), Vector2(x + 34, 558), Vector2(x, 558 - h)]), Color("060a12"))
		x += 120.0
		i += 1
	# The plowed road, its banks, and the snow stakes along the shoulder
	# flicking past.
	var so := fposmod(scroll, 360.0)
	var sx := Kit.R + 120.0 - so
	while sx > Kit.L - 40.0:
		ci.draw_line(Vector2(sx, 612), Vector2(sx - 2, 548), Color("1a1f2b"), 3.0)
		ci.draw_line(Vector2(sx - 1.5, 556), Vector2(sx - 2, 548), Color("d0542e"), 3.0)
		sx -= 360.0
	var seg := 26.0
	var k0 := int(floor(scroll / seg))
	var bank := PackedVector2Array([Vector2(Kit.L - seg, 615)])
	var bx := Kit.L - fposmod(scroll, seg)
	var k := 0
	while bx < Kit.R + seg:
		bank.append(Vector2(bx, 608.0 - 6.0 * Townscape.h(k0 + k)))
		bx += seg
		k += 1
	bank.append(Vector2(bx, 615))
	ci.draw_colored_polygon(bank, Color("cdd6e4"))
	ci.draw_polyline(bank.slice(1, bank.size() - 1), Color("eef2f8"), 2.0, true)
	# The trail the tracks leave behind her: a cleat mark every few inches.
	var rear := 560.0 - 200.0 * 0.62
	ci.draw_rect(Rect2(Kit.L, 641, rear - Kit.L, 8), Color(0.3, 0.35, 0.47, 0.5))
	var px := rear - fposmod(scroll, 16.0)
	while px > Kit.L:
		ci.draw_line(Vector2(px, 642), Vector2(px, 648), Color(0.22, 0.26, 0.37, 0.55), 2.0)
		px -= 16.0
	# Mara at the wheel. The engine and the lights die together.
	Vehicles.snowcat(ci, Vector2(560, 646), 0.62, t, {"moving": speed > 1.0, "engine": lights, "lights": lights,
		"driver": true, "travel": scroll, "snow": 0.7})


func draw_fore(ci: CanvasItem) -> void:
	if bridge_x == INF or bridge_x < -800:
		return
	var b := bridge_x
	var deck := Color("2a2d33")
	ci.draw_rect(Rect2(b - 520, 300, 1040, 70), deck)
	ci.draw_rect(Rect2(b - 520, 300, 1040, 10), Color("3a3e45"))
	ci.draw_rect(Rect2(b - 540, 300, 70, 360), deck.darkened(0.2))
	ci.draw_rect(Rect2(b + 470, 300, 70, 360), deck.darkened(0.2))
	ci.draw_rect(Rect2(b - 470, 370, 940, 290), Color(0.0, 0.0, 0.02, 0.55))


func draw_glow(ci: CanvasItem) -> void:
	if not lights:
		return
	# Halvard's windows in the valley, breathing; hidden once the bridge is overhead.
	if bridge_x > 1000.0:
		for k in 46:
			var wx := 660.0 + fposmod(k * 97.3, 560.0)
			var wy := 404.0 + fposmod(k * 41.7, 40.0) - (wx - 660.0) * 0.03
			var a := 0.5 + 0.5 * sin(t * 0.8 - wx * 0.012 + k * 0.3)
			ci.draw_rect(Rect2(wx, wy, 5, 4), Color(1.0, 0.8, 0.45, 0.1 + 0.85 * a * a))
	# Headlights.
	var hl := Vector2(560 + 204 * 0.62, 646 - 99 * 0.62)
	# The beam fades out along its length instead of ending in a hard edge.
	var warm := Color(1.0, 0.95, 0.8)
	ci.draw_polygon(PackedVector2Array([hl, Vector2(hl.x + 480, hl.y - 64), Vector2(hl.x + 480, hl.y + 84)]),
		PackedColorArray([Color(warm, 0.28), Color(warm, 0.0), Color(warm, 0.0)]))
	ci.draw_circle(hl, 6.0, Color("fff6d8"))
