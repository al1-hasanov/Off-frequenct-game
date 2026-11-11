class_name Story
extends RefCounted
## Works out Mara's current objective (and the ? button's hint) from what has
## happened so far, so every room in Acts 1 and 2 agrees on what's next.
## (The prologue rooms from v0.1 still set their objectives by hand.)


static func objective(freq: String) -> String:
	var g := GameState
	if g.has("road_done"):
		return _act2_objective(freq)
	if freq == "03":
		return "Same snowcat. Same key, I bet. Drive down to Ash Street."
	if freq == "01":
		return _in_01()
	if not g.has("crossed_once"):
		if g.story.get("ANSWERED") == true:
			return "Sollen's office, down the dark east wing: who picked up? Then Tomas's box."
		return "See who picked up in Sollen's office. It's down the dark east wing."
	if not g.has_item("flashlight"):
		if g.has_item("batteries"):
			return "Put the clock batteries in the flashlight. (Tap one, then the other.)"
		if g.has_item("flashlight_dead"):
			return "The flashlight's batteries are dead. The corridor's wall clock runs on D cells."
		return "No more dark without a light. The security booth has a flashlight."
	if not g.has_item("tuner"):
		var box: bool = g.story.get("ANSWERED") == true or g.has("heard_cassette")
		if not g.has("office_h_seen"):
			if box:
				return "Find Tomas's box in the basement. And see who picked up in Sollen's office."
			return "Get into Sollen's office. The phone rang in there."
		if box:
			return "Tomas's box. In the basement."
		return "Search Sollen's office. Somebody was in there tonight."
	if not g.has("crossed_03"):
		if g.has("garage_checked"):
			return "No road, no fuel. Use Tomas's radio here in the dark (tap it twice)."
		if g.has("garage_open"):
			return "Get the snowcat running. Ash Street is eleven miles down the mountain."
		if g.has("garage_key"):
			return "Get to Mom's house on Ash Street. The snowcat's in the garage."
		return "Get to Mom's on Ash Street. The garage key isn't on Sollen's ring."
	return ""


static func _in_01() -> String:
	var g := GameState
	if g.has("office_closed_01"):
		return "Dark. Walk back through the fire doors."
	if g.has("bulb_out"):
		if not g.has_item("keys"):
			return "Take Sollen's keys from his coat. Then shut out the light from his office."
		return "Light's still spilling out of Sollen's office. Shut his door."
	if g.has("lamp_burned"):
		if g.has_item("scarf"):
			return "Unscrew the hot bulb, using Sollen's scarf."
		return "The bulb's too hot to touch. Find something to hold it with."
	return "It happened in the dark. Make it dark again, starting with that caged lamp."


# --- hints (the ? button) ------------------------------------------------------------

## Exactly what to do next, from wherever the player is standing. Plain
## instructions rather than Mara's voice: this is the player's safety net.
static func hint(room: String, freq: String) -> String:
	var g := GameState
	if g.has("road_done"):
		return _act2_hint(room, freq)
	match room:
		"snowfield_1980":
			if not g.has("p1_talked"):
				return "Walk over to Tomas at the far right of the field and tap him."
			return "Tap the padlock on the gate, on the left next to the truck."
		"road_down":
			return "Drag the dial slowly. Home has no number: it's the low hum between 06 and 07. Then tap Step into the dark."
		"menu", "end_card", "":
			return ""
	if not g.has("fuse_installed"):
		return _prologue(room)
	if not g.has("choice1"):
		return _transmission(room)
	if not g.has("body_done"):
		return _body(room)
	if not g.has("called_observatory"):
		return _phone(room)
	if freq == "01":
		return _hint_01(room)
	if freq == "03":
		if room != "garage":
			return "Go back to the garage."
		return "Tap Sollen's keys in your pockets once, then tap the snowcat."
	if not g.has("crossed_once"):
		return _go(room, "corridor", "the main corridor") + "Tap the dark doorway marked EAST WING at the far right end. Mara will feel her way in."
	return _hint_home(room)


static func _go(room: String, target: String, label: String) -> String:
	return "" if room == target else "Go to %s. " % label


