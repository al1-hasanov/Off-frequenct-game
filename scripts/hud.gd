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
signal chapter_chosen(pick: Dictionary)
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
const C_HINT := Color("8fd6a0")

var main: Node
var root: Control
var top_bar: Control
var clock_label: Label
var place_label: Label
var objective_label: Label
var inv_box: HBoxContainer
var hint_button: Button
var menu_button: Button
var notebook_button: Button
var _nb_dot: Panel
var notebook_layer: ColorRect
var _nb_seen_list: VBoxContainer
var _nb_theory_list: VBoxContainer
var _nb_status: Label
var _nb_connect: Button
var _nb_selected: Array[String] = []
## How many notebook entries the player has already looked at (for the dot).
var _nb_read := 0
var blocker: Control
var dialog_panel: PanelContainer
var speaker_label: Label
var text_label: RichTextLabel
var more_label: Label
var choice_box: VBoxContainer
var menu_box: VBoxContainer
var pause_panel: PanelContainer
var pause_menu_button: Button
var audio_settings: AudioSettings
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
var chapter_layer: ColorRect
var _ch_grid: GridContainer
var _ch_tabs := {}
var _ch_tab := "Prologue"
var _ch_answered := true
var _ch_took := true

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
	tuner.tuned.connect(func(st: String) -> void:
		if main != null and main.room != null:
			main.room.tuning = st)
	_build_dialog()
	_build_choices()
	_build_menus()
	_build_doc()
	_build_cards()
	_build_film()
	audio_settings = AudioSettings.new()
	root.add_child(audio_settings)
	_build_fps()
	GameState.changed.connect(refresh)
	GameState.inventory_changed.connect(refresh_inventory)
	refresh()
	refresh_inventory()


func _process(delta: float) -> void:
	_update_fps(delta)
	Audio.set_dialogue(_dialog_open)
	Audio.set_tuning(tuner.visible)
	_blink += delta
	if not GameState.clock_frozen:
		var colon := ":" if fmod(_blink, 1.0) < 0.5 else " "
		clock_label.text = _clock(GameState.clock_text.replace(":", colon))
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


# --- the opening's film: captions and Skip -------------------------------------------

## A line along the bottom of the picture that fades in and out by itself,
## for what a scene shows or sounds like (the player doesn't tap it away).
var caption_label: Label
var skip_button: Button
## Set when the player presses Skip during the aftermath film.
var skip_requested := false
var _caption_tw: Tween


func _build_film() -> void:
	caption_label = Label.new()
	caption_label.add_theme_font_size_override("font_size", 24)
	caption_label.add_theme_color_override("font_color", Color("dfe3dc"))
	caption_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	caption_label.add_theme_constant_override("shadow_offset_x", 2)
	caption_label.add_theme_constant_override("shadow_offset_y", 2)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.anchor_left = 0.1
	caption_label.anchor_right = 0.9
	caption_label.anchor_top = 1.0
	caption_label.anchor_bottom = 1.0
	caption_label.offset_top = -168.0
	caption_label.offset_bottom = -92.0
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_label.modulate.a = 0.0
	root.add_child(caption_label)
	skip_button = Button.new()
	skip_button.text = "Skip  ▸"
	skip_button.custom_minimum_size = Vector2(150, 60)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.anchor_top = 1.0
	skip_button.anchor_bottom = 1.0
	skip_button.offset_left = -176.0
	skip_button.offset_right = -22.0
	skip_button.offset_top = -82.0
	skip_button.offset_bottom = -20.0
	skip_button.visible = false
	skip_button.pressed.connect(request_skip)
	root.add_child(skip_button)


## Shows a caption for `hold` seconds. Awaitable, but nothing has to wait.
func caption(text: String, hold: float = 3.0) -> void:
	if GameState.test_mode:
		print("    [caption] %s" % text)
	caption_label.text = text
	if _caption_tw != null and _caption_tw.is_valid():
		_caption_tw.kill()
	_caption_tw = create_tween()
	_caption_tw.tween_property(caption_label, "modulate:a", 1.0, 0.45)
	_caption_tw.tween_interval(maxf(0.2, hold))
	_caption_tw.tween_property(caption_label, "modulate:a", 0.0, 0.6)
	await _caption_tw.finished


