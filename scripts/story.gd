class_name Story
extends RefCounted
## Works out Mara's current objective (and the ? button's hint) from what has
## happened so far, so every room in Acts 1 and 2 agrees on what's next.
## (The prologue rooms from v0.1 still set their objectives by hand.)

## The goodbye Mara and Tomas always said when he went off to listen, chosen
## in the prologue (story SIGNOFF): [what Mara says, what Tomas says back].
## Other frequencies have their own: Tomas in 12 remembers the next one in
## ORDER, the Mara from 07 the one after that.
const SIGNOFFS := {
	"over": ["Over and out, Tomas.", "Over and out."],
	"light": ["Leave a light on, kid.", "Always."],
	"dial": ["See you at the end of the dial.", "Save my place."],
}
const SIGNOFF_ORDER := ["over", "light", "dial"]


## The player's goodbye (H), or another world's: shift 1 = Tomas in 12, 2 = the Mara from 07.
static func signoff_key(shift: int = 0) -> String:
	var mine := str(GameState.story.get("SIGNOFF", "over"))
	if not SIGNOFFS.has(mine):
		mine = "over"
	return SIGNOFF_ORDER[(SIGNOFF_ORDER.find(mine) + shift) % 3]


## Blue's goodbye: the Mara from 07 says "Over and out, Tomas." unless that is
## the player's own (Red's), then "See you in the morning." Never the same.
static func blue_signoff() -> String:
	return "See you in the morning." if signoff_key() == "over" else "Over and out, Tomas."


## The two goodbyes as June wrote them on her 1983 radio-check roster.
static func roster_signoff(blue: bool) -> String:
	if blue:
		return "SEE YOU IN THE MORNING" if signoff_key() == "over" else "OVER AND OUT"
	return signoff_line().trim_suffix(".").to_upper()


static func signoff_line(shift: int = 0) -> String:
	return SIGNOFFS[signoff_key(shift)][0]


static func signoff_reply(shift: int = 0) -> String:
	return SIGNOFFS[signoff_key(shift)][1]


static func objective(freq: String) -> String:
	var g := GameState
	if g.has("act3"):
		return _act3_objective()
	if g.has("road_done"):
		return _act2_objective(freq)
	if not g.has("called_observatory"):
		# The opening and the prologue set their objectives scene by scene.
		return g.objective
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
	if g.has("act3"):
		return _act3_hint(room) + _science_extra(room)
	if g.has("road_done"):
		return _act2_hint(room, freq)
	match room:
		"intro_diner":
			if g.has("intro_called"):
				return "Tap the front door, on the far left, to take Tomas up the mountain."
			return "Tap the telephone on the wall, between the booths and the counter."
		"snowfield_1980":
			if g.has("p1_vanished"):
				return "Walk over to the flashlight lying in the snow, out on the right."
			if g.has("p1_talked"):
				return "Tap the padlock on the gate, on the left by the truck. It sticks: keep trying it."
			return "Drag the light onto the back of the radio, then where Tomas points."
		"intro_road", "intro_after":
			return ""
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
		if not g.has("june_door"):
			return "June wants you to stop by the shop first."
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
		if not g.has("june_door"):
			if room == "pike_radio":
				return "Tap June."
			return _go_main(room) + "Tap the door of Pike Radio & Repair: June asked you to stop by."
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
		if g.frequency == "H":
			return "Go back down to Main Street (left), then into the Lantern diner."
		return "Tap the broken streetlight and tune home: the hum between 06 and 07."
	if room != "diner":
		return _go_main(room) + "Tap the door of the Lantern diner."
	if not g.has("pie_sent"):
		return "Tap Ma. She'll go to the front for a slice of pie."
	return "Tap the pantry door on the right. In the dark the dial opens on 10–19: tune to 12 (a truck idling), then Step into the dark."


# --- Act 3 ---------------------------------------------------------------------------

## How the observatory's rooms connect, and what the door to each is called.
const MAP := {
	"dish": {"lobby": "the Lobby doors"},
	"lobby": {"dish": "the Front doors", "corridor": "the Corridor door"},
	"corridor": {"lobby": "the Lobby door", "control_room": "the Control room door", "east_corridor": "the East wing",
		"receiver_room": "the Receiver room door"},
	"control_room": {"corridor": "the Corridor door"},
	"receiver_room": {"corridor": "the Corridor door"},
	"east_corridor": {"corridor": "the Fire doors", "sollen_office": "Sollen's office", "basement": "the Basement door", "garage": "the Garage door"},
	"sollen_office": {"east_corridor": "the Door"},
	"basement": {"east_corridor": "the Stairs up"},
	"garage": {"east_corridor": "the East wing door"},
}


## "Tap X, then Y." from one room to another, or "" if already there.
static func _path(from: String, to: String) -> String:
	if from == to or not MAP.has(from):
		return ""
	var prev := {from: ""}
	var queue := [from]
	while not queue.is_empty():
		var r: String = queue.pop_front()
		if r == to:
			break
		for n in MAP[r]:
			if not prev.has(n):
				prev[n] = r
				queue.append(n)
	if not prev.has(to):
		return ""
	var steps: Array = []
	var cur := to
	while cur != from:
		var p: String = prev[cur]
		steps.push_front(MAP[p][cur])
		cur = p
	return "Tap " + ", then ".join(steps) + "."


## Go somewhere, then do something there.
static func _go3(room: String, target: String, then: String) -> String:
	var p := _path(room, target)
	return then if p == "" else p + " Then " + then.left(1).to_lower() + then.substr(1)


