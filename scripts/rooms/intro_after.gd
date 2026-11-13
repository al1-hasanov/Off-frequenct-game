extends "res://scripts/rooms/intro_diner.gd"
## The opening, part 4: afterwards. A short film, from the police car's
## headlights in the clearing that night to October 14, 1983, when Ruth puts a
## new poster in the diner window and Mara goes in to work.
##
## Mara keeps looking because she feels responsible; Ruth keeps their home
## ready because she can't accept he won't come back. They still look after
## each other, even when they can't make each other feel better.
##
## Lines are tapped through like any dialogue; what's only seen or heard comes
## up as a caption. Skip (bottom right) goes straight to 1983.
## It extends the opening's diner so its diner scenes are the same room.

const PRINTS_FROM := 286.0
const PRINTS_END := 530.0
const FLASH := Vector2(552, 652)
const BLANKET := Color("6a6458")
const DINER_SHOTS := ["diner_night", "diner_day", "phone"]

var shot := ""
var _st := 0.0
var cal: Actor
var searcher: Actor
var neighbour: Actor
var mara80: Actor
var outdoor_snow: Snowfall
## Moving things, by shot.
var car_x := 0.0
var car_target := 0.0
var sedan_x := 0.0
var sedan_target := 0.0
var road_scroll := 0.0
var road_speed := 0.0
var photo_out := 0.0
var sheets := 0
var tape_strips := 0
var soup := false
var cards := 3
var card_out := false
var bag_out := false
var letters := 0
var poster_swap := 0.0
var _sheet_t := 0.0


func setup() -> void:
	shows_hud = false
	is_story_room = false
	animated_back = true
	place_name = ""
	base_tint = Color(0.9, 0.92, 1.0)
	table_cleared = true
	add_window_snow()
	outdoor_snow = Snowfall.new()
	outdoor_snow.area = Rect2(Kit.L, -30, Kit.R - Kit.L, 790)
	outdoor_snow.count = 200
	outdoor_snow.wind = 36.0
	add_child(outdoor_snow)
	ruth = add_actor("ruth_1980", -300.0, 1)
	cal = add_actor("cal_1980", -300.0, 1)
	searcher = add_actor("searcher_a", -300.0, 1)
	neighbour = add_actor("searcher_b", -300.0, -1)
	add_layer(1, _draw_counter)
	mara80 = make_player(-300.0, 1, "mara_1980")
	mara80.z_index = 2
	for a in [ruth, cal, searcher, neighbour, mara80]:
		a.visible = false
		a.step_sound = "step_snow"


func enter(_entry: String) -> void:
	pass


func score_quiet() -> bool:
	return false


func ambience() -> void:
	pass


func on_arrive() -> void:
	hud.show_skip(true)
	for step in [_clearing, _ruth_arrives, _search, _interview, _morning, _days, _weeks_later, _spring, _crate, _poster_1983]:
		if hud.skip_requested:
			break
		await step.call()
	hud.show_skip(false)
	await hud.fade_out(0.6)
	Audio.stop_all(0.6)
	# The night shift in 1983 starts here: set before the corridor saves.
	GameState.set_flag("intro_seen")
	GameState.set_clock("1:40")
	GameState.set_flag("radio_on")
	GameState.set_objective("Read Sollen's note on the control-room door.")
	main.change_room("corridor", "intro")


# --- helpers: each returns at once once the player has pressed Skip -----------------------

func _skip() -> bool:
	return hud.skip_requested


func _line(speaker: String, text: String) -> void:
	if not _skip():
		await say(speaker, text)


func _note(text: String) -> void:
	if not _skip():
		await narrate(text)


func _cap(text: String, hold: float) -> void:
	if _skip():
		return
	hud.caption(text, hold)
	await _hold(hold + 1.0)


func _hold(sec: float) -> void:
	var left := sec
	while left > 0.0 and not _skip():
		await get_tree().process_frame
		left -= get_process_delta_time()


func _walk(a: Actor, x: float) -> void:
	if _skip():
		a.position.x = x
		return
	await a.walk_to(x)


## A hard cut to another shot: everyone off stage first.
func _cut(s: String) -> void:
	shot = s
	_st = 0.0
	for a in [ruth, cal, searcher, neighbour, mara80]:
		a.visible = false
		a.seated = false
		a.prop = ""
		a.arm_pose = []
		a.blanket = Color(0, 0, 0, 0)
		a.head_tilt = 0.0
		a.sob = false
		a.headphones_mode = ""
		a.holding_light = false
		a.z_index = 0
		a.scale = Vector2.ONE
		a.position.y = floor_y
	mara80.z_index = 2
	outdoor_snow.visible = s in ["clearing", "search", "post", "drive_back"]
	window_snow.visible = s in DINER_SHOTS
	window_day = s in ["diner_day", "phone"]
	window_spring = s == "diner_day"
	base_tint = Color(0.62, 0.6, 0.66) if s == "diner_night" else Color(0.9, 0.92, 1.0)
	# Only the shots with something moving in the scenery redraw it every frame.
	animated_back = s in ["clearing", "drive_out", "drive_back", "black", ""]
	if s == "diner_day":
		# Spring through the front window: no more snow.
		window_snow.visible = false


func static_key() -> String:
	return "%s|%d|%d|%s|%d|%s|%s|%d|%d" % [shot, letters, tape_strips, soup, cards, card_out, bag_out, int(car_x), int(sedan_x)]


func _fade_cut(s: String, dur: float = 0.5) -> void:
	if _skip():
		return
	await hud.fade_out(dur)
	_cut(s)
	await hud.fade_in(dur)


func _show(a: Actor, x: float, facing: int) -> void:
	a.position.x = x
	a.face(facing)
	a.visible = true


# --- the film ----------------------------------------------------------------------------

## That night. A police car's headlights across the field; Mara standing where
## the footprints stop, snow on her shoulders; Cal with a blanket.
func _clearing() -> void:
	_cut("clearing")
	car_x = -760.0
	car_target = 70.0
	sedan_x = -1400.0
	sedan_target = -1400.0
	_show(mara80, PRINTS_END + 30.0, 1)
	Audio.play_loop("wind", -14.0, 0.5)
	Audio.play_loop("truck_idle", -24.0, 0.5)
	Audio.set_loop_pitch("truck_idle", 0.9, 0.0)
	await hud.fade_in(1.2)
	await _hold(3.4)
	Audio.sfx("door", -10.0)
	_show(cal, car_x + 150.0, 1)
	cal.prop = "coat"
	cal.prop_col = BLANKET
	await _hold(0.4)
	await _walk(cal, mara80.position.x - 64.0)
	await _line("CAL", "Mara. We need you by the truck.")
	await _line("MARA", "You'll step on them.")
	await _line("CAL", "We've photographed them.")
	await _line("MARA", "They stop here.")
	cal.head_tilt = 0.35
	await _note("Cal looks down.")
	await _line("MARA", "They stop here, Cal.")
	cal.head_tilt = 0.0
	cal.prop = "none"
	mara80.blanket = BLANKET
	await _note("He puts the blanket around her.")


## Ruth's car; she's out before it's stopped.
func _ruth_arrives() -> void:
	if _skip():
		return
	sedan_x = -1100.0
	sedan_target = -330.0
	await _hold(1.6)
	Audio.sfx("door", -9.0)
	_show(ruth, sedan_x + 160.0, 1)
	ruth.speed = 380.0
	cal.walk_to(mara80.position.x - 250.0)
	await _walk(ruth, mara80.position.x - 96.0)
	cal.face(1)
	await _line("RUTH", "Where is he?")
	await _note("Mara tries to answer. Nothing comes.")
	await _line("RUTH", "Mara. Where did you last see him?")
	mara80.arm_pose = [[1.62, 0.05], [0.12, 0.1]]
	await _note("Mara points.")
	ruth.face(1)
	await _hold(0.6)
	await _line("RUTH", "TOMAS!")
	mara80.arm_pose = []
	await _cap("Her voice carries across the clearing.", 2.4)
	mara80.head_tilt = 0.32
	mara80.sob = true
	await _cap("For the first time, Mara begins to cry.", 3.0)


## Through the night: flashlights in the trees, a dog, a map on a car bonnet,
## Ruth with coffee from the diner and the same question for everyone.
func _search() -> void:
	await _fade_cut("search", 0.8)
	sedan_x = 980.0
	sedan_target = 980.0
	_show(neighbour, 900.0, 1)
	neighbour.arm_pose = [[0.9, 0.5], [0.8, 0.6]]
	_show(ruth, 620.0, 1)
	ruth.prop = "thermos"
	ruth.speed = 120.0
	_show(searcher, 120.0, 1)
	searcher.holding_light = true
	searcher.speed = 90.0
	searcher.walk_to(420.0)
	Audio.play_loop("wind", -16.0, 0.5)
	Audio.stop_loop("truck_idle", 0.5)
	await _cap("The search goes on through the night.", 2.6)
	Audio.sfx("bark", -14.0)
	await _cap("Flashlights between the trees. A search dog, pulling through the snow.", 3.0)
	Audio.sfx("bark", -16.0)
	await _cap("Neighbours at a map spread on a car bonnet. Ruth hands out coffee from the diner.", 3.4)
	ruth.face(-1)
	await _cap("She asks every group that comes back the same question.", 3.0)
	searcher.head_tilt = 0.28
	await _cap("Each time, someone shakes their head.", 2.8)


## Inside the observatory, Cal's questions.
func _interview() -> void:
	await _fade_cut("interview", 0.8)
	Audio.stop_loop("wind", 0.6)
	Audio.play_loop("hum", -28.0, 0.6)
	_show(mara80, 452.0, 1)
	mara80.seated = true
	mara80.blanket = BLANKET
	mara80.prop = "key"
	_show(cal, 836.0, -1)
	cal.seated = true
	await _hold(0.8)
	await _line("CAL", "Did he mention meeting anyone?")
	await _line("MARA", "No.")
	await _line("CAL", "Anyone who'd spoken to him recently? Someone on the radio?")
	await _line("MARA", "He said it knew his name.")
	cal.prop = "notebook"
	Audio.sfx("scratch", -22.0)
	await _note("Cal writes that down.")
	await _line("MARA", "You think somebody took him.")
	await _line("CAL", "I'm trying to find out what happened.")
	await _line("MARA", "I was right there.")
	await _hold(1.2)
	await _line("CAL", "While you were locking the gate—how long couldn't you see him?")
	mara80.head_tilt = 0.3
	await _note("Mara stares at the key in her hand.")
	await _line("MARA", "Long enough to turn this.")


