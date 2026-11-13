extends Room
## Act 3.2 — 2031, inside the Halvard Signal Visitor Center: the old lobby and
## labs made over. Polished concrete, charcoal walls, LED track lights, glass
## cases. The recordings wall and Cal's card index, the transcript of the 2:14
## transmission, Sollen's desk behind a rope, the 2.14 study with Dad in it,
## and a brass plaque by the control-room door. Every radio in the gift shop is
## silent; a screen over it says NO SIGNAL. People talk in whispers.
##
## At 2:14 PM the sound goes, and the white comes down the valley.

const NEEDED := ["ruth_tape", "knows_key", "anders_exhibit", "cal_plaque"]

var cal: Actor
## 2:14 PM: the white, rolling in behind the glass doors (0..1).
var white := 0.0
var shot := ""


func env() -> Env:
	return Env.of("F2031")


func setup() -> void:
	animated_back = false
	place_name = "Visitor center  ·  2031"
	base_tint = Color(1.0, 0.98, 0.95)
	walk_min = 70.0
	walk_max = 1170.0
	make_player(130.0, 1)
	cal = add_actor("cal_2031", 566.0, -1)
	add_hotspot("exit", Rect2(16, 330, 104, 320), "Way out", 110.0, -1)
	add_hotspot("shop", Rect2(132, 286, 106, 300), "Gift shop", 196.0)
	add_hotspot("wall", Rect2(254, 248, 268, 196), "Recordings wall", 380.0)
	add_hotspot("index", Rect2(392, 496, 112, 124), "Card index", 470.0)
	add_hotspot("cal", Rect2(526, 440, 84, 210), "Cal", 486.0, 1)
	add_hotspot("transcript", Rect2(626, 246, 166, 232), "Transcript", 706.0)
	add_hotspot("desk", Rect2(808, 500, 170, 150), "Sollen's desk", 890.0)
	add_hotspot("study", Rect2(1000, 246, 140, 236), "The 2.14 study", 1068.0)
	add_hotspot("plaque", Rect2(1140, 380, 32, 44), "Brass plaque", 1140.0, 1)
	add_hotspot("equation", Rect2(560, 118, 400, 74), "Lettering on the wall", 760.0)
	add_hotspot("control_door", Rect2(1176, 330, 96, 320), "Control room", 1160.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	player.position.x = 130.0
	player.face(1)


func static_key() -> String:
	return "silent" if GameState.has("silence_2031") else ""


func ambience() -> void:
	Audio.stop_loop("wind", 0.6)
	Audio.play_loop("room_air", -26.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	if not GameState.has("center_seen"):
		GameState.set_flag("center_seen")
		await wait(0.3)
		await narrate("A notice by the door: \"Some audio exhibits unavailable. Please ask a volunteer for a transcript.\"")
		await mara("It's my lobby. Somebody's put the whole night in glass cases.")
		await say("CAL", "(quietly) Afternoon. Welcome to Halvard Signal. Take your time.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"exit":
			Audio.sfx("door", -14.0)
			main.change_room("dish", "from_center")
		"shop":
			await mara("A rack of transistor radios, twenty-four dollars each. Every one of them switched on. Every one of them silent.")
			await mara("A screen over the rack: NO SIGNAL.")
		"wall":
			await narrate("THE RECORDINGS. What Halvard taped when the radios went: kitchen tapes, answering machines, a shelf of June Pike's call logs.")
			await mara("Thousands of them. Every one somebody's voice, kept.")
		"index":
			if GameState.has("ruth_tape"):
				await mara("RUTH LIND, THE LANTERN. Cal put the card back exactly where it was.")
			elif GameState.has("cal_met"):
				await _ruth_tape()
			else:
				await mara("A library card cabinet, a hundred little drawers. The docent would know where everything is.")
		"cal":
			await _cal()
		"transcript":
			await _transcript()
		"desk":
			await _desk()
		"study":
			await _study()
		"plaque":
			await _plaque()
		"equation":
			await _equation()
		"control_door":
			await mara("CLOSED FOR CONSERVATION. A red rope across it.")
			await mara("My control room. Where she's lying, tonight.")


func use_item(id: String, item: String) -> bool:
	if item == "cassette_2031" and id == "cal":
		await say("CAL", "That's yours. We don't take them back.")
		return true
	if item == "tuner":
		await mara("Nothing. Not even static. It's the same on every band.")
		return true
	return false


func _cal() -> void:
	var g := GameState
	if g.has("ruth_tape"):
		var left := _left()
		if left.is_empty():
			await say("CAL", "(whispering) Nearly two-fifteen. Funny. I always get a feeling, round now.")
		else:
			await say("CAL", "(whispering) The history's on the right. Don't miss the little plaque by the door. It's the one people ask about.")
		if not g.has("museum_lambda"):
			await say("CAL", "(whispering) And look up. Everybody forgets to look up.")
		return
	if not g.has("cal_met"):
		g.set_flag("cal_met")
		await say("CAL", "(whispering) We keep our voices down these days. Everybody does. It's the quiet. You notice yourself in it.")
		await wait(0.3)
		await say("CAL", "...")
		await say("CAL", "You've got a face I used to know.")
		await mara("I get that a lot.")
		await say("CAL", "Who are you looking for? Everybody who comes up here is looking for somebody.")
	else:
		await say("CAL", "Found who you were looking for?")
	var pick: int = await hud.choose(["\"Ruth Lind. She ran the Lantern.\"", "\"Just looking.\""])
	if pick == 0:
		await _ruth_tape()
	else:
		await say("CAL", "Take your time. Recordings on the left, the history on the right.")
		objective()


func _ruth_tape() -> void:
	var g := GameState
	await say("CAL", "Ruth Lind. Sure.")
	await cal.walk_to(512.0)
	cal.face(-1)
	await narrate("He flips through the cards without looking, the way you'd find a spoon in your own kitchen.")
	await narrate("RUTH LIND  ·  THE LANTERN  ·  LAST NIGHT, MARCH 1998.")
	await say("CAL", "She closed up for good that spring. One of the regulars taped her last night.")
	Audio.play_loop("tape_hiss", -16.0, 0.3)
	await wait(0.6)
	await say("RUTH (TAPE)", "Last pie of the last night. Don't you tell me you're not hungry, Walt.")
	await say("RUTH (TAPE)", "My girl worked nights up at the dish. Came in at one for pie, every night.")
	await say("RUTH (TAPE)", "I still cut two slices.")
	Audio.stop_loop("tape_hiss", 0.6)
	await wait(0.8)
	await mara("...")
	await say("CAL", "We copy them, for families.")
	await narrate("He hands her a cassette. He doesn't ask whether she's family.")
	g.add_item("cassette_2031")
	hud.toast("Got: Cassette")
	g.set_flag("ruth_tape")
	await cal.walk_to(566.0)
	cal.face(-1)
	if not g.has("museum_lambda"):
		await say("CAL", "(whispering) And look up, while you're here. Everybody forgets to look up.")
	await _maybe_silence()


func _transcript() -> void:
	await narrate("A framed transcript: DON'T LET HER IN. WHATEVER HAPPENS, DON'T OPEN THE DOOR — \"Received on 2.14 MHz at 2:14 AM, October 14, 1983.\"")
	await narrate("Beneath it, a photograph shows a fallen chair beside the control-room console.")
	await hud.choose(["Press the listening button"])
	# The preserved section: the same scrape, the same clicks, the same breath.
	for k in 2:
		Audio.sfx("scrape", -14.0)
		await wait(0.55)
		Audio.sfx("click", -12.0)
		await wait(0.28)
		Audio.sfx("click", -12.0, 0.78)
		await wait(0.45)
		Audio.sfx("breath", -14.0, 1.1)
		await wait(1.0)
		if k == 0:
			await narrate("A chair scrapes. Two relay clicks. The clipped breath. Mara presses it again. Same scrape, same clicks.")
	GameState.set_flag("transcript_seen")
	await mara("That chair. That sound.")
	await say("CAL", "(quietly) There was nobody left to tell us whose voice it was.")


func _desk() -> void:
	await narrate("Behind a rope: \"DR. HENRIK SOLLEN'S DESK, 1971. During the 1998 renovations, workers found the station's missing transmitter key inside its hollow left rear leg.\"")
	if not GameState.has("knows_key"):
		GameState.set_flag("knows_key")
		await mara("The key. In the leg of his desk. Fifteen years, and nobody looked.")
		await narrate("She reaches toward the desk. Cal gently catches the rope before she steps over it.")
		await say("CAL", "(quietly) You can look underneath. Just don't move anything. It gets everyone arguing.")
		await narrate("Mara kneels, and draws the foot cap in her notebook.")
		GameState.set_flag("drew_foot_cap")
		await _maybe_silence()
	else:
		await mara("The hollow left rear leg. It's in my notebook.")


func _study() -> void:
	var first := not GameState.has("anders_exhibit")
	await narrate("A photograph: \"THE 2.14 STUDY, 1974–79. Captain Anders Lind, U.S. Air Force, beside the feed horn.\"")
	await narrate("Beside it, a clipping: AIR FORCE ENGINEER KILLED ON OBSERVATORY ROAD.")
	await mara("Dad. It says he was driving home. Down the mountain.")
	await mara("In the photograph of the wreck his car points uphill.")
	if first:
		GameState.set_flag("anders_exhibit")
		await say("CAL", "(coming over) I noticed that too. The report says I was first on the scene. I wasn't.")
		await say("CAL", "The Air Force was already there. They took his briefcase.")
		await say("CAL", "Somebody asked me to sign the time under a sentence I hadn't written.")
		await mara("Did you?")
		await narrate("Cal looks at the old photograph of himself in uniform.")
		await say("CAL", "I was thirty-one. That's an explanation. It isn't much of one.")
		GameState.set_flag("cal_signed")
		await _maybe_silence()


func _plaque() -> void:
	await narrate("A small brass plaque by the control-room door: MARA LIND, NIGHT TECHNICIAN. FOUND HERE OCT 14, 1983.")
	if GameState.has("cal_plaque"):
		return
	GameState.set_flag("cal_plaque")
	await say("CAL", "I found her. By the console.")
	await say("CAL", "Ruth never believed it was her. Said her girl used red tape.")
	await narrate("Mara looks at her wrist. She pulls her cuff down.")
	await _maybe_silence()


## The lettering high on the wall, and the panel that goes with it: what
## the dish was listening for, from Einstein's constant to dark energy.
func _equation() -> void:
	var g := GameState
	await narrate("High on the wall, in brass letters a foot tall: Einstein's field equation, with his cosmological constant. Λ.")
	await hud.read_doc("WHAT WAS THE DISH LISTENING FOR?", [
		"1917. Albert Einstein adds Λ, the cosmological constant, to his equations of gravity while seeking a static model of the universe.\n\n1935. Einstein and Nathan Rosen describe a bridge connecting two regions of a mathematical spacetime. It is not a demonstrated passage for a traveller.",
		"1949. Kurt Gödel finds a rotating universe in Einstein's equations with paths that loop into their own past.\n\n1957. Hugh Everett proposes his relative-state formulation of quantum mechanics. Its later many-worlds reading makes parallel histories a familiar idea.",
		"1967–68. Yakov Zel'dovich connects quantum vacuum energy with the cosmological constant.\n\n1974–79. THE 2.14 STUDY. Its Air Force code name was LAMBDA.\n\n1988. Michael Morris, Kip Thorne and Ulvi Yurtsever examine whether a traversable wormhole, if one could be maintained, could become a time machine.",
		"1998. Two teams studying distant supernovae report evidence that the expansion of the universe is accelerating. The unknown cause becomes known as dark energy.\n\n2011. The discovery of accelerating expansion is recognised by the Nobel Prize in Physics.\n\n2025. DESI's first three years of observations cover nearly fifteen million galaxies and quasars. Combined with other observations, they strengthen hints that dark energy may change over time.\n\nNobody yet knows what it is.",
	])
	if g.has("museum_lambda"):
		return
	g.set_flag("museum_lambda")
	await mara("Λ. Like the A in Dad's initials.")
	await mara("LAMBDA. Empty space. That's what he thought he was listening to.")
	objective()


## What's still to see before 2:14 PM.
func _left() -> Array:
	return NEEDED.filter(func(f: String) -> bool: return not GameState.has(f))


## 2:14 PM, once Mara has what this future has to give: the sound goes out of
## it, and the white comes down the valley.
func _maybe_silence() -> void:
	if not _left().is_empty() or GameState.has("silence_2031"):
		objective()
		return
	GameState.set_flag("silence_2031")
	GameState.set_clock("2:14 PM", false)
	await wait(0.6)
	await say("CAL", "(whispering) There. Fourteen minutes past. Every day I get this feeling, round now, like somebody's about to—")
	Audio.stop_all(0.1)
	await wait(0.5)
	await narrate("The sound goes. Cal's mouth keeps moving.")
	player.face(-1)
	shot = "silence"
	var tw := create_tween()
	tw.tween_property(self, "white", 1.0, 2.4)
	await tw.finished
	await narrate("Behind the glass doors a white wall rolls down the valley.")
	await Act3.silence(self)


# --- drawing --------------------------------------------------------------------------

func draw_back() -> void:
	# Charcoal walls, a black ceiling with its track, polished concrete.
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 760), Color("23272b"), Color("34393e"))
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 140), Color("121416"))
	cv.draw_rect(Rect2(Kit.L, 34, Kit.R - Kit.L, 6), Color("2a2e32"))
	for i in 24:
		var x := Kit.L + 40 + i * 92.0
		cv.draw_rect(Rect2(x - 6, 40, 12, 14), Color("1a1c1e"))
		cv.draw_circle(Vector2(x, 58), 5.0, Color("fff4dc"))
	# A band of oak along the bottom of the wall.
	Kit.vgrad(cv, Rect2(Kit.L, 590, Kit.R - Kit.L, 60), Color("8a6440"), Color("6a4a30"))
	for i in 40:
		cv.draw_line(Vector2(Kit.L + i * 56.0, 590), Vector2(Kit.L + i * 56.0, 650), Color(0, 0, 0, 0.12), 1.0)
	Kit.vgrad(cv, Rect2(Kit.L, 650, Kit.R - Kit.L, 120), Color("8e9296"), Color("b6babe"))
	for i in 14:
		cv.draw_line(Vector2(Kit.L + i * 170.0, 650), Vector2(Kit.L + i * 170.0 - 90, 770), Color(0, 0, 0, 0.06), 2.0)
	_timeline()
	_wall_equation()
	_exit_doors()
	_shop()
	_recordings()
	_index()
	_transcript_panel()
	_desk_exhibit()
	_study_exhibit()
	_control_door()
	# Light from the track spots falling on the exhibits.
	for c in [Vector2(388, 250), Vector2(708, 250), Vector2(892, 470), Vector2(1070, 250)]:
		cv.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 14, 60), Vector2(c.x + 14, 60), Vector2(c.x + 120, c.y + 200),
			Vector2(c.x - 120, c.y + 200)]), Color(1.0, 0.95, 0.85, 0.035))