func clear_caption() -> void:
	if _caption_tw != null and _caption_tw.is_valid():
		_caption_tw.kill()
	caption_label.modulate.a = 0.0


func show_skip(on: bool) -> void:
	skip_requested = false
	skip_button.visible = on


## Skip: the film checks skip_requested between beats; a line on screen is let go.
func request_skip() -> void:
	skip_requested = true
	skip_button.visible = false
	if _caption_tw != null and _caption_tw.is_valid():
		_caption_tw.kill()
	caption_label.modulate.a = 0.0
	if _dialog_open and not _choosing:
		advance.emit()


## The frame-rate counter (Settings → Show frame rate): frames per second, and
## the slowest frame's CPU time in the last second; over everything, bottom left.
var fps_label: Label
var _fps_acc := 0.0


func _build_fps() -> void:
	fps_label = _label("", 15, Color("cfe8d0"))
	fps_label.anchor_top = 1.0
	fps_label.anchor_bottom = 1.0
	fps_label.offset_left = 10.0
	fps_label.offset_top = -30.0
	fps_label.offset_bottom = -8.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	bg.content_margin_left = 8
	bg.content_margin_right = 8
	bg.set_corner_radius_all(4)
	fps_label.add_theme_stylebox_override("normal", bg)
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_label.visible = false
	root.add_child(fps_label)


func _update_fps(delta: float) -> void:
	fps_label.visible = DisplaySettings.show_fps
	if not fps_label.visible:
		return
	_fps_acc += delta
	if _fps_acc < 0.5:
		return
	_fps_acc = 0.0
	var ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	fps_label.text = "%d fps · %.0f ms peak" % [Engine.get_frames_per_second(), ms]


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
	right.offset_left = -900.0
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
	notebook_button = _icon_button("")
	notebook_button.icon = _notebook_icon()
	notebook_button.tooltip_text = "Notebook: what Mara has seen, and what she thinks"
	notebook_button.visible = false
	notebook_button.pressed.connect(func() -> void:
		if main != null and not main.is_busy():
			open_notebook())
	right.add_child(notebook_button)
	_nb_dot = Panel.new()
	var dot := StyleBoxFlat.new()
	dot.bg_color = C_ACCENT
	dot.set_corner_radius_all(7)
	_nb_dot.add_theme_stylebox_override("panel", dot)
	_nb_dot.size = Vector2(14, 14)
	_nb_dot.position = Vector2(52, 6)
	_nb_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nb_dot.visible = false
	notebook_button.add_child(_nb_dot)
	hint_button = _icon_button("?")
	hint_button.tooltip_text = "Hint: what to do next"
	hint_button.pressed.connect(func() -> void:
		if main != null and not main.is_busy():
			main.show_hint())
	right.add_child(hint_button)
	menu_button = _icon_button("II")
	menu_button.tooltip_text = "Pause"
	menu_button.pressed.connect(open_pause)
	right.add_child(menu_button)


## "2:14" is the small hours; a future can be in the afternoon ("2:14 PM").
static func _clock(t: String) -> String:
	return t if t.ends_with("AM") or t.ends_with("PM") else t + " AM"


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
	menu_box.anchor_top = 0.68
	menu_box.anchor_bottom = 0.68
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
	var sound := Button.new()
	sound.text = "Settings"
	sound.custom_minimum_size = Vector2(440, 64)
	sound.pressed.connect(func() -> void: audio_settings.open())
	v.add_child(sound)
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
	var notes := Notebook.count()
	notebook_button.visible = notes > 0
	if notes < _nb_read:
		_nb_read = notes  # a new game
	_nb_dot.visible = notes > _nb_read
	if notes > 0 and not GameState.has("nb_intro"):
		_notebook_intro.call_deferred()
	clock_label.text = _clock(GameState.clock_text)
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
	# Act 3 fills Mara's pockets: past six things the slots shrink to fit.
	var n := maxi(1, GameState.inventory.size())
	var slot_px := clampf(floorf((900.0 - 3.0 * 82.0 + 8.0) / n - 8.0), 50.0, 72.0)
	for id in GameState.inventory:
		var slot := ItemSlot.new(id)
		slot.custom_minimum_size = Vector2(slot_px, slot_px)
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
	elif speaker == "HINT":
		sc = C_HINT
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
	elif speaker == "HINT":
		text_label.text = "[color=#d8f0de]%s[/color]" % safe
	elif tape:
		text_label.text = "[color=#e6dcc0]%s[/color]" % safe
	else:
		text_label.text = safe
	more_label.modulate.a = 0.0
	if GameState.test_mode:
		print("    %s: %s" % [speaker if speaker != "" else "(narration)", text])
	if not Audio.play_voice(speaker, text) and voice:
		# No recording yet: the squelch opens on a fading carrier under the words.
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
	items.append(["Settings", "audio"])
	if OS.is_debug_build():
		items.append(["Chapters (debug)", "chapters"])
	if OS.get_name() != "iOS":
		items.append(["Quit", "quit"])
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.custom_minimum_size = Vector2(440, 60)
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


