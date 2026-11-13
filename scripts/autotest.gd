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
	"You're late", "I just left, Henrik", "Somehow you can still talk", "Please tell me that isn't",
	"I was going to tell you", "That means yes", "I'm locking the gate", "It knows my name", "this isn't funny",
	"They stop here, Cal", "Where did you last see him", "Long enough to turn this", "done that sentence too",
	"Eat while we do", "I hear him in here", "Put his name on it", "Twenty to two", "Thirteen forever",
	"Back in business", "It's writing by itself", "Don't let her in", "Which one are you",
	"Emergency lights", "that's me", "THE KNOCK IS HER", "I buried her Tuesday",
	"My daughter died", "Sollen's office is locked", "stopped existing",
	"The lights are on", "Ow. Hot", "Did the fuse", "Properly dark", "hum's right again",
	"green crust", "still warm", "other us", "HOME = 00", "Station 12", "use it",
	"in your pockets twice", "lights off", "which one is me", "Every light in town", "gutted with love", "Lights. Cal's lights", "Lorraine", "Not a sound", "Dark. Empty. For sale", "Eighty-One. That's how many", "Everyone's early", "Where was I", "who's feeding Biscuit", "Did you cut your hair", "You look old", "Keep him in the light", "never vanishes", "The dish is calling", "Rails. Timbers", "dish is turning", "Plowed. Somebody", "Halvard spreads", "darkest dark", "Hold on, Mom",
	# Act 3.
	"Dad used to say that", "That's Dad's writing", "He finished it", "Leaves. October", "You've got a face",
	"I still cut two slices", "points uphill", "her girl used red tape", "The sound goes", "Gone.",
	"I haven't been there yet", "Close isn't the same", "outside the line too", "I'm T.L. too", "glows in his hands",
	"still wet", "pulling it in myself", "I'll keep calling", "smells of solder", "What's left of it",
	"coast car", "Lise picked it", "That means yes", "Blue. Zero-seven. Alive", "When did I", "until the white",
	"Somebody breathes", "...Dad?", "first light since", "Hold on. I'm coming", "It was me he went to",
	"Under 1991", "Station twenty-three", "lose my nerve", "what was it all for", "burned again", "Three slow knocks",
	# v0.6.2: what Dad was listening to; Red's turnings, labelled.
	"pressed in so hard", "same capitals", "Like the A in Dad's", "Twenty years after the road", "reads physics journals",
	"Left: The Lunds", "Left: The farm report", "Left: A phone ringing",
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
		_watch_captions()
		_watch_shots()
	var watchdog := get_tree().create_timer(1500.0 if shots_dir != "" else 300.0, true, false, true)
	watchdog.timeout.connect(func() -> void:
		_fail("watchdog: test timed out in room '%s'" % main.room_id)
		_finish())
	_run.call_deferred()


func _run() -> void:
	print("AUTOTEST start: branch=", branch)
	main.change_room("menu")
	await _wait_room("intro_diner")
	if branch == "atmosphere":
		await _run_atmosphere()
		return
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
	if branch == "vehicles":
		await _run_vehicles()
		return
	if branch == "layout":
		await _run_layout()
		return
	if branch == "perf":
		await _run_perf()
		return
	if branch == "eras":
		await _run_eras()
		return
	if branch.begins_with("act3_"):
		# Just Act 3, from chapter 3.1's recorded state (act3_answer, act3_cut...).
		branch = branch.trim_prefix("act3_")
		answered = branch.begins_with("answer")
		take_tomas = branch in ["answer", "cut_take"]
		var st := Chapters.state("3.1", answered, take_tomas)
		GameState.new_game()
		GameState.apply_snapshot(st)
		main.change_room(str(st.room), str(st.entry))
		await _wait_room("basement", 120.0)
		await _run_act3()
		_finish()
		return
	if branch == "glimpses":
		await _run_glimpses()
		return
	if branch == "opening":
		# Just the opening, 1980 to 1983 (use with --shots to look at it).
		await _play_opening(1, false)
		_finish()
		return
	if branch == "lineup":
		main.change_room("lineup")
		await _wait_room("lineup")
		await get_tree().create_timer(0.4).timeout
		await _capture("lineup")
		main.change_room("lineup2")
		await _wait_room("lineup2")
		await get_tree().create_timer(0.4).timeout
		await _capture("lineup2")
		main.change_room("lineup3")
		await _wait_room("lineup3")
		await get_tree().create_timer(0.4).timeout
		await _capture("lineup3")
		for id in ["lineup4", "lineup5", "lineup6"]:
			main.change_room(id)
			await _wait_room(id)
			await get_tree().create_timer(0.4).timeout
			await _capture(id)
		_finish()
		return

	# The goodbye they always said: vary it across the branches. Two of them
	# watch the whole film after the clearing; two press Skip.
	var signoff_pick: int = {"answer": 1, "cut": 2, "answer_leave": 0, "cut_take": 1}.get(branch, 0)
	await _play_opening(signoff_pick, branch in ["cut", "cut_take"])
	await _press_hint()

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
		_expect(GameState.has("voice_tested"), "Mara proved herself to the voice with their goodbye, on air")
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
		_expect(main.room.hotspot_enabled(main.room.get_hotspot("gauze")), "something on the floor where the prints stop")
		await _tap("gauze")
		_expect(GameState.has("saw_gauze"), "burn gauze: the knocker has a burned hand (cut branch only)")
	else:
		_expect(main.room.get_hotspot("gauze").is_empty() or not main.room.hotspot_enabled(main.room.get_hotspot("gauze")), "no gauze if Mara answered")
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
	_expect(int(GameState.story["CROSSINGS"]) == 1, "crossing 1")
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
	_expect(GameState.frequency == "H" and int(GameState.story["CROSSINGS"]) == 2, "crossed home in the dark, crossing 2")
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
	_expect(GameState.frequency == "H" and int(GameState.story["CROSSINGS"]) == 2, "with a light, darkness is just darkness")
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
	_expect(int(GameState.story["CROSSINGS"]) == 3, "crossing 3")
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
	_expect(int(GameState.story["CROSSINGS"]) == 4, "crossing 4 after Act 1")
	await _run_act2()


