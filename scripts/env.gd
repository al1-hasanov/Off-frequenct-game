class_name Env
extends RefCounted
## The world outside, station by station.
##
## Every frequency on Tomas's dial is another Halvard, and most of them aren't
## in the middle of a snowy October night. Tuning changes the season, the hour,
## the weather, and how the town and the Lind house have fared.
##
## The stations the story visits (H, 01, 03, 05, 12, 14) keep the long night of
## the story, in the snow. The quiet ones are white and empty. Every other
## station takes its look from its number and from what can be heard on it
## (see TunerUI). Station 02 is the rain the caption promises, 06 the open door
## in the wind, 09 the empty house with the phone ringing in it.
##
## A room sets Env.current before it draws (see Room.env()). The outdoor
## helpers in Townscape and Kit read it: snow on ledges, icicles, banks, pines,
## stars, lit windows, the view through a window. Indoors nothing changes but
## the view outside.

const SEASONS := ["winter", "spring", "summer", "autumn"]
const PAINT := ["7a6650", "5a6a7a", "8a5a4a", "6a7a5a", "c8c0b0", "4e6478", "9a8a6a", "6a4a5a", "a08a70", "5e5a6e"]

## The station this is ("H", "02", "37"...).
var st := "H"
## winter, spring, summer or autumn.
var season := "winter"
## night, dusk, dawn or day.
var hour := "night"
## What's falling through the air: snow, rain, leaves, petals, fireflies or none.
var fall := "snow"
## A grey sky: no stars, no sun.
var overcast := false
## Somebody's home: lights on in the houses.
var lit := true
## home, empty (dark and unfurnished), derelict (boarded up, years gone) or
## gone (the quiet ones: nothing there at all).
var state := "home"
## Sirens on this one: something's burning over the hill.
var fire := false
## The streetlight outside the Lind house works in this one.
var lamp_fixed := false
## A moon over a clear night.
var moon := false
## The Lind house's paint.
var paint := Color("7a6650")
## Which of the Lind house's windows are lit (upstairs left, upstairs right,
## front room, porch window) and whether the porch light is on.
var windows := [true, true, true, true]
var porch_light := true

static var current: Env = null
static var _cache := {}


## The world of station `station` ("" is home).
static func of(station: String) -> Env:
	var key := station if station != "" else "H"
	if _cache.has(key):
		return _cache[key]
	var e := Env.new()
	e._build(key)
	_cache[key] = e
	return e


## The world the drawing in progress belongs to.
static func now() -> Env:
	if current == null:
		current = of("H")
	return current


## True for the stations the story visits: the long snowy night.
func story() -> bool:
	return st in ["H", "01", "03", "05", "12", "14"]


func _build(key: String) -> void:
	st = key
	if key.begins_with("F"):
		_future(key)
		return
	if story():
		if key == "14":
			lit = false
			state = "empty"
			paint = Color("54504c")
			windows = [false, false, false, false]
			porch_light = false
		return
	if TunerUI.is_quiet(key):
		state = "gone"
		lit = false
		fall = "none"
		windows = [false, false, false, false]
		porch_light = false
		return
	var n := int(key)
	match key:
		"00":  # A flat tone, like a dead line: the town given up, a grey winter dawn.
			_look("winter", "dawn", "none", true, false, "derelict")
			paint = Color("5a5652")
		"02":  # Rain. It never rains up here this late in the year.
			_look("autumn", "night", "rain", true, true, "home")
			paint = Color("6a5a48")
			windows = [false, true, true, false]
		"04":  # Tonight's song, a beat behind: nearly home. A clear sky, a moon, a blue house.
			_look("winter", "night", "none", false, true, "home")
			moon = true
			lamp_fixed = true
			paint = Color("4e6478")
		"06":  # Wind through a door somebody left open.
			_look("autumn", "dusk", "leaves", false, false, "empty")
			paint = Color("7a6650")
		"07":  # Breathing. Close. One light upstairs, on a summer night.
			_look("summer", "night", "fireflies", false, false, "home")
			paint = Color("6a7a5a")
			windows = [false, true, false, false]
		"08":  # Knocking, three then two. A wet spring evening, the porch light on.
			_look("spring", "dusk", "rain", true, true, "home")
			paint = Color("8a7a5a")
			windows = [true, false, true, true]
		"09":  # A phone ringing in an empty room, on a bright summer afternoon.
			_look("summer", "day", "none", false, false, "empty")
			paint = Color("c8c0b0")
		_:
			_derive(n)
	if not lit:
		windows = [false, false, false, false]
		porch_light = false
	moon = moon and not overcast
	if state == "derelict":
		lamp_fixed = false


