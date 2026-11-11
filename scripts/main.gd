extends Node2D
## Owns the camera, the HUD and the current room, and runs every interaction.
##
## Interactions are coroutines. `run()` counts them so the room ignores taps
## while a scene is playing. Rooms change with `change_room()`, which a room
## script should call as its last statement (never awaited), because the old
## room is freed during the change.

const ROOMS := {
	"menu": "res://scripts/rooms/menu.gd",
	"snowfield_1980": "res://scripts/rooms/snowfield_1980.gd",
	"corridor": "res://scripts/rooms/corridor.gd",
	"receiver_room": "res://scripts/rooms/receiver_room.gd",
	"control_room": "res://scripts/rooms/control_room.gd",
	"lobby": "res://scripts/rooms/lobby.gd",
	"east_corridor": "res://scripts/rooms/east_corridor.gd",
	"sollen_office": "res://scripts/rooms/sollen_office.gd",
	"basement": "res://scripts/rooms/basement.gd",
	"garage": "res://scripts/rooms/garage.gd",
	"road_down": "res://scripts/rooms/road_down.gd",
	"main_street": "res://scripts/rooms/main_street.gd",
	"pike_radio": "res://scripts/rooms/pike_radio.gd",
	"sheriff_office": "res://scripts/rooms/sheriff_office.gd",
	"ash_street": "res://scripts/rooms/ash_street.gd",
	"ash_kitchen": "res://scripts/rooms/ash_kitchen.gd",
	"diner": "res://scripts/rooms/diner.gd",
	"mine_tunnel": "res://scripts/rooms/mine_tunnel.gd",
	"end_card": "res://scripts/rooms/end_card.gd",
}

## Fired as a room change begins, before the new room's arrival scene runs.
## The automated playthrough uses it to record chapter starting points.
signal entering(id: String, entry: String)

var hud: Hud
var room: Room
var room_id := ""
var busy_count := 0
var camera: Camera2D


func _ready() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	camera.make_current()
	hud = Hud.new()
	hud.main = self
	add_child(hud)

	var test := ""
	var shots := ""
	var chapters_out := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--check":
			# Compile every room script with the autoloads present, then quit.
			for id in ROOMS:
				var sc: GDScript = load(ROOMS[id])
				print("check ", id, ": ", "ok" if sc != null and sc.can_instantiate() else "FAILED")
			get_tree().quit()
			return
		if arg.begins_with("--autotest="):
			test = arg.get_slice("=", 1)
		elif arg.begins_with("--shots="):
			shots = arg.get_slice("=", 1)
		elif arg.begins_with("--chapters="):
			chapters_out = arg.get_slice("=", 1)
	if test != "":
		var tester: Node = load("res://scripts/autotest.gd").new()
		tester.set("shots_dir", shots)
		tester.set("chapters_out", chapters_out)
		add_child(tester)
		tester.call("start", self, test)
	else:
		change_room("menu")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Android back button: pause in game, quit from the title screen.
			if room_id == "menu":
				get_tree().quit()
			elif room != null and room.shows_hud:
				hud.toggle_pause()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			if room != null and room.is_story_room and not GameState.test_mode:
				GameState.save_game()


func is_busy() -> bool:
	return busy_count > 0


## Runs an interaction coroutine while blocking room input.
func run(action: Callable) -> void:
	busy_count += 1
	await action.call()
	busy_count -= 1


func change_room(id: String, entry: String = "") -> void:
	_go(id, entry)


## Mara slips into another version of the building: the same room, or another
## room, on frequency `freq`. Like change_room(), call it last and don't await it.
func cross(freq: String, id: String, entry: String = "") -> void:
	busy_count += 1
	Audio.sfx("crossing", -3.0)
	hud.glitch(1.4)
	await get_tree().create_timer(0.5).timeout
	GameState.cross_to(freq)
	busy_count -= 1
	_go(id, entry)


func _go(id: String, entry: String) -> void:
	entering.emit(id, entry)
	busy_count += 1
	if room != null:
		await hud.fade_out(0.4)
		room.queue_free()
		room = null
	var script: GDScript = load(ROOMS[id])
	var next: Room = script.new()
	next.name = id
	next.main = self
	next.hud = hud
	next.freq = GameState.frequency
	room = next
	room_id = id
	GameState.entry = entry
	GameState.selected_item = ""
	add_child(next)
	next.setup()
	next.enter(entry)
	if next.is_story_room:
		GameState.room = id
		next.objective()  # never carry the last room's objective into this one
	GameState.place = next.place_name
	hud.set_gameplay_visible(next.shows_hud)
	hud.refresh()
	hud.refresh_inventory()
	if next.is_story_room and not GameState.test_mode:
		GameState.save_game()
	await hud.fade_in(0.45)
	busy_count -= 1
	if room == next:
		run(next.on_arrive)


func start_new_game() -> void:
	GameState.new_game()
	GameState.delete_save()
	change_room("snowfield_1980")


## Debug chapter select: jump to the start of a chapter with the story state a
## full playthrough had at that moment (see scripts/chapters.gd).
func start_chapter(id: String, answered: bool, took_tomas: bool) -> void:
	var ch := Chapters.find(id)
	var st := Chapters.state(id, answered, took_tomas)
	busy_count += 1
	Audio.stop_all(0.4)
	await hud.fade_out(0.4)
	if not ch.is_empty() and not GameState.test_mode:
		await hud.card(str(ch.num), str(ch.title), 1.2)
	busy_count -= 1
	if st.is_empty():
		start_new_game()
		return
	GameState.new_game()
	GameState.apply_snapshot(st)
	_go(GameState.room, GameState.entry)


func continue_game() -> void:
	if GameState.load_game() and ROOMS.has(GameState.room):
		change_room(GameState.room, "load")
	else:
		start_new_game()


func flash_hotspots() -> void:
	if room != null:
		room.flash()


## The ? button: says exactly what to do next, then lights up everything tappable.
func show_hint() -> void:
	if room == null:
		return
	var text := Story.hint(room_id, room.freq)
	run(func() -> void:
		if text != "":
			await hud.say("HINT", text)
		room.flash())