## Act 2: Main Street, June, the sheriff's office in 05, Ash Street and
## Eighty-One, the diner, 1980 and Choice 2, the mine tunnel.
func _run_act2() -> void:
	print("  -- Act 2.1 Main Street")
	await _tap("townsman")
	await _tap("couple")
	_expect(GameState.has("met_lunds"), "the Lunds: two husbands, one coat")
	await _tap("bell")
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
	_expect(GameState.frequency == "05" and int(GameState.story["CROSSINGS"]) == 5, "crossed to 05, crossing 5")
	await _tap("board")
	_expect(GameState.has("read_board"), "read Cal's case board")
	await _notebook_checks()
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
	_expect(GameState.frequency == "H" and int(GameState.story["CROSSINGS"]) == 6, "home through the alley, crossing 6")
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
	_expect(int(GameState.story["CROSSINGS"]) == 7, "the house with the lights off is 14, crossing 7")
	# Every question in order (with the 2:05 challenge if Mara worked it out),
	# then the response to the switch: confront her if Mara answered the voice.
	var topics := 4 if GameState.has("theory_loop") else 3
	var kitchen: Array = []
	for i in topics:
		kitchen.append(0)
	kitchen.append(0 if answered else 1)
	GameState.test_choices = kitchen
	await _tap("front_door")
	await _wait_room("ash_kitchen")
	await _idle()
	_expect(GameState.has("met_81") and GameState.has("swapped"), "met Eighty-One; the switch happened")
	_expect(GameState.has("e81_gauze") and GameState.has("e81_tomas"), "her burned hand; she took a Tomas once (\"Mostly.\")")
	_expect(GameState.has("pressed_81") == GameState.has("theory_loop"), "the 2:05 challenge only with the theory")
	if answered:
		_expect(GameState.has("e81_signoff"), "Eighty-One knew the goodbye Mara said on air")
		_expect(GameState.story.get("SWITCH") == "confront" and GameState.has("saw_blue"), "confronted her: the tape is blue")
	else:
		_expect(GameState.has("kept_signoff") and not GameState.has("e81_signoff"), "she didn't hear it: Mara kept it")
		_expect(GameState.story.get("SWITCH") == "conceal", "said nothing in the kitchen")
	_expect(GameState.has_item("blue_tape") and not GameState.has_item("red_tape"), "the tape in Mara's pocket is blue now")
	_expect(main.room.player.wrist_tape.is_equal_approx(Color("2f63c9")), "the tape on her wrist is blue")
	await _tap("hall")
	await _wait_room("ash_street")
	await _tap("front_door")
	_expect(main.room_id == "ash_street", "won't go back into the dark house")
	GameState.test_tune = ["H"]
	await _tap("streetlight")
	await _wait_freq("H")
	_expect(int(GameState.story["CROSSINGS"]) == 8, "home from 14, crossing 8")
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
	_expect(GameState.has("signoff_wrong"), "Ma corrects the goodbye: this Mara remembers it differently")
	_expect(Notebook.connect_notes("signoff", "signoff_wrong") == "not_me", "notebook: a life that isn't quite mine")
	GameState.test_tune = ["H", "12"]
	await _tap("pantry")
	await _wait_freq("12")
	_expect(int(GameState.story["CROSSINGS"]) == 9, "1980 through the pantry, crossing 9")
	await _tap("back_door")
	_expect(main.room_id == "diner", "keys first")
	await _tap("keys")
	_expect(GameState.has_item("truck_keys"), "took Ma's truck keys, 1980")
	_mark("2.6", "snowfield_1980")
	await _tap("back_door")
	await _wait_room("snowfield_1980")

	print("  -- Act 2.6 Choice 2: ", "take Tomas" if take_tomas else "leave Tomas")
	# Tomas's three questions, then the choice.
	GameState.test_choices = [0, 0, 0, 0 if take_tomas else 1]
	GameState.test_tune = ["12", "H"]
	_expect(GameState.has("saw_top_button") and main.room.tomas.buttoned, "this Tomas keeps his coat buttoned up: twelve's 1980, not hers")
	await _tap("tomas")
	_expect(GameState.has("tomas_goal"), "Tomas: he came to rescue the lady on 2.14")
	if take_tomas:
		await _wait_room("pike_radio", 120.0)
		_expect(GameState.story.get("TOMAS") == "taken", "TOMAS = taken")
		_expect(main.room.tomas.visible, "Tomas is safe at June's")
		await _tap("tomas")
		await _confide_if_quiet()
		await _tap("door")
		await _wait_room("main_street")
	else:
		await _wait_freq("H", 120.0)
		_expect(GameState.story.get("TOMAS") == "left", "TOMAS = left")
		_expect(main.room_id == "diner", "back in the 1983 pantry")
		_expect(GameState.has("tomas12_goodbye"), "he answered their goodbye with someone else's")
		_expect(not main.room.trucker.visible, "Mr. Dahl's booth is empty now")
		await _tap("booths")
		await _tap("ruth")
		_expect(GameState.has("ate_pie"), "Ma made her eat")
		await _tap("front_door")
		await _wait_room("main_street")
		if GameState.story.get("SWITCH") == "conceal":
			await _tap("pike_door")
			await _wait_room("pike_radio")
			await _confide_if_quiet()
			await _tap("door")
			await _wait_room("main_street")
	_expect(GameState.has("dish_turning"), "the dish is turning; June calls")
	_expect(not main.room.couple_h2.visible, "one Mr. Lund is gone")
	await _tap("couple")
	_expect(GameState.has("lund_gone"), "Mrs. Lund: he went upstairs for a coat")
	await _tap("bell")
	_expect(int(GameState.story["FRACTURE"]) == 0, "the way forward never frays: FRACTURE 0")
	_expect(int(GameState.story["CROSSINGS"]) == 10, "crossing 10")

	print("  -- Act 2.7 the mine tunnel")
	_mark("2.7", "mine_tunnel")
	_mark("3.1", "basement")
	await _tap("tunnel")
	await _wait_room("basement", 200.0)
	_expect(GameState.has("tunnel_done") and GameState.has("act2_done") and GameState.has("act3"), "through the mine and up into the basement: Act 3")
	_expect(GameState.has_item("flashlight_cold") and not GameState.has_light(), "the flashlight died in the cold")
	await _run_act3()
	# Fair FRACTURE: only a crossing Mara has made before frays her.
	var before := int(GameState.story["FRACTURE"])
	GameState.room = "main_street"
	GameState.frequency = "H"
	_expect(GameState.cross_to("05") and int(GameState.story["FRACTURE"]) == before + 1, "crossing the alley to 05 a second time frays her")
	_expect(not GameState.cross_to("33") and int(GameState.story["FRACTURE"]) == before + 1, "a crossing she's never made doesn't")
	await _idle()
	_expect(int(GameState.meta.get("slices_completed", 0)) >= 1, "meta progress saved")
	_finish()


