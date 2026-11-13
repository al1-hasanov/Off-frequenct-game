extends Room
## The opening, part 3: the clearing below Halvard Observatory, October 14,
## 1980, a little after two in the morning. Mara comes back across the snow
## from fixing receiver 2. Tomas has his radio up over his head. She holds the
## light while he fixes it, and for one song they share his headphones. Then
## she turns her back to lock the gate, and he's gone.
##
## Act 2.6: the same night from the treeline, in frequency 12. Mara is the
## figure at the trees, and makes Choice 2: take Tomas, or leave him. Their
## song is playing on his radio when she gets there.

const TOMAS_X := 560.0

var tomas: Actor
var figure: Actor
var snow: Snowfall
var mara80: Actor
## For one song they share his headphones: the band's drawn between them.
var sharing := false
## Tomas's footprints in the snow end here (0: not walked yet).
var prints_to := 0.0
## Where his flashlight lies once he's gone (ZERO: still in his hand).
var dropped := Vector2.ZERO
var _lock_tries := 0
var _ending := false


func setup() -> void:
	if freq == "12":
		_setup_12()
		return
	animated_back = false
	place_name = "Halvard Observatory · October 14, 1980"
	base_tint = Color(0.82, 0.87, 1.0)
	walk_min = 150.0
	walk_max = 1180.0
	walk_top = 470.0
	figure = add_actor("silhouette", 1188.0, -1)
	figure.position.y = 486.0
	figure.scale = Vector2(0.42, 0.42)
	figure.visible = false
	tomas = add_actor("tomas", TOMAS_X, 1)
	tomas.prop = "radio_up"
	make_player(1240.0, -1, "mara_1980")
	player.step_sound = "step_snow"
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 790)
	snow.count = 230
	snow.wind = 42.0
	add_child(snow)

	var near := func() -> bool: return tomas.visible and prints_to == 0.0
	var far := func() -> bool: return tomas.visible and prints_to > 0.0
	add_hotspot("tomas", Rect2(TOMAS_X - 50, 470, 100, 190), "Tomas", TOMAS_X + 70.0, -1, near)
	add_hotspot("tomas_far", Rect2(760, 470, 120, 190), "Tomas", NAN, 0, far)
	add_hotspot("padlock", Rect2(370, 528, 64, 64), "Gate padlock", 420.0, -1)
	add_hotspot("truck", Rect2(-10, 466, 330, 184), "The truck", 250.0, -1)
	add_hotspot("observatory", Rect2(880, 230, 330, 240), "The observatory")
	add_hotspot("flashlight", Rect2(0, 0, 0, 0), "The flashlight", NAN, 1, func() -> bool: return dropped != Vector2.ZERO)


func enter(_entry: String) -> void:
	if freq == "H":
		GameState.set_clock("2:12")


func score_quiet() -> bool:
	return true


func static_key() -> String:
	return "%d|%s" % [int(prints_to / 13.0), dropped]


func _process(delta: float) -> void:
	super(delta)
	if freq != "H" or tomas == null:
		return
	if tomas.visible and tomas.walking and tomas.position.x > TOMAS_X + 8.0:
		prints_to = maxf(prints_to, tomas.position.x)
	# She goes to look. Walking there is enough.
	if dropped != Vector2.ZERO and not _ending and player.position.x > dropped.x - 120.0 and main != null and not main.is_busy():
		main.run(_footprints_end)


