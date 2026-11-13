extends Room
## Act 3 — outside, on the summit, at the foot of the 26-metre dish. The same
## place in three years.
##
## 1983, tonight: snow, the dish swung round to the horizon for the 2.14 run,
## the ladder up the yoke to the feed cabin, Mara's car snowed in, the stone
## wing, and Halvard's lights across the valley.
## 2031, an October afternoon: the observatory is the Halvard Signal Visitor
## Center. A glass entrance, solar panels, an electric car on charge, a
## driverless shuttle, wind turbines on the far ridge, visitors talking in
## whispers. The dish is painted white and parked at the zenith behind a fence.
## 2009, a winter night: the concrete building is a roofless shell full of
## snow, the stone wing is lit in every window and ringed by the lamp line. Two
## cars abandoned in the lot, the dish rusted fast, Tomas's hut at its foot,
## and on the far ridge, the white.

## Everything here is drawn to the people's scale, about 110 px to the metre
## on the line they walk: doors two and a quarter metres tall, the stone wing's
## two storeys running up out of the picture, cars full size a metre back in
## the lot. The dish stands well back across the summit, so distance shrinks it.

var snow: Snowfall
var tomas: Actor
var lund_w: Actor
var lund_h: Actor
var visitor_a: Actor
var visitor_b: Actor
var tomas_lamp: PointLight2D
## 2009, at 2:14: the coupling glowing in Tomas's hands (0..1).
var coupling := 0.0
var shot := ""


func _era() -> String:
	return GameState.era


func env() -> Env:
	if GameState.era != "":
		return Env.of("F" + GameState.era)
	return super()


func setup() -> void:
	animated_back = false
	outdoors = true
	walk_min = 70.0
	walk_max = 1210.0
	base_tint = Color(0.84, 0.88, 1.0)
	var era := _era()
	place_name = {"2031": "Halvard Signal Visitor Center  ·  2031", "2009": "The dish  ·  2009"}.get(era, "The dish")
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -40, Kit.R - Kit.L, 760)
	snow.count = 46 if era == "2031" else 150
	snow.wind = 22.0 if era == "2031" else 36.0
	add_child(snow)
	snow.follow(env())
	match era:
		"2031":
			_setup_2031()
		"2009":
			_setup_2009()
		_:
			_setup_1983()
	make_player(840.0, -1)


func _setup_1983() -> void:
	add_hotspot("doors", DOORS, "Lobby", 150.0, -1)
	add_hotspot("stone_wing", Rect2(250, 100, 380, 300), "The stone wing", 430.0, -1)
	add_hotspot("car", Rect2(690, 486, 400, 146), "My car", 880.0)
	add_hotspot("disconnect", Rect2(1066, 474, 54, 70), "Main disconnect", 1050.0, 1)
	add_hotspot("ladder", Rect2(830, 60, 360, 380), "The dish", 1200.0, 1)


func _setup_2031() -> void:
	visitor_b = add_actor("visitor_b", 960.0, 1)
	visitor_a = add_actor("visitor_a", 1022.0, -1)
	visitor_a.prop = "smartphone"
	add_hotspot("doors", DOORS, "Visitor center", 150.0, -1)
	add_hotspot("ev", Rect2(640, 478, 270, 156), "Electric car", 760.0)
	add_hotspot("visitors", Rect2(920, 440, 140, 210), "Visitors", 880.0, 1)
	add_hotspot("sign", Rect2(1204, 510, 80, 140), "Sign", 1190.0, 1)
	add_hotspot("shuttle", Rect2(1290, 380, 320, 220), "Shuttle", 1210.0, 1)
	add_hotspot("turbines", Rect2(1170, 240, 300, 140), "Wind turbines", NAN)
	add_hotspot("ladder", Rect2(830, 60, 340, 360), "The dish", 1200.0, 1)


