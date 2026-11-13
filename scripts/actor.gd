class_name Actor
extends Node2D
## A character in a room: Mara, Tomas, Eighty-One, June, Ruth, the
## townspeople, the body, Sollen and Cal asleep, or a silhouette. The origin
## is between the feet, on the floor.
##
## Actor poses a small skeleton every frame (a walk cycle with bending knees
## and swinging arms, idle breathing, sitting, the slumped and sleeping
## poses) and Figure draws the person over it, using their Looks entry.

var kind := "mara":
	set(value):
		kind = value
		_fig = null
		if _vp != null:
			_fit()
var facing := 1
var walking := false
var speed := 280.0
var headphones := false
## Red tape around Mara's wrist once she starts crossing (transparent = none).
var wrist_tape := Color(0, 0, 0, 0)
## Mara holds the flashlight out in front of her.
var holding_light := false
## Sitting on a chair (the chair itself is the room's to draw).
var seated := false
## Hip height above the floor when seated: match it to the room's chair.
var seat_y := 54.0
## Tomas: a strip of tape around his headphone cord (transparent = none).
var cord_tape := Color(0, 0, 0, 0)
## Optional fixed arms, [[upper, elbow], near, far], e.g. resting on a table.
var arm_pose: Array = []
## What they hold, instead of their usual prop ("none" for empty hands).
var prop := ""
var prop_col := Color(0, 0, 0, 0)
## Headphones: "" as usual, or "off" / "neck" / "head".
var headphones_mode := ""
## A blanket round the shoulders (transparent = none).
var blanket := Color(0, 0, 0, 0)
## Tomas's parka done up to the top button.
var buttoned := false
## Head bowed (+) or raised (-), added to the pose.
var head_tilt := 0.0
## Crying: the shoulders shake a little.
var sob := false
## Another Mara's radio, slung on a strap: the colour of the tape on its
## handle (transparent = none). Eighty-One carries Red's in Act 3.
var carried_radio := Color(0, 0, 0, 0)
var step_sound := "step"
var _phase := 0.0
var _t := 0.0
## Standing or sitting still, a person only needs redrawing a few times a
## second (breathing, blinking); walking, every frame. Mara gets 12 a second,
## everyone else 6 (Room.make_player sets hers).
var idle_step := 1.0 / 6.0
var _idle_acc := 0.0
var _was_walking := false
var _tween: Tween
var _fig: Figure
## Each person is drawn into a small texture of their own and shown as a single
## quad, redrawn only when they change (a dozen times a second standing still,
## every frame while walking). A figure is a couple of hundred shapes; without
## this a phone pays for every one of them, every frame.
var cv: CanvasItem
var _vp: SubViewport
var _sprite: Sprite2D
var _painter: Node2D
var _fit_scale := 0.0
static var _premult: CanvasItemMaterial


func _init() -> void:
	cv = self
	# Spread the idle redraws of everyone in a room over different frames.
	_idle_acc = randf() * idle_step


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.disable_3d = true
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_vp)
	_painter = Painter.new()
	_painter.actor = self
	_vp.add_child(_painter)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture = _vp.get_texture()
	# Drawn onto a clear background, the texture holds premultiplied colour.
	if _premult == null:
		_premult = CanvasItemMaterial.new()
		_premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	_sprite.material = _premult
	# Exactly one texel per screen pixel: nearest keeps outlines sharp wherever she stands.
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _vp != null and is_visible_in_tree():
		redraw()


## Redraws the figure (into its texture).
func redraw() -> void:
	if _vp == null:
		return
	_painter.queue_redraw()
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


