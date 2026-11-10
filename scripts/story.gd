class_name Story
extends RefCounted
## Works out Mara's current objective from what has happened so far, so every
## room in Act 1 agrees on what the player should be doing next.
## (The prologue rooms from v0.1 still set their objectives by hand.)


static func objective(freq: String) -> String:
	var g := GameState
	if g.has("road_done"):
		return ""
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
			return "The flashlight's batteries are dead. Something on this floor runs on D cells."
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
	return "It happened in the dark. Make it dark again."