# --- chapter select (debug) ---------------------------------------------------------

## Debug screen: pick a chapter and how Choice 1 and Choice 2 went.
## Returns {id, answered, took}, or {} for Back.
func chapter_select() -> Dictionary:
	if chapter_layer == null:
		_build_chapter_select()
	_fill_chapters()
	chapter_layer.visible = true
	var pick: Dictionary = await chapter_chosen
	chapter_layer.visible = false
	Audio.sfx("click", -8.0)
	return pick


func _build_chapter_select() -> void:
	chapter_layer = ColorRect.new()
	chapter_layer.color = Color(0.015, 0.02, 0.035, 0.97)
	chapter_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chapter_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	chapter_layer.visible = false
	root.add_child(chapter_layer)
	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.offset_left = -600.0
	v.offset_right = 600.0
	v.offset_top = 22.0
	v.add_theme_constant_override("separation", 14)
	chapter_layer.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	head.add_child(tv)
	tv.add_child(_label("Chapter select", 34, C_TEXT))
	tv.add_child(_label("Debug. Starts the chapter as a full playthrough reached it. Replaces your save.", 18, C_DIM))
	var back := _ch_button("Back", Vector2(170, 60))
	back.pressed.connect(func() -> void: chapter_chosen.emit({}))
	head.add_child(back)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var tabs := ButtonGroup.new()
	for act in Chapters.ACTS:
		var b := _ch_button(act, Vector2(180, 56))
		b.toggle_mode = true
		b.button_group = tabs
		b.button_pressed = act == _ch_tab
		_ch_tabs[act] = b
		b.pressed.connect(func() -> void:
			_ch_tab = act
			_fill_chapters())
		row.add_child(b)

	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 10)
	v.add_child(choices)
	_ch_toggle(choices, "Choice 1", ["Answered", "Cut the power"], _ch_answered,
		func(first: bool) -> void: _ch_answered = first)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(24, 0)
	choices.add_child(gap)
	_ch_toggle(choices, "Choice 2", ["Took Tomas", "Left Tomas"], _ch_took,
		func(first: bool) -> void: _ch_took = first)

	_ch_grid = GridContainer.new()
	_ch_grid.columns = 2
	_ch_grid.add_theme_constant_override("h_separation", 14)
	_ch_grid.add_theme_constant_override("v_separation", 12)
	v.add_child(_ch_grid)


