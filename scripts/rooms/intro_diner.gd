extends "res://scripts/rooms/diner.gd"
## The opening, part 1: the Lantern, October 14, 1980, shortly after midnight.
## Rain has turned to snow against the windows. Tomas is doing his homework
## under a radio he's taken apart in the corner booth; Mara comes in from the
## observatory with her work coat over her arm. Then Henrik calls her back up
## the mountain, and Tomas talks his way into coming.
##
## The player answers the phone and, at the end, takes him out of the door.

const PHONE := Vector2(508, 404)

## How far the scene has got: "" (arriving), "ringing", "called", "leaving".
var phase := ""
var bag_on_counter := false
var table_cleared := false
var receiver_up := false
var _ring_t := 0.0


func is_1980() -> bool:
	return true


func setup() -> void:
	animated_back = false
	add_window_snow()
	place_name = "The Lantern · October 14, 1980"
	base_tint = Color(1.0, 0.95, 0.86)
	shows_hud = true
	walk_min = 70.0
	walk_max = 1000.0
	ruth = add_actor("ruth_1980", 770.0, -1)
	trucker = add_actor("dahl_1980", 440.0, -1)
	trucker.seated = true
	tomas = add_actor("tomas", 202.0, 1)
	tomas.seated = true
	tomas.prop = "none"
	tomas.headphones_mode = "neck"
	add_layer(1, _draw_counter)
	make_player(64.0, 1, "mara_1980")
	player.prop = "coat"
	player.prop_col = Color("5f5c3c")

	add_hotspot("front_door", Rect2(26, 330, 100, 320), "Front door", 110.0, -1)
	add_hotspot("phone", Rect2(PHONE.x - 26, PHONE.y - 10, 52, 86), "Telephone", PHONE.x - 40.0, 1)
	add_hotspot("tomas", Rect2(170, 450, 120, 200), "Tomas", 330.0, -1, func() -> bool: return phase in ["", "ringing"])
	add_hotspot("dahl", Rect2(400, 470, 90, 180), "Mr. Dahl", 330.0, 1)
	add_hotspot("ruth", Rect2(690, 440, 170, 120), "Mom", 640.0, 1, func() -> bool: return ruth.position.x > 600.0)
	add_hotspot("window", WIN.grow(8), "Front window", 300.0, -1)
	add_hotspot("menu", Rect2(600, 240, 360, 100), "Menu board", 760.0)


func enter(_entry: String) -> void:
	entered_from = _entry
	GameState.set_clock("12:24")
	player.position.x = 64.0
	player.face(1)


func score_quiet() -> bool:
	return true


func static_key() -> String:
	return "%s|%s|%s" % [bag_on_counter, table_cleared, receiver_up]


func ambience() -> void:
	Audio.stop_all(0.4)
	Audio.play_loop("radio_music", -27.0)
	Audio.set_environment("diner", "12")


func _process(delta: float) -> void:
	super(delta)
	# The phone rings the way phones did: a burst, then a pause.
	if phase == "ringing":
		_ring_t -= delta
		if _ring_t <= 0.0:
			_ring_t = 3.2
			Audio.sfx("ring", -6.0)


func on_arrive() -> void:
	ambience()
	if GameState.has("intro_called"):
		# Back here from a save after the call: just the leaving to do.
		phase = "leaving"
		_after_call_positions()
		GameState.set_objective("Take Tomas up to the observatory.")
		return
	GameState.set_objective("")
	await wait(0.6)
	Audio.sfx("shopbell", -12.0)
	await player.walk_to(600.0)
	await say("RUTH", "You're late.")
	await mara("Receiver two. Again.")
	await say("TOMAS", "Did you fix it?")
	await mara("Temporarily.")
	await say("TOMAS", "That means no.")
	await mara("That means put your coat on.")
	Audio.sfx("scrape", -20.0, 1.3)
	bag_on_counter = true
	await narrate("Ruth slides a paper bag across the counter.")
	await say("RUTH", "Something for breakfast. Try to leave some until breakfast.")
	tomas.seated = false
	tomas.z_index = 2  # this side of the counter, by Mara
	await tomas.walk_to(686.0)
	tomas.face(1)
	await narrate("Tomas reaches inside.")
	Audio.sfx("click", -10.0, 1.9)
	await narrate("Without looking, Ruth taps his hand with a spoon.")
	await wait(0.4)
	phase = "ringing"
	_ring_t = 0.0
	GameState.set_objective("Answer the phone.")
	hud.caption("The telephone on the wall is ringing.", 2.6)


