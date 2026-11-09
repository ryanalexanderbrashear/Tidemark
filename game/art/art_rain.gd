class_name ArtRain
extends Node2D
## Rain over the style test, drawn in screen space at native resolution: two
## depths of streaks, and splashes where drops hit the walkway and the water.

const P = preload("res://game/art/art_palette.gd")

var view_size: Vector2i = Vector2i(640, 360)
## Screen rows where drops land: the walkway, then the water.
var walk_y: int = 286
var water_y: int = 300

var _drops: Array[Vector4] = []      # x, y, speed, depth (0 far .. 1 near)
var _splashes: Array[Vector3] = []   # x, y, age
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	reset()


func reset() -> void:
	_drops.clear()
	_splashes.clear()
	var count: int = int(view_size.x * view_size.y / 900.0)
	for i: int in range(count):
		_drops.append(_new_drop(_rng.randf_range(0.0, float(view_size.y))))


## Runs the rain forward without drawing, so a screenshot shows it settled.
func warm(seconds: float) -> void:
	var step: float = 1.0 / 30.0
	var t: float = 0.0
	while t < seconds:
		_step(step)
		t += step
	queue_redraw()


func _new_drop(y: float) -> Vector4:
	var depth: float = _rng.randf()
	return Vector4(_rng.randf_range(-20.0, float(view_size.x) + 20.0), y, lerpf(220.0, 420.0, depth), depth)


func _process(delta: float) -> void:
	_step(delta)
	queue_redraw()


func _step(delta: float) -> void:
	for i: int in range(_drops.size()):
		var d: Vector4 = _drops[i]
		d.y += d.z * delta
		d.x -= d.z * delta * 0.12
		var floor_y: float = float(walk_y) if d.w > 0.55 else float(view_size.y)
		if d.w > 0.55 and d.y > floor_y and _rng.randf() < 0.5:
			floor_y = float(water_y) + _rng.randf_range(0.0, float(view_size.y - water_y))
		if d.y >= floor_y:
			if d.w > 0.55:
				_splashes.append(Vector3(roundf(d.x), floor_y, 0.0))
			d = _new_drop(_rng.randf_range(-30.0, 0.0))
		_drops[i] = d
	var kept: Array[Vector3] = []
	for s: Vector3 in _splashes:
		s.z += delta
		if s.z < 0.2:
			kept.append(s)
	_splashes = kept


func _draw() -> void:
	for d: Vector4 in _drops:
		var length: int = int(lerpf(3.0, 9.0, d.w))
		var c: Color = Color(P.RAIN, lerpf(0.12, 0.42, d.w))
		var x: float = floorf(d.x)
		var y: float = floorf(d.y)
		# One pixel wide, stepping left one pixel every few rows for the wind.
		for k: int in range(length):
			draw_rect(Rect2(x + floorf(float(k) / 4.0), y - float(k), 1, 1), c)
	for s: Vector3 in _splashes:
		var r: float = 1.0 + floorf(s.z * 15.0)
		var c: Color = Color(P.RAIN, 0.45 * (1.0 - s.z / 0.2))
		draw_rect(Rect2(s.x - r, s.y - 1.0, 1, 1), c)
		draw_rect(Rect2(s.x + r, s.y - 1.0, 1, 1), c)
		if s.z < 0.07:
			draw_rect(Rect2(s.x, s.y - 2.0, 1, 1), c)