## Morning: tracks everywhere, and she can't find the place.
func _morning() -> void:
	await _fade_cut("morning", 1.0)
	Audio.stop_loop("hum", 0.6)
	Audio.play_loop("wind", -22.0, 1.0)
	car_x = 70.0
	_show(mara80, PRINTS_END + 30.0, 1)
	mara80.head_tilt = 0.42
	_show(searcher, 1060.0, -1)
	searcher.scale = Vector2(0.5, 0.5)
	searcher.position.y = 492.0
	_show(neighbour, 1120.0, -1)
	neighbour.scale = Vector2(0.48, 0.48)
	neighbour.position.y = 490.0
	await _cap("Morning. The clearing is full of tracks now: searchers, dogs, vehicles.", 3.4)
	await _cap("Mara looks for the place where Tomas's footprints ended.", 2.8)
	mara80.position.x -= 40.0
	await _cap("She can no longer find it.", 2.8)


## Ruth just inside the Lantern's window, close to us, reaching up to the
## poster's corners.
func _ruth_at_window() -> void:
	_show(ruth, 604.0, 1)
	ruth.scale = Vector2(1.5, 1.5)
	ruth.position.y = 668.0
	ruth.arm_pose = [[2.62, 0.22], [2.72, 0.2]]


## Days, in short cuts.
func _days() -> void:
	await _fade_cut("frame", 0.8)
	Audio.stop_loop("wind", 0.4)
	photo_out = 0.0
	await _cap("Days pass.", 1.6)
	var tw := create_tween()
	tw.tween_property(self, "photo_out", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	await _cap("A photograph comes out of its frame.", 1.6)
	_cut("printer")
	sheets = 0
	_sheet_t = 0.0
	await _cap("MISSING. TOMAS LIND. AGE 13.", 2.8)
	_cut("window")
	_ruth_at_window()
	await _cap("Ruth tapes one inside the diner window. She smooths the corners down, carefully.", 3.6)
	_cut("post")
	tape_strips = 0
	_show(mara80, 566.0, 1)
	mara80.scale = Vector2(1.32, 1.32)
	mara80.position.y = 760.0
	mara80.arm_pose = [[2.25, 0.3], [2.0, 0.45]]
	Audio.play_loop("wind", -16.0, 0.3)
	await _cap("Mara pins another by the service road. The wind tears it loose.", 2.6)
	for k in 3:
		if _skip():
			break
		tape_strips = k + 1
		Audio.sfx("tape_rip", -10.0)
		await _hold(0.7)
	await _cap("She tapes it down with red electrical tape.", 2.2)
	Audio.stop_loop("wind", 0.3)
	_cut("phone")
	_show(ruth, 780.0, -1)
	if not _skip():
		Audio.sfx("ring", -6.0)
	await _hold(0.5)
	ruth.speed = 420.0
	await _walk(ruth, PHONE.x + 44.0)
	ruth.face(-1)
	ruth.prop = "phone"
	await _cap("A telephone rings. Ruth answers before it can ring again.", 2.8)
	_cut("drive_out")
	road_scroll = 0.0
	road_speed = 520.0
	Audio.play_loop("truck_idle", -18.0, 0.2)
	Audio.set_loop_pitch("truck_idle", 1.4, 0.0)
	await _cap("Mara drives out to a reported sighting.", 2.2)
	_cut("drive_back")
	road_speed = -150.0
	Audio.set_loop_pitch("truck_idle", 1.05, 0.0)
	await _cap("She comes back alone.", 2.4)
	Audio.stop_loop("truck_idle", 0.3)
	_cut("black")
	await _hold(0.6)
	if not _skip():
		Audio.sfx("ring", -9.0)
	await _cap("Another telephone rings.", 1.8)


## Weeks later, the diner after closing: the map, the soup.
func _weeks_later() -> void:
	await _fade_cut("diner_night", 0.9)
	Audio.play_loop("hum", -34.0, 0.6)
	soup = false
	_show(mara80, 700.0, 1)
	mara80.seated = true
	mara80.seat_y = 62.0
	mara80.arm_pose = [[1.15, 0.9], [1.05, 0.95]]
	mara80.head_tilt = 0.25
	_show(ruth, 852.0, -1)
	await _cap("Weeks later. The diner, after closing.", 2.6)
	await _line("MARA", "There's an old culvert below Hollis Road.")
	await _line("RUTH", "Cal checked it.")
	await _line("MARA", "I haven't.")
	soup = true
	Audio.sfx("click", -14.0, 0.7)
	await _note("Ruth puts a bowl of soup down beside the map.")
	await _line("MARA", "I'm not hungry.")
	await _line("RUTH", "You don't have to be hungry.")
	await _note("Mara keeps looking at the map.")
	await _line("MARA", "They're taking the posters down in town.")
	await _note("Ruth stands very still.")
	await _line("RUTH", "I have more.")
	await _hold(2.2)
	await _line("MARA", "If I'd made him get in the truck—")
	await _line("RUTH", "I've done that sentence too.")
	mara80.head_tilt = -0.04
	await _note("Mara finally looks up.")
	await _line("RUTH", "If I'd taken him home. If I hadn't been working. If I'd said no.")
	if not _skip():
		await hud.fade_out(0.3)
		ruth.position.x = 790.0
		ruth.face(-1)
		ruth.seated = true
		ruth.seat_y = 62.0
		ruth.z_index = 2
		await hud.fade_in(0.3)
	await _note("Ruth sits beside her.")
	await _line("RUTH", "We can stay here all night doing it.")
	await _note("She pushes the soup a little closer.")
	await _line("RUTH", "Eat while we do.")
	await _hold(1.4)
	Audio.stop_loop("hum", 0.6)


## Spring: Cal's number by the register, Mara listening on her breaks, the
## porch light at home.
func _spring() -> void:
	await _fade_cut("diner_day", 0.9)
	_show(cal, 790.0, 1)
	cal.z_index = 2
	_show(ruth, 930.0, -1)
	cards = 3
	card_out = false
	await _cap("Winter becomes spring.", 2.2)
	card_out = true
	await _cap("Cal comes by. He leaves a telephone number beside a photograph of Tomas.", 3.2)
	card_out = false
	cards = 4
	await _cap("Ruth puts it with the others.", 2.2)
	bag_out = true
	await _cap("He has brought the field set back in a paper evidence bag. Mara keeps the bag even after the radio comes out.", 4.0)
	bag_out = false
	_cut("station")
	_show(mara80, 600.0, 1)
	mara80.seated = true
	mara80.headphones_mode = "head"
	mara80.arm_pose = [[1.25, 0.6], [1.1, 0.75]]
	Audio.play_loop("hum", -28.0, 0.3)
	Audio.play_loop("static", -30.0, 0.3)
	await _cap("Mara goes back to work at the observatory. On her breaks she listens through headphones, and writes down signals she doesn't know.", 4.4)
	Audio.stop_loop("hum", 0.3)
	Audio.stop_loop("static", 0.3)
	_cut("porch")
	await _cap("At home, Ruth leaves the porch light on.", 2.6)
	await _cap("Neither of them mentions the other's habit.", 2.6)


## The crate.
func _crate() -> void:
	await _fade_cut("house", 0.9)
	letters = 0
	_show(mara80, 520.0, 1)
	mara80.head_tilt = 0.2
	_show(ruth, 150.0, 1)
	await _cap("One evening, Ruth finds Mara packing Tomas's radio parts, blankets and tapes into a wooden crate.", 3.8)
	await _walk(ruth, 330.0)
	await _line("RUTH", "What are you doing?")
	await _line("MARA", "Taking them up to the station.")
	await _line("RUTH", "Why?")
	mara80.face(-1)
	mara80.prop = "headphones"
	mara80.head_tilt = 0.1
	await _note("Mara lifts the headphones. Their cable catches round her wrist.")
	await _line("MARA", "I keep thinking I hear him in here.")
	await _walk(ruth, 432.0)
	ruth.arm_pose = [[1.3, 0.4], [0.3, 0.2]]
	await _note("Ruth helps untangle it. For a moment, they both hold the headphones.")
	await _hold(1.2)
	await _line("RUTH", "Somewhere dry.")
	await _line("MARA", "The basement.")
	await _line("RUTH", "Put his name on it.")
	ruth.arm_pose = []
	mara80.prop = "none"
	mara80.face(1)
	await _walk(mara80, 560.0)
	await _note("Mara writes TOMAS across the wood.")
	for k in 5:
		if _skip():
			break
		letters = k + 1
		Audio.sfx("scratch", -24.0, 1.4)
		await _hold(0.35)
	letters = 5
	await _hold(1.0)


## October 14, 1983.
func _poster_1983() -> void:
	if _skip():
		return
	await hud.fade_out(0.8)
	await hud.card("October 14, 1983", "", 1.6)
	_cut("window_1983")
	poster_swap = 0.0
	ruth.kind = "ruth"
	_ruth_at_window()
	await hud.fade_in(0.8)
	await _cap("Ruth replaces the missing-person poster in the diner window. The old one has faded almost white.", 3.0)
	var tw := create_tween()
	tw.tween_property(self, "poster_swap", 1.0, 1.6)
	await _hold(3.0)
	ruth.kind = "ruth_1980"


# --- moving parts ------------------------------------------------------------------------

func _process(delta: float) -> void:
	super(delta)
	_st += delta
	car_x = move_toward(car_x, car_target, delta * maxf(30.0, absf(car_target - car_x) * 1.1))
	sedan_x = move_toward(sedan_x, sedan_target, delta * maxf(40.0, absf(sedan_target - sedan_x) * 1.4))
	road_scroll += road_speed * delta
	if shot == "printer":
		_sheet_t += delta
		if _sheet_t > 0.55:
			_sheet_t = 0.0
			sheets += 1
			Audio.sfx("thunk", -18.0, 1.3)


# --- drawing -----------------------------------------------------------------------------

func draw_back() -> void:
	match shot:
		"clearing":
			_draw_clearing(IntroArt.NIGHT)
		"morning":
			_draw_clearing(IntroArt.DAWN)
		"search":
			_draw_search()
		"interview":
			_draw_interview()
		"frame":
			_draw_frame()
		"printer":
			_draw_printer()
		"window", "window_1983":
			_draw_window_out()
		"post":
			_draw_post()
		"drive_out":
			IntroArt.road(cv, road_scroll, 0.0, IntroArt.DAY)
			Vehicles.pickup(cv, Vector2(600, 614), 1.0, t, {"engine": true, "snow": 0.2, "travel": road_scroll, "cab": ["mara80"]})
		"drive_back":
			IntroArt.road(cv, road_scroll, 0.0, IntroArt.NIGHT)
			Vehicles.pickup(cv, Vector2(680, 614), 1.0, t, {"engine": true, "lights": true, "beam": 420.0, "snow": 0.4,
				"travel": road_scroll, "flip": true, "cab": ["mara80"]})
		"diner_night", "diner_day", "phone":
			super()
		"station":
			_draw_station()
		"porch":
			_draw_porch()
		"house":
			_draw_house()
		_:
			cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 900), Color.BLACK)