func _timeline() -> void:
	cv.draw_line(Vector2(252, 212), Vector2(1140, 212), Color("c8a46a"), 2.0)
	var marks := [[262.0, "1971  THE DISH"], [430.0, "1974–79  THE 2.14 STUDY"], [660.0, "1983  THE TRANSMISSION"],
		[870.0, "1997  DECOMMISSIONED"], [1040.0, "2004  OPEN TO ALL"]]
	for m in marks:
		cv.draw_circle(Vector2(m[0], 212), 4.0, Color("c8a46a"))
		Kit.text(cv, Vector2(m[0] - 6, 200), m[1], 11, Color("d8d2c4"))


## High on the charcoal wall, in brushed-brass letters: Einstein's field
## equation with his constant, and what the museum says Λ is.
func _wall_equation() -> void:
	var size := 36
	var w := 0.0
	for s in ["G", " + Λg", " = 8πG T"]:
		w += Kit.text_width(s, size)
	w += 3.0 * Kit.text_width("μν", int(size * 0.55))
	var x := 760.0 - w * 0.5
	Kit.field_equation(cv, Vector2(x + 1, 163), size, Color(0, 0, 0, 0.35))
	Kit.field_equation(cv, Vector2(x, 162), size, Color("d8b47a"))
	Kit.text(cv, Vector2(460, 186), "EINSTEIN, 1917  ·  Λ: THE ENERGY OF EMPTY SPACE", 10, Color("a8a49a"), HORIZONTAL_ALIGNMENT_CENTER, 600)


