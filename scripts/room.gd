class_name Room
extends Node2D
## One screen of the game.
##
## Subclasses override:
##   setup()                 add actors and hotspots (read `freq` for this frequency's version)
##   enter(entry)            place the player depending on where she came from
##   on_arrive()             a coroutine that runs after the fade-in
##   draw_back()             draw the room behind the characters
##   draw_fore(ci)           draw anything in front of the characters
##   draw_glow(ci)           draw light sources: never darkened, drawn over the room
##   on_hotspot(id)          what happens when a hotspot is tapped
##   use_item(id, item)      using an inventory item on a hotspot; return true if handled
##   examine_item(item)      tapping a selected item again; return true to replace the description
##   is_dark()               true when the room is pitch black (flashlight or crossing territory)

const DARK := Color(0.035, 0.04, 0.06)
## Hotspots smaller than this (in px²) also catch taps up to TAP_SLACK px away.
const SMALL_HOTSPOT := 12000.0
const TAP_SLACK := 30.0
const CONE := preload("res://textures/cone.png")
const GLOW := preload("res://textures/glow.png")

var main: Node
var hud: Hud
var player: Actor
var hotspots: Array[Dictionary] = []
var floor_y := 650.0
var walk_top := 520.0
var walk_min := 70.0
var walk_max := 1210.0
var shows_hud := true
var is_story_room := true
var place_name := ""
var entered_from := ""
var base_tint := Color(0.86, 0.9, 1.0)
## Which version of this room: "H" (home), "01", "03"...
var freq := "H"
## Mara switches her flashlight off to use the Tuner.
var light_off := false
## The Tuner is open: its dial lights her up a little.
var tuner_glow := false
## The station the Tuner is locked on right now ("" if none): rooms can show a
## glimpse of that frequency behind the panel.
var tuning := ""
var t := 0.0
var fore: Node2D
var glow: Node2D
var hint: Node2D
var light: CanvasModulate
var _beam: PointLight2D
var _aura: PointLight2D
var _flash := 0.0


func _ready() -> void:
	light = CanvasModulate.new()
	add_child(light)
	fore = ForeLayer.new()
	fore.room = self
	fore.z_index = 10
	add_child(fore)
	glow = _layer(1, GlowLayer.new())
	hint = _layer(2, HintLayer.new())


func _layer(index: int, node: Node2D) -> Node2D:
	var cl := CanvasLayer.new()
	cl.layer = index
	cl.follow_viewport_enabled = true
	add_child(cl)
	node.set("room", self)
	cl.add_child(node)
	return node


func _process(delta: float) -> void:
	t += delta
	if _flash > 0.0:
		_flash -= delta
	if light != null:
		light.color = current_tint()
	_update_flashlight()
	queue_redraw()
	fore.queue_redraw()
	glow.queue_redraw()
	hint.queue_redraw()


func _draw() -> void:
	draw_back()


# --- overridables -------------------------------------------------------------

func setup() -> void:
	pass


func enter(_entry: String) -> void:
	pass


func on_arrive() -> void:
	pass


## Starts this room's ambience loops (also called after the Tuner closes).
func ambience() -> void:
	pass


func draw_back() -> void:
	pass


func draw_fore(_ci: CanvasItem) -> void:
	pass


func draw_glow(_ci: CanvasItem) -> void:
	pass


func on_hotspot(_id: String) -> void:
	pass


func use_item(_id: String, _item: String) -> bool:
	return false


func examine_item(item: String) -> bool:
	if item != "tuner":
		return false
	if can_tune():
		await tune()
	else:
		await mara(GameState.item_desc("tuner"))
		await mara(tune_refusal())
	return true


## Rooms where Tomas's radio can be used override these two.
func can_tune() -> bool:
	return false


func tune() -> void:
	pass


func tune_refusal() -> String:
	if not is_dark():
		return "It only works in the dark, Tomas said."
	return "Not here. I don't need a way out of this room. I need a way down the mountain."


## Opens the Tuner with the flashlight off. `refuse` returns "" to accept a
## station, or the line Mara says instead. Returns "" if she switched it off.
func tuner_session(refuse: Callable, start: float = 0.0, band: int = 0) -> String:
	light_off = true
	tuner_glow = true
	Audio.sfx("click", -6.0)
	var st: String = await hud.tune(refuse, start, band)
	tuner_glow = false
	if st == "":
		light_off = false
		Audio.sfx("click", -6.0)
	return st


