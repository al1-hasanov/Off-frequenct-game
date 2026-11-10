class_name Hud
extends CanvasLayer
## Everything on screen that isn't the room: the clock, objective, inventory,
## dialogue box, choice buttons, the Tuner dial, documents, fades, title cards
## and menus.
##
## Scenes talk to it with coroutines:
##     await hud.say("MARA", "Okay. Okay.")
##     var pick := await hud.choose(["Answer", "Cut the power"])
##     await hud.read_doc("Station log", ["page one", "page two"])

signal advance
signal chosen(index: int)
signal menu_chosen(action: String)
signal doc_turn(step: int)
## Only used by the screenshot run: a line finished typing / buttons appeared.
signal line_shown(speaker: String, text: String)
signal buttons_shown(kind: String)

const C_TEXT := Color("e7e3d6")
const C_DIM := Color("9aa3a0")
const C_ACCENT := Color("e8a54b")
const C_VOICE := Color("9fd3e6")
const C_FROZEN := Color("e06b5f")
const C_HER := Color("d9b3c7")
const C_TAPE := Color("d8c79a")

var main: Node
var root: Control
var top_bar: Control
var clock_label: Label
var place_label: Label
var objective_label: Label
var inv_box: HBoxContainer
var hint_button: Button
var menu_button: Button
var blocker: Control
var dialog_panel: PanelContainer
var speaker_label: Label
var text_label: RichTextLabel
var more_label: Label
var choice_box: VBoxContainer
var menu_box: VBoxContainer
var pause_panel: PanelContainer
var pause_menu_button: Button
var fade_rect: ColorRect
var card_title: Label
var card_sub: Label
var toast_label: Label
var tuner: TunerUI
var glitch_fx: GlitchFX
var doc_layer: Control
var doc_title: Label
var doc_text: Label
var doc_page: Label
var doc_prev: Button
var doc_next: Button

var _typing := false
var _type_tween: Tween
var _dialog_open := false
var _pending_close := false
var _choosing := false
var _flicker := false
var _blink := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)
	_build_top_bar()
	tuner = TunerUI.new()
	root.add_child(tuner)
	_build_dialog()
	_build_choices()
	_build_menus()
	_build_doc()
	_build_cards()
	GameState.changed.connect(refresh)
	GameState.inventory_changed.connect(refresh_inventory)
	refresh()
	refresh_inventory()


func _process(delta: float) -> void:
	_blink += delta
	if not GameState.clock_frozen:
		var colon := ":" if fmod(_blink, 1.0) < 0.5 else " "
		clock_label.text = GameState.clock_text.replace(":", colon) + " AM"
	if _flicker and card_title.visible:
		card_title.position.x = randf_range(-3.0, 3.0) if randf() < 0.15 else 0.0
		card_title.modulate.a = randf_range(0.55, 1.0) if randf() < 0.12 else 1.0
	if dialog_panel.visible:
		_place_dialog()
	if main != null:
		menu_button.visible = top_bar.visible
		pause_menu_button.disabled = main.is_busy()


