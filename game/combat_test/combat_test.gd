class_name CombatTest
extends World
## The combat test ground: a sandbox for fights, like the art test is for the
## look. It's the game itself (World) with the same detective, hostiles and
## bolts, set in one arena room that isn't part of the case, so tuning a fight
## here tunes the case's fights too. Only the arena and the try-out keys live
## here:
##
## - 1 a thug, 2 a drone, 3 a wave (a thug from each side and a drone),
##   C clears the room, R refills his health.
## - Loopers (Looper): 4 a brawler, 5 an alarm, 6 a grabber, 7 a crowd (two
##   brawlers, a grabber and an alarm, asleep in their loops). E pulls a
##   downed looper's rig.
## - B shows hit boxes: his body (cyan while a dash lets hits through), each
##   hostile's, and in amber how close a thug has to get to land a blow (the
##   box around the thug's feet that the tick at his own feet must be inside).
## - I makes him unhurtable, M runs the world at quarter speed.
## - H hides the key list.
##
## The status line shows his health, the dash's cooldown, what hit him last
## and how many hits his dashes slipped. Getting downed puts him back at the
## start with full health (the game would wake him in the precinct), and
## whoever he was fighting stays, as in the game.
##
## The arena is a stand-in room (placeholder, not canon): open floor, a step of
## low ledges to jump and dash between, and a far ledge that takes a running
## jump out of a dash to reach.

const ARENA: String = "arena"
## Where he starts, and where he comes back to when downed (native x).
const START_X: float = 120.0
## How far in front of him a new hostile appears (native px).
const SPAWN_AHEAD: float = 240.0
## A drone's height above the floor when it appears (native px).
const DRONE_HEIGHT: float = 140.0
const SLOW_MOTION: float = 0.25
## How far a thug's blow reaches (Hostile: within 14 px across, 28 up or down).
const THUG_REACH: Vector2 = Vector2(14, 28)

var show_boxes: bool = false
var unhurtable: bool = false
var slow_motion: bool = false
## What hit him last ("" before anything has), and how many hits his dashes
## have let through since the start.
var last_hit: String = ""
var slipped_count: int = 0
var downed_count: int = 0

var _keys: Label
var _boxes: Boxes


## The arena: a stand-in room in grey-box units, like the case's rooms.
static func arena() -> RoomDef:
	var r: RoomDef = RoomDef.make(ARENA, "Combat test ground", 1440, Color("0c1018"), Color("1a2230"), Color("1c2430"))
	r.ledge(300, 420, 140).ledge(500, 370, 160).ledge(1020, 400, 200)
	return r


func _build() -> void:
	market.rooms[ARENA] = arena()
	super._build()
	detective.downed.disconnect(Case.player_downed)
	detective.downed.connect(_on_downed)
	detective.hurt_by.connect(_on_hurt)
	detective.slipped.connect(func(_what: String) -> void: slipped_count += 1)
	_boxes = Boxes.new()
	_boxes.test = self
	_boxes.z_index = 50
	_actors.add_child(_boxes)
	_keys = Label.new()
	_keys.add_theme_color_override("font_color", Color(P.RAIN, 0.8))
	add_child(_keys)
	move_child(_keys, _notices.get_index() + 1)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	super._exit_tree()


func _begin() -> void:
	start()


## Starts over: an empty arena, him at the start with full health. He carries
## the thermal optic, so fights can be tried in its picture too.
func start() -> void:
	Case.reset()
	Case.grant_optic()
	last_hit = ""
	slipped_count = 0
	downed_count = 0
	arrive(ARENA, START_X)
	detective.heal()
	_notices.clear_toasts()


func _layout(native: Vector2i, zoom: int, offset: Vector2) -> void:
	super._layout(native, zoom, offset)
	_keys.add_theme_font_size_override("font_size", maxi(12, roundi(float(get_window().size.y) / 70.0)))
	_keys.position = offset + Vector2(12, 26)


func _process(delta: float) -> void:
	super._process(delta)
	_keys.text = "A/D move   Shift dash (+S slide)   W/Space jump   F stun pistol   T thermal   E pull a rig\n1 thug   2 drone   3 wave   4 brawler   5 alarm   6 grabber   7 looper crowd   C clear\nR refill health   B hit boxes   I unhurtable   M slow motion   H hide"
	_boxes.visible = show_boxes
	_boxes.queue_redraw()


func _update_status() -> void:
	var parts: PackedStringArray = []
	parts.append("HP " + "■".repeat(detective.hp) + "□".repeat(Detective.MAX_HP - detective.hp))
	var wait: float = detective.dash_wait()
	parts.append("DASH " + ("ready" if wait <= 0.0 else "%.2fs" % wait))
	parts.append("HOSTILES %d" % hostiles().size())
	if detective.held > 0.0:
		parts.append("HELD %.1fs" % detective.held)
	parts.append("LAST HIT " + (last_hit if last_hit != "" else "-"))
	parts.append("SLIPPED %d  DOWNED %d" % [slipped_count, downed_count])
	var modes: PackedStringArray = []
	if unhurtable:
		modes.append("UNHURTABLE")
	if slow_motion:
		modes.append("SLOW")
	if Case.optic_on:
		modes.append("THERMAL")
	if not modes.is_empty():
		parts.append(" ".join(modes))
	_notices.status_color(P.AMBER)
	_notices.status(_view, "   ".join(parts))
	_notices.corner(_view, market.rooms[room].title + "  (sandbox, stand-in art)")


