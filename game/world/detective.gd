class_name Detective
extends CharacterBody2D
## The player: runs, sprints, jumps, fires a stun pistol, takes hits. Origin at
## the feet.

signal downed

const SPEED: float = 260.0
## Holding sprint (Shift): his reinforced legs, starting cyberware. It works in
## the air too, so a sprinting jump carries further.
const SPRINT_SPEED: float = 420.0
const JUMP_SPEED: float = 660.0
const GRAVITY: float = 1800.0
const MAX_HP: int = 5
const INVULNERABLE_SECONDS: float = 1.0
const SHOT_COOLDOWN: float = 0.32

var hp: int = MAX_HP
var facing: float = 1.0
var optic_on: bool = false
var _invulnerable: float = 0.0
var _cooldown: float = 0.0
var _clock: float = 0.0


func _ready() -> void:
	add_to_group("detective")
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(24, 44)
	shape.shape = rect
	shape.position = Vector2(0, -22)
	add_child(shape)
	floor_snap_length = 4.0


func _physics_process(delta: float) -> void:
	_clock += delta
	var dir: float = Input.get_axis("move_left", "move_right")
	velocity.x = dir * (SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED)
	if dir != 0.0:
		facing = signf(dir)
	velocity.y += GRAVITY * delta
	# Let go of jump early for a short hop.
	if not Input.is_action_pressed("jump") and velocity.y < -200.0:
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -JUMP_SPEED
	move_and_slide()

	_invulnerable = maxf(0.0, _invulnerable - delta)
	_cooldown -= delta
	if Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_cooldown = SHOT_COOLDOWN
		var bolt: Bolt = Bolt.make(global_position + Vector2(facing * 16.0, -28.0), Vector2(facing * 720.0, 0.0), true)
		get_parent().add_child(bolt)
	queue_redraw()


func hurt() -> void:
	if _invulnerable > 0.0:
		return
	hp -= 1
	_invulnerable = INVULNERABLE_SECONDS
	if hp <= 0:
		hp = MAX_HP
		downed.emit()


func heal() -> void:
	hp = MAX_HP
	_invulnerable = 0.0


func _draw() -> void:
	if _invulnerable > 0.0 and int(_clock * 20.0) % 2 == 0:
		return
	var f: float = facing
	var lean: float = 0.0
	if absf(velocity.x) > 1.0:
		lean = -f * (10.0 if absf(velocity.x) > SPEED else 6.0)
	draw_circle(Vector2(0, -52), 8.0, Color("ffb347") if optic_on else Color("c8d6e5"))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -44), Vector2(12, -44), Vector2(14 + lean, -6), Vector2(-14 + lean, -6)]), Color("3b4a5e"))
	draw_rect(Rect2(-7, -8, 5, 8), Color("1d2633"))
	draw_rect(Rect2(2, -8, 5, 8), Color("1d2633"))
	draw_rect(Rect2(minf(f * 2.0, f * 10.0), -55, 8, 3), Color("3ee6d0"))
	draw_rect(Rect2(minf(f * 10.0, f * 20.0), -32, 10, 4), Color("222222"))