## Act 3, start to end. The choices differ by branch: LETGO blessed (answer,
## answer_leave) or asked (cut, cut_take); EIGHTY follow (answer), expose
## (cut) or force (answer_leave, cut_take). The exhibits in 2031 are seen in a
## different order in each half, and the cut run takes the feed cabin once
## with nothing on the needle (+2 FRACTURE).
func _run_act3() -> void:
	var g := GameState
	print("  -- Act 3.1 the 2.14 chain")
	await _use("flashlight_cold", "boiler")
	_expect(g.has("batteries_warm") and g.has_light(), "warmed the batteries on the boiler")
	await _go_tap("stairs", "east_corridor")
	await _go_tap("fire_doors", "corridor")
	await _go_tap("control_door", "control_room")
	_expect(g.has("cr3_seen"), "the control room at 2:14: the dish has turned to the horizon")
	_expect(Story.hint("control_room", g.frequency).contains("Optional: the old chalk"), "hint: the old chalk, optional, while unseen")
	await _tap("old_chalk")
	_expect(not Story.hint("control_room", g.frequency).contains("Optional"), "hint: no optional clue once the chalk is seen")
	_expect(g.has("saw_chalk_lambda") and _noted("chalk_lambda"), "the Λ nobody could rub off Sollen's board: Dad's")
	await _tap("patch_bay")
	_expect(g.has("patch_tried") and not g.has("patched"), "no routing yet: Sollen writes everything down")
	await _go_tap("door", "corridor")
	await _go_tap("east_wing", "east_corridor")
	await _go_tap("office_door", "sollen_office")
	await _tap("logbook")
	_expect(g.has("chain_known") and g.has_item("chain_sheet"), "Dad's diagram in Sollen's log: Λ.L. 10/79")
	_expect(Story.hint("sollen_office", g.frequency).contains("Optional: the black textbook"), "hint: the textbook, optional, while unread")
	await _tap("book")
	_expect(not Story.hint("sollen_office", g.frequency).contains("Optional"), "hint: no optional clue once the notes are read")
	_expect(g.has("dad_notes_read") and _noted("dad_notes") and _noted("dad_bridge"), "Dad's GRAVITATION on Sollen's shelf, his LAMBDA notes inside")
	_expect(Notebook.connect_notes("dad_bridge", "tape_lind") == "other_us", "notebook: every branch is real; other us")
	await _go_tap("door", "east_corridor")
	await _go_tap("fire_doors", "corridor")
	await _go_tap("control_door", "control_room")
	g.test_choices = [1, 0, 1, 2]
	await _tap("patch_bay")
	_expect(g.has("patched") and Act3.next_future() == "2031", "a wrong jack, then Dad's chain: the needle settles on 2031")
	await _go_tap("door", "corridor")
	await _go_tap("lobby_door", "lobby")
	await _go_tap("front_door", "dish")
	_expect(g.era == "", "outside at the dish, 1983")

	print("  -- Act 3.2 future one: 2031")
	_mark("3.2", "dish", "arrive")
	var crossings := int(g.story.CROSSINGS)
	var fracture := int(g.story.FRACTURE)
	await _go_tap("ladder", "dish")
	_expect(g.era == "2031" and g.has("been_2031"), "through the feed cabin into 2031")
	_expect(int(g.story.CROSSINGS) == crossings + 1 and int(g.story.FRACTURE) == fracture, "a trip through the cabin is a crossing, never FRACTURE")
	await _tap("visitors")
	await _go_tap("doors", "visitor_center")
	g.test_choices = [0]
	await _tap("cal")
	_expect(g.has("ruth_tape") and g.has_item("cassette_2031"), "Cal finds Ma's last night on tape and makes a copy")
	await _tap("equation")
	_expect(g.has("museum_lambda") and not g.has("silence_2031") and main.room_id == "visitor_center", "Einstein's Λ on the wall: what the dish was listening for")
	_expect(Notebook.connect_notes("museum_lambda", "dad_notes") == "dark_energy", "notebook: Dad's Λ is dark energy")
	_mark("3.3", "dish", "wake")
	var before: Node = main.room
	for id in (["transcript", "desk", "study", "plaque"] if answered else ["plaque", "study", "transcript", "desk"]):
		await _tap(id)
		if main.room != before:
			break
	await _wait_until(func() -> bool: return main.room != before and main.room_id == "dish" and g.era == "", "back from 2031")
	_expect(g.has("knows_key") and g.has("anders_exhibit") and g.has("cal_plaque"), "the desk leg, Dad's photograph, the plaque")
	_expect(g.has("silence_2031") and not g.has_item("cassette_2031") and g.has("cassette_faded"), "2:14 PM, the Silence; the cassette fades on the way back")
	_expect(Notebook.connect_notes("body_tape", "red_tape_cal") == "not_hers", "notebook: her girl used red tape; the body wore blue")

	print("  -- Act 3.3 the desk and the chalkboard")
	await _go_tap("doors", "lobby")
	await _go_tap("corridor_door", "corridor")
	await _go_tap("east_wing", "east_corridor")
	await _go_tap("office_door", "sollen_office")
	_expect(not main.room.hotspot_enabled(main.room.get_hotspot("desk_leg")) or not g.has("chalk_2031"), "the desk leg waits for the chalkboard")
	await _go_tap("door", "east_corridor")
	await _go_tap("fire_doors", "corridor")
	await _go_tap("control_door", "control_room")
	await _tap("chalkboard")
	_expect(g.has("chalk_2031") and g.has("saw_oct25"), "SILENCE: 2031, beside 2.14 RUN, OCT 25")
	await _go_tap("door", "corridor")
	await _go_tap("east_wing", "east_corridor")
	await _go_tap("office_door", "sollen_office")
	await _tap("desk_leg")
	_expect(g.has_item("transmit_key") and Act3.next_future() == "", "the key, out of the desk leg; the needle slides past 2031")
	if branch == "cut":
		await _go_tap("door", "east_corridor")
		await _go_tap("fire_doors", "corridor")
		await _go_tap("lobby_door", "lobby")
		await _go_tap("front_door", "dish")
		var f0 := int(g.story.FRACTURE)
		g.test_choices = [0]
		await _tap("ladder")
		await _idle()
		_expect(int(g.story.FRACTURE) == f0 + 2 and g.era == "", "the cabin with nothing on the needle: a trip for nothing frays her (+2)")
		await _go_tap("doors", "lobby")
		await _go_tap("corridor_door", "corridor")
	else:
		await _go_tap("door", "east_corridor")
		await _go_tap("fire_doors", "corridor")
	await _go_tap("control_door", "control_room")
	_expect(g.has("board_2009") and Act3.next_future() == "2009", "2009 on the board, in her own handwriting")

	print("  -- Act 3.4 future two: 2009")
	await _go_tap("door", "corridor")
	await _go_tap("lobby_door", "lobby")
	await _go_tap("front_door", "dish")
	_mark("3.4", "dish", "arrive")
	await _go_tap("ladder", "dish")
	_expect(g.era == "2009", "2009")
	await _tap("graffiti")
	await _tap("lunds")
	_expect(g.has("lund_count"), "the count at the lamp line: down, then up, dear")
	await _tap("tomas")
	_expect(g.has("tomas09_met"), "Tomas at forty, outside the line")
	await _tap("padlock")
	_expect(Story.hint("dish", g.frequency).contains("Optional: the papers on Tomas's hut door"), "hint: the papers on his door, optional")
	await _tap("hut_papers")
	_expect(g.has("big_rip") and _noted("big_rip"), "Tomas's door: dark energy, 1999; the Big Rip, 2003")
	await _go_tap("chute", "basement_2009")
	await _tap("light")
	await _tap("light")
	_expect(int(main.room.get("stage")) == 2, "followed his lamp to the boiler")
	_mark("3.5", "dish", "wake")
	before = main.room
	await _tap("cavity")
	await _wait_until(func() -> bool: return main.room_id == "dish" and g.era == "" and not main.is_busy(), "back from 2009")
	_expect(g.has("knows_tin") and g.has("woke_2009"), "the T.L. tin behind the boiler; the coupling glows at 2:14")

	print("  -- Act 3.5 Tomas's notebook")
	await _go_tap("doors", "lobby")
	await _go_tap("corridor_door", "corridor")
	await _go_tap("east_wing", "east_corridor")
	await _tap("axe_case")
	_expect(g.has_item("fire_axe"), "the fire axe")
	await _go_tap("basement_door", "basement")
	await _use("fire_axe", "plaster")
	_expect(g.has("wall_broken") and g.has_item("station_log") and g.has("notebook_read"), "wet plaster, the tin, Tomas's STATION LOG")
	_expect(Notebook.connect_notes("day1_whistle", "lund_whistle") == "dad_whistle", "notebook: Dad whistled down, then up")
	await _go_tap("stairs", "east_corridor")
	await _go_tap("fire_doors", "corridor")
	await _go_tap("control_door", "control_room")
	await _tap("drive")
	_expect(g.has("dish_parked"), "parked the dish")
	await _go_tap("door", "corridor")
	var cr := int(g.story.CROSSINGS)
	var fr := int(g.story.FRACTURE)
	await _tap("east_wing")
	_expect(g.has("crossed_parked") and int(g.story.CROSSINGS) == cr + 4 and int(g.story.FRACTURE) == fr, "two crossings there and back with the dish parked: required, no FRACTURE")
	await _go_tap("control_door", "control_room")
	await _tap("chart")
	_expect(g.has("strip_flat"), "the flat strip")
	await _tap("drive")
	await _tap("chart")
	_expect(g.has("experiment_done") and g.has_item("chart_strips"), "the climbing strip: they match his")
	_expect(Notebook.theories().any(func(e: Dictionary) -> bool: return e.id == "listening"), "theory: it's the dish listening")
	_expect(Notebook.connect_notes("strips", "big_rip") == "white_rip", "notebook: the white is a small Big Rip, and the dish is pulling")
	_expect(g.item_desc("tuner").contains("LIGHT = BALLAST"), "the Tuner's lid: Λ, LIGHT = BALLAST")
	_expect(g.has("call_1991") and g.has("board_1991") and Act3.next_future() == "1991", "Tomas calling from 1991; 1991 on the board")

	print("  -- Act 3.6 future three: 1991")
	await _go_tap("door", "corridor")
	await _go_tap("lobby_door", "lobby")
	await _go_tap("front_door", "dish")
	_mark("3.6", "shop_1991")
	await _go_tap("ladder", "shop_1991")
	_expect(g.has("tomas91_met") and g.era == "1991", "1991, Pike & Lind Radio")
	_expect(main.room.tomas.kind == ("tomas_21" if take_tomas else "tomas_24"), "Tomas is %s" % ("21, with June" if take_tomas else "24, with Lise"))
	await _tap("other")
	await _tap("tomas")
	_expect(Story.hint("shop_1991", g.frequency).contains("Optional: the photocopy"), "hint: the photocopy, optional")
	await _tap("photocopy")
	_expect(not Story.hint("shop_1991", g.frequency).contains("Optional"), "hint: no optional clue once it's read")
	_expect(g.has("wormhole_paper") and _noted("wormhole_paper"), "Tomas's pegboard: wormholes, time machines, 1988")
	_expect(Notebook.connect_notes("wormhole_paper", "relay") == "time_door", "notebook: Dad's relay found the way through")
	await _tap("shelves")
	await _go_tap("door", "main_street_1991")
	await _tap("news")
	await _tap("video")
	await _tap("car")
	_expect(g.has("street_done"), "the street, eight years on: his car, the white at the end")
	await _go_tap("pike_door", "shop_1991")
	await _tap("bench")
	_expect(g.has("held_light"), "held the light; he fixed it, mostly")
	var bless := branch in ["answer", "answer_leave"]
	g.test_choices = [0 if bless else 1]
	_mark("3.7", "red_dark")
	before = main.room
	await _tap("tomas")
	await _wait_until(func() -> bool: return main.room_id == "red_dark" and not main.is_busy(), "into the dark")
	_expect(g.has("roll_call") and g.story.get("LETGO") == ("blessed" if bless else "asked"), "the roll call; LETGO = %s" % ("blessed" if bless else "asked"))
	_expect(g.has("playing_red") and g.inventory.is_empty() and main.room.player.wrist_tape.is_equal_approx(Color("b8322c")), "now Red: red tape, empty pockets")

	print("  -- Act 3.7 Red")
	await _tap("coats")
	_expect(Story.hint("red_dark", g.frequency).contains("Listen"), "hint, in the basement: tap Listen")
	await _tap("listen")
	_expect(Story.hint("red_dark", g.frequency).contains("Turning 1 of 3") and Story.hint("red_dark", g.frequency).contains("ahead"), "hint, turning 1: the farm report is ahead")
	await _tap("left")
	_expect(int(main.room.get("stage")) == 1, "a wrong sound walks her back round to the stairs")
	await _tap("ahead")
	_expect(Story.hint("red_dark", g.frequency).contains("Turning 2 of 3") and Story.hint("red_dark", g.frequency).contains("on the left"), "hint, turning 2: on the left")
	await _tap("left")
	_expect(g.has("red_whistle") and int(main.room.get("stage")) == 3, "the third turning: a whistle, down then up")
	_expect(Story.hint("red_dark", g.frequency).contains("June's voice") and Story.hint("red_dark", g.frequency).contains("on the right"), "hint, turning 3: on the right, June's voice")
	await _go_tap("right", "pike_dark")
	_expect(g.frequency == "44", "Pike Radio in 44, the power out")
	g.test_choices = [1, 0]
	await _tap("batteries")
	_expect(g.has("red_lamp"), "a spark, then fat to fat: the pilot lamp")
	_mark("3.8", "dish", "wake")
	await _tap("rig")
	await _wait_until(func() -> bool: return main.room_id == "dish" and not main.is_busy(), "back to Blue")
	_expect(g.has("red_called") and g.has("red_done") and not g.has("playing_red") and g.has_item("tuner"), "Red's call goes three years back; Blue's pockets back")
	_expect(g.frequency == "H" and g.era == "", "Blue, in the feed cabin, 1983")

	print("  -- Act 3.8 Eighty-One")
	var eighty: String = {"answer": "follow", "cut": "expose"}.get(branch, "force")
	g.test_choices = {"follow": [0], "expose": [1, 0], "force": [1, 1]}[eighty]
	await _go_tap("doors", "lobby")
	await _go_tap("corridor_door", "corridor")
	await _tap("control_door")
	await _wait_room("end_card", 240.0)
	_expect(g.has("e81_told") and g.has("board_tonight"), "TONIGHT on the board; station twenty-three")
	_expect(g.story.get("EIGHTY") == eighty and g.has("act3_done"), "Choice 3: EIGHTY = %s; three knocks" % eighty)
	if eighty == "follow":
		_expect(g.has_item("revolver"), "she hands over the revolver, handle first")
	if eighty == "force":
		_expect(g.has("bank_burst") and Act3.next_future() == "", "the forward bank burst: no more futures")
	for id in ["dark_energy", "other_us", "white_rip", "time_door"]:
		_expect(g.has("theory_" + id), "theory kept to the end: " + id)
	_expect(Notebook.LINKS.size() == 12, "twelve theories to work out")