func _exit_doors() -> void:
	var r := Rect2(22, 340, 92, 310)
	var e := env()
	var sk: Array = e.sky()
	Kit.vgrad(cv, Rect2(r.position, Vector2(r.size.x, 150)), sk[0], sk[1])
	Kit.vgrad(cv, Rect2(r.position.x, r.position.y + 150, r.size.x, r.size.y - 150), Color("7d8440"), Color("8e8c84"))
	cv.draw_rect(Rect2(r.position.x, r.position.y + 120, r.size.x, 34), Color("8a8aa0"))
	cv.draw_line(r.position + Vector2(10, r.size.y), r.position + Vector2(50, 0), Color(1, 1, 1, 0.2), 14.0)
	cv.draw_rect(r.grow(6), Color("3a3e44"), false, 10.0)
	cv.draw_line(Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), Color("3a3e44"), 4.0)
	cv.draw_rect(Rect2(40, 300, 56, 22), Color("1e7a3e"))
	Kit.text(cv, Vector2(40, 316), "EXIT", 13, Color("e8f4ea"), HORIZONTAL_ALIGNMENT_CENTER, 56)
	# The clock over the door: big plain digits.
	cv.draw_rect(Rect2(28, 232, 80, 40), Color("0e1012"))
	var clock := "2:14 PM" if GameState.has("silence_2031") else "2:13 PM"
	Kit.text(cv, Vector2(28, 259), clock, 17, Color("f2c27a"), HORIZONTAL_ALIGNMENT_CENTER, 80)


