extends Room
## Act 3.7 — Red. The kitchen after the match went out.
##
## The player is Red now: the Mara the exchange took out of the Ash Street
## kitchen (2.4). Eighty-One caught her strap as she followed the carrier on
## 61: no Tuner, no flashlight. Her coat, her own notebook, the red tape round
## her wrist. The table is gone when she reaches for it.
##
## She finds her way by sound. A cupboard latch, a distant engine, the
## two-note whistle, down then up: walk toward the right one, away from the
## others. A wrong one walks her back to the strip of tape she pressed to the
## floor. At the end: a wire-mesh partition, a desk microphone, a small
## emergency lamp whose battery is already weak, and a metal door.

## At each turning: [left, ahead, right], the right one, and the loops to play.
const TURNINGS := [
	{"names": ["A cupboard latch, lifting", "Her own voice, saying something she hasn't said", "A tap, dripping"],
		"right": 0, "loops": [["click", -22.0], ["voice_short", -20.0], ["drip", -24.0]]},
	{"names": ["A dog, barking", "A phone ringing in an empty room", "A distant engine"],
		"right": 2, "loops": [["barking", -26.0], ["ring", -28.0], ["engine", -26.0]]},
	{"names": ["A typewriter", "Two notes: down, then up", "The Lunds, arguing about a coat"],
		"right": 1, "loops": [["typewriter", -26.0], ["whistle", -14.0], ["voice", -26.0]]},
]
const SIDES := ["left", "ahead", "right"]
const SPOTS := [Vector2(150, 470), Vector2(640, 330), Vector2(1130, 470)]
const WHERE := ["on the left", "ahead, in the middle", "on the right"]
const LOOPS := ["click", "voice_short", "drip", "barking", "ring", "engine", "typewriter", "whistle", "voice"]


## The ? button at turning n (1..3): exactly where the right sound is.
static func hint_for(n: int) -> String:
	if n < 1 or n > TURNINGS.size():
		return ""
	var tn: Dictionary = TURNINGS[n - 1]
	var i := int(tn.right)
	var what: String = ["the cupboard latch", "the distant engine", "the whistle, down then up"][n - 1]
	return "Turning %d of 3. Follow %s: it's %s. Tap \"%s\"." % [n, what, WHERE[i], tn.names[i]]

## 0: the kitchen floor, by touch. 1..3: the turnings. 4: the mesh, the lamp, the door.
var stage := 0
## The emergency lamp behind the mesh (0..1): it fades as the battery goes.
var lamp := 0.0
var lamp_light: PointLight2D
var shot := ""


func setup() -> void:
	animated_back = false
	shows_hud = true
	place_name = "The dark"
	walk_min = 100.0
	walk_max = 1180.0
	make_player(640.0, 1)
	player.wrist_tape = Color("b8322c")
	GameState.red_turning = 0
	for i in 3:
		add_hotspot(SIDES[i], Rect2(SPOTS[i] - Vector2(110, 120), Vector2(220, 240)), "", NAN, 0, func() -> bool: return stage > 0 and stage < 4)
	add_hotspot("mic", Rect2(560, 430, 150, 130), "Microphone cord", 600.0, 1, func() -> bool: return stage == 4 and not GameState.has("red_mic"))
	add_hotspot("door", Rect2(900, 300, 150, 350), "Metal door", 880.0, 1, func() -> bool: return stage == 4 and GameState.has("red_mic"))
	# The emergency lamp's narrow spill behind the mesh.
	lamp_light = add_lamp(Vector2(800, 500), 2.4, Color(1.0, 0.82, 0.55), 0.0)
	if GameState.has("red_mic"):
		# Back from a save: she's at the mesh already.
		stage = 4
		lamp = 0.6
		player.position.x = 600.0


func _process(delta: float) -> void:
	super(delta)
	if lamp_light != null:
		lamp_light.energy = lamp * 1.5 * (0.92 + 0.08 * sin(t * 9.0)) if stage == 4 else 0.0


func enter(entry: String) -> void:
	entered_from = entry


func is_dark() -> bool:
	return true


func score_quiet() -> bool:
	return true


func static_key() -> String:
	return str(stage)


func ambience() -> void:
	Audio.play_loop("breath", -24.0)
	Audio.play_loop("drone", -30.0)
	Audio.set_environment("basement", freq)


