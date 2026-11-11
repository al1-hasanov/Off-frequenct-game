extends Node
## Automated playthrough of the prologue and Act 1, used for headless testing.
##
##   godot --headless --path . -- --autotest=answer
##   godot --headless --path . -- --autotest=cut
##   godot --headless --path . -- --autotest=continue
##   godot --headless --path . -- --autotest=answer_leave   (or cut_take)
##   godot --headless --path . -- --autotest=chapters       (loads every chapter)
##
## Branches: answer = answer the voice + take Tomas, cut = cut the power +
## leave him; answer_leave and cut_take mix the two choices the other way.
## Add --chapters=FILE to a playthrough to write each chapter's starting
## state to FILE (tools/gen_chapters.py turns four of those into
## scripts/chapter_states.gd).
##
## It taps hotspots through the same code path as a player, checks the story
## state after each beat, and exits with code 0 on success, 1 on failure.

var main: Node
var branch := ""
var failures: Array[String] = []
## Choice 1 (answer the voice?) and Choice 2 (take Tomas?) for this run.
var answered := true
var take_tomas := true

## Chapter recording: each queued [chapter, room] is saved as that chapter's
## starting state at the next room change into that room.
var chapters_out := ""
var _marks: Array = []
var _snaps := {}

## Screenshot mode (needs a real renderer, not --headless):
##   godot --path . -- --autotest=answer --shots=/some/dir
var shots_dir := ""
var _shot_n := 0
var _cards_seen := {}
const SHOT_LINES := [
	"It's talking back", "Come on, you stupid thing", "Twenty to two", "Thirteen forever",
	"Back in business", "It's writing by itself", "Don't let her in", "Which one are you",
	"Emergency lights", "that's me", "THE KNOCK IS HER", "I buried her Tuesday",
	"My daughter died", "Sollen's office is locked", "stopped existing",
	"The lights are on", "Ow. Hot", "Did the fuse", "Properly dark", "hum's right again",
	"green crust", "still warm", "other us", "HOME = 00", "Station 12", "use it",
	"in your pockets twice", "lights off", "which one is me", "Every light in town", "gutted with love", "Lights. Cal's lights", "Lorraine", "Not a sound", "Dark. Empty. For sale", "Eighty-One. That's how many", "Everyone's early", "Where was I", "who's feeding Biscuit", "Did you cut your hair", "You look old", "Keep him in the light", "never vanishes", "The dish is calling", "Rails. Timbers", "dish is turning", "Plowed. Somebody", "Halvard spreads", "darkest dark", "Hold on, Mom",
]


func start(m: Node, b: String) -> void:
	main = m
	branch = b
	answered = b.begins_with("answer")
	take_tomas = b in ["answer", "cut_take"]
	main.entering.connect(_on_entering)
	GameState.test_mode = true
	GameState.use_test_paths()
	Engine.time_scale = 8.0
	if shots_dir != "":
		GameState.test_show_ui = true
		Engine.time_scale = 2.0
		DirAccess.make_dir_recursive_absolute(shots_dir)
		main.hud.line_shown.connect(_on_line_shown)
		main.hud.buttons_shown.connect(func(kind: String) -> void: _capture("buttons_" + kind))
		_watch_cards()
	var watchdog := get_tree().create_timer(1500.0 if shots_dir != "" else 300.0, true, false, true)
	watchdog.timeout.connect(func() -> void:
		_fail("watchdog: test timed out in room '%s'" % main.room_id)
		_finish())
	_run.call_deferred()