func on_arrive() -> void:
	if freq == "12":
		await _arrive_12()
		return
	Audio.stop_all(0.3)
	Audio.play_loop("wind", -12.0)
	Audio.play_loop("truck_idle", -30.0)  # Mara's truck by the gate, the heater on for Tomas
	Audio.play_loop("static", -28.0)  # his radio, hunting for a station
	if GameState.has("p1_started"):
		return
	GameState.set_flag("p1_started")
	GameState.set_objective("")
	await wait(0.6)
	await player.walk_to(700.0)
	await mara("Please tell me that isn't improving reception.")
	await say("TOMAS", "It was. Then you started talking.")
	tomas.prop = "radio"
	Audio.loop_volume("static", -18.0)
	await wait(0.35)
	Audio.stop_loop("static", 0.08)
	await narrate("He lowers it. The speaker crackles, and cuts out.")
	await say("TOMAS", "Hold this?")
	Audio.sfx("click", -12.0)
	player.holding_light = true
	await narrate("He gives her his flashlight, and turns the radio round. Its back is off.")
	await player.walk_to(TOMAS_X + 72.0)
	player.face(-1)
	GameState.set_objective("Hold the light for Tomas.")
	var fix := RadioFix.new()
	hud.root.add_child(fix)
	await fix.run()
	GameState.set_flag("radio_fixed")
	GameState.set_objective("")
	await mara("That connection needs solder.")
	await say("TOMAS", "I know. I ran out.")
	await mara("There's some in my—")
	await say("TOMAS", "Ran out of yours too.")
	await narrate("Mara looks at him.")
	await say("TOMAS", "I was going to tell you.")
	# Their song: on the radio, then (in time with it) in his headphones.
	Audio.play_loop("song_radio", -13.0, 0.05)
	Audio.play_loop("song_clear", -60.0, 0.0)
	hud.caption("Music, out of the little speaker. A few clear notes.", 3.0)
	await wait(2.6)
	await narrate("Tomas freezes. Then he turns to her, delighted.")
	await say("TOMAS", "There.")
	await narrate("He holds out one side of his headphones.")
	await hud.choose(["Listen"])
	await _share(true)
	await wait(4.0)
	await mara("You built that.")
	await say("TOMAS", "Mostly.")
	await mara("That means yes.")
	await narrate("He smiles without looking at her.")
	await wait(2.0)
	await _share(false)
	await wait(1.2)
	await say("TOMAS", "It gets better near the trees.")
	await mara("We're leaving.")
	await say("TOMAS", "Two more minutes.")
	await mara("That's what Henrik said.")
	await say("TOMAS", "I learned from a professional.")
	await narrate("Mara hands him the flashlight.")
	player.holding_light = false
	tomas.prop = "radio_light"
	Audio.sfx("click", -12.0)
	await mara("Two minutes. I'm locking the gate.")
	# The goodbye the two of them always say when he goes off to listen
	# (story SIGNOFF): it comes back all through the night in 1983.
	await narrate("And what she always says when he goes off to listen:")
	var pick: int = await hud.choose([
		"\"%s\"" % Story.SIGNOFFS.over[0], "\"%s\"" % Story.SIGNOFFS.light[0], "\"%s\"" % Story.SIGNOFFS.dial[0]])
	var key: String = Story.SIGNOFF_ORDER[pick]
	GameState.set_story("SIGNOFF", key)
	await mara(Story.SIGNOFFS[key][0])
	await say("TOMAS", Story.SIGNOFFS[key][1])
	GameState.set_flag("p1_talked")
	GameState.set_objective("Lock the gate.")
	Audio.play_loop("static", -30.0)
	# A few steps along the edge of the clearing, the light out in front of him.
	tomas.speed = 62.0
	tomas.walk_to(TOMAS_X + 270.0)


## The song in his headphones: she leans in, the wind drops away, and the
## music is clear. share(false): it fades back into the interference.
func _share(on: bool) -> void:
	if on:
		await player.walk_to(tomas.position.x + 44.0)
		player.face(-1)
		tomas.face(1)
		tomas.headphones_mode = "off"
		player.head_tilt = 0.24
		tomas.head_tilt = -0.06
		sharing = true
		Audio.play_loop("song_radio", -60.0, 1.4)
		Audio.play_loop("song_clear", -7.0, 1.4)
		Audio.play_loop("wind", -30.0, 1.6)
		Audio.play_loop("truck_idle", -46.0, 1.6)
	else:
		Audio.play_loop("song_clear", -60.0, 3.0)
		Audio.play_loop("song_radio", -17.0, 2.0)
		Audio.play_loop("static", -24.0, 3.0)
		Audio.play_loop("wind", -12.0, 3.0)
		Audio.play_loop("truck_idle", -30.0, 3.0)
		await wait(2.0)
		sharing = false
		tomas.headphones_mode = ""
		player.head_tilt = 0.0
		tomas.head_tilt = 0.0
		await player.walk_to(tomas.position.x + 76.0)
		Audio.stop_loop("song_clear", 0.5)
		Audio.play_loop("song_radio", -60.0, 2.5)
		get_tree().create_timer(2.6).timeout.connect(func() -> void: Audio.stop_loop("song_radio", 0.1))