## The futures the dish hears (Act 3): "F2031", "F2009", "F1991".
func _future(key: String) -> void:
	match key:
		"F2031":
			# An October afternoon, clear, the maples turning.
			_look("autumn", "day", "leaves", false, false, "home")
			paint = Color("c8c0b0")
			lamp_fixed = true
		"F2009":
			# A wet October afternoon. The town below has lost half its roofs.
			_look("autumn", "day", "rain", true, false, "derelict")
			paint = Color("5a5652")
		"F1991":
			# Half past one in the morning, the first snow, the town lit.
			_look("winter", "night", "snow", false, true, "home")
			paint = Color("7a6650")
			lamp_fixed = true
	if not lit:
		windows = [false, false, false, false]
		porch_light = false


func _look(s: String, h: String, f: String, grey: bool, on: bool, how: String) -> void:
	season = s
	hour = h
	fall = f
	overcast = grey
	lit = on
	state = how


## Every other station: its season from its number, the rest from what can be
## heard on it.
func _derive(n: int) -> void:
	season = SEASONS[(n + n / 10) % 4]
	var r1 := _r(n, 1)
	hour = "night" if r1 < 0.42 else ("dusk" if r1 < 0.62 else ("dawn" if r1 < 0.76 else "day"))
	paint = Color(PAINT[(n * 3 + 1) % PAINT.size()])
	var r2 := _r(n, 2)
	match season:
		"winter":
			fall = "snow" if r2 < 0.6 else "none"
		"spring":
			fall = "rain" if r2 < 0.4 else ("petals" if r2 < 0.75 else "none")
		"summer":
			fall = "fireflies" if hour in ["night", "dusk"] and r2 < 0.7 else "none"
		"autumn":
			fall = "leaves" if r2 < 0.6 else ("rain" if r2 < 0.85 else "none")
	overcast = fall == "rain" or (fall == "snow" and r2 < 0.3)
	lit = hour != "day" and _r(n, 3) > 0.3
	lamp_fixed = _r(n, 4) > 0.6
	moon = hour == "night" and not overcast and _r(n, 5) > 0.45
	if _r(n, 6) > 0.86:
		state = "derelict"
		lit = false
	windows = [_r(n, 7) > 0.35, _r(n, 8) > 0.35, true, _r(n, 9) > 0.4]
	porch_light = _r(n, 10) > 0.3
	match TunerUI.info("%02d" % n).sound:
		"rain":
			fall = "rain"
			overcast = true
			if season in ["winter", "summer"]:
				season = "autumn"
		"plow":
			season = "winter"
			fall = "snow"
		"siren":
			fire = true
		"crowd", "kettle", "radio_music", "barking", "truck_idle":
			if sound_is(n, "crowd"):
				hour = "night"  # "A street full of people at night."
			if state != "derelict":
				lit = hour != "day"
				state = "home"
		"ring", "breath", "knock":
			lit = false
			if state == "home" and _r(n, 11) > 0.5:
				state = "empty"
		"bell":
			hour = "night"  # "Church bells. At two in the morning."
			lit = state != "derelict"
		"snore", "typewriter":
			# Somebody up late, or asleep: one window lit, at night.
			hour = "night"
			lit = state != "derelict"
			windows = [false, true, false, false] if n % 2 == 0 else [true, false, false, false]
			porch_light = false


static func sound_is(n: int, sound: String) -> bool:
	return TunerUI.info("%02d" % n).sound == sound


static func _r(n: int, k: int) -> float:
	return Townscape.h(n * 37 + k * 101 + 7)


# --- what it looks like -------------------------------------------------------------------

func day() -> bool:
	return hour == "day"


func night() -> bool:
	return hour == "night"


## Snow lying on the ground, the roofs and every ledge.
func snowy() -> bool:
	return season == "winter"


## Spring: what's left of the snow, grey, in the banks along the kerb.
func thaw() -> bool:
	return season == "spring"


