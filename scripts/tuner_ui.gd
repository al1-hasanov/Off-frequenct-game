class_name TunerUI
extends Control
## Tomas's radio: a backlit dial Mara drags (or nudges with ◀ ▶) through the
## static until a station locks. Each station is another version of Halvard,
## heard through the speaker. Home is not marked on the dial.
##
## Stations come in bands of ten (00–09, 10–19 ... 90–99). Until June Pike
## replaces the cracked crystal (Act 2), only the first band works.
##
## While a station is locked, the room behind the panel shows a glimpse of that
## frequency (see Room.tuning). The room decides what happens when Mara tries
## to step through; see Hud.tune(). The mine tunnel uses "hold" mode instead:
## the needle drifts and the player keeps it on home.

signal picked(station: String)
signal tuned(station: String)

## The stations the story needs. Everything else comes from POOL by number.
const FIXED := {
	"00": {"sound": "carrier", "caption": "Nothing. A flat tone, like a dead line."},
	"01": {"sound": "snore", "caption": "Snoring. Sollen, asleep in his office."},
	"02": {"sound": "rain", "caption": "Rain. It never rains up here this late in the year."},
	"03": {"sound": "plow", "caption": "A plow. Somebody's clearing the road."},
	"04": {"sound": "radio_music", "caption": "KHLV. Tonight's song, a beat behind."},
	"05": {"sound": "scanner", "caption": "A police scanner, and somebody snoring under it."},
	"06": {"sound": "wind", "caption": "Wind. Wind through a door somebody left open."},
	"H": {"sound": "hum", "caption": "That hum. That's... mine. That's home."},
	"07": {"sound": "breath", "caption": "Breathing. Close. Too close."},
	"08": {"sound": "knock", "caption": "Knocking. Three, then two."},
	"09": {"sound": "ring", "caption": "A phone ringing in an empty room."},
	"12": {"sound": "engine", "caption": "A truck idling in the snow. A boy laughing. It sounds like 1980."},
	"14": {"sound": "wind", "caption": "Wind through an empty house. Nobody home."},
}
const POOL := [
	["kettle", "A kettle whistling. Nobody's taking it off."],
	["bell", "Church bells. At two in the morning."],
	["barking", "A dog barking, far off."],
	["rain", "Rain on a tin roof."],
	["radio_music", "Music. Tonight's song, slowed right down."],
	["crowd", "A crowd murmuring. A whole street of people, outside."],
	["typewriter", "A typewriter. Somebody working late."],
	["siren", "Sirens. Somewhere, something's burning."],
	["ring", "A phone ringing in an empty room."],
	["knock", "Knocking. Three, then two."],
	["breath", "Breathing. Close."],
	["snore", "Somebody snoring."],
	["plow", "A plow, a long way off."],
	["engine", "An engine idling."],
	["drone", "A low groan, like the dish turning."],
]
const QUIET_CAPTION := "Nothing. Not static. Nothing at all. One of the quiet ones."
const LOCK := 0.16
const HOLD_LOCK := 0.26
const MAX := 9.9

var value := 0.0
var band := 0
## The highest band the dial can reach: 0 until the crystal is replaced.
var max_band := 0
## Hold mode (the mine tunnel): the needle drifts, there's no step-through button.
var hold := false
var drift := 0.0
var _drift_dir := 1.0
var _drift_t := 0.0
var _dragging := false
var _playing := ""
var _hit_stop := 0.0
var _t := 0.0
var _last_locked := "-"
var _btn_left: Button
var _btn_right: Button
var _btn_band_down: Button
var _btn_band_up: Button
var _btn_step: Button
var _btn_off: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_btn_left = _button("◀", func() -> void: _nudge(-0.1))
	_btn_right = _button("▶", func() -> void: _nudge(0.1))
	_btn_band_down = _button("−10", func() -> void: _set_band(band - 1))
	_btn_band_up = _button("+10", func() -> void: _set_band(band + 1))
	_btn_step = _button("Step into the dark", func() -> void:
		if locked() != "":
			picked.emit(locked()))
	_btn_off = _button("Switch off", func() -> void: picked.emit(""))
	resized.connect(_layout)
	_layout()


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	add_child(b)
	return b