func on_hotspot(id: String) -> void:
	if freq == "12":
		await _hotspot_12(id)
		return
	match id:
		"tomas", "tomas_far":
			if GameState.has("p1_talked"):
				await say("TOMAS", "Two minutes! You said!")
			else:
				await say("TOMAS", "Shh. Listen.")
		"padlock":
			if not GameState.has("p1_talked"):
				await mara("Not till he's in the truck.")
			elif dropped == Vector2.ZERO:
				await _lock()
			else:
				await mara("Tomas?")
		"truck":
			if dropped != Vector2.ZERO:
				await mara("Tomas? Are you in the truck?")
				await narrate("The cab's empty. The heater's still running.")
			else:
				await mara("Engine's running, heater's on. He'll come. He always comes.")
		"observatory":
			await mara("Receiver two's fine. For now. Henrik can have it back.")
		"flashlight":
			await _footprints_end()


## The lock sticks. Behind her, the radio comes clear. Three goes at it.
func _lock() -> void:
	_lock_tries += 1
	player.face(-1)
	match _lock_tries:
		1:
			Audio.sfx("lock", -6.0)
			await mara("Come on...")
			Audio.stop_loop("static", 0.4)
			Audio.play_loop("carrier", -19.0, 0.8)
			hud.caption("Behind her, the radio comes clear.", 2.6)
			await wait(1.0)
			await say("TOMAS", "Mara?")
			await mara("Nearly done.")
			GameState.set_objective("The lock's sticking. Keep at it.")
		2:
			Audio.sfx("lock", -5.0, 0.92)
			await wait(0.4)
			await say("TOMAS", "It knows my name.")
		_:
			await _vanish()


## The key turns, and the radio stops.
func _vanish() -> void:
	Audio.sfx("thunk", -6.0)
	await narrate("The key turns.")
	Audio.stop_loop("carrier", 0.02)
	Audio.stop_loop("song_radio", 0.02)
	var p := tomas.position
	tomas.visible = false
	prints_to = maxf(prints_to, p.x)
	dropped = Vector2(p.x + 20.0, p.y + 2.0)
	get_hotspot("flashlight").rect = Rect2(dropped.x - 50.0, 600.0, 110.0, 70.0)
	GameState.set_objective("")
	await wait(0.5)
	# One frame at the treeline that almost nobody will see. Ending E explains it.
	figure.visible = true
	await wait(0.07)
	figure.visible = false
	await wait(1.0)
	player.face(1)
	await wait(0.7)
	await narrate("The radio has stopped. The flashlight is lying in the snow.")
	await mara("Tomas?")
	GameState.set_flag("p1_vanished")


## Where his footprints stop: she goes to look.
func _footprints_end() -> void:
	if _ending:
		return
	_ending = true
	await player.walk_to(dropped.x - 64.0)
	player.face(1)
	await wait(0.5)
	await narrate("His footprints lead away from the truck. Halfway across the clearing, they end.")
	await mara("Tomas, this isn't funny.")
	await narrate("She looks toward the trees.")
	await mara("TOMAS!")
	GameState.set_flag("p1_done")
	GameState.set_objective("")
	Audio.stop_all(0.05)
	await hud.fade_out(0.05)
	await wait(1.6)
	main.change_room("intro_after")


func draw_back() -> void:
	IntroArt.clearing(cv)
	if freq == "12":
		IntroArt.footprints(cv, 470.0, 1000.0, 654.0)
	elif prints_to > 0.0:
		IntroArt.footprints(cv, TOMAS_X + 26.0, prints_to, 652.0)
	Vehicles.pickup(cv, Vector2(50, 646), 1.0, 0.0, {"engine": true, "lights": true, "beam": 560.0, "ruts": 360.0,
		"snow": 0.55, "vapour": false})
	IntroArt.gate(cv)
	if dropped != Vector2.ZERO:
		IntroArt.dropped_flashlight(cv, dropped, 0.0)