func _setup_2009() -> void:
	walk_min = 570.0
	lund_h = add_actor("lund_h_2009", 380.0, 1)
	lund_w = add_actor("lund_w_2009", 452.0, 1)
	tomas = add_actor("tomas_2009", 1196.0, -1)
	tomas.prop = "lamp"
	tomas_lamp = add_lamp(Vector2(1150, 520), 2.6, Color(1.0, 0.78, 0.45), 0.9)
	add_hotspot("lunds", Rect2(330, 440, 170, 210), "The lamp line", 600.0, -1)
	add_hotspot("tomas", Rect2(1152, 440, 90, 210), "The man with the lamp", 1130.0, 1)
	add_hotspot("chute", Rect2(570, 600, 70, 50), "Coal chute", 620.0, -1, func() -> bool: return GameState.has("tomas09_met"))
	add_hotspot("graffiti", Rect2(0, 400, 236, 140), "Spray paint", 600.0, -1)
	add_hotspot("suv", Rect2(660, 450, 400, 150), "Abandoned cars", 800.0)
	add_hotspot("padlock", Rect2(1066, 474, 54, 70), "Main disconnect", 1050.0, 1)
	add_hotspot("white", Rect2(1240, 160, 300, 160), "The far ridge", NAN)
	add_hotspot("ladder", Rect2(830, 60, 340, 360), "The dish", 1090.0, 1)
	add_hotspot("hut_papers", Rect2(1254, 462, 52, 74), "Papers on his door", 1240.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"from_lobby", "from_center":
			player.position.x = 170.0
			player.face(1)
		"from_chute":
			player.position.x = 640.0
			player.face(1)
			if tomas != null:
				tomas.position.x = 720.0
				tomas.face(1)
		_:
			player.position.x = {"2009": 1010.0, "2031": 1100.0}.get(_era(), 1150.0)
			player.face(-1)


func _process(delta: float) -> void:
	super(delta)
	if tomas != null and tomas_lamp != null:
		tomas_lamp.position = tomas.position + Vector2(26.0 * tomas.facing, -110.0)
		tomas_lamp.visible = tomas.visible


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	match _era():
		"2031":
			Audio.play_loop("wind", -32.0)
			Audio.play_loop("street_air", -30.0)
		"2009":
			Audio.play_loop("wind", -18.0)
			Audio.play_loop("drone", -32.0)
		_:
			Audio.play_loop("wind", -18.0)
			if not GameState.has("dish_parked") or GameState.has("dish_released"):
				Audio.play_loop("dish_motor", -30.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	match entered_from:
		"arrive":
			await _arrive()
		"wake":
			await _wake()
		"from_chute":
			await _two_fourteen_2009()
			return
		_:
			if _era() == "" and not GameState.has("dish_seen"):
				GameState.set_flag("dish_seen")
				await wait(0.3)
				await mara("Snow on everything. And the dish...")
				await mara("It's swung right round to the horizon. Sollen parks it at the top every night. Nobody's touched the drive.")
	objective()


func _arrive() -> void:
	await wait(0.5)
	match _era():
		"2031":
			await mara("Daylight.")
			await mara("Leaves. October, and no snow, and the sun's out.")
			await mara("The dish is white. Somebody painted it. There's a fence round it.")
			await say("VISITOR", "(whispering) ...still nothing on mine. Not even static.")
			await mara("Everybody's whispering.")
		"2009":
			await mara("No roof. Snow inside the walls.")
			await mara("Nobody down in Halvard. Not a light in the valley.")
			await mara("Only up here: lamps in every window of the old stone wing, and a ring of them round it.")
			await mara("And on the far ridge... white. Like the edge of a page.")


## Back from a future: Mara wakes on the floor of the feed cabin and climbs down.
func _wake() -> void:
	# Down the ladder, out there on the dish, and back along the path.
	player.position.x = 1360.0
	await player.walk_to(1150.0)
	player.face(-1)
	await wait(0.3)
	var g := GameState
	if g.has("been_2031") and not g.has("woke_2031"):
		g.set_flag("woke_2031")
		await mara("The cabin floor. Snow. Two-fourteen. 1983.")
		if g.has_item("cassette_2031"):
			await mara("And Ma's tape, still in my hand.")
			Audio.play_loop("tape_hiss", -20.0, 0.2)
			await narrate("As she climbs down, the label goes pale, then the cassette, like a station drifting out of tune.")
			Audio.stop_loop("tape_hiss", 1.4)
			g.remove_item("cassette_2031")
			g.set_flag("cassette_faded")
			await wait(0.6)
			await mara("Gone.")
		await say("JUNE (TUNER)", "A future's a signal, honey, not a station. You can listen to it. You can't take it home.")
		await mara("Nothing comes back from a future. It hasn't happened yet.")
		await mara("But I can remember. The hollow left rear leg of Sollen's desk.")
		await mara("And I'm putting that year on the chalkboard before I forget it.")
	elif g.has("been_2009") and not g.has("woke_2009"):
		g.set_flag("woke_2009")
		await mara("He's still up there. In 2009. With his hands on it.")
		await mara("The tin behind the boiler. T.L. In the stone wing's basement.")
		await mara("Our basement. The fresh plaster.")
	elif g.has("red_done") and not g.has("woke_red"):
		g.set_flag("woke_red")
		await mara("The cabin floor. 1983.")
		await mara("My hand's still warm where he held it.")
		await mara("Blue. Zero-seven. Doesn't know.")
		await wait(0.4)
		await mara("I know.")
		await mara("And somebody's calling on 2.14. From the dark. I can hear her in my teeth.")
	else:
		await mara("Pitch black. Nothing. Just me, frayed at the edges.")


func on_hotspot(id: String) -> void:
	match id:
		"doors":
			await _doors()
		"ladder":
			await _ladder()
		"dish":
			if GameState.has("dish_parked") and not GameState.has("dish_released"):
				await mara("Parked, straight up at the zenith. Not listening to anything.")
			else:
				await mara("Twenty-six metres of steel, pointing at the horizon. Listening on 2.14, all by itself.")
				await mara("The feed cabin's that box at the focus, where the legs meet. No windows. The darkest place on the mountain.")
		"disconnect":
			await mara("The dish's main disconnect. A padlock on it, U.S. AIR FORCE stamped in the steel.")
			await mara("Sollen says he's never seen the key. It's been there since before his time.")
		"car":
			await mara("My car. Snowed in to the door handles. Nobody's driving down tonight.")
		"stone_wing":
			await mara("The old stone wing. The station was a weather post before the dish. The basement's under there. Tomas's box.")
		"sign":
			await narrate("HALVARD 26-METRE DISH, 1971. Decommissioned 1997. Parked at the zenith. Please stay behind the fence.")
		"visitors":
			await say("VISITOR", "(whispering) Months, now. Not even static. My grandmother says it's like the war.")
			await say("VISITOR", "(whispering) They say the dish heard it first. Back in the eighties.")
			await mara("They're whispering because nothing else makes a sound.")
		"ev":
			await mara("A car on a cord, plugged into a post. No engine, no exhaust. Just a little light, breathing.")
		"shuttle":
			await mara("A bus with no driver's seat. HALVARD SIGNAL  ·  SHUTTLE.")
		"turbines":
			await mara("Windmills on the far ridge, as tall as the dish. Sollen would hate them.")
		"lunds":
			await _lunds()
		"tomas":
			await _tomas()
		"chute":
			await _chute()
		"graffiti":
			await narrate("Spray paint across what's left of the lobby wall: THEY CAME OUT OF THE DARK. Beneath it, smaller: COUNT YOURSELF.")
		"suv":
			await mara("Cars in the lot, snowed in, rusting. Nobody's driven down in years.")
			await mara("The plates say 2008. Tags never renewed.")
		"padlock":
			GameState.set_flag("padlock_seen")
			await mara("The main disconnect. U.S. AIR FORCE on the padlock. The same one. Twenty-six more years of rust.")
		"white":
			await mara("White, on the ridge. It doesn't move when I look at it. It's nearer when I look back.")
		"hut_papers":
			await _hut_papers()


## 2009: what Tomas keeps on his door, in plastic sleeves against the weather.
func _hut_papers() -> void:
	var g := GameState
	await narrate("Tacked to his door in plastic sleeves: a newspaper clipping gone yellow, and a printout.")
	await hud.read_doc("ON TOMAS'S DOOR", [
		"HALVARD COURIER, MARCH 1999\n\nUNIVERSE IS FLYING APART, FASTER AND FASTER\n\nAstronomers watching distant exploding stars say the expansion of the universe is speeding up. Something in empty space is pushing. They are calling it \"dark energy.\"\n\nAcross the top, in marker: DAD WAS RIGHT.",
		"PHANTOM ENERGY AND COSMIC DOOMSDAY\nR. R. Caldwell, M. Kamionkowski, N. N. Weinberg, 2003\n\n[Printed out, and folded many times.]\n\nIf dark energy keeps getting stronger, it ends in a Big Rip: galaxies first, then stars and planets, then atoms, pulled apart.\n\nIn the margin, in Tomas's hand: \"Here it's small. Here it's the white.\"",
	])
	if g.has("big_rip"):
		return
	g.set_flag("big_rip")
	await mara("Dark energy. 'Dad was right.' Twenty years after the road.")
	await mara("Space pulled apart until nothing can cross it. Not light. Not sound. That's the white.")
	objective()


func _doors() -> void:
	match _era():
		"2031":
			Audio.sfx("door", -14.0)
			main.change_room("visitor_center", "from_dish")
		"2009":
			await mara("No doors, no roof. Snow in the lobby, up to the bench.")
		_:
			Audio.sfx("door", -10.0)
			main.change_room("lobby", "from_dish")


func _ladder() -> void:
	match _era():
		"2031":
			await mara("There's a fence round it now. PLEASE KEEP OFF THE DISH.")
			await mara("I can't climb back. It'll let me go when it's ready.")
			return
		"2009":
			await mara("Tomas climbs it at two-fourteen. Not me. Not tonight.")
			return
	if not GameState.has("patched"):
		await mara("The ladder up the yoke to the feed cabin. Pitch black up there.")
		await mara("But the dish isn't listening to anything I can reach. Not yet. Not without the receiver patched in.")
		return
	var year := Act3.next_future()
	if year == "":
		await mara("The needle won't settle. There's nothing on it. Not yet.")
		var pick: int = await hud.choose(["Climb in anyway", "Not now"])
		if pick != 0:
			return
		await _climb_up()
		GameState.cabin_fray()
		await hud.fade_out(0.5)
		await wait(0.6)
		hud.toast("Something frays. (FRACTURE %d: a trip into the dark for nothing)" % int(GameState.story.FRACTURE))
		main.warn_fracture(2.6)
		await hud.fade_in(0.5)
		await _wake()
		objective()
		return
	match year:
		"2031":
			await mara("The needle's on 2031. The loudest future it can hear.")
			await mara("Twenty-six metres up, in a steel box with no windows. Whatever you're doing, don't do it twice.")
		"2009":
			await mara("2009. In my own handwriting.")
		"1991":
			await mara("1991. He's calling. I'm coming.")
			await mara("One more. Then I park it for good.")
	await _climb_up()
	await Act3.go(self, year)


## Out along the path to the dish, and up its ladder.
func _climb_up() -> void:
	player.face(1)
	await player.walk_to(1380.0)


# --- 2009 -----------------------------------------------------------------------------

func _lunds() -> void:
	var g := GameState
	if g.has("lund_count"):
		await say("MRS. LUND", "Outside the line, dear. It's nothing personal. It's the Rules.")
		return
	await say("MRS. LUND", "Stop there, dear. That's the line.")
	await say("MRS. LUND", "Lamps in every window, all night. Any room that won't stay lit, we brick up.")
	await say("MRS. LUND", "And every night at the line, everyone counts themselves. Name, house, and one thing only you would know.")
	await mara("Why?")
	await say("MRS. LUND", "The winter it went, two of everyone came out of the dark. Somebody had to choose.")
	await say("MRS. LUND", "One of them went upstairs for the spare coat and came down in March. By then there were Rules, and I had to say which one was mine.")
	await say("MR. LUND", "She chose right.")
	await say("MRS. LUND", "You've the Lind girl's face. Anders's girl. You can try the count, if you like.")
	await say("MRS. LUND", "What did Anders whistle, calling the two of you in?")
	await wait(0.3)
	Audio.sfx("whistle_rev", -6.0)
	await narrate("Mara whistles two notes. Up, then down.")
	await wait(0.4)
	await say("MRS. LUND", "Down, then up, dear. Close isn't the same.")
	await say("MRS. LUND", "You stay outside the line.")
	g.set_flag("lund_count")
	await mara("Up, then down. That's how he did it. I'd swear it.")
	objective()


func _tomas() -> void:
	var g := GameState
	if g.has("knows_tin"):
		await say("TOMAS", "Nearly time.")
		return
	if g.has("tomas09_met"):
		await say("TOMAS", "Round the line, not through it. The coal chute, by the wall. Keep in my light.")
		return
	await narrate("A man of about forty in a patched parka. He holds his lamp out between them, the way you'd hold it out to a stray.")
	await say("TOMAS", "You're outside the line too.")
	await mara("...Tomas?")
	await say("TOMAS", "Everyone up here was somebody's. I came through the dark at thirteen, looking for my sister. Found this Halvard instead.")
	await say("TOMAS", "They let me stay, as long as I stay out here.")
	await narrate("His palms are shiny with old burns.")
	await say("TOMAS", "Every October fourteenth, at two-fourteen, I climb the dish and pull the coupling in the feed cabin. By hand.")
	await say("TOMAS", "The main disconnect's had an Air Force padlock on it since November '79. So: by hand.")
	await mara("Since November '79. Dad.")
	await say("TOMAS", "There's something you should see before I go up. Not through the line. Round it.")
	await say("TOMAS", "The coal chute. Stay in my light. Light holds you where you are.")
	g.set_flag("tomas09_met")
	objective()


func _chute() -> void:
	await say("TOMAS", "After you. No, wait. After me. Keep in the light.")
	Audio.sfx("scrape", -8.0)
	main.change_room("basement_2009", "chute")


## 2:14 in 2009: Tomas climbs to the coupling, and tonight it glows in his hands.
func _two_fourteen_2009() -> void:
	await wait(0.4)
	await say("TOMAS", "Two-fourteen.")
	if GameState.story.get("TOMAS") == "taken":
		await say("TOMAS", "Did you bring one of us across?")
		await mara("...Yes.")
		await say("TOMAS", "Then stay with him. Nobody stayed with me.")
	else:
		await say("TOMAS", "Go home, if you've got one.")
	await tomas.walk_to(1420.0)
	tomas.visible = false
	await wait(1.2)
	await narrate("He climbs to the coupling. Tonight it won't pull.")
	Audio.play_loop("carrier", -20.0, 1.0)
	shot = "coupling"
	var glow_tw := create_tween()
	glow_tw.tween_property(self, "coupling", 1.0, 2.0)
	await glow_tw.finished
	await narrate("It glows in his hands.")
	Audio.stop_loop("carrier", 0.2)
	await Act3.silence(self)


# --- drawing ----------------------------------------------------------------------------

func static_key() -> String:
	return "%s|%d" % [_era(), _white_steps()]


## How near the white is in 2009: it comes on as the visit goes.
func _white_steps() -> int:
	var n := 0
	for f in ["lund_count", "tomas09_met", "knows_tin"]:
		if GameState.has(f):
			n += 1
	return n


func _aim() -> float:
	match _era():
		"2031":
			return -PI / 2 + 0.1
		"2009":
			return -0.95
	if GameState.has("dish_parked") and not GameState.has("dish_released"):
		return -PI / 2
	return -0.16


func draw_back() -> void:
	var e := env()
	match _era():
		"2031":
			_back_2031(e)
		"2009":
			_back_2009(e)
		_:
			_back_1983(e)


## A polygon shaded from colour a to b along the line from `from` to `to`.
func _shaded(pts: PackedVector2Array, a: Color, b: Color, from: Vector2, to: Vector2) -> void:
	var ax := to - from
	var l2 := maxf(ax.length_squared(), 1.0)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(a.lerp(b, clampf((p - from).dot(ax) / l2, 0.0, 1.0)))
	cv.draw_polygon(pts, cols)


func _ridge(y: float, amp: float, seed: int) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(Kit.L, 760)])
	var steps := 18
	for i in steps + 1:
		var x := lerpf(Kit.L, Kit.R, float(i) / steps)
		pts.append(Vector2(x, y - amp * (0.5 + 0.5 * sin(i * 1.37 + seed)) - amp * 0.4 * Townscape.h(i + seed * 13)))
	pts.append(Vector2(Kit.R, 760))
	return pts