static func _prologue(room: String) -> String:
	var g := GameState
	if not g.has("read_note"):
		return _go(room, "corridor", "the main corridor") + "Tap Sollen's note, taped to the Control Room door."
	if not g.has("cabinet_empty"):
		return _go(room, "receiver_room", "the Receiver Room (main corridor, middle door)") + "Tap the spares cabinet on the left wall."
	if not g.has_item("fuse"):
		return _go(room, "corridor", "the main corridor") + "Tap the vending machine. Its display light runs on the same 5-amp fuse."
	return _go(room, "receiver_room", "the Receiver Room") + "Tap the fuse in your pockets (top right) once, then tap the fuse holder on receiver 2."


static func _transmission(room: String) -> String:
	var g := GameState
	var there := _go(room, "receiver_room", "the Receiver Room")
	if not g.has("chart_checked"):
		return there + "Tap the chart recorder."
	if not g.has("heard_transmission"):
		return there + "Tap the headphones on the desk."
	return there + "Choose: tap the microphone to answer the voice, or the main breaker on the wall to cut the power. Both paths reach the end of Act 1."


static func _body(room: String) -> String:
	var g := GameState
	if room != "control_room":
		return "Go to the Control Room (main corridor, door on the right)."
	var left: Array[String] = []
	if not g.has("inspected_wrist"):
		left.append("her wrist (the hand on the floor)")
	if not g.has("inspected_watch"):
		left.append("her watch")
	if not g.has("inspected_pocket"):
		left.append("her jacket pocket")
	if not g.has("inspected_transmitter"):
		left.append("the transmitter on the right (TX-1)")
	return "Look closely. Still to tap: " + ", ".join(left) + "."


static func _phone(room: String) -> String:
	var g := GameState
	var there := _go(room, "lobby", "the lobby (main corridor, door on the far left)")
	if not g.has("phone_dead"):
		return there + "Tap the phone in the security booth's window."
	if not g.has("junction_open"):
		return there + "The line's been cut. Tap the junction box on the lobby wall."
	if not g.has("phone_fixed"):
		if not g.has_item("red_tape"):
			return "You need your red tape. It's in your locker in the main corridor: tap the open locker next to the mop."
		return there + "Tap the red tape in your pockets once, then tap the junction box."
	if g.has("called_sheriff") and g.has("called_home"):
		return there + "Tap the phone and call the observatory's own number."
	return there + "Tap the phone and make the calls: the sheriff and home first, then the observatory's own number."


static func _hint_01(room: String) -> String:
	var g := GameState
	var office := room == "sollen_office"
	if g.has("office_closed_01"):
		return "It's dark now. Tap the fire doors on the left to walk home."
	if not g.has("lamp_burned"):
		if office:
			return "Leave through the door on the left, then tap the caged lamp on the corridor wall, near the fire doors."
		return "Tap the caged lamp on the wall, near the fire doors."
	if not g.has("bulb_out"):
		if not g.has_item("scarf"):
			if office:
				return "Tap the scarf on the coat stand. While you're here, tap his coat for his keys too."
			return "The bulb's too hot to touch. Go into Sollen's office and take the scarf from his coat stand."
		if office and not g.has_item("keys"):
			return "Tap his coat on the coat stand to take his keys. Then go back out to the lamp."
		if office:
			return "Leave through the door on the left. Then tap the scarf in your pockets once, and tap the caged lamp."
		return "Tap the scarf in your pockets once, then tap the caged lamp."
	if not g.has_item("keys"):
		if office:
			return "Tap his coat on the coat stand to take his keys."
		return "Go into Sollen's office and tap his coat for his keys. You'll want them at home."
	if office:
		return "Leave his desk lamp on. Go out through the door on the left, then tap Sollen's office door to shut it."
	return "Light is still spilling from Sollen's office. Tap his office door to shut it."