func _run() -> void:
	print("AUTOTEST start: branch=", branch)
	main.change_room("menu")
	await _wait_room("snowfield_1980")
	if branch == "continue":
		await _run_continue()
		return
	if branch == "tuner":
		await _run_tuner()
		return
	if branch == "rooms":
		await _run_rooms()
		return
	if branch == "chapters":
		await _run_chapters()
		return

	print("  -- P1 snowfield")
	await _tap("truck")
	await _tap("padlock")
	_expect(not GameState.has("p1_done"), "gate should not lock before talking to Tomas")
	await _tap("tomas")
	_expect(GameState.has("p1_talked"), "talked to Tomas")
	_mark("P2", "corridor")
	await _tap("padlock")
	await _wait_room("corridor")
	await _press_hint()
	_expect(GameState.clock_text == "1:40", "clock reads 1:40 after the cold open")

	print("  -- P2 night shift")
	await _tap("note")
	await _tap("locker")
	_expect(GameState.has_item("red_tape"), "red tape picked up")
	await _tap("vending")
	_expect(not GameState.has_item("fuse"), "fuse not available before checking the cabinet")
	await _tap("receiver_door")
	await _wait_room("receiver_room")
	await _tap("headphones")
	_expect(not GameState.has("heard_transmission"), "no transmission before the fuse")
	await _tap("cabinet")
	_expect(GameState.has("cabinet_empty"), "cabinet checked")
	await _tap("door")
	await _wait_room("corridor")
	await _tap("vending")
	_expect(GameState.has_item("fuse"), "fuse taken from the vending machine")
	_mark("P3", "receiver_room")
	await _tap("receiver_door")
	await _wait_room("receiver_room")
	await _use("red_tape", "fuse_slot")
	await _use("fuse", "fuse_slot")
	_expect(GameState.has("fuse_installed"), "fuse installed")
	_expect(GameState.clock_text == "2:13", "clock reads 2:13")

	print("  -- P3 the transmission")
	await _tap("chart")
	await _tap("headphones")
	_expect(GameState.has("heard_transmission"), "heard the transmission")
	_expect(GameState.clock_frozen and GameState.clock_text == "2:14", "clocks frozen at 2:14")

	print("  -- Act 1.1 Choice 1: ", "answer" if answered else "cut")
	if answered:
		await _tap("mic")
		_expect(GameState.story["ANSWERED"] == true, "ANSWERED = yes")
		_expect(not GameState.emergency, "power still on")
	else:
		await _tap("breaker")
		_expect(GameState.story["ANSWERED"] == false, "ANSWERED = no")
		_expect(GameState.emergency, "emergency lighting on")
	_expect(GameState.has("choice1"), "choice 1 recorded")

	print("  -- Act 1.2 the body")
	await _tap("door")
	await _wait_room("corridor")
	_mark("1.2", "control_room")
	await _tap("control_door")
	await _wait_room("control_room")
	_expect(GameState.has("body_seen"), "body reveal played")
	for h in ["body_face", "body_wrist", "body_watch", "body_pocket", "transmitter"]:
		await _tap(h)
	_expect(GameState.has_item("note"), "note found in her pocket")
	_expect(GameState.has("body_done"), "all four details inspected")

	print("  -- save and load round trip")
	GameState.save_game()
	var flags_before: Dictionary = GameState.flags.duplicate()
	var inv_before: Array[String] = GameState.inventory.duplicate()
	_expect(GameState.load_game(), "save loads")
	_expect(GameState.flags == flags_before, "flags survive save/load")
	_expect(GameState.inventory == inv_before, "inventory survives save/load")
	_expect(GameState.story["ANSWERED"] == answered, "ANSWERED survives save/load")

	print("  -- Act 1.3 the phone")
	await _tap("door")
	await _wait_room("corridor")
	_mark("1.3", "lobby")
	await _tap("lobby_door")
	await _wait_room("lobby")
	await _tap("front_door")
	if not answered:
		_expect(not main.room.get_hotspot("footprints").is_empty() and main.room.hotspot_enabled(main.room.get_hotspot("footprints")), "footprints visible")
		await _tap("footprints")
	await _tap("phone")
	_expect(GameState.has("phone_dead"), "phone found dead")
	await _tap("junction")
	await _use("red_tape", "junction")
	_expect(GameState.has("phone_fixed"), "wire spliced with red tape")
	GameState.test_choices = [0]
	await _tap("phone")
	_expect(GameState.has("called_sheriff"), "called the sheriff")
	GameState.test_choices = [0]
	await _tap("phone")
	_expect(GameState.has("called_home"), "called home")
	GameState.test_choices = [0]
	await _tap("phone")
	_expect(GameState.has("called_observatory"), "called the observatory's own number")
	_expect(main.room_id == "lobby", "the game carries on after the call")
	await _tap("booth_door")
	_expect(not GameState.has("booth_open"), "booth stays locked without Sollen's keys")

	print("  -- Act 1.4 the first crossing")
	_mark("1.4", "corridor")
	await _tap("corridor_door")
	await _wait_room("corridor")
	await _tap("east_wing")
	await _wait_room("east_corridor")
	_expect(GameState.frequency == "01" and main.room.freq == "01", "crossed into frequency 01")
	_expect(int(GameState.story["FRACTURE"]) == 1, "FRACTURE = 1")
	_expect(not main.room.is_dark(), "the 01 east wing is lit")
	await _tap("fire_doors")
	_expect(GameState.frequency == "01", "chained fire doors don't let her back while it's lit")
	await _tap("lamp")
	_expect(GameState.has("lamp_burned"), "the bulb is too hot to touch")
	await _tap("office_door")
	await _wait_room("sollen_office")
	await _tap("photo")
	await _tap("sollen")
	await _tap("coat")
	_expect(GameState.has_item("keys"), "took Sollen's keys from his coat")
	await _tap("scarf")
	_expect(GameState.has_item("scarf"), "took the scarf")
	print("  -- save/load keeps the frequency")
	GameState.save_game()
	GameState.frequency = "H"
	_expect(GameState.load_game() and GameState.frequency == "01", "frequency survives save/load")
	await _tap("door")
	await _wait_room("east_corridor")
	await _use("scarf", "lamp")
	_expect(GameState.has("bulb_out") and not GameState.has_item("scarf"), "bulb unscrewed with the scarf")
	_expect(not main.room.is_dark(), "office light still spills into the corridor")
	await _tap("office_door")
	_expect(GameState.has("office_closed_01") and main.room.is_dark(), "office door shut: total darkness")
	_mark("1.5", "corridor")
	await _tap("fire_doors")
	await _wait_room("corridor")
	_expect(GameState.frequency == "H" and int(GameState.story["FRACTURE"]) == 2, "crossed home in the dark, FRACTURE = 2")
	_expect(GameState.has("back_home"), "Mara knows she's home")
	await _tap("east_wing")
	_expect(main.room_id == "corridor", "won't walk into the dark again without a light")

	print("  -- the flashlight")
	await _tap("lobby_door")
	await _wait_room("lobby")
	await _tap("booth_door")
	_expect(GameState.has_item("flashlight_dead"), "dead flashlight from the security booth")
	await _tap("corridor_door")
	await _wait_room("corridor")
	await _use("flashlight_dead", "radio")
	_expect(not GameState.has_item("batteries"), "the radio's battery is the wrong size")
	await _tap("clock")
	_expect(GameState.has_item("batteries"), "took the clock's batteries")
	await _combine("batteries", "batteries")
	_expect(GameState.has_item("batteries"), "an item can't combine with itself")
	await _combine("batteries", "flashlight_dead")
	_expect(GameState.has_item("flashlight") and not GameState.has_item("batteries"), "combined into a working flashlight")
	await _tap("east_wing")
	await _wait_room("east_corridor")
	_expect(GameState.frequency == "H" and int(GameState.story["FRACTURE"]) == 2, "with a light, darkness is just darkness")
	_expect(main.room.flashlight_on(), "the flashlight beam is on")

	print("  -- Sollen's office at home")
	await _tap("office_door")
	await _wait_room("sollen_office")
	_expect(GameState.has("office_h_seen"), "office unlocked with Sollen's key")
	await _tap("phone")
	_expect(GameState.has("phone_found"), "receiver off the hook, still warm")
	await _tap("logbook")
	_expect(GameState.has("read_logbook"), "read the 1980 station log")
	await _tap("cassette")
	_expect(GameState.has("heard_cassette"), "heard Tomas's tape")
	await _tap("drawer")
	_expect(GameState.has("garage_key"), "garage key from the desk drawer")
	await _tap("lamp")
	if answered:
		_expect(not main.room.is_dark(), "desk lamp works: the power is on")
	else:
		_expect(main.room.is_dark(), "desk lamp is dead: Mara cut the power")
	await _tap("door")
	await _wait_room("east_corridor")

	print("  -- Act 1.5-1.6 Tomas's box and the knock")
	_mark("1.6", "basement")
	await _tap("basement_door")
	await _wait_room("basement")
	await _tap("plaster")
	await _tap("crate")
	_expect(GameState.has("crate_open"), "opened Tomas's crate")
	await _tap("gap")
	await _tap("walkman")
	_expect(GameState.has("heard_day41"), "heard the Day 41 tape")
	await _tap("tuner")
	_expect(GameState.has_item("tuner"), "took Tomas's radio")
	_expect(GameState.has("knock_done"), "the knock at the delivery door")
	await _tap("stairs")
	await _wait_room("east_corridor")

	print("  -- Act 1.7 the garage")
	_mark("1.7", "garage")
	await _tap("garage_door")
	await _wait_room("garage")
	await _examine("tuner")
	_expect(not GameState.has("wrist_tape"), "the radio isn't used before the snowcat's been tried")
	await _tap("cans")
	await _tap("snowcat")
	_expect(GameState.has("tank_checked"), "the tank is empty")
	await _tap("road_doors")
	_expect(GameState.has("garage_checked"), "road blocked by a fallen pine")
	GameState.test_tune = ["H", "01", "03"]
	await _examine("tuner")
	await _wait_freq("03")
	_expect(GameState.has("wrist_tape") and main.room.player.wrist_tape.a > 0.0, "red tape on her wrist")
	_expect(int(GameState.story["FRACTURE"]) == 3, "FRACTURE = 3")
	_expect(not main.room.is_dark(), "the 03 garage is lit")
	await _tap("snowcat")
	_expect(main.room_id == "garage", "no key in the 03 snowcat")
	GameState.test_tune = ["00", "", "H"]
	_mark("1.8", "road_down")
	_mark("2.1", "main_street")
	await _use("keys", "snowcat")
	await _wait_room("main_street", 200.0)
	_expect(GameState.has("road_done"), "drove down and found home in the underpass")
	_expect(GameState.frequency == "H", "Act 1 ends at home")
	_expect(int(GameState.story["FRACTURE"]) == 4, "FRACTURE = 4 after Act 1")
	await _run_act2()