func _panel() -> Rect2:
	var w := 1040.0
	var h := 292.0
	return Rect2((size.x - w) * 0.5, size.y - h - 14.0, w, h)


func _dial() -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + 36.0, p.position.y + 60.0, p.size.x - 72.0, 118.0)


func _layout() -> void:
	var p := _panel()
	var y := p.position.y + 196.0
	_btn_left.position = Vector2(p.position.x + 36.0, y)
	_btn_left.size = Vector2(86, 76)
	_btn_right.position = Vector2(p.position.x + 130.0, y)
	_btn_right.size = Vector2(86, 76)
	_btn_band_down.position = Vector2(p.position.x + 232.0, y)
	_btn_band_down.size = Vector2(86, 76)
	_btn_band_up.position = Vector2(p.position.x + 326.0, y)
	_btn_band_up.size = Vector2(86, 76)
	_btn_off.size = Vector2(220, 76)
	_btn_off.position = Vector2(p.end.x - 36.0 - 220.0, y)
	_btn_step.size = Vector2(320, 76)
	_btn_step.position = Vector2(_btn_off.position.x - 14.0 - 320.0, y)


func _scale_x(v: float) -> float:
	var d := _dial()
	return d.position.x + 34.0 + v / 10.0 * (d.size.x * 0.76)


# --- stations -----------------------------------------------------------------------

static func station_value(st: String) -> float:
	return 6.5 if st == "H" else float(int(st) % 10)


static func station_band(st: String) -> int:
	return 0 if st == "H" else int(st) / 10


static func is_quiet(st: String) -> bool:
	if st == "H" or FIXED.has(st):
		return false
	var n := int(st)
	return n >= 60 or n in [23, 31, 47, 52]


static func info(st: String) -> Dictionary:
	if FIXED.has(st):
		return FIXED[st]
	if is_quiet(st):
		return {"sound": "", "caption": QUIET_CAPTION}
	var e: Array = POOL[(int(st) * 7 + 3) % POOL.size()]
	return {"sound": e[0], "caption": e[1]}


# --- state ------------------------------------------------------------------------

func open(start: float = 0.0, start_band: int = 0) -> void:
	max_band = 9 if GameState.has("tuner_repaired") else 0
	band = clampi(start_band, 0, max_band)
	value = clampf(start, 0.0, MAX)
	hold = false
	drift = 0.0
	visible = true
	_playing = ""
	_last_locked = "-"
	_btn_band_down.visible = max_band > 0
	_btn_band_up.visible = max_band > 0
	_btn_step.visible = true
	_btn_off.visible = true
	Audio.stop_all(0.3)
	Audio.play_loop("static", -14.0, 0.2)
	_update_audio()


## The mine tunnel: no buttons but the fine-tune ones, and a drifting needle.
func open_hold(start: float, drift_speed: float) -> void:
	open(start, 0)
	hold = true
	drift = drift_speed
	_btn_band_down.visible = false
	_btn_band_up.visible = false
	_btn_step.visible = false
	_btn_off.visible = false


func close() -> void:
	visible = false
	_dragging = false
	hold = false
	drift = 0.0
	Audio.stop_loop("static", 0.3)
	if _playing != "":
		Audio.stop_loop(_playing, 0.3)
	_playing = ""
	if _last_locked != "-":
		_last_locked = "-"
		tuned.emit("")


## [station, distance] for the station nearest the needle in the current band.
func nearest() -> Array:
	var i := clampi(int(round(value)), 0, 9)
	var best := "%02d" % (band * 10 + i)
	var best_d := absf(value - float(i))
	if band == 0 and absf(value - 6.5) < best_d:
		best = "H"
		best_d = absf(value - 6.5)
	return [best, best_d]


func locked() -> String:
	var n := nearest()
	return n[0] if float(n[1]) <= (HOLD_LOCK if hold else LOCK) else ""


func caption() -> String:
	if _hit_stop > 0.0:
		return "The needle won't go past 09. Tomas soldered a stop on it." if max_band == 0 else "That's the end of the band. Try −10 / +10."
	var st := locked()
	if st != "":
		return info(st).caption
	return "Something under the static..." if float(nearest()[1]) < 0.4 else "Static."


