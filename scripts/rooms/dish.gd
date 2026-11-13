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
## 2009, a wet October afternoon: the concrete building is a roofless shell,
## the town below has lost half its roofs. A rope across the path with
## hand-painted boards, Mrs. Lund at the gate beside an empty chair, a
## digital-TV poster and a pile of dead aerials; under the dish, Tomas at the
## coupling handle. On the far ridge, the white.

## Everything here is drawn to the people's scale, about 110 px to the metre
## on the line they walk: doors two and a quarter metres tall, the stone wing's
## two storeys running up out of the picture, cars full size a metre back in
## the lot. The dish stands well back across the summit, so distance shrinks it.

var snow: Snowfall
var tomas: Actor
var lund_w: Actor
var visitor_a: Actor
var visitor_b: Actor
## 2009: the coupling handle, 0 = home in its socket (the dish listening),
## 1 = pulled clear. It creeps back by itself: the pawl is worn smooth.
var handle := 0.0
## 2009: the rope across the path, lifted once Mrs. Lund lets Mara through.
var rope_up := false
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
	walk_min = 90.0
	walk_max = 1060.0 if GameState.has("lund_gate") else 540.0
	rope_up = GameState.has("lund_gate")
	lund_w = add_actor("lund_w_2009", 600.0, -1)
	lund_w.seated = true
	lund_w.seat_y = 46.0
	tomas = add_actor("tomas_2009", 1156.0, -1)
	tomas.arm_pose = PUSH
	add_hotspot("lund", Rect2(560, 470, 84, 180), "Mrs. Lund", 520.0, 1)
	add_hotspot("chair", Rect2(470, 560, 70, 90), "Empty chair", 450.0, 1)
	add_hotspot("rope", Rect2(650, 470, 120, 110), "The rope", 520.0, 1)
	add_hotspot("poster", Rect2(792, 430, 82, 112), "Poster", NAN)
	add_hotspot("aerials", Rect2(880, 520, 120, 124), "Aerials", NAN)
	add_hotspot("tomas", Rect2(1110, 440, 92, 210), "The man at the dish", 1050.0, 1, func() -> bool: return GameState.has("lund_gate"))
	add_hotspot("graffiti", Rect2(0, 400, 236, 140), "The old lobby", NAN)
	add_hotspot("white", Rect2(1240, 160, 300, 160), "The far ridge", NAN)
	add_hotspot("ladder", Rect2(830, 60, 340, 360), "The dish", NAN)


## Tomas's shoulder against the handle; both hands on it, pulling.
const PUSH := [[1.45, 0.55], [1.35, 0.7]]
const PULL := [[0.95, 0.35], [0.85, 0.4]]