func draw_fore(ci: CanvasItem) -> void:
	match shot:
		"diner_night", "diner_day", "phone":
			draw_poster_back(ci, 1.0)
		"window", "window_1983":
			_draw_window_front(ci)


func draw_glow(ci: CanvasItem) -> void:
	match shot:
		"clearing":
			Vehicles.car_bar_glow(ci, Vector2(car_x, 650), 0.95, t)
			# The headlights sweeping across the field as it turns in.
			var turn := clampf((car_target - car_x) / 500.0, 0.0, 1.0)
			_sweep(ci, Vector2(car_x + 255.0, 578.0), -0.32 * turn + 0.02, 900.0)
			IntroArt.dropped_flashlight(ci, FLASH, 0.35, -1.0)
		"search":
			for k in 4:
				var p := Vector2(180.0 + k * 300.0 + 30.0 * sin(t * 0.3 + k), 488.0)
				_sweep(ci, p + Vector2(0, -20), 0.35 * sin(t * 0.7 + k * 1.7) + 0.3, 210.0, 0.16)
			if searcher.visible:
				_sweep(ci, searcher.position + Vector2(36, -80), 0.55, 220.0, 0.22)
			Vehicles.car_bar_glow(ci, Vector2(-180, 640), 0.7, t)
		"interview":
			Kit.soft_glow(ci, Vector2(646, 516), 230.0, Color(1.0, 0.82, 0.5, 0.22))
			Kit.soft_glow(ci, Vector2(646, 520), 26.0, Color(1.0, 0.95, 0.8, 0.8))
		"porch":
			var c := Vector2(-290, -244) + LindHouse.SCONCE * 1.4
			Kit.soft_glow(ci, c, 200.0, Color(1.0, 0.76, 0.4, 0.26))
			Kit.soft_glow(ci, c, 26.0, Color(1.0, 0.9, 0.7, 0.9))
		"station":
			Kit.soft_glow(ci, Vector2(910, 470), 26.0, Color(1.0, 0.92, 0.7, 0.8))
		"house":
			Kit.soft_glow(ci, Vector2(1195, 445), 30.0, Color(1.0, 0.9, 0.7, 0.7))
		"frame":
			Kit.soft_glow(ci, Vector2(1052, 360), 70.0, Color(1.0, 0.88, 0.6, 0.5))
		"diner_night":
			Kit.soft_glow(ci, Vector2(760, 470), 300.0, Color(1.0, 0.8, 0.5, 0.12))


## A flashlight or headlight beam: a soft cone from p at angle a (radians, 0
## = right, positive = down), `length` long.
func _sweep(ci: CanvasItem, p: Vector2, a: float, length: float, alpha: float = 0.2) -> void:
	var warm := Color(1.0, 0.94, 0.74)
	var d := Vector2(cos(a), sin(a))
	var n := Vector2(-d.y, d.x)
	ci.draw_polygon(PackedVector2Array([p - n * 4.0, p + d * length - n * length * 0.18, p + d * length + n * length * 0.18, p + n * 4.0]),
		PackedColorArray([Color(warm, alpha), Color(warm, 0.0), Color(warm, 0.0), Color(warm, alpha)]))


func draw_anim(ci: CanvasItem) -> void:
	match shot:
		"clearing":
			if mara80.visible and mara80.blanket.a <= 0.0:
				# Snow settled on her shoulders.
				for k in 4:
					ci.draw_circle(mara80.position + Vector2(-10 + k * 6, -0.72 * 188.0 + (k % 2) * 2), 3.5, Color(0.9, 0.93, 0.98, 0.9))
		"search":
			# Searchers deep in the trees: small dark figures, moving slowly.
			for k in 4:
				var p := Vector2(180.0 + k * 300.0 + 30.0 * sin(t * 0.3 + k), 488.0)
				ci.draw_rect(Rect2(p.x - 4, p.y - 34, 8, 30), Color("0a0d14"))
				ci.draw_circle(p + Vector2(0, -40), 5.0, Color("0a0d14"))
			if searcher.visible:
				_draw_dog(ci, searcher.position.x + 130.0)
		"station":
			# The scope's trace, and the reels turning.
			ci.draw_line(Vector2(STATION_SCOPE.position.x + 4, STATION_SCOPE.get_center().y),
				Vector2(STATION_SCOPE.end.x - 4, STATION_SCOPE.get_center().y + sin(t * 5.0) * 6.0), Color(0.3, 1.0, 0.55, 0.85), 1.5)
			for k in 2:
				var rc := Vector2(1006 + k * 64, 388)
				var a := t * 2.2
				for j in 3:
					var aa := a + TAU * j / 3.0
					ci.draw_line(rc, rc + Vector2(cos(aa), sin(aa)) * 18.0, Color("8a8e92"), 3.0)
		"printer":
			_printer_moving(ci)
		"frame":
			var keep := cv
			cv = ci
			var f := FRAME
			_portrait(Rect2(f.position + Vector2(30, 30 - 520.0 * photo_out), f.size - Vector2(60, 60)))
			# The frame's top edge stays in front of the photo as it slides up.
			cv.draw_rect(Rect2(f.position.x - 20, f.position.y - 20, f.size.x + 40, 20), Color("6a4a2a"))
			cv.draw_rect(Rect2(f.position.x - 20, f.position.y - 2, f.size.x + 40, 2), Color("8a6a40"))
			cv = keep
		"post":
			_post_moving(ci)


func _draw_clearing(mood: String) -> void:
	cv.draw_set_transform(Vector2(-300, 0), 0.0, Vector2.ONE)
	IntroArt.clearing(cv, mood)
	if mood == IntroArt.NIGHT:
		IntroArt.mast_lights(cv, t)
		IntroArt.footprints(cv, PRINTS_FROM + 300.0, PRINTS_END + 300.0, 652.0)
	else:
		IntroArt.trampled(cv, 7)
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mood == IntroArt.NIGHT:
		IntroArt.dropped_set(cv, FLASH + Vector2(30, 2))
		IntroArt.dropped_flashlight(cv, FLASH, 0.0, -1.0)
	if sedan_x > -1300.0:
		Vehicles.car(cv, Vector2(sedan_x, 640), 0.9, t, {"body": Color("8a7a5a"), "lights": mood == IntroArt.NIGHT,
			"engine": sedan_x != sedan_target, "travel": sedan_x, "snow": 0.2})
	Vehicles.car(cv, Vector2(car_x, 650), 0.95, t, {"police": true, "lights": mood == IntroArt.NIGHT, "bar": mood == IntroArt.NIGHT,
		"engine": mood == IntroArt.NIGHT, "travel": car_x, "snow": 0.15 if mood == IntroArt.NIGHT else 0.7})


## The treeline at night: trunks close up, the search beyond them, the map on
## the bonnet of a neighbour's car.
func _draw_search() -> void:
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 560), Color("05070c"), Color("161c2c"))
	Kit.pines(cv, 470.0, Color("080b12"))
	IntroArt.pine_snow(cv, 470.0)
	Kit.vgrad(cv, Rect2(Kit.L, 466, Kit.R - Kit.L, 320), Color("6f7d96"), Color("4e5a70"))
	for x in [-60.0, 250.0, 1180.0, 1460.0]:
		cv.draw_rect(Rect2(x, -100, 46, 760), Color("0c0f15"))
		cv.draw_line(Vector2(x + 30, -100), Vector2(x + 30, 660), Color(0.6, 0.66, 0.78, 0.12), 3.0)
		for k in 3:
			var y := 120.0 + k * 150.0
			cv.draw_line(Vector2(x + 46, y), Vector2(x + 150, y - 30), Color("0c0f15"), 7.0)
			cv.draw_line(Vector2(x + 46, y - 4), Vector2(x + 140, y - 34), Color(0.8, 0.85, 0.92, 0.4), 2.0)
	IntroArt.trampled(cv, 3)
	Vehicles.car(cv, Vector2(sedan_x, 646), 0.8, t, {"body": Color("5a6a7a"), "lights": true, "beam": 300.0})
	# The map spread on its bonnet.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(sedan_x + 120, 566), Vector2(sedan_x + 200, 568), Vector2(sedan_x + 196, 574),
		Vector2(sedan_x + 114, 572)]), Color("e8e0c8"))
	cv.draw_line(Vector2(sedan_x + 130, 569), Vector2(sedan_x + 186, 571), Color("8a1d1d"), 1.2)


## The search dog on a long lead, nose down: a shepherd, tan and black.
func _draw_dog(ci: CanvasItem, x: float) -> void:
	var y := 650.0
	var tan := Color("a8743e")
	var saddle := Color("2a2018")
	var leg := sin(t * 9.0) * 9.0
	for k in 4:
		var lx := x - 40.0 + k * 22.0 if k < 2 else x + 4.0 + (k - 2) * 22.0
		ci.draw_line(Vector2(lx, y - 30), Vector2(lx + (leg if k % 2 == 0 else -leg), y), tan.darkened(0.15 if k % 2 else 0.0), 6.0)
	var body := PackedVector2Array([Vector2(x - 54, y - 50), Vector2(x - 20, y - 58), Vector2(x + 22, y - 56), Vector2(x + 38, y - 46),
		Vector2(x + 34, y - 30), Vector2(x - 10, y - 26), Vector2(x - 50, y - 30)])
	ci.draw_colored_polygon(body, tan)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 46, y - 52), Vector2(x - 18, y - 59), Vector2(x + 18, y - 57),
		Vector2(x + 10, y - 44), Vector2(x - 40, y - 42)]), saddle)
	# Head down at the snow, ears up.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 30, y - 50), Vector2(x + 48, y - 46), Vector2(x + 66, y - 26),
		Vector2(x + 70, y - 18), Vector2(x + 58, y - 16), Vector2(x + 36, y - 30)]), tan)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 40, y - 48), Vector2(x + 44, y - 62), Vector2(x + 50, y - 46)]), saddle)
	ci.draw_circle(Vector2(x + 68, y - 18), 3.0, Color("141010"))
	ci.draw_line(Vector2(x - 52, y - 48), Vector2(x - 74, y - 40), tan.darkened(0.2), 6.0)
	if searcher.visible:
		ci.draw_line(Vector2(x + 34, y - 48), searcher.position + Vector2(30, -96), Color("6a2a20"), 2.0)