# --- 1983 --------------------------------------------------------------------------------

func _back_1983(e: Env) -> void:
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 560), Color("04060d"), Color("1b2542"))
	Kit.stars(cv, Rect2(Kit.L, -60, Kit.R - Kit.L, 380), 120, 0.0)
	# The far side of the valley, and Halvard's lights at its foot: every one on tonight.
	cv.draw_colored_polygon(_ridge(400.0, 70.0, 3), Color("0d1426"))
	cv.draw_colored_polygon(_ridge(470.0, 36.0, 7), Color("111a30"))
	for i in 80:
		var x := 300.0 + Townscape.h(i * 7) * 1420.0
		var y := 490.0 + Townscape.h(i * 11) * 44.0
		cv.draw_rect(Rect2(x, y, 3, 2), Color(1.0, 0.78, 0.42, 0.55 + 0.4 * Townscape.h(i)))
	_summit(Color("5c6880"), Color("8592aa"))
	_far_fence(Color("161c28"))
	_dish(e, "1983")
	_control_building("1983")
	_stone_wing("1983")
	# Mara's car, a metre back in the lot, snowed in to the door handles.
	Vehicles.car(cv, Vector2(960, 634), 1.0, 0.0, {"body": Color("5e4a36"), "snow": 1.0})
	_gate_box("1983")
	_lamp_post(664.0)
	_snow_ground()


## The summit: the lot and the snow (or the lawn), out to where the mountain falls away.
func _summit(top: Color, bottom: Color) -> void:
	Kit.vgrad(cv, Rect2(Kit.L, 544, Kit.R - Kit.L, 230), top, bottom)
	cv.draw_line(Vector2(Kit.L, 545), Vector2(Kit.R, 545), Color(0.82, 0.86, 0.95, 0.3), 2.0)


## The perimeter fence where the summit falls away: far off, so small.
func _far_fence(col: Color) -> void:
	for i in 40:
		var x := Kit.L + 20.0 + i * 56.0
		cv.draw_line(Vector2(x, 548), Vector2(x, 524), col, 2.0)
	for k in 3:
		cv.draw_line(Vector2(Kit.L, 528 + k * 6), Vector2(Kit.R, 528 + k * 6), Color(col, 0.6), 1.0)


func _snow_ground() -> void:
	Townscape.snowbank(cv, Kit.L, 236, 652, 22.0, 4)
	Townscape.snowbank(cv, 236, 640, 652, 16.0, 6)
	Townscape.snowbank(cv, 1240, Kit.R, 652, 18.0, 8)
	for i in 34:
		var p := Vector2(560 + i * 30.0, 666 + (i % 3) * 8.0)
		cv.draw_line(p, p + Vector2(12, 1), Color(0.25, 0.3, 0.42, 0.28), 3.0)


