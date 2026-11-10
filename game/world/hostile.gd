class_name Hostile
extends Node2D
## An enemy, in native pixels. Thugs walk at the detective on the floor;
## drones float, drift toward him and fire slow bolts. Contact hurts.
##
## Placeholder looks: thugs are flat red silhouettes on the cast's body,
## drones a small pixel hull with a magenta eye.

const P = preload("res://game/art/art_palette.gd")
## A little under his walking pace, so he can always walk away from one.
const THUG_SPEED: float = 48.0
const THUG_RANGE: float = 340.0
const DRONE_SPEED: float = 46.0
const DRONE_FIRE_EVERY: float = 2.2
const DRONE_SHOT_SPEED: float = 150.0
const DRONE_BOB: float = 26.0
const THUG_TINT: Color = Color("5a1a24")

var kind: String = "thug"
var room: String = ""
var hp: int = 3
## Its glow in the thermal optic's picture (set by whoever spawns it).
var heat: Sprite2D
var _base_y: float
var _phase: float
var _fire_in: float
var _flash: float = 0.0
var _sprite: CastSprite
var _walked: float = 0.0
var _facing: float = -1.0


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
	if kind == "thug":
		var anims: Array[String] = ["walk", "idle"]
		_sprite = CastSprite.new("fixer", anims, THUG_TINT)
		_sprite.position = Vector2(-floorf(_sprite.frame_size.x * 0.5), -_sprite.frame_size.y + 2)
		add_child(_sprite)


func _exit_tree() -> void:
	if heat != null:
		heat.queue_free()


func hit_box() -> Rect2:
	if kind == "drone":
		return Rect2(position - Vector2(9, 7), Vector2(18, 14))
	return Rect2(position + Vector2(-8, -64), Vector2(16, 64))


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
	var dx: float = d.position.x - position.x
	if kind == "thug":
		var moving: bool = absf(dx) < THUG_RANGE and absf(dx) > 4.0
		if moving:
			position.x += signf(dx) * THUG_SPEED * delta
			_walked += THUG_SPEED * delta
			_facing = signf(dx)
		if absf(dx) < 14.0 and absf(d.position.y - position.y) < 28.0:
			d.hurt("thug")
		if moving:
			_sprite.step_at("walk", _walked, ArtCast.build("fixer").stride)
		else:
			_sprite.play_at("idle", _phase)
		_sprite.flip_h = _facing < 0.0
		_sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE
	else:
		_phase += delta * 2.0
		position.x += signf(dx) * DRONE_SPEED * delta
		position.y = _base_y + sin(_phase) * DRONE_BOB
		_fire_in -= delta
		if _fire_in <= 0.0:
			_fire_in = DRONE_FIRE_EVERY
			var aim: Vector2 = (d.position + Vector2(0, -36) - position).normalized()
			get_parent().add_child(Bolt.make(position, aim * DRONE_SHOT_SPEED, false))
		# Chest high: a slide goes under it.
		if absf(dx) < 12.0 and absf(d.position.y - 36.0 - position.y) < 20.0 and d.hit_box().grow(12.0).has_point(position):
			d.hurt("drone")
		queue_redraw()


func _draw() -> void:
	if kind != "drone":
		return
	var hull: Color = Color.WHITE if _flash > 0.0 else P.STEEL
	draw_rect(Rect2(-8, -4, 16, 8), hull)
	draw_rect(Rect2(-8, -4, 16, 1), P.RAIN)
	draw_rect(Rect2(-11, -7, 22, 1), Color(P.RAIN, 0.6))
	draw_rect(Rect2(-2, -1, 4, 3), P.MAGENTA)
