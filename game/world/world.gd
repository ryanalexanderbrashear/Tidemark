class_name World
extends Node
## The main scene: the whole Drowned Market case in the game's look. Each room
## is drawn at 640 x 360 in a PixelView: the market floor and Vale's stall as
## drawn rooms (MarketScene, StallScene), every other room as a stand-in
## (StandInScene) until it's drawn. The detective (on the 8-head cast) walks,
## dashes, jumps and fights in it; the room's spots (DrownedMarket, placed by
## RoomLayout) open dialogue in the talk box; Tab opens the cork case board; X
## holds up what's in his pockets; T switches the thermal optic. His inner
## voice types over his head, and readings bring their white in like fog.
##
## The world freezes (the tree pauses) while anything is up in front of it: a
## dialogue, the board, a close-up, a door's fade, the case screens. The room's
## own life (rain, lamps, sound) runs on.

const P = preload("res://game/art/art_palette.gd")
## Where the left and right walls stop him.
const EDGE: float = 10.0
## Seconds to fade out (and in again) through a door.
const FADE_TIME: float = 0.3
## The legacy screens (intro, summary) and the bleed-through overlay are laid
## out for this size and scaled to the picture.
const LEGACY_SIZE: Vector2 = Vector2(960, 540)
## How far the white comes in when a looper's hold flashes its loop into him.
const GRAB_WHITE: float = 0.7
## In a fight the camera looks this far ahead of him (native px): he stands a
## third of the way across the screen and sees 430 px in front.
const FIGHT_LEAD: float = 110.0
## How fast the camera's look-ahead moves when he turns or a fight starts or
## ends (native px a second): a turn takes under a second to swing across.
const LEAD_SPEED: float = 260.0

var market: DrownedMarket
var layout: RoomLayout
var detective: Detective
## The room he's in (a DrownedMarket room id).
var room: String = ""
var fog: RoomScene.Fog = RoomScene.Fog.STEPPED
var reading_amount: float = 0.0

var _view: PixelView
var _scenes: Dictionary[String, RoomScene] = {}
## The physics side of the room (floor, ledges, hostiles, bolts) and the
## detective, moved with the camera. Pauses with the tree.
var _actors: Node2D
var _room_root: Node2D
var _detective_heat: Sprite2D
var _voice: InnerVoice
var _notices: Notices
var _examine: ExamineView
var _talk: TalkBox
var _board: CaseBoard
var _sound: ArtAmbience
var _bleed_root: Control
var _screen_root: Control
var _screen: Control
var _next_room: String = ""
var _next_x: float = 0.0
var _fade_t: float = 0.0
var _time: float = 0.0
var _limit_warned: bool = false
## How far ahead of him the camera looks now (native px, signed): eases to
## fight_lead() so he sees what's coming in a fight.
var cam_lead: float = 0.0
var _seen_market: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	market = DrownedMarket.new()
	# The chip is the examine tutorial: her body gives it, and turning it over
	# (X) finds the etching.
	market.etching_by_examining = true
	layout = RoomLayout.new(market)
	_build()
	Case.travel_requested.connect(_on_travel)
	Case.notice.connect(_notices.toast)
	Mind.thought.connect(_voice.say)
	# Deferred: a beat can fire from inside a dialogue choice, and the box closes
	# after the choice returns.
	Case.announcement.connect(func(who: String, text: String, at: String) -> void:
		_announce.call_deferred(who, text, at))
	Case.case_closed.connect(func(s: CaseSummary) -> void:
		_show_screen(CaseScreens.summary(s, _start, _start_fresh)))
	_view.laid_out.connect(_layout)
	_begin()
	print("Boot: Tidemark %s on Godot %s" % [ProjectSettings.get_setting("application/config/version"), Engine.get_version_info().string])


func _exit_tree() -> void:
	layout.release()