func _shop() -> void:
	# A screen over the rack: NO SIGNAL.
	cv.draw_rect(Rect2(140, 292, 92, 54), Color("0c0e10"))
	cv.draw_rect(Rect2(144, 296, 84, 46), Color("1d3a6a"))
	Kit.text(cv, Vector2(144, 324), "NO SIGNAL", 11, Color("dfe8f4"), HORIZONTAL_ALIGNMENT_CENTER, 84)
	cv.draw_rect(Rect2(136, 370, 100, 214), Color("e8e6e0"))
	for row in 4:
		var y := 384.0 + row * 50.0
		cv.draw_rect(Rect2(136, y + 36, 100, 5), Color("c8c4bc"))
		for k in 3:
			var col: Color = [Color("c4502e"), Color("2f5878"), Color("e0b440"), Color("4e7a6a")][(row + k) % 4]
			var b := Rect2(144 + k * 30, y + 12, 24, 24)
			cv.draw_rect(b, col)
			cv.draw_circle(b.position + Vector2(17, 15), 4.0, col.darkened(0.4))
			cv.draw_rect(Rect2(b.position + Vector2(3, 4), Vector2(10, 4)), Color("f2efe6"))
	Kit.text(cv, Vector2(136, 364), "SHOP", 11, Color("d8d2c4"), HORIZONTAL_ALIGNMENT_CENTER, 100)