func is_station() -> bool:
	return false


func is_dark() -> bool:
	return false


func current_tint() -> Color:
	var c := base_tint
	if GameState.emergency and is_station() and freq == "H":
		c = Color(1.0, 0.5, 0.47)
	if is_dark():
		c = DARK
	return c * GameState.freq_tint(freq)


## The beam is on when the room is dark, Mara carries a working light and hasn't switched it off.
func flashlight_on() -> bool:
	return player != null and is_dark() and GameState.has_light() and not light_off


# --- darkness -------------------------------------------------------------------

func _update_flashlight() -> void:
	if player == null:
		return
	var on := flashlight_on()
	player.holding_light = on and player.kind == "mara"
	var dark := is_dark()
	if not dark:
		if _beam != null:
			_beam.visible = false
			_aura.visible = false
		return
	if _beam == null:
		_beam = PointLight2D.new()
		_beam.texture = CONE
		_beam.texture_scale = 1.35
		_beam.energy = 1.5
		_beam.color = Color(1.0, 0.95, 0.82)
		player.add_child(_beam)
		_aura = PointLight2D.new()
		_aura.texture = GLOW
		_aura.texture_scale = 1.7
		_aura.position = Vector2(0, -95)
		player.add_child(_aura)
	_beam.visible = on
	# Eyes adjust: even with no light Mara stays faintly visible. The Tuner's dial glows cyan.
	_aura.visible = true
	if on:
		_aura.energy = 0.6
		_aura.color = Color(1.0, 0.93, 0.8)
	elif tuner_glow:
		_aura.energy = 0.55
		_aura.color = Color(0.55, 0.85, 0.95)
	else:
		_aura.energy = 0.3
		_aura.color = Color(0.7, 0.75, 0.9)
	var f := player.facing
	_beam.position = Vector2(84.0 * f, -132.0)
	_beam.rotation = 0.12 if f > 0 else PI - 0.12


## A soft light in the room (a lamp, a doorway's spill) that also lights Mara as she passes.
func add_lamp(pos: Vector2, scale: float, col: Color, energy: float = 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = GLOW
	l.texture_scale = scale
	l.color = col
	l.energy = energy
	l.position = pos
	add_child(l)
	return l


# --- building helpers ---------------------------------------------------------

func add_actor(kind: String, x: float, facing: int = 1) -> Actor:
	var a := Actor.new()
	a.kind = kind
	a.position = Vector2(x, floor_y)
	a.face(facing)
	add_child(a)
	return a


func make_player(x: float, facing: int = 1, kind: String = "mara") -> Actor:
	player = add_actor(kind, x, facing)
	player.z_index = 2
	if kind == "mara" and GameState.has("swapped"):
		player.wrist_tape = Color("2f63c9")
	elif kind == "mara" and GameState.has("wrist_tape"):
		player.wrist_tape = Color("b8322c")
	return player


## A drawing at its own depth: z 1 sits in front of other people (z 0) but
## behind Mara (z 2). Counters and desks that someone stands behind use it.
func add_layer(z: int, fn: Callable) -> Node2D:
	var n := PropLayer.new()
	n.fn = fn
	n.z_index = z
	add_child(n)
	return n


## walk_x: where Mara walks before acting (NAN = she stays put).
## face: -1 / 1 to force a direction, 0 to face the hotspot.
## cond: optional Callable returning bool; the hotspot only exists while true.
func add_hotspot(id: String, rect: Rect2, label: String, walk_x: float = NAN, face: int = 0, cond: Variant = null) -> void:
	hotspots.append({"id": id, "rect": rect, "label": label, "walk_x": walk_x, "face": face, "cond": cond})


func hotspot_enabled(h: Dictionary) -> bool:
	var c: Variant = h.get("cond")
	return c == null or bool((c as Callable).call())


func get_hotspot(id: String) -> Dictionary:
	for h in hotspots:
		if h.id == id:
			return h
	return {}


## The smallest enabled hotspot under the point, so small details win over big ones.
## Small hotspots (a watch, a fuse holder) also catch taps that land just outside them.
func hotspot_at(p: Vector2) -> Dictionary:
	var best := {}
	var best_area := INF
	for h in hotspots:
		var r: Rect2 = h.rect
		if r.has_point(p) and hotspot_enabled(h) and r.get_area() < best_area:
			best = h
			best_area = r.get_area()
	if not best.is_empty():
		return best
	var best_d := TAP_SLACK
	for h in hotspots:
		var r: Rect2 = h.rect
		if r.get_area() > SMALL_HOTSPOT or not hotspot_enabled(h):
			continue
		var d := p.distance_to(Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y)))
		if d <= best_d:
			best = h
			best_d = d
	return best