static func _act3_objective() -> String:
	var g := GameState
	var room := g.room
	if g.has("playing_red"):
		if g.red_turning > 0:
			return "Find your way by sound."
		if not g.has("red_mic"):
			return "The microphone cord, through the opening in the mesh."
		return "The metal door at the end of the mesh."
	match g.era:
		"2031":
			if room == "dish":
				return "The visitor center. Go in."
			if not g.has("ruth_tape"):
				return "Ask the docent about Ma."
			return "Look round the exhibits: Sollen's desk, the 2.14 study, the plaque by the door."
		"2009":
			if not g.has("lund_gate"):
				return "The gate. Mrs. Lund keeps it."
			return "The man under the dish."
		"1991":
			return ""
	if not g.has("batteries_warm"):
		return "Warm the frozen batteries on the boiler."
	if not g.has("patched"):
		if not g.has("cr3_seen"):
			return "The control room. The dish is turning."
		if not g.has("chain_known"):
			if g.has("patch_tried"):
				return "Find the patch-bay routing. Sollen writes everything in his station log."
			return "Get Tomas's radio into receiver 2: the patch bay on the transmitter."
		return "Patch the Tuner into receiver 2, the way Dad drew it."
	if not g.has("been_2031"):
		return "The feed cabin, up on the dish. Out through the lobby's front doors."
	if not g.has("chalk_2031"):
		return "Write down what you saw: the chalkboard in the control room."
	if not g.has("key_taken"):
		return "Sollen's desk: the hollow left rear leg."
	if not g.has("board_2009"):
		return "Back to the control room."
	if not g.has("been_2009"):
		return "The feed cabin. 2009."
	if not g.has("chalk_2009"):
		return "The chalkboard in the control room."
	if not g.has("tin_open"):
		return "The fresh plaster behind the boiler, in the basement."
	if not g.has("call_1991"):
		return "One test: the dish drive in the control room, with Dad's card and Sollen's key."
	if not g.has("been_1991"):
		return "One more. The feed cabin."
	if not g.has("cupboard_07"):
		return "The control room. The chart."
	if g.has("red_done") and not g.has("e81_done"):
		return "The control room."
	return ""


## The optional science clue in the room the player is standing in, while
## it's still unread (the 2031 wall has its own, in _act3_hint). Never during
## Red's dark or after it.
static func _science_extra(room: String) -> String:
	var g := GameState
	if g.has("playing_red") or g.has("red_done"):
		return ""
	if g.era == "":
		if room == "control_room" and not g.has("saw_chalk_lambda"):
			return " Optional: the old chalk under the schedule on the chalkboard."
		if room == "sollen_office" and not g.has("dad_notes_read"):
			return " Optional: the black textbook on Sollen's shelf."
	return ""


static func _act3_hint(room: String) -> String:
	var g := GameState
	if g.has("playing_red"):
		if g.red_turning > 0:
			return str(load("res://scripts/rooms/red_dark.gd").call("hint_for", g.red_turning))
		if not g.has("red_mic"):
			return "Tap the Microphone cord, through the opening in the mesh."
		return "Tap the Metal door, on the right."
	match g.era:
		"2031":
			if room == "dish":
				return "Tap the glass doors of the visitor center, on the left."
			if not g.has("ruth_tape"):
				return "Tap Cal, the docent, and ask for Ruth Lind."
			var left: Array = []
			if not g.has("knows_key"):
				left.append("Sollen's desk")
			if not g.has("anders_exhibit"):
				left.append("the 2.14 study")
			if not g.has("cal_plaque"):
				left.append("the brass plaque by the control-room door")
			var extra := "" if g.has("museum_lambda") else " Optional, before 2:14: the lettering high on the wall."
			return ("Tap " + ", ".join(left) + "." + extra) if not left.is_empty() else "Wait. It's nearly 2:14."
		"2009":
			if not g.has("lund_gate"):
				return "Tap Mrs. Lund, in the green coat at the gate."
			return "Tap the man at the dish, by the maintenance box on the right."
		"1991":
			return "Listen."
	if not g.has("batteries_warm"):
		return _go3(room, "basement", "Tap the dead flashlight in your pockets, then tap the Boiler.")
	if not g.has("patched"):
		if not g.has("cr3_seen"):
			return _go3(room, "control_room", "Look around.")
		if not g.has("chain_known"):
			if not g.has("patch_tried"):
				return _go3(room, "control_room", "Tap the Patch bay on the transmitter, on the right.")
			return _go3(room, "sollen_office", "Tap the Station log on Sollen's desk.")
		return _go3(room, "control_room", "Tap the Patch bay. Dad's diagram: DISH LO-FEED to A1, Rx-2 IF OUT to B3, FIELD SET OUT to C2.")
	if not g.has("been_2031"):
		return _go3(room, "dish", "Tap The dish, out on the right, to walk out to it and climb to the feed cabin.")
	if not g.has("chalk_2031"):
		return _go3(room, "control_room", "Tap the Chalkboard.")
	if not g.has("key_taken"):
		return _go3(room, "sollen_office", "Tap the Desk leg, at the left end of the desk.")
	if not g.has("board_2009"):
		return _go3(room, "control_room", "Look at the chalkboard.")
	if not g.has("been_2009"):
		return _go3(room, "dish", "Tap The dish, out on the right, to walk out to it and climb to the feed cabin.")
	if not g.has("chalk_2009"):
		return _go3(room, "control_room", "Look at the chalkboard.")
	if not g.has("tin_open"):
		return _go3(room, "basement", "Tap the Fresh plaster behind the boiler.")
	if not g.has("call_1991"):
		return _go3(room, "control_room", "Tap the Dish drive, on the right end of the console.")
	if not g.has("been_1991"):
		return _go3(room, "dish", "Tap The dish, out on the right, to walk out to it and climb to the feed cabin.")
	if not g.has("cupboard_07"):
		return _go3(room, "control_room", "Look around.")
	return "Listen."