## Act 2: Main Street, June, the sheriff's office in 05, Ash Street and
## Eighty-One, the diner, 1980 and Choice 2, the mine tunnel.
func _run_act2() -> void:
	print("  -- Act 2.1 Main Street")
	await _tap("townsman")
	await _tap("couple")
	await _tap("alley")
	_expect(main.room_id == "main_street", "no reason to go into the alley yet")

	print("  -- Act 2.4a Ash Street, before the repair")
	await _tap("ash_street")
	await _wait_room("ash_street")
	await _tap("front_door")
	GameState.test_tune = ["03", ""]
	await _tap("streetlight")
	_expect(GameState.has("ash_tried") and main.room.freq == "H", "every house lit on 00–09; the dial stops at 09")
	await _tap("main_street")
	await _wait_room("main_street")

	print("  -- Act 2.2 Pike Radio")
	_mark("2.2", "pike_radio")
	await _tap("pike_door")
	await _wait_room("pike_radio")
	await _tap("june")
	_expect(GameState.has("june_diag"), "June finds the cracked crystal")
	_mark("2.3", "main_street")
	await _tap("door")
	await _wait_room("main_street")

	print("  -- Act 2.3 the sheriff's office in 05")
	GameState.test_tune = ["H", "04", "05"]
	await _tap("alley")
	await _wait_room("sheriff_office")
	_expect(GameState.frequency == "05" and int(GameState.story["FRACTURE"]) == 5, "crossed to 05, FRACTURE = 5")
	await _tap("board")
	_expect(GameState.has("read_board"), "read Cal's case board")
	await _tap("radio")
	_expect(GameState.has("radio_seen") and not GameState.has_item("crystal"), "the radio is live: can't open it")
	await _tap("cabinet")
	_expect(GameState.has("cabinet_tried") and not GameState.has("cabinet_moved"), "the cabinet scrapes and Cal stirs")
	await _tap("side_door")
	_expect(main.room_id == "sheriff_office", "won't leave without the crystal")
	await _tap("doormat")
	await _use("doormat", "cabinet")
	_expect(GameState.has("cabinet_moved"), "cabinet slid silently on the doormat")
	await _tap("plug")
	_expect(GameState.has("unplugged"), "pulled the radio's plug")
	await _tap("radio")
	_expect(GameState.has_item("crystal"), "took the crystal")
	GameState.test_tune = ["05", "H"]
	await _tap("side_door")
	await _wait_room("main_street")
	_expect(GameState.frequency == "H" and int(GameState.story["FRACTURE"]) == 6, "home through the alley, FRACTURE = 6")
	await _tap("pike_door")
	await _wait_room("pike_radio")
	await _use("crystal", "june")
	_expect(GameState.has("tuner_repaired") and not GameState.has_item("crystal"), "June fits the crystal: dial reaches 99")
	await _tap("door")
	await _wait_room("main_street")

	print("  -- Act 2.4 Ash Street, Eighty-One and the switch")
	_mark("2.4", "ash_street")
	await _tap("ash_street")
	await _wait_room("ash_street")
	GameState.test_tune = ["H", "61", "14"]
	await _tap("streetlight")
	await _wait_freq("14")
	_expect(int(GameState.story["FRACTURE"]) == 7, "the house with the lights off is 14, FRACTURE = 7")
	GameState.test_choices = [0, 0, 0]
	await _tap("front_door")
	await _wait_room("ash_kitchen")
	await _idle()
	_expect(GameState.has("met_81") and GameState.has("swapped"), "met Eighty-One; the switch happened")
	_expect(GameState.has_item("blue_tape") and not GameState.has_item("red_tape"), "the tape in Mara's pocket is blue now")
	_expect(main.room.player.wrist_tape.is_equal_approx(Color("2f63c9")), "the tape on her wrist is blue")
	await _tap("hall")
	await _wait_room("ash_street")
	await _tap("front_door")
	_expect(main.room_id == "ash_street", "won't go back into the dark house")
	GameState.test_tune = ["H"]
	await _tap("streetlight")
	await _wait_freq("H")
	_expect(int(GameState.story["FRACTURE"]) == 8, "home from 14, FRACTURE = 8")
	await _tap("main_street")
	await _wait_room("main_street")

	print("  -- Act 2.5 the Lantern")
	_mark("2.5", "diner")
	await _tap("diner_door")
	await _wait_room("diner")
	await _tap("pantry")
	_expect(not GameState.has("in_12"), "Ma won't let anyone into her pantry")
	GameState.test_choices = [0]
	await _tap("ruth")
	_expect(GameState.has("talked_ma") and GameState.has("pie_sent"), "asked Ma for pie: she goes to the front")
	GameState.test_tune = ["H", "12"]
	await _tap("pantry")
	await _wait_freq("12")
	_expect(int(GameState.story["FRACTURE"]) == 9, "1980 through the pantry, FRACTURE = 9")
	await _tap("back_door")
	_expect(main.room_id == "diner", "keys first")
	await _tap("keys")
	_expect(GameState.has_item("truck_keys"), "took Ma's truck keys, 1980")
	_mark("2.6", "snowfield_1980")
	await _tap("back_door")
	await _wait_room("snowfield_1980")

	print("  -- Act 2.6 Choice 2: ", "take Tomas" if take_tomas else "leave Tomas")
	GameState.test_choices = [0 if take_tomas else 1]
	GameState.test_tune = ["12", "H"]
	await _tap("tomas")
	if take_tomas:
		await _wait_room("pike_radio", 120.0)
		_expect(GameState.story.get("TOMAS") == "taken", "TOMAS = taken")
		_expect(main.room.tomas.visible, "Tomas is safe at June's")
		await _tap("tomas")
		await _tap("door")
		await _wait_room("main_street")
	else:
		await _wait_freq("H", 120.0)
		_expect(GameState.story.get("TOMAS") == "left", "TOMAS = left")
		_expect(main.room_id == "diner", "back in the 1983 pantry")
		await _tap("front_door")
		await _wait_room("main_street")
	_expect(GameState.has("dish_turning"), "the dish is turning; June calls")
	_expect(int(GameState.story["FRACTURE"]) == 10, "FRACTURE = 10")

	print("  -- Act 2.7 the mine tunnel")
	_mark("2.7", "mine_tunnel")
	await _tap("tunnel")
	await _wait_room("end_card", 200.0)
	_expect(GameState.has("tunnel_done") and GameState.has("act2_done"), "through the mine and up into the basement")
	_expect(GameState.has_item("flashlight_cold") and not GameState.has_light(), "the flashlight died in the cold")
	await _idle()
	_expect(int(GameState.meta.get("slices_completed", 0)) >= 1, "meta progress saved")
	_finish()