func enter(entry: String) -> void:
	entered_from = entry
	match entry:
		"from_lobby", "from_center":
			player.position.x = 170.0
			player.face(1)
		_:
			if _era() == "2009":
				player.position.x = 150.0
				player.face(1)
			else:
				player.position.x = {"2031": 1100.0}.get(_era(), 1150.0)
				player.face(-1)


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	match _era():
		"2031":
			Audio.play_loop("wind", -32.0)
			Audio.play_loop("street_air", -30.0)
		"2009":
			Audio.play_loop("wind", -24.0)
			Audio.play_loop("rain", -30.0)
			Audio.play_loop("drone", -34.0)
		_:
			Audio.play_loop("wind", -18.0)
			if not GameState.has("dish_parked"):
				Audio.play_loop("dish_motor", -30.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	match entered_from:
		"arrive":
			await _arrive()
		"wake":
			await _wake()
		_:
			if _era() == "" and not GameState.has("dish_seen"):
				GameState.set_flag("dish_seen")
				await wait(0.3)
				await mara("Snow on everything. And the dish...")
				await mara("It's swung right round to the horizon. Nobody's touched the drive.")
	objective()


func _arrive() -> void:
	await wait(0.5)
	match _era():
		"2031":
			await mara("Daylight. Leaves. October, and no snow, and the sun's out.")
			await mara("The dish is white. Somebody painted it. There's a fence round it.")
			await narrate("Visitors walk the path, speaking in whispers. In the trees, birds open their beaks. Mara cannot hear them.")
			await narrate("One visitor is tapping a small black rectangle of glass. Mara takes it for a pocket radio.")
			await say("VISITOR", "(whispering) ...still nothing on mine. Not even static. Months, now. My grandmother says it's like the war.")
			await say("VISITOR", "(whispering) They say the dish heard it first. Back in the eighties.")
			await mara("They're whispering because nothing else makes a sound.")
			GameState.set_flag("heard_visitors")
		"2009":
			await narrate("The feed cabin opens onto wet October grass. The dish is still there. The town below it has lost half its roofs.")
			await mara("Twenty-six years. It looks like somebody left the window open for twenty-six years.")
			await narrate("A rope crosses the path. On it, hand-painted boards: ONE AT A TIME. SHOW YOUR HANDS. KEEP A LIGHT.")


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
		await mara("The cabin floor. Snow. Two-fourteen. 1983. And Ma's tape, still in my hand.")
		if g.has_item("cassette_2031"):
			Audio.play_loop("tape_hiss", -20.0, 0.2)
			await narrate("As she climbs down, the label goes pale, then the cassette, like a station drifting out of tune.")
			Audio.stop_loop("tape_hiss", 1.4)
			g.remove_item("cassette_2031")
			g.set_flag("cassette_faded")
			await wait(0.6)
			await mara("Gone.")
		await say("JUNE (TUNER)", "A future's a signal, honey, not a station. You can listen to it. You can't take it home.")
		await mara("My notebook's still here. What I drew in it.")
		await say("JUNE (TUNER)", "Well, that's not from there. That's from you. Write the rest down while you've got it.")
		await hud.read_doc("MY NOTEBOOK", ["The numbered stations let me bring things across.\n\nA thing from one of the dish's years faded when I left.\n\nDon't count on a person from there staying either."])
		g.set_flag("note_futures")
	elif g.has("been_2009") and not g.has("woke_2009"):
		g.set_flag("woke_2009")
		await narrate("1983. The cabin floor. Mara is still gripping something that is not there.")
		await say("JUNE (TUNER)", "There you are. I had you for a second. Sounded like you were lifting a piano.")
		await mara("I found him.")
		await narrate("June gives her room to say the rest.")
		await mara("Older. Alone. He'd been listening for us all his life.")
		if g.story.get("TOMAS") == "taken":
			await say("TOMAS (TUNER)", "How old?")
			await narrate("Mara closes her eyes. She had forgotten that he could hear her.")
			await mara("Older than me.")
			await say("TOMAS (TUNER)", "Was I any good at fixing things?")
			await mara("Very.")
			await say("TOMAS (TUNER)", "Well. That's something.")
			await narrate("At June's bench, the boy turns the spare receiver around so its weak speaker faces him. He has been holding a loose contact in place with a teaspoon.")
			await say("JUNE (TUNER)", "This one's been fixing mine. I was going to buy a new one. Don't tell him that.")
	elif g.has("been_1991") and not g.has("woke_1991"):
		g.set_flag("woke_1991")
		await narrate("1983. She comes out of the feed cabin on her knees.")
		await mara("The control room. The chart.")
	else:
		await mara("Pitch black. Nothing. Just me, frayed at the edges.")


func on_hotspot(id: String) -> void:
	match id:
		"doors":
			await _doors()
		"ladder":
			await _ladder()
		"dish":
			if GameState.has("dish_parked"):
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
		"lund":
			await _lund_gate()
		"chair":
			if GameState.has("lund_gate"):
				await mara("The second coat, folded on the empty chair. She smoothed its collar before she let me through.")
			else:
				await narrate("Beside the gate is an empty chair. A second coat lies folded on it.")
		"rope":
			await narrate("Hand-painted boards on the rope: ONE AT A TIME. SHOW YOUR HANDS. KEEP A LIGHT.")
		"poster":
			await narrate("Behind the gate, a rain-soaked poster announces the switch to digital television on June 12, 2009. Someone has crossed out ARE YOU READY? and written TOO LATE.")
		"aerials":
			await narrate("A pile of discarded aerials leans against the fence. Rabbit ears, a rooftop yagi, a coat hanger somebody bent into hope.")
		"tomas":
			await _tomas()
		"graffiti":
			await mara("The old lobby. No doors, no roof. Grass growing where Sollen's bench was.")
		"white":
			await mara("White, on the ridge. It doesn't move when I look at it. It's nearer when I look back.")


func _doors() -> void:
	match _era():
		"2031":
			Audio.sfx("door", -14.0)
			main.change_room("visitor_center", "from_dish")
		"2009":
			await mara("No doors, no roof. Grass in the lobby, up to the bench.")
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
			if GameState.has("lund_gate"):
				await mara("Not without him. He's right there, under it.")
			else:
				await mara("I came down that. The rope's between me and it now.")
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
			await mara("The needle's on 2031. Twenty-six metres up, in a steel box with no windows. Whatever you're doing, don't do it twice.")
		"2009":
			await mara("2009. In my own handwriting.")
		"1991":
			await mara("The display's still on 1991.")
	await _climb_up()
	await Act3.go(self, year)


## Out along the path to the dish, and up its ladder.
func _climb_up() -> void:
	player.face(1)
	await player.walk_to(1380.0)


# --- 2009 -----------------------------------------------------------------------------

## Mrs. Lund at the gate: name, hands, and the empty chair. Then she lifts the rope.
func _lund_gate() -> void:
	var g := GameState
	if g.has("lund_gate"):
		await say("MRS. LUND", "Don't bring anyone back through here. I don't care how much you miss them.")
		return
	await narrate("Mrs. Lund sits at the gate in a green coat. The darn on its sleeve has been darned again.")
	lund_w.face(-1)
	await say("MRS. LUND", "Name.")
	await mara("Mara Lind.")
	await narrate("Mrs. Lund's hand closes around the gate rope.")
	await say("MRS. LUND", "No. Try another.")
	await mara("You knew my mother.")
	await say("MRS. LUND", "I knew a great many people. Show your hands.")
	player.arm_pose = [[1.4, 0.3], [1.3, 0.35]]
	await narrate("Mara shows her the tape. Mrs. Lund looks past her, counting.")
	player.arm_pose = []
	await mara("There's only me.")
	await say("MRS. LUND", "That's what Arne said.")
	await narrate("Beside the gate is an empty chair. A second coat lies folded on it. Mrs. Lund smooths the collar before she lifts the rope.")
	Audio.sfx("scrape", -20.0, 1.4)
	rope_up = true
	g.set_flag("lund_gate")
	walk_max = 1060.0
	await say("MRS. LUND", "Don't bring anyone back through here. I don't care how much you miss them.")
	objective()


## Tomas at the coupling: the handle, the park, the drawing, and the whistle.
func _tomas() -> void:
	var g := GameState
	if g.has("held_handle"):
		await say("TOMAS", "Hold it. Don't let it run back.")
		return
	g.set_flag("tomas09_met")
	await narrate("A man is working under the dish, one shoulder pressed against a heavy handle. His sleeves are rolled above white scars on both palms. A small radio sits on the concrete at his feet.")
	await mara("Tomas?")
	await narrate("He does not look up.")
	await say("TOMAS", "If you're here to sell batteries, you're twenty years late.")
	await mara("Tomas.")
	tomas.face(-1)
	tomas.arm_pose = []
	Audio.sfx("voice", -10.0, 0.85)
	Audio.play_loop("dish_motor", -24.0, 0.2)
	await narrate("He looks. His shoulder slips from the handle. The radio gives a short, enormous burst of voices.")
	await say("TOMAS", "Take that. Both hands. Don't let it run back.")
	await hud.choose(["Take the handle"])
	await player.walk_to(1060.0)
	player.face(1)
	player.arm_pose = PUSH
	await tomas.walk_to(1196.0)
	tomas.face(-1)
	tomas.arm_pose = [[1.25, 0.6], [0.3, 0.2]]
	await narrate("Mara catches it. Tomas holds PARK on the maintenance box until the dish settles.")
	Audio.stop_loop("dish_motor", 1.2)
	await wait(0.8)
	tomas.arm_pose = PULL
	player.arm_pose = PULL
	var tw := create_tween()
	tw.tween_property(self, "handle", 1.0, 1.2)
	Audio.sfx("thunk", -10.0, 0.8)
	await narrate("Then they pull the handle down until a wide metal coupling comes clear of its socket. He releases PARK. The radio gives only hiss and a distant weather report.")
	Audio.play_loop("static", -30.0, 0.4)
	tomas.arm_pose = []
	player.arm_pose = []
	await narrate("Tomas sits on the concrete. He keeps looking at her shoes.")
	await say("TOMAS", "I remembered you taller.")
	await mara("I remembered you with your coat done up wrong.")
	await say("TOMAS", "It wasn't wrong. I was leaving room to grow.")
	await narrate("She kneels. He lets her put a hand against his cheek, but shuts his eyes before she can see him cry.")
	await mara("What happened to you?")
	await say("TOMAS", "I stayed.")
	await narrate("He folds her hand between his damaged ones.")
	await say("TOMAS", "Come on. It'll pull itself back in if we leave it.")
	tomas.arm_pose = PULL
	player.arm_pose = PULL
	var creep := create_tween()
	creep.tween_property(self, "handle", 0.82, 1.6)
	await narrate("They brace the handle together. The coupling is spring-loaded; when they ease their weight, it creeps toward the socket. A worn pawl should hold it out. Its teeth have been ground smooth.")
	creep.kill()
	handle = 1.0
	await mara("You've been doing this by hand?")
	await say("TOMAS", "Since '83. The latch still worked then. You won't need two people. Not yet.")
	await mara("The cable in the control room—")
	await say("TOMAS", "That's a voice on a desk. This is the ear on the mountain. House power won't stop it. The drive's got its own supply.")
	await say("TOMAS", "Dad didn't trust a winter outage with something that big moving over people's heads.")
	await narrate("Mara looks from the handle to the stopped dish. She draws the coupling and its latch in her notebook. Nothing else: one handle, one catch.")
	g.set_flag("coupling_drawn")
	hud.toast("In my notebook: the coupling and its latch")
	await mara("Park it. Pull this clear. Latch it.")
	await say("TOMAS", "In that order. You try it while the dish is moving, it'll take your hands with it.")
	await mara("You could have left it out. Before the latch wore away.")
	await narrate("Tomas looks at the radio.")
	await say("TOMAS", "Every night I did.")
	await mara("And in the morning?")
	await say("TOMAS", "Sometimes she'd be setting the plates out. You could hear the forks. Then she'd call us in.")
	await narrate("He rubs the old dent in the radio's speaker grille with his thumb.")
	await say("TOMAS", "I told myself I'd only listen till she said my name.")
	await narrate("Mara stops drawing.")
	await say("TOMAS", "Once it was Dad. The whistle. Down, then up. He used to do it from the bottom of the garden when he didn't want to shout.")
	await mara("Ma still does.")
	await say("TOMAS", "Does she?")
	await narrate("His face changes. He is thirteen for one second, waiting for her to go on.")
	await mara("When she thinks I'm not listening.")
	await say("TOMAS", "Good.")
	if g.story.get("TOMAS") != "taken":
		await mara("I left you with your sister. You were safe.")
		await say("TOMAS", "I was. For three years. Then I found that station again. I thought I'd find you. That bit was my doing, Mara.")
		await narrate("He looks at the rope across the path.")
		await say("TOMAS", "They let me through once. A boy with a radio. I thought that meant I belonged here.")
	# One note of the whistle gets through, and the coupling creeps home.
	Audio.sfx("whistle", -16.0)
	var back := create_tween()
	back.tween_property(self, "handle", 0.55, 1.4)
	await narrate("From the little radio, one note of the whistle gets through. The coupling has crept toward the socket while they talked.")
	tomas.arm_pose = PUSH
	await narrate("Tomas reaches to push the handle back in.")
	await hud.choose(["Catch his wrist"])
	back.kill()
	await narrate("Mara catches his wrist. For a moment he hates her for it. Then he helps her pull it clear.")
	tomas.arm_pose = PULL
	var clear := create_tween()
	clear.tween_property(self, "handle", 1.0, 0.8)
	await mara("Is anyone here with you?")
	await say("TOMAS", "Don't spend the time you've got asking me about the time I wasted.")
	g.set_flag("white_houses")
	await narrate("Beyond Mrs. Lund's gate, the white has begun taking the houses. Their windows remain for a moment after their walls are gone.")
	await say("TOMAS", "You'll go back. You'll have a good latch and your hands won't hurt. You'll think that makes it easy.")
	await mara("Come with me.")
	await narrate("He looks at her notebook, then the radio.")
	await say("TOMAS", "Take what you wrote. Remember what it does to you when it's quiet.")
	Audio.stop_all(0.6)
	await wait(0.6)
	await narrate("His voice is lost first. Mara holds the handle with him until she can no longer feel his hand beside hers.")
	g.set_flag("held_handle")
	await Act3.silence(self)


# --- drawing ----------------------------------------------------------------------------

func static_key() -> String:
	return "%s|%d|%s|%s" % [_era(), _white_steps(), rope_up, GameState.has("dish_parked")]


## How near the white is in 2009: it comes on as the visit goes.
func _white_steps() -> int:
	var n := 0
	for f in ["lund_gate", "tomas09_met", "white_houses"]:
		if GameState.has(f):
			n += 1
	return n


func _aim() -> float:
	match _era():
		"2031":
			return -PI / 2 + 0.1
		"2009":
			return -0.95
	if GameState.has("dish_parked"):
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
	var night := era == "1983"
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
				# Glass long gone; one room bricked up.
				cv.draw_rect(low, Color("2a2c2e"))
				cv.draw_rect(low, Color("3a3a36"), false, 4.0)
				if x > 400.0:
					EnvironmentArt.brick(cv, up, Color("6a5a50"))
				else:
					cv.draw_rect(up, Color("2a2c2e"))
					cv.draw_rect(up, Color("3a3a36"), false, 4.0)
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
	# The coal chute's iron hatch at the foot of the wall (in 2009 Mrs. Lund's chair stands there).
	if era == "2009":
		return
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
	cv.draw_colored_polygon(_ridge(400.0, 70.0, 3), Color("4a525c"))
	_white_wall()
	cv.draw_colored_polygon(_ridge(470.0, 36.0, 7), Color("525a60"))
	_valley_2009()
	# Wet October grass on the summit.
	_summit(Color("4e5a44"), Color("6a7458"))
	_far_fence(Color("2a3028"))
	_dish(e, "2009")
	_ruin()
	_stone_wing("2009")
	_chairs_2009()
	_gate_2009()
	_poster_2009()
	_aerials_2009()
	_box_2009()
	for i in 30:
		var p := Vector2(Kit.L + 40.0 + i * 70.0, 660 + (i % 3) * 9.0)
		cv.draw_line(p, p + Vector2(22, 0), Color(0.75, 0.82, 0.9, 0.18), 2.0)


## Halvard below, half its roofs gone: walls and window holes, a few roofs left.
func _valley_2009() -> void:
	for i in 26:
		var x := 300.0 + Townscape.h(i * 7 + 3) * 1300.0
		var y := 486.0 + Townscape.h(i * 13) * 34.0
		var w := 18.0 + Townscape.h(i * 5) * 16.0
		var h := 12.0 + Townscape.h(i * 3) * 8.0
		var wall := Color("6a6a66").darkened(0.15 * Townscape.h(i * 9))
		cv.draw_rect(Rect2(x, y - h, w, h), wall)
		if i % 2 == 0:
			cv.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, y - h), Vector2(x + w * 0.5, y - h - 8), Vector2(x + w + 2, y - h)]), Color("4a3e38"))
		else:
			cv.draw_line(Vector2(x, y - h), Vector2(x + w, y - h + 3), Color("3a3a38"), 1.5)
		cv.draw_rect(Rect2(x + 3, y - h + 4, 4, 4), Color("2a2c30"))
		if w > 24.0:
			cv.draw_rect(Rect2(x + w - 8, y - h + 4, 4, 4), Color("2a2c30"))


