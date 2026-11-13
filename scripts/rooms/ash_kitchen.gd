extends Room
## Act 2.4 — the dark kitchen of the Lind house in frequency 14. Eighty-One
## at the table, lit by one match and the glow of her Tuner's dial. The act's
## centerpiece conversation, then the switch: a third Mara at the back door,
## the match goes out, and three seconds later the player is Blue Mara.
## Nothing on screen says so, but the player gets to answer it: confront
## Eighty-One here, or say nothing (and maybe tell June later). Story SWITCH.

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
	e81.arm_pose = [[1.05, 0.95], [0.95, 0.75]]  # forearms on the table, a match in her fingers
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
	await wait(0.6)
	await mara("Hello?")
	await wait(0.6)
	Audio.sfx("match", -4.0)
	create_tween().tween_property(self, "match_light", 1.0, 0.4)
	light_off = true
	await wait(0.8)
	await say("HER", "There are a lot of us. Fewer than there were.")
	await player.walk_to(520.0)
	await mara("You. From the basement door.")
	await mara("Her left hand's wrapped in gauze. Burn gauze.")
	GameState.set_flag("e81_gauze")
	await mara("What's your name?")
	await say("HER", "Eighty-One. That's how many stations I've stood in.")
	await _questions()
	await _switch()


## Mara asks what she needs to know, in whatever order the player likes.
func _questions() -> void:
	var asked := {}
	var labels := {
		"world": "What's happening to Halvard?",
		"body": "There's a body in the control room. It's me.",
		"tomas": "Where's my brother?",
		"early": "A plow driver heard the warning at 2:05. Before it was sent.",
	}
	var topics := ["world", "body", "tomas"]
	# Only a Mara who connected Cal's board to the 2:14 transmission can ask this.
	if GameState.has("theory_loop"):
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
				await say("EIGHTY-ONE", "Every time one of us walks through the dark, the world frays a little.")
				await say("EIGHTY-ONE", "The fraying has an end. It's called the Silence. I've seen it, through the dish.")
			"body":
				await say("EIGHTY-ONE", "One of us who went wrong.")
				await say("EIGHTY-ONE", "I got there too late.")
			"tomas":
				await say("EIGHTY-ONE", "There's a station where he's still alive. Twelve. It's three years back there.")
				await say("EIGHTY-ONE", "Don't go.")
				await mara("Why not?")
				await say("EIGHTY-ONE", "Because I went. I brought him home. He lasted eleven days, and then his station went quiet with him in it.")
				await wait(0.6)
				await say("EIGHTY-ONE", "The second night, he took my kitchen radio apart and put it back together. I said, you did that?")
				await say("EIGHTY-ONE", "He said, mostly.")
				await mara("...That means yes.")
				await say("EIGHTY-ONE", "That's what I said too.")
				GameState.set_flag("e81_tomas")
			"early":
				await say("EIGHTY-ONE", "You read Cal's board.")
				await wait(0.5)
				await say("EIGHTY-ONE", "It's never the first time, love. I've sat at this table nineteen times. You've asked me that in four of them.")
				await mara("What happens in the others?")
				await say("EIGHTY-ONE", "In most of them you go to twelve anyway.")
				await say("EIGHTY-ONE", "So go. Just know what you're carrying back.")
				GameState.set_flag("pressed_81")
	await _goodbye_beat()
	await say("EIGHTY-ONE", "Meet me at the dish when it's time. You'll know when.")


## What Mara said to Tomas, every night. If she said it to the voice on an
## open band (Choice 1: answer), Eighty-One heard it and uses it now.
func _goodbye_beat() -> void:
	if GameState.story.get("ANSWERED") == true:
		await say("EIGHTY-ONE", "\"%s\" That's what you said to him. Every night." % Story.signoff_line())
		await mara("How do you know that?")
		await say("EIGHTY-ONE", "You said it on 2.14 tonight. On an open band. Every one of us heard you.")
		GameState.set_flag("e81_signoff")
	else:
		await say("EIGHTY-ONE", "What did you say to him? Last thing, every night.")
		await mara("...Why do you want to know?")
		await say("EIGHTY-ONE", "Good. Don't tell me. Don't tell anyone. Not even a radio.")
		GameState.set_flag("kept_signoff")