## True if Mara's notebook has the note `id` under Seen & heard.
func _noted(id: String) -> bool:
	return Notebook.seen().any(func(e: Dictionary) -> bool: return e.id == id)



## Music preferences persist independently of save games and ambience.
func _run_atmosphere() -> void:
	Audio.set_setting("music_enabled", false)
	Audio.play_loop("wind", -24.0, 0.0)
	await get_tree().process_frame
	var score: AudioStreamPlayer = Audio.get("_music")
	_expect(not score.playing, "music OFF stops its player")
	_expect(Audio.is_looping("wind"), "music OFF preserves environmental sounds")
	Audio.set_setting("music_volume", 0.37)
	Audio.save_settings()
	var cfg := ConfigFile.new()
	_expect(cfg.load(Audio.SETTINGS_PATH) == OK, "audio settings file is readable")
	_expect(not bool(cfg.get_value("audio", "music_enabled", true)), "music OFF persisted")
	_expect(is_equal_approx(float(cfg.get_value("audio", "music_volume", 0.0)), 0.37), "slider volume persisted")
	Audio.music_enabled = true
	Audio.load_settings()
	_expect(not Audio.music_enabled, "saved OFF preference reloads")
	for f in ["road_done", "a2_arrived", "met_june", "june_diag"]:
		GameState.set_flag(f)
	main.change_room("main_street", "from_pike")
	await _wait_room("main_street")
	_expect(not score.playing, "music stays OFF across room changes")
	var env: Dictionary = Audio.get("_environment")
	_expect(env.has("street_air") and env["street_air"].playing, "street has its own ambient bed")
	main.change_room("pike_radio", "from_main")
	await _wait_room("pike_radio")
	await get_tree().create_timer(2.0).timeout
	_expect(not env.has("people_murmur"), "no fake crowd murmur anywhere (v0.5)")
	_expect(not Audio.is_looping("crowd"), "legacy street crowd stops indoors")
	Audio.set_setting("music_enabled", true)
	_expect(score.playing, "music can be enabled without restarting")
	Audio.set_setting("music_volume", 0.0)
	_expect(not score.playing, "zero music volume releases playback")
	Audio.set_setting("music_volume", 0.55)
	Audio.music_context("mine_tunnel")
	_expect(not score.playing, "mine listening puzzle suppresses score")
	Audio.music_context("pike_radio")
	_expect(score.playing, "score returns after leaving mine")
	for sound in ["night_score", "street_air", "room_air", "diner_room", "radio_music"]:
		var stream: AudioStream = Audio._stream(sound, true)
		_expect(stream is AudioStreamOggVorbis and stream.loop and stream.get_length() >= 31.0, "streamed looping asset: " + sound)
	_expect(Audio._stream("night_score", true).get_length() >= 179.0, "the score is the three-minute dark ambient piece")
	main.hud.open_pause()
	_expect(get_tree().paused, "pause still pauses gameplay")
	main.hud.audio_settings.open()
	await get_tree().process_frame
	var panel: Control = main.hud.audio_settings.get_child(0).get_child(0)
	var bounds := Rect2(Vector2.ZERO, main.hud.root.size)
	_expect(bounds.encloses(panel.get_global_rect()), "settings (sound and display) fit within the viewport")
	# Display: battery saver caps the frame rate and draws at 720p; smoothing;
	# the frame counter; all saved apart from the story.
	DisplaySettings.set_setting("battery_saver", true)
	_expect(Engine.max_fps == 30 and get_tree().root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT, "battery saver: 30 fps, drawn at 720p")
	_expect(get_tree().root.msaa_2d == Viewport.MSAA_DISABLED, "battery saver turns off smoothing")
	DisplaySettings.set_setting("battery_saver", false)
	DisplaySettings.set_setting("smooth_edges", true)
	_expect(Engine.max_fps == 60 and get_tree().root.msaa_2d == Viewport.MSAA_2X, "normal: 60 fps cap, smooth edges on")
	DisplaySettings.set_setting("show_fps", true)
	await get_tree().create_timer(0.7).timeout
	_expect(main.hud.fps_label.visible and main.hud.fps_label.text.contains("fps"), "the frame counter shows")
	DisplaySettings.save_settings()
	DisplaySettings.show_fps = false
	DisplaySettings.load_settings()
	_expect(DisplaySettings.show_fps, "display settings persist")
	if shots_dir != "":
		main.hud.audio_settings._refresh()
		await _capture("audio_settings")
	DisplaySettings.set_setting("show_fps", false)
	DisplaySettings.save_settings()
	Audio.set_setting("music_enabled", false)
	_expect(not score.playing, "music toggle works while paused")
	main.hud.audio_settings.close()
	_expect(get_tree().paused, "closing audio settings preserves pause")
	main.hud.close_pause()
	_expect(not get_tree().paused, "Resume restores gameplay")
	Audio.set_setting("music_enabled", true)
	Audio.save_settings()
	_finish()