## A room inside the observatory, late: Cal and Mara either side of a table
## under a desk lamp; the map of the mountain on the board behind them.
func _draw_interview() -> void:
	Kit.wall(cv, floor_y, StationRoom.WALL, StationRoom.WALL_LOW, StationRoom.TRIM)
	Kit.floor_tiles(cv, floor_y, StationRoom.FLOOR, StationRoom.FLOOR_LINE)
	Kit.ceiling_light(cv, 300.0, floor_y, false)
	Kit.ceiling_light(cv, 980.0, floor_y, false)
	var win := Rect2(870, 210, 230, 170)
	Kit.night_view(cv, win, 0.0, 960.0, 0.6)
	Kit.window_frame(cv, win, 2)
	Kit.door(cv, Rect2(100, 340, 92, 310), StationRoom.DOOR, "")
	# The search map pinned to a board: the mountain's contours, the clearing
	# ringed in red, the areas already searched hatched.
	var board := Rect2(390, 150, 380, 230)
	cv.draw_rect(board.grow(8), Color("4a3a28"))
	cv.draw_rect(board, Color("b08a5a"))
	var map := Rect2(board.position + Vector2(20, 18), Vector2(250, 190))
	cv.draw_rect(map, Color("e8e2cc"))
	for k in 7:
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * i / 24.0
			var rr := 20.0 + k * 13.0 + 6.0 * sin(a * 3.0 + k)
			pts.append(map.get_center() + Vector2(cos(a) * rr * 1.2, sin(a) * rr * 0.8))
		cv.draw_polyline(pts, Color(0.55, 0.42, 0.25, 0.7), 1.0, true)
	cv.draw_line(map.position + Vector2(10, map.size.y - 20), map.get_center() + Vector2(30, -10), Color("6a6a70"), 2.0)
	cv.draw_arc(map.get_center() + Vector2(40, -20), 16.0, 0, TAU, 20, Color("c8322c"), 2.5)
	for k in 6:
		cv.draw_line(map.position + Vector2(150 + k * 12, 120), map.position + Vector2(180 + k * 12, 150), Color(0.3, 0.4, 0.7, 0.5), 1.5)
	for p in [Vector2(60, 40), Vector2(200, 60), Vector2(120, 160)]:
		cv.draw_circle(map.position + p, 4.0, Color("2a6ab0"))
	# Notes pinned beside it.
	for k in 3:
		var n := Rect2(board.position.x + 290, board.position.y + 20 + k * 66, 70, 54)
		cv.draw_rect(n, Color("f2eed8") if k != 1 else Color("f2e48a"))
		for j in 3:
			cv.draw_line(n.position + Vector2(8, 14 + j * 12), n.position + Vector2(60 - j * 8, 14 + j * 12), Color(0.2, 0.2, 0.3, 0.6), 1.0)
		cv.draw_circle(n.position + Vector2(35, 4), 3.0, Color("c8322c"))
	# A filing cabinet, a clock that says ten to three.
	var fc := Rect2(220, 420, 110, 230)
	cv.draw_rect(fc, Color("5a6466"))
	for k in 3:
		var d := Rect2(fc.position.x + 8, fc.position.y + 10 + k * 72, fc.size.x - 16, 64)
		cv.draw_rect(d, Color("6a7476"))
		cv.draw_rect(Rect2(d.get_center().x - 16, d.position.y + 12, 32, 6), Color("c8ccca"))
	var cl := Vector2(1150, 120)
	cv.draw_circle(cl, 30.0, Color("e8e4d8"))
	cv.draw_arc(cl, 30.0, 0, TAU, 32, Color("2a2e30"), 3.0)
	cv.draw_line(cl, cl + Vector2(cos(-PI / 2 + 2.9 * TAU / 12.0), sin(-PI / 2 + 2.9 * TAU / 12.0)) * 16.0, Color("1a1a1a"), 3.0)
	cv.draw_line(cl, cl + Vector2(cos(-PI / 2 + 50.0 / 60.0 * TAU), sin(-PI / 2 + 50.0 / 60.0 * TAU)) * 24.0, Color("1a1a1a"), 2.0)
	# The table: the lamp, two mugs, Cal's hat, the thermos, the notebook.
	cv.draw_rect(Rect2(500, 560, 280, 12), Color("4a3a2c"))
	cv.draw_line(Vector2(500, 561), Vector2(780, 561), Color("6a5440"), 2.0)
	cv.draw_rect(Rect2(512, 572, 8, 78), Color("3a2e24"))
	cv.draw_rect(Rect2(760, 572, 8, 78), Color("3a2e24"))
	cv.draw_rect(Rect2(624, 540, 32, 20), Color("2a2f33"))
	cv.draw_line(Vector2(640, 540), Vector2(650, 512), Color("2a2f33"), 3.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(628, 520), Vector2(664, 516), Vector2(656, 500), Vector2(636, 502)]), Color("2e5a3a"))
	EnvironmentArt.mug(cv, Vector2(560, 545))
	EnvironmentArt.mug(cv, Vector2(712, 545))
	cv.draw_rect(Rect2(586, 528, 20, 32), Color("8a2a24"))
	cv.draw_rect(Rect2(588, 522, 16, 8), Color("c8ccca"))
	# Cal's hat, crown down on the table.
	cv.draw_colored_polygon(Vehicles._ellipse(Vector2(742, 556), 30.0, 6.0, 16), Color("5a4a32"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(722, 556), Vector2(762, 556), Vector2(756, 534), Vector2(728, 534)]), Color("6a5838"))
	cv.draw_line(Vector2(726, 550), Vector2(758, 550), Color("3a2e1e"), 3.0)
	for c in [[440.0, -1.0], [848.0, 1.0]]:
		var x: float = c[0]
		var d2: float = c[1]
		cv.draw_rect(Rect2(x - 26, 594, 52, 8), Color("3a3028"))
		cv.draw_line(Vector2(x - 22, 602), Vector2(x - 22, 650), Color("2a221c"), 4.0)
		cv.draw_line(Vector2(x + 22, 602), Vector2(x + 22, 650), Color("2a221c"), 4.0)
		cv.draw_line(Vector2(x + 24 * d2, 596), Vector2(x + 28 * d2, 520), Color("3a3028"), 6.0)


## A framed school photograph on the sideboard at home; the photo comes out
## (its frame on the moving layer). Wallpaper, a lamp, the other photographs.
const FRAME := Rect2(470, 130, 340, 400)


func _draw_frame() -> void:
	# Striped wallpaper above a dado rail.
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 640), Color("4a3e36"), Color("5a4c40"))
	for k in 60:
		var x := Kit.L + k * 40.0
		cv.draw_rect(Rect2(x, -100, 14, 620), Color(0.0, 0.0, 0.0, 0.07))
		for j in 9:
			cv.draw_circle(Vector2(x + 27, -60 + j * 64 + (k % 2) * 32), 3.0, Color(0.85, 0.75, 0.55, 0.08))
	Kit.soft_glow(cv, Vector2(1060, 300), 360.0, Color(1.0, 0.8, 0.5, 0.18))
	# The sideboard: its top, a lace runner, drawers with brass pulls.
	cv.draw_rect(Rect2(Kit.L, 520, Kit.R - Kit.L, 400), Color("4a2e1c"))
	cv.draw_rect(Rect2(Kit.L, 516, Kit.R - Kit.L, 14), Color("6a4228"))
	cv.draw_line(Vector2(Kit.L, 517), Vector2(Kit.R, 517), Color("8a5a38"), 2.0)
	for k in 3:
		var d := Rect2(170 + k * 330, 560, 280, 110)
		cv.draw_rect(d, Color("54341f"))
		cv.draw_rect(d, Color("3a2414"), false, 3.0)
		cv.draw_rect(Rect2(d.get_center().x - 24, d.position.y + 20, 48, 8), Color("c8a24a"))
	var lace := Rect2(380, 508, 520, 12)
	cv.draw_rect(lace, Color("ece6d8"))
	for k in 26:
		cv.draw_arc(Vector2(lace.position.x + 10 + k * 20, lace.end.y), 9.0, 0.0, PI, 10, Color("ece6d8"), 3.0)
	for k in 13:
		cv.draw_circle(Vector2(lace.position.x + 20 + k * 40, lace.position.y + 6), 2.0, Color("cfc6b2"))
	# The lamp at the right, lit.
	cv.draw_rect(Rect2(1046, 380, 12, 130), Color("8a6a40"))
	cv.draw_rect(Rect2(1020, 500, 64, 12), Color("6a4a2a"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(990, 380), Vector2(1114, 380), Vector2(1090, 300), Vector2(1014, 300)]), Color("f2dca8"))
	cv.draw_line(Vector2(990, 380), Vector2(1114, 380), Color("d8b878"), 3.0)
	# Two smaller frames: Ruth and her husband, the children on a beach.
	for k in 2:
		var pf := Rect2(170 + k * 160, 330 + k * 50, 140 - k * 40, 180 - k * 50)
		cv.draw_rect(pf.grow(10), Color("2a2a2a") if k == 0 else Color("b89a5a"))
		var inner := pf.grow(-6)
		Kit.vgrad(cv, inner, Color("c8b49a") if k == 0 else Color("8ab0c8"), Color("9a8468") if k == 0 else Color("d8c8a0"))
		if k == 0:
			cv.draw_circle(inner.position + Vector2(inner.size.x * 0.36, inner.size.y * 0.36), 14.0, Color("6a5444"))
			cv.draw_circle(inner.position + Vector2(inner.size.x * 0.64, inner.size.y * 0.32), 14.0, Color("5a4434"))
			cv.draw_rect(Rect2(inner.position + Vector2(10, inner.size.y * 0.5), Vector2(inner.size.x - 20, inner.size.y * 0.5)), Color("3a3a40"))
		else:
			cv.draw_circle(inner.position + Vector2(30, 60), 9.0, Color("c87a5a"))
			cv.draw_circle(inner.position + Vector2(64, 66), 7.0, Color("b4352b"))
	# The big frame; its photo (and the frame's top edge) are on the moving layer.
	var f := FRAME
	cv.draw_rect(f.grow(20), Color("6a4a2a"))
	cv.draw_rect(f.grow(8), Color("8a6a40"))
	cv.draw_rect(f, Color("c9b89a"))
	cv.draw_line(f.position + Vector2(-20, f.size.y + 20), f.position + Vector2(-60, f.size.y + 40), Color(0, 0, 0, 0.2), 10.0)