## Mrs. Lund's chair at the gate, and beside it the empty one with the second coat folded on it.
func _chairs_2009() -> void:
	for cx in [600.0, 504.0]:
		cv.draw_rect(Rect2(cx - 26, 598, 56, 7), Color("5a4232"))
		cv.draw_line(Vector2(cx + 27, 598), Vector2(cx + 32, 520), Color("5a4232"), 5.0)
		cv.draw_line(Vector2(cx + 20, 530), Vector2(cx + 31, 528), Color("5a4232"), 4.0)
		cv.draw_line(Vector2(cx - 22, 605), Vector2(cx - 22, 650), Color("4a3428"), 4.0)
		cv.draw_line(Vector2(cx + 24, 605), Vector2(cx + 24, 650), Color("4a3428"), 4.0)
	# The second coat, folded square, collar up.
	cv.draw_rect(Rect2(482, 584, 48, 15), Color("3a3c44"))
	cv.draw_rect(Rect2(482, 584, 48, 4), Color("4a4c56"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(486, 584), Vector2(498, 576), Vector2(512, 584)]), Color("2e3038"))


## The rope across the path between two posts, and its hand-painted boards.
func _gate_2009() -> void:
	var pc := Color("4a3a2c")
	for x in [660.0, 764.0]:
		cv.draw_rect(Rect2(x - 5, 486, 10, 166), pc)
		cv.draw_rect(Rect2(x - 7, 482, 14, 6), pc.darkened(0.3))
	var sag := 18.0 if not rope_up else -8.0
	var pts := PackedVector2Array()
	for k in 11:
		var u := k / 10.0
		pts.append(Vector2(lerpf(660, 764, u), (500.0 if not rope_up else 486.0) + sin(u * PI) * sag))
	if rope_up:
		# Lifted off the far post and hung back along the near one.
		pts = PackedVector2Array([Vector2(660, 496), Vector2(652, 560), Vector2(664, 610)])
	cv.draw_polyline(pts, Color("8a7a5a"), 3.0, true)
	var boards := ["ONE AT A TIME", "SHOW YOUR HANDS", "KEEP A LIGHT"]
	for k in 3:
		var r := Rect2(670 + k * 30, 512 + (k % 2) * 4, 28, 40)
		if rope_up:
			r = Rect2(632, 540 + k * 30, 40, 26)
		cv.draw_rect(r, Color("c8bca0"))
		cv.draw_rect(r, Color("5a4a36"), false, 1.5)
		for line in 2:
			cv.draw_line(r.position + Vector2(4, 8 + line * 9), r.position + Vector2(r.size.x - 4, 8 + line * 9), Color(0.55, 0.15, 0.12, 0.8), 2.0)
	if not rope_up:
		Kit.text(cv, Vector2(640, 470), "SHOW YOUR HANDS", 9, Color("e8dcc0"), HORIZONTAL_ALIGNMENT_CENTER, 150)