## Save in the lobby, wipe memory, press Continue, and check everything came back.
func _run_continue() -> void:
	await _tap("tomas")
	await _tap("padlock")
	await _wait_room("corridor")
	await _tap("locker")
	await _tap("lobby_door")
	await _wait_room("lobby")
	GameState.save_game()
	GameState.new_game()
	_expect(not GameState.has_item("red_tape"), "memory wiped before continuing")
	main.continue_game()
	await _wait_room("lobby")
	_expect(GameState.has_item("red_tape"), "Continue restores the inventory")
	_expect(GameState.has("p1_done") and GameState.has("locker_opened"), "Continue restores story flags")
	_expect(GameState.clock_text == "1:40", "Continue restores the clock")
	_expect(main.room.player.position.x > 0.0, "Mara is placed in the room")

	print("  -- Continue inside another frequency")
	GameState.set_flag("called_observatory")
	GameState.set_flag("crossed_once")
	GameState.frequency = "01"
	GameState.room = "east_corridor"
	GameState.save_game()
	GameState.new_game()
	main.continue_game()
	await _wait_room("east_corridor")
	_expect(GameState.frequency == "01" and main.room.freq == "01", "Continue restores frequency 01")
	_expect(not main.room.is_dark(), "the 01 east wing comes back lit")

	print("  -- Continue inside frequency 05")
	for f in ["road_done", "june_diag", "in_05"]:
		GameState.set_flag(f)
	GameState.frequency = "05"
	GameState.room = "sheriff_office"
	GameState.save_game()
	GameState.new_game()
	main.continue_game()
	await _wait_room("sheriff_office")
	_expect(GameState.frequency == "05" and main.room.freq == "05", "Continue restores frequency 05")
	_finish()


