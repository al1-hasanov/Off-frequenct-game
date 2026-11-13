extends Room
## Debug only (autotest --autotest=lineup): the same people across the years,
## side by side. Page 1: Mara, Ruth and Cal from 1980 to 2031; Tomas at 13,
## 21, 24 and about 40; June in 1983 and 1991; Lise. Page 2 (page = 2): Mr.
## Dahl, the Lunds then and in 2009, the visitors of 2031, and Eighty-One in
## Act 3 with Sollen's revolver and Red's radio.

var page := 1
var cast: Array[Actor] = []

const LABELS_1 := [["1980", "1983", "1980", "1983", "1980", "1983", "2031"],
	["13", "21 (H, 1991)", "24 (12, 1991)", "2009", "1983", "1991", "1991"]]
const LABELS_2 := [["Dahl 1980", "Dahl 1983", "Mrs. Lund 1983", "Mrs. Lund 2009", "Mr. Lund 1983", "Mr. Lund 2009", "Eighty-One"],
	["2031 visitor", "2031 visitor", "Tomas walking", "Cal 2031 walking", "Lise walking", "81, aiming", "Red, in the dark"]]


func setup() -> void:
	shows_hud = false
	is_story_room = false
	base_tint = Color(1, 1, 1)
	place_name = "Lineup 4"
	var rows: Array
	if page == 1:
		rows = [["mara_1980", "mara", "ruth_1980", "ruth", "cal_1980", "cal", "cal_2031"],
			["tomas", "tomas_21", "tomas_24", "tomas_2009", "june", "june_1991", "lise_1991"]]
	else:
		rows = [["dahl_1980", "dahl", "townswoman", "lund_w_2009", "husband", "lund_h_2009", "eighty_one"],
			["visitor_a", "visitor_b", "tomas_21", "cal_2031", "lise_1991", "eighty_one", "mara"]]
	for r in 2:
		for i in 7:
			var a := add_actor(rows[r][i], 110.0 + i * 170.0, 1)
			a.position.y = 330.0 if r == 0 else 690.0
			cast.append(a)
	if page == 1:
		cast[7].cord_tape = Color("c8322a")
		cast[8].headphones_mode = "neck"
	else:
		cast[1].seated = false
		cast[6].prop = "revolver"
		cast[6].carried_radio = Color("c8322a")
		for i in [9, 10, 11]:
			cast[i].walking = true
			cast[i]._phase = i * 1.3
		cast[12].prop = "revolver_aim"
		cast[13].wrist_tape = Color("b8322c")


func _process(delta: float) -> void:
	super(delta)
	for a in cast:
		if a.walking:
			a._phase += delta * 11.0


func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("6f7a86"))
	cv.draw_rect(Rect2(Kit.L, 330, Kit.R - Kit.L, 30), Color("4e5660"))
	cv.draw_rect(Rect2(Kit.L, 690, Kit.R - Kit.L, 30), Color("4e5660"))
	var labels: Array = LABELS_1 if page == 1 else LABELS_2
	for r in 2:
		for i in 7:
			Kit.text(cv, Vector2(110.0 + i * 170.0 - 80.0, (346.0 if r == 0 else 706.0) + 4.0), str(labels[r][i]), 15,
				Color("e8ecf0"), HORIZONTAL_ALIGNMENT_CENTER, 160.0)