## The digital-TV poster on a fence panel, rain-soaked, with its graffiti.
func _poster_2009() -> void:
	cv.draw_rect(Rect2(780, 430, 108, 222), Color("3a3e3a"))
	for k in 6:
		cv.draw_line(Vector2(784 + k * 18, 430), Vector2(784 + k * 18, 652), Color("2a2e2a"), 2.0)
	var r := Rect2(796, 444, 76, 92)
	cv.draw_rect(r, Color("d8dce4"))
	cv.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 18), Color("2a5aa8"))
	Kit.text(cv, Vector2(r.position.x, r.position.y + 13), "DTV", 11, Color("f0f0f0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 34), "JUNE 12, 2009", 8, Color("1a2a4a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 50), "ARE YOU READY?", 7, Color("1a2a4a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	cv.draw_line(r.position + Vector2(8, 47), r.position + Vector2(68, 47), Color("1a1a1a"), 2.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 72), "TOO LATE", 12, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	# Rain streaks and a curled corner.
	for k in 5:
		cv.draw_line(r.position + Vector2(10 + k * 14, 20), r.position + Vector2(12 + k * 14, 88), Color(0.4, 0.45, 0.55, 0.25), 2.0)
	cv.draw_colored_polygon(PackedVector2Array([r.end - Vector2(14, 0), r.end, r.end - Vector2(0, 14)]), Color("a8acb4"))


## The pile of dead aerials against the fence.
func _aerials_2009() -> void:
	var c := Color("8a8e94")
	cv.draw_line(Vector2(880, 646), Vector2(996, 646), Color("3a3a36"), 6.0)
	for k in 7:
		var b := Vector2(890 + k * 15, 646)
		var a := -1.2 + 0.35 * sin(k * 2.1)
		var tip := b + Vector2(cos(a), sin(a)) * (70.0 + 20.0 * Townscape.h(k))
		cv.draw_line(b, tip, c, 2.0)
		for r in 4:
			var q := b.lerp(tip, 0.3 + r * 0.17)
			cv.draw_line(q - Vector2(10, -4), q + Vector2(10, 4), c, 1.5)
	# Rabbit ears on a box.
	cv.draw_rect(Rect2(950, 628, 30, 14), Color("2a2a2c"))
	cv.draw_line(Vector2(958, 628), Vector2(940, 574), c, 1.5)
	cv.draw_line(Vector2(972, 628), Vector2(992, 572), c, 1.5)


## The maintenance box at the foot of the dish: PARK, and the coupling's socket.
func _box_2009() -> void:
	# The cable conduit back to the pedestal.
	cv.draw_line(Vector2(1128, 640), Vector2(1060, 560), Color("2a2c30"), 6.0)
	var r := Rect2(1104, 520, 60, 128)
	cv.draw_rect(r, Color("4a4e46"))
	cv.draw_rect(r, Color("1e2220"), false, 2.0)
	Kit.text(cv, Vector2(r.position.x, r.position.y + 14), "DRIVE", 8, Color("d8d8c8"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	cv.draw_rect(Rect2(r.end.x - 20, r.position.y + 26, 14, 12), Color("c8a030"))
	Kit.text(cv, Vector2(r.end.x - 30, r.position.y + 50), "PARK", 7, Color("d8d8c8"))
	# The socket the coupling seats in.
	cv.draw_circle(Vector2(r.position.x - 2, r.position.y + 70), 14.0, Color("1a1c1e"))
	cv.draw_circle(Vector2(r.position.x - 2, r.position.y + 70), 14.0, Color("6a6e70"), false, 2.0)


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
## height, empty windows, and through the fallen front, the lobby's back wall.
func _ruin() -> void:
	var conc := Color("6a6c6a")
	var top := PackedVector2Array([Vector2(Kit.L, 650), Vector2(Kit.L, 190)])
	var xs := [-380.0, -300.0, -230.0, -170.0, -120.0, -60.0, -30.0, 40.0, 130.0, 190.0, 236.0]
	var ys := [176.0, 214.0, 168.0, 246.0, 222.0, 330.0, 372.0, 352.0, 300.0, 250.0, 262.0]
	for i in xs.size():
		top.append(Vector2(xs[i], ys[i]))
	top.append(Vector2(236, 650))
	cv.draw_colored_polygon(top, conc)
	# Through the gap: the lobby's back wall, stained, grass on the floor.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(-60, 650), Vector2(-60, 330), Vector2(-30, 372), Vector2(40, 352),
		Vector2(130, 300), Vector2(236, 330), Vector2(236, 650)]), Color("4e504e"))
	cv.draw_rect(Rect2(-50, 390, 286, 260), Color("565856"))
	for i in 9:
		cv.draw_line(Vector2(-40 + i * 32, 390), Vector2(-36 + i * 32, 470 + Townscape.h(i) * 60), Color(0.3, 0.32, 0.28, 0.4), 4.0)
	for i in 3:
		var w := Rect2(-420 + i * 124, 410, 108, 134)
		cv.draw_rect(w, Color("2a2c2e"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(120, 650), Vector2(170, 560), Vector2(236, 600), Vector2(236, 650)]), conc.lightened(0.06))
	for i in 12:
		var x := -60.0 + i * 26.0
		cv.draw_line(Vector2(x, 650), Vector2(x + 4, 632 - Townscape.h(i) * 10), Color("5a6a44"), 2.0)


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
		_handle_2009(ci)


