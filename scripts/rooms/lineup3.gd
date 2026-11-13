extends Room
## Debug only (autotest --autotest=lineup): the vehicles. Sollen's snowcat
## parked and on the move, Ma's pickup idling, and the county plow (at its
## real size and blown up).

var travel := 0.0


func setup() -> void:
	shows_hud = false
	is_story_room = false
	base_tint = Color(1, 1, 1)
	place_name = "Lineup 3"


func _process(delta: float) -> void:
	super(delta)
	travel += 150.0 * delta


func draw_back() -> void:
	cv.draw_rect(Rect2(Kit.L, -100, Kit.R - Kit.L, 480), Color("3f4446"))
	cv.draw_rect(Rect2(Kit.L, 380, Kit.R - Kit.L, 60), Color("2c2f30"))
	Kit.vgrad(cv, Rect2(Kit.L, 440, Kit.R - Kit.L, 400), Color("1a2442"), Color("6f7d96"))
	Vehicles.snowcat(cv, Vector2(420, 380), 1.0, t, {"snow": 0.35, "puddle": true})
	Vehicles.pickup(cv, Vector2(1000, 380), 0.6, t, {"engine": true, "lights": true, "beam": 300.0, "ruts": 200.0, "snow": 0.5})
	Vehicles.snowcat(cv, Vector2(330, 690), 0.62, t, {"moving": true, "lights": true, "driver": true, "travel": travel, "snow": 0.7})
	Vehicles.plow_far(cv, Vector2(860, 690), 2.0)
	Vehicles.plow_far(cv, Vector2(1150, 690), 0.5)


func draw_glow(ci: CanvasItem) -> void:
	Vehicles.plow_lights(ci, Vector2(860, 690), 2.0, t)
	Vehicles.plow_lights(ci, Vector2(1150, 690), 0.5, t)