## Waits for Mara to step through a station (or switch off: ""). The automated
## test picks from GameState.test_tune instead, sweeping the needle on screen.
func pick() -> String:
	if GameState.test_mode:
		var st := "" if GameState.test_tune.is_empty() else str(GameState.test_tune.pop_front())
		print("    [tune] -> ", st if st != "" else "(switch off)")
		if st != "":
			band = station_band(st)
		if GameState.test_show_ui and st != "":
			var tw := create_tween()
			tw.tween_property(self, "value", station_value(st), 1.4).set_trans(Tween.TRANS_SINE)
			await tw.finished
			await get_tree().create_timer(0.5).timeout
			var hud := get_parent().get_parent() as Hud
			if hud != null:
				hud.buttons_shown.emit("tuner_" + st)
			await get_tree().create_timer(0.4).timeout
		else:
			if st != "":
				value = station_value(st)
			await get_tree().process_frame
			await get_tree().process_frame
		return st
	var picked_st: String = await picked
	Audio.sfx("click", -8.0)
	return picked_st


# --- input -------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed and _dial().grow(18.0).has_point(mb.position):
			_dragging = true
			_set_from_x(mb.position.x)
		elif not mb.pressed and _dragging:
			_dragging = false
			_snap()
		accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _dragging:
		_set_from_x(mm.position.x)
		accept_event()


func _set_from_x(x: float) -> void:
	var d := _dial()
	var raw := (x - d.position.x - 34.0) / (d.size.x * 0.76) * 10.0
	if raw > MAX + 0.05:
		_hit_stop = 1.6
	value = clampf(raw, 0.0, MAX)


func _nudge(step: float) -> void:
	if value + step > MAX + 0.01:
		_hit_stop = 1.6
	value = clampf(value + step, 0.0, MAX)
	Audio.sfx("click", -22.0, 1.6)


func _set_band(b: int) -> void:
	var nb := clampi(b, 0, max_band)
	if nb == band:
		return
	band = nb
	Audio.sfx("click", -14.0, 0.8)


func _snap() -> void:
	var st := locked()
	if st != "":
		create_tween().tween_property(self, "value", station_value(st), 0.12)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _hit_stop > 0.0:
		_hit_stop -= delta
	if hold and drift > 0.0 and not _dragging:
		_drift_t -= delta
		if _drift_t <= 0.0:
			_drift_dir = -1.0 if randf() < 0.5 else 1.0
			_drift_t = randf_range(0.8, 2.2)
		value = clampf(value + _drift_dir * drift * delta, 0.0, MAX)
	_btn_step.disabled = locked() == ""
	_btn_band_down.disabled = band <= 0
	_btn_band_up.disabled = band >= max_band
	var st := locked()
	if st != _last_locked:
		_last_locked = st
		tuned.emit(st)
	_update_audio()
	queue_redraw()


func _update_audio() -> void:
	var n := nearest()
	var st: String = n[0]
	var d: float = n[1]
	var snd: String = info(st).sound
	if snd != _playing:
		if _playing != "":
			Audio.stop_loop(_playing, 0.12)
		_playing = snd
		if snd != "":
			Audio.play_loop(snd, -42.0, 0.0)
			if snd == "hum":
				Audio.set_loop_pitch("hum", 1.0, 0.0)
	var closeness := clampf(1.0 - (d - 0.04) / 0.42, 0.0, 1.0)
	if snd != "":
		Audio.loop_volume(snd, lerpf(-42.0, -8.0, closeness))
	# The quiet ones swallow even the static.
	var quiet := is_quiet(st) and d <= LOCK
	Audio.loop_volume("static", -60.0 if quiet else lerpf(-12.0, -34.0, closeness))