## Tomas's school photo: head and shoulders against the studio's mottled
## blue, the red parka with its fur ruff, his headphones round his neck.
func _portrait(r: Rect2) -> void:
	Kit.vgrad(cv, r, Color("8796a8"), Color("5a6676"))
	Kit.soft_glow(cv, r.get_center() + Vector2(0, -r.size.y * 0.1), r.size.x * 0.55, Color(1, 1, 1, 0.12))
	var s := r.size.x / 280.0
	var c := r.position + Vector2(r.size.x * 0.5, r.size.y * 0.4)
	var P := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	var skin := Color("dfb093")
	var hair := Color("5a3b28")
	var parka := Color("b4352b")
	# Shoulders and the parka.
	var low := r.end.y
	cv.draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + 4, low), P.call(-120, 120), P.call(-70, 88), P.call(70, 88),
		P.call(120, 120), Vector2(r.end.x - 4, low)]), parka)
	for k in 3:
		cv.draw_line(P.call(-118, 136 + k * 24), P.call(118, 136 + k * 24), parka.darkened(0.25), 2.0 * s)
	cv.draw_line(P.call(4, 96), Vector2(c.x + 4 * s, low), parka.darkened(0.45), 3.0 * s)
	# Headphones resting round his neck: the band goes behind it.
	for e in [-1.0, 1.0]:
		cv.draw_line(P.call(46 * e, 96), P.call(22 * e, 64), Color("26292e"), 6.0 * s)
	# Neck, the fur ruff, then the cups on top of it.
	cv.draw_colored_polygon(PackedVector2Array([P.call(-22, 40), P.call(22, 40), P.call(26, 96), P.call(-26, 96)]), skin.darkened(0.14))
	var ruff := PackedVector2Array()
	for k in 15:
		var a := PI * k / 14.0
		var rr := 1.0 + (0.06 if k % 2 == 0 and k > 0 and k < 14 else 0.0)
		ruff.append(P.call(-cos(a) * 74.0 * rr, 92.0 + sin(a) * 14.0 * rr))
	for k in range(1, 14):
		var a := PI * (14 - k) / 14.0
		# The lower edge shares the upper one's ends and stays below it: a crescent.
		ruff.append(P.call(-cos(a) * 74.0, 92.0 + sin(a) * 34.0))
	cv.draw_colored_polygon(ruff, Color("e2d6bc"))
	for e in [-1.0, 1.0]:
		cv.draw_colored_polygon(Vehicles._ellipse(P.call(48 * e, 100), 15.0 * s, 19.0 * s, 18), Color("2c3036"))
		cv.draw_circle(P.call(48 * e, 100), 6.0 * s, Color("3e434a"))
	# Ears, then the face.
	for e in [-1.0, 1.0]:
		cv.draw_colored_polygon(Vehicles._ellipse(P.call(57 * e, 4), 10.0 * s, 16.0 * s, 18), skin.darkened(0.08))
	var face := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		var squeeze := 0.86 if sin(a) > 0.0 else 1.0
		face.append(P.call(cos(a) * 56.0 * (1.0 - 0.12 * maxf(0.0, sin(a))), sin(a) * 70.0 * squeeze))
	cv.draw_colored_polygon(face, skin)
	# Hair: a tousled cap with a fringe over the forehead.
	cv.draw_colored_polygon(PackedVector2Array([P.call(-60, 4), P.call(-62, -38), P.call(-44, -68), P.call(-12, -80), P.call(22, -78),
		P.call(50, -62), P.call(62, -32), P.call(60, 4), P.call(52, -22), P.call(40, -30), P.call(30, -22), P.call(22, -34),
		P.call(8, -26), P.call(-6, -36), P.call(-20, -26), P.call(-34, -34), P.call(-46, -22), P.call(-54, -10)]), hair)
	cv.draw_line(P.call(-30, -60), P.call(-10, -68), hair.lightened(0.2), 2.0 * s)
	cv.draw_line(P.call(10, -66), P.call(30, -62), hair.lightened(0.2), 2.0 * s)
	# Brows, eyes, nose, a closed-mouth smile.
	for e in [-1.0, 1.0]:
		cv.draw_line(P.call(14 * e, -14), P.call(36 * e, -16), hair.darkened(0.2), 3.0 * s)
		cv.draw_colored_polygon(Vehicles._ellipse(P.call(24 * e, -1), 9.0 * s, 5.0 * s, 18), Color("f2ece2"))
		cv.draw_circle(P.call(24 * e + 1, -1), 4.2 * s, Color("3b2a1e"))
		cv.draw_circle(P.call(24 * e + 2, -2), 1.4 * s, Color(1, 1, 1, 0.8))
		cv.draw_circle(P.call(30 * e, 22), 9.0 * s, Color(0.88, 0.45, 0.42, 0.18))
	cv.draw_line(P.call(-3, 4), P.call(-6, 24), skin.darkened(0.22), 2.0 * s)
	cv.draw_line(P.call(-8, 26), P.call(6, 27), skin.darkened(0.3), 2.0 * s)
	cv.draw_polyline(PackedVector2Array([P.call(-14, 40), P.call(-4, 44), P.call(8, 44), P.call(16, 39)]), Color("a8665c"), 2.4 * s, true)


## The office at St. Olaf's on a grey morning: the parish duplicator on its
## table running off posters, its crank turning, the stack growing (those move,
## in _printer_moving()).
const DUP := Rect2(170, 330, 360, 210)


func _draw_printer() -> void:
	# Plaster above, dark panelling below, a small arched window on the snow.
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 500), Color("cbbfa6"), Color("b4a68a"))
	for i in 60:
		var x := Kit.L + fposmod(i * 193.7, Kit.R - Kit.L)
		var y := fposmod(i * 71.3, 360.0)
		cv.draw_line(Vector2(x, y), Vector2(x + 6 + i % 7, y + 1), Color(0.35, 0.3, 0.22, 0.12), 1.0)
	cv.draw_rect(Rect2(Kit.L, 392, Kit.R - Kit.L, 300), Color("5a3e2a"))
	for k in 40:
		cv.draw_line(Vector2(Kit.L + k * 60.0, 400), Vector2(Kit.L + k * 60.0, 700), Color("44301f"), 3.0)
	cv.draw_rect(Rect2(Kit.L, 384, Kit.R - Kit.L, 14), Color("6e4c32"))
	cv.draw_line(Vector2(Kit.L, 385), Vector2(Kit.R, 385), Color("8e6a48"), 2.0)
	var w := Rect2(1010, 90, 160, 220)
	cv.draw_rect(Rect2(w.position.x - 14, w.position.y + 40, w.size.x + 28, w.size.y - 30), Color("8a7a5e"))
	cv.draw_circle(Vector2(w.get_center().x, w.position.y + 54), w.size.x * 0.5 + 14, Color("8a7a5e"))
	Kit.vgrad(cv, Rect2(w.position.x, w.position.y + 54, w.size.x, w.size.y - 54), Color("c4ccd6"), Color("e6eaee"))
	cv.draw_circle(Vector2(w.get_center().x, w.position.y + 54), w.size.x * 0.5, Color("c4ccd6"))
	cv.draw_rect(Rect2(w.position.x, w.end.y - 40, w.size.x, 40), Color("eef2f6"))
	cv.draw_line(Vector2(w.position.x + 10, w.end.y - 60), Vector2(w.end.x - 20, w.position.y + 70), Color("4a4e54"), 3.0)
	cv.draw_line(Vector2(w.position.x + 70, w.position.y + 120), Vector2(w.end.x - 10, w.position.y + 100), Color("4a4e54"), 2.0)
	cv.draw_line(Vector2(w.get_center().x, w.position.y + 4), Vector2(w.get_center().x, w.end.y), Color("5a4a36"), 6.0)
	cv.draw_line(Vector2(w.position.x, w.position.y + 120), Vector2(w.end.x, w.position.y + 120), Color("5a4a36"), 6.0)
	cv.draw_rect(Rect2(w.position.x - 18, w.end.y, w.size.x + 36, 12), Color("9a8a6e"))
	# The hymn board and the notice board.
	var hb := Rect2(820, 120, 120, 170)
	cv.draw_rect(hb.grow(6), Color("4a3020"))
	cv.draw_rect(hb, Color("2a1e16"))
	Kit.text(cv, Vector2(hb.position.x, hb.position.y + 26), "HYMNS", 14, Color("e8dcc0"), HORIZONTAL_ALIGNMENT_CENTER, hb.size.x)
	for k in 3:
		Kit.text(cv, Vector2(hb.position.x, hb.position.y + 70 + k * 36), ["214", "37", "401"][k], 24, Color("f2ead2"), HORIZONTAL_ALIGNMENT_CENTER, hb.size.x)
	var nb := Rect2(560, 110, 220, 160)
	cv.draw_rect(nb.grow(6), Color("6a4a2a"))
	cv.draw_rect(nb, Color("b08a5a"))
	var notes := ["COAT DRIVE", "CHOIR THURS 7", "BAKE SALE"]
	for k in 3:
		var n := Rect2(nb.position.x + 12 + k * 70, nb.position.y + 16 + (k % 2) * 30, 60, 76)
		cv.draw_rect(n, Color("f2eedc"))
		Kit.text(cv, n.position + Vector2(0, 16), notes[k], 7, Color("3a3030"), HORIZONTAL_ALIGNMENT_CENTER, n.size.x)
		for j in 3:
			cv.draw_line(n.position + Vector2(8, 30 + j * 10), n.position + Vector2(52 - j * 6, 30 + j * 10), Color(0.3, 0.3, 0.35, 0.5), 1.0)
		cv.draw_circle(n.position + Vector2(30, 3), 3.0, Color("2a5a9a"))
	# A plain wooden cross.
	cv.draw_rect(Rect2(452, 60, 14, 110), Color("6a4a2a"))
	cv.draw_rect(Rect2(424, 92, 70, 14), Color("6a4a2a"))
	# The table, and the duplicator on it: an enamel body, the ink drum, the
	# feed board with its stack of blank paper, the tray the posters land in.
	cv.draw_rect(Rect2(80, 540, 900, 18), Color("6a4a30"))
	cv.draw_line(Vector2(80, 541), Vector2(980, 541), Color("8a6a48"), 2.0)
	cv.draw_rect(Rect2(100, 558, 14, 120), Color("4a3220"))
	cv.draw_rect(Rect2(946, 558, 14, 120), Color("4a3220"))
	cv.draw_rect(Rect2(Kit.L, 660, Kit.R - Kit.L, 200), Color("3a2c22"))
	var d := DUP
	cv.draw_colored_polygon(PackedVector2Array([Vector2(d.position.x - 70, d.position.y + 60), Vector2(d.position.x + 10, d.position.y + 90),
		Vector2(d.position.x + 10, d.position.y + 100), Vector2(d.position.x - 70, d.position.y + 70)]), Color("8a8e8a"))
	for k in 6:
		cv.draw_colored_polygon(PackedVector2Array([Vector2(d.position.x - 64, d.position.y + 56 - k * 2), Vector2(d.position.x + 4, d.position.y + 82 - k * 2),
			Vector2(d.position.x + 4, d.position.y + 85 - k * 2), Vector2(d.position.x - 64, d.position.y + 59 - k * 2)]), Color("f4f0e4"))
	cv.draw_rect(Rect2(d.position.x, d.position.y + 60, d.size.x, d.size.y - 60), Color("c8c2a8"))
	Kit.vgrad(cv, Rect2(d.position.x, d.position.y + 60, d.size.x, d.size.y - 60), Color("d8d2b8"), Color("a8a288"))
	cv.draw_rect(Rect2(d.position.x, d.position.y + 60, d.size.x, d.size.y - 60), Color("6a6650"), false, 3.0)
	cv.draw_rect(Rect2(d.position.x + 20, d.end.y - 40, 120, 24), Color("2a2c2c"))
	Kit.text(cv, Vector2(d.position.x + 20, d.end.y - 23), "GESTETNER", 12, Color("d8d2b8"), HORIZONTAL_ALIGNMENT_CENTER, 120)
	cv.draw_circle(DRUM, 74.0, Color("6a6e6a"))
	cv.draw_circle(DRUM, 66.0, Color("1e2022"))
	cv.draw_arc(DRUM, 66.0, -PI * 0.9, -PI * 0.3, 16, Color(1, 1, 1, 0.12), 6.0)
	cv.draw_rect(Rect2(d.end.x - 8, d.position.y + 120, 70, 10), Color("5a5e5a"))
	cv.draw_rect(Rect2(d.end.x + 50, d.position.y + 112, 210, 12), Color("8a8e8a"))
	# A box of fresh paper and the master stencil, typed.
	cv.draw_rect(Rect2(720, 480, 120, 60), Color("8a6a40"))
	Kit.text(cv, Vector2(720, 516), "BOND 500", 12, Color("3a2a18"), HORIZONTAL_ALIGNMENT_CENTER, 120)


