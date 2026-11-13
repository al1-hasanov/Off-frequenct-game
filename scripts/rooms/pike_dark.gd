extends "res://scripts/rooms/pike_radio.gd"
## Act 3.7 — Pike Radio in station 44, where the storm has the power out. June
## isn't here. Red finds the rig by touch, and under the little bench by the
## shelves the storm batteries June keeps for the winters: jumper leads, post
## to post, fat to fat, since the positive post is always the bigger one. The
## pilot lamp is the first light she's had since the kitchen. Then she calls
## on 2.14, and the dish carries the call three years back.

const PILOT := Vector2(1102, 440)

var pilot := 0.0
var pilot_light: PointLight2D


func setup() -> void:
	animated_back = false
	place_name = "Pike Radio  ·  44"
	base_tint = Color(0.95, 0.96, 0.86)
	walk_min = 110.0
	walk_max = 560.0
	make_player(140.0, 1)
	player.wrist_tape = Color("b8322c")
	add_layer(1, _draw_counter)
	pilot_light = add_lamp(PILOT, 2.2, Color(1.0, 0.7, 0.4), 0.0)
	pilot = 1.0 if GameState.has("red_lamp") else 0.0
	add_hotspot("door", Rect2(26, 330, 100, 320), "Door", 110.0, -1)
	add_hotspot("shelves", Rect2(150, 240, 320, 250), "Shelves", 320.0)
	add_hotspot("batteries", Rect2(474, 572, 112, 78), "Under the bench", 440.0, 1)
	add_hotspot("rig", Rect2(880, 380, 250, 110), "June's rig", 540.0, 1)
	add_hotspot("counter", Rect2(590, 556, 430, 94), "Counter", 540.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 140.0
	player.face(1)


func is_dark() -> bool:
	return true


func score_quiet() -> bool:
	return true


func ambience() -> void:
	Audio.play_loop("wind", -22.0)
	Audio.set_environment("pike_radio", freq)


func _process(delta: float) -> void:
	super(delta)
	if pilot_light != null:
		pilot_light.energy = pilot * 1.3


func on_arrive() -> void:
	ambience()
	if not GameState.has("red_44"):
		GameState.set_flag("red_44")
		await wait(0.4)
		await mara("June? ...No June. Just her radios, cold. The storm's got the power out.")
		await mara("Wherever this is, it isn't home. The dial would say. If I had a dial.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"door":
			await mara("Back into the dark? No. Not without a light.")
		"shelves":
			await mara("Radios, every one of them dead. I know these by touch. That's Mrs. Halloran's kitchen set.")
		"counter":
			await mara("June's counter. Her mug. Cold.")
		"batteries":
			await _batteries()
		"rig":
			await _use_rig()


func use_item(_id: String, _item: String) -> bool:
	return false


func _batteries() -> void:
	var g := GameState
	if g.has("red_lamp"):
		await mara("Fat to fat. It's holding. For now.")
		return
	await mara("Under the bench: June's storm batteries. Four car batteries for the winters, and a set of jumper leads.")
	await narrate("By touch: two posts on each battery. One fat, one thin.")
	while true:
		var pick: int = await hud.choose(["Fat post to fat post", "Fat post to thin post"])
		if pick == 0:
			break
		Audio.sfx("crack", -8.0)
		await narrate("A spark bites her fingers.")
		await mara("Ow. Wrong way round. The positive post's always the fat one. Dad said.")
	Audio.sfx("click", -6.0)
	await wait(0.4)
	Audio.sfx("powerup", -8.0)
	var tw := create_tween()
	tw.tween_property(self, "pilot", 1.0, 1.2)
	await tw.finished
	g.set_flag("red_lamp")
	await mara("Light.")
	await mara("The pilot lamp on June's rig. The first light since the kitchen.")
	await mara("Light holds you. I'm in a station now. At a radio I know how to use.")
	objective()


## (Not _rig(): that's the parent's drawing of the rig.)
func _use_rig() -> void:
	var g := GameState
	if not g.has("red_lamp"):
		await mara("June's rig, cold under my hands. No power. Not a flicker.")
		return
	await _call()


## Red's call on 2.14, with their goodbye for a call sign.
func _call() -> void:
	var g := GameState
	g.set_flag("red_called")
	Audio.play_loop("static", -20.0, 0.5)
	await narrate("She keys the mic. Two-point-one-four.")
	var sign: String = {"over": "Over-and-Out", "light": "Leave-a-Light", "dial": "End-of-the-Dial"}.get(Story.signoff_key(), "Over-and-Out")
	if g.story.get("ANSWERED") == true:
		await mara("Not our goodbye. I said it on an open band once. Anybody could have heard.")
		sign = "Pepper"
	await mara("This is %s, calling anyone on two-fourteen." % sign)
	await mara("My name's Mara Lind. Ash Street, Halvard. There's somebody in my house. I'm stuck somewhere dark, and I can't find the way out.")
	await narrate("Her words come back a beat late, tired and slightly wrong, as if something were learning them.")
	await wait(0.6)
	await say("TOMAS (RADIO)", "Mara? Is that you? Where are you? Hold on. I'm coming.")
	await narrate("A boy. Thirteen. Her own Tomas, in the weeks before the trees. The dish has carried her call three years back, into his headphones.")
	await mara("No. No, stay home. Tomas, stay away from the trees—")
	await narrate("The warning doesn't go through. What comes back on the echo is only her first line, and the boy saying he's coming.")
	await mara("It was me. It was me he went to.")
	if g.story.get("SWITCH") == "confide":
		await wait(0.5)
		await say("JUNE (RADIO)", "I hear you, honey. Whichever one you are. Stay by that light and keep talking.")
	else:
		await wait(0.8)
		await narrate("Nobody else answers.")
	Audio.stop_loop("static", 1.0)
	for k in 4:
		pilot = 0.3
		await wait(0.12)
		pilot = 0.9
		await wait(0.3)
	await narrate("The pilot lamp flickers. The storm batteries won't last.")
	var tw := create_tween()
	tw.tween_property(self, "pilot", 0.0, 1.4)
	await tw.finished
	await hud.fade_out(0.8)
	await wait(1.2)
	# Back to Blue, waking on the floor of the feed cabin.
	g.set_flag("red_done")
	Act3.become_blue()
	g.frequency = "H"
	g.travel("")
	g.set_clock("2:14", true)
	main.change_room("dish", "wake")


# --- drawing --------------------------------------------------------------------------

## The radios are dead: nothing moves on the shelves or the rig.
func draw_anim(_ci: CanvasItem) -> void:
	pass


## June's cot isn't here. A little bench by the shelves, the storm batteries under it.
func _cot() -> void:
	cv.draw_rect(Rect2(476, 556, 110, 10), Color("5a4a38"))
	cv.draw_line(Vector2(482, 566), Vector2(482, 650), Color("2a2420"), 5.0)
	cv.draw_line(Vector2(580, 566), Vector2(580, 650), Color("2a2420"), 5.0)
	for k in 4:
		var r := Rect2(488 + (k % 2) * 46, 592 + (k / 2) * 30, 40, 26)
		cv.draw_rect(r, Color("1e2024"))
		cv.draw_circle(r.position + Vector2(10, 0), 4.0, Color("8a2a24"))
		cv.draw_circle(r.position + Vector2(30, 0), 2.5, Color("2a2a2a"))
	cv.draw_line(Vector2(498, 592), Vector2(520, 572), Color("b8322c"), 2.0)
	cv.draw_line(Vector2(538, 592), Vector2(560, 576), Color("1a1a1a"), 2.0)


func draw_glow(ci: CanvasItem) -> void:
	if pilot > 0.0:
		Kit.soft_glow(ci, PILOT, 60.0 * pilot, Color(1.0, 0.6, 0.3, 0.4 * pilot))
		ci.draw_circle(PILOT, 4.0, Color(1.0, 0.75, 0.4, pilot))
