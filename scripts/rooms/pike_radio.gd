extends Room
## Act 2.2 — Pike Radio & Repair. June Pike at her ham rig, every radio in the
## shop talking. She finds the cracked crystal that stops Tomas's dial at 09,
## and fits the one Mara brings back from the sheriff's office.

var june: Actor
var tomas: Actor


func setup() -> void:
	place_name = "Pike Radio & Repair"
	base_tint = Color(0.95, 0.96, 0.86)
	walk_min = 110.0
	walk_max = 560.0
	make_player(140.0, 1)
	june = add_actor("june", 820.0, -1)
	tomas = add_actor("tomas", 1130.0, -1)
	tomas.seated = true
	tomas.visible = _tomas_here()
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


func ambience() -> void:
	Audio.stop_loop("hum", 0.6)
	Audio.stop_loop("wind", 0.6)
	Audio.stop_loop("crowd", 0.6)
	Audio.play_loop("scanner", -25.0)
	Audio.play_loop("shortwave", -24.0)
	Audio.play_loop("radio_music", -30.0)


func on_arrive() -> void:
	ambience()
	if entered_from == "with_tomas":
		await _with_tomas()
	elif not GameState.has("met_june"):
		GameState.set_flag("met_june")
		await wait(0.4)
		await say("JUNE", "Mara Lind. Come in out of the snow.")
		await say("JUNE", "Lit up like Christmas, all of it. And a woman on 2.14 saying the same thing for an hour.")
	objective()


func on_hotspot(id: String) -> void:
	match id:
		"door":
			Audio.sfx("shopbell", -12.0)
			main.change_room("main_street", "from_pike")
		"shelves":
			await mara("Every radio in the shop is switched on. Every one of them is talking over the others.")
		"rig":
			await mara("June's ham rig. The meters are pinned. Every band's crowded with voices.")
		"counter":
			await mara("Tubes, crystals, a soldering iron still warm.")
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
	elif _tomas_here():
		await say("JUNE", "He's fine. He ate two sandwiches and asked about my rig. I'll keep him in the light.")
	elif GameState.has("swapped"):
		await say("JUNE", "Find what you were looking for, honey?")
		await mara("Not yet.")
	else:
		await say("JUNE", "Some of those stations are quiet. Don't go to the quiet ones.")


func _diagnose() -> void:
	if GameState.has("june_diag"):
		await say("JUNE", "Crystal's cracked. You need the one from the sheriff's base radio.")
		return
	await mara("June, I need you to look at a radio.")
	await narrate("Mara sets Tomas's radio on the counter.")
	await say("JUNE", "Well. That's a field radio somebody gutted with love.")
	await say("JUNE", "Tomas built this? Thirteen years old.")
	await narrate("June unscrews the back, holds a crystal up to her lamp.")
	await say("JUNE", "There's your trouble. Cracked crystal. That's why your dial dies above 09.")
	await say("JUNE", "You're a station, honey. Somebody knocked your dial.")
	await mara("Can you fix it?")
	await say("JUNE", "Not with anything I've got. The only crystal in town that'd fit is in the sheriff's base radio.")
	await say("JUNE", "Cal won't miss it till Monday. But it's locked up tight, and Cal's out on calls.")
	await say("JUNE", "Stay out of the dark, Mara. If you can't, know where you're going.")
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
	await mara("I'm coming back.")
	GameState.set_flag("dish_turning")
	await wait(0.4)
	Audio.sfx("powerup", -10.0)
	await say("JUNE", "Honey. Look out the window. The dish up on the mountain. It's turning.")
	await say("JUNE", "Whole band's lit up. Whoever's up there, it's for you.")
	await mara("The road's eleven miles. But the old mine runs right under the mountain. Halvard Number 2.")


# --- drawing ------------------------------------------------------------------------

func draw_back() -> void:
	Kit.wall(self, floor_y, Color("4a5048"), Color("3a403a"), Color("1f2420"))
	draw_rect(Rect2(Kit.L, floor_y, Kit.R - Kit.L, 400), Color("3a3028"))
	for i in 20:
		draw_line(Vector2(Kit.L + i * 120.0, floor_y), Vector2(Kit.L + i * 120.0 - 60, 760), Color(0, 0, 0, 0.15), 2.0)
	Kit.door(self, Rect2(30, 340, 92, 310), Color("4a5258"))
	_shelves()
	_rig()
	_cot()


func _shelves() -> void:
	var r := Rect2(150, 240, 330, 260)
	draw_rect(r, Color("2a241e"))
	for row in 3:
		var y := r.position.y + 10 + row * 84
		draw_rect(Rect2(r.position.x, y + 72, r.size.x, 8), Color("4a3a2a"))
		for k in 4:
			var x := r.position.x + 12 + k * 80
			var body: Color = [Color("6a4a30"), Color("3a3a3e"), Color("8a6a40"), Color("2e4a3a")][(row + k) % 4]
			draw_rect(Rect2(x, y + 22, 66, 50), body)
			var glow := 0.6 + 0.4 * sin(t * (1.3 + k * 0.4) + row)
			draw_rect(Rect2(x + 8, y + 30, 34, 12), Color(1.0, 0.68, 0.3, glow))
			draw_circle(Vector2(x + 54, y + 52), 6.0, Color("1a1a1a"))


func _rig() -> void:
	draw_rect(Rect2(870, 470, 280, 20), Color("4a3a2a"))
	draw_rect(Rect2(884, 384, 240, 88), Color("2a2c30"))
	for k in 3:
		var x := 900.0 + k * 76.0
		draw_rect(Rect2(x, 396, 60, 36), Color("e8e0c0"))
		var a := -0.8 + 0.25 * sin(t * (3.0 + k)) + 1.2
		draw_line(Vector2(x + 30, 428), Vector2(x + 30, 428) + Vector2(sin(a), -cos(a)) * 26.0, Color("8a1d1d"), 2.0)
	for k in 6:
		draw_circle(Vector2(906 + k * 38, 452), 8.0, Color("1a1a1a"))
	draw_line(Vector2(1110, 384), Vector2(1110, 0), Color("1a1a1a"), 3.0)
	draw_rect(Rect2(1040, 330, 70, 50), Color("3a3a3e"))
	draw_circle(Vector2(1075, 355), 18.0, Color("2a2a2e"))


func _cot() -> void:
	draw_rect(Rect2(1050, 600, 190, 16), Color("4a5a48"))
	draw_line(Vector2(1060, 616), Vector2(1060, 650), Color("2a2a2a"), 4.0)
	draw_line(Vector2(1230, 616), Vector2(1230, 650), Color("2a2a2a"), 4.0)
	draw_rect(Rect2(1180, 584, 54, 18), Color("d8d0c0"))


func _draw_counter(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(590, 556, 430, 14), Color("6a4a30"))
	ci.draw_rect(Rect2(600, 570, 410, 80), Color("54392a"))
	ci.draw_rect(Rect2(620, 584, 370, 52), Color("4a3224"))
	for k in 4:
		ci.draw_rect(Rect2(626 + k * 90, 526, 50, 30), Color("3a3a3e"))
		ci.draw_rect(Rect2(632 + k * 90, 532, 26, 8), Color(1.0, 0.7, 0.35, 0.8))
