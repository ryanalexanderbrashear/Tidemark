class_name Detective
extends CharacterBody2D
## The player, on the 8-head cast (ArtCast "detective"): moves at a brisk jog,
## dashes, slides, jumps, fires a stun pistol, takes hits. Origin at the feet,
## in native pixels.
##
## His pace is the one his run cycle is drawn for. The dash and slide are his
## reinforced legs (starting cyberware). The dash is a short burst along the
## ground or once in the air that bolts and blows pass through. The slide
## (down + dash, on the ground) goes further and lower: no protection, but
## his body drops under shots at chest height. The jump clears a little over
## his own height, the grey box's jump at the game's scale. Jumping out of a
## dash or slide on the ground (or just after one) carries its speed into the
## jump, easing back to his pace in the air; turning back drops it at once. His jump, fall and
## aim are placeholder poses (frames of the run, and a pistol held out) until
## they're drawn.

signal downed
## A hit landed on him: what it was ("thug", "drone", "bolt", or "" when
## unnamed).
signal hurt_by(what: String)
## A hit reached him mid-dash and passed through.
signal slipped(what: String)

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
## The slide (down + dash): starts at SLIDE_SPEED and eases to SLIDE_END_SPEED,
## about one and a quarter of his heights in all. Shares the dash's cooldown.
const SLIDE_SPEED: float = 300.0
const SLIDE_END_SPEED: float = 140.0
const SLIDE_SECONDS: float = 0.38
## His body's height while sliding, for hits: under a chest-high shot.
const SLIDE_HEIGHT: float = 34.0
## Jumping out of a dash or slide keeps up to CARRY_MAX of its speed, which
## eases back to his pace by CARRY_DRAG px/s each second in the air.
const CARRY_MAX: float = 220.0
const CARRY_DRAG: float = 160.0
## Seconds after a dash or slide on the ground ends that a jump still carries.
const CARRY_GRACE: float = 0.1
## Seconds into a dash or slide when its second frame takes over.
const DASH_FRAME_SECONDS: float = 0.06
const SLIDE_FRAME_SECONDS: float = 0.1
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
## Seconds left of the slide under way (0 when not sliding).
var sliding: float = 0.0
## Speed carried from a dash or slide into the jump under way (0 when none).
var carry: float = 0.0
var _grace: float = 0.0
var _grace_speed: float = 0.0
var _dash_grounded: bool = false
## One-shot presses queued by code (tests, the art test), read like a
## just-pressed action on his next physics step.
var _queued: Array[String] = []
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
	var anims: Array[String] = ["idle", "walk", "run", "dash", "slide"]
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
		if velocity.y >= 0.0:
			carry = 0.0
	_dash_ready -= delta
	_grace = maxf(0.0, _grace - delta)
	if not frozen and dashing <= 0.0 and sliding <= 0.0 and _just("dash"):
		if is_on_floor() and Input.is_action_pressed("move_down"):
			_start_slide(dir)
		else:
			_start_dash(dir)
	if dashing > 0.0:
		_dash_step(delta)
	elif sliding > 0.0:
		_slide_step(delta)
	else:
		if carry > 0.0 and dir * _dash_dir >= 0.0:
			velocity.x = _dash_dir * carry
			carry = move_toward(carry, SPEED, CARRY_DRAG * delta)
			if carry <= SPEED:
				carry = 0.0
		else:
			carry = 0.0
			velocity.x = dir * SPEED
		if dir != 0.0 and carry <= 0.0:
			facing = signf(dir)
			_walk_dist += absf(velocity.x) * delta
		else:
			_walk_dist = 0.0
		velocity.y += GRAVITY * delta
		if not frozen:
			# Let go of jump early for a short hop.
			if not Input.is_action_pressed("jump") and velocity.y < -SHORT_HOP:
				velocity.y += GRAVITY * delta
			if _just("jump") and is_on_floor():
				if _grace > 0.0:
					_launch(_grace_speed)
				else:
					velocity.y = -JUMP_SPEED
	move_and_slide()

	_invulnerable = maxf(0.0, _invulnerable - delta)
	_cooldown -= delta
	_aim = maxf(0.0, _aim - delta)
	if not frozen and dashing <= 0.0 and sliding <= 0.0 and Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_cooldown = SHOT_COOLDOWN
		_aim = AIM_SECONDS
		var bolt: Bolt = Bolt.make(position + Vector2(facing * 14.0, -40.0), Vector2(facing * SHOT_SPEED, 0.0), true)
		get_parent().add_child(bolt)
	_queued.clear()
	_pose()