func _recordings() -> void:
	var r := Rect2(258, 252, 260, 188)
	cv.draw_rect(r.grow(6), Color("15171a"))
	Kit.vgrad(cv, r, Color("3e3428"), Color("2a241e"))
	for row in 5:
		var y := r.position.y + 10 + row * 36.0
		cv.draw_rect(Rect2(r.position.x, y + 30, r.size.x, 4), Color("5a4a38"))
		var x := r.position.x + 6
		var k := 0
		while x < r.end.x - 20:
			var kind := int(Townscape.h(row * 31 + k) * 4.0)
			match kind:
				0, 1:  # cassettes on their spines
					var c := Color("e8e2d0") if Townscape.h(k + row) > 0.4 else Color("c8603a")
					cv.draw_rect(Rect2(x, y + 8, 7, 22), Color("1a1a1c"))
					cv.draw_rect(Rect2(x + 1, y + 11, 5, 14), c)
					x += 9.0
				2:  # an answering machine
					cv.draw_rect(Rect2(x, y + 14, 34, 16), Color("2c2c30"))
					cv.draw_rect(Rect2(x + 4, y + 17, 14, 9), Color("4a4a50"))
					cv.draw_circle(Vector2(x + 27, y + 21), 2.0, Color("6a1e1a"))
					x += 38.0
				_:  # a reel box
					cv.draw_rect(Rect2(x, y + 4, 24, 26), Color("6a5a40"))
					cv.draw_circle(Vector2(x + 12, y + 17), 7.0, Color("3a3024"))
					x += 28.0
			k += 1
	cv.draw_rect(r, Color(0.8, 0.88, 0.95, 0.06))
	cv.draw_line(r.position + Vector2(30, 0), r.position + Vector2(90, r.size.y), Color(1, 1, 1, 0.08), 16.0)
	Kit.text(cv, Vector2(r.position.x, 240), "THE RECORDINGS", 14, Color("f2efe6"))