func _build() -> void:
	_view = PixelView.new()
	add_child(_view)
	_scenes["market"] = MarketScene.new(market)
	_scenes["stall"] = StallScene.new()
	for id: String in market.rooms:
		if not _scenes.has(id):
			_scenes[id] = StandInScene.new(market.rooms[id], layout)
	for id: String in _scenes:
		_scenes[id].build(_view)
	_actors = Node2D.new()
	_actors.process_mode = Node.PROCESS_MODE_PAUSABLE
	_view.people.add_child(_actors)
	_room_root = Node2D.new()
	_actors.add_child(_room_root)
	detective = Detective.new()
	detective.downed.connect(Case.player_downed)
	detective.grabbed.connect(_on_grabbed)
	_actors.add_child(detective)
	_detective_heat = _view.heat_sprite(1.0)

	_bleed_root = _legacy_root()
	_bleed_root.add_child(BleedOverlay.new())
	_voice = InnerVoice.new()
	add_child(_voice)
	_notices = Notices.new()
	add_child(_notices)
	_examine = ExamineView.new()
	add_child(_examine)
	_examine.item_shown.connect(func(_it: ExamineItem) -> void: _sound.play("pickup"))
	_examine.item_opened.connect(func(_it: ExamineItem) -> void: _sound.play("catch"))
	_examine.item_taken.connect(func(_it: ExamineItem) -> void: _sound.play("paper"))
	_examine.detail_found.connect(_on_detail_found)
	_talk = TalkBox.new()
	add_child(_talk)
	_board = CaseBoard.new()
	add_child(_board)
	_board.closed.connect(func() -> void: _sound.play("board"))
	_board.committed.connect(func(_id: String) -> void: _sound.play("found"))
	_screen_root = _legacy_root()
	_sound = ArtAmbience.new()
	add_child(_sound)


## A layer for UI laid out at LEGACY_SIZE, scaled onto the picture.
func _legacy_root() -> Control:
	var c: Control = Control.new()
	c.theme = UiTheme.make()
	c.size = LEGACY_SIZE
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func _layout(native: Vector2i, zoom: int, offset: Vector2) -> void:
	_examine.layout(native, zoom, offset)
	_talk.layout(native, zoom, offset)
	_board.layout(native, zoom, offset)
	for c: Control in [_bleed_root, _screen_root]:
		c.position = offset
		c.scale = Vector2.ONE * (_view.shown.x / LEGACY_SIZE.x)


## How the game opens: on the case brief.
func _begin() -> void:
	_show_screen(CaseScreens.intro(_start))


func _start() -> void:
	_clear_screen()
	Case.reset()
	_seen_market = false
	_voice.narration = ""
	_voice.said = ""
	_notices.clear_toasts()
	Case.travel(Case.RECOVERY_ROOM, Case.RECOVERY_X)
	_notices.toast("Captain Ruiz has the case brief. The market is east, past Broker's Row.")


## Play again with no symptoms and a full bottle.
func _start_fresh() -> void:
	Mind.reset()
	_start()


# ---------- rooms ----------

## A door opened or he walked off an edge: fade through to the room (straight
## there when nothing's showing yet).
func _on_travel(to: String, x: float) -> void:
	if room == "" or _screen != null:
		_load_room(to, x)
		return
	_next_room = to
	_next_x = x
	_fade_t = 0.0
	_sound.play("catch")


func _update_fade(delta: float) -> void:
	if _next_room != "":
		_fade_t += delta / FADE_TIME
		if _fade_t >= 1.0:
			var to: String = _next_room
			_next_room = ""
			_fade_t = 1.0
			_load_room(to, _next_x)
	elif _fade_t > 0.0:
		_fade_t = maxf(0.0, _fade_t - delta / FADE_TIME)
	_view.set_fade(_fade_t)


## Puts him in `id` at native `x` straight away, through the case.
func arrive(id: String, x: float) -> void:
	_clear_screen()
	Case.travel(id, 0.0)
	_next_room = ""
	_fade_t = 0.0
	_view.set_fade(0.0)
	_load_room(id, 0.0)
	detective.position = Vector2(x, RoomLayout.WALK_Y)
	cam_lead = fight_lead()


