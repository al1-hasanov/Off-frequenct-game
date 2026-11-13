extends Room
## Act 2.7 — Halvard No. 2, the old mine under the mountain. The longest dark
## crossing in the game: Mara's flashlight dies in the cold, and in total
## darkness the Tuner's needle drifts. The player keeps it on home by ear
## while Mara walks. Halfway, every sound in the world stops for two seconds.

const WALK_TIME := 22.0
const SLIP_AFTER := 2.6

var progress := 0.0
var scroll := 0.0
var slip := 0.0
var silenced := false
var silence_left := 0.0
var flicker := 0.0


func setup() -> void:
	place_name = "Halvard No. 2 mine"
	floor_y = 400.0
	walk_min = 380.0
	walk_max = 420.0
	make_player(400.0, 1)


func enter(entry: String) -> void:
	entered_from = entry
	player.position = Vector2(400.0, floor_y)
	player.face(1)


func is_dark() -> bool:
	return true


func ambience() -> void:
	Audio.stop_all(0.6)
	Audio.play_loop("drip", -18.0)
	Audio.set_environment(str(name), freq)


func on_arrive() -> void:
	ambience()
	await wait(0.6)
	await mara("Rails. Timbers. Cold like a freezer.")
	# The clock batteries give out.
	for i in 3:
		light_off = true
		await wait(0.12)
		light_off = false
		await wait(0.2)
	light_off = true
	Audio.sfx("click", -8.0)
	if GameState.has_item("flashlight"):
		var at := GameState.inventory.find("flashlight")
		GameState.inventory[at] = "flashlight_cold"
		GameState.inventory_changed.emit()
	light_off = false
	await mara("No. No, no. The cold ate the batteries.")
	await mara("Total dark, a mile of it. I'm going to slide.")
	await mara("Tomas's radio. Home's between six and seven. Keep the needle on the hum, and keep walking.")
	await _hold()
	await narrate("Mara holds the needle where the hum should be until the hum comes back.")
	await mara("...What was that?")
	await mara("Everything stopped. Even my heart, I think.")
	await wait(0.4)
	await mara("A ladder. Light at the top.")
	GameState.set_flag("tunnel_done")
	main.change_room("basement", "from_tunnel")


## The minigame. Progress only counts while the needle is locked on home; let
## it drift too long and Mara slides a little way into another station.
func _hold() -> void:
	if GameState.test_mode:
		print("    [tunnel] holding the dial (simulated)")
		if GameState.test_show_ui:
			hud.tuner.open_hold(6.5, 0.0)
			tuner_glow = true
			await wait(1.2)
			hud.buttons_shown.emit("tunnel")
			await wait(0.6)
			hud.tuner.close()
		progress = 1.0
		await _silence()
		return
	tuner_glow = true
	hud.tuner.open_hold(6.5, 0.22)
	while progress < 1.0:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		if silence_left > 0.0:
			continue
		var locked := hud.tuner.locked() == "H"
		player.walking = locked
		if locked:
			progress = minf(1.0, progress + dt / WALK_TIME)
			scroll += dt * 120.0
			slip = maxf(0.0, slip - dt * 2.0)
		else:
			slip += dt
			if slip >= SLIP_AFTER:
				await _slide()
		if progress >= 0.5 and not silenced:
			await _silence()
	player.walking = false
	hud.tuner.close()
	tuner_glow = false


## Halfway: a voice like her own comes up through the rails, only the
## beginning of a word. The needle drops; then two seconds of nothing at all.
func _silence() -> void:
	silenced = true
	silence_left = 2.0
	player.walking = false
	var drift: float = hud.tuner.drift
	hud.tuner.drift = 0.0
	Audio.sfx("voice_short", -20.0, 0.92)
	hud.caption("A voice like her own comes up through the rails: only the beginning of a word. The needle drops.", 3.2)
	await wait(0.9)
	Audio.sfx("silence_hit", -10.0)
	await wait(0.4)
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master, true)
	# The same moment for players without sound: say what they can't hear.
	hud.toast("[Every sound stops. Footsteps, hiss, breath. Nothing.]")
	await wait(2.0)
	AudioServer.set_bus_mute(master, false)
	silence_left = 0.0
	hud.tuner.drift = drift


func _slide() -> void:
	slip = 0.0
	GameState.fray()
	Audio.sfx("crossing", -10.0)
	hud.glitch(0.6)
	progress = maxf(0.0, progress - 0.12)
	hud.toast("Mara slid into another station. Back to the hum, between 06 and 07.")
	hud.tuner.value = 6.5
	main.warn_fracture(2.4)


# --- drawing --------------------------------------------------------------------

func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("0a0a0c"))
	# Rock ceiling and walls.
	cv.draw_rect(Rect2(Kit.L, 100, Kit.R - Kit.L, 300), Color("2a2622"))
	for i in 40:
		var x := fposmod(i * 97.0 - scroll * 0.9, Kit.R - Kit.L) + Kit.L
		cv.draw_circle(Vector2(x, 130 + (i * 37) % 240), 10.0 + (i % 5) * 4.0, Color("231f1c"))
	# Rails.
	cv.draw_rect(Rect2(Kit.L, 398, Kit.R - Kit.L, 10), Color("3a3430"))
	for i in 60:
		var x := fposmod(i * 40.0 - scroll, Kit.R - Kit.L) + Kit.L
		cv.draw_rect(Rect2(x, 404, 26, 8), Color("4a3a2a"))
	cv.draw_line(Vector2(Kit.L, 404), Vector2(Kit.R, 404), Color("5a5a5e"), 3.0)
	# Timber sets every few metres.
	for i in 14:
		var x := fposmod(i * 220.0 - scroll, Kit.R - Kit.L + 220.0) + Kit.L - 110.0
		cv.draw_rect(Rect2(x, 110, 22, 290), Color("5a4430"))
		cv.draw_rect(Rect2(x - 40, 100, 160, 20), Color("5a4430"))
		cv.draw_rect(Rect2(x + 120, 110, 22, 290), Color("5a4430"))
	cv.draw_rect(Rect2(Kit.L, 412, Kit.R - Kit.L, 400), Color("15120f"))