func _index() -> void:
	var r := Rect2(396, 500, 104, 118)
	cv.draw_rect(r, Color("7a5434"))
	for row in 5:
		for c in 4:
			var d := Rect2(r.position.x + 6 + c * 24, r.position.y + 6 + row * 22, 20, 18)
			cv.draw_rect(d, Color("8e6440"))
			cv.draw_rect(d, Color("5a3a22"), false, 1.0)
			cv.draw_rect(Rect2(d.position + Vector2(6, 6), Vector2(8, 4)), Color("c8a46a"))
	cv.draw_line(Vector2(r.position.x + 8, r.end.y), Vector2(r.position.x + 8, 650), Color("4a3220"), 5.0)
	cv.draw_line(Vector2(r.end.x - 8, r.end.y), Vector2(r.end.x - 8, 650), Color("4a3220"), 5.0)
	# A listening post: headphones on a hook.
	cv.draw_line(Vector2(380, 470), Vector2(380, 520), Color("2a2c30"), 3.0)
	cv.draw_arc(Vector2(380, 530), 9.0, PI, TAU, 10, Color("1a1c1e"), 3.0)
	cv.draw_circle(Vector2(371, 534), 4.0, Color("1a1c1e"))
	cv.draw_circle(Vector2(389, 534), 4.0, Color("1a1c1e"))


