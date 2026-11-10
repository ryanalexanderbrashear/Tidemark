class_name Bolt
extends Node2D
## A stun bolt, in native pixels. The detective's hit hostiles; hostiles' hit
## the detective.

const LIFETIME: float = 1.2
const P = preload("res://game/art/art_palette.gd")

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
			if h != null and h.hit_box().has_point(position):
				h.hit()
				queue_free()
				return
	else:
		for node: Node in get_tree().get_nodes_in_group("detective"):
			var d: Detective = node as Detective
			if d != null and d.hit_box().has_point(position):
				d.hurt("bolt")
				queue_free()
				return
	if _life <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if friendly:
		draw_rect(Rect2(-5, -1, 10, 2), P.CYAN)
		draw_rect(Rect2(-2, -1, 4, 2), Color.WHITE)
	else:
		draw_rect(Rect2(-2, -2, 4, 4), P.MAGENTA)
		draw_rect(Rect2(-1, -1, 2, 2), Color("ffc2dc"))
