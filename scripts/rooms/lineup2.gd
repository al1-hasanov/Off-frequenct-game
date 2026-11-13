extends Room
## Debug only (autotest --autotest=lineup): the seated and lying poses, with
## stand-in furniture at the heights the rooms use.

func setup() -> void:
	shows_hud = false
	is_story_room = false
	base_tint = Color(1, 1, 1)
	place_name = "Lineup 2"
	var e := add_actor("eighty_one", 160.0, 1)
	e.seated = true
	e.seat_y = 50.0
	var d := add_actor("dahl", 400.0, 1)
	d.seated = true
	d.seat_y = 50.0
	var t := add_actor("tomas", 640.0, -1)
	t.seated = true
	t.seat_y = 46.0
	add_actor("body", 900.0, 1)
	var s := add_actor("sollen_asleep", 300.0, 1)
	s.position.y = 330.0
	var c := add_actor("cal_asleep", 820.0, 1)
	c.position.y = 330.0


func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("6f7a86"))
	cv.draw_rect(Rect2(Kit.L, 650, Kit.R - Kit.L, 80), Color("4e5660"))
	cv.draw_rect(Rect2(Kit.L, 330, Kit.R - Kit.L, 30), Color("4e5660"))
	for x in [160.0, 400.0]:
		cv.draw_rect(Rect2(x - 40, 650 - 46, 50, 8), Color("5a4030"))
		cv.draw_rect(Rect2(x - 42, 650 - 120, 8, 120), Color("5a4030"))
	cv.draw_rect(Rect2(600, 650 - 42, 160, 10), Color("4a5a48"))
	cv.draw_rect(Rect2(150, 300, 260, 30), Color("6a4a3a"))
	cv.draw_rect(Rect2(840, 330 - 96, 200, 12), Color("6a4a3a"))
	cv.draw_rect(Rect2(764, 330 - 46, 50, 8), Color("5a4030"))