# --- the observatory: the concrete control building and the stone wing, true to scale --

## The control building (1971): board-marked concrete, a 4.5 m parapet, a
## ribbon of lab windows and the lobby entrance.
func _control_building(era: String) -> void:
	var night := era != "2031"
	var conc := Color("394049") if night else Color("c9c6be")
	var top := 150.0
	Kit.vgrad(cv, Rect2(Kit.L, top, 236 - Kit.L, 650 - top), conc.lightened(0.05), conc.darkened(0.14))
	for k in 14:
		cv.draw_line(Vector2(Kit.L, top + 30 + k * 34), Vector2(236, top + 30 + k * 34), Color(0, 0, 0, 0.1), 1.0)
	for i in 12:
		cv.draw_line(Vector2(Kit.L + 60 + i * 120, top), Vector2(Kit.L + 60 + i * 120, 650), Color(0, 0, 0, 0.07), 2.0)
	cv.draw_rect(Rect2(Kit.L, top - 14, 236 - Kit.L, 16), conc.darkened(0.25))
	# The labs' ribbon windows: sills at a metre, two-metre glass.
	for i in 3:
		var w := Rect2(-420 + i * 124, 410, 108, 134)
		if era == "2031":
			Kit.vgrad(cv, w, Color("9cc0dc"), Color("5a7a94"))
			cv.draw_line(w.position + Vector2(10, w.size.y), w.position + Vector2(40, 0), Color(1, 1, 1, 0.3), 10.0)
		else:
			var lit := i != 1
			Kit.vgrad(cv, w, Color("f2c27a") if lit else Color("10151e"), Color("c8863e") if lit else Color("0a0d14"))
			if lit:
				cv.draw_rect(Rect2(w.position.x + 10, w.end.y - 40, 50, 40), Color(0.25, 0.18, 0.12, 0.5))  # a desk, a lamp
		cv.draw_rect(w, Color("1f242a") if night else Color("3a3e44"), false, 4.0)
		cv.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("1f242a") if night else Color("3a3e44"), 3.0)
		cv.draw_rect(Rect2(w.position.x - 6, w.end.y, w.size.x + 12, 8), conc.darkened(0.2))
		if night:
			Townscape.snow_ledge(cv, w.position.x - 6, w.end.x + 6, w.end.y, 5.0, i)
	match era:
		"2031":
			_solar()
			_entrance_2031()
		_:
			Townscape.snow_ledge(cv, Kit.L, 240, top - 14, 8.0, 3)
			Townscape.icicles(cv, -300, 230, top + 2, 4)
			# The air handler on the roof, and the station's own radio mast.
			cv.draw_rect(Rect2(-170, 92, 120, 44), Color("252b34"))
			Townscape.snow_ledge(cv, -172, -48, 92, 6.0, 9)
			cv.draw_line(Vector2(-330, top - 14), Vector2(-330, -100), Color("10141c"), 5.0)
			for k in 4:
				cv.draw_line(Vector2(-356 + k * 6, 40 + k * 24), Vector2(-304 - k * 6, 40 + k * 24), Color("10141c"), 2.0)
			_entrance_1983()


## The lobby doors, true size: glass double doors two and a quarter metres tall.
const DOORS := Rect2(36, 404, 196, 246)


func _entrance_1983() -> void:
	var r := DOORS
	Kit.vgrad(cv, r, Color("d9d2b0"), Color("8e8a70"))
	cv.draw_rect(Rect2(r.position.x, r.end.y - 50, r.size.x, 50), Color("6a6658"))
	# Inside: the bulletin board, the bench, the booth's window.
	cv.draw_rect(Rect2(r.position.x + 24, r.position.y + 70, 70, 56), Color("8a6a45"))
	cv.draw_rect(Rect2(r.position.x + 120, r.position.y + 60, 60, 40), Color("2a3036"))
	cv.draw_rect(Rect2(r.position.x + 20, r.end.y - 78, 80, 10), Color("5a4532"))
	cv.draw_rect(r.grow(7), Color("1a1e22"), false, 14.0)
	cv.draw_line(Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), Color("1a1e22"), 8.0)
	for x in [r.get_center().x - 18, r.get_center().x + 11]:
		cv.draw_rect(Rect2(x, r.position.y + 120, 7, 60), Color("9aa3a8"))
	# The canopy, the plates, a wall lamp.
	cv.draw_rect(Rect2(10, 378, 230, 18), Color("2e343c"))
	Townscape.snow_ledge(cv, 8, 242, 378, 8.0, 13)
	Kit.plate(cv, Vector2(122, 322), "HALVARD RADIO OBSERVATORY", 13)
	Kit.text(cv, Vector2(10, 362), "WITH THE U.S. AIR FORCE", 11, Color("8a94a0"), HORIZONTAL_ALIGNMENT_CENTER, 226)
	cv.draw_rect(Rect2(14, 420, 14, 22), Color("2a2c30"))
	# Warm light from the doors on the snow.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(36, 650), Vector2(232, 650), Vector2(290, 720), Vector2(0, 720)]), Color(1.0, 0.88, 0.6, 0.12))


func _entrance_2031() -> void:
	# A glass box built onto the old entrance: timber fins, the new sign, sliding doors.
	var r := Rect2(-24, 330, 260, 320)
	Kit.vgrad(cv, r, Color("aac6d8"), Color("6e8a9c"))
	cv.draw_rect(Rect2(r.position.x, r.end.y - 90, r.size.x, 90), Color(0.22, 0.24, 0.26, 0.45))
	# Inside: the recordings wall and warm track lights.
	cv.draw_rect(Rect2(-10, 470, 130, 120), Color("4a3a30"))
	for k in 5:
		cv.draw_rect(Rect2(-4 + k * 25, 480, 19, 100), Color("6a5444"))
	for k in 5:
		Kit.soft_glow(cv, Vector2(-4 + k * 54, 350), 16.0, Color(1.0, 0.86, 0.6, 0.7))
	for i in 9:
		var x := r.position.x + i * 30.0
		cv.draw_rect(Rect2(x, r.position.y, 8, r.size.y), Color("8a6440"))
		cv.draw_rect(Rect2(x + 6, r.position.y, 2, r.size.y), Color("6a4a30"))
	cv.draw_line(r.position + Vector2(30, r.size.y), r.position + Vector2(100, 0), Color(1, 1, 1, 0.22), 22.0)
	cv.draw_rect(Rect2(-34, 288, 280, 44), Color("2c3338"))
	Kit.text(cv, Vector2(-34, 314), "HALVARD SIGNAL", 21, Color("f2f0ea"), HORIZONTAL_ALIGNMENT_CENTER, 280)
	Kit.text(cv, Vector2(-34, 328), "VISITOR CENTER", 10, Color("c8ccd0"), HORIZONTAL_ALIGNMENT_CENTER, 280)
	cv.draw_rect(DOORS, Color(0.85, 0.92, 0.98, 0.22))
	cv.draw_rect(DOORS, Color("3a3e44"), false, 4.0)
	cv.draw_line(Vector2(DOORS.get_center().x, DOORS.position.y), Vector2(DOORS.get_center().x, DOORS.end.y), Color("3a3e44"), 3.0)
	# Banners on poles by the path.
	for p in [[Vector2(-70, 650), Color("c4502e")], [Vector2(252, 650), Color("2f5878")]]:
		var b: Vector2 = p[0]
		cv.draw_line(b, b + Vector2(0, -390), Color("3a3e44"), 5.0)
		cv.draw_rect(Rect2(b + Vector2(3, -380), Vector2(64, 170)), p[1])
		Kit.text(cv, b + Vector2(7, -340), "LISTENING", 10, Color("f2f0ea"))
		Kit.text(cv, b + Vector2(7, -322), "SINCE", 10, Color("f2f0ea"))
		Kit.text(cv, b + Vector2(7, -300), "1971", 16, Color("f2f0ea"))


