class_name Bolt
extends Node2D
## A stun bolt. The detective's hit hostiles; hostiles' hit the detective.

const LIFETIME: float = 1.2

var velocity: Vector2
var friendly: bool
var _life: float = LIFETIME


static func make(at: Vector2, vel: Vector2, from_detective: bool) -> Bolt:
	var b: Bolt = Bolt.new()
	b.position = at
	b.velocity = vel
	b.friendly = from_detective
	return b


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_life -= delta
	if friendly:
		for node: Node in get_tree().get_nodes_in_group("hostiles"):
			var h: Hostile = node as Hostile
			if h != null and h.hit_box().has_point(global_position):
				h.hit()
				queue_free()
				return
	else:
		for node: Node in get_tree().get_nodes_in_group("detective"):
			var d: Detective = node as Detective
			if d != null and Rect2(d.global_position + Vector2(-12, -46), Vector2(24, 46)).has_point(global_position):
				d.hurt()
				queue_free()
				return
	if _life <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if friendly:
		draw_rect(Rect2(-8, -2, 16, 4), Color("3ee6d0"))
	else:
		draw_circle(Vector2.ZERO, 5.0, Color("ff4fa0"))
