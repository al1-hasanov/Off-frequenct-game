extends Room
## Act 2.2 — Pike Radio & Repair. June Pike at her ham rig, every radio in the
## shop talking. She finds the cracked crystal that stops Tomas's dial at 09,
## and fits the one Mara brings back from the sheriff's office.

var june: Actor
var tomas: Actor
## Act 3.5: Ruth, brought down from the diner by June.
var ruth: Actor


func setup() -> void:
	animated_back = false
	place_name = "Pike Radio & Repair"
	base_tint = Color(0.95, 0.96, 0.86)
	walk_min = 110.0
	walk_max = 560.0
	make_player(140.0, 1)
	june = add_actor("june", 820.0, -1)
	tomas = add_actor("tomas", 1130.0, -1)
	tomas.seated = true
	tomas.visible = _tomas_here()
	ruth = add_actor("ruth", 260.0, 1)
	ruth.visible = false
	add_layer(1, _draw_counter)
	add_hotspot("door", Rect2(26, 330, 100, 320), "Door", 110.0, -1)
	add_hotspot("shelves", Rect2(150, 240, 330, 260), "Shelves", 320.0)
	add_hotspot("june", Rect2(780, 440, 90, 210), "June", 540.0, 1)
	add_hotspot("rig", Rect2(880, 380, 250, 110), "Ham rig", 540.0, 1)
	add_hotspot("counter", Rect2(590, 556, 430, 94), "Counter", 540.0, 1)
	add_hotspot("tomas", Rect2(1060, 500, 150, 150), "Tomas", 540.0, 1, _tomas_here)