# --- building the interface ------------------------------------------------

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 26
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.03, 0.04, 0.06, 0.9)
	panel.set_corner_radius_all(10)
	panel.set_content_margin_all(20)
	panel.border_color = Color(1, 1, 1, 0.08)
	panel.set_border_width_all(1)
	t.set_stylebox("panel", "PanelContainer", panel)
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.07, 0.09, 0.12, 0.94)
	btn.set_corner_radius_all(8)
	btn.set_content_margin_all(14)
	btn.border_color = Color(1, 1, 1, 0.14)
	btn.set_border_width_all(1)
	var btn_hover: StyleBoxFlat = btn.duplicate()
	btn_hover.bg_color = Color(0.13, 0.16, 0.2, 0.96)
	btn_hover.border_color = C_ACCENT
	var btn_press: StyleBoxFlat = btn_hover.duplicate()
	btn_press.bg_color = Color(0.22, 0.17, 0.1, 0.96)
	var btn_disabled: StyleBoxFlat = btn.duplicate()
	btn_disabled.bg_color = Color(0.05, 0.06, 0.08, 0.7)
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_press)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", C_ACCENT)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.5))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	return t


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_top_bar() -> void:
	top_bar = Control.new()
	top_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bar)

	var left := VBoxContainer.new()
	left.position = Vector2(26, 14)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_theme_constant_override("separation", 2)
	top_bar.add_child(left)
	clock_label = _label("1:40 AM", 34, C_TEXT)
	left.add_child(clock_label)
	place_label = _label("", 17, C_DIM)
	left.add_child(place_label)
	objective_label = _label("", 19, C_ACCENT)
	objective_label.custom_minimum_size = Vector2(880, 0)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(objective_label)

	var right := HBoxContainer.new()
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -760.0
	right.offset_right = -18.0
	right.offset_top = 14.0
	right.offset_bottom = 90.0
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 10)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(right)
	inv_box = HBoxContainer.new()
	inv_box.add_theme_constant_override("separation", 8)
	inv_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(inv_box)
	hint_button = _icon_button("?")
	hint_button.tooltip_text = "Show everything I can interact with"
	hint_button.pressed.connect(func() -> void:
		if main != null and not main.is_busy():
			main.flash_hotspots())
	right.add_child(hint_button)
	menu_button = _icon_button("II")
	menu_button.tooltip_text = "Pause"
	menu_button.pressed.connect(open_pause)
	right.add_child(menu_button)


func _icon_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(72, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28)
	return b


func _build_dialog() -> void:
	blocker = Control.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.visible = false
	blocker.gui_input.connect(_on_blocker_input)
	root.add_child(blocker)

	dialog_panel = PanelContainer.new()
	dialog_panel.anchor_left = 0.0
	dialog_panel.anchor_right = 1.0
	# Dialogue sits near the top, under the clock, so it never hides the characters.
	dialog_panel.anchor_top = 0.0
	dialog_panel.anchor_bottom = 0.0
	dialog_panel.offset_left = 60.0
	dialog_panel.offset_right = -60.0
	dialog_panel.offset_top = 136.0
	dialog_panel.offset_bottom = 136.0
	dialog_panel.grow_vertical = Control.GROW_DIRECTION_END
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.visible = false
	root.add_child(dialog_panel)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 6)
	dialog_panel.add_child(v)
	speaker_label = _label("", 21, C_ACCENT)
	v.add_child(speaker_label)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.add_theme_font_size_override("normal_font_size", 28)
	text_label.add_theme_font_size_override("italics_font_size", 28)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(text_label)
	more_label = _label("tap to continue  ▼", 16, C_DIM)
	more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(more_label)


func _build_choices() -> void:
	choice_box = VBoxContainer.new()
	choice_box.anchor_left = 0.5
	choice_box.anchor_right = 0.5
	choice_box.anchor_top = 0.6
	choice_box.anchor_bottom = 0.6
	choice_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	choice_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_box.add_theme_constant_override("separation", 12)
	choice_box.visible = false
	root.add_child(choice_box)