func _load_room(id: String, world_x: float) -> void:
	room = id
	for s: String in _scenes:
		_scenes[s].set_shown(s == id)
	for c: Node in _room_root.get_children():
		c.queue_free()
	var width: float = float(_scene().width)
	_room_root.add_child(_solid(Rect2(-200, RoomLayout.WALK_Y, width + 400, 120), false))
	for l: Rect2 in layout.ledges(id):
		_room_root.add_child(_solid(l, true))
	if id == Case.RECOVERY_ROOM and is_equal_approx(world_x, Case.RECOVERY_X):
		detective.heal()
	detective.position = Vector2(clampf(layout.to_native(id, world_x), EDGE, width - EDGE), RoomLayout.WALK_Y)
	detective.velocity = Vector2.ZERO
	var spawns: Array[Vector2] = layout.spawns(id)
	var left: int = Case.hostiles.get(id, 0)
	for i: int in mini(left, spawns.size()):
		var h: Hostile = Hostile.make(market.rooms[id].spawn_kind, id, spawns[i])
		if h.kind == "thug":
			h.heat = _view.heat_sprite(1.0)
		_room_root.add_child(h)
	_limit_warned = false
	var line: String = Mind.room_line(randf(), randi())
	if id == "market" and not _seen_market:
		_seen_market = true
		_voice.narrate(DrownedMarket.MARKET_OPENING)
	if line != "":
		_voice.say(line)
	elif id == "market" and DrownedMarket.chip_unexamined():
		_voice.say(DrownedMarket.CHIP_REMINDER)


func _solid(r: Rect2, one_way: bool) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.position + r.size / 2.0
	shape.one_way_collision = one_way
	body.add_child(shape)
	return body


func _scene() -> RoomScene:
	return _scenes[room]


## Walking off an edge leads on (or a hard stop says why not).
func _check_edges() -> void:
	var def: RoomDef = market.rooms[room]
	var x: float = detective.position.x
	if x < EDGE:
		if def.exit_left != "":
			Case.travel(def.exit_left, def.exit_left_x)
			return
		detective.position.x = EDGE
	var right: float = layout.to_native(room, def.limit) if def.limit > 0.0 else float(_scene().width)
	if x > right - EDGE:
		if def.exit_right != "" and def.limit == 0.0:
			Case.travel(def.exit_right, def.exit_right_x)
			return
		detective.position.x = right - EDGE
		if def.limit_line != "" and not _limit_warned:
			_limit_warned = true
			_notices.toast(def.limit_line)
	elif x < right - 60.0:
		_limit_warned = false


# ---------- each frame ----------

## Where the camera wants to look: FIGHT_LEAD ahead of the way he faces while
## the room has hostiles, so a fight shows more in front of him than behind
## (he stands a third of the way across); centred on him otherwise.
func fight_lead() -> float:
	return detective.facing * FIGHT_LEAD if Case.hostiles_left(room) else 0.0


## True while something is up in front of the room.
func busy() -> bool:
	return _screen != null or _examine.is_open() or _talk.visible or _board.is_open() or _next_room != ""


func _process(delta: float) -> void:
	_time += delta
	get_tree().paused = busy()
	if room == "":
		return
	if not get_tree().paused:
		_check_edges()
	cam_lead = move_toward(cam_lead, fight_lead(), LEAD_SPEED * delta)
	var cam: float = _scene().cam_x(detective.position.x, roundf(cam_lead))
	_actors.position = Vector2(-cam, 0)
	_scene().update(cam, _time, fog)
	_update_heat()
	_update_fade(delta)
	_update_reading(delta)
	if _screen == null:
		_voice.advance(delta)
	_voice.show_line(_view, Vector2(detective.position.x - cam, detective.position.y - detective.sprite.frame_size.y - 6), busy())
	_update_prompt(cam)
	_notices.update_toast(_view, delta, _examine.is_open())
	_update_status()
	_sound.muffled = busy()
	_sound.indoors = not _scene().outdoors
	_sound.update(delta, detective.position.x - _scene().lamp_x, _scene().lamp_on)