# --- drawing -------------------------------------------------------------------------

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var p := _panel()
	draw_rect(p.grow(4.0), Color("12150f"))
	draw_rect(p, Color("262c21"))
	draw_rect(p, Color("434c3a"), false, 2.0)
	for c in [p.position + Vector2(12, 12), Vector2(p.end.x - 12, p.position.y + 12),
			Vector2(p.position.x + 12, p.end.y - 12), p.end - Vector2(12, 12)]:
		draw_circle(c, 5.0, Color("5a6150"))
		draw_line(c - Vector2(3, 0), c + Vector2(3, 0), Color("2a2f25"), 1.5)
	draw_string(font, p.position + Vector2(34, 32), "AN/PRC · MOD. T.L.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.75, 0.78, 0.66, 0.6))
	var cap_col := Color("bfe6f0") if locked() != "" else Color("9aa3a0")
	draw_string(font, Vector2(p.position.x + 200, p.position.y + 36), caption(), HORIZONTAL_ALIGNMENT_CENTER, p.size.x - 350, 21, cap_col)

	var d := _dial()
	draw_rect(d.grow(6.0), Color("0d0f0b"))
	draw_rect(d, Color("2b1f0f"))
	var flick := 0.88 + 0.12 * sin(_t * 31.0) * sin(_t * 7.0)
	draw_rect(d.grow(-3.0), Color(0.96, 0.66, 0.28, 0.2 * flick))
	var ink := Color("f3dfb0")
	# Ticks every quarter: nothing marks where home is.
	for i in 41:
		var v := i * 0.25
		var x := _scale_x(v)
		var major := i % 4 == 0
		var tick := 30.0 if major else (18.0 if i % 2 == 0 else 10.0)
		var a := 1.0 if v <= 9.0 else 0.4
		draw_line(Vector2(x, d.position.y + 8), Vector2(x, d.position.y + 8 + tick), Color(ink, a), 2.0 if major else 1.0)
		if major and v <= 9.0:
			draw_string(font, Vector2(x - 20, d.position.y + 66), "%02d" % (band * 10 + int(v)), HORIZONTAL_ALIGNMENT_CENTER, 40, 20, Color(ink, a))
	if max_band == 0:
		# The rest of the scale, crushed together where the needle can't reach.
		var beyond := ["20", "30", "50", "70", "99"]
		for i in beyond.size():
			var x := _scale_x(10.0) + 26.0 + i * 36.0
			draw_line(Vector2(x, d.position.y + 8), Vector2(x, d.position.y + 24), Color(ink, 0.25), 1.0)
			draw_string(font, Vector2(x - 18, d.position.y + 66), beyond[i], HORIZONTAL_ALIGNMENT_CENTER, 36, 15, Color(ink, 0.25))
	else:
		# Band readout: which ten stations the dial is showing.
		var bx := _scale_x(10.0) + 30.0
		draw_string(font, Vector2(bx, d.position.y + 40), "BAND", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(ink, 0.6))
		draw_string(font, Vector2(bx, d.position.y + 82), "%02d–%02d" % [band * 10, band * 10 + 9], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, ink)
	draw_string(font, Vector2(d.position.x + 10, d.end.y - 14), "MHz ×1", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(ink, 0.5))
	# Needle.
	var nx := _scale_x(value)
	draw_line(Vector2(nx, d.position.y + 4), Vector2(nx, d.end.y - 4), Color("e0453a"), 3.0)
	draw_circle(Vector2(nx, d.end.y - 8), 5.0, Color("e0453a"))
	if max_band == 0 or hold:
		# How to use it, where the band buttons go once they work.
		var hy := p.position.y + 226.0
		var hx := p.position.x + 236.0
		var l1 := "Keep the needle on home." if hold else "Drag the dial, or ◀ ▶."
		var l2 := "Listen for the hum." if hold else "Green lamp = locked."
		draw_string(font, Vector2(hx, hy), l1, HORIZONTAL_ALIGNMENT_LEFT, 190, 15, Color(0.75, 0.78, 0.66, 0.75))
		draw_string(font, Vector2(hx, hy + 22), l2, HORIZONTAL_ALIGNMENT_LEFT, 190, 15, Color(0.75, 0.78, 0.66, 0.75))
	# Lock lamp.
	var lamp := Vector2(d.end.x - 26, d.position.y - 28)
	var on := locked() != ""
	draw_circle(lamp, 10.0, Color("0d0f0b"))
	draw_circle(lamp, 7.0, Color("74e08c") if on else Color("1f2b20"))
	if on:
		draw_circle(lamp, 16.0, Color(0.45, 0.9, 0.55, 0.18))
	draw_string(font, lamp + Vector2(-70, 6), "LOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.78, 0.66, 0.7))
