class_name Hostile
extends Node2D
## A grey-box enemy. Thugs walk at the detective on the floor; drones float,
## drift toward them and fire slow bolts. Contact hurts.

const THUG_SPEED: float = 110.0
const THUG_RANGE: float = 520.0
const DRONE_SPEED: float = 70.0
const DRONE_FIRE_EVERY: float = 2.2

var kind: String = "thug"
var room: String = ""
var hp: int = 3
var _base_y: float
var _phase: float
var _fire_in: float
var _flash: float = 0.0


static func make(what: String, in_room: String, at: Vector2) -> Hostile:
	var h: Hostile = Hostile.new()
	h.kind = what
	h.room = in_room
	h.position = at
	h.hp = 2 if what == "drone" else 3
	return h


func _ready() -> void:
	add_to_group("hostiles")
	_base_y = position.y
	_phase = randf() * TAU
	_fire_in = 1.0 + randf()


func hit_box() -> Rect2:
	if kind == "drone":
		return Rect2(global_position - Vector2(16, 16), Vector2(32, 32))
	return Rect2(global_position + Vector2(-14, -60), Vector2(28, 60))


func hit() -> void:
	hp -= 1
	_flash = 0.12
	if hp <= 0:
		Case.hostile_down(room)
		queue_free()


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	var d: Detective = get_tree().get_first_node_in_group("detective") as Detective
	if d == null:
		return
	var dx: float = d.global_position.x - global_position.x
	if kind == "thug":
		if absf(dx) < THUG_RANGE:
			position.x += signf(dx) * THUG_SPEED * delta
		if absf(dx) < 24.0 and absf(d.global_position.y - global_position.y) < 40.0:
			d.hurt()
	else:
		_phase += delta * 2.0
		position.x += signf(dx) * DRONE_SPEED * delta
		position.y = _base_y + sin(_phase) * 40.0
		_fire_in -= delta
		if _fire_in <= 0.0:
			_fire_in = DRONE_FIRE_EVERY
			var aim: Vector2 = (d.global_position + Vector2(0, -26) - global_position).normalized()
			get_parent().add_child(Bolt.make(global_position, aim * 230.0, false))
		if absf(dx) < 22.0 and absf(d.global_position.y - 26.0 - global_position.y) < 30.0:
			d.hurt()
	queue_redraw()


func _draw() -> void:
	var c: Color = Color.WHITE if _flash > 0.0 else (Color("ff4fa0") if kind == "drone" else Color("ff5a6e"))
	if kind == "drone":
		draw_circle(Vector2.ZERO, 13.0, c)
		draw_rect(Rect2(-4, -2, 8, 4), Color("220000"))
		draw_line(Vector2(-20, -12), Vector2(20, -12), Color(1, 0.3, 0.6, 0.5), 2.0)
	else:
		RoomView.draw_person(self, Vector2.ZERO, c, true)
