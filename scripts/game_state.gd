extends Node
## Story state, inventory and saves. Autoloaded as `GameState`.
##
## The `story` dictionary holds the hidden variables from the story bible
## (ANSWERED, TOMAS, EIGHTY, FINALE, FRACTURE, plus SIGNOFF: the goodbye Mara
## and Tomas always said, chosen in the prologue; SWITCH: how Mara answered
## the kitchen switch; JUNE: "trusted" if Mara told June about the kitchen at
## her shop door, "check" if she only asked for a radio check; EIGHTY: Choice 3,
## "cut" or "keep" Red's channel; LETGO: what Blue asked Tomas in 1991;
## CROSSINGS: every crossing). `flags` holds every smaller
## fact the scenes need ("read_note", "fuse_installed", ...). `meta` survives
## across playthroughs: it will hold the transmission's tail lines.
##
## `frequency` is the version of Halvard Mara is standing in: "H" is home,
## "01".."99" are the others. Every crossing adds 1 to CROSSINGS. FRACTURE
## only counts the avoidable ones: making a crossing Mara has already made
## (same doorway, same two stations) or sliding off the dial in the mine.

signal changed
signal inventory_changed

const VERSION := "0.7.0"

const ITEMS := {
	"red_tape": {
		"name": "Red tape",
		"desc": "A roll of red electrical tape. I never leave home without it.",
	},
	"fuse": {
		"name": "5-amp fuse",
		"desc": "A glass fuse from the vending machine. The same kind receiver 2 takes.",
	},
	"note": {
		"name": "Folded note",
		"desc": "\"THE KNOCK IS HER. SHE'LL SAY SHE'S ME. 81.\" My handwriting. I never wrote it.",
	},
	"keys": {
		"name": "Sollen's keys",
		"desc": "Sollen's key ring. Office, booth, basement, the snowcat. Every lock on the mountain.",
	},
	"scarf": {
		"name": "Sollen's scarf",
		"desc": "Thick wool. Smells like pipe smoke and the other Sollen's aftershave.",
	},
	"flashlight_dead": {
		"name": "Flashlight (dead)",
		"desc": "The booth flashlight. The batteries inside have turned to green crust.",
	},
	"batteries": {
		"name": "Clock batteries",
		"desc": "Two D cells from the wall clock. It won't be needing them.",
	},
	"flashlight_cold": {
		"name": "Flashlight (dead)",
		"desc": "The clock batteries gave out in the cold of the mine. Dead again.",
	},
	"flashlight": {
		"name": "Flashlight",
		"desc": "Heavy, steel, and working. Light keeps me where I am. Tomas said that.",
	},
	"blue_tape": {
		"name": "Blue tape",
		"desc": "A roll of blue electrical tape. I never leave home without it.",
	},
	"doormat": {
		"name": "Doormat",
		"desc": "The sheriff's office doormat. Rubber underneath. It says WELCOME, mostly.",
	},
	"crystal": {
		"name": "Quartz crystal",
		"desc": "A crystal in a little metal can, out of Cal's base radio. The same kind as the cracked one in Tomas's radio.",
	},
	"truck_keys": {
		"name": "Truck keys",
		"desc": "Mom's truck keys, off the hook in the diner. In 1980. The rabbit's foot still has fur on it.",
	},
	"tuner": {
		"name": "Tomas's radio",
		"desc": "A field radio Tomas gutted and rebuilt. The dial runs 00 to 99. On the back, masking tape in his handwriting: HOME = 00.",
	},
	"transmit_key": {
		"name": "Transmit key",
		"desc": "TX-1's key, on its lanyard. It was in the hollow leg of Sollen's desk, where a museum finds it in 1998. Found it, I mean. Won't, now.",
	},
	"fire_axe": {
		"name": "Fire axe",
		"desc": "Out of the case by the basement door. BREAK GLASS. I didn't have to: the case was never locked.",
	},
	"station_log": {
		"name": "Tomas's notebook",
		"desc": "His notebook, out of a biscuit tin behind the boiler. September to October 1980. Day 42, and the dish drawn with arrows through it. One page torn out: HOLD IT STILL.",
	},
	"service_card": {
		"name": "Dad's service card",
		"desc": "October 1979. Across REPLACE FAILED LINK, in Dad's hand: LEFT OPEN ON PURPOSE. PARK BEFORE RESTORING. Under it, Sollen: Programme requires an uninterrupted sample.",
	},
	"chain_sheet": {
		"name": "Dad's diagram",
		"desc": "THE 2.14 CHAIN, in Dad's hand. DISH LO-FEED to jack A1. Rx-2 IF OUT to jack B3. FIELD SET OUT to jack C2. Don't route through the forward bank. Λ.L. 10/79.",
	},
	"blue_set": {
		"name": "My own radio",
		"desc": "Mine. The strap I carried into the kitchen. Eighty-One pushed it back across the floor. I'm keeping Red's on the patch: that's where her voice is.",
	},
	"revolver": {
		"name": "Sollen's revolver",
		"desc": "Sollen's old service revolver. She gave it to me handle first. In case she loses her nerve.",
	},
	"cassette_2031": {
		"name": "Cassette",
		"desc": "A copy of Ma's last night at the Lantern, March 1998. The visitor center made it for me. In 2031.",
	},
}