const DRUM := Vector2(345, 432)


## The crank going round, the stack in the tray, the sheet coming out.
func _printer_moving(ci: CanvasItem) -> void:
	var a := t * 6.0
	for k in 4:
		var aa := a + TAU * k / 4.0
		ci.draw_line(DRUM + Vector2(cos(aa), sin(aa)) * 30.0, DRUM + Vector2(cos(aa), sin(aa)) * 60.0, Color(0.55, 0.57, 0.6, 0.6), 2.0)
	ci.draw_circle(DRUM, 16.0, Color("8a8e92"))
	var arm := DRUM + Vector2(cos(a), sin(a)) * 54.0
	ci.draw_line(DRUM, arm, Color("2a2c2c"), 8.0)
	ci.draw_circle(arm, 9.0, Color("8a2a24"))
	var n := mini(sheets, 12)
	for k in n:
		ci.draw_rect(Rect2(DUP.end.x + 56, DUP.position.y + 108 - k * 2, 200, 4), Color("ece6d6"))
	var slide := clampf(_sheet_t / 0.5, 0.0, 1.0)
	var keep := cv
	cv = ci
	_poster(Rect2(Vector2(560 + 300 * slide, 100), Vector2(240, 312)), 1.0)
	cv = keep


## A missing poster, readable, at r. `fresh` 1 = new; near 0 = sun-bleached.
func _poster(r: Rect2, fresh: float) -> void:
	var paper := Color("efeadb").lerp(Color("f6f4ee"), 1.0 - fresh)
	var red := Color("a01c18").lerp(Color("e8ccc8"), 1.0 - fresh)
	var ink := Color("1c1c1c").lerp(Color("d8d6d0"), 1.0 - fresh)
	cv.draw_rect(r, paper)
	var s := r.size.x / 300.0
	Kit.text(cv, r.position + Vector2(0, 48 * s), "MISSING", int(44 * s), red, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var ph := Rect2(r.position + Vector2(70, 70) * s, Vector2(160, 170) * s)
	if fresh > 0.5:
		_portrait(ph)
	else:
		cv.draw_rect(ph, Color("d0ccc4").lerp(Color("eceae4"), 1.0 - fresh))
	Kit.text(cv, r.position + Vector2(0, 280 * s), "TOMAS LIND", int(30 * s), ink, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(cv, r.position + Vector2(0, 314 * s), "AGE 13", int(24 * s), ink, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(cv, r.position + Vector2(0, 348 * s), "LAST SEEN OCT 14, HALVARD OBSERVATORY", int(12 * s), ink, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(cv, r.position + Vector2(0, 368 * s), "CALL THE COUNTY SHERIFF OR THE LANTERN", int(12 * s), ink, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


const SHOP := Rect2(330, 150, 620, 430)


## The Lantern from the street: inside, warm light and Ruth at the glass.
func _draw_window_out() -> void:
	var dusk := shot == "window_1983"
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 900), Color("101420"), Color("20283a"))
	Townscape.wall(cv, Rect2(-200, -100, 1680, 820), Color("5a3a30"), "brick")
	Kit.vgrad(cv, SHOP, Color("f6d39a"), Color("d8985a"))
	for k in 3:
		cv.draw_rect(Rect2(SHOP.position.x + 40 + k * 200, SHOP.end.y - 150, 120, 80), Color(0.45, 0.12, 0.1, 0.7))
		cv.draw_circle(Vector2(SHOP.position.x + 100 + k * 200, SHOP.position.y + 60), 16.0, Color(1.0, 0.95, 0.75))
	cv.draw_rect(Rect2(SHOP.position.x, SHOP.end.y - 60, SHOP.size.x, 60), Color(0.55, 0.2, 0.16, 0.6))
	if dusk:
		cv.draw_rect(SHOP, Color(0.1, 0.12, 0.2, 0.15))


## In front of Ruth: the wall under the window, the frame, the glass and the
## poster taped to its inside, facing the street.
func _draw_window_front(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(SHOP.position.x - 30, SHOP.end.y, SHOP.size.x + 60, 260), Color("4a3028"))
	ci.draw_rect(SHOP.grow(14), Color("3a2620"), false, 28.0)
	ci.draw_rect(Rect2(SHOP.position.x - 24, SHOP.end.y, SHOP.size.x + 48, 16), Color("8a7a6a"))
	Townscape.snow_ledge(ci, SHOP.position.x - 24, SHOP.end.x + 24, SHOP.end.y, 6.0, 41)
	var pr := Rect2(SHOP.position.x + 250, SHOP.position.y + 40, 150, 195)
	if shot == "window_1983":
		# The old one, sun-bleached almost white, coming down; the new one going up.
		var old := 1.0 - poster_swap
		if old > 0.0:
			ci.draw_rect(pr, Color(0.96, 0.95, 0.92, 0.95 * old))
			Kit.text(ci, pr.position + Vector2(0, 30), "MISSING", 22, Color(0.9, 0.8, 0.78, old), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
		if poster_swap > 0.0:
			_poster_on(ci, pr, poster_swap)
	else:
		_poster_on(ci, pr, 1.0)
	for c in [pr.position, Vector2(pr.end.x, pr.position.y), pr.end, Vector2(pr.position.x, pr.end.y)]:
		ci.draw_rect(Rect2(c - Vector2(9, 5), Vector2(18, 10)), Color(0.9, 0.9, 0.85, 0.75))
	# Glass sheen.
	ci.draw_colored_polygon(PackedVector2Array([SHOP.position + Vector2(40, 0), SHOP.position + Vector2(120, 0),
		Vector2(SHOP.position.x + 20, SHOP.end.y), Vector2(SHOP.position.x - 30, SHOP.end.y)]), Color(0.8, 0.9, 1.0, 0.07))
	Kit.text(ci, Vector2(SHOP.position.x, SHOP.position.y - 36), "THE LANTERN", 34, Color("ff9a4a"), HORIZONTAL_ALIGNMENT_CENTER, SHOP.size.x)


func _poster_on(ci: CanvasItem, pr: Rect2, a: float) -> void:
	ci.draw_rect(pr, Color(0.94, 0.92, 0.86, a))
	Kit.text(ci, pr.position + Vector2(0, 30), "MISSING", 22, Color(0.63, 0.11, 0.09, a), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	ci.draw_rect(Rect2(pr.position + Vector2(35, 42), Vector2(80, 86)), Color(0.55, 0.59, 0.64, a))
	ci.draw_circle(pr.position + Vector2(75, 78), 18.0, Color(0.87, 0.69, 0.58, a))
	ci.draw_rect(Rect2(pr.position + Vector2(48, 98), Vector2(54, 30)), Color(0.7, 0.21, 0.17, a))
	Kit.text(ci, pr.position + Vector2(0, 150), "TOMAS LIND", 16, Color(0.1, 0.1, 0.1, a), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	Kit.text(ci, pr.position + Vector2(0, 172), "AGE 13", 14, Color(0.1, 0.1, 0.1, a), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)


## A pole by the service road on a grey afternoon, the poster flapping on it,
## red tape going on its corners (the poster moves: _post_moving()).
func _draw_post() -> void:
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 620), Color("7c8796"), Color("bcc3cc"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 420), Vector2(-60, 330), Vector2(260, 380), Vector2(620, 300),
		Vector2(980, 360), Vector2(Kit.R, 320), Vector2(Kit.R, 470), Vector2(Kit.L, 470)]), Color("9aa4b2"))
	Kit.pines(cv, 470.0, Color("39424c"))
	IntroArt.pine_snow(cv, 470.0, IntroArt.DAY)
	Kit.vgrad(cv, Rect2(Kit.L, 466, Kit.R - Kit.L, 320), Color("e2e6ec"), Color("b4bcc8"))
	cv.draw_rect(Rect2(Kit.L, 600, Kit.R - Kit.L, 46), Color("8a929e"))
	for k in 2:
		cv.draw_line(Vector2(Kit.L, 610 + k * 24), Vector2(Kit.R, 612 + k * 24), Color(0.4, 0.44, 0.5, 0.5), 3.0)
	Townscape.snowbank(cv, Kit.L, Kit.R, 602, 10.0, 5)
	# The road's snow stakes, and the pole.
	for x in [180.0, 1100.0]:
		cv.draw_line(Vector2(x, 600), Vector2(x, 520), Color("1a1f2b"), 3.0)
		cv.draw_line(Vector2(x, 528), Vector2(x, 520), Color("d0542e"), 3.0)
	cv.draw_rect(Rect2(684, 60, 22, 600), Color("5a4634"))
	cv.draw_line(Vector2(690, 60), Vector2(690, 660), Color("6e5844"), 2.0)
	for k in 7:
		cv.draw_line(Vector2(686, 120 + k * 70), Vector2(704, 122 + k * 70), Color("4a3828"), 1.5)
	# What's left of an older poster under the new one.
	cv.draw_rect(Rect2(706, 260, 20, 30), Color(0.92, 0.9, 0.84, 0.6))


func _post_moving(ci: CanvasItem) -> void:
	var top := Vector2(640, 300)
	var flap := sin(t * 7.0) * (10.0 if tape_strips < 3 else 2.0)
	ci.draw_colored_polygon(PackedVector2Array([top, top + Vector2(110, 0), top + Vector2(112 + flap * 0.4, 140), top + Vector2(-2 + flap, 146)]),
		Color("efeadb"))
	Kit.text(ci, top + Vector2(0, 26), "MISSING", 18, Color("a01c18"), HORIZONTAL_ALIGNMENT_CENTER, 110)
	ci.draw_rect(Rect2(top + Vector2(28, 36), Vector2(54, 56)), Color("8a96a4"))
	ci.draw_circle(top + Vector2(55, 60), 12.0, Color("dfb093"))
	ci.draw_rect(Rect2(top + Vector2(42, 74), Vector2(26, 18)), Color("b4352b"))
	Kit.text(ci, top + Vector2(0, 112), "TOMAS LIND", 12, Color("1c1c1c"), HORIZONTAL_ALIGNMENT_CENTER, 110)
	Kit.text(ci, top + Vector2(0, 128), "AGE 13", 10, Color("1c1c1c"), HORIZONTAL_ALIGNMENT_CENTER, 110)
	var spots := [top + Vector2(0, 0), top + Vector2(110, 0), top + Vector2(-2 + flap, 146)]
	for k in mini(tape_strips, 3):
		var p: Vector2 = spots[k]
		ci.draw_set_transform(p, 0.6 if k % 2 == 0 else -0.6, Vector2.ONE)
		ci.draw_rect(Rect2(-14, -5, 28, 10), Color("c8322a"))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The receiver room on a night shift: Mara at the desk in the headphones,
## writing down what she hears. Racks of receivers, the scope, the tape
## machine, the dish through the window, the desk lamp.
const STATION_SCOPE := Rect2(572, 512, 74, 46)


func _draw_station() -> void:
	Kit.wall(cv, floor_y, StationRoom.WALL, StationRoom.WALL_LOW, StationRoom.TRIM)
	Kit.floor_tiles(cv, floor_y, StationRoom.FLOOR, StationRoom.FLOOR_LINE)
	Kit.ceiling_light(cv, 300.0, floor_y, false)
	var win := Rect2(640, 150, 300, 190)
	Kit.night_view(cv, win, 0.0, 820.0, 0.8)
	Kit.window_frame(cv, win, 3)
	# Two racks of receivers, every one with its meter and its lamps.
	for k in 2:
		var x := 150.0 + k * 160.0
		cv.draw_rect(Rect2(x, 250, 130, 400), Color("232a31"))
		cv.draw_rect(Rect2(x, 250, 130, 400), Color("12171b"), false, 3.0)
		for row in 6:
			var u := Rect2(x + 8, 264 + row * 62, 114, 54)
			Kit.vgrad(cv, u, Color("3a444c"), Color("2c343c"))
			cv.draw_rect(Rect2(u.position + Vector2(8, 8), Vector2(40, 26)), Color("d8d0b0") if (row + k) % 3 != 0 else Color("6a6450"))
			cv.draw_line(u.position + Vector2(28, 30), u.position + Vector2(20 + (row % 3) * 8, 14), Color("1a1a1a"), 1.5)
			for j in 3:
				cv.draw_circle(u.position + Vector2(62 + j * 16, 20), 5.0, Color("15191d"))
			cv.draw_circle(u.position + Vector2(104, 42), 3.0, Color("49d17a") if (row + k) % 2 == 0 else Color("e8a54b"))
	# The desk: the logbook open, the scope, the tape machine, the lamp.
	cv.draw_rect(Rect2(500, 556, 600, 14), Color("4a3a2c"))
	cv.draw_line(Vector2(500, 557), Vector2(1100, 557), Color("6a5440"), 2.0)
	cv.draw_rect(Rect2(512, 570, 10, 80), Color("3a2e24"))
	cv.draw_rect(Rect2(1078, 570, 10, 80), Color("3a2e24"))
	cv.draw_rect(Rect2(690, 536, 120, 20), Color("e8e2cc"))
	cv.draw_line(Vector2(750, 536), Vector2(750, 556), Color("b8b0a0"), 1.5)
	for k in 4:
		cv.draw_line(Vector2(696, 541 + k * 4), Vector2(744 - k * 8, 541 + k * 4), Color("4a5a8a"), 1.0)
		cv.draw_line(Vector2(756, 541 + k * 4), Vector2(800 - k * 10, 541 + k * 4), Color("4a5a8a"), 1.0)
	cv.draw_line(Vector2(780, 548), Vector2(820, 530), Color("c8a030"), 2.0)
	cv.draw_rect(Rect2(STATION_SCOPE.position.x - 12, STATION_SCOPE.position.y - 8, STATION_SCOPE.size.x + 24, STATION_SCOPE.size.y + 12), Color("2b3238"))
	cv.draw_rect(STATION_SCOPE, Color("06120c"))
	for k in 4:
		cv.draw_line(Vector2(STATION_SCOPE.position.x + k * 18.5, STATION_SCOPE.position.y), Vector2(STATION_SCOPE.position.x + k * 18.5, STATION_SCOPE.end.y), Color(0.2, 0.5, 0.3, 0.3), 1.0)
	var tape := Rect2(960, 350, 180, 206)
	cv.draw_rect(tape, Color("3a4046"))
	cv.draw_rect(tape, Color("1e2226"), false, 3.0)
	for k in 2:
		cv.draw_circle(Vector2(1006 + k * 64, 388), 28.0, Color("1a1c1e"))
		cv.draw_circle(Vector2(1006 + k * 64, 388), 8.0, Color("8a8e92"))
	cv.draw_rect(Rect2(tape.position.x + 20, tape.position.y + 450 - 350, 140, 40), Color("2a2e32"))
	for k in 5:
		cv.draw_rect(Rect2(tape.position.x + 26 + k * 26, tape.position.y + 160, 18, 12), Color("c8ccd0"))
	cv.draw_rect(Rect2(880, 520, 40, 36), Color("2a2f33"))
	cv.draw_line(Vector2(900, 520), Vector2(910, 470), Color("2a2f33"), 3.0)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(888, 476), Vector2(934, 470), Vector2(926, 452), Vector2(898, 456)]), Color("2e5a3a"))
	Kit.soft_glow(cv, Vector2(910, 520), 140.0, Color(1.0, 0.85, 0.55, 0.22))
	EnvironmentArt.mug(cv, Vector2(840, 541))
	cv.draw_rect(Rect2(540, 594, 52, 8), Color("3a3028"))
	cv.draw_line(Vector2(546, 602), Vector2(546, 650), Color("2a221c"), 4.0)
	cv.draw_line(Vector2(586, 602), Vector2(586, 650), Color("2a221c"), 4.0)
	cv.draw_line(Vector2(542, 596), Vector2(538, 520), Color("3a3028"), 6.0)


