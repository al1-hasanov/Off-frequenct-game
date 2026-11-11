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
const SETTINGS_PATH := "user://audio_settings.cfg"

signal settings_changed
var music_enabled := true
var music_volume := 0.55
var ambience_volume := 0.8
var effects_volume := 0.85
var master_volume := 0.9
var _music: AudioStreamPlayer
var _environment := {}
var _score_quiet := false
var _dialogue := false
var _tuning := false
var _mix_db := 0.0
var _settings_dirty := false
var _save_delay := 0.0

var _streams := {}
var _loops := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _voice: AudioStreamPlayer
var _voice_fade: Tween
var _ducked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Ambience", "SFX", "Voice", "Music", "Environment"]:
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
	AudioServer.set_bus_send(AudioServer.get_bus_index("Environment"), "Ambience")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.stream = _stream("night_score", true)
	_music.volume_db = -10.0
	add_child(_music)
	load_settings()
	_apply_settings()
	_sync_music()


func _process(delta: float) -> void:
	# Audio is always processed, including the pause menu. Ease under dialogue/tuning.
	var target := -10.0 if _dialogue or _tuning or _ducked else 0.0
	_mix_db = move_toward(_mix_db, target, delta * 18.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)) + _mix_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(maxf(ambience_volume, 0.0001)) + _mix_db * 0.4)
	if _settings_dirty:
		_save_delay -= delta
		if _save_delay <= 0.0:
			save_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_enabled = bool(cfg.get_value("audio", "music_enabled", true))
	for key in ["music_volume", "ambience_volume", "effects_volume", "master_volume"]:
		set(key, clampf(float(cfg.get_value("audio", key, get(key))), 0.0, 1.0))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in ["music_enabled", "music_volume", "ambience_volume", "effects_volume", "master_volume"]:
		cfg.set_value("audio", key, get(key))
	if cfg.save(SETTINGS_PATH) != OK:
		push_warning("Could not save audio preferences.")
	_settings_dirty = false


func set_setting(key: String, value: Variant) -> void:
	if key == "music_enabled":
		music_enabled = bool(value)
	elif key in ["music_volume", "ambience_volume", "effects_volume", "master_volume"]:
		set(key, clampf(float(value), 0.0, 1.0))
	else:
		return
	_apply_settings()
	_sync_music()
	_settings_dirty = true
	_save_delay = 0.4
	settings_changed.emit()


func _apply_settings() -> void:
	for entry in [["Master", master_volume], ["Ambience", ambience_volume], ["SFX", effects_volume]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(entry[0]), linear_to_db(maxf(float(entry[1]), 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not music_enabled or music_volume <= 0.0)


func _sync_music() -> void:
	if _music == null:
		return
	if music_enabled and music_volume > 0.0 and not _score_quiet:
		if not _music.playing:
			_music.play()
	else:
		_music.stop()


func set_dialogue(active: bool) -> void:
	_dialogue = active


func set_tuning(active: bool) -> void:
	_tuning = active


func music_context(id: String) -> void:
	# The mine's intentional silence and listening puzzle keep their original mix.
	_score_quiet = id == "mine_tunnel"
	_sync_music()


func set_environment(id: String, frequency: String) -> void:
	var desired := {}
	match id:
		"main_street": desired = {"street_air": -18.0, "people_murmur": -25.0}
		"ash_street": desired = {"street_air": -30.0}
		"diner": desired = {"diner_room": -25.0, "people_murmur": -34.0}
		"pike_radio": desired = {"room_air": -30.0, "street_air": -36.0}
		"corridor", "receiver_room", "control_room", "lobby", "east_corridor", "sollen_office", "garage", "sheriff_office":
			desired = {"room_air": -31.0}
	if frequency in ["00", "14", "61"]:
		desired.clear()
	for sound in _environment:
		if not desired.has(sound):
			_fade(_environment[sound], -60.0, 0.7, true)
	for sound in desired:
		var p: AudioStreamPlayer = _environment.get(sound)
		if p == null:
			p = AudioStreamPlayer.new()
			p.bus = "Environment"
			p.stream = _stream(sound, true)
			add_child(p)
			_environment[sound] = p
		if not p.playing:
			p.volume_db = -60.0
			p.play()
		_fade(p, float(desired[sound]), 1.4, false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _settings_dirty:
			save_settings()


func shutdown() -> void:
	# Release active Vorbis decoders before the audio server tears down.
	if _settings_dirty:
		save_settings()
	set_process(false)
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	_streams.clear()


func _exit_tree() -> void:
	shutdown()


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
	_ducked = on


func _stream(sound: String, loop: bool) -> AudioStream:
	var key := sound + ("#loop" if loop else "")
	if _streams.has(key):
		return _streams[key]
	var path := "res://audio/%s.ogg" % sound
	if not ResourceLoader.exists(path):
		path = "res://audio/%s.wav" % sound
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
	elif loop and s is AudioStreamOggVorbis:
		var ogg: AudioStreamOggVorbis = s.duplicate()
		ogg.loop = true
		s = ogg
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
	for p in _environment.values():
		_fade(p, -60.0, fade, true)


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
