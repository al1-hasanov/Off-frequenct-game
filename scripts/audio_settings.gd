class_name AudioSettings
extends ColorRect
## Touch-sized, modal settings shared by the title and pause menus: sound on
## the left, display options for slower phones on the right.

signal closed
var _music: CheckButton
var _sliders := {}
var _values := {}
var _display := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.015, 0.025, 0.04, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1120, 0)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 32)
	outer.add_child(title)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 44)
	outer.add_child(cols)

	# Left: sound.
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size.x = 560
	cols.add_child(v)
	v.add_child(_heading("Sound & atmosphere"))
	var sub := _small("A quiet mystery. Set your own mood.")
	v.add_child(sub)
	_music = CheckButton.new()
	_music.text = "Background music"
	_music.custom_minimum_size.y = 58
	_music.toggled.connect(func(on: bool) -> void: Audio.set_setting("music_enabled", on))
	v.add_child(_music)
	for row in [["master_volume", "Overall volume"], ["music_volume", "Music"], ["ambience_volume", "Street, rooms & radios"], ["effects_volume", "Footsteps & effects"]]:
		var box := VBoxContainer.new()
		v.add_child(box)
		var labels := HBoxContainer.new()
		box.add_child(labels)
		var label := Label.new()
		label.text = row[1]
		label.add_theme_font_size_override("font_size", 20)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		labels.add_child(label)
		var value := Label.new()
		value.add_theme_font_size_override("font_size", 20)
		labels.add_child(value)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.custom_minimum_size = Vector2(540, 34)
		var key: String = row[0]
		slider.value_changed.connect(func(n: float) -> void: Audio.set_setting(key, n / 100.0))
		box.add_child(slider)
		_sliders[key] = slider
		_values[key] = value
	v.add_child(_small("Music can be off while every story sound stays on."))

	# Right: display, for phones that run hot or slow.
	var d := VBoxContainer.new()
	d.add_theme_constant_override("separation", 6)
	d.custom_minimum_size.x = 500
	cols.add_child(d)
	d.add_child(_heading("Display"))
	d.add_child(_small("If the game stutters or your phone gets warm."))
	for row in [["battery_saver", "Battery saver", "30 frames a second, drawn at 720p. Longer battery, cooler phone."],
			["smooth_edges", "Smooth edges", "Softer outlines on shapes. Costs speed on some phones."],
			["show_fps", "Show frame rate", "A small counter in the bottom corner."]]:
		var key: String = row[0]
		var b := CheckButton.new()
		b.text = row[1]
		b.custom_minimum_size.y = 58
		b.toggled.connect(func(on: bool) -> void:
			DisplaySettings.set_setting(key, on)
			_refresh())
		d.add_child(b)
		var note := _small(row[2])
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size.x = 480
		d.add_child(note)
		_display[key] = b

	var back := Button.new()
	back.text = "Done"
	back.custom_minimum_size.y = 58
	back.pressed.connect(close)
	outer.add_child(back)
	Audio.settings_changed.connect(_refresh)
	visible = false
	_refresh()


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	l.modulate = Color("e8a54b")
	return l


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.modulate = Color("a7b9ba")
	return l


func open() -> void:
	_refresh()
	visible = true
	_music.grab_focus()


func close() -> void:
	Audio.save_settings()
	DisplaySettings.save_settings()
	visible = false
	closed.emit()


func _refresh() -> void:
	_music.set_pressed_no_signal(Audio.music_enabled)
	for key in _sliders:
		var n := roundi(float(Audio.get(key)) * 100.0)
		_sliders[key].set_value_no_signal(n)
		_values[key].text = "%d%%" % n
	for key in _display:
		_display[key].set_pressed_no_signal(DisplaySettings.get_setting(key))
	if _display.has("smooth_edges"):
		# Battery saver already turns smoothing off.
		_display["smooth_edges"].disabled = DisplaySettings.battery_saver


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
