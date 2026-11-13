class_name RadioFix
extends Control
## The opening's one hands-on moment: Mara holds the flashlight on the open
## back of Tomas's radio while he fixes a loose battery contact. The player
## drags the light; Tomas says where. Nothing can go wrong and nothing is
## timed: the light just has to rest where he needs it.

signal done

const BEAM := 150.0
const LINES := [
	"Shine it on the back. I can't see a thing.",
	"Down a bit. The batteries, bottom left.",
	"There. Hold it there. The spring's come loose.",
]
## How long the light has to rest on each spot (seconds).
const HOLD := [0.5, 0.7, 1.3]

static var _mask: ImageTexture

var stage := 0
var _hold := 0.0
var _beam := Vector2.ZERO
var _aim := Vector2.ZERO
var _t := 0.0
var _spark := 0.0
var _finished := false
var _tool := 0.0  # 0: hand resting, 1: screwdriver on the contact
var _caption: Label
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0.0
	if _mask == null:
		_mask = _make_mask()
	_caption = Label.new()
	_caption.add_theme_font_size_override("font_size", 26)
	_caption.add_theme_color_override("font_color", Color("f2e6cf"))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_caption.add_theme_constant_override("shadow_offset_x", 2)
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_caption.offset_top = 30.0
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_hint = Label.new()
	_hint.text = "Drag to move the light."
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.add_theme_color_override("font_color", Color("a7b9ba"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -46.0
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_set_line()
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)


## Shows the close-up and waits until the contact is fixed.
func run() -> void:
	if GameState.test_mode:
		_autoplay()
	await done


func _set_line() -> void:
	_caption.text = "TOMAS:  " + LINES[mini(stage, LINES.size() - 1)]


# --- layout: everything is placed relative to the radio's case -------------------------

func _case() -> Rect2:
	var c := size * 0.5 + Vector2(0, 30)
	return Rect2(c - Vector2(330, 190), Vector2(660, 380))


func _batteries() -> Rect2:
	var r := _case()
	return Rect2(r.position + Vector2(52, 220), Vector2(250, 120))


func _contact() -> Vector2:
	var b := _batteries()
	return b.position + Vector2(-6, b.size.y * 0.5)


func _target_ok() -> bool:
	match stage:
		0:
			return _case().grow(-40).has_point(_beam)
		1:
			return _batteries().grow(40).has_point(_beam)
		_:
			return _beam.distance_to(_contact()) < 70.0


# --- input and play ----------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if _finished:
		return
	if event is InputEventMouseButton and event.pressed:
		_aim = event.position
	elif event is InputEventMouseMotion:
		_aim = event.position
	accept_event()


func _process(delta: float) -> void:
	_t += delta
	if _aim == Vector2.ZERO and size.x > 0.0:
		# Start the light up and to one side, off the radio.
		_aim = Vector2(size.x * 0.5, size.y * 0.16)
		_beam = _aim
	_beam = _beam.lerp(_aim, minf(1.0, delta * 14.0))
	_spark = maxf(0.0, _spark - delta * 2.5)
	if stage >= 2:
		_tool = minf(1.0, _tool + delta * 1.6)
	if not _finished:
		if _target_ok():
			_hold += delta
			if _hold >= HOLD[stage]:
				_advance()
		else:
			_hold = maxf(0.0, _hold - delta * 0.5)
	queue_redraw()


func _advance() -> void:
	_hold = 0.0
	stage += 1
	if stage < LINES.size():
		_set_line()
		Audio.sfx("click", -18.0, 1.4)
		return
	_finished = true
	_spark = 1.0
	Audio.sfx("plug", -10.0)
	_caption.text = "TOMAS:  Got it."
	_hint.visible = false
	await get_tree().create_timer(0.9).timeout
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	await tw.finished
	done.emit()
	queue_free()


## Test runs: rest the light on each spot in turn.
func _autoplay() -> void:
	while not _finished and is_inside_tree():
		await get_tree().process_frame
		if size.x <= 0.0:
			continue
		var p: Vector2 = [_case().get_center(), _batteries().get_center(), _contact()][mini(stage, 2)]
		_aim = p
		_beam = p


# --- drawing ------------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.04))
	# Snow falling past, lit only where the light is.
	for i in 40:
		var p := Vector2(fposmod(i * 197.3 + _t * 30.0, size.x), fposmod(i * 89.7 + _t * 70.0 * (0.6 + 0.4 * sin(i)), size.y))
		draw_circle(p, 1.5 + (i % 3), Color(1, 1, 1, 0.5))
	_draw_radio()
	_draw_hand()
	# The dark everywhere but the beam.
	var r := BEAM * 2.2
	var hole := Rect2(_beam - Vector2(r, r), Vector2(r, r) * 2.0)
	draw_texture_rect(_mask, hole, false)
	var dark := Color(0.0, 0.0, 0.01, 0.93)
	draw_rect(Rect2(0, 0, size.x, maxf(0.0, hole.position.y)), dark)
	draw_rect(Rect2(0, hole.end.y, size.x, maxf(0.0, size.y - hole.end.y)), dark)
	draw_rect(Rect2(0, hole.position.y, maxf(0.0, hole.position.x), hole.size.y), dark)
	draw_rect(Rect2(hole.end.x, hole.position.y, maxf(0.0, size.x - hole.end.x), hole.size.y), dark)
	draw_circle(_beam, BEAM * 0.9, Color(1.0, 0.86, 0.55, 0.07))
	if _spark > 0.0:
		var c := _contact()
		for k in 7:
			var a := k * 0.9 + _t * 3.0
			draw_line(c, c + Vector2(cos(a), sin(a)) * 26.0 * _spark, Color(1.0, 0.9, 0.5, _spark), 2.0)
		draw_circle(c, 14.0 * _spark, Color(1.0, 0.95, 0.7, 0.8 * _spark))
	# Progress: a ring that fills while the light rests in the right place.
	if not _finished and _hold > 0.0:
		var f := clampf(_hold / HOLD[stage], 0.0, 1.0)
		draw_arc(_beam, 26.0, -PI / 2.0, -PI / 2.0 + TAU * f, 32, Color(1.0, 0.85, 0.5, 0.75), 3.0, true)


## The open back of the radio he rebuilt: the green case, the board, the
## tuning gang, the speaker's magnet, the wires, four AA cells and the spring
## contact that's worked loose.
func _draw_radio() -> void:
	var r := _case()
	draw_rect(r.grow(14), Color("3a4a2e"))
	draw_rect(r.grow(14), Color("1c2416"), false, 3.0)
	draw_rect(r, Color("1d2418"))
	# Screw holes in the corners where the back panel came off.
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		draw_circle(c + (r.get_center() - c).normalized() * 6.0, 5.0, Color("101410"))
	# The circuit board.
	var board := Rect2(r.position + Vector2(40, 30), Vector2(400, 170))
	draw_rect(board, Color("2f5a3a"))
	for k in 9:
		var y := board.position.y + 12 + k * 17
		draw_line(Vector2(board.position.x + 8, y), Vector2(board.end.x - 8, y + (k % 3) * 2), Color("4c7a52"), 1.0)
	var parts := [Color("c9a04a"), Color("8a3a2e"), Color("3a5a8a"), Color("d0c8b0")]
	for k in 14:
		var p := board.position + Vector2(24 + (k % 7) * 52, 36 + (k / 7) * 70)
		draw_rect(Rect2(p, Vector2(26, 9)), Color("d8c8a0"))
		for b in 3:
			draw_rect(Rect2(p + Vector2(5 + b * 6, 0), Vector2(3, 9)), parts[(k + b) % 4])
	for k in 4:
		var p := board.position + Vector2(60 + k * 86, 120)
		draw_rect(Rect2(p, Vector2(22, 34)), Color("2a3a6a"))
		draw_rect(Rect2(p, Vector2(22, 6)), Color("9aa0a6"))
	# The tuning capacitor and the speaker.
	draw_rect(Rect2(r.position + Vector2(460, 34), Vector2(120, 86)), Color("8a9096"))
	for k in 7:
		draw_line(r.position + Vector2(470 + k * 15, 40), r.position + Vector2(470 + k * 15, 114), Color("5a6066"), 2.0)
	draw_circle(r.position + Vector2(520, 250), 82.0, Color("2a2a2a"))
	draw_circle(r.position + Vector2(520, 250), 40.0, Color("4a4a4c"))
	draw_circle(r.position + Vector2(520, 250), 18.0, Color("6a6a6c"))
	# Wires.
	var wires := [[Color("b8322c"), Vector2(300, 200), Vector2(330, 236), Vector2(470, 240)],
		[Color("1a1a1a"), Vector2(310, 205), Vector2(350, 300), Vector2(480, 290)],
		[Color("d8b830"), Vector2(150, 200), Vector2(120, 230), Vector2(70, 250)]]
	for w in wires:
		draw_polyline(PackedVector2Array([r.position + w[1], r.position + w[2], r.position + w[3]]), w[0], 3.0, true)
	# Four AA cells in their holder.
	var b := _batteries()
	draw_rect(b.grow(6), Color("141414"))
	for k in 4:
		var cell := Rect2(b.position + Vector2(18, 6 + k * 28), Vector2(212, 24))
		draw_rect(cell, Color("2a2a2c") if k % 2 == 0 else Color("b8322c"))
		draw_rect(Rect2(cell.position, Vector2(cell.size.x, 6)), Color(1, 1, 1, 0.12))
		draw_rect(Rect2(cell.end.x, cell.position.y + 7, 6, 10), Color("c0c4c8"))
		Kit.text(self, cell.position + Vector2(60, 18), "1.5V", 12, Color(1, 1, 1, 0.5))
	# The spring contact at the end of the holder, bent away from the cell.
	var c := _contact()
	var loose := 1.0 - (1.0 if _finished else 0.0)
	var pts := PackedVector2Array()
	for k in 9:
		pts.append(c + Vector2(-8.0 * loose - 4.0 + (6.0 if k % 2 == 0 else -6.0), -22.0 + k * 5.5))
	draw_polyline(pts, Color("d0d4d8"), 2.5, true)


## Tomas's hand from the bottom of the frame, a jeweller's screwdriver in it.
func _draw_hand() -> void:
	var c := _contact()
	var rest := _case().position + Vector2(300, 470)
	var tip := rest.lerp(c + Vector2(4, 6), _tool) + Vector2(sin(_t * 18.0), cos(_t * 15.0)) * (1.5 if _tool > 0.9 and not _finished else 0.0)
	var dir := Vector2(0.62, 0.78)
	var grip := tip + dir * 70.0
	draw_line(tip, tip + dir * 40.0, Color("c0c4c8"), 3.0)
	draw_line(tip + dir * 40.0, grip, Color("b8322c"), 9.0)
	var skin := Color("dfb093")
	var sleeve := Color("b4352b")
	draw_colored_polygon(PackedVector2Array([grip + Vector2(-14, -6), grip + Vector2(16, -10), grip + Vector2(30, 22),
		grip + Vector2(6, 34), grip + Vector2(-16, 16)]), skin)
	draw_line(grip + Vector2(-10, 0), tip + dir * 52.0 + Vector2(-8, -4), skin, 7.0)
	draw_colored_polygon(PackedVector2Array([grip + Vector2(0, 24), grip + Vector2(34, 16), grip + Vector2(120, 200),
		grip + Vector2(40, 220)]), sleeve)


static func _make_mask() -> ImageTexture:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var a := smoothstep(0.36, 0.98, d) * 0.93
			img.set_pixel(x, y, Color(0.0, 0.0, 0.01, a))
	return ImageTexture.create_from_image(img)