## Ash Street one spring night: the Lind house, closer, the lamp in the front
## window and the porch light on; a tree in blossom by the fence.
static var _spring_night: Env


func _draw_porch() -> void:
	if _spring_night == null:
		_spring_night = Env.new()
		_spring_night.st = "spring 1981"
		_spring_night.season = "spring"
		_spring_night.hour = "night"
		_spring_night.fall = "none"
	var e := _spring_night
	var keep := Env.current
	Env.current = e
	Kit.vgrad(cv, Rect2(Kit.L, -100, Kit.R - Kit.L, 900), Color("04060e"), Color("18203a"))
	Kit.stars(cv, Rect2(Kit.L, 0, Kit.R - Kit.L, 200), 70, 0.0)
	cv.draw_set_transform(Vector2(-290, -244), 0.0, Vector2(1.4, 1.4))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(Kit.L, 420), Vector2(100, 340), Vector2(500, 370), Vector2(900, 320),
		Vector2(Kit.R, 360), Vector2(Kit.R, 460), Vector2(Kit.L, 460)]), e.hills())
	Townscape.hill_houses(cv, 372.0, 420.0, 0.0, true)
	Kit.pines(cv, 440.0, Color("070b14"))
	var g: Array = e.ground()
	Kit.vgrad(cv, Rect2(Kit.L, 438, Kit.R - Kit.L, 260), g[0], g[1])
	Townscape.tree(cv, Vector2(330, 640), 300.0, 330)
	Townscape.tree(cv, Vector2(1000, 646), 270.0, 1000)
	LindHouse.draw(cv, e, false)
	LindHouse.yard(cv, e)
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Env.current = keep