## Solar panels along the old flat roof.
func _solar() -> void:
	for i in 7:
		var x := Kit.L + 30 + i * 92.0
		var pts := PackedVector2Array([Vector2(x, 136), Vector2(x + 80, 136), Vector2(x + 70, 96), Vector2(x + 10, 96)])
		cv.draw_colored_polygon(pts, Color("1e3550"))
		for k in 3:
			cv.draw_line(Vector2(x + 3 + k * 3, 126 - k * 10), Vector2(x + 77 - k * 3, 126 - k * 10), Color("4a6a8a"), 1.0)
		cv.draw_line(Vector2(x + 40, 96), Vector2(x + 40, 136), Color("4a6a8a"), 1.0)
		cv.draw_line(Vector2(x + 10, 97), Vector2(x + 70, 97), Color(1, 1, 1, 0.35), 1.0)


## The stone wing (1931): the weather post the station was before the dish.
## Granite, two storeys (the eaves are above the top of the picture), tall
## arched windows, a carved lintel over its door, and the coal chute's hatch.
const WING := Rect2(236, -100, 404, 750)


func _stone_wing(era: String) -> void:
	var night := era != "2031"
	var stone := Color("4a4c50") if night else Color("8e8a80")
	Townscape.wall(cv, WING, stone, "stone")
	cv.draw_rect(Rect2(WING.position.x, 282, WING.size.x, 12), stone.lightened(0.1))
	cv.draw_rect(Rect2(WING.position.x, 294, WING.size.x, 3), Color(0, 0, 0, 0.3))
	# Quoins down the corners.
	for k in 12:
		var y := -60.0 + k * 60.0
		for x in [WING.position.x, WING.end.x - 30]:
			cv.draw_rect(Rect2(x, y, 30, 28), stone.lightened(0.06))
	for x in [262.0, 518.0]:
		var low := Rect2(x, 418, 92, 142)
		var up := Rect2(x, 112, 92, 142)
		match era:
			"2009":
				_lamp_window(low, true)
				if x > 400.0:
					EnvironmentArt.brick(cv, up, Color("5a4a40"))  # a dark room, bricked up
				else:
					_lamp_window(up, true)
				Townscape.snow_ledge(cv, x - 6, x + 98, 561, 5.0, int(x))
			"2031":
				Townscape.window(cv, low, false, Color("25221f"), true, false)
				Townscape.window(cv, up, false, Color("25221f"), true, false)
			_:
				Townscape.window(cv, low, x < 400.0, Color("25221f"), true, x < 400.0)
				Townscape.window(cv, up, false, Color("25221f"), true, false)
	# The door, and the lintel carved when it was built.
	var d := Rect2(388, 420, 92, 230)
	cv.draw_rect(d.grow(8), stone.darkened(0.25))
	cv.draw_rect(d, Color("2a1e18") if night else Color("4a3a2e"))
	for k in 4:
		cv.draw_line(Vector2(d.position.x + 8 + k * 22, d.position.y + 8), Vector2(d.position.x + 8 + k * 22, d.end.y - 8), Color(0, 0, 0, 0.25), 2.0)
	cv.draw_circle(Vector2(d.end.x - 14, d.position.y + 128), 4.0, Color("8a8478"))
	cv.draw_rect(Rect2(376, 380, 116, 30), stone.lightened(0.12))
	Kit.text(cv, Vector2(376, 401), "WEATHER POST 1931", 9, stone.darkened(0.4), HORIZONTAL_ALIGNMENT_CENTER, 116)
	if night:
		Townscape.snow_ledge(cv, 374, 494, 380, 5.0, 17)
	# The coal chute's iron hatch at the foot of the wall.
	var h := Rect2(574, 606, 62, 42)
	cv.draw_rect(h, Color("26282c") if night else Color("4a4c50"))
	cv.draw_rect(h, Color("15171a"), false, 3.0)
	for k in 3:
		cv.draw_line(Vector2(h.position.x + 6, h.position.y + 9 + k * 11), Vector2(h.end.x - 6, h.position.y + 9 + k * 11), Color("3a3c40"), 2.0)
	cv.draw_circle(Vector2(h.get_center().x, h.end.y - 6), 4.0, Color("6a6c70"))


## A window with a lamp burning behind it (the Rules: every window, all night).
func _lamp_window(r: Rect2, arch: bool) -> void:
	Kit.vgrad(cv, r, Color("f6cf86"), Color("c98a42"))
	cv.draw_circle(Vector2(r.get_center().x, r.end.y - 20), 8.0, Color("fff2c8"))
	cv.draw_rect(Rect2(r.get_center().x - 7, r.end.y - 12, 14, 10), Color("6a4a2a"))
	cv.draw_rect(r, Color("25221f"), false, 4.0)
	cv.draw_line(Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), Color("25221f"), 3.0)
	cv.draw_line(Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Color("25221f"), 3.0)
	if arch:
		cv.draw_arc(Vector2(r.get_center().x, r.position.y + 6), r.size.x * 0.5 + 5, PI, TAU, 16, Color("6a4a3e"), 9.0)