func on_arrive() -> void:
	ambience()
	if not GameState.has("red_woke"):
		GameState.set_flag("red_woke")
		await wait(1.2)
		player.arm_pose = [[1.5, 0.2], [0.2, 0.1]]
		await mara("My light. Where's my light?")
		player.arm_pose = []
		await narrate("Nothing answers. Her coat, her own notebook, the tape round her wrist. No Tuner. No flashlight. The table is gone when she reaches for it.")
		Audio.sfx("tape_rip", -10.0)
		await narrate("She tears a short piece from the tape and presses it to the floor. She crawls away, counting. Six steps to a wall. She crawls back. It takes eight.")
		await mara("All right. I heard you, kid.")
		await wait(0.4)
		await _turning(1)
		return
	# Back from a save: the turnings start again from the tape on the floor,
	# or she's at the mesh already.
	if not GameState.has("red_mic"):
		await _turning(1)
		return
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"left", "ahead", "right":
			await _choose(SIDES.find(id))
		"mic":
			await _mic()
		"door":
			await _door()


func use_item(_id: String, _item: String) -> bool:
	return false


func _turning(n: int) -> void:
	stage = n
	GameState.red_turning = n
	var tn: Dictionary = TURNINGS[n - 1]
	for loop in LOOPS:
		Audio.stop_loop(loop, 0.5)
	for l in tn.loops:
		Audio.play_loop(l[0], l[1], 0.8)
	for i in 3:
		var h := get_hotspot(SIDES[i])
		h.label = str(tn.names[i])
	await narrate("Left: %s. Ahead: %s. Right: %s." % [tn.names[0], tn.names[1], tn.names[2]])
	objective()


func _choose(i: int) -> void:
	var tn: Dictionary = TURNINGS[stage - 1]
	await player.walk_to(SPOTS[i].x)
	if i != int(tn.right):
		Audio.sfx("step", -10.0)
		await narrate("The sound slides round behind her. Under her hand, the strip of tape she pressed to the floor.")
		await mara("Back where I started. Listen properly.")
		player.position.x = 640.0
		await _turning(1)
		return
	if stage < 3:
		await mara("Closer. Keep going.")
		player.position.x = 640.0
		await _turning(stage + 1)
		return
	for loop in LOOPS:
		Audio.stop_loop(loop, 0.6)
	GameState.red_turning = 0
	await _mesh()


## A wire-mesh partition. Behind it, a desk microphone and a small emergency lamp.
func _mesh() -> void:
	stage = 4
	player.position.x = 480.0
	player.face(1)
	var tw := create_tween()
	tw.tween_property(self, "lamp", 1.0, 0.8)
	await narrate("Red follows it until she meets a wire-mesh partition. Behind the mesh: a desk microphone and a small emergency lamp.")
	await narrate("Its battery is already weak.")
	objective()


