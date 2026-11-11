class_name AudioSettings
extends ColorRect
## Touch-sized, modal controls shared by the title and pause menus.

signal closed
var _music: CheckButton
var _sliders := {}
var _values := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.015, 0.025, 0.04, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	title.text = "Sound & atmosphere"
	title.add_theme_font_size_override("font_size", 32)
	v.add_child(title)
	var sub := Label.new()
	sub.text = "A quiet mystery. Set your own mood."
	sub.add_theme_font_size_override("font_size", 20)
	sub.modulate = Color("a7b9ba")
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
		slider.custom_minimum_size = Vector2(580, 34)
		var key: String = row[0]
		slider.value_changed.connect(func(n: float) -> void: Audio.set_setting(key, n / 100.0))
		box.add_child(slider)
		_sliders[key] = slider
		_values[key] = value
	var note := Label.new()
	note.text = "Music can be off while every story sound stays on."
	note.add_theme_font_size_override("font_size", 18)
	note.modulate = Color("a7b9ba")
	v.add_child(note)
	var back := Button.new()
	back.text = "Done"
	back.custom_minimum_size.y = 58
	back.pressed.connect(close)
	v.add_child(back)
	Audio.settings_changed.connect(_refresh)
	visible = false
	_refresh()


func open() -> void:
	_refresh()
	visible = true
	_music.grab_focus()


func close() -> void:
	Audio.save_settings()
	visible = false
	closed.emit()


func _refresh() -> void:
	_music.set_pressed_no_signal(Audio.music_enabled)
	for key in _sliders:
		var n := roundi(float(Audio.get(key)) * 100.0)
		_sliders[key].set_value_no_signal(n)
		_values[key].text = "%d%%" % n


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