func on_hotspot(id: String) -> void:
	match id:
		"phone":
			if phase == "ringing":
				await _call()
			else:
				await mara("The Lantern's phone. Half the county has the number. Henrik has it memorised.")
		"front_door":
			if phase == "leaving":
				await _leave()
			elif phase == "ringing":
				await mara("If I walk out now, it'll only ring up at the observatory instead.")
			else:
				await mara("Not without him.")
		"tomas":
			if phase == "ringing":
				await say("TOMAS", "It's for you. It's always for you.")
			else:
				await say("TOMAS", "I'm nearly done. This bit's nearly done.")
		"dahl":
			await narrate("Mr. Dahl, in his booth with his pie, the same as every night.")
			await say("DAHL", "Evening, Mara. Your brother fixed my watch.")
			await mara("He's going to be an engineer or a burglar.")
		"ruth":
			await say("RUTH", "Eat something, Mara. You look like a draught.")
		"window":
			await mara("Raining when I came down the mountain. It's snow now.")
		"menu":
			await narrate("\"COFFEE 35¢ · PIE 85¢ · SPECIAL: MEATLOAF\"")


## Henrik, from the observatory. We only hear Mara's side.
func _call() -> void:
	phase = "called"
	GameState.set_objective("")
	player.face(1)
	Audio.sfx("hangup", -12.0, 1.3)
	receiver_up = true
	player.prop = "phone"
	await wait(0.4)
	await mara("I just left, Henrik.")
	await wait(1.4)
	await mara("Fine. Don't touch anything. Especially whatever you touched last time.")
	Audio.sfx("hangup", -8.0)
	receiver_up = false
	player.prop = "coat"
	await narrate("She hangs up.")
	await mara("I have to go back.")
	tomas.face(-1)
	await say("TOMAS", "I'm coming.")
	await mara("You're going home.")
	await say("TOMAS", "You promised I could test it by the dish. There's too much interference down here.")
	await say("RUTH", "There's too much homework under it.")
	await narrate("Tomas starts gathering his things.")
	player.walk_to(330.0)
	await tomas.walk_to(236.0)
	tomas.face(1)
	Audio.sfx("click", -14.0, 2.2)
	await wait(0.2)
	Audio.sfx("click", -16.0, 2.6)
	table_cleared = true
	tomas.prop = "radio"
	tomas.headphones_mode = ""
	player.face(-1)
	await narrate("A screw falls onto the floor. Mara catches another before it rolls off the table.")
	await mara("One test. While I finish up.")
	await say("RUTH", "Straight back afterwards.")
	await mara("Straight back.")
	# Ma comes round the counter with the bag.
	bag_on_counter = false
	ruth.prop = "bag"
	await ruth.walk_to(290.0)
	ruth.face(-1)
	await wait(0.3)
	tomas.buttoned = true
	await narrate("Ruth fastens the top button of Tomas's coat.")
	await wait(0.5)
	tomas.buttoned = false
	await narrate("He immediately unfastens it.")
	await say("TOMAS", "I can't breathe like that.")
	await say("RUTH", "Somehow you can still talk.")
	ruth.prop = "none"
	player.prop = "bag"
	await narrate("He grins. Mara takes the paper bag.")
	GameState.set_flag("intro_called")
	phase = "leaving"
	GameState.set_objective("Take Tomas up to the observatory.")


func _after_call_positions() -> void:
	table_cleared = true
	tomas.seated = false
	tomas.position.x = 236.0
	tomas.prop = "radio"
	tomas.headphones_mode = ""
	ruth.position.x = 290.0
	player.prop = "bag"
	player.position.x = 330.0


