class_name Detective
extends CharacterBody2D
## The player, on the 8-head cast (ArtCast "detective"): walks, sprints, jumps,
## fires a stun pistol, takes hits. Origin at the feet, in native pixels.
##
## Walking and sprinting keep the art test's pace, which the walk and run
## cycles are drawn for. The jump clears a little over his own height, the
## grey box's jump at the game's scale. His jump, fall and aim are placeholder
## poses (frames of the run, and a pistol held out) until they're drawn.

signal downed

## Walking pace: about 1.5 walk cycles a second with his stride.
const SPEED: float = 54.0
## Holding sprint (Shift): his reinforced legs, starting cyberware. About 1.5
## run cycles a second with his run stride. It works in the air too, so a
## sprinting jump carries further.
const SPRINT_SPEED: float = 144.0
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
var sprinting: bool = false
## Set by whoever runs him: input is ignored while true.
var frozen: bool = false
var sprite: CastSprite
var _gun: Polygon2D
var _invulnerable: float = 0.0
var _cooldown: float = 0.0
var _aim: float = 0.0
var _clock: float = 0.0
var _walk_dist: float = 0.0
var _stride: float
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
	_stride = b.stride
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
	var was_sprinting: bool = sprinting
	sprinting = dir != 0.0 and Input.is_action_pressed("sprint")
	if sprinting != was_sprinting:
		# Start the new cycle from its first frame.
		_walk_dist = 0.0
	velocity.x = dir * (SPRINT_SPEED if sprinting else SPEED)
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
	if not frozen and Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_cooldown = SHOT_COOLDOWN
		_aim = AIM_SECONDS
		var bolt: Bolt = Bolt.make(position + Vector2(facing * 14.0, -40.0), Vector2(facing * SHOT_SPEED, 0.0), true)
		get_parent().add_child(bolt)
	_pose()


## Picks his frame: standing, walking or running by distance, or the
## airborne run frames while he's off the ground.
func _pose() -> void:
	if not is_on_floor() and absf(velocity.y) > 1.0:
		sprite.show_frame("run", RISE_FRAME if velocity.y < 0.0 else FALL_FRAME)
	elif velocity.x != 0.0:
		sprite.step_at("run" if sprinting else "walk", _walk_dist, _run_stride if sprinting else _stride)
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