## The texture covers the figure in any pose, at the screen's resolution times
## the actor's own scale.
func _fit() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var sc := maxf(0.05, vp.get_final_transform().get_scale().y * absf(get_global_transform().get_scale().y))
	_fit_scale = sc
	var H := figure().H
	var box := Rect2(-0.75 * H - 30.0, -1.45 * H, 1.5 * H + 60.0, 1.65 * H + 20.0)
	var px := Vector2i(ceili(box.size.x * sc), ceili(box.size.y * sc)).clamp(Vector2i(8, 8), Vector2i(4096, 4096))
	_vp.size = px
	_vp.oversampling_override = sc
	_vp.msaa_2d = vp.msaa_2d
	_vp.canvas_transform = Transform2D(0.0, Vector2(sc, sc), 0.0, -box.position * sc)
	_sprite.position = box.position
	_sprite.scale = Vector2.ONE / sc
	redraw()


func face(dir: int) -> void:
	if dir != 0:
		var f := 1 if dir > 0 else -1
		if f != facing:
			facing = f
			redraw()


## Walks horizontally to x. Awaitable; a newer walk_to cancels an older one.
func walk_to(x: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var dist := absf(x - position.x)
	if dist < 3.0:
		walking = false
		return
	face(1 if x > position.x else -1)
	walking = true
	_tween = create_tween()
	_tween.tween_property(self, "position:x", x, dist / speed)
	await _tween.finished
	walking = false


func _process(delta: float) -> void:
	_t += delta
	if walking:
		var before := _phase
		_phase += delta * 11.0
		# A footstep each time a foot plants: twice a stride.
		if int(before / PI) != int(_phase / PI):
			Audio.sfx(step_sound, -15.0, randf_range(0.9, 1.1))
	else:
		_phase = 0.0
	if walking or _was_walking:
		redraw()
	elif is_visible_in_tree():
		_idle_acc += delta
		if _idle_acc >= idle_step and _idle_slot():
			_idle_acc = fmod(_idle_acc, idle_step)
			redraw()
	_was_walking = walking
	var vp := get_viewport()
	if vp != null and (absf(vp.get_final_transform().get_scale().y * absf(get_global_transform().get_scale().y) - _fit_scale) > 0.001
			or vp.msaa_2d != _vp.msaa_2d):
		_fit()


## At most two people standing still are redrawn in any one frame, so a
## crowded street spreads its redraws out instead of stalling on one frame.
static var _slot_frame := -1
static var _slots := 0


static func _idle_slot() -> bool:
	var f := Engine.get_process_frames()
	if f != _slot_frame:
		_slot_frame = f
		_slots = 2
	if _slots <= 0:
		return false
	_slots -= 1
	return true


func figure() -> Figure:
	if _fig == null:
		_fig = Figure.new(Looks.get_look(kind))
		_fig.flat = kind == "silhouette"
	return _fig


func _draw() -> void:
	pass  # the figure lives in its texture (see redraw())


## Draws the person on cv (the painter of their texture).
func paint() -> void:
	var fig := figure()
	match kind:
		"body":
			_draw_body(fig)
		"sollen_asleep":
			_draw_sollen(fig)
		"cal_asleep":
			_draw_cal(fig)
		_:
			# A soft contact shadow seats each character in the room.
			cv.draw_set_transform(Vector2(1, 1), 0.0, Vector2(1.0, 0.22))
			cv.draw_circle(Vector2.ZERO, 26.0 if not seated else 34.0, Color(0.015, 0.02, 0.03, 0.3))
			cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
			fig.draw(cv, _pose(fig))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _base_pose() -> Dictionary:
	return {
		"torso": 0.0, "head": 0.0,
		"breath": 0.5 + 0.5 * sin(_t * 1.7),
		"blink": fmod(_t + position.x * 0.013, 5.3) < 0.13,
		"tape": wrist_tape, "headphones": "head" if headphones else "",
		"prop": "", "cord_tape": cord_tape, "seated": false,
		"blanket": blanket, "buttoned": buttoned, "strap_radio": carried_radio,
	}


func _pose(fig: Figure) -> Dictionary:
	var p := _base_pose()
	var look_prop := str(fig.look.get("prop", ""))
	if prop != "":
		look_prop = "" if prop == "none" else prop
	if prop_col.a > 0.0:
		p.prop_col = prop_col
	if fig.look.get("headphones", false):
		p.headphones = "head"
	if headphones_mode != "":
		p.headphones = "" if headphones_mode == "off" else headphones_mode
	if holding_light:
		p.prop = "flashlight"
	elif look_prop != "":
		p.prop = look_prop
	var legs: Array
	var arms: Array
	if walking:
		var ph := _phase
		legs = [_walk_leg(ph), _walk_leg(ph + PI)]
		arms = [[-0.34 * sin(ph), 0.26 + 0.2 * maxf(0.0, sin(ph))], [-0.34 * sin(ph + PI), 0.26 + 0.2 * maxf(0.0, sin(ph + PI))]]
		p.torso = 0.05 + 0.01 * sin(ph * 2.0)
		p.head = -0.04
	elif seated:
		legs = _seated_legs(fig)
		arms = [[0.34, 0.95], [0.4, 0.9]]
		p.torso = 0.05
		p.seated = true
	else:
		var sway := sin(_t * 0.9) * 0.012
		legs = [[0.05 + sway, 0.05, 0.0], [-0.06 + sway, 0.04, 0.0]]
		arms = [[0.07 + sin(_t * 1.1) * 0.02, 0.2], [-0.05, 0.17]]
		p.torso = sin(_t * 1.7) * 0.006
	if arm_pose.size() == 2 and not walking:
		arms = arm_pose
	p.head = float(p.head) + head_tilt
	if sob:
		p.torso = float(p.torso) + 0.012 * sin(_t * 9.0) * maxf(0.0, sin(_t * 1.3))
	match str(p.prop):
		"radio":
			arms = [[0.4, 1.2], [0.52, 1.08]]
		"radio_up":
			arms = [[2.72, 0.3], [2.86, 0.22]]
		"radio_light":
			arms = [[0.95, 0.3], [0.12, 0.08]] if not walking else [[0.9 + 0.05 * sin(_phase), 0.3], [0.12, 0.08]]
		"key":
			arms[0] = [0.55, 1.45]
		"notebook":
			arms = [[0.45, 1.5], [0.6, 1.25]]
		"thermos":
			arms[0] = [0.7, 0.9]
		"phone":
			arms[0] = [0.55, 2.35]
		"bag":
			arms[0] = [0.08, 0.06]
		"poster":
			arms = [[1.95, 0.25], [2.05, 0.2]]
		"headphones":
			arms[0] = [1.15, 0.55]
		"flashlight":
			arms[0] = [1.25 + sin(_t * 1.6) * 0.03, 0.2]
		"coat":
			arms[0] = [0.18, 1.35]
		"mug":
			arms[0] = [0.85, 0.75] if seated else [0.4, 1.3]
		"lamp":
			arms[0] = [0.5 + sin(_t * 1.3) * 0.02, 0.18]
		"cane":
			arms[0] = [0.3, 0.08]
		"smartphone":
			arms[0] = [0.55, 1.62]
		"revolver":
			arms[0] = [0.32, 0.3]
		"revolver_aim":
			arms[0] = [1.38 + sin(_t * 7.0) * 0.012, 0.04]
		"clipboard":
			arms[0] = [0.5, 1.42]
	p.legs = legs
	p.arms = arms
	p.hip = Vector2(0, -seat_y) if seated else Vector2(0, -fig.leg_drop(legs))
	return p


## One leg through a stride: thigh swinging, the knee bending as it comes
## through, the foot rolling from heel to toe.
static func _walk_leg(ph: float) -> Array:
	var thigh := 0.42 * sin(ph)
	var knee := 0.06 + 0.78 * pow(maxf(0.0, cos(ph)), 1.5)
	var foot := 0.22 * sin(ph + 0.6)
	return [thigh, knee, foot]


## Seated: shins near upright, feet flat on the floor; the thighs tilt up
## or down to make up the chair's height.
func _seated_legs(fig: Figure) -> Array:
	var H := fig.H
	var out := []
	for shin in [0.06, 0.16]:
		var drop := seat_y - cos(shin) * Figure.SHIN * H - Figure.ANKLE_H * H
		var a := acos(clampf(drop / (Figure.THIGH * H), -1.0, 1.0))
		out.append([a, a - shin, 0.0])
	return out


func _flip() -> Transform2D:
	return Transform2D(Vector2(facing, 0), Vector2(0, 1), Vector2.ZERO)


## The woman against the console: sitting on the floor, leaning back, chin on
## her chest, legs out, one arm at her side with blue tape at the wrist.
func _draw_body(fig: Figure) -> void:
	cv.draw_set_transform_matrix(_flip())
	var p := _base_pose()
	p.hip = Vector2(0, -0.075 * fig.H)
	p.torso = -0.42
	p.head = 0.72
	p.blink = true
	p.breath = 0.0
	p.tape = Color("2f63c9")
	p.headphones = "neck"
	p.stain = true
	p.legs = [[1.6, 0.04, 1.4], [1.95, 0.75, 1.25]]
	p.arms = [[-0.3, 1.0], [0.95, 0.55]]
	fig.draw(cv, p)


## Sollen asleep on his couch: lying on his back, head to the left, a
## blanket up to his chest, one arm hanging off the edge.
func _draw_sollen(fig: Figure) -> void:
	var lie := Transform2D(-PI / 2.0, Vector2(78.0, -20.0))
	cv.draw_set_transform_matrix(_flip() * lie)
	var p := _base_pose()
	var breath := sin(_t * 1.1)
	p.hip = Vector2(0, -fig.leg_drop([[0.0, 0.03, 0.0], [0.0, 0.03, 0.0]]))
	p.head = -0.12
	p.blink = true
	p.breath = 0.5 + 0.5 * breath
	p.legs = [[0.0, 0.03, 0.0], [0.03, 0.05, 0.0]]
	p.arms = [[-1.4, 0.15], [0.05, 0.3]]
	fig.draw(cv, p)
	var H := fig.H
	var blanket := PackedVector2Array([Vector2(-0.09 * H, 6), Vector2(0.085 * H, 6), Vector2(0.125 * H, -0.28 * H),
		Vector2(0.12 * H, -0.5 * H), Vector2(0.11 * H + breath, -0.7 * H), Vector2(-0.09 * H, -0.7 * H)])
	fig.fill(Figure.smooth(blanket, 2), Color("4a5a48"), 0.1, 0.14)
	for k in 4:
		var y := -0.12 * H - k * 0.14 * H
		cv.draw_line(Vector2(0.11 * H, y), Vector2(-0.02 * H, y + 8.0), Color("3a4838"), 1.2, true)
	cv.draw_line(Vector2(0.11 * H + breath, -0.7 * H), Vector2(-0.09 * H, -0.7 * H), Color("6a7a66"), 3.0, true)


## Deputy Cal asleep at his desk: slumped forward in his chair, head down on
## his folded arms. The desk top is the room's, in front of him.
func _draw_cal(fig: Figure) -> void:
	cv.draw_set_transform_matrix(_flip())
	var p := _base_pose()
	var breath := sin(_t * 1.0)
	seat_y = 68.0  # the sheriff's desk is a tall one
	p.hip = Vector2(-26.0, -seat_y)
	p.torso = 0.5 + breath * 0.01
	p.head = 1.0
	p.blink = true
	p.seated = true
	p.legs = _seated_legs(fig)
	# Folded on the desk: upper arms forward, forearms back under his head.
	p.arms = [[1.57, 2.95], [1.5, 2.85]]
	fig.draw(cv, p)


## Renders an actor into its texture.
class Painter extends Node2D:
	var actor: Actor

	func _draw() -> void:
		actor.cv = self
		actor.paint()
		actor.cv = actor