## Quick visual pass over every Act 2 room (use with --shots).
func _run_rooms() -> void:
	for f in ["road_done", "a2_arrived", "met_june", "june_diag", "in_05", "ash_seen", "diner_seen", "wrist_tape"]:
		GameState.set_flag(f)
	for it in ["blue_tape", "keys", "flashlight", "tuner"]:
		GameState.add_item(it)
	var visits := [
		["main_street", "H", "from_pike"], ["pike_radio", "H", "from_main"], ["sheriff_office", "05", "from_alley"],
		["ash_street", "H", "from_main"], ["ash_street", "14", "from_house"], ["diner", "H", "from_main"],
		["diner", "12", "from_main"], ["snowfield_1980", "12", "from_truck"],
	]
	for v in visits:
		if v[0] == "snowfield_1980":
			GameState.set_flag("choice2")
		GameState.frequency = v[1]
		main.change_room(v[0], v[2])
		await _wait_freq(v[1])
		await get_tree().create_timer(0.3).timeout
	GameState.set_flag("met_81")
	GameState.set_flag("swapped")
	GameState.frequency = "14"
	main.change_room("ash_kitchen", "from_street")
	await _wait_room("ash_kitchen")
	_finish()


## Quick visual check of the Tuner in the dark garage (use with --shots).
func _run_tuner() -> void:
	for f in ["read_note", "cabinet_empty", "fuse_installed", "chart_checked", "heard_transmission", "choice1",
			"body_done", "phone_dead", "junction_open", "phone_fixed", "office_h_seen", "heard_cassette",
			"called_observatory", "crossed_once", "back_home", "knock_done", "garage_open", "garage_key",
			"tank_checked", "road_seen", "garage_checked", "wrist_tape"]:
		GameState.set_flag(f)
	for it in ["red_tape", "keys", "flashlight", "tuner"]:
		GameState.add_item(it)
	GameState.frequency = "H"
	main.change_room("garage", "from_corridor")
	await _wait_room("garage")
	await _press_hint()
	main.room.light_off = true
	main.room.tuner_glow = true
	main.hud.tuner.open(2.6)
	await get_tree().create_timer(0.5).timeout
	var tu: Control = main.hud.tuner
	print("    tuner visible=%s size=%s rect=%s" % [tu.is_visible_in_tree(), tu.size, tu.get_global_rect()])
	_expect(tu.is_visible_in_tree() and tu.size.y > 600.0, "tuner is on screen")
	if shots_dir != "":
		await _capture("tuner_static")
		tu.value = 6.5
		await get_tree().create_timer(0.4).timeout
		await _capture("tuner_home")
	main.hud.tuner.close()
	_finish()