func _sandbox_key(key: InputEventKey) -> bool:
	match key.physical_keycode:
		KEY_1:
			spawn("thug")
		KEY_2:
			spawn("drone")
		KEY_3:
			wave()
		KEY_4:
			spawn("brawler")
		KEY_5:
			spawn("alarm")
		KEY_6:
			spawn("grabber")
		KEY_7:
			crowd()
		KEY_C:
			clear()
		KEY_R:
			detective.heal()
		KEY_B:
			show_boxes = not show_boxes
		KEY_I:
			unhurtable = not unhurtable
			if unhurtable:
				detective.heal()
		KEY_M:
			set_slow_motion(not slow_motion)
		KEY_H:
			_keys.visible = not _keys.visible
		_:
			return false
	return true


# ---------- hostiles ----------

## Puts a hostile of `kind` ("thug", "drone", or a Looper kind) in the arena, SPAWN_AHEAD in
## front of him (behind him when that's past the wall), or `side` px off his
## position when given.
func spawn(kind: String, side: float = 0.0) -> Hostile:
	var width: float = float(_scene().width)
	var off: float = side if side != 0.0 else detective.facing * SPAWN_AHEAD
	var x: float = detective.position.x + off
	if x < EDGE * 3.0 or x > width - EDGE * 3.0:
		x = detective.position.x - off
	x = clampf(x, EDGE * 3.0, width - EDGE * 3.0)
	var y: float = RoomLayout.WALK_Y - (DRONE_HEIGHT if kind == "drone" else 0.0)
	var h: Hostile
	if Looper.KINDS.has(kind):
		h = Looper.make_looper(kind, ARENA, Vector2(x, y), width)
	else:
		h = Hostile.make(kind, ARENA, Vector2(x, y))
	if kind != "drone":
		h.heat = _view.heat_sprite(1.0)
	_room_root.add_child(h)
	Case.spawn_hostiles(ARENA, hostiles().size())
	return h


## A thug from each side and a drone overhead.
func wave() -> void:
	spawn("thug", SPAWN_AHEAD)
	spawn("thug", -SPAWN_AHEAD)
	spawn("drone", SPAWN_AHEAD * 0.5)


## Loopers asleep in their loops ahead of him: two brawlers, a grabber, and
## an alarm at the back that wakes the rest.
func crowd() -> void:
	var ahead: float = detective.facing
	spawn("brawler", ahead * 200.0)
	spawn("grabber", ahead * 250.0)
	spawn("brawler", ahead * 300.0)
	spawn("alarm", ahead * 380.0)


## Takes every hostile and bolt out of the room.
func clear() -> void:
	for c: Node in _room_root.get_children():
		if c is Hostile or c is Bolt:
			_room_root.remove_child(c)
			c.queue_free()
	for c: Node in _actors.get_children():
		if c is Bolt:
			_actors.remove_child(c)
			c.queue_free()
	Case.spawn_hostiles(ARENA, 0)


## The hostiles standing in the arena now.
func hostiles() -> Array[Hostile]:
	var out: Array[Hostile] = []
	for c: Node in _room_root.get_children():
		var h: Hostile = c as Hostile
		if h != null and not h.is_queued_for_deletion() and not (h is Looper and (h as Looper).is_down()):
			out.append(h)
	return out


func set_slow_motion(on: bool) -> void:
	slow_motion = on
	Engine.time_scale = SLOW_MOTION if on else 1.0


func _on_hurt(what: String) -> void:
	last_hit = what if what != "" else "unnamed"
	if unhurtable:
		detective.hp = Detective.MAX_HP


## Back to the start with full health; the hostiles stay, as in the game.
func _on_downed() -> void:
	downed_count += 1
	detective.position = Vector2(START_X, RoomLayout.WALK_Y)
	detective.velocity = Vector2.ZERO
	detective.heal()
	_notices.toast("Downed. The game would wake him in the precinct infirmary; here he's back at the start.")


## Hit boxes over the room, moved with the camera like the actors.
class Boxes:
	extends Node2D

	var test: CombatTest

	func _draw() -> void:
		var d: Detective = test.detective
		var body: Color = P.CYAN if d.dashing > 0.0 else Color("7fe0a0")
		draw_rect(d.hit_box(), Color(body, 0.25))
		draw_rect(d.hit_box(), body, false, 1.0)
		for h: Hostile in test.hostiles():
			draw_rect(h.hit_box(), Color(P.MAGENTA, 0.2))
			draw_rect(h.hit_box(), P.MAGENTA, false, 1.0)
			if h.kind == "thug":
				# A blow lands when the middle of his feet is inside this box.
				var reach: Rect2 = Rect2(h.position - test.THUG_REACH, test.THUG_REACH * 2.0)
				draw_rect(reach, Color(P.AMBER, 0.6), false, 1.0)
				draw_line(d.position + Vector2(0, -4), d.position + Vector2(0, 4), P.AMBER)