func _build_menus() -> void:
	menu_box = VBoxContainer.new()
	menu_box.anchor_left = 0.5
	menu_box.anchor_right = 0.5
	menu_box.anchor_top = 0.72
	menu_box.anchor_bottom = 0.72
	menu_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	menu_box.add_theme_constant_override("separation", 12)
	menu_box.visible = false
	root.add_child(menu_box)

	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	pause_panel.visible = false
	root.add_child(pause_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pause_panel.add_child(v)
	var title := _label("Paused", 34, C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var resume := Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(440, 72)
	resume.pressed.connect(close_pause)
	v.add_child(resume)
	pause_menu_button = Button.new()
	pause_menu_button.text = "Save and quit to menu"
	pause_menu_button.custom_minimum_size = Vector2(440, 72)
	pause_menu_button.pressed.connect(func() -> void:
		close_pause()
		GameState.save_game()
		main.change_room("menu"))
	v.add_child(pause_menu_button)


func _build_doc() -> void:
	doc_layer = ColorRect.new()
	(doc_layer as ColorRect).color = Color(0, 0, 0, 0.55)
	doc_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	doc_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	doc_layer.visible = false
	root.add_child(doc_layer)
	var paper := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("e8e0c8")
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(30)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	paper.add_theme_stylebox_override("panel", sb)
	paper.anchor_left = 0.5
	paper.anchor_right = 0.5
	paper.anchor_top = 0.5
	paper.anchor_bottom = 0.5
	paper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	paper.grow_vertical = Control.GROW_DIRECTION_BOTH
	doc_layer.add_child(paper)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	paper.add_child(v)
	doc_title = Label.new()
	doc_title.add_theme_font_size_override("font_size", 24)
	doc_title.add_theme_color_override("font_color", Color("6a2a22"))
	v.add_child(doc_title)
	doc_text = Label.new()
	doc_text.custom_minimum_size = Vector2(720, 300)
	doc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_text.add_theme_font_size_override("font_size", 25)
	doc_text.add_theme_color_override("font_color", Color("2a2824"))
	v.add_child(doc_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	doc_prev = Button.new()
	doc_prev.text = "◀ Back"
	doc_prev.custom_minimum_size = Vector2(170, 66)
	doc_prev.focus_mode = Control.FOCUS_NONE
	doc_prev.pressed.connect(func() -> void: doc_turn.emit(-1))
	row.add_child(doc_prev)
	doc_page = Label.new()
	doc_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	doc_page.add_theme_color_override("font_color", Color("6b665a"))
	doc_page.add_theme_font_size_override("font_size", 20)
	row.add_child(doc_page)
	doc_next = Button.new()
	doc_next.custom_minimum_size = Vector2(170, 66)
	doc_next.focus_mode = Control.FOCUS_NONE
	doc_next.pressed.connect(func() -> void: doc_turn.emit(1))
	row.add_child(doc_next)


func _build_cards() -> void:
	toast_label = _label("", 24, C_ACCENT)
	toast_label.anchor_left = 0.5
	toast_label.anchor_right = 0.5
	toast_label.offset_left = -430.0
	toast_label.offset_right = 430.0
	toast_label.offset_top = 300.0
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)

	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)

	var card := VBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)
	card_title = _label("", 80, C_TEXT)
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.visible = false
	card.add_child(card_title)
	card_sub = _label("", 28, C_DIM)
	card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_sub.visible = false
	card.add_child(card_sub)

	glitch_fx = GlitchFX.new()
	glitch_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	glitch_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glitch_fx)


# --- top bar ----------------------------------------------------------------

func refresh() -> void:
	clock_label.text = GameState.clock_text + " AM"
	clock_label.add_theme_color_override("font_color", C_FROZEN if GameState.clock_frozen else C_TEXT)
	place_label.text = GameState.place
	objective_label.text = ("▸ " + GameState.objective) if GameState.objective != "" else ""
	_place_dialog.call_deferred()


## Keeps the dialogue box clear of the objective when it wraps onto two lines.
func _place_dialog() -> void:
	var top := 136.0
	if top_bar.visible and objective_label.text != "":
		top = maxf(top, objective_label.get_global_rect().end.y + 10.0)
	dialog_panel.offset_top = top
	dialog_panel.offset_bottom = top


func set_gameplay_visible(v: bool) -> void:
	top_bar.visible = v


func refresh_inventory() -> void:
	for c in inv_box.get_children():
		c.queue_free()
	for id in GameState.inventory:
		var slot := ItemSlot.new(id)
		slot.selected = id == GameState.selected_item
		slot.pressed.connect(_on_item_pressed.bind(id))
		inv_box.add_child(slot)


## Tap an item to pick it up, tap it again to look at it, or tap a second
## item to try the two together.
func _on_item_pressed(id: String) -> void:
	if main == null or main.is_busy():
		return
	var held := GameState.selected_item
	if held == id:
		GameState.selected_item = ""
		refresh_inventory()
		main.run(examine.bind(id))
	elif held != "":
		GameState.selected_item = ""
		refresh_inventory()
		main.run(combine.bind(held, id))
	else:
		GameState.selected_item = id
		refresh_inventory()
		toast("Using: %s\nTap something to use it on, or another item to combine. Tap it again to look at it." % GameState.item_name(id))