# --- input and interaction -------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if main == null or main.is_busy() or get_tree().paused:
		return
	get_viewport().set_input_as_handled()
	var p := get_global_mouse_position()
	var h := hotspot_at(p)
	if not h.is_empty():
		main.run(interact.bind(h.id))
	elif player != null:
		player.walk_to(clampf(p.x, walk_min, walk_max))
		if GameState.selected_item != "":
			GameState.selected_item = ""
			hud.refresh_inventory()


## Walk to a hotspot and act on it. Also called by the automated test.
func interact(id: String) -> void:
	var h := get_hotspot(id)
	if h.is_empty():
		push_error("No hotspot '%s' in room '%s'" % [id, name])
		return
	if not hotspot_enabled(h):
		push_error("Hotspot '%s' is not available right now in '%s'" % [id, name])
		return
	var item := GameState.selected_item
	var wx: float = h.walk_x
	if player != null and not is_nan(wx):
		await player.walk_to(clampf(wx, walk_min, walk_max))
		var f: int = h.face
		if f == 0:
			var r: Rect2 = h.rect
			f = 1 if r.get_center().x >= player.position.x else -1
		player.face(f)
	if item != "":
		GameState.selected_item = ""
		hud.refresh_inventory()
		var handled: bool = await use_item(id, item)
		if not handled:
			await mara(["That won't do anything.", "No. That's not going to help.", "I don't think so."].pick_random())
	else:
		await on_hotspot(id)


func flash() -> void:
	_flash = 1.8
	Audio.sfx("click", -16.0)


# --- scripting shortcuts -----------------------------------------------------------

func say(speaker: String, text: String) -> void:
	await hud.say(speaker, text)


func mara(text: String) -> void:
	await hud.say("MARA", text)


func narrate(text: String) -> void:
	await hud.say("", text)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func objective() -> void:
	GameState.set_objective(Story.objective(freq))


# --- hint highlight -----------------------------------------------------------------

func _draw_flash(ci: CanvasItem) -> void:
	if _flash <= 0.0:
		return
	var a := clampf(_flash, 0.0, 1.0) * (0.65 + 0.35 * sin(t * 10.0))
	for h in hotspots:
		if not hotspot_enabled(h):
			continue
		var r: Rect2 = h.rect
		ci.draw_rect(r, Color(0.91, 0.65, 0.29, 0.12 * a))
		ci.draw_rect(r, Color(1.0, 0.75, 0.35, 0.95 * a), false, 3.0)
		# Label on its own dark tag inside the hotspot, so it never collides with signs.
		var w := ThemeDB.fallback_font.get_string_size(h.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		var tag := Rect2(r.position + Vector2(5, 5), Vector2(w + 14, 26))
		ci.draw_rect(tag, Color(0.04, 0.05, 0.07, 0.85 * a))
		Kit.text(ci, tag.position + Vector2(7, 19), h.label, 17, Color(1.0, 0.85, 0.6, a))


class PropLayer extends Node2D:
	var fn: Callable

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		fn.call(self)


class ForeLayer extends Node2D:
	var room: Room

	func _draw() -> void:
		room.draw_fore(self)


## Light sources: drawn on their own canvas layer, so darkness never dims them.
class GlowLayer extends Node2D:
	var room: Room

	func _draw() -> void:
		room.draw_glow(self)


## The ? button's highlights: also on their own layer, so they show in the dark.
class HintLayer extends Node2D:
	var room: Room

	func _draw() -> void:
		room._draw_flash(self)
