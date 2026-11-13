extends Room
## Debug only (autotest --autotest=lineup): the cars of each year the story
## visits. Top: 1980 (Ma's pickup, a late-'70s sedan) and 1991 (a sedan, the
## woodgrain minivan). Bottom: 2009 (abandoned in the lot) and 2031 (an
## electric crossover on charge, the visitor center's shuttle).


func setup() -> void:
	shows_hud = false
	is_story_room = false
	base_tint = Color(1, 1, 1)
	place_name = "Lineup 6"


func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 920), Color("6f7a86"))
	cv.draw_rect(Rect2(Kit.L, 330, Kit.R - Kit.L, 30), Color("4e5660"))
	cv.draw_rect(Rect2(Kit.L, 690, Kit.R - Kit.L, 30), Color("4e5660"))
	Vehicles.pickup(cv, Vector2(170, 330), 0.5, t, {"snow": 0.3})
	Vehicles.car(cv, Vector2(470, 330), 0.5, t, {"body": Color("5a6a4a")})
	EraVehicles.sedan_1991(cv, Vector2(790, 330), 0.5, t, {})
	EraVehicles.minivan_1991(cv, Vector2(1100, 330), 0.5, t, {"snow": 0.3})
	EraVehicles.suv_2009(cv, Vector2(170, 690), 0.5, t, {})
	EraVehicles.sedan_2009(cv, Vector2(460, 690), 0.5, t, {})
	EraVehicles.ev_2031(cv, Vector2(760, 690), 0.5, t, {"charging": true})
	EraVehicles.charger_2031(cv, Vector2(910, 690), 0.5, t, {"in_use": true})
	EraVehicles.shuttle_2031(cv, Vector2(1120, 690), 0.42, t, {})
	for p in [[Vector2(170, 370), "1980 pickup"], [Vector2(470, 370), "late-'70s sedan"], [Vector2(790, 370), "1991 sedan"],
			[Vector2(1100, 370), "1991 minivan"], [Vector2(170, 730), "2009 SUV, abandoned"], [Vector2(460, 730), "2009 sedan"],
			[Vector2(800, 730), "2031 EV, charging"], [Vector2(1120, 730), "2031 shuttle"]]:
		Kit.text(cv, p[0] - Vector2(110, 0), p[1], 15, Color("e8ecf0"), HORIZONTAL_ALIGNMENT_CENTER, 220.0)
