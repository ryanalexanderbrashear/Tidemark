class_name World
extends Node2D
## The main scene: builds the current room from DrownedMarket, runs the
## detective and hostiles in it, and opens dialogue, the case board and the
## case screens over it (pausing the room while they're open).

const FLOOR_Y: float = 470.0
const EDGE: float = 14.0
const USE_RANGE_X: float = 34.0
const USE_RANGE_Y: float = 70.0

var market: DrownedMarket
var detective: Detective
var _room_root: Node2D
var _view: RoomView
var _camera: Camera2D
var _hud: Hud
var _dialog: DialogBox
var _board: CaseBoard
var _ui: CanvasLayer
var _screen: Control
var _limit_warned: bool = false


func _ready() -> void:
	market = DrownedMarket.new()
	_ui = CanvasLayer.new()
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui)
	var root: Control = Control.new()
	root.theme = UiTheme.make()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	root.add_child(BleedOverlay.new())
	_hud = Hud.new()
	root.add_child(_hud)
	_dialog = DialogBox.new()
	_dialog.closed.connect(_resume)
	root.add_child(_dialog)
	_board = CaseBoard.new()
	_board.closed.connect(_resume)
	root.add_child(_board)

	_room_root = Node2D.new()
	add_child(_room_root)
	_camera = Camera2D.new()
	_camera.limit_top = 0
	_camera.limit_bottom = 540
	add_child(_camera)

	Case.travel_requested.connect(_load_room)
	Case.notice.connect(_hud.toast)
	Mind.thought.connect(_hud.thought)
	# Deferred: a beat can fire from inside a dialogue choice, and the box closes
	# after the choice returns.
	Case.announcement.connect(func(who: String, text: String, at: String) -> void:
		_announce.call_deferred(who, text, at))
	Case.case_closed.connect(func(s: CaseSummary) -> void:
		_show_screen(CaseScreens.summary(s, _start, _start_fresh)))
	_show_screen(CaseScreens.intro(_start))
	print("Boot: Undertow %s on Godot %s" % [ProjectSettings.get_setting("application/config/version"), Engine.get_version_info().string])


func _start() -> void:
	_clear_screen()
	Case.reset()
	Case.travel("lab", 200.0)
	_hud.toast("Captain Ruiz has the case brief. The market is east, past Broker's Row.")
	get_tree().paused = false


## Play again with no symptoms and a full bottle.
func _start_fresh() -> void:
	Mind.reset()
	_start()


func _load_room(id: String, x: float) -> void:
	var room: RoomDef = market.rooms[id]
	for c: Node in _room_root.get_children():
		c.queue_free()
	_view = RoomView.new()
	_view.room = room
	_view.spots = market.spots_in(id)
	_room_root.add_child(_view)
	_room_root.add_child(_solid(Rect2(-200, FLOOR_Y, room.width + 400, 200), false))
	for l: Rect2 in room.ledges:
		_room_root.add_child(_solid(l, true))
	if detective == null:
		detective = Detective.new()
		detective.downed.connect(Case.player_downed)
		add_child(detective)
		_hud.detective = detective
	if id == Case.RECOVERY_ROOM and x == Case.RECOVERY_X:
		detective.heal()
	detective.position = Vector2(x, FLOOR_Y)
	detective.velocity = Vector2.ZERO
	var left: int = Case.hostiles.get(id, 0)
	for i: int in mini(left, room.spawns.size()):
		_room_root.add_child(Hostile.make(room.spawn_kind, id, room.spawns[i]))
	_camera.limit_left = 0
	_camera.limit_right = int(maxf(room.width, 960.0))
	_camera.position = detective.position
	_camera.reset_smoothing()
	_hud.room_title = room.title
	_limit_warned = false
	var line: String = Mind.room_line(randf(), randi())
	if line != "":
		_hud.thought.call_deferred(line)


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


func _physics_process(_delta: float) -> void:
	if detective == null or _view == null or get_tree().paused:
		return
	var room: RoomDef = market.rooms[Case.room]
	var x: float = detective.position.x
	if x < EDGE:
		if room.exit_left != "":
			Case.travel(room.exit_left, room.exit_left_x)
			return
		detective.position.x = EDGE
	var right: float = room.right_limit()
	if x > right - EDGE:
		if room.exit_right != "" and room.limit == 0.0:
			Case.travel(room.exit_right, room.exit_right_x)
			return
		detective.position.x = right - EDGE
		if room.limit_line != "" and not _limit_warned:
			_limit_warned = true
			_hud.toast(room.limit_line)
	elif x < right - 80.0:
		_limit_warned = false
	_camera.position = Vector2(detective.position.x, 270)
	_view.camera_x = clampf(detective.position.x - 480.0, 0.0, maxf(0.0, room.width - 960.0))
	_view.nearest = _nearest_spot()
	detective.optic_on = Case.optic_on


func _nearest_spot() -> Spot:
	var best: Spot = null
	var best_d: float = INF
	for s: Spot in _view.spots:
		if not s.is_visible():
			continue
		var d: float = absf(s.x + s.size.x / 2.0 - detective.position.x)
		if d < s.size.x / 2.0 + USE_RANGE_X and absf(s.y - detective.position.y) < USE_RANGE_Y and d < best_d:
			best_d = d
			best = s
	return best


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or _view == null:
		return
	if event.is_action_pressed("interact"):
		var s: Spot = _nearest_spot()
		if s != null:
			var t: Talk = s.use()
			if t != null and not Case.closed:
				_show_talk(t)
	elif event.is_action_pressed("optic"):
		if Case.has_optic:
			_hud.toast("Thermal optic on" if Case.toggle_optic() else "Thermal optic off")
		else:
			_hud.toast("You don't have a thermal optic yet.")
	elif event.is_action_pressed("dose"):
		Mind.take_dose()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
			and (event as InputEventKey).keycode in [KEY_F2, KEY_F3]:
		# Playtest keys: raise bleed-through, or clear the detective's mind.
		if (event as InputEventKey).keycode == KEY_F2:
			Mind.add_bleed(2)
			_hud.toast("Playtest: bleed-through %d/%d (%s)" % [Mind.bleed, Mind.tuning.bleed_max, Mind.tier_name()])
		else:
			Mind.reset()
			_hud.toast("Playtest: symptoms, pills and passengers reset")
	elif event.is_action_pressed("case_board"):
		get_tree().paused = true
		_board.open_board()


func _announce(who: String, text: String, at: String) -> void:
	if not Case.closed:
		_show_talk(Talk.say(who, at + ".  " + text))


func _show_talk(t: Talk) -> void:
	get_tree().paused = true
	_dialog.show_talk(t)


func _resume() -> void:
	if _screen == null and not _board.visible and not _dialog.visible:
		get_tree().paused = false


func _show_screen(c: Control) -> void:
	_clear_screen()
	_dialog.hide()
	_board.hide()
	_screen = c
	(_ui.get_child(0) as Control).add_child(c)
	get_tree().paused = true


func _clear_screen() -> void:
	if _screen != null:
		_screen.queue_free()
		_screen = null