## The thermal optic: the cold picture over everything, and the warm drawn on
## top of it from each warm sprite's own shape.
func _update_heat() -> void:
	_view.set_thermal(Case.optic_on)
	if not Case.optic_on:
		return
	_scene().update_heat()
	_mirror(detective.sprite, _detective_heat)
	for node: Node in get_tree().get_nodes_in_group("hostiles"):
		var h: Hostile = node as Hostile
		if h != null and h.heat != null and h.get_child_count() > 0:
			_mirror(h.get_child(0) as Sprite2D, h.heat)


func _mirror(src: Sprite2D, heat: Sprite2D) -> void:
	heat.visible = src.is_visible_in_tree()
	heat.texture = src.texture
	heat.position = src.global_position
	heat.flip_h = src.flip_h
	heat.rotation = src.global_rotation


## A reading's white comes in while its words are up: part way for a surface
## reading, nearly to the middle for a deep one.
func _update_reading(delta: float) -> void:
	var target: float = RoomLayout.reading_depth(_talk.talk) if _talk.visible else 0.0
	reading_amount = move_toward(reading_amount, target, delta * (0.8 if target > reading_amount else 1.6))
	_view.set_reading(reading_amount, _time)


func nearest_spot() -> Spot:
	return layout.nearest(room, detective.position.x, detective.position.y)


func _update_prompt(cam: float) -> void:
	var l: Looper = null if busy() else nearest_rig()
	if l != null:
		_notices.prompt(_view, "E  Pull the rig", Vector2(l.position.x - cam, RoomLayout.PROMPT_Y_LOW))
		return
	var s: Spot = null if busy() else nearest_spot()
	if s == null:
		_notices.prompt(_view, "")
		return
	_notices.prompt(_view, RoomLayout.prompt(s), Vector2(RoomLayout.place(s).x - cam, RoomLayout.prompt_y(s)))


func _update_status() -> void:
	var parts: PackedStringArray = []
	var struck: bool = Case.has_beat("second_victim")
	parts.append(Case.clock_text(Case.minutes) + ("  KILLER STRUCK AGAIN" if struck else ""))
	parts.append("BADGE " + ("ACTIVE" if Case.clearance else "REVOKED"))
	parts.append("HP " + "■".repeat(detective.hp) + "□".repeat(Detective.MAX_HP - detective.hp))
	if Case.has_optic:
		parts.append("THERMAL" if Case.optic_on else "optic off")
	parts.append("BLEED %d/%d  PILLS %d" % [Mind.level(), Mind.tuning.bleed_max, Mind.pills])
	_notices.status_color(P.BLOOD.lightened(0.4) if struck else P.AMBER)
	_notices.status(_view, "   ".join(parts))
	var def: RoomDef = market.rooms[room]
	_notices.corner(_view, def.title + ("" if RoomLayout.is_drawn(room) else "  (stand-in art)"))


# ---------- input ----------

func _unhandled_input(event: InputEvent) -> void:
	if busy() or room == "":
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and _sandbox_key(key):
		return
	if event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("optic"):
		toggle_optic()
	elif event.is_action_pressed("dose"):
		Mind.take_dose()
	elif event.is_action_pressed("examine"):
		examine()
	elif event.is_action_pressed("case_board"):
		_sound.play("board")
		_board.open()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
			and (event as InputEventKey).keycode in [KEY_F2, KEY_F3]:
		# Playtest keys: raise bleed-through, or clear the detective's mind.
		if (event as InputEventKey).keycode == KEY_F2:
			Mind.add_bleed(2)
			_notices.toast("Playtest: bleed-through %d/%d (%s)" % [Mind.bleed, Mind.tuning.bleed_max, Mind.tier_name()])
		else:
			Mind.reset()
			_notices.toast("Playtest: symptoms, pills and passengers reset")