## The opening, 1980 to 1983: the Lantern, the drive, the clearing, the film,
## the locker. Ends in the corridor with the night shift starting.
func _play_opening(signoff_pick: int, skip_film: bool) -> void:
	print("  -- P1 the Lantern, 1980")
	_expect(main.room_id == "intro_diner" and main.room.phase == "ringing", "the Lantern, 12:24: the telephone's ringing")
	_expect(GameState.clock_text == "12:24", "clock reads 12:24 in the diner")
	await _tap("front_door")
	_expect(not GameState.has("intro_called"), "not out of the door before the phone")
	await _tap("tomas")
	await _tap("phone")
	_expect(GameState.has("intro_called"), "Henrik called: back up the mountain, Tomas coming")
	_expect(not main.room.tomas.buttoned, "Tomas undid the top button Ruth did up")
	_expect(main.room.player.prop == "bag", "Mara took the paper bag")
	await _press_hint()
	GameState.test_choices = [0, signoff_pick]
	_mark("P1b", "snowfield_1980")
	await _tap("front_door")
	await _wait_room("snowfield_1980", 160.0)
	print("  -- P1b the clearing")
	_expect(GameState.has("radio_fixed"), "Mara held the light while Tomas fixed the contact")
	_expect(GameState.has("p1_talked"), "they shared the song; she handed back the flashlight")
	_expect(GameState.story.get("SIGNOFF") == Story.SIGNOFF_ORDER[signoff_pick], "their goodbye is %s" % Story.SIGNOFF_ORDER[signoff_pick])
	_expect(main.room.tomas.prop == "radio_light" and not main.room.tomas.buttoned, "Tomas, radio and flashlight, coat open at the neck")
	await _press_hint()
	await _tap("padlock")
	await _tap("padlock")
	_expect(not GameState.has("p1_vanished") and main.room.tomas.visible, "the lock sticks; he's still there")
	await _tap("padlock")
	_expect(GameState.has("p1_vanished") and not main.room.tomas.visible, "the key turns, and he's gone")
	_expect(main.room.prints_to > main.room.TOMAS_X + 40.0, "his footprints run out across the clearing")
	await _press_hint()
	_mark("P2", "corridor")
	await _idle()
	_check_hint()
	print("  > tap flashlight")
	main.run(main.room.interact.bind("flashlight"))  # not awaited: the film follows
	var waited := 0.0
	while main.room_id != "intro_after" and waited < 30.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_expect(main.room_id == "intro_after", "the film after the clearing")
	_expect(GameState.has("p1_done"), "where the footprints end: TOMAS!")
	if skip_film:
		await get_tree().create_timer(1.0).timeout
		_expect(main.hud.skip_button.visible, "the film can be skipped")
		print("  > press Skip")
		main.hud.request_skip()
	await _wait_room("corridor", 400.0)
	print("  -- P2 October 14, 1983")
	_expect(GameState.has("p2_intro"), "the locker, the song down the corridor, the title")
	_expect(not main.room.get("_intro_locker"), "the locker's shut again")
	_expect(GameState.clock_text == "1:40", "clock reads 1:40 when the night shift starts")
	_expect(not main.hud.skip_button.visible, "Skip is gone once the film's over")