## The switch: a third Mara, the match goes out, three seconds of dark.
func _switch() -> void:
	Audio.sfx("door", -8.0)
	other.visible = true
	other.position.x = 1180.0
	await wait(0.4)
	await other.walk_to(1000.0)
	await mara("...What?")
	await say("EIGHTY-ONE", "Ah. Everyone's early.")
	# A draft from the back door.
	Audio.play_loop("wind", -14.0, 0.2)
	await wait(0.3)
	create_tween().tween_property(self, "match_light", 0.0, 0.25)
	await wait(0.4)
	# Total darkness: no aura, no dial, nothing to see.
	var keep := player.visible
	blackout = true
	player.visible = false
	other.visible = false
	await say("MARA", "Who's—")
	Audio.sfx("scrape", -4.0)
	await say("MARA", "Let go of me—")
	Audio.sfx("thunk", -2.0)
	await wait(0.8)
	# Unseen: our Mara is swept into the dark. The one who stays came from 07.
	GameState.set_flag("swapped")
	GameState.set_flag("met_81")
	if GameState.has_item("red_tape"):
		var at := GameState.inventory.find("red_tape")
		GameState.inventory[at] = "blue_tape"
		GameState.inventory_changed.emit()
	player.wrist_tape = Color("2f63c9")
	player.visible = keep
	blackout = false
	Audio.play_loop("wind", -30.0, 0.5)
	Audio.sfx("match", -4.0)
	create_tween().tween_property(self, "match_light", 1.0, 0.4)
	await wait(1.0)
	e81.face(-1)
	await wait(1.2)
	await say("EIGHTY-ONE", "Right. Where was I.")
	await _response()
	await wait(0.4)
	e81.seated = false
	await say("EIGHTY-ONE", "Go see your brother if you have to. Just come back.")
	await e81.walk_to(1180.0)
	Audio.sfx("door", -12.0)
	e81.visible = false
	create_tween().tween_property(self, "match_light", 0.0, 1.2)
	await wait(1.0)
	light_off = false
	await mara("Twelve. Three years back.")
	await mara("He's alive in twelve.")
	objective()


## The player's answer to the switch (story SWITCH). Confronting her happens
## here; saying nothing leaves a door open to tell June later.
func _response() -> void:
	await mara("My hands are shaking. There were two of us. Weren't there?")
	var pick: int = await hud.choose(["\"What did you just do?\"", "Say nothing."])
	if pick == 0:
		GameState.set_story("SWITCH", "confront")
		await mara("What did you just do? There were two of us.")
		await say("EIGHTY-ONE", "There's only ever one of you in a room, love. Rooms are strict about it.")
		await mara("Where did she go?")
		await say("EIGHTY-ONE", "Somewhere dark. She's better in the dark than you'd think.")
		await say("EIGHTY-ONE", "Look at your wrist if you have to. Then stop looking. It doesn't help.")
		await narrate("The tape on Mara's wrist is blue.")
		GameState.set_flag("saw_blue")
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
	if e81.visible:
		# Her Tuner on the table: the same green field radio, a tally counter taped to it.
		ci.draw_rect(Rect2(586, 542, 70, 24), Color("4a5a3a"))
		ci.draw_rect(Rect2(594, 547, 40, 10), Color(0.6, 0.85, 0.95, 0.9))
		ci.draw_rect(Rect2(640, 546, 12, 12), Color("9aa3a8"))


func draw_glow(ci: CanvasItem) -> void:
	if match_light <= 0.01:
		return
	# The match, in Eighty-One's fingers (or on the table once she's gone).
	var p := Vector2(708, 544) if e81.visible else Vector2(690, 560)
	var f := 0.8 + 0.2 * sin(t * 13.0) * sin(t * 5.0)
	ci.draw_circle(p, 3.0, Color(1.0, 0.95, 0.7, match_light))
	ci.draw_circle(p + Vector2(0, -3), 5.0 * f, Color(1.0, 0.75, 0.35, 0.7 * match_light))