## Two items combined in the inventory. Key = both ids, sorted, joined by "+".
const RECIPES := {
	"batteries+flashlight_dead": {
		"result": "flashlight",
		"lines": ["Clock batteries in a flashlight. A little loose...", "Light. Okay. Light."],
	},
}

## How each frequency looks and sounds: a colour cast over everything and the
## pitch of the building's hum. Attentive players can tell where they are.
const FREQS := {
	"H": {"tint": Color(1.0, 1.0, 1.0), "hum": 1.0},
	"01": {"tint": Color(1.0, 0.92, 0.78), "hum": 1.14},
	"03": {"tint": Color(0.78, 0.86, 1.0), "hum": 0.84},
	"05": {"tint": Color(0.95, 1.0, 0.86), "hum": 1.22},
	"12": {"tint": Color(1.0, 0.86, 0.72), "hum": 0.76},
	"14": {"tint": Color(0.84, 0.82, 0.95), "hum": 1.3},
	"44": {"tint": Color(0.8, 0.86, 0.94), "hum": 1.06},
}

var story := {}
var flags := {}
var inventory: Array[String] = []
var selected_item := ""
var room := ""
var entry := ""
var clock_text := "2:12"
var clock_frozen := false
var objective := ""
var place := ""
## True once Mara pulls the main breaker: station rooms switch to red emergency light.
var emergency := false
var frequency := "H"
## Act 3.7: which turning Red is at in the dark (0 = still in the basement).
## Not saved: the room starts again from the basement stairs.
var red_turning := 0
## The year Mara is walking in, when the dish has taken her into a future
## ("2031", "2009", "1991"), or "" in tonight's 1983.
var era := ""
## Blue's pockets while the player is Red (Act 3.7): see Act3.become_red().
var stash: Array[String] = []

var meta := {"tail": [], "endings": [], "slices_completed": 0}

## Set by the automated test run.
var test_mode := false
## Test runs that only look at rooms (perf) skip their arrival scenes.
var test_skip_arrive := false
var test_choices: Array = []
## Stations the automated test picks on the Tuner dial, in order.
var test_tune: Array = []
## Screenshot runs show the real dialogue and buttons and advance on a timer.
var test_show_ui := false

var save_path := "user://save.json"
var meta_path := "user://meta.json"


func _ready() -> void:
	_load_meta()
	new_game()


func use_test_paths() -> void:
	save_path = "user://test_save.json"
	meta_path = "user://test_meta.json"
	meta = {"tail": [], "endings": [], "slices_completed": 0}


func new_game() -> void:
	story = {"ANSWERED": null, "TOMAS": null, "EIGHTY": null, "FINALE": null, "FRACTURE": 0,
		"CROSSINGS": 0, "SIGNOFF": null, "SWITCH": null, "LETGO": null, "JUNE": null}
	flags = {}
	inventory.clear()
	selected_item = ""
	room = "intro_diner"
	entry = ""
	clock_text = "2:12"
	clock_frozen = false
	objective = ""
	place = ""
	emergency = false
	frequency = "H"
	era = ""
	stash.clear()
	changed.emit()
	inventory_changed.emit()


# --- flags --------------------------------------------------------------

func has(flag: String) -> bool:
	return bool(flags.get(flag, false))


func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value
	changed.emit()


func set_story(key: String, value: Variant) -> void:
	story[key] = value
	changed.emit()


# --- inventory ----------------------------------------------------------

func has_item(id: String) -> bool:
	return id in inventory


func add_item(id: String) -> void:
	if not has_item(id):
		inventory.append(id)
		inventory_changed.emit()


func remove_item(id: String) -> void:
	inventory.erase(id)
	if selected_item == id:
		selected_item = ""
	inventory_changed.emit()


func item_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)


func item_desc(id: String) -> String:
	var d: String = ITEMS.get(id, {}).get("desc", "")
	if id == "tuner" and has("named_blue"):
		# June's roster, 1991: this is H's set. Red pencilled the H.
		d += " Under the strap, in red pencil: H. I didn't write it."
	if id == "tuner" and has("patched"):
		# Act 3: Dad's relay is in. The dial reads years.
		var y := Act3.next_future()
		d += " Since Dad's relay clicked in, there's a fourth digit: the dial reads years."
		d += (" The needle's on %s." % y) if y != "" else " The needle won't settle on anything."
	return d


func recipe(a: String, b: String) -> Dictionary:
	var pair := [a, b]
	pair.sort()
	return RECIPES.get("+".join(pair), {})


## A working light means darkness is just darkness: no crossing.
func has_light() -> bool:
	return has_item("flashlight")


# --- frequencies -------------------------------------------------------------