## Home, one evening: the living room, the crate on the floor.
func _draw_house() -> void:
	Kit.wall(cv, floor_y, Color("7a6a58"), Color("5a4a3c"), Color("2a221c"))
	# Wallpaper: a small repeating sprig.
	for k in 40:
		var x := Kit.L + k * 60.0
		cv.draw_line(Vector2(x, 30), Vector2(x, floor_y - 124), Color(0.3, 0.2, 0.12, 0.08), 3.0)
		for j in 6:
			var p := Vector2(x + 30, 70 + j * 70 + (k % 2) * 35)
			cv.draw_line(p, p + Vector2(-4, -8), Color(0.35, 0.42, 0.3, 0.25), 2.0)
			cv.draw_line(p, p + Vector2(4, -8), Color(0.35, 0.42, 0.3, 0.25), 2.0)
			cv.draw_circle(p + Vector2(0, -10), 2.5, Color(0.7, 0.4, 0.35, 0.25))
	cv.draw_rect(Rect2(Kit.L, floor_y, Kit.R - Kit.L, 400), Color("4a3428"))
	for k in 30:
		cv.draw_line(Vector2(Kit.L, floor_y + 8 + k * 9), Vector2(Kit.R, floor_y + 8 + k * 9), Color(0.25, 0.16, 0.1, 0.4), 1.0)
	# The rug, with a border.
	var rug := Rect2(240, floor_y + 4, 800, 64)
	cv.draw_rect(rug, Color("6a3a30"))
	cv.draw_rect(rug.grow(-8), Color("8a5038"), false, 4.0)
	for k in 12:
		cv.draw_circle(Vector2(rug.position.x + 40 + k * 64, rug.get_center().y), 8.0, Color("a8704a"))
	Kit.door(cv, Rect2(60, 340, 92, 310), Color("6a5040"), "")
	# The window, curtained, on a dark evening.
	var win := Rect2(820, 250, 180, 190)
	Kit.vgrad(cv, win, Color("1a2848"), Color("4a5a80"))
	Kit.window_frame(cv, win, 2)
	# Curtains drawn back either side.
	for side in [-1, 1]:
		var x0 := win.position.x - 34.0 if side < 0 else win.end.x + 6.0
		var pts := PackedVector2Array([Vector2(x0, win.position.y - 30), Vector2(x0 + 28, win.position.y - 30),
			Vector2(x0 + 28 + (6.0 if side < 0 else -6.0), win.get_center().y), Vector2(x0 + 30, win.end.y + 40), Vector2(x0 - 2, win.end.y + 40),
			Vector2(x0 + (4.0 if side < 0 else -4.0), win.get_center().y)])
		cv.draw_colored_polygon(pts, Color("8a4a3a"))
		for j in 3:
			cv.draw_line(Vector2(x0 + 7 + j * 7, win.position.y - 26), Vector2(x0 + 7 + j * 7, win.end.y + 36), Color(0, 0, 0, 0.15), 2.0)
	cv.draw_rect(Rect2(win.position.x - 40, win.position.y - 36, win.size.x + 80, 8), Color("6a4a2a"))
	# A picture over the sofa: the lake in summer.
	var pic := Rect2(380, 200, 200, 130)
	cv.draw_rect(pic.grow(8), Color("6a4a2a"))
	Kit.vgrad(cv, pic, Color("8ab0d0"), Color("d8e4e8"))
	cv.draw_colored_polygon(PackedVector2Array([pic.position + Vector2(0, 80), pic.position + Vector2(60, 50), pic.position + Vector2(110, 70),
		pic.position + Vector2(160, 40), pic.position + Vector2(200, 70), pic.end, pic.position + Vector2(0, 130)]), Color("4a6a50"))
	cv.draw_rect(Rect2(pic.position + Vector2(0, 100), Vector2(200, 30)), Color("5a8aaa"))
	# The sofa, the radiator, the television on its stand.
	cv.draw_rect(Rect2(330, 520, 300, 130), Color("5a6a5a"))
	cv.draw_rect(Rect2(330, 470, 300, 60), Color("4a5a4a"))
	cv.draw_rect(Rect2(316, 500, 30, 150), Color("4a5a4a"))
	cv.draw_rect(Rect2(614, 500, 30, 150), Color("4a5a4a"))
	cv.draw_line(Vector2(480, 530), Vector2(480, 600), Color("3e4c3e"), 2.0)
	EnvironmentArt.radiator(cv, Vector2(860, 540), 9)
	var tv := Rect2(1010, 470, 140, 110)
	cv.draw_rect(tv, Color("6a4a2a"))
	cv.draw_rect(Rect2(tv.position + Vector2(12, 12), Vector2(90, 74)), Color("1a1e22"))
	cv.draw_circle(tv.position + Vector2(122, 34), 7.0, Color("2a2a2a"))
	cv.draw_circle(tv.position + Vector2(122, 62), 7.0, Color("2a2a2a"))
	cv.draw_line(tv.position + Vector2(50, 0), tv.position + Vector2(20, -50), Color("8a8e92"), 2.0)
	cv.draw_line(tv.position + Vector2(60, 0), tv.position + Vector2(96, -46), Color("8a8e92"), 2.0)
	cv.draw_rect(Rect2(1020, 580, 10, 70), Color("4a3220"))
	cv.draw_rect(Rect2(1130, 580, 10, 70), Color("4a3220"))
	# Lamp and armchair.
	cv.draw_rect(Rect2(1190, 470, 10, 180), Color("2a2420"))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(1160, 470), Vector2(1230, 470), Vector2(1214, 420), Vector2(1176, 420)]), Color("d8c8a0"))
	Kit.soft_glow(cv, Vector2(1195, 450), 200.0, Color(1.0, 0.82, 0.5, 0.2))
	# The crate, his things beside it.
	var c := Rect2(570, 550, 154, 100)
	cv.draw_rect(c, Color("7a6040"))
	cv.draw_rect(c, Color("5a4430"), false, 3.0)
	for i in 3:
		cv.draw_line(Vector2(c.position.x, c.position.y + 30 + i * 30), Vector2(c.end.x, c.position.y + 30 + i * 30), Color("5a4430"), 3.0)
	if letters > 0:
		Kit.text(cv, Vector2(c.position.x, c.position.y + 62), "TOMAS".left(letters), 18, Color("2a2018"), HORIZONTAL_ALIGNMENT_CENTER, c.size.x)
	cv.draw_rect(Rect2(574, 536, 146, 16), Color("4a5a6a"))
	cv.draw_rect(Rect2(740, 620, 70, 30), Color("4a5a6a"))
	cv.draw_rect(Rect2(744, 612, 62, 10), Color("5a6a7a"))
	cv.draw_rect(Rect2(820, 626, 50, 24), Color("d8b830"))
	for k in 4:
		cv.draw_rect(Rect2(824 + k * 11, 630, 9, 16), Color("2a2a2a"))
	cv.draw_rect(Rect2(600, 512, 40, 24), Color("4a5a3a"))
	# Cal's paper evidence bag, folded, kept: it goes in under the blanket.
	var bag := Rect2(650, 516, 52, 22)
	cv.draw_rect(bag, Color("b8996a"))
	cv.draw_rect(bag, Color("8a6e48"), false, 1.2)
	cv.draw_line(Vector2(bag.position.x + 34, bag.position.y), Vector2(bag.position.x + 34, bag.end.y), Color("8a6e48"), 1.0)
	cv.draw_rect(Rect2(bag.position + Vector2(4, 5), Vector2(26, 9)), Color("e8dcc0"))
	Kit.text(cv, Vector2(bag.position.x + 4, bag.position.y + 4), "EVIDENCE", 7, Color("8a2a20"), HORIZONTAL_ALIGNMENT_CENTER, 26)
	# A coil of aerial wire, a soldering iron, a few tubes in a shoebox lid.
	for r in 3:
		cv.draw_arc(Vector2(500, 640), 14.0 - r * 3.0, 0, TAU, 16, Color("8a8e92"), 2.0)
	cv.draw_rect(Rect2(880, 636, 80, 14), Color("c8b48a"))
	for k in 4:
		cv.draw_rect(Rect2(888 + k * 18, 622, 10, 16), Color(0.75, 0.82, 0.86, 0.6))


## The diner's counter in the film: the map and the soup after closing; the
## register, Tomas's photo and the cards in spring.
func _draw_counter(ci: CanvasItem) -> void:
	if not shot in DINER_SHOTS:
		return
	super(ci)
	if shot == "diner_night":
		var m := Rect2(690, 534, 150, 14)
		ci.draw_colored_polygon(PackedVector2Array([m.position + Vector2(8, 0), Vector2(m.end.x - 8, m.position.y), m.end,
			Vector2(m.position.x, m.end.y)]), Color("e8e0c8"))
		for k in 4:
			ci.draw_line(m.position + Vector2(20 + k * 30, 4), m.position + Vector2(40 + k * 28, 12), Color("6a6a70"), 1.0)
		for k in 3:
			ci.draw_arc(m.position + Vector2(40 + k * 40, 7), 7.0, 0.0, TAU, 10, Color("b8322c"), 1.5)
		if soup:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(744, 532), Vector2(780, 532), Vector2(774, 546), Vector2(750, 546)]), Color("ece6d8"))
			ci.draw_line(Vector2(746, 533), Vector2(778, 533), Color("c8823a"), 3.0)
			for k in 2:
				ci.draw_line(Vector2(756 + k * 10, 526), Vector2(752 + k * 10, 512), Color(1, 1, 1, 0.25), 1.5)
	elif shot == "diner_day":
		ci.draw_rect(Rect2(900, 508, 70, 40), Color("8a7a5a"))
		ci.draw_rect(Rect2(906, 494, 58, 16), Color("6a5a3a"))
		ci.draw_rect(Rect2(856, 512, 30, 36), Color("6a4a2a"))
		ci.draw_rect(Rect2(860, 516, 22, 26), Color("8a96a4"))
		ci.draw_circle(Vector2(871, 526), 5.0, Color("dfb093"))
		ci.draw_rect(Rect2(865, 532, 12, 10), Color("b4352b"))
		for k in cards:
			ci.draw_rect(Rect2(830 - k * 1.5, 544 - k * 2, 22, 4), Color("f0ece0"))
		if card_out:
			ci.draw_rect(Rect2(800, 540, 24, 6), Color("f8f6ee"))
		if bag_out:
			# Cal's paper evidence bag, the field set's shape inside it.
			ci.draw_colored_polygon(PackedVector2Array([Vector2(670, 548), Vector2(674, 512), Vector2(722, 510), Vector2(726, 548)]), Color("b89a6a"))
			ci.draw_line(Vector2(674, 512), Vector2(722, 510), Color("8a7048"), 2.0)
			ci.draw_rect(Rect2(682, 522, 34, 9), Color("efe6cc"))
			Kit.text(ci, Vector2(682, 523), "EVIDENCE", 7, Color("8a2a20"), HORIZONTAL_ALIGNMENT_CENTER, 34)