## A downed looper by him whose rig he can pull, nearest first, or null.
func nearest_rig() -> Looper:
	var best: Looper = null
	for node: Node in get_tree().get_nodes_in_group("loopers"):
		var l: Looper = node as Looper
		if l == null or not l.can_pull() or absf(l.position.y - detective.position.y) > RoomLayout.REACH_Y:
			continue
		var d: float = absf(l.position.x - detective.position.x)
		if d <= Looper.RIG_REACH and (best == null or d < absf(best.position.x - detective.position.x)):
			best = l
	return best


## E: pulls a downed looper's rig if he's by one: the loop ends, and for a
## moment they're themselves. Otherwise uses the spot he's standing at.
func interact() -> void:
	var l: Looper = nearest_rig()
	if l != null:
		_sound.play("catch")
		_show_talk(Talk.say("Looper", l.pull_rig()))
		return
	var s: Spot = nearest_spot()
	if s == null:
		return
	var t: Talk = s.use()
	if t != null and not Case.closed:
		_show_talk(t)
	# The chip is the examine tutorial: the voice leads him to turn it over
	# once the body's talk is done (the voice waits while the box is up).
	if s.id == "body" and DrownedMarket.chip_unexamined():
		_voice.narration = ""
		_voice.say(DrownedMarket.CHIP_HINT)


## Keys only the sandbox (ArtTest) knows. True when the key was used.
func _sandbox_key(_key: InputEventKey) -> bool:
	return false


## T: the thermal optic, if he has it.
func toggle_optic() -> void:
	if not Case.has_optic:
		_notices.toast("You don't have a thermal optic yet.")
		return
	_sound.play("turn")
	Case.toggle_optic()


## X: holds up what's in his pockets: the chip once he's taken it from her
## hand (turning it over finds the etching), the storage tag once he's found
## it.
func examine() -> void:
	var items: Array[ExamineItem] = _pockets()
	if items.is_empty():
		_notices.toast("Nothing in your pockets worth a closer look yet.")
		return
	_examine.items = items
	_examine.open(0)


func _pockets() -> Array[ExamineItem]:
	var items: Array[ExamineItem] = []
	if Case.is_set("has_chip") or Case.has_clue("chip"):
		items.append(ExamineItem.chip())
	if Case.has_clue("tag"):
		items.append(ExamineItem.tag())
	return items


func _on_detail_found(it: ExamineItem) -> void:
	_sound.play("found")
	if it.clue != "":
		Case.find_clue(it.clue)
	if it.id == "chip":
		_voice.unsay(DrownedMarket.CHIP_HINT)
		_voice.unsay(DrownedMarket.CHIP_REMINDER)


## A looper's hold pushes its loop into him: a flash of someone else's
## memory (the reading's white, and the memory in his inner voice). It leaves
## no lasting symptom; those come only from readings he chooses.
func _on_grabbed(_by: String) -> void:
	var grip: Looper = null
	for node: Node in get_tree().get_nodes_in_group("loopers"):
		var l: Looper = node as Looper
		if l != null and l.kind == "grabber" and (grip == null or absf(l.position.x - detective.position.x) < absf(grip.position.x - detective.position.x)):
			grip = l
	reading_amount = maxf(reading_amount, GRAB_WHITE)
	if grip != null:
		_voice.say(grip.flash_line())


func _announce(who: String, text: String, at: String) -> void:
	if not Case.closed:
		_show_talk(Talk.say(who, at + ".  " + text))


func _show_talk(t: Talk) -> void:
	_sound.play("talk")
	_talk.show_talk(t)


func _show_screen(c: Control) -> void:
	_clear_screen()
	_talk.hide()
	_board.hide()
	if _examine.is_open():
		_examine.close()
	_screen = c
	_screen_root.add_child(c)


func _clear_screen() -> void:
	if _screen != null:
		_screen.queue_free()
		_screen = null