## The main disconnect for the dish, on a post where the path to it starts.
func _gate_box(era: String) -> void:
	var x := 1092.0
	cv.draw_rect(Rect2(x - 4, 470, 8, 180), Color("2a2c30"))
	var box := Rect2(x - 24, 478, 48, 60)
	cv.draw_rect(box, Color("5a6068") if era != "2009" else Color("4a3a30"))
	cv.draw_rect(box, Color("1e2228"), false, 2.0)
	cv.draw_line(Vector2(x + 16, 494), Vector2(x + 30, 514), Color("8a2a24"), 5.0)
	cv.draw_arc(Vector2(x + 10, 530), 6.0, PI, TAU, 8, Color("b8a050"), 2.0)
	cv.draw_rect(Rect2(x + 4, 530, 13, 11), Color("b8a050") if era != "2009" else Color("7a5a30"))
	Kit.text(cv, Vector2(box.position.x, box.position.y + 18), "DISH", 9, Color("e8e2cc"), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	if era != "2031":
		Townscape.snow_ledge(cv, box.position.x - 2, box.end.x + 2, box.position.y, 5.0, 21)


# --- the dish, out on the summit -------------------------------------------------------------

## Where the dish stands, well back across the summit, and how much it shrinks
## with the distance. In its own drawing (0, 0) is the ground under its middle.
const DISH_AT := Vector2(1010, 512)
const DISH_K := 0.78
const HUB := Vector2(0, -336)
const R := 214.0
const DEPTH := 78.0


## The 26-metre dish on its yoke, side on: the far arm, the bowl (its back
## ribbed with panels), the feed legs and the cabin, then the near arm and its
## ladder. Distance takes a little of its colour.
func _dish(e: Env, era: String) -> void:
	var haze := Color("1b2542")
	var steel := Color("272d38")
	var near := Color("323a48")
	var paint_a := Color("6a7484")
	var paint_b := Color("3a4250")
	var inner := Color("8a96aa")
	match era:
		"2031":
			haze = Color("c8d6e4")
			steel = Color("a8acb0")
			near = Color("c4c8cc")
			paint_a = Color("f4f6f8")
			paint_b = Color("b8c0c8")
			inner = Color("dfe6ee")
		"2009":
			haze = Color("1c2029")
			steel = Color("2a2420")
			near = Color("3a302a")
			paint_a = Color("6a5a4c")
			paint_b = Color("3a302a")
			inner = Color("d8dee8")
	var f := 0.22
	steel = steel.lerp(haze, f)
	near = near.lerp(haze, f)
	paint_a = paint_a.lerp(haze, f * 0.6)
	paint_b = paint_b.lerp(haze, f)
	cv.draw_set_transform(DISH_AT, 0.0, Vector2(DISH_K, DISH_K))
	var aim := _aim()
	var d := Vector2(cos(aim), sin(aim))
	var n := Vector2(-d.y, d.x)
	var v := HUB + d * 30.0
	var cr := v + d * DEPTH
	# The pedestal and its drive house.
	var c := steel.lightened(0.15)
	cv.draw_rect(Rect2(-132, -78, 264, 78), c)
	cv.draw_rect(Rect2(-132, -78, 264, 8), c.lightened(0.12))
	cv.draw_rect(Rect2(-112, -56, 46, 56), c.darkened(0.25))
	if era != "2031":
		cv.draw_colored_polygon(PackedVector2Array([Vector2(-136, -76), Vector2(136, -76), Vector2(130, -86), Vector2(-130, -86)]), Color("d8e0ec").lerp(haze, 0.2))
	_yoke(steel.darkened(0.25), Vector2(18, -8))
	# The bowl's back: a paraboloid side on, with its panel lines.
	var shell := PackedVector2Array()
	for i in 25:
		var u := -1.0 + i / 12.0
		shell.append(v + n * (R * u) + d * (DEPTH * u * u))
	_shaded(shell, paint_a, paint_b, cr + n * R, cr - n * R)
	for k in [0.35, 0.7, -0.35, -0.7]:
		var rib := PackedVector2Array()
		for i in 13:
			var s := i / 12.0
			rib.append(v + n * (R * s * k) + d * (DEPTH * s * s))
		cv.draw_polyline(rib, paint_b.darkened(0.25), 2.0, true)
	for s in [0.45, 0.75]:
		cv.draw_line(v + n * (-R * s) + d * (DEPTH * s * s), v + n * (R * s) + d * (DEPTH * s * s), paint_b.darkened(0.2), 2.0)
	if era == "2009":
		for i in 34:
			var w := -0.85 + Townscape.h(i * 3) * 1.7
			var q := 0.3 + Townscape.h(i * 7) * 0.6
			var p := v + n * (R * w) + d * lerpf(DEPTH * w * w, DEPTH, q)
			cv.draw_line(p, p - d * (5.0 + Townscape.h(i * 11) * 12.0), Color(0.42, 0.22, 0.12, 0.45 + 0.3 * Townscape.h(i)), 2.0 + 2.0 * Townscape.h(i * 5))
	# The rim, and a sliver of the inside (snow in it, in 2009).
	var rim := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		rim.append(cr + n * (R * cos(a)) + d * (R * 0.09 * sin(a)))
	cv.draw_colored_polygon(rim, inner.lerp(haze, f * 0.5))
	cv.draw_polyline(rim, paint_b.darkened(0.3), 2.5, true)
	# The feed legs and the cabin at the focus.
	var fc := cr + d * 128.0
	for p in [cr + n * R, cr - n * R]:
		cv.draw_line(p, fc, steel, 6.0)
	cv.draw_line(cr + d * (R * 0.09), fc, steel.lightened(0.1), 4.0)
	var low: Vector2 = cr + n * R if (cr + n * R).y > (cr - n * R).y else cr - n * R
	for k in 9:
		var p := low.lerp(fc, 0.08 + k * 0.1)
		var side := (fc - low).normalized().orthogonal() * 7.0
		cv.draw_line(p - side, p + side, steel.lightened(0.18), 1.5)
	cv.draw_set_transform(DISH_AT + fc * DISH_K, aim, Vector2(DISH_K, DISH_K))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(-26, -14), Vector2(-50, -7), Vector2(-50, 7), Vector2(-26, 14)]), steel.lightened(0.05))
	cv.draw_rect(Rect2(-26, -28, 60, 56), near.lightened(0.08))
	cv.draw_rect(Rect2(-26, -28, 60, 56), steel.darkened(0.3), false, 2.0)
	cv.draw_rect(Rect2(-14, -20, 22, 30), steel.darkened(0.1), false, 1.5)
	cv.draw_set_transform(DISH_AT, 0.0, Vector2(DISH_K, DISH_K))
	_yoke(near, Vector2.ZERO)
	# The ladder up the near arm.
	var foot := Vector2(-116, 0)
	var top := Vector2(-38, -310)
	var side2 := (top - foot).normalized().orthogonal() * 9.0
	cv.draw_line(foot - side2, top - side2, near.lightened(0.15), 2.5)
	cv.draw_line(foot + side2, top + side2, near.lightened(0.15), 2.5)
	for k in 14:
		var p := foot.lerp(top, (k + 0.5) / 14.0)
		cv.draw_line(p - side2, p + side2, near.lightened(0.15), 2.0)
	cv.draw_circle(HUB, 14.0, near.lightened(0.1))
	cv.draw_circle(HUB, 6.0, steel)
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## One arm of the yoke: a braced steel tower from the pedestal to the axle.
func _yoke(col: Color, off: Vector2) -> void:
	var bl := Vector2(-96, -76) + off
	var br := Vector2(96, -76) + off
	var tl := Vector2(-22, HUB.y + 10) + off
	var tr := Vector2(22, HUB.y + 10) + off
	cv.draw_line(bl, tl, col, 9.0)
	cv.draw_line(br, tr, col, 9.0)
	var steps := 5
	for k in steps:
		var a := bl.lerp(tl, float(k) / steps)
		var b := br.lerp(tr, float(k) / steps)
		var a2 := bl.lerp(tl, float(k + 1) / steps)
		var b2 := br.lerp(tr, float(k + 1) / steps)
		cv.draw_line(a, b2, col, 3.0)
		cv.draw_line(b, a2, col, 3.0)
		cv.draw_line(a, b, col, 3.0)
	cv.draw_colored_polygon(PackedVector2Array([tl + Vector2(-8, 0), tr + Vector2(8, 0), tr + Vector2(4, -30), tl + Vector2(-4, -30)]), col)


## Where the feed cabin is on screen.
func _cabin() -> Vector2:
	var aim := _aim()
	var d := Vector2(cos(aim), sin(aim))
	return DISH_AT + (HUB + d * (30.0 + DEPTH + 128.0)) * DISH_K


# --- 2031 --------------------------------------------------------------------------------

