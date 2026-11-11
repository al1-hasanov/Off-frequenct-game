extends Node
## Plays sound effects, ambience loops and voice lines. Autoloaded as `Audio`.
##
## Loops are named after their file ("hum", "wind", "static"...) and can be
## faded in and out from any room; they keep playing across room changes.
##
## Voice acting hook: if res://voice/<key>.ogg exists, where key is the first
## 16 hex digits of md5("SPEAKER|exact line text"), hud.say() plays it. There
## are no recordings yet; lines without one fall back to subtitles only (and
## a burst of radio carrier for the 2:14 voice).

const SFX_PLAYERS := 10
const DUCK_DB := -8.0

var _streams := {}
var _loops := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _voice: AudioStreamPlayer
var _voice_fade: Tween
var _duck: Tween
var _ducked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Ambience", "SFX", "Voice"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for i in SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "Voice"
	_voice.finished.connect(_unduck)
	add_child(_voice)


# --- voice -----------------------------------------------------------------------

## Characters speak; narration is silent except notes read aloud (lines in quotes).
static func should_voice(speaker: String, text: String) -> bool:
	return speaker != "" or text.begins_with("\"")


static func voice_path(speaker: String, text: String) -> String:
	return "res://voice/%s.ogg" % (speaker + "|" + text).md5_text().left(16)


func has_voice(speaker: String, text: String) -> bool:
	return should_voice(speaker, text) and ResourceLoader.exists(voice_path(speaker, text))


## Plays the line's recording and ducks the ambience under it. False if there is none.
func play_voice(speaker: String, text: String) -> bool:
	if not has_voice(speaker, text):
		return false
	# A tap mid-line starts a fade-out; it must not go on to stop this new line.
	if _voice_fade != null and _voice_fade.is_valid():
		_voice_fade.kill()
	_voice.stream = load(voice_path(speaker, text))
	_voice.volume_db = 0.0
	_voice.play()
	_set_duck(true)
	return true


func is_voice_playing() -> bool:
	return _voice.playing and _voice.volume_db > -1.0


func voice_stream() -> AudioStream:
	return _voice.stream


func stop_voice(fade: float = 0.08) -> void:
	if not _voice.playing:
		return
	if _voice_fade != null and _voice_fade.is_valid():
		_voice_fade.kill()
	_voice_fade = create_tween()
	_voice_fade.tween_property(_voice, "volume_db", -40.0, fade)
	_voice_fade.tween_callback(func() -> void:
		_voice.stop()
		_voice.volume_db = 0.0
		_unduck())


func _unduck() -> void:
	_set_duck(false)


func _set_duck(on: bool) -> void:
	if on == _ducked:
		return
	_ducked = on
	if _duck != null and _duck.is_valid():
		_duck.kill()
	var bus := AudioServer.get_bus_index("Ambience")
	_duck = create_tween()
	_duck.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v),
		AudioServer.get_bus_volume_db(bus), DUCK_DB if on else 0.0, 0.15 if on else 0.6)


func _stream(sound: String, loop: bool) -> AudioStream:
	var key := sound + ("#loop" if loop else "")
	if _streams.has(key):
		return _streams[key]
	var path := "res://audio/%s.wav" % sound
	if not ResourceLoader.exists(path):
		push_warning("Missing sound: " + path)
		return null
	var s: AudioStream = load(path)
	if loop and s is AudioStreamWAV:
		var w: AudioStreamWAV = s.duplicate()
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
		s = w
	_streams[key] = s
	return s


## Fire-and-forget sound effect.
func sfx(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var s := _stream(sound, false)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play_loop(sound: String, volume_db: float = -8.0, fade: float = 0.6) -> void:
	var p: AudioStreamPlayer = _loops.get(sound)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = "Ambience"
		p.stream = _stream(sound, true)
		if p.stream == null:
			p.free()
			return
		add_child(p)
		_loops[sound] = p
	if not p.playing:
		p.volume_db = -50.0 if fade > 0.0 else volume_db
		p.play()
	_fade(p, volume_db, fade, false)


## Sets a playing loop's volume right now (the Tuner calls this every frame).
func loop_volume(sound: String, volume_db: float) -> void:
	var p: AudioStreamPlayer = _loops.get(sound)
	if p == null or not p.playing:
		return
	if p.has_meta("tween"):
		var old: Tween = p.get_meta("tween")
		if old != null and old.is_valid():
			old.kill()
	p.volume_db = volume_db


## Glides a loop's pitch (each frequency's hum sits at its own pitch).
func set_loop_pitch(sound: String, pitch: float, glide: float = 0.6) -> void:
	var p: AudioStreamPlayer = _loops.get(sound)
	if p == null:
		return
	if glide <= 0.0:
		p.pitch_scale = pitch
	else:
		create_tween().tween_property(p, "pitch_scale", pitch, glide)


func stop_loop(sound: String, fade: float = 0.6) -> void:
	var p: AudioStreamPlayer = _loops.get(sound)
	if p == null or not p.playing:
		return
	_fade(p, -50.0, fade, true)


func is_looping(sound: String) -> bool:
	var p: AudioStreamPlayer = _loops.get(sound)
	return p != null and p.playing


func stop_all(fade: float = 0.5) -> void:
	for sound in _loops:
		stop_loop(sound, fade)


func _fade(p: AudioStreamPlayer, db: float, dur: float, stop_after: bool) -> void:
	if p.has_meta("tween"):
		var old: Tween = p.get_meta("tween")
		if old != null and old.is_valid():
			old.kill()
	if dur <= 0.0:
		p.volume_db = db
		if stop_after:
			p.stop()
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", db, dur)
	if stop_after:
		tw.tween_callback(p.stop)
	p.set_meta("tween", tw)
