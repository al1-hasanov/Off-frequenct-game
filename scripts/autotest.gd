extends Node
## Automated playthrough of the prologue and Act 1, used for headless testing.
##
##   godot --headless --path . -- --autotest=answer
##   godot --headless --path . -- --autotest=cut
##   godot --headless --path . -- --autotest=continue
##
## It taps hotspots through the same code path as a player, checks the story
## state after each beat, and exits with code 0 on success, 1 on failure.

var main: Node
var branch := ""
var failures: Array[String] = []

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
	"lights off", "which one is me", "Plowed. Somebody", "Halvard spreads", "darkest dark", "Hold on, Mom",
]


func start(m: Node, b: String) -> void:
	main = m
	branch = b
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

	print("  -- P1 snowfield")
	await _tap("truck")
	await _tap("padlock")
	_expect(not GameState.has("p1_done"), "gate should not lock before talking to Tomas")
	await _tap("tomas")
	_expect(GameState.has("p1_talked"), "talked to Tomas")
	await _tap("padlock")
	await _wait_room("corridor")
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

	print("  -- Act 1.1 Choice 1: ", branch)
	if branch == "answer":
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
	_expect(GameState.story["ANSWERED"] == (branch == "answer"), "ANSWERED survives save/load")

	print("  -- Act 1.3 the phone")
	await _tap("door")
	await _wait_room("corridor")
	await _tap("lobby_door")
	await _wait_room("lobby")
	await _tap("front_door")
	if branch == "cut":
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
	if branch == "answer":
		_expect(not main.room.is_dark(), "desk lamp works: the power is on")
	else:
		_expect(main.room.is_dark(), "desk lamp is dead: Mara cut the power")
	await _tap("door")
	await _wait_room("east_corridor")

	print("  -- Act 1.5-1.6 Tomas's box and the knock")
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
	await _use("keys", "snowcat")
	await _wait_room("end_card", 200.0)
	_expect(GameState.has("road_done"), "drove down and found home in the underpass")
	_expect(GameState.frequency == "H", "ends at home")
	_expect(int(GameState.story["FRACTURE"]) == 4, "FRACTURE = 4")
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
	_finish()


## Quick visual check of the Tuner in the dark garage (use with --shots).
func _run_tuner() -> void:
	for f in ["called_observatory", "crossed_once", "back_home", "knock_done", "garage_open", "garage_key",
			"tank_checked", "road_seen", "garage_checked", "wrist_tape"]:
		GameState.set_flag(f)
	for it in ["red_tape", "keys", "flashlight", "tuner"]:
		GameState.add_item(it)
	GameState.frequency = "H"
	main.change_room("garage", "from_corridor")
	await _wait_room("garage")
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


func _tap(id: String) -> void:
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
