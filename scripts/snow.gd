class_name Snowfall
extends Node2D
## What's falling past, inside `area`: snow, or (on other stations, see Env)
## rain, autumn leaves, spring petals, summer fireflies, or nothing at all.
## Set `frozen` to hold everything in mid-air for that many seconds (the 2:14
## moment).
##
## Every particle is a textured rect, a line or a four-point quad, so a whole
## snowfall goes to the GPU as one batch instead of a shape per flake.

var area := Rect2(0, 0, 1280, 720)
var count := 120
var wind := 30.0
var speed := 55.0
var color := Color(1, 1, 1, 0.85)
var frozen := 0.0
## snow, rain, leaves, petals, fireflies or none.
var kind := "snow":
	set(v):
		kind = v
		visible = v != "none"

var _pos := PackedVector2Array()
var _vel := PackedFloat32Array()
var _size := PackedFloat32Array()
var _drift := PackedFloat32Array()
var _t := 0.0

const LEAVES := [Color("d8742a"), Color("c8462a"), Color("e8b440"), Color("9a5a2a"), Color("b8742e")]
const PETALS := [Color("f6d2dc"), Color("fbeef2"), Color("f0b8c8")]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1983 + count
	for i in count:
		_pos.append(Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y)))
		_vel.append(rng.randf_range(0.6, 1.4))
		_size.append(rng.randf_range(1.3, 3.4))
		_drift.append(rng.randf_range(0.0, TAU))


## Follows the weather of a station (Env.fall).
func follow(e: Env) -> void:
	kind = e.fall


func _process(delta: float) -> void:
	_t += delta
	if kind == "none":
		return
	if frozen > 0.0:
		frozen -= delta
		return
	var fall_speed := speed
	var sway := 18.0
	var drift := wind
	match kind:
		"rain":
			fall_speed = speed * 9.0
			sway = 0.0
			drift = wind * 2.0
		"leaves":
			fall_speed = speed * 0.7
			sway = 46.0
		"petals":
			fall_speed = speed * 0.45
			sway = 34.0
		"fireflies":
			fall_speed = 0.0
			sway = 0.0
			drift = 0.0
	for i in count:
		var p := _pos[i]
		if kind == "fireflies":
			p += Vector2(sin(_t * 0.7 + _drift[i] * 3.0), cos(_t * 0.53 + _drift[i] * 2.0)) * 14.0 * delta
		else:
			p.y += fall_speed * _vel[i] * delta
			p.x += (drift + sin(_t * 1.3 + _drift[i]) * sway) * delta * _vel[i]
		if p.y > area.end.y:
			p.y = area.position.y
		elif p.y < area.position.y:
			p.y = area.end.y
		if p.x > area.end.x:
			p.x = area.position.x
		elif p.x < area.position.x:
			p.x = area.end.x
		_pos[i] = p
	queue_redraw()


func _draw() -> void:
	match kind:
		"snow":
			var tex := Kit.soft_tex()
			for i in count:
				# A soft dot looks about a third of its size: draw it bigger, a
				# little stronger, to match a solid flake.
				var c := color
				c.a = minf(1.0, c.a * (0.32 + _vel[i] * 0.4) * 1.3)
				var r := _size[i] * (0.65 if i % 3 else 1.0) * 2.3
				draw_texture_rect(tex, Rect2(_pos[i] - Vector2(r, r), Vector2(r, r) * 2.0), false, c)
		"rain":
			var dir := Vector2(wind * 2.0, speed * 9.0).normalized()
			for i in count:
				var c2 := Color(0.75, 0.82, 0.92, 0.18 + 0.22 * _vel[i])
				draw_line(_pos[i], _pos[i] + dir * (12.0 + 10.0 * _vel[i]), c2, 1.4)
		"leaves", "petals":
			var pal: Array = LEAVES if kind == "leaves" else PETALS
			var s0 := 1.0 if kind == "leaves" else 0.7
			for i in count:
				var a := _t * (1.6 + _vel[i]) + _drift[i] * 5.0
				var u := Vector2(cos(a), sin(a)) * 4.2 * s0 * (0.8 + 0.3 * _vel[i])
				# Tumbling: the leaf turns edge-on and back.
				var v := Vector2(-u.y, u.x) * (0.25 + 0.45 * absf(sin(a * 0.7)))
				var p := _pos[i]
				var c3: Color = pal[i % pal.size()]
				draw_primitive(PackedVector2Array([p - u, p + v, p + u, p - v]), PackedColorArray([c3, c3, c3.darkened(0.25), c3]), PackedVector2Array())
		"fireflies":
			var tex2 := Kit.soft_tex()
			for i in count:
				var blink := maxf(0.0, sin(_t * (0.9 + _vel[i]) + _drift[i] * 4.0))
				if blink < 0.05:
					continue
				var c4 := Color(0.85, 1.0, 0.45, blink * blink * 0.9)
				var r2 := 3.0 + 2.0 * blink
				draw_texture_rect(tex2, Rect2(_pos[i] - Vector2(r2, r2), Vector2(r2, r2) * 2.0), false, c4)