func _finish() -> void:
	Engine.time_scale = 1.0
	if chapters_out != "" and failures.is_empty():
		_write_chapters()
	if failures.is_empty():
		print("AUTOTEST PASS: branch=", branch)
		get_tree().quit(0)
	else:
		print("AUTOTEST FAIL: branch=%s, %d problem(s)" % [branch, failures.size()])
		for f in failures:
			print("  - ", f)
		get_tree().quit(1)


func _fail(msg: String) -> void:
	failures.append(msg)
	printerr("  FAIL: ", msg)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("    ok: ", msg)
	else:
		_fail(msg)


func _idle() -> void:
	var calm := 0
	while calm < 3:
		await get_tree().process_frame
		calm = calm + 1 if not main.is_busy() else 0


func _wait_room(id: String, timeout: float = 90.0) -> void:
	var waited := 0.0
	while main.room_id != id or main.is_busy():
		await get_tree().process_frame
		waited += get_process_delta_time()
		if waited > timeout:
			_fail("never reached room '%s' (stuck in '%s')" % [id, main.room_id])
			_finish()
			return
	await _idle()
	if shots_dir != "":
		await _capture("room_" + id)
		if id == "corridor" and _shot_n < 12:
			main.flash_hotspots()
			await get_tree().create_timer(0.3).timeout
			await _capture("hint_" + id)