func examine(id: String) -> void:
	var handled := false
	if main.room != null:
		handled = await main.room.examine_item(id)
	if not handled:
		await say("MARA", GameState.item_desc(id))


func combine(a: String, b: String) -> void:
	var r := GameState.recipe(a, b)
	if r.is_empty():
		await say("MARA", ["Those don't go together.", "No. That's not a thing.", "I don't see how."].pick_random())
		return
	GameState.remove_item(a)
	GameState.remove_item(b)
	GameState.add_item(r.result)
	Audio.sfx("click", -6.0)
	for line in r.lines:
		await say("MARA", line)
	toast("Got: " + GameState.item_name(r.result))
	if main.room != null:
		main.room.objective()


# --- dialogue -----------------------------------------------------------------

## Shows one line and waits for a tap. An empty speaker means narration.
func say(speaker: String, text: String) -> void:
	_pending_close = false
	_open_dialog()
	var voice := speaker == "VOICE"
	var tape := speaker.ends_with("(TAPE)")
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	var sc := C_ACCENT
	if voice:
		sc = C_VOICE
	elif speaker == "HER":
		sc = C_HER
	elif tape:
		sc = C_TAPE
	speaker_label.add_theme_color_override("font_color", sc)
	var safe := text.replace("[", "[lb]")
	if speaker == "":
		text_label.text = "[i][color=#b9c0bd]%s[/color][/i]" % safe
	elif voice:
		text_label.text = "[shake rate=14.0 level=4 connected=1][color=#9fd3e6]%s[/color][/shake]" % safe
	elif speaker == "HER":
		text_label.text = "[color=#e8d3dd]%s[/color]" % safe
	elif tape:
		text_label.text = "[color=#e6dcc0]%s[/color]" % safe
	else:
		text_label.text = safe
	more_label.modulate.a = 0.0
	if GameState.test_mode:
		print("    %s: %s" % [speaker if speaker != "" else "(narration)", text])
	if not Audio.play_voice(speaker, text) and voice:
		# No recording yet: fall back to the garbled radio murmur.
		Audio.sfx("voice" if text.length() > 24 else "voice_short", -3.0)
	if GameState.test_mode and not GameState.test_show_ui:
		text_label.visible_ratio = 1.0
		await get_tree().process_frame
	else:
		text_label.visible_ratio = 0.0
		_typing = true
		if _type_tween != null and _type_tween.is_valid():
			_type_tween.kill()
		_type_tween = create_tween()
		_type_tween.tween_property(text_label, "visible_ratio", 1.0, clampf(text.length() * 0.024, 0.25, 3.0))
		_type_tween.finished.connect(_finish_typing)
		if GameState.test_show_ui:
			# Screenshot runs: show the real dialogue box, then advance by itself.
			_type_tween.finished.connect(func() -> void:
				line_shown.emit(speaker, text)
				get_tree().create_timer(0.6).timeout.connect(func() -> void: advance.emit()))
		await advance
	# Tapping on cuts the line short, like skipping dialogue in any adventure game.
	Audio.stop_voice()
	_pending_close = true
	_close_later.call_deferred()


func narrate(text: String) -> void:
	await say("", text)


func _finish_typing() -> void:
	_typing = false
	text_label.visible_ratio = 1.0
	more_label.modulate.a = 1.0


func _on_blocker_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	var tap: bool = mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if not tap or _choosing or not _dialog_open:
		return
	if _typing:
		if _type_tween != null and _type_tween.is_valid():
			_type_tween.kill()
		_finish_typing()
	else:
		advance.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if _dialog_open and not _choosing and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
		if _typing:
			_type_tween.kill()
			_finish_typing()
		else:
			advance.emit()


func _open_dialog() -> void:
	_dialog_open = true
	dialog_panel.visible = true
	blocker.visible = true


func _close_later() -> void:
	if _pending_close:
		_close_dialog()


func _close_dialog() -> void:
	_pending_close = false
	_dialog_open = false
	dialog_panel.visible = false
	if not _choosing:
		blocker.visible = false


# --- choices -------------------------------------------------------------------

