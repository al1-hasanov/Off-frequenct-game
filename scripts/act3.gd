class_name Act3
extends RefCounted
## Act 3: the futures.
##
## With Dad's 2.14 chain patched in, the Tuner reads years. The dish hears one
## future at a time, the loudest first, and Mara walks into it through the feed
## cabin at the dish's focal point: the darkest place on the mountain. A trip
## is required travel, so it counts as a crossing and never as FRACTURE. She
## comes back when the Silence reaches that future: the sound goes, the white
## comes down, and she wakes on the cabin floor at 2:14, 1983. Nothing comes
## back from a future: it hasn't happened yet.
##
## Every future she acts on changes. When she has seen one and done what it
## told her, the next year turns up on the control room's chalkboard, in her
## own handwriting, while she's out of the room.

const YEARS := {
	"2031": {"sub": "October 14  ·  an afternoon", "clock": "2:06 PM", "room": "dish"},
	"2009": {"sub": "October 14  ·  a little before two in the morning", "clock": "1:49", "room": "dish"},
	"1991": {"sub": "October 14  ·  half past one in the morning", "clock": "1:31", "room": "shop_1991"},
}


## The future the needle has settled on, or "" if none: the dish only hears
## the next one once the last has been seen and answered.
static func next_future() -> String:
	var g := GameState
	if not g.has("patched"):
		return ""
	if not g.has("been_2031"):
		return "2031"
	if g.has("board_2009") and not g.has("been_2009"):
		return "2009"
	if g.has("call_1991") and not g.has("been_1991"):
		return "1991"
	return ""


## Into a future through the feed cabin. Call last, like change_room().
static func go(room: Room, year: String) -> void:
	var y: Dictionary = YEARS[year]
	Audio.stop_all(1.2)
	Audio.sfx("crossing", -2.0)
	room.hud.glitch(1.6)
	await room.wait(0.6)
	await room.hud.fade_out(0.9)
	Audio.play_loop("static", -18.0, 0.4)
	await room.wait(0.5)
	await room.hud.card(year, str(y.sub), 2.0, true)
	Audio.stop_loop("static", 0.6)
	GameState.travel(year)
	GameState.set_flag("been_" + year)
	GameState.set_clock(str(y.clock), false)
	room.main.change_room(str(y.room), "arrive")


## The Silence reaches the future Mara is in: the sound goes out of it, a
## white wall of static comes down the valley, and she wakes in the feed cabin
## at 2:14 AM, 1983. Call last.
static func silence(room: Room, to: String = "dish", entry: String = "wake") -> void:
	Audio.stop_all(0.25)
	Audio.sfx("silence_hit", -3.0)
	await room.wait(1.4)
	Audio.play_loop("static", -9.0, 2.0)
	await room.hud.whiteout(2.4)
	await room.wait(0.8)
	Audio.stop_loop("static", 1.2)
	GameState.travel("")
	GameState.set_clock("2:14", true)
	room.main.change_room(to, entry)


## What the control room's chalkboard says in the corner Sollen keeps empty
## for discoveries. Mara writes the first line; the rest turn up by themselves.
static func board_lines() -> Array:
	var g := GameState
	var out: Array = []
	if g.has("chalk_2031"):
		out.append("SILENCE: 2031")
	if g.has("board_2009"):
		out.append("2009")
	if g.has("board_1991"):
		out.append("1991")
	if g.has("board_tonight"):
		out.append("TONIGHT")
	return out


## Act 3.7: the player is the Mara who was swept into the dark at Ash Street.
## She has nothing of Blue's: Blue's pockets are put aside until she's back.
static func become_red() -> void:
	var g := GameState
	if g.has("playing_red"):
		return
	g.stash.assign(g.inventory)
	g.inventory.clear()
	g.selected_item = ""
	g.set_flag("playing_red")
	g.inventory_changed.emit()


static func become_blue() -> void:
	var g := GameState
	if not g.has("playing_red"):
		return
	g.inventory.assign(g.stash)
	g.stash.clear()
	g.set_flag("playing_red", false)
	g.inventory_changed.emit()


## Which Tomas the dish found in 1991: H's (he was taken, he's 21 and runs the
## shop with June) or 12's (he was sent home, he's 24 and Lise is expecting).
static func tomas_1991() -> String:
	return "tomas_21" if GameState.story.get("TOMAS") == "taken" else "tomas_24"


## The close-up of a Mara's left wrist (3.6 and 3.7): the jacket sleeve, the
## wrist, three neat turns of tape, the hand. `a` fades it in and out.
static func draw_wrist(ci: CanvasItem, tape: Color, a: float) -> void:
	if a <= 0.0:
		return
	ci.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color(0.02, 0.02, 0.03, 0.94 * a))
	var skin := Color(0.88, 0.69, 0.56, a)
	var shade := Color(0.66, 0.48, 0.38, a)
	# The jacket sleeve, from the left, and its cuff.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-100, 290), Vector2(420, 312), Vector2(446, 476), Vector2(-100, 510)]), Color(0.29, 0.33, 0.24, a))
	ci.draw_line(Vector2(420, 312), Vector2(446, 476), Color(0.18, 0.21, 0.15, a), 8.0)
	for k in 5:
		ci.draw_line(Vector2(80 + k * 70, 300 + k * 3), Vector2(110 + k * 70, 500 - k * 4), Color(0.22, 0.25, 0.18, 0.5 * a), 2.0)
	# The forearm and wrist.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(430, 332), Vector2(760, 350), Vector2(772, 446), Vector2(436, 458)]), skin)
	ci.draw_line(Vector2(440, 452), Vector2(764, 442), shade, 4.0)
	# The hand: the back of it, the thumb along the top, four fingers curled under.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(758, 344), Vector2(884, 334), Vector2(938, 352), Vector2(952, 420),
		Vector2(906, 462), Vector2(770, 452)]), skin)
	for k in 4:
		var p0 := Vector2(928, 360 + k * 24)
		var p1 := Vector2(986 + 6.0 * (1.5 - absf(k - 1.5)), 374 + k * 22)
		var fc := Color(skin.r - 0.025 * k, skin.g - 0.025 * k, skin.b - 0.025 * k, a)
		ci.draw_line(p0, p1, fc, 20.0)
		ci.draw_circle(p0, 10.0, fc)
		ci.draw_circle(p1, 10.0, fc)
		ci.draw_arc(p1, 10.0, -0.6, 0.9, 6, shade, 2.0)
	ci.draw_line(Vector2(804, 344), Vector2(884, 316), skin, 18.0)
	ci.draw_circle(Vector2(884, 316), 9.0, skin)
	for k in 3:
		ci.draw_arc(Vector2(918, 366 + k * 26), 8.0, -1.2, 1.2, 6, Color(shade, 0.5 * a), 2.0)
	# The tape: three turns, wound neat, the end pressed flat.
	var tp := Color(tape, a)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(636, 342), Vector2(714, 347), Vector2(722, 452), Vector2(640, 454)]), tp)
	for k in 3:
		var x := 650.0 + k * 24.0
		ci.draw_line(Vector2(x, 344), Vector2(x + 5, 453), Color(tape.darkened(0.35), a), 2.0)
	ci.draw_line(Vector2(642, 352), Vector2(714, 357), Color(1, 1, 1, 0.38 * a), 3.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(700, 400), Vector2(726, 404), Vector2(724, 420), Vector2(702, 418)]), Color(tape.lightened(0.12), a))
