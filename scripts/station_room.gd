class_name StationRoom
extends Room
## Shared look and ambience for rooms inside Halvard Radio Observatory.

const WALL := Color("34413f")
const WALL_LOW := Color("2a3434")
const TRIM := Color("151a1c")
const FLOOR := Color("1e2427")
const FLOOR_LINE := Color("262d31")
const DOOR := Color("3d474b")


func is_station() -> bool:
	return true


## Hum while the power is on; the transistor radio until 2:14.
func ambience() -> void:
	Audio.stop_loop("wind", 0.8)
	Audio.stop_loop("drone", 0.8)
	if GameState.emergency and freq == "H":
		Audio.stop_loop("hum", 0.2)
	else:
		Audio.play_loop("hum", -24.0)
		# Every frequency's building hums at its own pitch.
		Audio.set_loop_pitch("hum", GameState.freq_hum(freq), 0.4)
	if GameState.has("radio_on") and not GameState.clock_frozen:
		Audio.play_loop("radio_music", music_db())
	else:
		Audio.stop_loop("radio_music", 0.3)


func music_db() -> float:
	return -30.0


func draw_shell(lights: Array) -> void:
	Kit.wall(self, floor_y, WALL, WALL_LOW, TRIM)
	Kit.floor_tiles(self, floor_y, FLOOR, FLOOR_LINE)
	var red := GameState.emergency and freq == "H"
	for x in lights:
		Kit.ceiling_light(self, x, floor_y, not red)
	if red:
		Kit.emergency_lamp(self, Vector2(76.0, 262.0), t)