## The masts blink, the truck's exhaust drifts, and for one song the two of
## them share his headphones.
func draw_anim(ci: CanvasItem) -> void:
	IntroArt.mast_lights(ci, t)
	Vehicles.pickup_exhaust(ci, Vector2(50, 646), 1.0, t)
	if sharing:
		var a := tomas.position + Vector2(-3.0, -0.86 * 152.0)
		var b := player.position + Vector2(3.0, -0.87 * 188.0)
		var mid := a.lerp(b, 0.5) + Vector2(0, -26.0)
		ci.draw_polyline(Figure.smooth(PackedVector2Array([a, mid, b]), 6, false), Color("26292e"), 3.2, true)
		for p in [a, b]:
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -7), p + Vector2(5, -7), p + Vector2(6, 7), p + Vector2(-6, 7)]), Color("2c3036"))
			ci.draw_circle(p, 3.0, Color("3e434a"))


## Light: Tomas's flashlight out ahead of him, then lying in the snow.
func draw_glow(ci: CanvasItem) -> void:
	if freq != "H":
		return
	if dropped != Vector2.ZERO:
		IntroArt.dropped_flashlight(ci, dropped, 1.0)
	elif tomas.visible and tomas.prop == "radio_light":
		var hand := tomas.position + Vector2(tomas.facing * 34.0, -78.0)
		var warm := Color(1.0, 0.94, 0.72)
		var d := float(tomas.facing)
		ci.draw_polygon(PackedVector2Array([hand + Vector2(0, -3), hand + Vector2(d * 200.0, 70.0), hand + Vector2(d * 120.0, 90.0), hand + Vector2(0, 3)]),
			PackedColorArray([Color(warm, 0.4), Color(warm, 0.0), Color(warm, 0.0), Color(warm, 0.4)]))
		ci.draw_set_transform(hand + Vector2(d * 170.0, 82.0), 0.0, Vector2(1.0, 0.25))
		ci.draw_circle(Vector2.ZERO, 60.0, Color(warm, 0.12))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Act 2.6: frequency 12 ------------------------------------------------------

func _setup_12() -> void:
	animated_back = false
	place_name = "Halvard Observatory · October 14, 1980"
	base_tint = Color(0.82, 0.87, 1.0)
	walk_min = 860.0
	walk_max = 1230.0
	tomas = add_actor("tomas", 1010.0, 1)
	tomas.buttoned = true  # twelve's Tomas lets Ma do his top button up
	mara80 = add_actor("mara_1980", -120.0, 1)
	make_player(1210.0, -1)
	player.step_sound = "step_snow"
	snow = Snowfall.new()
	snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 790)
	snow.count = 230
	snow.wind = 42.0
	add_child(snow)
	add_hotspot("tomas", Rect2(962, 470, 100, 190), "Tomas", 1120.0, -1, func() -> bool: return tomas.visible)
	add_hotspot("truck", Rect2(-10, 466, 330, 184), "The truck", NAN)
	add_hotspot("observatory", Rect2(880, 230, 330, 240), "The observatory", NAN)


func _arrive_12() -> void:
	Audio.stop_all(0.3)
	Audio.play_loop("wind", -10.0)
	Audio.play_loop("truck_idle", -30.0)
	if GameState.has("choice2"):
		Audio.play_loop("static", -30.0)
		return
	# Their song, on his radio: the minutes before the gate.
	Audio.play_loop("song_radio", -15.0, 0.6)
	hud.caption("Music on Tomas's radio. That song.", 3.0)
	await wait(2.8)
	await mara("...That song.")
	await mara("I know where I am. A few minutes before the gate.")
	Audio.play_loop("song_radio", -60.0, 2.4)
	Audio.play_loop("static", -30.0, 2.0)
	get_tree().create_timer(2.5).timeout.connect(func() -> void: Audio.stop_loop("song_radio", 0.1))
	await wait(1.0)
	await say("MARA (1980)", "Tomas! Two minutes, I said!")
	await mara("That's me. Behind the building. Calling him.")
	await mara("And I'm standing at the trees. I'm the one at the trees.")
	await say("TOMAS", "Mara?")
	tomas.face(1)
	await say("TOMAS", "You look old.")
	await mara("Hi, Tomas.")
	await say("TOMAS", "It told me to come to the trees. It said you'd be here.")
	await mara("His coat's done up to the top button.")
	await mara("Mine never kept it done up for a second. \"I can't breathe like that.\"")
	await mara("This is twelve's 1980. Not mine. Whatever I do here, my Tomas is still gone.")
	GameState.set_flag("saw_top_button")
	objective()