func _back_2031(e: Env) -> void:
	var sk: Array = e.sky()
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 600), sk[0], sk[1])
	Townscape.sky_extras(cv, e, Vector2(420, 70))
	cv.draw_colored_polygon(_ridge(392.0, 74.0, 3), e.shade(Color("8a8aa0")))
	_turbines_static()
	cv.draw_colored_polygon(_ridge(460.0, 40.0, 7), e.shade(Color("7a6a3e")))
	# Halvard, across the valley in the sun.
	for i in 50:
		var x := 300.0 + Townscape.h(i * 7) * 1400.0
		var y := 488.0 + Townscape.h(i * 11) * 40.0
		cv.draw_rect(Rect2(x, y, 9, 6), Color("e8e2d4").lerp(Color("8a5a48"), Townscape.h(i * 3)))
		cv.draw_colored_polygon(PackedVector2Array([Vector2(x - 1, y), Vector2(x + 4.5, y - 4), Vector2(x + 10, y)]), Color("6a4a3a"))
	# The summit: a lawn, the car park, the path.
	_summit(Color("7d8440"), Color("626a30"))
	Kit.vgrad(cv, Rect2(Kit.L, 600, Kit.R - Kit.L, 50), Color("6c7076"), Color("5a5e64"))
	cv.draw_rect(Rect2(640, 600, 520, 50), Color("4a5a3e"))
	for x in [640.0, 1160.0]:
		cv.draw_line(Vector2(x, 600), Vector2(x - 20, 650), Color("e8e8e0"), 3.0)
	cv.draw_rect(Rect2(Kit.L, 650, Kit.R - Kit.L, 130), Color("8e8c84"))
	cv.draw_line(Vector2(Kit.L, 651), Vector2(Kit.R, 651), Color("c8c4ba"), 3.0)
	# Maples turning, out on the summit, and the low fence round the dish.
	Townscape.tree(cv, Vector2(720, 562), 380.0, 5)
	Townscape.tree(cv, Vector2(1330, 556), 420.0, 9)
	for i in 30:
		var x := 700.0 + i * 34.0
		cv.draw_line(Vector2(x, 548), Vector2(x, 530), Color("6a6e74"), 2.0)
	cv.draw_line(Vector2(700, 534), Vector2(Kit.R, 534), Color("6a6e74"), 1.5)
	_dish(e, "2031")
	# The shuttle, waiting at its stop further back.
	cv.draw_line(Vector2(1300, 600), Vector2(1300, 380), Color("3a3e44"), 4.0)
	cv.draw_rect(Rect2(1284, 380, 34, 40), Color("2f5878"))
	Kit.text(cv, Vector2(1284, 406), "BUS", 11, Color("f2f0ea"), HORIZONTAL_ALIGNMENT_CENTER, 34)
	EraVehicles.shuttle_2031(cv, Vector2(1490, 600), 0.8, 0.0, {})
	_control_building("2031")
	_stone_wing("2031")
	# An electric car on charge in the green bay, a metre back from the path.
	EraVehicles.ev_2031(cv, Vector2(862, 634), 1.0, 0.0, {"charging": true, "body": Color("2f5878")})
	EraVehicles.charger_2031(cv, Vector2(1162, 634), 1.0, 0.0, {"in_use": true})
	# The interpretive sign where the path to the dish begins.
	cv.draw_line(Vector2(1244, 650), Vector2(1244, 560), Color("3a3e44"), 6.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1206, 514), Vector2(1282, 514), Vector2(1278, 566), Vector2(1210, 566)]), Color("2c3338"))
	for k in 4:
		cv.draw_line(Vector2(1216, 526 + k * 9), Vector2(1270 - k * 8, 526 + k * 9), Color("d8dcd6"), 1.0)
	cv.draw_circle(Vector2(1244, 556), 5.0, Color("c4502e"))


## The towers of the wind turbines on the far ridge; the blades turn in draw_anim().
const TURBINES := [Vector2(1200, 372), Vector2(1310, 360), Vector2(1450, 376), Vector2(1580, 366), Vector2(-300, 368)]


func _turbines_static() -> void:
	for p in TURBINES:
		var c := Color("eef0f2")
		cv.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p + Vector2(3, 0), p + Vector2(1.5, -110), p + Vector2(-1.5, -110)]), c)
		cv.draw_rect(Rect2(p + Vector2(-4, -116), Vector2(12, 7)), c)


# --- 2009 --------------------------------------------------------------------------------

func _back_2009(e: Env) -> void:
	var sk: Array = e.sky()
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 560), sk[0], sk[1])
	cv.draw_colored_polygon(_ridge(400.0, 70.0, 3), Color("0b0e16"))
	_white_wall()
	cv.draw_colored_polygon(_ridge(470.0, 36.0, 7), Color("0e121c"))
	# Halvard below: dark. Not one light.
	_summit(Color("3c4454"), Color("5a6476"))
	_far_fence(Color("12151c"))
	_dish(e, "2009")
	# Two cars abandoned in the lot, further back, snowed in for years.
	EraVehicles.sedan_2009(cv, Vector2(1110, 583), 0.73, 0.0, {"snow": 0.9})
	EraVehicles.suv_2009(cv, Vector2(860, 604), 0.85, 0.0, {"snow": 1.0})
	_ruin()
	_stone_wing("2009")
	_hut()
	_gate_box("2009")
	_lamp_line()
	_snow_ground()


## The white on the far ridge: a wall of static where the next valley was. It
## comes nearer as the visit goes on.
func _white_wall() -> void:
	var k := _white_steps()
	var x0 := 1060.0 - k * 120.0
	var top := 300.0 - k * 34.0
	var base := 440.0
	var n := 40
	var fog := Color(0.93, 0.95, 1.0, 0.22)
	var solid := Color(0.95, 0.97, 1.0, 0.97)
	var prev := Vector2.ZERO
	for i in n + 1:
		var x := lerpf(x0, Kit.R, float(i) / n)
		var rise := clampf(float(i) / 6.0, 0.0, 1.0)
		var p := Vector2(x, lerpf(base, top + 22.0 * sin(i * 0.9 + k) + 18.0 * Townscape.h(i * 7 + k), rise))
		if i > 0:
			cv.draw_polygon(PackedVector2Array([prev, p, Vector2(p.x, base), Vector2(prev.x, base)]), PackedColorArray([fog, fog, solid, solid]))
		prev = p
	for i in 10:
		var c := Vector2(lerpf(x0 + 70.0, Kit.R, i / 9.0), top + 34.0 + 22.0 * Townscape.h(i * 5 + k))
		Kit.soft_glow(cv, c, 80.0 + 50.0 * Townscape.h(i + k), Color(0.95, 0.97, 1.0, 0.45))
	for i in 34:
		var y := top + 30.0 + Townscape.h(i * 3) * (base - top - 30.0)
		var x := x0 + 80.0 + Townscape.h(i * 5) * (Kit.R - x0 - 80.0)
		cv.draw_line(Vector2(x, y), Vector2(x + 20.0 + 50.0 * Townscape.h(i), y), Color(0.75, 0.8, 0.9, 0.35), 1.0)
	Kit.soft_glow(cv, Vector2(x0 + 260, 410), 320.0, Color(0.9, 0.93, 1.0, 0.16))


## The roofless shell of the control building: walls broken off at every
## height, empty windows, and through the fallen front, the lobby's back wall
## with the spray paint on it.
func _ruin() -> void:
	var conc := Color("2e3238")
	var top := PackedVector2Array([Vector2(Kit.L, 650), Vector2(Kit.L, 190)])
	var xs := [-380.0, -300.0, -230.0, -170.0, -120.0, -60.0, -30.0, 40.0, 130.0, 190.0, 236.0]
	var ys := [176.0, 214.0, 168.0, 246.0, 222.0, 330.0, 372.0, 352.0, 300.0, 250.0, 262.0]
	for i in xs.size():
		top.append(Vector2(xs[i], ys[i]))
	top.append(Vector2(236, 650))
	cv.draw_colored_polygon(top, conc)
	# Through the gap: the lobby's back wall, the paint, snow on the floor.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(-60, 650), Vector2(-60, 330), Vector2(-30, 372), Vector2(40, 352),
		Vector2(130, 300), Vector2(236, 330), Vector2(236, 650)]), Color("24262a"))
	cv.draw_rect(Rect2(-50, 390, 286, 260), Color("2b2d31"))
	var red := Color(0.66, 0.15, 0.12, 0.92)
	Kit.text(cv, Vector2(6, 440), "THEY CAME OUT", 28, red)
	Kit.text(cv, Vector2(26, 478), "OF THE DARK", 28, red)
	Kit.text(cv, Vector2(34, 516), "COUNT YOURSELF", 17, Color(0.86, 0.86, 0.8, 0.78))
	for i in 6:
		cv.draw_line(Vector2(16 + i * 36, 446), Vector2(17 + i * 36, 456 + Townscape.h(i) * 18), Color(red, 0.6), 3.0)
	# Window holes, snow on their sills and drifted in.
	for i in 3:
		var w := Rect2(-420 + i * 124, 410, 108, 134)
		cv.draw_rect(w, Color("07080b"))
		Townscape.snow_ledge(cv, w.position.x - 2, w.end.x + 2, w.end.y, 6.0, i)
	Townscape.snowbank(cv, -70, 236, 650, 46.0, 14)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(120, 650), Vector2(170, 560), Vector2(236, 600), Vector2(236, 650)]), conc.lightened(0.06))
	for i in xs.size() - 1:
		Townscape.snow_ledge(cv, xs[i], xs[i + 1], minf(ys[i], ys[i + 1]) + 2.0, 5.0, i)