func _ch_button(text: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	return b


## A label and two toggle buttons; `set_first(true)` when the first is picked.
func _ch_toggle(parent: Control, title: String, names: Array, first: bool, set_first: Callable) -> void:
	var l := _label(title, 20, C_DIM)
	l.custom_minimum_size = Vector2(96, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_FILL
	parent.add_child(l)
	var group := ButtonGroup.new()
	for i in 2:
		var b := _ch_button(names[i], Vector2(176, 54))
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = (i == 0) == first
		b.pressed.connect(func() -> void: set_first.call(i == 0))
		parent.add_child(b)


func _fill_chapters() -> void:
	for c in _ch_grid.get_children():
		c.queue_free()
	for ch in Chapters.in_act(_ch_tab):
		var b := _ch_button("", Vector2(593, 96))
		var m := VBoxContainer.new()
		m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		m.offset_left = 18.0
		m.offset_right = -18.0
		m.offset_top = 12.0
		m.offset_bottom = -10.0
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.add_theme_constant_override("separation", 4)
		b.add_child(m)
		var top := HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.add_child(top)
		var t := _label("%s   %s" % [ch.num, ch.title], 26, C_TEXT)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		var needs := Chapters.needs(ch.id)
		if needs > 0:
			top.add_child(_label("Choice 1" if needs == 1 else "Choices 1 + 2", 17, C_ACCENT))
		m.add_child(_label(ch.blurb, 19, C_DIM))
		var id: String = ch.id
		b.pressed.connect(func() -> void:
			chapter_chosen.emit({"id": id, "answered": _ch_answered, "took": _ch_took}))
		_ch_grid.add_child(b)


# --- the Tuner ---------------------------------------------------------------------

## Opens Tomas's radio and waits until Mara steps through a station the room
## accepts. `refuse(station)` returns "" to accept, or a line Mara says instead.
## Returns the station, or "" if she switched the radio off.
func tune(refuse: Callable, start: float = 0.0, start_band: int = 0) -> String:
	tuner.open(start, start_band)
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

# --- the notebook ----------------------------------------------------------------

func _notebook_intro() -> void:
	if GameState.has("nb_intro"):
		return
	GameState.set_flag("nb_intro")
	toast("New: Mara's notebook (top bar). What she's seen, and what she thinks it means.")


## A small drawn notebook for the top-bar button.
func _notebook_icon() -> ImageTexture:
	# A brown leather notebook with an elastic band and a pencil: not a sheet of paper.
	var img := Image.create(46, 46, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(6, 4, 30, 38), Color("5a3a24"))
	img.fill_rect(Rect2i(8, 6, 26, 34), Color("7a5232"))
	img.fill_rect(Rect2i(6, 4, 5, 38), Color("3e2818"))
	img.fill_rect(Rect2i(28, 4, 3, 38), Color("c8322a"))
	img.fill_rect(Rect2i(14, 16, 14, 8), Color("e9dfc6"))
	for i in 18:
		var x := 22 + i
		var y := 40 - i * 2
		if x < 46 and y >= 0:
			img.fill_rect(Rect2i(x, y, 3, 3), Color("e8b43a"))
	img.fill_rect(Rect2i(38, 4, 3, 3), Color("2a2420"))
	return ImageTexture.create_from_image(img)


## Opens the notebook: what Mara has seen and heard on the left, what she
## thinks on the right. Tap two notes and Connect them.
func open_notebook() -> void:
	if notebook_layer == null:
		_build_notebook()
	_nb_selected.clear()
	_nb_status.text = "Tap two notes that belong together, then Connect."
	_fill_notebook()
	notebook_layer.visible = true
	_nb_read = Notebook.count()
	_nb_dot.visible = false
	Audio.sfx("click", -12.0)


func close_notebook() -> void:
	if notebook_layer != null:
		notebook_layer.visible = false
	_nb_read = Notebook.count()
	_nb_dot.visible = false


func _build_notebook() -> void:
	notebook_layer = ColorRect.new()
	notebook_layer.color = Color(0.02, 0.025, 0.035, 0.96)
	notebook_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	notebook_layer.visible = false
	root.add_child(notebook_layer)
	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_bottom = 1.0
	v.offset_left = -610.0
	v.offset_right = 610.0
	v.offset_top = 20.0
	v.offset_bottom = -18.0
	v.add_theme_constant_override("separation", 10)
	notebook_layer.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("Notebook", 34, C_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := _ch_button("Close", Vector2(170, 58))
	close.pressed.connect(close_notebook)
	head.add_child(close)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 18)
	v.add_child(cols)
	_nb_seen_list = _nb_column(cols, "Seen & heard", 1.35)
	_nb_theory_list = _nb_column(cols, "What I think", 1.0)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	v.add_child(foot)
	_nb_status = _label("", 20, C_DIM)
	_nb_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nb_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nb_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(_nb_status)
	_nb_connect = _ch_button("Connect", Vector2(200, 60))
	_nb_connect.pressed.connect(_nb_try_connect)
	foot.add_child(_nb_connect)


func _nb_column(parent: Control, heading: String, ratio: float) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = ratio
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)
	col.add_child(_label(heading, 22, C_ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list


func _fill_notebook() -> void:
	for c in _nb_seen_list.get_children():
		c.queue_free()
	for c in _nb_theory_list.get_children():
		c.queue_free()
	for e in Notebook.seen():
		var b := Button.new()
		b.text = e.text
		b.toggle_mode = true
		b.button_pressed = _nb_selected.has(e.id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 58)
		b.focus_mode = Control.FOCUS_NONE
		# PASS, so a drag on a note still scrolls the list on a phone.
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		b.add_theme_font_size_override("font_size", 19)
		var id: String = e.id
		b.toggled.connect(func(on: bool) -> void: _nb_toggle(id, on))
		_nb_seen_list.add_child(b)
	var theories := Notebook.theories()
	if theories.is_empty():
		_nb_theory_list.add_child(_label("Nothing yet. Connect two notes that belong together.", 19, C_DIM))
	for t in theories:
		var l := _label("• " + str(t.text), 19, C_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(300, 0)
		_nb_theory_list.add_child(l)
	_nb_connect.disabled = _nb_selected.size() != 2


func _nb_toggle(id: String, on: bool) -> void:
	if on and not _nb_selected.has(id):
		_nb_selected.append(id)
		if _nb_selected.size() > 2:
			_nb_selected.pop_front()
			_fill_notebook()
	elif not on:
		_nb_selected.erase(id)
	_nb_connect.disabled = _nb_selected.size() != 2


func _nb_try_connect() -> void:
	if _nb_selected.size() != 2:
		return
	var got := Notebook.connect_notes(_nb_selected[0], _nb_selected[1])
	_nb_selected.clear()
	if got == "":
		_nb_status.text = "Those two don't connect. Not yet, anyway."
		Audio.sfx("click", -12.0)
	elif got == "known":
		_nb_status.text = "I've already worked that one out."
	else:
		_nb_status.text = "New theory: " + Notebook.theory_text(got)
		Audio.sfx("powerup", -16.0)
	_fill_notebook()
	_nb_read = Notebook.count()


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
	if audio_settings.visible:
		audio_settings.close()
		return
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
	# After a whiteout the next fade is black again.
	fade_rect.color = Color(0, 0, 0, fade_rect.color.a)


## The Silence arriving in a future: the screen goes white. The next room
## comes up out of the white (fade_in), and the fade is black again after.
func whiteout(dur: float = 1.2) -> void:
	fade_rect.color = Color(0.95, 0.96, 0.98, fade_rect.color.a)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, dur)
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
		# Icons are drawn for a 72 px slot; a smaller slot scales them about its centre.
		var k := size.x / 72.0
		if k < 0.99:
			draw_set_transform(c * (1.0 - k), 0.0, Vector2(k, k))
		match item_id:
			"red_tape", "blue_tape":
				var tc := Color("b8322c") if item_id == "red_tape" else Color("2f63c9")
				draw_circle(c, 23.0, tc)
				draw_arc(c, 23.0, 0.0, TAU, 32, tc.lightened(0.25), 2.0)
				draw_circle(c, 10.0, Color("15181d"))
				draw_line(c + Vector2(18, 12), c + Vector2(30, 26), tc, 6.0)
			"doormat":
				draw_rect(Rect2(c.x - 28, c.y - 16, 56, 32), Color("5a4430"))
				draw_rect(Rect2(c.x - 24, c.y - 12, 48, 24), Color("6e5438"), false, 2.0)
				Kit.text(self, Vector2(c.x - 24, c.y + 5), "WELC", 11, Color("c9b48a"), HORIZONTAL_ALIGNMENT_CENTER, 48)
			"crystal":
				draw_rect(Rect2(c.x - 12, c.y - 16, 24, 26), Color("9aa3a8"))
				draw_rect(Rect2(c.x - 12, c.y - 16, 24, 26), Color("cfd6da"), false, 2.0)
				draw_line(Vector2(c.x - 6, c.y + 10), Vector2(c.x - 6, c.y + 22), Color("c9a332"), 2.0)
				draw_line(Vector2(c.x + 6, c.y + 10), Vector2(c.x + 6, c.y + 22), Color("c9a332"), 2.0)
			"truck_keys":
				draw_arc(c + Vector2(-10, -8), 9.0, 0.0, TAU, 16, Color("b9b6aa"), 3.0)
				draw_line(c + Vector2(-2, -2), c + Vector2(18, 16), Color("c9a332"), 5.0)
				draw_line(c + Vector2(12, 10), c + Vector2(8, 16), Color("c9a332"), 3.0)
				draw_circle(c + Vector2(-16, 14), 7.0, Color("e8e0d0"))
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
			"flashlight_dead", "flashlight", "flashlight_cold":
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
			"chain_sheet":
				draw_rect(Rect2(c.x - 20, c.y - 24, 40, 48), Color("e8e4d4"))
				for i in 6:
					draw_line(Vector2(c.x - 20, c.y - 20 + i * 8), Vector2(c.x + 20, c.y - 20 + i * 8), Color(0.55, 0.7, 0.8, 0.6), 1.0)
					draw_line(Vector2(c.x - 16 + i * 7, c.y - 24), Vector2(c.x - 16 + i * 7, c.y + 24), Color(0.55, 0.7, 0.8, 0.6), 1.0)
				draw_polyline(PackedVector2Array([c + Vector2(-12, -12), c + Vector2(4, -12), c + Vector2(4, 4), c + Vector2(14, 4)]), Color("2a3a6a"), 2.0)
				Kit.text(self, c + Vector2(-14, 20), "Λ.L.", 9, Color("2a3a6a"))
			"transmit_key":
				draw_arc(c + Vector2(-14, -14), 11.0, 0.0, TAU, 20, Color("8a2a24"), 3.0)
				draw_line(c + Vector2(-6, -6), c + Vector2(18, 18), Color("c9a332"), 6.0)
				draw_line(c + Vector2(12, 12), c + Vector2(6, 18), Color("c9a332"), 4.0)
				draw_line(c + Vector2(16, 16), c + Vector2(10, 22), Color("c9a332"), 4.0)
				draw_circle(c + Vector2(-6, -6), 6.0, Color("d8b84a"))
			"fire_axe":
				draw_line(c + Vector2(-22, 24), c + Vector2(14, -18), Color("8a5a30"), 6.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(6, -26), c + Vector2(26, -14), c + Vector2(20, -2), c + Vector2(8, -12)]), Color("c4c8cc"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(6, -26), c + Vector2(0, -22), c + Vector2(8, -12)]), Color("b8322c"))
			"station_log":
				draw_rect(Rect2(c.x - 20, c.y - 24, 40, 48), Color("3a4a6a"))
				draw_rect(Rect2(c.x - 20, c.y - 24, 6, 48), Color("2a3448"))
				draw_rect(Rect2(c.x - 10, c.y - 12, 26, 12), Color("e6dfc8"))
				Kit.text(self, c + Vector2(-9, -3), "LOG", 9, Color("2a2a2a"))
			"chart_strips":
				draw_rect(Rect2(c.x - 26, c.y - 20, 52, 14), Color("ece6d0"))
				draw_rect(Rect2(c.x - 26, c.y + 4, 52, 14), Color("ece6d0"))
				draw_line(Vector2(c.x - 22, c.y - 12), Vector2(c.x + 22, c.y - 12), Color("b8322c"), 2.0)
				draw_line(Vector2(c.x - 22, c.y + 15), Vector2(c.x + 22, c.y + 7), Color("b8322c"), 2.0)
			"cassette_2031":
				draw_rect(Rect2(c.x - 26, c.y - 16, 52, 32), Color("2a2a2e"))
				draw_rect(Rect2(c.x - 20, c.y - 12, 40, 12), Color("e8e2d0"))
				draw_circle(c + Vector2(-10, 6), 5.0, Color("e8e2d0"))
				draw_circle(c + Vector2(10, 6), 5.0, Color("e8e2d0"))
			"revolver":
				draw_rect(Rect2(c.x - 16, c.y - 12, 34, 9), Color("3a3c40"))
				draw_circle(c + Vector2(-8, -2), 8.0, Color("4a4c50"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 2), c + Vector2(-6, 2), c + Vector2(-12, 24), c + Vector2(-22, 22)]), Color("6a4a30"))
				draw_arc(c + Vector2(-4, 8), 6.0, 0.0, PI, 8, Color("3a3c40"), 2.0)
			_:
				draw_circle(c, 18.0, Color("777777"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