## Presses `action` once, for his next physics step.
func press(action: String) -> void:
	_queued.append(action)


func _just(action: String) -> bool:
	return Input.is_action_just_pressed(action) or _queued.has(action)


## Starts a dash the way he's pushing, or the way he faces if he isn't. Once
## per cooldown, and once per jump in the air.
func _start_dash(dir: float) -> void:
	if _dash_ready > 0.0 or (_air_dashed and not is_on_floor()):
		return
	_dash_grounded = is_on_floor()
	if not _dash_grounded:
		_air_dashed = true
	_dash_dir = signf(dir) if dir != 0.0 else facing
	facing = _dash_dir
	dashing = DASH_SECONDS
	_dash_ready = DASH_COOLDOWN
	_trail = 0.0
	_aim = 0.0


## One frame of a dash: straight along, no gravity, leaving afterimages. On
## the ground, jump breaks out of it into a jump that carries its speed.
func _dash_step(delta: float) -> void:
	velocity = Vector2(_dash_dir * DASH_SPEED, 0.0)
	if _dash_grounded and not frozen and _just("jump"):
		dashing = 0.0
		_launch(DASH_SPEED)
		return
	dashing = maxf(0.0, dashing - delta)
	if dashing <= 0.0 and _dash_grounded:
		_grace = CARRY_GRACE
		_grace_speed = DASH_SPEED
	_walk_dist = 0.0
	_trail -= delta
	if _trail <= 0.0 and get_parent() != null:
		_trail = TRAIL_SECONDS
		_leave_afterimage()


## Starts a slide the way he's pushing, or the way he faces.
func _start_slide(dir: float) -> void:
	if _dash_ready > 0.0:
		return
	_dash_dir = signf(dir) if dir != 0.0 else facing
	facing = _dash_dir
	sliding = SLIDE_SECONDS
	_dash_ready = DASH_COOLDOWN
	_aim = 0.0


## One frame of a slide: along the floor, slowing. Jump breaks out of it into
## a jump; running off a ledge ends it and he falls.
func _slide_step(delta: float) -> void:
	var t: float = 1.0 - sliding / SLIDE_SECONDS
	velocity.x = _dash_dir * lerpf(SLIDE_SPEED, SLIDE_END_SPEED, t)
	velocity.y += GRAVITY * delta
	sliding = maxf(0.0, sliding - delta)
	_walk_dist = 0.0
	if not is_on_floor() and velocity.y > 1.0:
		sliding = 0.0
	elif not frozen and _just("jump"):
		sliding = 0.0
		_launch(absf(velocity.x))
	elif sliding <= 0.0:
		_grace = CARRY_GRACE
		_grace_speed = SLIDE_END_SPEED


## Jumps, carrying `speed` along the way he was dashing or sliding.
func _launch(speed: float) -> void:
	velocity.y = -JUMP_SPEED
	carry = minf(speed, CARRY_MAX)
	velocity.x = _dash_dir * carry
	_grace = 0.0


## A fading copy of his sprite where he stands: the reinforced legs' blur.
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
		sprite.show_frame("dash", 0 if DASH_SECONDS - dashing < DASH_FRAME_SECONDS else 1)
	elif sliding > 0.0:
		sprite.show_frame("slide", 0 if SLIDE_SECONDS - sliding < SLIDE_FRAME_SECONDS else 1)
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


## His body in the room (native pixels), for hits: low while he slides.
func hit_box() -> Rect2:
	var size: Vector2 = Vector2(BODY.x, SLIDE_HEIGHT) if sliding > 0.0 else BODY
	return Rect2(position + Vector2(-size.x / 2.0, -size.y), size)


## Takes a hit from `what` (see hurt_by), unless he's dashing or still
## recovering from the last one.
func hurt(what: String = "") -> void:
	if _invulnerable > 0.0:
		return
	# A dash slips through bolts and blows.
	if dashing > 0.0:
		slipped.emit(what)
		return
	hp -= 1
	_invulnerable = INVULNERABLE_SECONDS
	hurt_by.emit(what)
	if hp <= 0:
		hp = MAX_HP
		downed.emit()


## Seconds until he can dash again (0 when ready).
func dash_wait() -> float:
	return maxf(0.0, _dash_ready)


func heal() -> void:
	hp = MAX_HP
	_invulnerable = 0.0
