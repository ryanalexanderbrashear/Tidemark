class_name Detective
extends CharacterBody2D
## The player, on the 8-head cast (ArtCast "detective"): moves at a brisk jog,
## dashes, jumps, fires a stun pistol, takes hits. Origin at the feet, in
## native pixels.
##
## His pace is the one his run cycle is drawn for. The dash is his reinforced
## legs (starting cyberware): a short burst along the ground or once in the
## air that bolts and blows pass through. The jump clears a little over his own
## height, the grey box's jump at the game's scale. His jump, fall, dash and
## aim are placeholder poses (frames of the run, and a pistol held out) until
## they're drawn.

signal downed

## His everyday pace: a brisk jog, about 1.4 run cycles a second with his run
## stride, so a screen (640 px) takes under 7 seconds.
const SPEED: float = 96.0
## The dash (Shift): fast and short, about two thirds of his height.
const DASH_SPEED: float = 330.0
const DASH_SECONDS: float = 0.16
## Seconds from the start of one dash until the next can start.
const DASH_COOLDOWN: float = 0.5
## Seconds between afterimages left along a dash.
const TRAIL_SECONDS: float = 0.04
## The run frame held through a dash: the far foot striking, legs spread.
const DASH_FRAME: int = 0
const JUMP_SPEED: float = 440.0
const GRAVITY: float = 1200.0
## Letting go of jump while still rising cuts the jump short.
const SHORT_HOP: float = 130.0
const MAX_HP: int = 5
const INVULNERABLE_SECONDS: float = 1.0
const SHOT_COOLDOWN: float = 0.32
const SHOT_SPEED: float = 480.0
## Seconds he holds the pistol out after a shot.
const AIM_SECONDS: float = 0.35
## His body for collisions and hits (native pixels, origin at the feet).
const BODY: Vector2 = Vector2(14, 64)
## The run frames that are airborne, used for his jump and fall.
const RISE_FRAME: int = 3
const FALL_FRAME: int = 7

var hp: int = MAX_HP
var facing: float = 1.0
## Seconds left of the dash under way (0 when not dashing).
var dashing: float = 0.0
var _dash_dir: float = 1.0
var _dash_ready: float = 0.0
## Whether his one air dash is spent; landing gives it back.
var _air_dashed: bool = false
var _trail: float = 0.0
## Set by whoever runs him: input is ignored while true.
var frozen: bool = false
var sprite: CastSprite
var _gun: Polygon2D
var _invulnerable: float = 0.0
var _cooldown: float = 0.0
var _aim: float = 0.0
var _clock: float = 0.0
var _walk_dist: float = 0.0
var _run_stride: float


func _ready() -> void:
	add_to_group("detective")
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = BODY
	shape.shape = rect
	shape.position = Vector2(0, -BODY.y / 2.0)
	add_child(shape)
	floor_snap_length = 3.0
	var anims: Array[String] = ["idle", "walk", "run"]
	sprite = CastSprite.new("detective", anims)
	add_child(sprite)
	var b: ArtFigure.Build = ArtCast.build("detective")
	_run_stride = b.run_stride
	# Placeholder: a stub of a pistol held out at chest height.
	_gun = Polygon2D.new()
	_gun.polygon = PackedVector2Array([Vector2(4, -41), Vector2(13, -41), Vector2(13, -39), Vector2(7, -39), Vector2(7, -37), Vector2(4, -37)])
	_gun.color = Color("2a3038")
	_gun.visible = false
	add_child(_gun)
	_pose()