# --- screenshots ---------------------------------------------------------------

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := shots_dir.path_join("%02d_%s.png" % [_shot_n, label.validate_filename()])
	_shot_n += 1
	img.save_png(path)
	print("    [shot] ", path.get_file())


func _on_line_shown(_speaker: String, text: String) -> void:
	for s in SHOT_LINES:
		if text.contains(s):
			_capture("line_" + s.left(18).replace(" ", "_"))
			return


func _watch_cards() -> void:
	while true:
		await get_tree().process_frame
		var c: Label = main.hud.card_title
		if c.visible and c.modulate.a > 0.97 and not _cards_seen.has(c.text):
			_cards_seen[c.text] = true
			await _capture("card_" + c.text.left(16).replace(" ", "_"))


## Waits until a crossing has landed on frequency `f` (the room id may not change).
func _wait_freq(f: String, timeout: float = 90.0) -> void:
	var waited := 0.0
	while main.room == null or main.room.freq != f or main.is_busy():
		await get_tree().process_frame
		waited += get_process_delta_time()
		if waited > timeout:
			_fail("never reached frequency '%s' (in '%s' on %s)" % [f, main.room_id, GameState.frequency])
			_finish()
			return
	await _idle()
	if shots_dir != "":
		await _capture("room_%s_%s" % [main.room_id, f])


func _combine(a: String, b: String) -> void:
	await _idle()
	print("  > combine ", a, " + ", b)
	if a == b:
		# The HUD treats tapping the same item twice as examining it.
		await main.run(main.hud.examine.bind(a))
	else:
		await main.run(main.hud.combine.bind(a, b))
	await _idle()


func _examine(item: String) -> void:
	await _idle()
	print("  > examine ", item)
	await main.run(main.hud.examine.bind(item))
	await _idle()


func _press_hint() -> void:
	await _idle()
	print("  > press ?")
	main.show_hint()
	await _idle()
	_expect(main.room._flash > 0.0, "the ? button gives a hint and lights up the hotspots")


## Every playable moment must have a hint for the ? button.
func _check_hint() -> void:
	if main.room == null or not main.room.shows_hud:
		return
	var h := Story.hint(main.room_id, main.room.freq)
	if h == "":
		_fail("no hint in '%s' (%s)" % [main.room_id, main.room.freq])
	else:
		print("    [hint] ", h)


func _tap(id: String) -> void:
	await _idle()
	_check_hint()
	await _idle()
	var h: Dictionary = main.room.get_hotspot(id)
	if h.is_empty() or not main.room.hotspot_enabled(h):
		_fail("hotspot '%s' not available in '%s'" % [id, main.room_id])
		return
	print("  > tap ", id)
	await main.run(main.room.interact.bind(id))
	await _idle()


## Use an inventory item on a hotspot. `allow_missing` skips items Mara doesn't have.
func _use(item: String, id: String, allow_missing: bool = false) -> void:
	if not GameState.has_item(item):
		if not allow_missing:
			_fail("tried to use '%s' but it's not in the inventory" % item)
		return
	GameState.selected_item = item
	print("  > use ", item, " on ", id)
	await _tap(id)


