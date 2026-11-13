extends Room
## Act 2.4 — the dark kitchen of the Lind house in frequency 14. Eighty-One
## at the table, lit by one match in a saucer and the glow of her Tuner's dial.
## The act's centrepiece conversation, then the exchange: a second Mara (Blue,
## from 07) at the back door, the match goes out, and when it's relit the
## player is Blue. Nothing on screen says so; only the tape at the edge of the
## frame is blue. Ask Eighty-One what she did, or say nothing (story SWITCH).

var e81: Actor
var other: Actor
## 0..1: how bright the match is (0 = out).
var match_light := 0.0
var lamp: PointLight2D
var dial_lamp: PointLight2D
## The three seconds of total dark during the switch.
var blackout := false


func setup() -> void:
	animated_back = false
	place_name = "The Lind house · frequency 14"
	walk_min = 100.0
	walk_max = 560.0
	make_player(120.0, 1)
	e81 = add_actor("eighty_one", 760.0, -1)
	e81.seated = true
	e81.seat_y = 52.0
	e81.arm_pose = [[1.05, 0.95], [0.95, 0.75]]  # forearms on the table, either side of the saucer
	e81.visible = not GameState.has("swapped")
	other = add_actor("mara", 1180.0, -1)
	other.wrist_tape = Color("2f63c9")
	other.visible = false
	add_layer(1, _draw_table)
	lamp = add_lamp(Vector2(700, 540), 3.2, Color(1.0, 0.75, 0.42), 0.0)
	dial_lamp = add_lamp(Vector2(614, 552), 1.4, Color(0.55, 0.85, 0.95), 0.0)
	add_hotspot("hall", Rect2(20, 330, 100, 320), "Front hall", 100.0, -1)
	add_hotspot("e81", Rect2(700, 440, 120, 210), "Her", 540.0, 1, func() -> bool: return e81.visible)
	add_hotspot("table", Rect2(560, 540, 260, 110), "Kitchen table", 540.0, 1)
	add_hotspot("back_door", Rect2(1140, 330, 100, 320), "Back door", 560.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 120.0
	player.face(1)


func is_dark() -> bool:
	return true


## Her radio on the table (a prop layer) comes and goes with her.
func static_key() -> String:
	return str(e81.visible)


func _process(delta: float) -> void:
	super(delta)
	var f := 0.82 + 0.18 * sin(t * 13.0) * sin(t * 4.7)
	lamp.energy = match_light * 1.4 * f
	dial_lamp.energy = 0.7 if e81.visible and not blackout else 0.0


func ambience() -> void:
	Audio.stop_all(0.4)
	Audio.play_loop("wind", -30.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	objective()
	if GameState.has("met_81"):
		return
	# One match burns in a saucer. She has Mara's face, older.
	match_light = 1.0
	light_off = true
	await wait(0.6)
	await narrate("In the kitchen, one match burns in a saucer. A woman sits behind it. She has Mara's face, older. Burn gauze covers her left hand. A tally counter is taped to her radio.")
	GameState.set_flag("e81_gauze")
	await say("HER", "Shut the door gently. It doesn't take much.")
	Audio.sfx("door", -18.0, 0.9)
	match_light = 0.75
	await wait(0.3)
	create_tween().tween_property(self, "match_light", 1.0, 0.6)
	await narrate("Mara closes it. The match steadies.")
	await say("HER", "There are a lot of us. Fewer than there were.")
	await player.walk_to(520.0)
	await mara("You. From the basement door. What's your name?")
	await say("HER", "Eighty-One.")
	await narrate("She touches the counter without pressing it.")
	await say("EIGHTY-ONE", "Stations I've stood in. I started counting when the names stopped helping.")
	await _questions()
	await _switch()


## Mara asks what she needs to know, in whatever order the player likes.
func _questions() -> void:
	var asked := {}
	var labels := {
		"world": "What's happening to Halvard?",
		"body": "There's a body in the control room. She looks like me.",
		"tomas": "Where's my brother?",
		"early": "A plow driver heard the warning at 2:05. Before it was sent.",
	}
	var topics := ["world", "body", "tomas"]
	# Only a Mara who has read Cal's board can ask this.
	if GameState.has("read_board"):
		topics.append("early")
	while asked.size() < topics.size():
		var opts: Array[String] = []
		var keys: Array[String] = []
		for k in topics:
			if not asked.has(k):
				opts.append(labels[k])
				keys.append(k)
		var pick: int = await hud.choose(opts)
		var k: String = keys[pick]
		asked[k] = true
		match k:
			"world":
				await say("EIGHTY-ONE", "Two of everything. Then one less. Then none. It has an end. I call it the Silence.")
				await say("EIGHTY-ONE", "I've watched it come down a street while a man was still deciding which front door was his.")
				await mara("Because we cross?")
				await say("EIGHTY-ONE", "Every station I've seen go quiet had one too many of somebody. That's what I know.")
			"body":
				await say("EIGHTY-ONE", "I know.")
				await mara("Did you see who did it?")
				await say("EIGHTY-ONE", "I saw what came after.")
			"tomas":
				await say("EIGHTY-ONE", "There's a station where he's still alive. Twelve. It's three years back there.")
				await say("EIGHTY-ONE", "He's thirteen, and he'll take your hand if you hold it out. Don't.")
				await mara("Why not?")
				await say("EIGHTY-ONE", "Because I did. I brought him home. Eleven days.")
				await wait(0.6)
				await say("EIGHTY-ONE", "The second night, he took my kitchen radio apart and put it back together. I said, you did that? He said, mostly.")
				await mara("...That means yes.")
				await say("EIGHTY-ONE", "That's what I said too.")
				await mara("What happened on the eleventh day?")
				await say("EIGHTY-ONE", "The white came back. I was down in the cellar, in the dark. He was in the kitchen with the light on.")
				await narrate("She straightens the saucer. There is no tremor in her good hand until she lets go.")
				GameState.set_flag("e81_tomas")
			"early":
				await say("EIGHTY-ONE", "You read Cal's board.")
				await wait(0.5)
				await say("EIGHTY-ONE", "It's never the first time, love. I've sat at this table nineteen times. You've asked me that in four of them.")
				await mara("What happens in the others?")
				await say("EIGHTY-ONE", "In most of them you go to twelve anyway.")
				GameState.set_flag("pressed_81")
	await _goodbye_beat()
	await say("EIGHTY-ONE", "Go and see him, if you have to. Then meet me at the dish. You'll know when.")


## What Mara said to Tomas, every night. If she said it to the voice on an
## open band (Choice 1: answer), Eighty-One heard it and uses it now.
func _goodbye_beat() -> void:
	if GameState.story.get("ANSWERED") == true:
		await say("EIGHTY-ONE", "\"%s\" That's what you said to him. Every night." % Story.signoff_line())
		await mara("How do you know that?")
		await say("EIGHTY-ONE", "You said it on 2.14 tonight. On an open band. Every one of us heard you.")
		await say("EIGHTY-ONE", "A password stops being a password when you give it to the room.")
		GameState.set_flag("e81_signoff")
	else:
		await say("EIGHTY-ONE", "What did you say to him? Last thing, every night.")
		await mara("...Why do you want to know?")
		await say("EIGHTY-ONE", "Good. Don't tell me. Don't tell anyone. Not even a radio.")
		GameState.set_flag("kept_signoff")


## The exchange. A second Mara (Blue, from 07) at the back door; the match
## goes out. In the dark Eighty-One turns Red's set to 61 and takes it off her
## shoulder as Red follows the carrier; then she retunes it to H and puts it
## in Blue's hands. Nothing on screen says so (3.8 tells it). From here the
## player is Blue: only the tape at the edge of the frame has changed.
func _switch() -> void:
	Audio.sfx("lock", -14.0, 1.3)
	other.visible = true
	other.position.x = 1180.0
	other.prop = "radio"
	await wait(0.4)
	await narrate("At the back door, a latch lifts. Another woman steps into the dark kitchen. The same face. A radio held against her chest.")
	await other.walk_to(1040.0)
	await say("SECOND MARA", "Ma?")
	await say("EIGHTY-ONE", "Ah. Everyone's early.")
	# A draft from the back door blows out the match.
	Audio.play_loop("wind", -14.0, 0.2)
	await wait(0.3)
	create_tween().tween_property(self, "match_light", 0.0, 0.25)
	await wait(0.4)
	# Total darkness: no aura, no dial, nothing to see.
	var keep := player.visible
	blackout = true
	player.visible = false
	other.visible = false
	Audio.sfx("scrape", -6.0)
	await wait(0.45)
	Audio.sfx("click", -16.0, 0.7)
	await wait(0.35)
	Audio.sfx("click", -20.0, 2.1)
	await wait(0.3)
	Audio.sfx("thunk", -14.0, 1.5)
	await narrate("A draft from the back door blows out the match. Total darkness. A chair scrapes. A radio strap catches on something. A small dry click, like a thumbnail turning a screw. A set knocks against someone's hands.")
	await say("MARA", "Let go of me—")
	Audio.sfx("thunk", -2.0)
	await narrate("A thump.")
	await wait(0.4)
	# Unseen: our Mara (Red) is in the dark. The one who stays came from 07.
	GameState.set_flag("swapped")
	GameState.set_flag("met_81")
	if GameState.has_item("red_tape"):
		var at := GameState.inventory.find("red_tape")
		GameState.inventory[at] = "blue_tape"
		GameState.inventory_changed.emit()
	player.wrist_tape = Color("2f63c9")
	player.prop = "radio"
	player.visible = keep
	blackout = false
	Audio.play_loop("wind", -30.0, 0.5)
	Audio.sfx("match", -4.0)
	create_tween().tween_property(self, "match_light", 1.0, 0.4)
	await wait(0.6)
	# One Mara by the table, holding a radio, breathing hard. Only the tape
	# at the edge of the frame says which one.
	Audio.sfx("breath", -16.0, 0.95)
	await narrate("Eighty-One strikes a new match. One Mara stands by the table, holding a radio, breathing hard.")
	e81.face(-1)
	await wait(0.8)
	await say("EIGHTY-ONE", "Right. Where was I. Your brother. Station twelve. It's three years back there.")
	await say("EIGHTY-ONE", "He's thirteen, and he'll take your hand if you hold it out. I'd tell you not to. You'll go anyway.")
	await say("EIGHTY-ONE", "Then the dish. I'll meet you there.")
	await narrate("She has said all of this before, nearly word for word. She says it now as if for the first time.")
	await _response()
	player.prop = "none"
	await wait(0.4)
	e81.seated = false
	e81.prop = "radio"
	await narrate("Eighty-One goes out by the back door. She is carrying two radios.")
	await say("EIGHTY-ONE", "Find the hum on that one. It knows the way home.")
	await e81.walk_to(1180.0)
	Audio.sfx("door", -12.0)
	e81.visible = false
	create_tween().tween_property(self, "match_light", 0.0, 1.2)
	await wait(1.0)
	light_off = false
	await mara("Twelve. Three years back. He's alive in twelve.")
	await mara("And Ma's house, for sale. I need to get home.")
	objective()


## The player's answer (story SWITCH): ask her, or say nothing.
func _response() -> void:
	await mara("There was somebody by the table. Where did she go?")
	var pick: int = await hud.choose(["\"What did you just do?\"", "Say nothing"])
	if pick == 0:
		GameState.set_story("SWITCH", "confront")
		await mara("What did you just do?")
		await say("EIGHTY-ONE", "Got one of you out. That's all a room like this can bear.")
		await mara("Where did she go?")
		await say("EIGHTY-ONE", "Somewhere dark. She's better in the dark than you'd think.")
	else:
		GameState.set_story("SWITCH", "conceal")
		await mara("Don't ask. Not her. Not now.")


func on_hotspot(id: String) -> void:
	match id:
		"hall":
			Audio.sfx("door", -10.0)
			main.change_room("ash_street", "from_house")
		"e81":
			await say("EIGHTY-ONE", "Go on.")
		"table":
			await mara("A kitchen table in an empty house. Dust, a matchbox, and a ring where her radio sat.")
		"back_door":
			await mara("The back door. She went out that way. I'm not following her into the dark.")


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(cv, floor_y, Color("5a5450"), Color("4a4440"), Color("2a2622"))
	EnvironmentArt.wall_props(cv, str(name))
	cv.draw_rect(Rect2(Kit.L, floor_y, Kit.R - Kit.L, 400), Color("3a3430"))
	for i in 16:
		cv.draw_line(Vector2(Kit.L + i * 150.0, floor_y), Vector2(Kit.L + i * 150.0, 760), Color(0, 0, 0, 0.15), 2.0)
	# Pale rectangles where the cupboards and fridge used to be.
	cv.draw_rect(Rect2(200, 250, 300, 120), Color(0.4, 0.38, 0.36, 0.6))
	cv.draw_rect(Rect2(880, 260, 120, 390), Color(0.42, 0.4, 0.38, 0.6))
	Kit.door(cv, Rect2(26, 340, 90, 310), Color("4a3a30"))
	Kit.door(cv, Rect2(1146, 340, 90, 310), Color("4a3a30"))
	cv.draw_rect(Rect2(580, 250, 160, 120), Color("101218"))
	cv.draw_rect(Rect2(580, 250, 160, 120), Color("2a2622"), false, 6.0)
	cv.draw_line(Vector2(660, 250), Vector2(660, 370), Color("2a2622"), 4.0)
	# The chair under Eighty-One.
	cv.draw_rect(Rect2(736, 598, 60, 8), Color("4a3428"))
	cv.draw_line(Vector2(794, 598), Vector2(800, 512), Color("4a3428"), 6.0)
	cv.draw_line(Vector2(780, 530), Vector2(798, 528), Color("4a3428"), 4.0)
	cv.draw_line(Vector2(742, 606), Vector2(742, 650), Color("4a3428"), 5.0)
	cv.draw_line(Vector2(790, 606), Vector2(790, 650), Color("4a3428"), 5.0)


func _draw_table(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(540, 566, 220, 12), Color("6a5040"))
	ci.draw_rect(Rect2(546, 578, 208, 8), Color("5a4434"))
	ci.draw_line(Vector2(554, 586), Vector2(554, 650), Color("5a4434"), 7.0)
	ci.draw_line(Vector2(746, 586), Vector2(746, 650), Color("5a4434"), 7.0)
	# The saucer the match burns in.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(672, 562), Vector2(708, 562), Vector2(702, 567), Vector2(678, 567)]), Color("d8d2c4"))
	ci.draw_line(Vector2(674, 562), Vector2(706, 562), Color("b8b0a0"), 1.5)
	if e81.visible:
		# Her Tuner on the table: the same green field radio, a tally counter taped to it.
		ci.draw_rect(Rect2(586, 542, 70, 24), Color("4a5a3a"))
		ci.draw_rect(Rect2(594, 547, 40, 10), Color(0.6, 0.85, 0.95, 0.9))
		ci.draw_rect(Rect2(640, 546, 12, 12), Color("9aa3a8"))


func draw_glow(ci: CanvasItem) -> void:
	if match_light <= 0.01:
		return
	# The match, in Eighty-One's fingers (or on the table once she's gone).
	var p := Vector2(690, 554)
	var f := 0.8 + 0.2 * sin(t * 13.0) * sin(t * 5.0)
	ci.draw_circle(p, 3.0, Color(1.0, 0.95, 0.7, match_light))
	ci.draw_circle(p + Vector2(0, -3), 5.0 * f, Color(1.0, 0.75, 0.35, 0.7 * match_light))