func _transcript_panel() -> void:
	var r := Rect2(630, 250, 158, 224)
	cv.draw_rect(r, Color("0e1012"))
	cv.draw_rect(r, Color("3a3e44"), false, 2.0)
	var w := Color("eceae2")
	Kit.text(cv, Vector2(642, 290), "DON'T LET", 19, w)
	Kit.text(cv, Vector2(642, 314), "HER IN.", 19, w)
	Kit.text(cv, Vector2(642, 346), "WHATEVER", 14, w)
	Kit.text(cv, Vector2(642, 364), "HAPPENS, DON'T", 14, w)
	Kit.text(cv, Vector2(642, 382), "OPEN THE DOOR—", 14, w)
	cv.draw_line(Vector2(642, 404), Vector2(776, 404), Color("c8a46a"), 1.0)
	Kit.text(cv, Vector2(642, 422), "2.14 MHz · 2:14 AM", 10, Color("a8a49a"))
	Kit.text(cv, Vector2(642, 436), "OCTOBER 14, 1983", 10, Color("a8a49a"))
	# A small photograph under it: the fallen chair beside the console. And the listening button.
	var ph := Rect2(642, 446, 52, 22)
	cv.draw_rect(ph, Color("c8c2b4"))
	cv.draw_rect(Rect2(ph.position + Vector2(3, 3), ph.size - Vector2(6, 6)), Color("4a4842"))
	cv.draw_rect(Rect2(ph.position.x + 24, ph.position.y + 6, 22, 9), Color("2a2a28"))
	cv.draw_line(ph.position + Vector2(8, 16), ph.position + Vector2(20, 12), Color("8a867c"), 2.0)
	cv.draw_line(ph.position + Vector2(10, 12), ph.position + Vector2(14, 17), Color("8a867c"), 1.5)
	cv.draw_circle(Vector2(760, 457), 8.0, Color("8a2a24"))
	cv.draw_circle(Vector2(760, 457), 8.0, Color("c8a46a"), false, 1.5)
	Kit.text(cv, Vector2(700, 470), "LISTEN", 7, Color("8a867c"))


func _desk_exhibit() -> void:
	# Sollen's desk, as it was: oak, a green lamp, the logbook, his pipe.
	var top := 566.0
	cv.draw_rect(Rect2(812, top, 164, 12), Color("7a5434"))
	cv.draw_rect(Rect2(818, top + 12, 52, 650 - top - 12), Color("6a4628"))
	cv.draw_rect(Rect2(918, top + 12, 52, 650 - top - 12), Color("6a4628"))
	for k in 2:
		cv.draw_rect(Rect2(924, top + 18 + k * 32, 40, 26), Color("5a3a20"), false, 1.5)
		cv.draw_rect(Rect2(940, top + 28 + k * 32, 8, 3), Color("c8a46a"))
	cv.draw_rect(Rect2(830, top - 8, 52, 8), Color("2a3a4a"))
	cv.draw_line(Vector2(950, top), Vector2(950, top - 34), Color("2a2a2a"), 2.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(934, top - 34), Vector2(966, top - 34), Vector2(960, top - 46), Vector2(940, top - 46)]), Color("2e5a3a"))
	cv.draw_line(Vector2(894, top - 3), Vector2(912, top - 6), Color("3a2418"), 3.0)
	# The rope, on brass stanchions.
	for x in [796.0, 992.0]:
		cv.draw_rect(Rect2(x - 3, 590, 6, 60), Color("c8a46a"))
		cv.draw_circle(Vector2(x, 588), 6.0, Color("d8b47a"))
	var rope := PackedVector2Array()
	for i in 17:
		var u := i / 16.0
		rope.append(Vector2(lerpf(796, 992, u), 592.0 + sin(u * PI) * 16.0))
	cv.draw_polyline(rope, Color("8a2a2a"), 4.0, true)
	# Its placard on a little stand.
	cv.draw_line(Vector2(1000, 650), Vector2(1000, 600), Color("2a2c30"), 3.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(984, 574), Vector2(1016, 574), Vector2(1014, 600), Vector2(986, 600)]), Color("eceae2"))
	for k in 3:
		cv.draw_line(Vector2(989, 580 + k * 6), Vector2(1011, 580 + k * 6), Color("6a665c"), 1.0)