## Crosses to `freq` from the current room. Returns true if this frays Mara:
## she has made this exact crossing before. The way forward is always free.
func cross_to(freq: String, required: bool = false) -> bool:
	var route := "route:%s:%s>%s" % [room, frequency, freq]
	frequency = freq
	story["CROSSINGS"] = int(story.get("CROSSINGS", 0)) + 1
	var frays := flags.has(route) and not required
	flags[route] = true
	if frays:
		story["FRACTURE"] = int(story.get("FRACTURE", 0)) + 1
	changed.emit()
	return frays


## A trip through the feed cabin, into a future or back out of one. Required
## travel: it counts as a crossing, never as FRACTURE.
func travel(to_era: String) -> void:
	era = to_era
	story["CROSSINGS"] = int(story.get("CROSSINGS", 0)) + 1
	changed.emit()


## Mara climbs into the feed cabin with no future on the needle: a crossing
## for nothing, and it costs her (+2).
func cabin_fray() -> void:
	story["CROSSINGS"] = int(story.get("CROSSINGS", 0)) + 1
	story["FRACTURE"] = int(story.get("FRACTURE", 0)) + 2
	changed.emit()


## The warning due now that FRACTURE has reached 8, 12 or 14 (once each), or
## "". At 15 Mara can no longer find home's hum: the game warns three times
## before that.
func fracture_warning() -> String:
	var f := int(story.get("FRACTURE", 0))
	for level in [14, 12, 8]:
		if f >= level and not has("fracture_warn_%d" % level):
			for l in [8, 12, 14]:
				if l <= level:
					flags["fracture_warn_%d" % l] = true
			match level:
				8:
					return "Something frays. Home's hum is harder to find. (FRACTURE 8 of 15: written in Mara's notebook.)"
				12:
					return "\"I can barely hear home.\" (FRACTURE 12 of 15.)"
				14:
					return "Something frays. One more, and home won't hold. (FRACTURE 14 of 15.)"
	return ""


## Something avoidable happened in the dark (a slide in the mine): +1 FRACTURE.
func fray() -> void:
	story["FRACTURE"] = int(story.get("FRACTURE", 0)) + 1
	changed.emit()


func freq_tint(freq: String = "") -> Color:
	var f := freq if freq != "" else frequency
	return FREQS.get(f, {"tint": Color(0.9, 0.9, 0.9)}).tint


func freq_hum(freq: String = "") -> float:
	var f := freq if freq != "" else frequency
	return FREQS.get(f, {"hum": 0.95}).hum


# --- clock and objective --------------------------------------------------

func set_clock(text: String, frozen: bool = false) -> void:
	clock_text = text
	clock_frozen = frozen
	changed.emit()


func set_objective(text: String) -> void:
	objective = text
	changed.emit()


# --- saving ---------------------------------------------------------------

## Everything a save holds. Chapter select (debug) starts from these too.
func snapshot() -> Dictionary:
	return {
		"version": VERSION,
		"story": story.duplicate(true),
		"flags": flags.duplicate(true),
		"inventory": inventory.duplicate(),  # a copy: Array(inventory) would be the live list
		"room": room,
		"entry": entry,
		"clock_text": clock_text,
		"clock_frozen": clock_frozen,
		"objective": objective,
		"emergency": emergency,
		"frequency": frequency,
		"era": era,
		"stash": stash.duplicate(),
	}


func apply_snapshot(data: Dictionary) -> void:
	story = (data.get("story", {}) as Dictionary).duplicate(true)
	for k in ["ANSWERED", "TOMAS", "EIGHTY", "FINALE", "SIGNOFF", "SWITCH", "LETGO", "JUNE"]:
		if not story.has(k):
			story[k] = null
	if not story.has("CROSSINGS"):
		# A save from before v0.5, when every crossing counted as FRACTURE.
		story["CROSSINGS"] = int(story.get("FRACTURE", 0))
		story["FRACTURE"] = 0
	story["FRACTURE"] = int(story.get("FRACTURE", 0))
	story["CROSSINGS"] = int(story.get("CROSSINGS", 0))
	flags = (data.get("flags", {}) as Dictionary).duplicate(true)
	inventory.assign(data.get("inventory", []))
	selected_item = ""
	room = str(data.get("room", "intro_diner"))
	entry = str(data.get("entry", ""))
	clock_text = str(data.get("clock_text", "1:40"))
	clock_frozen = bool(data.get("clock_frozen", false))
	objective = str(data.get("objective", ""))
	emergency = bool(data.get("emergency", false))
	frequency = str(data.get("frequency", "H"))
	era = str(data.get("era", ""))
	stash.assign(data.get("stash", []))
	changed.emit()
	inventory_changed.emit()


func save_game() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(snapshot(), "\t"))


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	apply_snapshot(parsed)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func save_meta() -> void:
	var f := FileAccess.open(meta_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta, "\t"))


func _load_meta() -> void:
	if not FileAccess.file_exists(meta_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed:
			meta[k] = parsed[k]