## The colour the whole scene is lit by (the room's CanvasModulate). At night
## the room keeps its own tint.
func tint(night_tint: Color) -> Color:
	if state == "gone":
		return Color(1, 1, 1)
	match hour:
		"dusk":
			return Color(1.0, 0.86, 0.78) if not overcast else Color(0.86, 0.84, 0.88)
		"dawn":
			return Color(0.96, 0.9, 0.95) if not overcast else Color(0.86, 0.88, 0.94)
		"day":
			return Color(1, 1, 1) if not overcast else Color(0.92, 0.94, 0.98)
	return night_tint


## [top, horizon]
func sky() -> Array:
	if state == "gone":
		return [Color("d8dce4"), Color("f0f2f5")]
	match hour:
		"dusk":
			return [Color("2a2a3a"), Color("6e6062")] if overcast else [Color("1e2a5c"), Color("e88a5c")]
		"dawn":
			return [Color("4a5060"), Color("9a9ca6")] if overcast else [Color("3a4e88"), Color("f2b894")]
		"day":
			if overcast:
				return [Color("6a7280"), Color("b4bac2")]
			match season:
				"winter":
					return [Color("6f93c0"), Color("d8e2ee")]
				"autumn":
					return [Color("4f84c4"), Color("d4e0ea")]
			return [Color("3f7fd0"), Color("bedcf2")]
	if overcast:
		return [Color("07090e"), Color("1c2029")]
	return [Color("03050c"), Color("1a2240")]


## How bright the stars are (0 = none).
func stars() -> float:
	if overcast or state == "gone":
		return 0.0
	match hour:
		"night":
			return 1.0
		"dusk", "dawn":
			return 0.22
	return 0.0


## Shades a daylight colour for this hour.
func shade(c: Color) -> Color:
	match hour:
		"night":
			return c.lerp(Color("0a1022"), 0.86)
		"dusk":
			return c.lerp(Color("3a2a4c"), 0.5)
		"dawn":
			return c.lerp(Color("5a5878"), 0.38)
	return c.lerp(Color("8a909a"), 0.25) if overcast else c


## The mountains and the far hills.
func hills() -> Color:
	if story() or (snowy() and night()):
		return Color("0d1426")
	match season:
		"winter":
			return shade(Color("a8b4c6"))
		"spring":
			return shade(Color("5e7e58"))
		"summer":
			return shade(Color("3a6440"))
	return shade(Color("8a6a3c"))


## Gardens and fields: [top, bottom].
func ground() -> Array:
	if story() or (snowy() and night()):
		return [Color("3a4458"), Color("6a768c")]
	match season:
		"winter":
			return [shade(Color("c4d0de")), shade(Color("e4eaf2"))]
		"spring":
			return [shade(Color("5a7a40")), shade(Color("7a9a50"))]
		"summer":
			return [shade(Color("3e7a34")), shade(Color("5c9a44"))]
	return [shade(Color("7a6a34")), shade(Color("9a8444"))]


## The road: plowed snow in winter, asphalt (wet in the rain) otherwise.
func road() -> Array:
	if story() or (snowy() and night()):
		return [Color("b4bed0"), Color("7a869c")]
	if snowy():
		return [shade(Color("dfe5ee")), shade(Color("b6bfcc"))]
	if fall == "rain":
		return [shade(Color("3c4048")), shade(Color("2a2d34"))]
	return [shade(Color("6c7078")), shade(Color("54585f"))]


## The kerbstone.
func kerb() -> Color:
	return Color("d8dce6") if snowy() and (story() or night()) else (shade(Color("f0f2f6")) if snowy() else shade(Color("a4a49e")))


## The roofs: deep in snow in winter, bare shingle otherwise.
func roof_snow() -> bool:
	return snowy()


## Evergreens.
func pine(night_col: Color) -> Color:
	if night() or story():
		return night_col
	return shade(Color("1e3a2a"))


## A deciduous tree's leaves (transparent: bare branches).
func foliage() -> Array:
	match season:
		"spring":
			return [shade(Color("8ec46a")), shade(Color("f2c4d2"))]
		"summer":
			return [shade(Color("3a7a36")), shade(Color("4e9444"))]
		"autumn":
			return [shade(Color("d8742a")), shade(Color("c8462a")), shade(Color("e8b440"))]
	return []


## A window with a lamp on behind it glows at night and in the twilight.
func windows_glow() -> bool:
	return not day()


## Smoke from the chimneys: cold nights.
func chimney_smoke() -> bool:
	return lit and season != "summer"
