class_name Spring
extends RefCounted
## A value that eases towards a target on a critically damped spring: it
## starts gently, slows into the target and never overshoots, settling in
## about `smooth` seconds and never moving faster than `max_speed` a second.
## (Game Programming Gems 4, 1.10.) The fight camera's look-ahead and zoom.

var value: float = 0.0
var speed: float = 0.0
var smooth: float = 0.45
var max_speed: float = INF


func _init(start: float = 0.0, smooth_seconds: float = 0.45, top_speed: float = INF) -> void:
	value = start
	smooth = smooth_seconds
	max_speed = top_speed


## Puts it at `v`, still.
func settle(v: float) -> void:
	value = v
	speed = 0.0


## Moves it `delta` seconds towards `target`, and returns where it is.
func step(target: float, delta: float) -> float:
	var omega: float = 2.0 / smooth
	var x: float = omega * delta
	var decay: float = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var max_step: float = max_speed * smooth
	var change: float = clampf(value - target, -max_step, max_step)
	var temp: float = (speed + omega * change) * delta
	speed = (speed - omega * temp) * decay
	var next: float = (value - change) + (change + temp) * decay
	if (target - value > 0.0) == (next > target):
		next = target
		speed = 0.0
	value = next
	return value