func _study_exhibit() -> void:
	Kit.text(cv, Vector2(1000, 240), "THE 2.14 STUDY", 13, Color("f2efe6"))
	# A sepia photograph: a man in Air Force blues and a peaked cap beside the feed horn.
	var p := Rect2(1004, 254, 96, 120)
	cv.draw_rect(p.grow(5), Color("1a1c1e"))
	Kit.vgrad(cv, p, Color("d8c8a4"), Color("a89870"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1060, 370), Vector2(1096, 300), Vector2(1100, 304), Vector2(1074, 372)]), Color("6a5a40"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1078, 300), Vector2(1100, 286), Vector2(1100, 330), Vector2(1078, 318)]), Color("5a4a34"))
	var man := Color("3a3428")
	cv.draw_circle(Vector2(1036, 300), 9.0, man)
	cv.draw_rect(Rect2(1025, 288, 22, 5), man.darkened(0.3))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1022, 312), Vector2(1050, 312), Vector2(1054, 372), Vector2(1018, 372)]), man)
	cv.draw_line(Vector2(1030, 318), Vector2(1030, 340), Color("c8b888"), 1.0)
	# The clipping, and a small photo of the wreck: the car points uphill.
	cv.draw_rect(Rect2(1010, 392, 120, 56), Color("e6e0cc"))
	Kit.text(cv, Vector2(1014, 404), "AIR FORCE ENGINEER", 8, Color("2a2a2a"))
	Kit.text(cv, Vector2(1014, 414), "KILLED ON", 8, Color("2a2a2a"))
	Kit.text(cv, Vector2(1014, 424), "OBSERVATORY ROAD", 8, Color("2a2a2a"))
	for k in 3:
		cv.draw_line(Vector2(1014, 431 + k * 5), Vector2(1080, 431 + k * 5), Color("8a867c"), 1.0)
	var w := Rect2(1088, 400, 38, 30)
	cv.draw_rect(w, Color("4a4a48"))
	cv.draw_line(Vector2(1088, 426), Vector2(1126, 412), Color("8a8a88"), 2.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1096, 422), Vector2(1116, 414), Vector2(1118, 408), Vector2(1104, 412), Vector2(1096, 418)]), Color("1a1a1a"))
	Kit.text(cv, Vector2(1004, 470), "Capt. Anders Lind, USAF, 1977", 8, Color("a8a49a"))


func _control_door() -> void:
	var r := Rect2(1184, 340, 80, 310)
	Kit.door(cv, r, Color("3d474b"), "CONTROL")
	cv.draw_line(Vector2(1176, 470), Vector2(1272, 470), Color("8a2a2a"), 4.0)
	cv.draw_rect(Rect2(1190, 500, 66, 24), Color("eceae2"))
	Kit.text(cv, Vector2(1190, 510), "CLOSED FOR", 7, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, 66)
	Kit.text(cv, Vector2(1190, 520), "CONSERVATION", 7, Color("2a2a2a"), HORIZONTAL_ALIGNMENT_CENTER, 66)
	# The brass plaque.
	var b := Rect2(1146, 386, 22, 32)
	cv.draw_rect(b, Color("c8a050"))
	cv.draw_rect(b, Color("8a6a30"), false, 1.0)
	for k in 4:
		cv.draw_line(Vector2(1153, 393 + k * 6), Vector2(1169, 393 + k * 6), Color("7a5a28"), 1.0)


func draw_glow(ci: CanvasItem) -> void:
	if white <= 0.0:
		return
	# The white, filling the glass doors from the top down.
	var r := Rect2(22, 340, 92, 310)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * white)), Color(0.96, 0.97, 1.0, 0.95))
	Kit.soft_glow(ci, Vector2(68, 420), 160.0 * white, Color(1, 1, 1, 0.5 * white))