func _tomas_here() -> bool:
	return GameState.story.get("TOMAS") == "taken"


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 140.0
	player.face(1)
	if entry == "reunion":
		# Over the radio: Mara is at the console, up the mountain.
		player.visible = false
		place_name = "Pike Radio  ·  over the Tuner"


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	Audio.stop_loop("wind", 0.6)
	Audio.stop_loop("crowd", 0.6)
	Audio.play_loop("scanner", -25.0)
	Audio.play_loop("shortwave", -24.0)
	Audio.play_loop("radio_music", -30.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if entered_from == "reunion":
		await _reunion()
		return
	if entered_from == "with_tomas":
		await _with_tomas()
		await _door_scene()
	elif GameState.has("dish_turning") and not GameState.has("june_door"):
		await _door_scene()
	elif not GameState.has("met_june"):
		GameState.set_flag("met_june")
		await wait(0.4)
		await say("JUNE", "Mara Lind. Come in out of the snow.")
		await say("JUNE", "Lit up like Christmas, all of it. And a woman on 2.14 saying the same thing for an hour.")
		await say("JUNE", "Pardon the mess. Mrs. Halloran's kitchen set. She can't sleep without the farm report.")
		await say("JUNE", "Tonight there's a farm report on every band, and none of them agree on the weather.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"door":
			Audio.sfx("shopbell", -12.0)
			main.change_room("main_street", "from_pike")
		"shelves":
			await mara("Every radio in the shop is switched on, all of them going at once.")
		"rig":
			await mara("June's ham rig. The meters are pinned. Every band's crowded with voices.")
		"counter":
			await mara("Tubes, crystals, a soldering iron still warm. A kitchen radio with a repair ticket: HALLORAN.")
		"june":
			await _june()
		"tomas":
			await say("TOMAS", "Is it really 1983? Do I still have my room?")
			await mara("You still have your room.")


func use_item(id: String, item: String) -> bool:
	if id in ["june", "counter", "rig"]:
		if item == "crystal":
			await _repair()
			return true
		if item == "tuner":
			await _diagnose()
			return true
	return false


func _june() -> void:
	if GameState.has_item("crystal"):
		await _repair()
	elif not GameState.has("june_diag"):
		await _diagnose()
	elif not GameState.has("tuner_repaired"):
		await say("JUNE", "The sheriff's base radio, honey. Same crystal. Cal won't miss it till Monday.")
		await say("JUNE", "And stay out of the dark. If you can't, know where you're going.")
	elif not GameState.has("june_door") and GameState.has("dish_turning"):
		await _door_scene()
	elif GameState.story.get("JUNE") == "trusted":
		await say("JUNE", "Which dog, honey? I'll ask it. Whoever comes up on my set.")
	elif _tomas_here():
		await say("JUNE", "He's fine. He ate two sandwiches and asked about my rig. I'll keep him in the light.")
	elif GameState.has("swapped"):
		await say("JUNE", "Find what you were looking for, honey?")
		await mara("Not yet.")
	else:
		await say("JUNE", "Some of those stations are quiet. Don't go to the quiet ones.")


## Act 2.6, both paths: June walks her to the shop door. She wants something
## to know Mara by that isn't her voice (story JUNE: "trusted" or "check").
func _door_scene() -> void:
	GameState.set_flag("june_door")
	await wait(0.4)
	if _tomas_here():
		await narrate("June walks her to the shop door. Tomas is at the bench under the lamp, taking a sandwich apart to see what is in it. June has rigged a car battery to keep the shop lit.")
	else:
		await narrate("June walks her to the shop door. Under the lamp, the stool at the bench is empty. June has rigged a car battery to keep the shop lit.")
	await player.walk_to(220.0)
	june.walk_to(330.0)
	await say("JUNE", "I've put a spare on the aerial. If you're going back up there, give me something I can know you by that isn't your voice.")
	await say("JUNE", "Everybody's got your voice tonight.")
	var pick: int = await hud.choose(["Tell June about the kitchen", "Ask only for a radio check"])
	if pick == 0:
		GameState.set_story("JUNE", "trusted")
		GameState.set_flag("told_june")
		await mara("June. Something happened to me tonight, in the dark. There was a woman with my face, and the match went out. I don't think I'm where I was an hour ago.")
		await say("JUNE", "Honey, nobody is. Not tonight.")
		await wait(0.4)
		await say("JUNE", "...You told me that already, you know. Tuesday.")
		await mara("I wasn't here Tuesday.")
		await say("JUNE", "Somebody with your face was. Asked me if a person could be in two places on the dial at once.")
		await say("JUNE", "Had her hand all bandaged up. I thought you'd burned yourself on the boiler again.")
		await say("JUNE", "I'll tell you what I told her. A station's only as real as whoever's listening.")
		await say("JUNE", "I'm listening, Mara. Whichever one you are.")
		await narrate("She takes a card and a pencil.")
		await say("JUNE", "Now give me the wrong things. All of them.")
		await mara("The dog. Ma calls him Pepper. He's supposed to be Biscuit.")
		await mara("And I was at the door. Then I was standing by the table.")
		GameState.set_flag("june_card")
		await narrate("June writes PEPPER / BISCUIT / ASH STREET and props the card against the receiver.")
		await say("JUNE", "If somebody comes up on my set, I'll ask which dog. Then I'll ask her something only right now knows.")
		await say("JUNE", "A voice can copy a name. I want to hear a person answer.")
	else:
		GameState.set_story("JUNE", "check")
		await mara("Just tell me you can hear this set.")
		await say("JUNE", "Five by nine, honey. I'll leave the other receiver open too. There's more voices on there tonight than yours.")
	objective()


func _diagnose() -> void:
	if GameState.has("june_diag"):
		await say("JUNE", "Crystal's cracked. You need the one from the sheriff's base radio.")
		return
	await mara("June, I need you to look at a radio.")
	await narrate("Mara sets Tomas's radio on the counter.")
	await say("JUNE", "Well. That's a field radio somebody gutted with love.")
	await say("JUNE", "Tomas built this? Thirteen years old.")
	await narrate("June unscrews the back and holds a crystal up to her lamp.")
	await say("JUNE", "There's your trouble. Cracked crystal. That's why your dial dies above 09.")
	await say("JUNE", "You're a station, honey. Somebody knocked your dial.")
	# Her bench test: the warning is a tape, and someone live is under it.
	Audio.sfx("click", -8.0)
	Audio.play_loop("static", -20.0, 0.2)
	await narrate("She clips a bench lead to the set. On her receiver the warning comes round: the scrape, the clicks, the breath.")
	Audio.sfx("scrape", -18.0)
	await wait(0.5)
	Audio.sfx("click", -14.0)
	await wait(0.28)
	Audio.sfx("click", -14.0, 0.78)
	await wait(0.4)
	Audio.sfx("breath", -16.0, 1.1)
	await wait(0.6)
	await say("JUNE", "Hear that? Same breath, same scrape, every time round. That's a tape.")
	await say("JUNE", "But under it... there.")
	Audio.sfx("voice_short", -24.0, 0.9)
	await narrate("A woman begins a different word under it, and is drowned out.")
	await say("JUNE", "That's somebody live, trying to get a word in. Two signals sat on one frequency.")
	await say("JUNE", "I can pull hiss off a voice, honey. I can't tell you whose voice it is.")
	Audio.stop_loop("static", 0.4)
	GameState.set_flag("june_tape_test")
	await mara("Can you fix the set?")
	await say("JUNE", "Not with anything I've got. The only crystal in town that'd fit is in the sheriff's base radio.")
	await say("JUNE", "Cal won't miss it till Monday. But it's locked up tight, and Cal's out on calls.")
	await narrate("She pushes the set back across the counter.")
	await say("JUNE", "A customer walked into my storeroom tonight with the bulb out. Came back with a different wedding ring.")
	await say("JUNE", "That's all I know, and it's plenty. Stay out of the dark, Mara. If you can't, know where you're going.")
	GameState.set_flag("june_diag")
	objective()


func _repair() -> void:
	await mara("Cal's crystal.")
	await say("JUNE", "I won't ask.")
	Audio.sfx("click", -6.0)
	GameState.remove_item("crystal")
	await narrate("June solders it in with three quick touches and turns the dial past 09. It keeps going.")
	GameState.set_flag("tuner_repaired")
	hud.toast("Tomas's radio now reaches 00–99 (use −10 / +10)")
	await say("JUNE", "There. All the way to 99.")
	await say("JUNE", "And that gap you call home, that's a carrier you've learnt by ear, not a number. Go by the hum, not the paint.")
	await say("JUNE", "Some of those stations are going to be quiet. Don't go to the quiet ones.")
	await mara("Quiet how?")
	await say("JUNE", "Quiet like nobody's left to make a sound.")
	objective()


## Back from 1980 with Tomas, by the diner's back door.
func _with_tomas() -> void:
	await wait(0.4)
	await say("JUNE", "Mara? Who's...")
	await narrate("June looks at the boy in the red parka for a long time.")
	await say("JUNE", "Lord. Tomas Lind.")
	await mara("June. Keep him in the light. Whatever happens, keep him in the light.")
	await say("JUNE", "Sit down, sweetheart. There's sandwiches.")
	await say("TOMAS", "Mara? You're coming back, right?")
	await mara("I'm coming back. %s" % Story.blue_signoff())
	await say("TOMAS", "Is it really 1983? Do I still have my room?")
	await mara("You still have your room.")
	GameState.set_flag("dish_turning")
	await wait(0.4)
	Audio.sfx("powerup", -10.0)
	await say("JUNE", "Honey. Look out the window. The dish up on the mountain. It's turning.")
	await say("JUNE", "Whole band's lit up. Whoever's up there, it's for you.")
	await mara("The road's eleven miles. But the old mine runs right under the mountain. Halvard Number 2.")


## Act 3.5: June has called Ruth down from the diner. Mara hears it over the
## Tuner, at the console. Taken: Ruth and the boy who isn't hers. Sent back:
## the empty stool, two sandwiches, the microphone in both hands.
func _reunion() -> void:
	var g := GameState
	g.set_flag("reunion_done")
	await hud.fade_in(0.8)
	await wait(0.3)
	if _tomas_here():
		ruth.visible = true
		ruth.position.x = 300.0
		ruth.prop = "bag"
		tomas.seated = false
		await narrate("June's shop, through the Tuner. Ruth stands in the doorway holding the paper bag she brought for Mara. June has called her down from the diner.")
		Audio.sfx("thunk", -18.0, 1.6)
		await narrate("Tomas has stood up too fast and knocked the teaspoon off the receiver.")
		await say("RUTH", "No.")
		await say("TOMAS", "Mom?")
		ruth.prop = "none"
		Audio.sfx("thunk", -16.0, 0.9)
		await narrate("Ruth does not cross the room. She puts the bag on the nearest surface, misses it, and lets it fall. She is looking at his collar.")
		await say("RUTH", "I buttoned that.")
		await narrate("Tomas looks down at the crooked top button.")
		await say("TOMAS", "You said I'd grow into it.")
		ruth.walk_to(1040.0)
		await tomas.walk_to(1080.0)
		ruth.arm_pose = [[1.55, 1.2], [1.45, 1.3]]
		await narrate("Ruth reaches him before he finishes. One hand behind his head, one between his shoulders. She holds him so tightly he has to move his chin to breathe.")
		await say("TOMAS", "I only went up the mountain.")
		await say("RUTH", "I know.")
		await say("TOMAS", "I was coming back.")
		await say("RUTH", "I know, baby.")
		await narrate("Up the mountain, Mara takes her hand off the talk button. They should not have to hear her crying.")
		await wait(0.6)
		await narrate("After a while Ruth eases the top button through its hole. Tomas catches her wrist.")
		await say("TOMAS", "She's still there. My mom. I left her in the diner.")
		ruth.arm_pose = []
		await narrate("Ruth's hands stop. She looks at June; June does not pretend otherwise.")
		await say("RUTH", "The one who buttoned this.")
		await narrate("Tomas nods. Ruth finishes undoing the button.")
		await say("RUTH", "Then we mustn't leave her waiting.")
		await narrate("He leans into her again. She holds him, knowing that.")
		await say("MARA (TUNER)", "June. Keep him in the light.")
		await wait(0.4)
		await say("MARA (TUNER)", "No. Wait. If the white comes, don't stay there for the lamp. Take him. Take both of them.")
		await say("JUNE", "A lamp's an anchor, honey. It isn't a roof. I've got a battery lantern and Ruth's got the truck. We'll move together.")
		await say("TOMAS", "Mara? I want to go back to her. When you can.")
		await say("MARA (TUNER)", "I heard you.")
		await narrate("He waits for a promise. She cannot make him one. He picks up the teaspoon and puts it back against the contact.")
		g.set_flag("tomas_wants_home")
	else:
		ruth.visible = true
		ruth.position.x = 520.0
		await narrate("June's shop, through the Tuner. Ruth has brought the paper bag down to June's. She stops by the bench, where a lamp lights an empty stool. June turns the set toward her.")
		await say("RUTH", "June says you found him.")
		await say("MARA (TUNER)", "A Tomas. In 1980. There was someone waiting for him. His sister. She came into the snow and called him.")
		await narrate("Ruth looks at the stool.")
		await say("RUTH", "You left him there.")
		await say("MARA (TUNER)", "Yes.")
		await narrate("Ruth sets the bag beside the lamp. Two sandwiches. She made them before she knew why June had called.")
		await say("RUTH", "Was he cold?")
		await say("MARA (TUNER)", "Not when I left.")
		await narrate("Ruth nods once. She puts one sandwich away, changes her mind, and leaves both out.")
		await say("RUTH", "Good.")
		await say("MARA (TUNER)", "Mom—")
		await narrate("The word surprises Mara. She has borrowed it without thinking.")
		await say("RUTH", "I'm here.")
		await say("MARA (TUNER)", "I'm sorry I couldn't bring him to you.")
		await say("RUTH", "I don't know what to do with that yet.")
		await narrate("She sits on the empty stool and holds the microphone in both hands.")
		await say("RUTH", "But I know you're still up there. Let June help you come down.")
	await wait(0.6)
	await hud.fade_out(0.8)
	main.change_room("control_room", "from_corridor")


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(cv, floor_y, Color("4a5048"), Color("3a403a"), Color("1f2420"))
	EnvironmentArt.wall_props(cv, str(name))
	cv.draw_rect(Rect2(Kit.L, floor_y, Kit.R - Kit.L, 400), Color("3a3028"))
	for i in 20:
		cv.draw_line(Vector2(Kit.L + i * 120.0, floor_y), Vector2(Kit.L + i * 120.0 - 60, 760), Color(0, 0, 0, 0.15), 2.0)
	Kit.door(cv, Rect2(30, 340, 92, 310), Color("4a5258"))
	_shelves()
	_rig()
	_cot()


func _shelves() -> void:
	var r := Rect2(150, 240, 330, 260)
	cv.draw_rect(r, Color("2a241e"))
	for row in 3:
		var y := r.position.y + 10 + row * 84
		cv.draw_rect(Rect2(r.position.x, y + 72, r.size.x, 8), Color("4a3a2a"))
		for k in 4:
			var x := r.position.x + 12 + k * 80
			var body: Color = [Color("6a4a30"), Color("3a3a3e"), Color("8a6a40"), Color("2e4a3a")][(row + k) % 4]
			cv.draw_rect(Rect2(x, y + 22, 66, 50), body)
			cv.draw_circle(Vector2(x + 54, y + 52), 6.0, Color("1a1a1a"))
			cv.draw_line(Vector2(x+54,y+48),Vector2(x+54,y+52),Color("c6b890"),1.0)
			for bar in 8:
				cv.draw_line(Vector2(x+7+bar*4,y+49),Vector2(x+7+bar*4,y+63),body.darkened(0.45),1.0)
			cv.draw_rect(Rect2(x+2,y+24,62,46),body.lightened(0.15),false,1.0)


## The shelf radios' dials breathe and the rig's needles swing.
func draw_anim(ci: CanvasItem) -> void:
	super(ci)
	var r := Rect2(150, 240, 330, 260)
	for row in 3:
		var y := r.position.y + 10 + row * 84
		for k in 4:
			var x := r.position.x + 12 + k * 80
			var glow := 0.6 + 0.4 * sin(t * (1.3 + k * 0.4) + row)
			ci.draw_rect(Rect2(x + 8, y + 30, 34, 12), Color(1.0, 0.68, 0.3, glow))
			for mark in 7:
				ci.draw_line(Vector2(x + 10 + mark * 4, y + 31), Vector2(x + 10 + mark * 4, y + 35), Color("6a553a"), 1.0)
	for k in 3:
		var x := 900.0 + k * 76.0
		var a := -0.8 + 0.25 * sin(t * (3.0 + k)) + 1.2
		ci.draw_line(Vector2(x + 30, 428), Vector2(x + 30, 428) + Vector2(sin(a), -cos(a)) * 26.0, Color("8a1d1d"), 2.0)


func _rig() -> void:
	cv.draw_rect(Rect2(870, 470, 280, 20), Color("4a3a2a"))
	cv.draw_rect(Rect2(884, 384, 240, 88), Color("2a2c30"))
	for k in 3:
		var x := 900.0 + k * 76.0
		cv.draw_rect(Rect2(x, 396, 60, 36), Color("e8e0c0"))
	for k in 6:
		cv.draw_circle(Vector2(906 + k * 38, 452), 8.0, Color("1a1a1a"))
	cv.draw_line(Vector2(1110, 384), Vector2(1110, 0), Color("1a1a1a"), 3.0)
	cv.draw_rect(Rect2(1040, 330, 70, 50), Color("3a3a3e"))
	cv.draw_circle(Vector2(1075, 355), 18.0, Color("2a2a2e"))


func _cot() -> void:
	cv.draw_rect(Rect2(1050, 600, 190, 16), Color("4a5a48"))
	cv.draw_line(Vector2(1060, 616), Vector2(1060, 650), Color("2a2a2a"), 4.0)
	cv.draw_line(Vector2(1230, 616), Vector2(1230, 650), Color("2a2a2a"), 4.0)
	cv.draw_rect(Rect2(1180, 584, 54, 18), Color("d8d0c0"))


func _draw_counter(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(590, 556, 430, 14), Color("6a4a30"))
	ci.draw_rect(Rect2(600, 570, 410, 80), Color("54392a"))
	ci.draw_rect(Rect2(620, 584, 370, 52), Color("4a3224"))
	for k in 4:
		ci.draw_rect(Rect2(626 + k * 90, 526, 50, 30), Color("3a3a3e"))
		ci.draw_rect(Rect2(632 + k * 90, 532, 26, 8), Color(1.0, 0.7, 0.35, 0.8))
		for i in 7:
			ci.draw_line(Vector2(631+k*90+i*4,546),Vector2(631+k*90+i*4,552),Color("1d2423"),1.0)
	EnvironmentArt.mug(ci,Vector2(971,541))