# --- chapters ------------------------------------------------------------------------

## Chapter `ch` starts at the next room change into `room`: record the state then.
func _mark(ch: String, room: String) -> void:
	_marks.append([ch, room])


func _on_entering(id: String, entry: String) -> void:
	if _marks.is_empty() or id != _marks[0][1]:
		return
	var ch: String = _marks.pop_front()[0]
	var d := GameState.snapshot()
	d["room"] = id
	d["entry"] = entry
	d.erase("objective")
	_snaps[ch] = d
	print("    [chapter %s] %s (%s) on %s, FRACTURE %d" % [ch, id, entry, d.frequency, int(d.story.FRACTURE)])


func _write_chapters() -> void:
	if not _marks.is_empty():
		_fail("chapters never recorded: %s" % str(_marks))
		return
	var f := FileAccess.open(chapters_out, FileAccess.WRITE)
	if f == null:
		_fail("can't write " + chapters_out)
		return
	f.store_string(JSON.stringify({"branch": branch, "answered": answered, "take_tomas": take_tomas, "chapters": _snaps}, "\t", false))
	print("  chapters written: ", _snaps.size(), " -> ", chapters_out)


## Debug chapter select: load every chapter (every choice combination) and
## check it lands in the right room, on the right frequency, with the right
## choices and a hint. Scenes that play on by themselves (the road down, the
## mine) are let run to wherever they stop.
func _run_chapters() -> void:
	# The screen itself: a tab per act, each with that act's chapters, and Back.
	var hud: Node = main.hud
	hud.chapter_select()  # not awaited: closed with Back below
	await get_tree().process_frame
	_expect(hud.chapter_layer.visible, "chapter select opens")
	for act in Chapters.ACTS:
		var tab: Button = hud._ch_tabs[act]
		tab.button_pressed = true
		tab.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_expect(hud._ch_grid.get_child_count() == Chapters.in_act(act).size(), "%s tab lists %d chapters" % [act, Chapters.in_act(act).size()])
		if shots_dir != "":
			await get_tree().create_timer(0.3).timeout
			await _capture("chapter_select_" + act)
	hud.chapter_chosen.emit({})
	await get_tree().process_frame
	_expect(not hud.chapter_layer.visible, "Back closes chapter select")

	for ch in Chapters.LIST:
		var combos: Array = [[true, true]]
		var needs := Chapters.needs(ch.id)
		if needs >= 1:
			combos = [[true, true], [false, false]]
		if needs >= 2:
			combos = [[true, true], [true, false], [false, true], [false, false]]
		for c in combos:
			var st := Chapters.state(ch.id, c[0], c[1])
			var want_room: String = st.get("room", "snowfield_1980")
			var want_freq: String = st.get("frequency", "H")
			print("  -- chapter %s %s  (answered=%s, took Tomas=%s)" % [ch.num, ch.title, c[0], c[1]])
			GameState.test_tune = ["00", "", "H"] if want_room == "road_down" else []
			var before: Node = main.room
			main.start_chapter(ch.id, c[0], c[1])
			var waited := 0.0
			while (main.room == before or main.room_id != want_room) and waited < 30.0:
				await get_tree().process_frame
				waited += get_process_delta_time()
			_expect(main.room_id == want_room, "chapter %s opens %s" % [ch.num, want_room])
			_expect(GameState.frequency == want_freq and main.room.freq == want_freq, "chapter %s is on frequency %s" % [ch.num, want_freq])
			if needs >= 1:
				_expect(GameState.story.get("ANSWERED") == c[0], "chapter %s: ANSWERED = %s" % [ch.num, c[0]])
			if needs >= 2:
				_expect(GameState.story.get("TOMAS") == ("taken" if c[1] else "left"), "chapter %s: TOMAS = %s" % [ch.num, "taken" if c[1] else "left"])
			waited = 0.0
			while main.is_busy() and waited < 200.0:
				await get_tree().process_frame
				waited += get_process_delta_time()
			_expect(not main.is_busy(), "chapter %s settles (now in %s)" % [ch.num, main.room_id])
			await _idle()
			if shots_dir != "":
				await _capture("chapter_%s_%s" % [ch.num, main.room_id])
			if main.room_id == want_room:
				_check_hint()
	_finish()
