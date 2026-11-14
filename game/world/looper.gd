class_name Looper
extends Hostile
## A looper: someone who replayed cheap recall until other people's memories
## crowded out their own (Gameplay and Production, Combat). What they replay
## decides how they fight:
##
## - "brawler" (a fight memory): closes in, winds up, then charges and swings.
## - "alarm" (a chase or fear memory): runs from him and screams, waking the
##   loopers around it. It never hits.
## - "grabber" (an intimate or grief memory): shuffles in and holds on. The
##   hold costs no health; it pins him for a moment (struggling frees him
##   sooner) and pushes its loop into him as a flash of someone else's memory.
##
## Loopers start swaying where they stand, asleep in their loop, and wake when
## he comes close, when one is shot, or when an alarm screams. The stun pistol
## drops one like any thug; a downed looper stays down, and pulling its rig
## (E, World) ends the loop: for a moment they're themselves and say one line
## from their own life, then they sleep. No looper is ever killed.
##
## Placeholder: the looks (cast bodies as flat silhouettes, the rig a lit dot
## at the temple), the lines, and every number below are for trying out, not
## canon. DESIGN-TBD: Q7

const KINDS: Array[String] = ["brawler", "alarm", "grabber"]
## How close he has to come to wake one (native px).
const WAKE_RANGE: float = 110.0
## How far an alarm's scream carries.
const SCREAM_RANGE: float = 320.0
const SCREAM_EVERY: float = 2.5
const SCREAM_SHOW: float = 0.45
## An alarm runs when he's this close, and stops when he's this far.
const FLEE_NEAR: float = 170.0
const FLEE_SPEED: float = 74.0
const BRAWLER_SPEED: float = 42.0
## A brawler winds up when he's this close, then charges.
const BRAWLER_REACH: float = 70.0
const WINDUP_SECONDS: float = 0.45
const CHARGE_SPEED: float = 230.0
const CHARGE_SECONDS: float = 0.32
const RECOVER_SECONDS: float = 0.7
const GRABBER_SPEED: float = 34.0
const HOLD_SECONDS: float = 1.4
## A grabber lets go for this long after a hold before it can grab again.
const REGRIP_SECONDS: float = 1.6
## How close he has to be to pull a downed looper's rig.
const RIG_REACH: float = 26.0
## Placeholder lines, not canon: what a looper says, back as themselves for
## a moment after the rig comes off. DESIGN-TBD: Q6
const OWN_LINES: Array[String] = [
	"Is it still raining? It was raining when I sat down.",
	"I used to fix radios. I was good at it. Wasn't I?",
	"What day is it? Someone was waiting for me.",
	"That wasn't mine. None of that was mine.",
]
## Placeholder lines, not canon: the flash a grabber's hold pushes into him.
## DESIGN-TBD: Q6
const FLASHES: Array[String] = [
	"A kitchen, warm. A hand over mine. Not my hand. Not my kitchen.",
	"Someone singing in the next room. I know every word. I've never heard it.",
	"A hospital bed and a hand going cold in mine. Whose?",
]
const TINTS: Dictionary[String, Color] = {"brawler": Color("4a2c38"), "alarm": Color("2e3a4e"), "grabber": Color("3e2f4a")}
const FIGURES: Dictionary[String, String] = {"brawler": "pell", "alarm": "cass", "grabber": "velvet"}

enum State { ASLEEP, AWAKE, WINDUP, CHARGE, RECOVER, DOWN, SLEEPING }

var state: State = State.ASLEEP
## Whether its rig has been pulled (it sleeps for real).
var pulled: bool = false
## How wide its room is (native px), so a fleeing alarm stops at the walls.
var room_width: float = 640.0
var _t: float = 0.0
var _scream_in: float = 0.0
var _scream_show: float = 0.0
var _regrip: float = 0.0


static func make_looper(what: String, in_room: String, at: Vector2, width: float) -> Looper:
	var l: Looper = Looper.new()
	l.kind = what
	l.room = in_room
	l.position = at
	l.room_width = width
	l.hp = 3
	return l


func _ready() -> void:
	add_to_group("hostiles")
	add_to_group("loopers")
	_phase = randf() * TAU
	_scream_in = randf() * SCREAM_EVERY
	var anims: Array[String] = ["walk", "idle"]
	_sprite = CastSprite.new(FIGURES[kind], anims, TINTS[kind])
	# Behind the rig's light and the scream, which this node draws.
	_sprite.show_behind_parent = true
	add_child(_sprite)
	_stand()


func is_down() -> bool:
	return state == State.DOWN or state == State.SLEEPING


## Whether its rig can still be pulled: down, and the loop still running.
func can_pull() -> bool:
	return state == State.DOWN and not pulled


func wake() -> void:
	if state == State.ASLEEP:
		state = State.AWAKE


func hit() -> void:
	if is_down():
		return
	hp -= 1
	_flash = 0.12
	wake()
	if hp <= 0:
		_go_down()


## Pulls the rig: the loop ends, and it says one line of its own. Returns the
## line ("" when there's no rig to pull).
func pull_rig() -> String:
	if not can_pull():
		return ""
	pulled = true
	state = State.SLEEPING
	queue_redraw()
	return OWN_LINES[absi(hash(name + str(position.x))) % OWN_LINES.size()]