func _leave() -> void:
	phase = "gone"
	GameState.set_objective("")
	tomas.walk_to(70.0)
	await player.walk_to(96.0)
	player.face(-1)
	ruth.face(-1)
	await say("RUTH", "Both of you. Breakfast.")
	# The family call: Ruth's two notes, and Tomas answering through his teeth.
	Audio.sfx("whistle", -9.0)
	await wait(1.1)
	Audio.sfx("whistle", -17.0, 1.06)
	await narrate("Ruth whistles two notes after them: down, then up. Tomas answers with the same two notes through his teeth.")
	GameState.set_flag("ruth_whistle")
	player.face(1)
	await mara("You still do that?")
	await say("RUTH", "Your father could call you in from three streets away. Saves shouting.")
	await say("TOMAS", "You shout anyway.")
	await say("RUTH", "Gives you something to complain about.")
	player.face(-1)
	Audio.sfx("shopbell", -10.0)
	await hud.fade_out(0.8)
	GameState.set_flag("intro_diner_done")
	main.change_room("intro_road")


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	super()
	_phone()
	if not table_cleared:
		_tomas_table()


## The diner's payphone on the wall, its cord, the coin slots.
func _phone() -> void:
	var p := PHONE
	cv.draw_rect(Rect2(p.x - 18, p.y, 36, 66), Color("1d1f22"))
	cv.draw_rect(Rect2(p.x - 18, p.y, 36, 66), Color("4a4d52"), false, 1.5)
	cv.draw_circle(p + Vector2(0, 34), 10.0, Color("c3c9cf"))
	for k in 10:
		var a := TAU * k / 10.0
		cv.draw_circle(p + Vector2(0, 34) + Vector2(cos(a), sin(a)) * 6.5, 1.3, Color("2a2c30"))
	cv.draw_rect(Rect2(p.x - 12, p.y + 6, 10, 3), Color("c3c9cf"))
	if not receiver_up:
		cv.draw_rect(Rect2(p.x + 14, p.y + 4, 9, 46), Color("111214"))
		cv.draw_rect(Rect2(p.x + 12, p.y, 13, 9), Color("111214"))
		cv.draw_rect(Rect2(p.x + 12, p.y + 46, 13, 9), Color("111214"))
		var coil := PackedVector2Array()
		for k in 10:
			coil.append(Vector2(p.x + 20 + sin(k * 1.8) * 3.0, p.y + 56 + k * 3.0))
		cv.draw_polyline(coil, Color("111214"), 1.5, true)


## Tomas's corner of the table: schoolbooks under a radio he's taken apart,
## the sugar bowl full of its screws.
func _tomas_table() -> void:
	cv.draw_rect(Rect2(190, 560, 56, 10), Color("3a5a8a"))
	cv.draw_rect(Rect2(194, 553, 50, 8), Color("c8b48a"))
	cv.draw_rect(Rect2(196, 538, 40, 16), Color("4a5a3a"))
	cv.draw_rect(Rect2(199, 541, 18, 9), Color("2f5a3a"))
	cv.draw_circle(Vector2(228, 546), 3.5, Color("1e2420"))
	cv.draw_line(Vector2(222, 538), Vector2(262, 516), Color("9aa0a6"), 1.4)
	for k in 3:
		cv.draw_rect(Rect2(204 + k * 7, 531, 4, 7), [Color("c9a04a"), Color("8a3a2e"), Color("3a5a8a")][k])
	cv.draw_rect(Rect2(242, 543, 18, 9), Color("4a5a3a"))
	# The sugar bowl, and the screws in it.
	cv.draw_rect(Rect2(254, 556, 18, 13), Color("ece6d8"))
	cv.draw_rect(Rect2(252, 553, 22, 4), Color("ece6d8"))
	for k in 4:
		cv.draw_circle(Vector2(257 + k * 4, 554), 1.4, Color("9aa3a8"))
	cv.draw_circle(Vector2(279, 568), 1.4, Color("9aa3a8"))


## The counter, with Ma's paper bag on it until it goes.
func _draw_counter(ci: CanvasItem) -> void:
	super(ci)
	if bag_on_counter:
		var b := Vector2(636, 548)
		ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-14, 0), b + Vector2(14, 0), b + Vector2(12, -30), b + Vector2(-12, -30)]), Color("b58a5a"))
		ci.draw_line(b + Vector2(-12, -26), b + Vector2(12, -26), Color("8a6a40"), 1.2)
		ci.draw_line(b + Vector2(-4, -30), b + Vector2(4, -34), Color("a07a4a"), 2.0)