func _mic() -> void:
	var g := GameState
	g.set_flag("red_mic")
	await player.walk_to(600.0)
	player.face(1)
	await narrate("She reaches through the service opening, catches the microphone cord, and pulls the set close enough to use. The lamp stays behind the mesh. She sits in its narrow spill, where the floor finally holds still.")
	var trusted: bool = g.story.get("JUNE") == "trusted"
	Audio.play_loop("static", -26.0, 0.4)
	if trusted:
		await narrate("On the set's little display, a line keeps repeating: JUNE — IF YOU CAN HEAR, TOUCH THE MICROPHONE TWICE.")
	else:
		await narrate("There is only an open carrier, and several women trying to be heard.")
	await mara("Hello? Somebody?")
	Audio.sfx("breath", -18.0, 1.3)
	Audio.sfx("step_snow", -18.0)
	await narrate("In the receiver, a boy's breath. Snow under boots.")
	await say("TOMAS (RADIO)", "Lady? Are you the tired lady?")
	await narrate("Red puts both hands around the microphone.")
	await mara("Tomas?")
	await say("TOMAS (RADIO)", "How do you know my name?")
	await narrate("She has heard this breath before. On the Day 41 tape, before he called into the trees.")
	await mara("No. No, sweetheart. Turn around.")
	Audio.sfx("voice_short", -16.0, 1.08)
	await narrate("Her own voice comes back, younger with the strain taken out of it: Tomas. Over here.")
	await narrate("Red has not said over here.")
	await mara("Stay away from the trees. Do you hear me? Stay away from the—")
	Audio.sfx("voice_short", -16.0, 1.08)
	await narrate("The echo takes one word. TREES. Then, in her voice: Tomas. Trees.")
	Audio.sfx("step_snow", -14.0)
	await narrate("The boy's boots start moving.")
	await mara("Stop. Please. I'm your sister. I'm—")
	Audio.sfx("scrape", -14.0)
	await narrate("Only the first part comes back: Please. The rest is covered by a chair scraping somewhere above her.")
	Audio.stop_loop("static", 0.1)
	await narrate("She takes her thumb off the switch. In the sudden quiet she understands what she has been listening to for three years.")
	await mara("It was me. It was me he went to.")
	await wait(1.4)
	g.set_flag("red_knows")
	var tw := create_tween()
	tw.tween_property(self, "lamp", 0.6, 1.2)
	await narrate("The lamp dims. In its fading spill, the microphone's label is briefly visible: EMERGENCY — 2.14. Its battery indicator has gone red.")
	if g.has("strip_1983"):
		# Only on the branch where she kept it: the 1.1 chart strip.
		await narrate("She takes out the chart strip she kept in her work notebook. Its upward kicks match the rhythm of her first conversation. She has carried the warning all night without knowing what it was warning her about.")
		g.set_flag("red_strip")
	await mara("Somebody cut the ends off what I said.")
	await hud.choose(["Cover the microphone"])
	await narrate("She covers the microphone and speaks into her sleeve. No echo. When she opens it again, the echo uses her last uncovered word.")
	await narrate("Talking into the set gives the other end more to use. Staying silent does not give her a way out.")
	Audio.play_loop("static", -26.0, 0.3)
	if trusted:
		await say("JUNE (RADIO)", "Don't give me your name, honey. Give me something happening where you are.")
		for i in 2:
			Audio.sfx("knock", -12.0, 1.6)
			await wait(0.35)
		await narrate("Red hits the mesh twice with the microphone.")
		await say("JUNE (RADIO)", "There. Again, one this time.")
		Audio.sfx("knock", -12.0, 1.6)
		await wait(0.4)
		Audio.sfx("click", -14.0, 1.4)
		await narrate("Red hits it once. June answers with one knock of her pencil against her own set.")
		await say("JUNE (RADIO)", "All right. I've got the living end of you. Which dog?")
		await mara("Pepper.")
		await say("JUNE (RADIO)", "Thought so. Keep a hand on that wire. Tell me what you can feel.")
	else:
		if g.story.get("ANSWERED") == true:
			await narrate("She will not use their goodbye as proof. She gave it to the room once.")
			await mara("Pepper. Anyone who knows Pepper.")
		else:
			await mara("...%s" % Story.signoff_line())
		Audio.sfx("voice_short", -18.0, 0.95)
		await wait(0.2)
		Audio.sfx("voice_short", -20.0, 1.05)
		await narrate("Several voices answer. None knows why she has chosen that word.")
		await say("JUNE (RADIO)", "Too many of you on top of each other. One at a time. Please, girls. I can't hear a thing.")
		Audio.sfx("knock", -12.0, 1.6)
		await narrate("Red strikes the mesh with the microphone. June hears a noise, but cannot yet separate her from the others. Red keeps her hand on the wire and starts finding her own way along it.")
	Audio.stop_loop("static", 0.6)
	objective()


## The metal door at the end of the mesh: no handle on her side. When the dish
## turns, the top hinge moves; she hears the control-room recorder through it.
func _door() -> void:
	var g := GameState
	await player.walk_to(880.0)
	player.face(1)
	Audio.play_loop("dish_motor", -30.0, 0.6)
	await narrate("Behind the microphone, the wire-mesh partition ends at a metal door. The door has no handle on Red's side.")
	Audio.sfx("scratch", -22.0)
	await narrate("When the dish outside turns, the top hinge moves against her fingers; she hears the control-room recorder through it. The spaces are touching for a moment at a time.")
	Audio.sfx("tape_rip", -12.0)
	await narrate("She ties a strip of her red tape round the mesh beside the hinge.")
	g.set_flag("red_tape_hinge")
	await mara("I'm at a door. I can hear the pen.")
	if g.story.get("JUNE") == "trusted":
		await narrate("June asks for the rhythm of the pen so she can compare it with Blue's room. Red taps it out against the steel.")
	else:
		await narrate("Red listens until she can recognise the pen's scrape herself.")
	await mara("I'm not lost.")
	await narrate("She says it again, to the door rather than the radio.")
	await mara("I'm here.")
	var tw := create_tween()
	tw.tween_property(self, "lamp", 0.3, 1.2)
	await narrate("The lamp fades another shade. Red braces one foot against the bottom of the door so she will not drift away from it if the light dies.")
	g.set_flag("red_done")
	Audio.stop_all(1.2)
	await hud.fade_out(1.2)
	Act3.become_blue()
	await hud.card("1983", "The control room", 1.6)
	await narrate("Back in 1983, Blue hears that last sentence. It is not an echo. Someone is waiting on the other side of a wall she cannot yet find.")
	main.change_room("control_room", "after_red")


# --- drawing --------------------------------------------------------------------------