static func _hint_home(room: String) -> String:
	var g := GameState
	if not g.has_item("flashlight"):
		if g.has_item("batteries"):
			return "Tap the batteries in your pockets once, then tap the dead flashlight."
		if g.has_item("flashlight_dead"):
			return _go(room, "corridor", "the main corridor") + "Tap the round wall clock, high up between the Receiver Room and Control doors. Take its batteries."
		return _go(room, "lobby", "the lobby") + "Tap the security booth's door, at the bottom right of the booth. Sollen's keys open it."
	if not g.has("office_h_seen"):
		if room != "east_corridor":
			return _go(room, "corridor", "the main corridor") + "Tap the dark EAST WING doorway. With your flashlight on, you'll stay home."
		return "Tap Sollen's office door (H. SOLLEN · DIRECTOR). His keys open it."
	if room == "sollen_office" and not g.has("garage_key") and (g.has("heard_cassette") or g.story.get("ANSWERED") == true):
		return "Tap the desk drawer, under the middle of his desk. The garage key is in it; you'll need it later."
	if not g.has_item("tuner"):
		if not g.has("heard_cassette") and g.story.get("ANSWERED") != true:
			if room != "sollen_office":
				return "Go back into Sollen's office (east wing). Tap the cassette player on his desk."
			return "Tap the cassette player at the right end of his desk. Then try the drawer, the phone and the station log."
		if room == "basement":
			if not g.has("crate_open"):
				return "Tap the crate marked TOMAS."
			return "Tap the radio on top of the crate to take it."
		if room == "east_corridor":
			return "Tap the door marked BASEMENT."
		return "Go to the basement: in the east wing, the door marked BASEMENT. Tomas's crate is down there."
	if not g.has("garage_key"):
		if room == "sollen_office":
			return "Tap the desk drawer, under the middle of his desk. The garage key is in it."
		return "The garage key isn't on Sollen's ring. Go to his office in the east wing and tap the desk drawer."
	if room != "garage":
		if room == "east_corridor":
			return "Tap the wide door marked GARAGE at the right end of the corridor."
		return "Go to the garage: the wide door at the right end of the east wing."
	if not g.has("tank_checked"):
		return "Tap the snowcat."
	if not g.has("road_seen"):
		return "Tap the big garage doors on the right to open them."
	return "Tap Tomas's radio in your pockets twice to use it. Drag the dial to 03, where you hear a plow, then tap Step into the dark."



# --- Act 2 ---------------------------------------------------------------------------

static func _act2_objective(freq: String) -> String:
	var g := GameState
	match freq:
		"05":
			if g.has("crystal_taken"):
				return "Back out the side door into the dark alley. Then home."
			if g.has("unplugged"):
				return "The radio's dead. Unscrew its panel and take the crystal."
			if g.has("cabinet_moved"):
				return "Pull the radio's plug from the wall socket."
			if g.has_item("doormat"):
				return "Slide the doormat under the filing cabinet's feet."
			if g.has("cabinet_tried"):
				return "The cabinet scrapes. Find something soft to slide it on."
			return "Take the crystal from Cal's base radio. Don't wake him."
		"14":
			if not g.has("met_81"):
				if g.room == "ash_kitchen":
					return "Listen to her."
				return "She's inside. The front door."
			if g.room == "ash_kitchen":
				return "Get home. Out through the hall, then the streetlight."
			return "Get home: tune at the broken streetlight."
		"12":
			if g.has("choice2"):
				return "Back to the pantry. Home."
			if g.room == "snowfield_1980":
				return "Tomas, at the edge of the field."
			if not g.has_item("truck_keys"):
				return "Take Ma's truck keys from the hook by the pantry."
			return "Tomas, at the snowfield. Out the back door to the truck."
	if g.has("tunnel_done"):
		return ""
	if g.has("dish_turning"):
		return "Get to the observatory: the old mine tunnel at the end of Main Street."
	if g.has("swapped"):
		if g.has("in_12"):
			return ""
		if g.has("pie_sent"):
			return "Ma's at the pie case. The pantry: bulb out, door shut, tune to 12."
		return "Tomas is alive in 12, three years back. Ma's pantry at the diner is dark enough."
	if g.has("tuner_repaired"):
		return "Ash Street. Tune at the broken streetlight until Mom's house goes dark."
	if g.has("crystal_taken"):
		return "Take the crystal back to June at Pike Radio."
	if g.has("june_diag"):
		return "June needs the sheriff's radio crystal. The office is dark, and so is the alley."
	if g.has("ash_tried"):
		return "Tomas's dial stops at 09. June Pike's radio shop is on Main Street."
	return "Ash Street, up the hill: find the house with the lights off."