## Save in the lobby, wipe memory, press Continue, and check everything came back.
func _run_continue() -> void:
	GameState.test_choices = []
	await _play_opening(0, true)
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


## Act 3's places in each year they're visited, without their scenes (use
## with --shots to look at them): the dish in 1983, 2031 and 2009, and the
## rooms of each future.
func _run_eras() -> void:
	GameState.test_skip_arrive = true
	for f in ["road_done", "dish_turning", "tunnel_done", "act3", "batteries_warm", "swapped", "wrist_tape"]:
		GameState.set_flag(f)
	GameState.story["TOMAS"] = "taken"
	for it in ["blue_tape", "flashlight", "tuner"]:
		GameState.add_item(it)
	for v in ERA_VISITS:
		GameState.era = v[1]
		for f in v[3]:
			GameState.set_flag(f)
		if v.size() > 4:
			GameState.story["TOMAS"] = v[4]
		GameState.frequency = "44" if v[0] == "pike_dark" else "H"
		if v[0] in ["red_dark", "pike_dark"]:
			GameState.inventory.clear()  # Red has nothing: no light, no dial
		main.change_room(v[0], v[2])
		await _wait_room(v[0])
		await get_tree().create_timer(0.4).timeout
		if shots_dir != "":
			await _capture("era_%s_%s" % [v[0], v[1] if v[1] != "" else "1983"])
	_finish()


const ERA_VISITS := [
	["dish", "", "from_lobby", []],
	["dish", "2031", "x", []],
	["visitor_center", "2031", "x", []],
	["dish", "2009", "x", []],
	["basement_2009", "2009", "chute", []],
	["shop_1991", "1991", "x", ["coffee_1991"], "taken"],
	["main_street_1991", "1991", "x", []],
	["shop_1991", "1991", "x", [], "left"],
	["main_street_1991", "1991", "x", []],
	["red_dark", "", "x", ["playing_red"]],
	["pike_dark", "", "x", ["red_lamp"]],
	["control_room", "", "x", ["act3", "cr3_seen", "patched", "chalk_2031", "board_2009", "board_1991", "board_tonight", "red_done"]],
]