func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("07080a"))
	if stage == 0 or (stage > 0 and stage < 4):
		# Nothing but the dark every station shares, and the strip of tape on the floor.
		for i in 60:
			var p := Vector2(Kit.L + Townscape.h(i * 7) * (Kit.R - Kit.L), Townscape.h(i * 13) * 720.0)
			cv.draw_circle(p, 1.0 + Townscape.h(i) * 1.5, Color(0.3, 0.32, 0.4, 0.15))
		cv.draw_rect(Rect2(620, 660, 34, 6), Color(0.45, 0.12, 0.1, 0.6))
		return
	# The mesh, the lamp and the microphone, the door.
	var mesh := Rect2(520, 260, 400, 390)
	cv.draw_rect(Rect2(mesh.position.x + 20, 520, 160, 12), Color("1a1c1e"))
	for x in range(int(mesh.position.x), int(mesh.end.x), 14):
		cv.draw_line(Vector2(x, mesh.position.y), Vector2(x + 60, mesh.end.y), Color(0.35, 0.37, 0.4, 0.35), 1.0)
		cv.draw_line(Vector2(x + 60, mesh.position.y), Vector2(x, mesh.end.y), Color(0.35, 0.37, 0.4, 0.35), 1.0)
	cv.draw_rect(mesh, Color("2a2c30"), false, 4.0)
	# The service opening at waist height.
	cv.draw_rect(Rect2(600, 470, 70, 40), Color("0a0b0d"))
	cv.draw_rect(Rect2(600, 470, 70, 40), Color("3a3c40"), false, 2.0)
	# The metal door, no handle on this side.
	var d := Rect2(924, 300, 120, 350)
	cv.draw_rect(d, Color("2a2e32"))
	cv.draw_rect(d, Color("14171a"), false, 3.0)
	cv.draw_rect(Rect2(d.position.x - 6, d.position.y + 20, 8, 30), Color("4a4e52"))
	cv.draw_rect(Rect2(d.position.x - 6, d.end.y - 50, 8, 30), Color("4a4e52"))
	if GameState.has("red_tape_hinge"):
		cv.draw_rect(Rect2(d.position.x - 14, d.position.y + 56, 10, 22), Color("b8322c"))
	cv.draw_rect(Rect2(Kit.L, 650, Kit.R - Kit.L, 120), Color("0c0d0f"))


func draw_glow(ci: CanvasItem) -> void:
	if stage > 0 and stage < 4:
		# Where each sound comes from: rings spreading out of the dark.
		var tn: Dictionary = TURNINGS[stage - 1]
		for i in 3:
			var c: Vector2 = SPOTS[i]
			var loud: float = 1.0 if i == int(tn.right) else 0.7
			for k in 3:
				var r := fposmod(t * 40.0 + k * 40.0, 120.0)
				var a := (1.0 - r / 120.0) * 0.3 * loud
				ci.draw_arc(c, r + 10.0, 0.0, TAU, 32, Color(0.75, 0.8, 0.95, a), 2.0)
			# What she hears from there, written in the middle of its rings.
			var w := 320.0
			var x0 := clampf(c.x - w * 0.5, 8.0, 1272.0 - w)
			Kit.text(ci, Vector2(x0, c.y - 18), str(SIDES[i]).to_upper(), 13, Color(0.75, 0.8, 0.95, 0.55), HORIZONTAL_ALIGNMENT_CENTER, w)
			Kit.text(ci, Vector2(x0 + 1, c.y + 35), str(tn.names[i]), 18, Color(0, 0, 0, 0.8), HORIZONTAL_ALIGNMENT_CENTER, w)
			Kit.text(ci, Vector2(x0, c.y + 34), str(tn.names[i]), 18, Color(0.86, 0.89, 0.98, 0.9), HORIZONTAL_ALIGNMENT_CENTER, w)
	if stage == 4 and lamp > 0.0:
		var f := 0.9 + 0.1 * sin(t * 9.0)
		var lp := Vector2(800, 500)
		Kit.soft_glow(ci, lp, 160.0 * lamp, Color(1.0, 0.86, 0.6, 0.35 * lamp * f))
		ci.draw_rect(Rect2(lp.x - 14, lp.y - 8, 28, 16), Color(1.0, 0.92, 0.7, 0.9 * lamp))
		ci.draw_rect(Rect2(lp.x - 18, lp.y + 8, 36, 10), Color(0.2, 0.2, 0.22, 1.0))
		# The battery indicator, red.
		ci.draw_rect(Rect2(lp.x + 10, lp.y + 10, 5, 5), Color(0.9, 0.15, 0.1, 0.9))
		# The desk microphone on its stand, the cord through the opening.
		var m := Vector2(700, 500) if not GameState.has("red_mic") else Vector2(640, 520)
		ci.draw_line(m + Vector2(0, 20), m, Color(0.25, 0.25, 0.28, lamp), 3.0)
		ci.draw_rect(Rect2(m.x - 6, m.y - 16, 12, 18), Color(0.3, 0.3, 0.33, lamp))
		ci.draw_rect(Rect2(m.x - 14, m.y + 20, 28, 5), Color(0.25, 0.25, 0.28, lamp))