## Shows buttons and returns the index picked. The last spoken line stays visible.
func choose(options: Array, at: float = 0.6) -> int:
	_pending_close = false
	var pick := 0
	if GameState.test_mode:
		if not GameState.test_choices.is_empty():
			pick = int(GameState.test_choices.pop_front())
		print("    [choice] %s -> %s" % [options, options[pick]])
	if GameState.test_mode and not GameState.test_show_ui:
		await get_tree().process_frame
		_close_dialog()
		return pick
	_choosing = true
	blocker.visible = true
	choice_box.anchor_top = at
	choice_box.anchor_bottom = at
	for c in choice_box.get_children():
		c.queue_free()
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.custom_minimum_size = Vector2(640, 76)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: chosen.emit(i))
		choice_box.add_child(b)
	choice_box.visible = true
	if GameState.test_show_ui:
		buttons_shown.emit("choice")
		get_tree().create_timer(0.8).timeout.connect(func() -> void: chosen.emit(pick))
	var idx: int = await chosen
	choice_box.visible = false
	_choosing = false
	_close_dialog()
	Audio.sfx("click", -10.0)
	return idx


## The title-screen menu. Returns "new", "continue" or "quit".
func main_menu(has_save: bool) -> String:
	if GameState.test_mode and not GameState.test_show_ui:
		await get_tree().process_frame
		return "new"
	for c in menu_box.get_children():
		c.queue_free()
	var items: Array = []
	if has_save:
		items.append(["Continue", "continue"])
	items.append(["New game", "new"])
	if OS.get_name() != "iOS":
		items.append(["Quit", "quit"])
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.custom_minimum_size = Vector2(420, 74)
		b.focus_mode = Control.FOCUS_NONE
		var action: String = it[1]
		b.pressed.connect(func() -> void: menu_chosen.emit(action))
		menu_box.add_child(b)
	menu_box.visible = true
	if GameState.test_show_ui:
		buttons_shown.emit("menu")
		get_tree().create_timer(1.2).timeout.connect(func() -> void: menu_chosen.emit("new"))
	var picked: String = await menu_chosen
	menu_box.visible = false
	Audio.sfx("click", -8.0)
	return picked


# --- the Tuner ---------------------------------------------------------------------

## Opens Tomas's radio and waits until Mara steps through a station the room
## accepts. `refuse(station)` returns "" to accept, or a line Mara says instead.
## Returns the station, or "" if she switched the radio off.
func tune(refuse: Callable, start: float = 0.0) -> String:
	tuner.open(start)
	var result := ""
	while true:
		var st: String = await tuner.pick()
		if st == "":
			break
		var line: String = refuse.call(st)
		if line == "":
			result = st
			break
		await say("MARA", line)
	tuner.close()
	if result == "" and main != null and main.room != null:
		main.room.ambience()
	return result


# --- documents ----------------------------------------------------------------------

## Shows a document page by page (a logbook, a letter) until it's closed.
func read_doc(title: String, pages: Array) -> void:
	if GameState.test_mode:
		print("    [doc] %s" % title)
		for pg in pages:
			print("      | ", str(pg).replace("\n", " / "))
		if not GameState.test_show_ui:
			await get_tree().process_frame
			return
	Audio.sfx("click", -10.0)
	doc_layer.visible = true
	var i := 0
	while i >= 0 and i < pages.size():
		doc_title.text = title
		doc_text.text = pages[i]
		doc_page.text = "%d / %d" % [i + 1, pages.size()]
		doc_prev.disabled = i == 0
		doc_next.text = "Next ▶" if i < pages.size() - 1 else "Close"
		if GameState.test_show_ui:
			buttons_shown.emit("doc_%d" % i)
			get_tree().create_timer(1.4).timeout.connect(func() -> void: doc_turn.emit(1))
		var step: int = await doc_turn
		Audio.sfx("click", -14.0)
		i = maxi(0, i + step) if step < 0 else i + step
	doc_layer.visible = false


# --- crossing ----------------------------------------------------------------------

## The screen tears for a moment, the way a station drifts.
func glitch(dur: float = 1.2) -> void:
	glitch_fx.left = dur
	glitch_fx.total = dur