## Layout check: no wall decoration sits on top of anything the room has on
## its walls (its hotspots stand in for those), and the big windows' frames
## stay clear of their neighbours.
func _run_layout() -> void:
	var people := ["june", "cal", "ruth", "tomas", "sollen", "body", "body_face", "body_wrist", "body_pocket", "body_watch", "her"]
	for id in ["corridor", "receiver_room", "control_room", "lobby", "east_corridor", "sollen_office", "pike_radio",
			"diner", "basement", "sheriff_office", "garage"]:
		GameState.frequency = "05" if id == "sheriff_office" else "H"
		main.change_room(id)
		while main.room_id != id or main.room == null:
			await get_tree().process_frame
		await get_tree().process_frame
		var room: Room = main.room
		for prop in EnvironmentArt.prop_rects(id):
			var r: Rect2 = prop
			for h in room.hotspots:
				if str(h.id) in people:
					continue
				var hr: Rect2 = h.rect
				_expect(not r.grow(-1.0).intersects(hr.grow(-2.0)), "%s: wall prop %s clear of %s %s" % [id, r, h.id, hr])
		if id == "control_room":
			var frame: Rect2 = room.get("WIN").grow(14.0)
			for other in ["chalkboard", "transmitter"]:
				var hr: Rect2 = room.get_hotspot(other).rect
				_expect(not frame.intersects(hr.grow(-4.0)), "control room window frame clear of the %s" % other)
	_finish()


## How long each place takes to make a frame, with the frame cap off: the
## average and the slowest of 120 frames after the fade-in. Headless runs
## measure the CPU side (scripts and their drawing), not the GPU.
func _run_perf() -> void:
	GameState.test_skip_arrive = true
	GameState.add_item("flashlight")
	# Real time: idle characters redraw a dozen times a second, as in play.
	Engine.time_scale = 1.0
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	OS.low_processor_usage_mode_sleep_usec = 0
	var rows := []
	for spec in [["intro_diner", "H"], ["snowfield_1980", "H"], ["corridor", "H"], ["receiver_room", "H"], ["control_room", "H"], ["lobby", "H"],
			["east_corridor", "01"], ["sollen_office", "01"], ["basement", "H"], ["garage", "03"], ["road_down", "03"],
			["main_street", "05"], ["pike_radio", "05"], ["sheriff_office", "05"], ["ash_street", "14"],
			["ash_kitchen", "14"], ["diner", "12"], ["mine_tunnel", "05"], ["dish", "H"], ["visitor_center", "H"],
			["basement_2009", "H"], ["main_street_1991", "H"], ["shop_1991", "H"]]:
		var id: String = spec[0]
		GameState.frequency = spec[1]
		main.change_room(id)
		while main.room_id != id or main.room == null or main.is_busy():
			await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var worst := 0
		var start := Time.get_ticks_usec()
		var last := start
		for i in 120:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			worst = maxi(worst, now - last)
			last = now
		var calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var per_frame := []
		for i in 24:
			await get_tree().process_frame
			per_frame.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		print("PERF frames ", id, " ", per_frame)
		# Where the draw calls go: the people, the HUD, the rest of the room.
		var people := []
		for c in main.room.get_children():
			if c is Actor and c.visible:
				people.append(c)
				c.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		var no_people := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		main.hud.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		var no_hud := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		main.hud.visible = true
		for c in people:
			c.visible = true
		rows.append("%-16s %-3s avg %6.2f ms   slowest %6.2f ms   draw calls %5d (people %d x%d, HUD %d, room %d)   primitives %7d" % [id, spec[1],
			(last - start) / 120000.0, worst / 1000.0, calls, calls - no_people, people.size(), no_people - no_hud, no_hud, prims])
		if shots_dir != "":
			await _capture("perf_" + id)
	print("PERF")
	for r in rows:
		print("PERF " + r)
	_finish()


## The stations as the Tuner shows them, in every place Mara tunes (use with
## --shots): seasons, hours, weather, the derelict ones and the quiet ones.
## Also checks every station builds a world, and that the story's stations keep
## the snowy night.
func _run_glimpses() -> void:
	GameState.test_skip_arrive = true
	Engine.time_scale = 1.0
	for f in ["road_seen", "june_diag"]:
		GameState.set_flag(f)
	for n in 100:
		var e := Env.of("%02d" % n)
		_expect(e.season in Env.SEASONS and e.hour in ["night", "dusk", "dawn", "day"], "station %02d has a world (%s, %s)" % [n, e.season, e.hour])
		if n < 60:
			print("    [world] %02d %-6s %-5s %-9s %-8s lit=%s fire=%s moon=%s lamp=%s (%s)" % [n, e.season, e.hour, e.fall, e.state,
				e.lit, e.fire, e.moon, e.lamp_fixed, TunerUI.info("%02d" % n).sound])
	for st in ["H", "01", "03", "05", "12", "14"]:
		var e2 := Env.of(st)
		_expect(e2.story() and e2.snowy() and e2.night(), "story station %s keeps the snowy night" % st)
	_expect(Env.of("23").state == "gone" and Env.of("75").state == "gone", "the quiet ones are empty")
	var seasons := {}
	for n in range(0, 60):
		var e3 := Env.of("%02d" % n)
		if not e3.story() and e3.state != "gone":
			seasons[e3.season] = true
	_expect(seasons.size() == 4, "the dial reaches all four seasons")
	var stations := ["H", "00", "02", "04", "06", "07", "08", "09", "14", "15", "18", "26", "33", "41", "44", "57", "63"]
	if shots_dir == "":
		stations = ["H", "02", "09", "14", "63"]
	for spec in [["ash_street", "H"], ["main_street", "H"], ["garage", "H"], ["diner", "H"]]:
		GameState.frequency = spec[1]
		main.change_room(spec[0])
		await _wait_room(spec[0])
		# The night's own clock, and no stale objective in the pictures.
		GameState.set_clock("2:14")
		GameState.set_objective("")
		await get_tree().create_timer(0.5).timeout
		for st in stations:
			main.room.tuning = st
			await get_tree().create_timer(0.7).timeout
			if shots_dir != "":
				await _capture("glimpse_%s_%s" % [spec[0], st])
		main.room.tuning = ""
		await get_tree().create_timer(0.3).timeout
		_expect(main.room.env().st == "H", "%s back to its own night after tuning" % spec[0])
	_finish()


