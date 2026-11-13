extends Room
## Debug only (autotest --autotest=lineup): every character side by side,
## standing, walking, seated, and the special poses, for checking the art.

var cast: Array[Actor] = []


func setup() -> void:
	shows_hud = false
	is_story_room = false
	base_tint = Color(1, 1, 1)
	place_name = "Lineup"
	var row1 := ["mara", "mara_1980", "eighty_one", "june", "ruth", "townswoman", "tomas"]
	for i in row1.size():
		var a := add_actor(row1[i], 110.0 + i * 170.0, 1)
		a.position.y = 330.0
		if row1[i] == "tomas":
			a.cord_tape = Color("c8322a")
		cast.append(a)
	var row2 := ["husband", "townsman", "dahl", "mara", "mara", "eighty_one", "tomas"]
	for i in row2.size():
		var a := add_actor(row2[i], 110.0 + i * 170.0, 1 if i < 5 else -1)
		a.position.y = 690.0
		cast.append(a)
	cast[10].walking = true          # Mara walking
	cast[11].walking = true
	cast[11]._phase = 1.6
	cast[11].holding_light = true    # Mara walking with the flashlight
	cast[12].walking = true          # Eighty-One walking
	cast[12]._phase = 3.2
	cast[13].walking = true          # Tomas walking
	cast[13]._phase = 4.4


func _process(delta: float) -> void:
	super(delta)
	for a in cast:
		if a.walking:
			a._phase += delta * 11.0
			a.position.x = a.position.x  # stay put: walk on the spot


func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("6f7a86"))
	cv.draw_rect(Rect2(Kit.L, 330, Kit.R - Kit.L, 30), Color("4e5660"))
	cv.draw_rect(Rect2(Kit.L, 690, Kit.R - Kit.L, 30), Color("4e5660"))