# --- pause ---------------------------------------------------------------------

func open_pause() -> void:
	if pause_panel.visible or not top_bar.visible:
		return
	pause_panel.visible = true
	blocker.visible = true
	get_tree().paused = true


func close_pause() -> void:
	pause_panel.visible = false
	if not _dialog_open and not _choosing:
		blocker.visible = false
	get_tree().paused = false


func toggle_pause() -> void:
	if pause_panel.visible:
		close_pause()
	else:
		open_pause()


# --- fades, title cards, toasts ------------------------------------------------------

func fade_out(dur: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, dur)
	await tw.finished


func fade_in(dur: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, dur)
	await tw.finished


## Big text on a black screen. Call fade_out() first.
func card(title: String, sub: String = "", hold: float = 2.5, flicker: bool = false) -> void:
	card_title.text = title
	card_sub.text = sub
	card_title.visible = true
	card_sub.visible = sub != ""
	card_title.add_theme_font_size_override("font_size", 86 if flicker else 52)
	card_title.modulate.a = 0.0
	card_sub.modulate.a = 0.0
	_flicker = flicker
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card_title, "modulate:a", 1.0, 0.8)
	tw.tween_property(card_sub, "modulate:a", 1.0, 0.8)
	await tw.finished
	await get_tree().create_timer(hold).timeout
	_flicker = false
	card_title.position.x = 0.0
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(card_title, "modulate:a", 0.0, 0.7)
	tw2.tween_property(card_sub, "modulate:a", 0.0, 0.7)
	await tw2.finished
	card_title.visible = false
	card_sub.visible = false


func toast(text: String) -> void:
	toast_label.text = text
	var tw := create_tween()
	tw.tween_property(toast_label, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.2)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.6)


# --- inventory slot -------------------------------------------------------------------