func _physics_process(delta: float) -> void:
	_clock += delta
	var dir: float = 0.0 if frozen else Input.get_axis("move_left", "move_right")
	if is_on_floor():
		_air_dashed = false
	_dash_ready -= delta
	if not frozen and dashing <= 0.0 and Input.is_action_just_pressed("dash"):
		_start_dash(dir)
	if dashing > 0.0:
		_dash_step(delta)
	else:
		velocity.x = dir * SPEED
		if dir != 0.0:
			facing = signf(dir)
			_walk_dist += absf(velocity.x) * delta
		else:
			_walk_dist = 0.0
		velocity.y += GRAVITY * delta
		if not frozen:
			# Let go of jump early for a short hop.
			if not Input.is_action_pressed("jump") and velocity.y < -SHORT_HOP:
				velocity.y += GRAVITY * delta
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = -JUMP_SPEED
	move_and_slide()

	_invulnerable = maxf(0.0, _invulnerable - delta)
	_cooldown -= delta
	_aim = maxf(0.0, _aim - delta)
	if not frozen and dashing <= 0.0 and Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_cooldown = SHOT_COOLDOWN
		_aim = AIM_SECONDS
		var bolt: Bolt = Bolt.make(position + Vector2(facing * 14.0, -40.0), Vector2(facing * SHOT_SPEED, 0.0), true)
		get_parent().add_child(bolt)
	_pose()


## Starts a dash the way he's pushing, or the way he faces if he isn't. Once
## per cooldown, and once per jump in the air.
func _start_dash(dir: float) -> void:
	if _dash_ready > 0.0 or (_air_dashed and not is_on_floor()):
		return
	if not is_on_floor():
		_air_dashed = true
	_dash_dir = signf(dir) if dir != 0.0 else facing
	facing = _dash_dir
	dashing = DASH_SECONDS
	_dash_ready = DASH_COOLDOWN
	_trail = 0.0
	_aim = 0.0


## One frame of a dash: straight along, no gravity, leaving afterimages.
func _dash_step(delta: float) -> void:
	velocity = Vector2(_dash_dir * DASH_SPEED, 0.0)
	dashing = maxf(0.0, dashing - delta)
	_walk_dist = 0.0
	_trail -= delta
	if _trail <= 0.0 and get_parent() != null:
		_trail = TRAIL_SECONDS
		_leave_afterimage()


## A fading copy of his sprite where he stands: placeholder dash art, the
## reinforced legs' blur.
func _leave_afterimage() -> void:
	var ghost: Sprite2D = Sprite2D.new()
	ghost.centered = false
	ghost.texture = sprite.texture
	ghost.flip_h = sprite.flip_h
	ghost.position = position + sprite.position
	ghost.modulate = Color(0.55, 0.85, 1.0, 0.6)
	get_parent().add_child(ghost)
	get_parent().move_child(ghost, get_index())
	var fade: Tween = ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.2)
	fade.tween_callback(ghost.queue_free)


## Picks his frame: the dash pose, standing, or running by distance, or the
## airborne run frames while he's off the ground.
func _pose() -> void:
	if dashing > 0.0:
		sprite.show_frame("run", DASH_FRAME)
	elif not is_on_floor() and absf(velocity.y) > 1.0:
		sprite.show_frame("run", RISE_FRAME if velocity.y < 0.0 else FALL_FRAME)
	elif velocity.x != 0.0:
		sprite.step_at("run", _walk_dist, _run_stride)
	else:
		sprite.show_frame("idle", int(_clock * 2.0))
	sprite.flip_h = facing < 0.0
	sprite.position = Vector2(-floorf(sprite.frame_size.x * 0.5), -sprite.frame_size.y + 2)
	_gun.visible = _aim > 0.0
	_gun.scale.x = facing
	# Flicker while he can't be hurt again.
	sprite.visible = _invulnerable <= 0.0 or int(_clock * 20.0) % 2 == 1


## His body in the room (native pixels), for hits.
func hit_box() -> Rect2:
	return Rect2(position + Vector2(-BODY.x / 2.0, -BODY.y), BODY)


func hurt() -> void:
	# A dash slips through bolts and blows.
	if _invulnerable > 0.0 or dashing > 0.0:
		return
	hp -= 1
	_invulnerable = INVULNERABLE_SECONDS
	if hp <= 0:
		hp = MAX_HP
		downed.emit()


func heal() -> void:
	hp = MAX_HP
	_invulnerable = 0.0