func _hotspot_12(id: String) -> void:
	match id:
		"tomas":
			await _choice2()
		"truck":
			await mara("My truck. The heater's running. In a minute I'll be standing there screaming his name.")
		"observatory":
			await mara("The dish. It's turning toward the trees. Toward us.")


func _choice2() -> void:
	if GameState.has("choice2"):
		return
	await say("TOMAS", "Is it you? From the radio?")
	await _tomas_questions()
	var pick: int = await hud.choose(["Take him with you", "Send him back to his sister"])
	GameState.set_flag("choice2")
	if pick == 0:
		GameState.set_story("TOMAS", "taken")
		await mara("Come with me. Right now. Don't look back.")
		await say("TOMAS", "Where are we going?")
		await mara("Somewhere you don't disappear.")
		Audio.stop_loop("static", 0.4)
		tomas.walk_to(1300.0)
		await player.walk_to(1290.0)
		await wait(0.6)
		await say("MARA (1980)", "Tomas? TOMAS!")
		await narrate("Behind them, his footprints run halfway across the snow, and stop.")
	else:
		GameState.set_story("TOMAS", "left")
		await mara("Go to your sister. Get in the truck.")
		await mara("And turn that radio off.")
		await say("TOMAS", "...Okay.")
		# Their goodbye. His answer isn't hers: this Tomas belongs to someone else.
		await mara(Story.signoff_line())
		await say("TOMAS", "...%s" % Story.signoff_reply(1))
		await mara("That's not what we said. That's theirs.")
		GameState.set_flag("tomas12_goodbye")
		Audio.stop_loop("static", 0.6)
		mara80.walk_to(620.0)
		await tomas.walk_to(680.0)
		await narrate("The other Mara grabs him so hard his headphones fall into the snow.")
		await say("MARA (1980)", "Don't you ever. Don't you ever do that.")
		tomas.face(1)
		await wait(0.8)
		await narrate("Over her shoulder, Tomas looks back at the trees. The woman there is gone.")
		player.walk_to(1300.0)
		await wait(0.8)
		await narrate("In frequency 12, Tomas Lind never vanishes.")
	await hud.fade_out(1.2)
	await narrate("Down the access road to Ma's truck. Down the mountain. In by the diner's back door.")
	main.change_room("diner", "return")


## Before Choice 2, Tomas gets to ask, and to say why he's out here at all.
func _tomas_questions() -> void:
	var asked := {}
	var labels := {
		"why": "\"Who told you to come to the trees?\"",
		"need": "\"I came a long way for you.\"",
		"sister": "\"Your sister's calling you.\"",
	}
	while asked.size() < 3:
		var opts: Array[String] = []
		var keys: Array[String] = []
		for k in ["why", "need", "sister"]:
			if not asked.has(k):
				opts.append(labels[k])
				keys.append(k)
		opts.append("Decide.")
		var pick: int = await hud.choose(opts)
		if pick >= keys.size():
			return
		var k: String = keys[pick]
		asked[k] = true
		match k:
			"why":
				await say("TOMAS", "The lady on 2.14. She sounds like you, but tired.")
				await say("TOMAS", "She says she's stuck somewhere dark and can't find the way out. I've been looking for her for weeks.")
				await say("TOMAS", "Tonight she said, come to the trees.")
				await mara("...You've been trying to rescue me.")
				await say("TOMAS", "Somebody has to.")
				GameState.set_flag("tomas_goal")
			"need":
				await say("TOMAS", "Why do you need me so bad? You're crying.")
				await mara("Because where I'm from, you walked into these trees tonight and nobody ever found you.")
				await say("TOMAS", "...Oh.")
				await say("TOMAS", "Did you look?")
				await mara("For three years.")
			"sister":
				await say("TOMAS", "She's going to be so mad.")
				await say("TOMAS", "If I go with you... is she going to be okay?")
				await mara("No. She'll look for you for three years. Like I did.")
				await say("TOMAS", "Then why would you—")
				await mara("I don't know yet.")