## The coupling handle on the maintenance box, and the coupling sliding clear of its socket.
func _handle_2009(ci: CanvasItem) -> void:
	var pivot := Vector2(1112, 566)
	var a := lerpf(-2.2, -0.35, handle)  # up and back (seated) to down and forward (clear)
	var tip := pivot + Vector2(cos(a), sin(a)) * 74.0
	ci.draw_line(pivot, tip, Color("2a2c2e"), 7.0)
	ci.draw_line(tip - Vector2(cos(a + PI / 2), sin(a + PI / 2)) * 10.0, tip + Vector2(cos(a + PI / 2), sin(a + PI / 2)) * 10.0, Color("8a2a24"), 8.0)
	ci.draw_circle(pivot, 6.0, Color("5a5e60"))
	# The wide metal coupling: home in the socket, or drawn out of it.
	var c := Vector2(1102 - 34.0 * handle, 590)
	ci.draw_rect(Rect2(c.x - 18, c.y - 16, 30, 32), Color("7a7e80"))
	ci.draw_rect(Rect2(c.x - 18, c.y - 16, 30, 32), Color("3a3e40"), false, 2.0)
	for k in 3:
		ci.draw_line(Vector2(c.x - 14 + k * 9, c.y - 14), Vector2(c.x - 14 + k * 9, c.y + 14), Color("5a5e60"), 2.0)
	# Tomas's little radio on the concrete, a dent in its grille.
	if tomas != null:
		var rp := Vector2(1196, 638)
		ci.draw_rect(Rect2(rp.x - 16, rp.y - 12, 32, 14), Color("3a4430"))
		ci.draw_circle(rp + Vector2(-6, -5), 4.0, Color("1a1c18"))
		ci.draw_line(rp + Vector2(8, -12), rp + Vector2(18, -34), Color("8a8e94"), 1.5)


func draw_glow(ci: CanvasItem) -> void:
	match _era():
		"2009":
			pass
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