## The equipment hut by the path to the dish, where Tomas lives outside the
## line: corrugated iron, a stovepipe, a lamp in the window, a woodpile.
func _hut() -> void:
	var r := Rect2(1176, 380, 340, 270)
	cv.draw_rect(r, Color("3a3e44"))
	for i in 25:
		cv.draw_line(Vector2(r.position.x + 7 + i * 14, r.position.y), Vector2(r.position.x + 7 + i * 14, r.end.y), Color("2a2e34"), 3.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1164, 386), Vector2(1528, 398), Vector2(1528, 380), Vector2(1164, 360)]), Color("2a2c30"))
	Townscape.snow_ledge(cv, 1162, 1530, 368, 12.0, 41)
	var door := Rect2(1210, 430, 100, 220)
	cv.draw_rect(door, Color("2a2622"))
	cv.draw_rect(door, Color("1a1612"), false, 3.0)
	cv.draw_circle(Vector2(door.end.x - 14, door.position.y + 120), 4.0, Color("8a8478"))
	# Papers in plastic sleeves, tacked to the door: a yellowed clipping
	# over a printout folded many times.
	var clip := Rect2(1258, 468, 36, 34)
	var sheet := Rect2(1266, 494, 36, 44)
	cv.draw_rect(sheet, Color("dcdad2"))
	for k in 7:
		cv.draw_line(sheet.position + Vector2(4, 8 + k * 5), sheet.position + Vector2(32, 8 + k * 5), Color(0.35, 0.35, 0.38, 0.55), 1.0)
	cv.draw_line(sheet.position + Vector2(0, 22), sheet.position + Vector2(36, 22), Color(0, 0, 0, 0.12), 1.0)
	cv.draw_rect(clip, Color("cdbd8c"))
	cv.draw_rect(Rect2(clip.position + Vector2(3, 4), Vector2(30, 4)), Color("3a3428"))
	for k in 4:
		cv.draw_line(clip.position + Vector2(3, 13 + k * 5), clip.position + Vector2(31, 13 + k * 5), Color(0.3, 0.27, 0.2, 0.6), 1.0)
	cv.draw_line(clip.position + Vector2(2, 2), clip.position + Vector2(20, 2), Color("1a1a6a"), 2.0)
	for sl: Rect2 in [clip, sheet]:
		cv.draw_line(sl.position + Vector2(6, 2), sl.position + Vector2(18, sl.size.y - 2), Color(1, 1, 1, 0.18), 3.0)
		cv.draw_circle(sl.position + Vector2(sl.size.x * 0.5, 1), 2.5, Color("9a9488"))
	_lamp_window(Rect2(1352, 450, 96, 84), false)
	cv.draw_line(Vector2(1480, 380), Vector2(1480, 200), Color("1a1c20"), 10.0)
	for i in 9:
		var p := Vector2(1352 + (i % 3) * 26, 636 - (i / 3) * 22)
		cv.draw_circle(p, 12.0, Color("5a4030"))
		cv.draw_circle(p, 6.0, Color("8a6a48"))


## The lamp line: hurricane lamps on posts in front of the stone wing, a rope
## between them. Newcomers stay outside it.
const LINE_POSTS := [262.0, 330.0, 398.0, 466.0, 534.0]


func _lamp_line() -> void:
	for i in LINE_POSTS.size():
		var x: float = LINE_POSTS[i]
		cv.draw_line(Vector2(x, 652), Vector2(x, 534), Color("2a2622"), 6.0)
		cv.draw_rect(Rect2(x - 9, 504, 18, 30), Color("3a3430"))
		cv.draw_rect(Rect2(x - 11, 500, 22, 5), Color("2a2622"))
		if i > 0:
			var pts := PackedVector2Array()
			for k in 9:
				var u := k / 8.0
				pts.append(Vector2(lerpf(LINE_POSTS[i - 1], x, u), 548.0 + sin(u * PI) * 12.0))
			cv.draw_polyline(pts, Color("6a5a40"), 2.5, true)
	# A string of bulbs along the string course, between the floors.
	for k in 18:
		var p := Vector2(250 + k * 22.0, 300 + sin(k * 0.6) * 3.0)
		cv.draw_circle(p, 3.5, Color("6a5a40"))


func draw_anim(ci: CanvasItem) -> void:
	if _era() == "2031":
		for i in TURBINES.size():
			var hub: Vector2 = TURBINES[i] + Vector2(6, -112)
			var a0 := t * (0.9 + i * 0.13) + i
			for b in 3:
				var a := a0 + b * TAU / 3.0
				ci.draw_line(hub, hub + Vector2(cos(a), sin(a)) * 46.0, Color("f4f6f8"), 2.5)
			ci.draw_circle(hub, 3.0, Color("d8dcdf"))
	elif _era() == "2009":
		# The white, crawling.
		var k := _white_steps()
		var x0 := 1060.0 - k * 120.0
		for i in 6:
			var y := 300.0 + fposmod(i * 37.0 + t * 26.0, 130.0)
			ci.draw_line(Vector2(x0 + 60, y), Vector2(Kit.R, y + 2), Color(1, 1, 1, 0.12), 2.0)


func draw_glow(ci: CanvasItem) -> void:
	match _era():
		"2009":
			for x in LINE_POSTS:
				Kit.soft_glow(ci, Vector2(x, 519), 46.0, Color(1.0, 0.72, 0.38, 0.5 + 0.08 * sin(t * 5.0 + x)))
				ci.draw_rect(Rect2(x - 5, 510, 10, 18), Color(1.0, 0.86, 0.55, 0.9))
			for k in 18:
				ci.draw_circle(Vector2(250 + k * 22.0, 303 + sin(k * 0.6) * 3.0), 2.5, Color(1.0, 0.85, 0.55, 0.85))
			Kit.soft_glow(ci, Vector2(1400, 492), 70.0, Color(1.0, 0.7, 0.35, 0.3))
			if coupling > 0.0:
				var f := _cabin()
				Kit.soft_glow(ci, f, 90.0 * coupling, Color(1.0, 0.95, 0.85, 0.85 * coupling))
				Kit.soft_glow(ci, f, 30.0, Color(1, 1, 1, coupling))
		"2031":
			pass
		_:
			Kit.soft_glow(ci, Vector2(747, 132), 90.0, Color(1.0, 0.65, 0.3, 0.25))
			ci.draw_rect(Rect2(724, 124, 46, 6), Color("ffd8a0"))
			Kit.soft_glow(ci, Vector2(134, 470), 90.0, Color(1.0, 0.9, 0.7, 0.14))
			Kit.soft_glow(ci, Vector2(21, 428), 30.0, Color(1.0, 0.85, 0.6, 0.3))


## The lot's sodium lamp, full size: a five-metre pole and a cobra head.
func _lamp_post(x: float) -> void:
	var c := Color("23252b")
	cv.draw_rect(Rect2(x - 10, 618, 20, 32), c)
	cv.draw_rect(Rect2(x - 6, 120, 12, 500), c)
	cv.draw_line(Vector2(x, 132), Vector2(x + 58, 112), c, 7.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(x + 50, 102), Vector2(x + 122, 104), Vector2(x + 114, 124), Vector2(x + 56, 124)]), Color("3a3c42"))
	cv.draw_rect(Rect2(x + 60, 124, 46, 6), Color("ffd8a0"))
	Townscape.snow_ledge(cv, x + 50, x + 122, 103, 6.0, int(x))