## Quick visual check of the vehicles where they live (use with --shots): the
## snowcat in the dark garage and on 03 with the plow down the road, then on
## the road down with Mara at the wheel.
func _run_vehicles() -> void:
	for f in ["read_note", "cabinet_empty", "fuse_installed", "chart_checked", "heard_transmission", "choice1",
			"body_done", "phone_dead", "junction_open", "phone_fixed", "office_h_seen", "heard_cassette",
			"called_observatory", "crossed_once", "back_home", "knock_done", "garage_open", "garage_key",
			"tank_checked", "road_seen", "garage_checked", "wrist_tape", "garage_seen"]:
		GameState.set_flag(f)
	for it in ["red_tape", "keys", "flashlight", "tuner"]:
		GameState.add_item(it)
	GameState.frequency = "H"
	main.change_room("garage", "from_corridor")
	await _wait_room("garage")
	GameState.frequency = "03"
	main.change_room("garage", "tuned")
	await _wait_freq("03")
	await _capture("garage_03_settled")
	GameState.frequency = "03"
	main.change_room("road_down")
	while main.room_id != "road_down":
		await get_tree().process_frame
	await get_tree().create_timer(2.5).timeout
	await _capture("road_down_moving")
	await get_tree().create_timer(3.0).timeout
	await _capture("road_down_moving2")
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
		main.quit_game(0)
	else:
		print("AUTOTEST FAIL: branch=%s, %d problem(s)" % [branch, failures.size()])
		for f in failures:
			print("  - ", f)
		main.quit_game(1)


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


## The opening's films: a picture of each new shot, a moment after the cut.
func _watch_shots() -> void:
	var seen := {}
	while true:
		await get_tree().process_frame
		for c in main.hud.root.get_children():
			if c is RadioFix and c.modulate.a > 0.9 and not seen.has("radiofix_%d" % c.stage):
				seen["radiofix_%d" % c.stage] = true
				await _capture("radio_fix_%d" % c.stage)
		if main.room == null or not ("shot" in main.room):
			continue
		var key := "%s_%s" % [main.room_id, main.room.get("shot")]
		if seen.has(key) or str(main.room.get("shot")) == "":
			continue
		seen[key] = true
		await get_tree().create_timer(1.6).timeout
		await _capture("shot_" + key)
		if key == "intro_road_climb":
			# The sign in the headlights, near the end of the climb.
			await get_tree().create_timer(6.8).timeout
			await _capture("shot_intro_road_sign")


## The opening's film: a picture of every caption once it's fully faded in.
func _watch_captions() -> void:
	var seen := {}
	while true:
		await get_tree().process_frame
		var c: Label = main.hud.caption_label
		if c.modulate.a > 0.97 and not seen.has(c.text):
			seen[c.text] = true
			await _capture("caption_" + c.text.left(24).replace(" ", "_"))


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


## Tap a door and wait for the next room (which may have the same id: the dish
## in another year).
func _go_tap(id: String, room: String, timeout: float = 120.0) -> void:
	var before: Node = main.room
	await _tap(id)
	await _wait_until(func() -> bool: return main.room != before and main.room_id == room and not main.is_busy(), "reach " + room, timeout)
	if shots_dir != "":
		await _capture("room_%s_%s" % [room, GameState.era if GameState.era != "" else GameState.frequency])


func _wait_until(cond: Callable, what: String, timeout: float = 160.0) -> void:
	var waited := 0.0
	while not bool(cond.call()):
		await get_tree().process_frame
		waited += get_process_delta_time()
		if waited > timeout:
			_fail("timed out waiting to %s (in '%s', era '%s')" % [what, main.room_id, GameState.era])
			_finish()
			return
	await _idle()


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

## Chapter `ch` starts at the next room change into `room` (through `entry`,
## if given): record the state then.
func _mark(ch: String, room: String, entry: String = "") -> void:
	_marks.append([ch, room, entry])


func _on_entering(id: String, entry: String) -> void:
	if _marks.is_empty() or id != _marks[0][1]:
		return
	if str(_marks[0][2]) != "" and str(_marks[0][2]) != entry:
		return
	var ch: String = _marks.pop_front()[0]
	var d := GameState.snapshot()
	d["room"] = id
	d["entry"] = entry
	if GameState.has("called_observatory") or GameState.has("road_done"):
		d.erase("objective")  # worked out from the story; before that it's set by hand
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
			var want_room: String = st.get("room", "intro_diner")
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


## The notebook after Cal's board: the right notes are there, wrong pairs
## don't connect, the right ones become theories, and the screen opens.
func _notebook_checks() -> void:
	var ids := Notebook.seen().map(func(e: Dictionary) -> String: return e.id)
	_expect(ids.has("heard_214") and ids.has("board_cb") and ids.has("board_sketch"), "notebook: 2:14 and Cal's board are written down")
	_expect(ids.has("voice_test") == answered and ids.has("gauze") == (not answered), "notebook: the Choice 1 evidence differs by branch")
	_expect(Notebook.connect_notes("body_watch", "call_cal") == "", "unrelated notes don't connect")
	if answered:
		_expect(Notebook.connect_notes("board_cb", "heard_214") == "loop", "connected the 2:05 warning to 2:14: a theory")
		_expect(Notebook.connect_notes("heard_214", "board_cb") == "known", "already worked out")
	else:
		_expect(Notebook.connect_notes("gauze", "knock_hand") == "burned", "connected the gauze to the hand at the glass")
	main.hud.open_notebook()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(main.hud.notebook_layer.visible and main.hud._nb_seen_list.get_child_count() == Notebook.seen().size(), "the notebook screen lists every note")
	if shots_dir != "":
		await get_tree().create_timer(0.3).timeout
		await _capture("notebook")
	main.hud.close_notebook()
	await get_tree().process_frame
	_expect(not main.hud.notebook_layer.visible, "the notebook closes")


## If Mara said nothing in the kitchen, she can tell June (story SWITCH).
func _confide_if_quiet() -> void:
	if GameState.story.get("SWITCH") != "conceal":
		return
	GameState.test_choices = [0]
	await _tap("june")
	_expect(GameState.story.get("SWITCH") == "confide" and GameState.has("told_june"), "told June: she remembers a Tuesday that never happened")