func _go_down() -> void:
	state = State.DOWN
	remove_from_group("hostiles")
	Case.hostile_down(room)
	_lie_down()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_phase += delta
	_scream_show = maxf(0.0, _scream_show - delta)
	_regrip = maxf(0.0, _regrip - delta)
	var d: Detective = get_tree().get_first_node_in_group("detective") as Detective
	if d == null or is_down():
		_sprite.modulate = Color.WHITE
		return
	var dx: float = d.position.x - position.x
	if state == State.ASLEEP:
		# Swaying where it stands, lost in the loop.
		_sprite.play_at("idle", _phase, 1)
		_sprite.position.x = _stand_x() + roundf(sin(_phase * 1.3))
		if absf(dx) < WAKE_RANGE:
			wake()
	else:
		_sprite.position.x = _stand_x()
		match kind:
			"brawler":
				_brawl(d, dx, delta)
			"alarm":
				_flee(dx, delta)
			"grabber":
				_cling(d, dx, delta)
	_sprite.flip_h = _facing < 0.0
	_sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else (Color(1.6, 1.3, 1.3) if state == State.WINDUP else Color.WHITE)
	queue_redraw()


func _brawl(d: Detective, dx: float, delta: float) -> void:
	_t -= delta
	match state:
		State.AWAKE:
			_facing = signf(dx) if dx != 0.0 else _facing
			if absf(dx) < BRAWLER_REACH:
				state = State.WINDUP
				_t = WINDUP_SECONDS
				_sprite.show_frame("idle", 0)
			else:
				_walk(signf(dx) * BRAWLER_SPEED * delta)
		State.WINDUP:
			if _t <= 0.0:
				state = State.CHARGE
				_t = CHARGE_SECONDS
		State.CHARGE:
			position.x += _facing * CHARGE_SPEED * delta
			_walked += CHARGE_SPEED * delta
			_sprite.step_at("walk", _walked, ArtCast.build(FIGURES[kind]).stride)
			if _touching(d):
				d.hurt("brawler")
			if _t <= 0.0:
				state = State.RECOVER
				_t = RECOVER_SECONDS
		State.RECOVER:
			_sprite.play_at("idle", _phase)
			if _t <= 0.0:
				state = State.AWAKE


func _flee(dx: float, delta: float) -> void:
	_scream_in -= delta
	if _scream_in <= 0.0:
		_scream_in = SCREAM_EVERY
		_scream_show = SCREAM_SHOW
		for node: Node in get_tree().get_nodes_in_group("loopers"):
			var l: Looper = node as Looper
			if l != null and l != self and absf(l.position.x - position.x) < SCREAM_RANGE:
				l.wake()
	if absf(dx) < FLEE_NEAR:
		_facing = -signf(dx) if dx != 0.0 else _facing
		var before: float = position.x
		position.x = clampf(position.x + _facing * FLEE_SPEED * delta, 20.0, room_width - 20.0)
		_walked += absf(position.x - before)
		_sprite.step_at("walk", _walked, ArtCast.build(FIGURES[kind]).stride)
	else:
		_facing = signf(dx) if dx != 0.0 else _facing
		_sprite.play_at("idle", _phase)


func _cling(d: Detective, dx: float, delta: float) -> void:
	_facing = signf(dx) if dx != 0.0 else _facing
	if d.held > 0.0:
		_sprite.play_at("idle", _phase)
		return
	if absf(dx) > 10.0:
		_walk(signf(dx) * GRABBER_SPEED * delta)
	else:
		_sprite.play_at("idle", _phase)
	if _regrip <= 0.0 and _touching(d) and d.grab(HOLD_SECONDS, "grabber"):
		_regrip = HOLD_SECONDS + REGRIP_SECONDS


## The flash its hold pushes into him (placeholder lines).
func flash_line() -> String:
	return FLASHES[absi(hash(name + str(_phase))) % FLASHES.size()]


func _walk(step: float) -> void:
	position.x += step
	_walked += absf(step)
	_sprite.step_at("walk", _walked, ArtCast.build(FIGURES[kind]).stride)


func _touching(d: Detective) -> bool:
	return absf(d.position.x - position.x) < 14.0 and absf(d.position.y - position.y) < 28.0


func _stand_x() -> float:
	return -floorf(_sprite.frame_size.x * 0.5)


func _stand() -> void:
	_sprite.rotation = 0.0
	_sprite.position = Vector2(_stand_x(), -_sprite.frame_size.y + 2)


## Lying on the floor, on its side.
func _lie_down() -> void:
	_sprite.flip_h = false
	_sprite.rotation = -PI / 2.0
	_sprite.position = Vector2(-_sprite.frame_size.y * 0.5, _sprite.frame_size.x * 0.5 - 13.0)
	_sprite.modulate = Color.WHITE


func _draw() -> void:
	# The rig: a lit dot at the temple while the loop runs.
	if not pulled:
		var pulse: float = 0.6 + 0.4 * sin(_phase * 6.0)
		var at: Vector2 = Vector2(-31, -13) if is_down() else Vector2(_facing * 2.0 - 1.0, -64)
		draw_rect(Rect2(at, Vector2(2, 2)), Color(P.CYAN, pulse))
	if _scream_show > 0.0:
		var r: float = (1.0 - _scream_show / SCREAM_SHOW) * 60.0 + 8.0
		draw_arc(Vector2(0, -60), r, 0.0, TAU, 24, Color(P.MAGENTA, _scream_show / SCREAM_SHOW), 1.0)