static func _act2_hint(room: String, freq: String) -> String:
	var g := GameState
	match freq:
		"05":
			return _hint_05()
		"14":
			if room == "ash_kitchen":
				if g.has("met_81"):
					return "Leave through the front hall on the left."
				return "Listen to her. Pick your questions in any order."
			if not g.has("met_81"):
				return "Tap the front door of the dark house."
			return "Tap the broken streetlight and tune home: the low hum between 06 and 07."
		"12":
			if room == "snowfield_1980":
				return "Tap Tomas, then choose: take him with you, or send him back to his sister."
			if g.has("choice2"):
				return "Tune home: the low hum between 06 and 07, in the first band."
			if not g.has_item("truck_keys"):
				return "Tap the truck keys on the hook by the pantry door."
			return "Tap the back door on the right."
	if g.has("tunnel_done"):
		return ""
	if room == "mine_tunnel":
		return "Keep the red needle between 06 and 07 with ◀ ▶ (or drag it) while Mara walks."
	if g.has("dish_turning"):
		if room == "main_street":
			return "Tap the boarded mine tunnel at the right end of Main Street."
		return "Go back to Main Street and take the mine tunnel at its right end."
	if g.has("swapped"):
		return _hint_swapped(room)
	if g.has("tuner_repaired"):
		if room == "ash_street":
			return "Tap the broken streetlight. The dial opens on stations 10–19: find 14, where the house goes dark, then Step into the dark."
		return _to_ash(room)
	if g.has("crystal_taken"):
		if room == "pike_radio":
			return "Tap June to give her the crystal."
		return _go_main(room) + "Tap the door of Pike Radio & Repair, the shop with the antenna."
	if g.has("june_diag"):
		if room == "main_street":
			return "Tap the dark alley between Pike Radio and the sheriff's office. Tune until the lock lamp lights on 05 and the office windows light up. Then Step into the dark."
		return _go_main(room) + "Tap the dark alley next to the sheriff's office."
	if g.has("ash_tried"):
		if room == "pike_radio":
			return "Tap June to show her Tomas's radio."
		return _go_main(room) + "Tap the door of Pike Radio & Repair, the shop with the antenna."
	if room == "ash_street":
		return "Tap the broken streetlight and use the radio there. Try the stations: you're looking for the house with its lights off."
	return _to_ash(room)


static func _go_main(room: String) -> String:
	return "" if room == "main_street" else "Go to Main Street. "


static func _to_ash(room: String) -> String:
	if room == "main_street":
		return "Go up to Ash Street: the sign at the far left of Main Street."
	return "Go to Ash Street: from Main Street, the sign at the far left."


static func _hint_05() -> String:
	var g := GameState
	if g.has("crystal_taken"):
		return "Tap the side door on the left. In the dark alley, tune home: the hum between 06 and 07."
	if g.has("unplugged"):
		return "Tap the base radio to unscrew its panel and take the crystal."
	if g.has("cabinet_moved"):
		return "Tap the plug in the wall socket, behind where the cabinet stood."
	if g.has_item("doormat"):
		return "Tap the doormat in your pockets once, then tap the filing cabinet."
	if not g.has("radio_seen"):
		return "Tap Cal's base radio, on the table right of his desk."
	if not g.has("cabinet_tried"):
		return "Tap the filing cabinet to the right of the radio."
	return "Tap the doormat by the front door on the right to take it."


static func _hint_swapped(room: String) -> String:
	var g := GameState
	if g.has("in_12"):
		if room == "diner":
			return "Go out the front door, on the left, to Main Street."
		return _go_main(room) + "Something's happening up on the mountain."
	if room == "ash_street":
		return "Go back down to Main Street (left), then into the Lantern diner."
	if room != "diner":
		return _go_main(room) + "Tap the door of the Lantern diner."
	if not g.has("pie_sent"):
		return "Tap Ma and ask for a slice of pie. That sends her to the front."
	return "Tap the pantry door on the right. In the dark the dial opens on 10–19: tune to 12 (a truck idling), then Step into the dark."
