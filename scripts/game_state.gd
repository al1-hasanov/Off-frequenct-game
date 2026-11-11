extends Node
## Story state, inventory and saves. Autoloaded as `GameState`.
##
## The `story` dictionary holds the hidden variables from the story bible
## (ANSWERED, TOMAS, EIGHTY, FINALE, FRACTURE). `flags` holds every smaller
## fact the scenes need ("read_note", "fuse_installed", ...). `meta` survives
## across playthroughs: it will hold the transmission's tail lines.
##
## `frequency` is the version of Halvard Mara is standing in: "H" is home,
## "01".."99" are the others. Every crossing adds 1 to FRACTURE.

signal changed
signal inventory_changed

const VERSION := "0.3.0"

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
		"desc": "An army field radio Tomas gutted and rebuilt. The dial runs 00 to 99. On the back, masking tape in his handwriting: HOME = 00.",
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

var meta := {"tail": [], "endings": [], "slices_completed": 0}

## Set by the automated test run.
var test_mode := false
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
	story = {"ANSWERED": null, "TOMAS": null, "EIGHTY": null, "FINALE": null, "FRACTURE": 0}
	flags = {}
	inventory.clear()
	selected_item = ""
	room = "snowfield_1980"
	entry = ""
	clock_text = "2:12"
	clock_frozen = false
	objective = ""
	place = ""
	emergency = false
	frequency = "H"
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
	return ITEMS.get(id, {}).get("desc", "")


func recipe(a: String, b: String) -> Dictionary:
	var pair := [a, b]
	pair.sort()
	return RECIPES.get("+".join(pair), {})


## A working light means darkness is just darkness: no crossing.
func has_light() -> bool:
	return has_item("flashlight")


# --- frequencies -------------------------------------------------------------

func cross_to(freq: String) -> void:
	frequency = freq
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

func save_game() -> void:
	var data := {
		"version": VERSION,
		"story": story,
		"flags": flags,
		"inventory": inventory,
		"room": room,
		"entry": entry,
		"clock_text": clock_text,
		"clock_frozen": clock_frozen,
		"objective": objective,
		"emergency": emergency,
		"frequency": frequency,
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	story = parsed.get("story", story)
	story["FRACTURE"] = int(story.get("FRACTURE", 0))
	flags = parsed.get("flags", {})
	inventory.assign(parsed.get("inventory", []))
	selected_item = ""
	room = str(parsed.get("room", "snowfield_1980"))
	entry = str(parsed.get("entry", ""))
	clock_text = str(parsed.get("clock_text", "1:40"))
	clock_frozen = bool(parsed.get("clock_frozen", false))
	objective = str(parsed.get("objective", ""))
	emergency = bool(parsed.get("emergency", false))
	frequency = str(parsed.get("frequency", "H"))
	changed.emit()
	inventory_changed.emit()
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