## A square inventory button that draws its item instead of using a texture.
class ItemSlot extends Button:
	var item_id := ""
	var selected := false

	func _init(id: String) -> void:
		item_id = id
		custom_minimum_size = Vector2(72, 72)
		focus_mode = Control.FOCUS_NONE
		tooltip_text = GameState.item_name(id)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var c := r.get_center()
		if selected:
			draw_rect(r.grow(-3.0), Color(0.91, 0.65, 0.29, 0.22))
			draw_rect(r.grow(-3.0), Color(0.91, 0.65, 0.29), false, 3.0)
		match item_id:
			"red_tape":
				draw_circle(c, 23.0, Color("b8322c"))
				draw_arc(c, 23.0, 0.0, TAU, 32, Color("dc5b4f"), 2.0)
				draw_circle(c, 10.0, Color("15181d"))
				draw_line(c + Vector2(18, 12), c + Vector2(30, 26), Color("b8322c"), 6.0)
			"fuse":
				draw_rect(Rect2(c.x - 19, c.y - 7, 38, 14), Color(0.75, 0.86, 0.92, 0.45))
				draw_rect(Rect2(c.x - 27, c.y - 9, 9, 18), Color("b9b6aa"))
				draw_rect(Rect2(c.x + 18, c.y - 9, 9, 18), Color("b9b6aa"))
				draw_line(Vector2(c.x - 18, c.y), Vector2(c.x + 18, c.y + 1), Color("efe6c4"), 1.5)
			"note":
				var pts := PackedVector2Array([c + Vector2(-20, -17), c + Vector2(19, -21), c + Vector2(22, 17), c + Vector2(-17, 20)])
				draw_colored_polygon(pts, Color("e6dfc8"))
				for i in 4:
					var y := -10.0 + i * 7.0
					draw_line(c + Vector2(-12, y), c + Vector2(12, y - 1), Color("3a3a44"), 1.5)
			"keys":
				draw_arc(c + Vector2(-8, -8), 13.0, 0.0, TAU, 24, Color("b9b6aa"), 3.0)
				var kc := [Color("c9a332"), Color("b9b6aa"), Color("9aa3a8")]
				for i in 3:
					var a := 0.5 + i * 0.45
					var base := c + Vector2(-8, -8) + Vector2(cos(a), sin(a)) * 13.0
					var tip := base + Vector2(cos(a), sin(a)) * 24.0
					draw_line(base, tip, kc[i], 5.0)
					draw_line(tip - Vector2(cos(a), sin(a)) * 6.0, tip - Vector2(cos(a), sin(a)) * 6.0 + Vector2(-sin(a), cos(a)) * 6.0, kc[i], 3.0)
			"scarf":
				var pts := PackedVector2Array()
				for i in 9:
					pts.append(c + Vector2(-26 + i * 6.5, sin(i * 0.9) * 7.0 - 4.0))
				draw_polyline(pts, Color("3e5a46"), 14.0)
				for i in range(1, 9, 2):
					draw_line(pts[i] + Vector2(0, -6), pts[i] + Vector2(0, 6), Color("8a2f2a"), 4.0)
				draw_line(pts[8], pts[8] + Vector2(4, 22), Color("3e5a46"), 10.0)
			"flashlight_dead", "flashlight":
				var on := item_id == "flashlight"
				if on:
					draw_colored_polygon(PackedVector2Array([c + Vector2(14, -6), c + Vector2(34, -18), c + Vector2(34, 18), c + Vector2(14, 6)]), Color(1.0, 0.92, 0.6, 0.35))
				draw_rect(Rect2(c.x - 26, c.y - 6, 30, 12), Color("2b2d31"))
				draw_rect(Rect2(c.x + 2, c.y - 10, 12, 20), Color("4a4d52"))
				draw_rect(Rect2(c.x + 12, c.y - 8, 3, 16), Color("fff2c8") if on else Color("5a5e66"))
				draw_rect(Rect2(c.x - 16, c.y - 9, 6, 4), Color("b8322c"))
			"batteries":
				for i in 2:
					var x := c.x - 18 + i * 20
					draw_rect(Rect2(x, c.y - 18, 16, 36), Color("23252a"))
					draw_rect(Rect2(x, c.y - 4, 16, 8), Color("c9a332"))
					draw_rect(Rect2(x + 5, c.y - 22, 6, 4), Color("b9b6aa"))
			"tuner":
				draw_rect(Rect2(c.x - 26, c.y - 14, 52, 32), Color("4a5a3a"))
				draw_rect(Rect2(c.x - 20, c.y - 9, 32, 11), Color("d8a24a"))
				draw_line(Vector2(c.x - 6, c.y - 9), Vector2(c.x - 6, c.y + 2), Color("e0453a"), 2.0)
				draw_circle(Vector2(c.x + 18, c.y + 8), 5.0, Color("2a2f25"))
				draw_line(Vector2(c.x + 20, c.y - 14), Vector2(c.x + 30, c.y - 32), Color("9aa0a6"), 2.0)
				draw_rect(Rect2(c.x - 22, c.y + 6, 18, 6), Color("e6dfc8"))
			_:
				draw_circle(c, 18.0, Color("777777"))


## Torn horizontal bands and a pale flash, drawn over everything for a moment.
class GlitchFX extends Control:
	var left := 0.0
	var total := 1.0

	func _process(delta: float) -> void:
		if left > 0.0:
			left -= delta
			queue_redraw()

	func _draw() -> void:
		if left <= 0.0:
			return
		var k := clampf(left / total, 0.0, 1.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = Time.get_ticks_msec() / 45
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.7, 0.9, 1.0, 0.3 * k * k))
		var cols := [Color(0.4, 0.9, 1.0), Color(1.0, 0.32, 0.3), Color(0.92, 0.92, 0.92), Color(0.0, 0.0, 0.0)]
		for i in 22:
			var y := rng.randf_range(0.0, size.y)
			var h := rng.randf_range(2.0, 34.0)
			var x := rng.randf_range(-260.0, 260.0)
			var col: Color = cols[i % 4]
			col.a = rng.randf_range(0.2, 0.6) * k
			draw_rect(Rect2(x, y, size.x, h), col)
		var y2 := 0.0
		while y2 < size.y:
			draw_line(Vector2(0, y2), Vector2(size.x, y2), Color(0, 0, 0, 0.12 * k), 1.0)
			y2 += 4.0
