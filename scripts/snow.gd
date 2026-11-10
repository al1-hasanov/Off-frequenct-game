class_name Snowfall
extends Node2D
## Falling snow that stays inside `area`. Set `frozen` to hold every flake in
## mid-air for that many seconds (the 2:14 moment).

var area := Rect2(0, 0, 1280, 720)
var count := 120
var wind := 30.0
var speed := 55.0
var color := Color(1, 1, 1, 0.85)
var frozen := 0.0

var _pos := PackedVector2Array()
var _vel := PackedFloat32Array()
var _size := PackedFloat32Array()
var _drift := PackedFloat32Array()
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1983 + count
	for i in count:
		_pos.append(Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y)))
		_vel.append(rng.randf_range(0.6, 1.4))
		_size.append(rng.randf_range(1.3, 3.4))
		_drift.append(rng.randf_range(0.0, TAU))


func _process(delta: float) -> void:
	_t += delta
	if frozen > 0.0:
		frozen -= delta
		return
	for i in count:
		var p := _pos[i]
		p.y += speed * _vel[i] * delta
		p.x += (wind + sin(_t * 1.3 + _drift[i]) * 18.0) * delta * _vel[i]
		if p.y > area.end.y:
			p.y = area.position.y
		if p.x > area.end.x:
			p.x = area.position.x
		elif p.x < area.position.x:
			p.x = area.end.x
		_pos[i] = p
	queue_redraw()


func _draw() -> void:
	for i in count:
		draw_circle(_pos[i], _size[i], color)
