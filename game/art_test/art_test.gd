class_name ArtTest
extends Node
## The Drowned Market style test (milestone M3 in Gameplay and Production): one
## stretch of the market floor drawn at the game's resolution (640 x 360), which
## settled the Look and Feel doc's questions on resolution, character size and
## how the detective's inner voice is shown. It's built from the game's shared
## pieces (PixelView, MarketScene, StallScene, CastSprite, InnerVoice, Notices,
## the talk box, board, examine view and sound), so what's tried here is what
## the game gets.
##
## It still compares the fog, water and neon motif two ways (Look and Feel doc,
## "Fog, water and neon"): stepped fog is pixel art like everything else;
## volumetric fog is drawn at the window's own resolution behind the crisp
## pixel-art playable layer.
##
## X opens the examine test (ExamineView): the items in the detective's pockets,
## held up close and turned over by hand to find what's on their other side.
##
## It's also a playable slice of the case, the whole loop in small
## (ArtMarketFloor): an opening caption, the market floor and Vale's stall (a
## second room, through her badge-taped door), the case's own people and
## objects in both, so E talks to them in a styled box (ArtTalkBox) and clues
## land in `Case`. Her body can be read: the reading's white comes in like fog,
## and a deep one brings her back as a passenger, standing at the fog's edge
## on the market floor. T switches on the thermal optic: the fog falls away,
## the cold goes dark blue, people show their heat, her passenger shows none,
## and a boarded stall turns out to be a heat-sealed door. Tab opens the case
## board (ArtBoard), and turning the chip over finds its etching. Placeholder
## sound (ArtAmbience) plays under it all, muffled while the detective is
## talking, at the board or holding something up.
##
## Keys: A/D move (hold Shift to sprint), E use, Tab case board, T thermal optic,
## X examine items, V switches the inner voice, F switches the fog, N shows the
## next thought, H hides the key list.
## Screenshots: run with `-- --shots=<dir>` and it saves a fixed set and quits.

const P = preload("res://game/art/art_palette.gd")
const VOICE_NAMES: Array[String] = ["thought text by the detective", "caption box", "silence"]
const FOG_NAMES: Array[String] = ["stepped pixel fog", "volumetric fog behind pixel art", "no fog"]
## Walking pace: about 1.5 walk cycles a second with the 8-head detective's
## stride.
const SPEED: float = 54.0
## Sprinting (hold Shift): about 1.5 run cycles a second with the detective's
## run_stride, a little under three times walking pace.
const SPRINT_SPEED: float = 144.0
## Where prompts sit over a spot (native y): above everyone's heads, or under
## the camera on its pole.
const PROMPT_Y: float = 178.0
const PROMPT_Y_CAMS: float = 96.0
## Inside the stall, over the counter and the floor.
const PROMPT_Y_LOW: float = 222.0
## Seconds to fade out (and in again) through a door.
const FADE_TIME: float = 0.3

## Scene-opening narration, in the caption box. Placeholder, not canon.
const OPENING: String = "The Drowned Market. Ines Vale's stall is taped off, the shutter's sealed, and the badge reader by it is waiting for me."

## Placeholder lines for the test. They lean on what the docs settle (Vale, the
## market, the badge), but they're not canon dialogue.
const THOUGHTS: Array[String] = [
	"Ines Vale sold other people's memories for a living. Somebody took the last one she had.",
	"The rain never stops down here. It just finds new ways in.",
	"Tape, a badge reader, a stall sealed with her inside. My badge still opens doors. For now.",
]

var fog: RoomScene.Fog = RoomScene.Fog.STEPPED
var detective_x: float = ArtMarketFloor.START_X
var facing: int = 1
## Which drawn room the detective is in ("market" or "stall").
var room: String = "market"
## Sprinting this frame (moving with Shift held).
var sprinting: bool = false
var reading_amount: float = 0.0

var _view: PixelView
var _scenes: Dictionary[String, RoomScene] = {}
var _market_scene: MarketScene
var _detective: CastSprite
var _detective_heat: Sprite2D
var _stride: float
var _run_stride: float
var _voice: InnerVoice
var _notices: Notices
var _keys: Label
var _examine: ExamineView
var _talk: ArtTalkBox
var _board: ArtBoard
var _sound: ArtAmbience
var _floor: ArtMarketFloor
var _fade_t: float = 0.0
var _next_room: String = ""
var _time: float = 0.0
## Distance walked, so the walk frames keep the planted foot still.
var _walk_dist: float = 0.0
## Screenshots only: shows this walk frame instead of standing (-1: off).
var _shot_walk: int = -1
## Screenshots only: shows the sprint instead of the walk.
var _shot_sprint: bool = false
var _shooting: bool = false


func _ready() -> void:
	# The case starts before the scene listens, so its starting clues don't toast.
	ArtMarketFloor.start_case()
	_floor = ArtMarketFloor.new()
	_build()
	Case.notice.connect(toast)
	Case.travel_requested.connect(_on_travel)
	Mind.thought.connect(say)
	Case.announcement.connect(func(who: String, text: String, at: String) -> void:
		_show_talk.call_deferred(Talk.say(who, at + ".  " + text)))
	_view.laid_out.connect(_layout)
	_enter_scene(room)
	var shots: String = _shots_dir()
	if shots != "":
		_take_shots.call_deferred(shots)


func _exit_tree() -> void:
	_floor.release()


func _build() -> void:
	_view = PixelView.new()
	add_child(_view)
	_market_scene = MarketScene.new(_floor.market)
	_scenes["market"] = _market_scene
	_scenes["stall"] = StallScene.new()
	for id: String in _scenes:
		_scenes[id].build(_view)
	# The detective goes between rooms, so he's in neither room's node.
	var anims: Array[String] = ["idle", "walk", "run"]
	_detective = CastSprite.new("detective", anims)
	_view.people.add_child(_detective)
	_detective_heat = _view.heat_sprite(1.0)
	_stride = ArtCast.build("detective").stride
	_run_stride = ArtCast.build("detective").run_stride

	_voice = InnerVoice.new()
	_voice.thoughts.assign(THOUGHTS)
	_voice.narrate(OPENING)
	add_child(_voice)
	_keys = Label.new()
	_keys.add_theme_color_override("font_color", Color(P.RAIN, 0.8))
	add_child(_keys)
	_notices = Notices.new()
	add_child(_notices)

	_examine = ExamineView.new()
	add_child(_examine)
	_examine.item_shown.connect(func(_it: ExamineItem) -> void: _sound.play("pickup"))
	_examine.item_opened.connect(func(_it: ExamineItem) -> void: _sound.play("catch"))
	_examine.item_taken.connect(func(_it: ExamineItem) -> void: _sound.play("paper"))
	_examine.detail_found.connect(_on_detail_found)
	_talk = ArtTalkBox.new()
	add_child(_talk)
	_board = ArtBoard.new()
	add_child(_board)
	_board.closed.connect(func() -> void: _sound.play("board"))
	_board.committed.connect(func(_id: String) -> void: _sound.play("found"))
	_sound = ArtAmbience.new()
	add_child(_sound)


func _layout(native: Vector2i, scale: int, offset: Vector2) -> void:
	_keys.add_theme_font_size_override("font_size", maxi(12, roundi(float(get_window().size.y) / 70.0)))
	_keys.position = offset + Vector2(12, 8)
	_examine.layout(native, scale, offset)
	_talk.layout(native, scale, offset)
	_board.layout(native, scale, offset)


func _process(delta: float) -> void:
	_time += delta
	# The detective stands still while he has something in his hands, is
	# talking, or is at the board.
	var dir: float = 0.0 if busy() else Input.get_axis("move_left", "move_right")
	var was_sprinting: bool = sprinting
	sprinting = (dir != 0.0 and Input.is_action_pressed("sprint")) or _shot_sprint
	if sprinting != was_sprinting:
		# Start the new cycle from its first frame.
		_walk_dist = 0.0
	if dir != 0.0:
		var speed: float = SPRINT_SPEED if sprinting else SPEED
		facing = 1 if dir > 0.0 else -1
		detective_x = clampf(detective_x + dir * speed * delta, 20.0, float(_scene().width - 20))
		_walk_dist += absf(dir) * speed * delta
	else:
		_walk_dist = 0.0
	if not _shooting:
		_voice.advance(delta)
	_update_fade(delta)
	_update_world(dir != 0.0 or _shot_walk >= 0)
	_update_reading(delta)
	_voice.show_line(_view, _head(), busy())
	_update_keys()
	_update_prompt()
	_notices.update_toast(_view, delta, _examine.is_open())
	_notices.status(_view, ("THERMAL   " if Case.optic_on else "") + Case.clock_text(Case.minutes))
	_sound.muffled = busy()
	_sound.indoors = not _scene().outdoors
	_sound.update(delta, detective_x - _scene().lamp_x, _scene().lamp_on)


## True while something is up in front of the market: an item close-up, a
## dialogue box or the case board.
func busy() -> bool:
	return _examine.is_open() or _talk.visible or _board.is_open() or _next_room != ""


func _scene() -> RoomScene:
	return _scenes[room]


# ---------- the case ----------

## E: uses the spot the detective is standing at.
func interact() -> void:
	var s: Spot = _floor.nearest(room, detective_x)
	if s == null:
		return
	var t: Talk = s.use()
	if t != null and not Case.closed:
		_show_talk(t)
	# The chip is the examine tutorial: the voice leads him to turn it over
	# once the body's talk is done (the voice waits while the box is up).
	if s.id == "body" and ArtMarketFloor.chip_unexamined():
		_voice.narration = ""
		say(ArtMarketFloor.CHIP_HINT)


func _show_talk(t: Talk) -> void:
	_sound.play("talk")
	_talk.show_talk(t)


func open_board() -> void:
	_sound.play("board")
	_board.open()


## A door opened. Into a room the art test draws, the screen fades through
## to it; anywhere else, the detective stays where he is and the scene says so
## (after the door's own line).
func _on_travel(to: String, _x: float) -> void:
	if to == room or to == _next_room:
		return
	if ArtMarketFloor.is_drawn(to):
		go_to(to)
		return
	toast.call_deferred(_floor.unbuilt_room_line(to))
	Case.travel.call_deferred(room, detective_x)


## Fades out, changes room, fades back in.
func go_to(to: String) -> void:
	_next_room = to
	_fade_t = 0.0
	_sound.play("catch")


func _update_fade(delta: float) -> void:
	if _next_room != "":
		_fade_t += delta / FADE_TIME
		if _fade_t >= 1.0:
			_enter(_next_room)
			_next_room = ""
			_fade_t = 1.0
	elif _fade_t > 0.0:
		_fade_t = maxf(0.0, _fade_t - delta / FADE_TIME)
	_view.set_fade(_fade_t)


func _enter(to: String) -> void:
	_enter_scene(to)
	detective_x = ArtMarketFloor.ENTRY_X[to]
	facing = 1
	var line: String = Mind.room_line(randf(), randi())
	if line != "":
		say(line)
	elif to == "market" and ArtMarketFloor.chip_unexamined():
		say(ArtMarketFloor.CHIP_REMINDER)


func _enter_scene(to: String) -> void:
	room = to
	for id: String in _scenes:
		_scenes[id].set_shown(id == to)


## A line of the inner voice from the case (a passenger arriving, a dose,
## bleed-through in a new room).
func say(text: String) -> void:
	_voice.say(text)


func toast(text: String) -> void:
	_notices.toast(text)


func _on_detail_found(it: ExamineItem) -> void:
	_sound.play("found")
	if it.clue != "":
		Case.find_clue(it.clue)
	if it.id == "chip":
		_voice.unsay(ArtMarketFloor.CHIP_HINT)
		_voice.unsay(ArtMarketFloor.CHIP_REMINDER)


func _update_prompt() -> void:
	var s: Spot = null if busy() else _floor.nearest(room, detective_x)
	if s == null:
		_notices.prompt(_view, "")
		return
	var py: float = PROMPT_Y_CAMS if s.id == "cams" else (PROMPT_Y_LOW if room == "stall" and s.id != "stall_exit" else PROMPT_Y)
	_notices.prompt(_view, ArtMarketFloor.prompt(s), Vector2(ArtMarketFloor.place(s).x - _cam_x(), py))


func _cam_x() -> float:
	return _scene().cam_x(detective_x)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or busy():
		return
	match key.physical_keycode:
		KEY_E, KEY_ENTER, KEY_KP_ENTER:
			interact()
		KEY_TAB:
			open_board()
		KEY_T:
			toggle_optic()
		KEY_V:
			_voice.mode = ((_voice.mode + 1) % 3) as InnerVoice.Mode
		KEY_F:
			fog = ((fog + 1) % 3) as RoomScene.Fog
		KEY_N:
			_voice.next_thought()
		KEY_H:
			_keys.visible = not _keys.visible
		KEY_X:
			examine()


## X: holds up what's in his pockets. The chip is there once he's taken it
## from her hand (turning it over finds the etching, the "chip" clue); the tag
## once he's found it; the tin and its slip are test items, always there.
func examine() -> void:
	var items: Array[ExamineItem] = []
	if Case.is_set("has_chip") or Case.has_clue("chip"):
		items.append(ExamineItem.chip())
	if Case.has_clue("tag"):
		items.append(ExamineItem.tag())
	items.append(ExamineItem.tin())
	if _examine.taken.get("tin", false):
		items.append(ExamineItem.slip())
	_examine.items = items
	_examine.open(0)


## T: the thermal optic, if he has it.
func toggle_optic() -> void:
	if not Case.has_optic:
		toast("You don't have a thermal optic yet.")
		return
	_sound.play("turn")
	Case.toggle_optic()


func _update_world(walking: bool) -> void:
	var cam: float = _cam_x()
	_scene().update(cam, _time, fog)
	if walking:
		var anim: String = "run" if sprinting else "walk"
		if _shot_walk >= 0:
			_detective.show_frame(anim, _shot_walk)
		else:
			_detective.step_at(anim, _walk_dist, _run_stride if sprinting else _stride)
	else:
		_detective.show_frame("idle", int(_time * 2.0))
	_detective.flip_h = facing < 0
	_detective.place(detective_x, MarketArt.WALK_Y, cam)
	# The thermal optic: the cold picture over everything, and the warm drawn
	# on top of it from each warm sprite's own shape.
	_view.set_thermal(Case.optic_on)
	if Case.optic_on:
		_scene().update_heat()
		_detective_heat.texture = _detective.texture
		_detective_heat.position = _detective.position
		_detective_heat.flip_h = _detective.flip_h


## Just over the detective's head, in view (native pixels).
func _head() -> Vector2:
	return Vector2(detective_x - _cam_x(), MarketArt.WALK_Y - _detective.frame_size.y - 6)


## A reading's white comes in while its words are up: part way for a surface
## reading, nearly to the middle for a deep one.
func _update_reading(delta: float) -> void:
	var target: float = ArtMarketFloor.reading_depth(_talk.talk) if _talk.visible else 0.0
	reading_amount = move_toward(reading_amount, target, delta * (0.8 if target > reading_amount else 1.6))
	if _shooting:
		reading_amount = target
	_view.set_reading(reading_amount, _time)


func _update_keys() -> void:
	_keys.text = "640x360 at x%d  |  voice: %s  |  fog: %s\nA/D move   Shift sprint   E use   Tab case board   T thermal optic   X examine items   V voice   F fog   N next thought   H hide" % [_view.zoom, VOICE_NAMES[_voice.mode], FOG_NAMES[fog]]


# ---------- screenshots ----------

func _shots_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			return arg.trim_prefix("--shots=")
	return ""


func _save(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("%s.png" % name))


func _settle() -> void:
	_time = 1.0
	_market_scene.rain.warm(2.0)
	for i: int in range(4):
		await get_tree().process_frame


func _take_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	_keys.visible = false
	_shooting = true
	_voice.narration = ""
	var plan: Array[Array] = [
		# name, voice, detective x, facing, line, fog[, walk frame, sprinting]
		["640-thought", InnerVoice.Mode.THOUGHT, 300.0, 1, 2, RoomScene.Fog.STEPPED],
		["640-caption", InnerVoice.Mode.CAPTION, 300.0, 1, 0, RoomScene.Fog.STEPPED],
		["640-silent", InnerVoice.Mode.NONE, 760.0, 1, 0, RoomScene.Fog.STEPPED],
		["fog-market-off", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.OFF],
		["fog-market-stepped", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.STEPPED],
		["fog-market-volumetric", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.VOLUMETRIC],
		["fog-fixer-off", InnerVoice.Mode.NONE, 1100.0, -1, 0, RoomScene.Fog.OFF],
		["fog-fixer-stepped", InnerVoice.Mode.NONE, 1100.0, -1, 0, RoomScene.Fog.STEPPED],
		["fog-fixer-volumetric", InnerVoice.Mode.NONE, 1100.0, -1, 0, RoomScene.Fog.VOLUMETRIC],
		["detective-walk", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.STEPPED, 1],
		["detective-sprint", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.STEPPED, 3, true],
		["detective-sprint-left", InnerVoice.Mode.NONE, 640.0, -1, 0, RoomScene.Fog.STEPPED, 0, true],
		["npcs-osk", InnerVoice.Mode.NONE, 440.0, 1, 0, RoomScene.Fog.STEPPED],
		["npcs-fixer", InnerVoice.Mode.NONE, 830.0, 1, 0, RoomScene.Fog.STEPPED],
		["npcs-tech", InnerVoice.Mode.NONE, 1120.0, 1, 0, RoomScene.Fog.STEPPED],
	]
	var only: String = _only_prefix()
	for shot: Array in plan:
		if not String(shot[0]).begins_with(only):
			continue
		_voice.mode = shot[1]
		detective_x = shot[2]
		facing = shot[3]
		_voice.line = shot[4]
		_voice.quiet = false
		fog = shot[5]
		_shot_walk = shot[6] if shot.size() > 6 else -1
		_shot_sprint = shot[7] if shot.size() > 7 else false
		_voice.typed = 9999.0
		await _settle()
		await _save(dir, shot[0])
		var native: Image = _view.native_image()
		native.save_png(dir.path_join("%s-native.png" % shot[0]))
	if "examine".begins_with(only) or only.begins_with("examine"):
		await _take_examine_shots(dir, only)
	if "scene".begins_with(only) or only.begins_with("scene"):
		await _take_scene_shots(dir, only)
	get_tree().quit()


## The playable slice: the opening caption, the stall door, inside the stall
## (plain and thermal), a surface and a deep reading of the body, Vale's
## passenger at the fog's edge afterwards (plain and thermal, where she shows
## no heat and the heat-sealed door shows), talking to Osk, the fixer and the
## tech, and the case board before and after a theory holds.
func _take_scene_shots(dir: String, only: String) -> void:
	fog = RoomScene.Fog.STEPPED
	_shot_walk = -1
	_shot_sprint = false
	var plan: Array[Array] = [
		# name, room, detective x, facing, what happens
		["scene-caption", "market", ArtMarketFloor.START_X, 1, "caption"],
		["scene-prompt-stall", "market", 380.0, 1, ""],
		["scene-stall", "stall", 300.0, 1, ""],
		["scene-stall-thermal", "stall", 300.0, 1, "optic"],
		["scene-reading-surface", "stall", 330.0, 1, "surface"],
		["scene-reading-deep", "stall", 330.0, 1, "deep"],
		["scene-vale-fog", "market", 250.0, 1, "vale"],
		["scene-vale-thermal", "market", 250.0, 1, "vale optic"],
		["scene-prompt-osk", "market", 484.0, 1, ""],
		["scene-talk-osk", "market", 484.0, 1, "talk"],
		["scene-talk-fixer", "market", 876.0, 1, "fixer"],
		["scene-talk-tech", "market", 1160.0, 1, "talk"],
		["scene-board", "market", 880.0, 1, "board"],
		["scene-board-committed", "market", 880.0, 1, "commit"],
	]
	for shot: Array in plan:
		if not String(shot[0]).begins_with(only):
			continue
		Mind.reset()
		ArtMarketFloor.start_case()
		_enter_scene(shot[1])
		if room != "market":
			Case.travel(room, 0.0)
		_next_room = ""
		_fade_t = 0.0
		_talk.hide()
		_board.hide()
		_board.selected.clear()
		_board.theory = ""
		_voice.narration = ""
		_voice.said = ""
		_voice.quiet = true
		_voice.mode = InnerVoice.Mode.NONE
		detective_x = shot[2]
		facing = shot[3]
		var what: String = shot[4]
		if what.contains("vale"):
			Case.read_memory("vale", true)
		if what.contains("optic"):
			Case.toggle_optic()
		match what:
			"caption":
				_voice.mode = InnerVoice.Mode.THOUGHT
				_voice.narrate(OPENING)
				_voice.typed = 9999.0
			"talk":
				interact()
			"fixer":
				Case.find_clue("chip")
				interact()
			"surface", "deep":
				var t: Talk = _floor.market.spot("body").use()
				_show_talk(t.choose("Surface reading" if what == "surface" else "Deep reading"))
			"board", "commit":
				for id: String in ["ledger", "chip", "rival", "fixerfmt"]:
					Case.find_clue(id)
				open_board()
				_board.selected.assign(["ledger", "rival"])
				_board.theory = "stolen"
				_board.refresh()
				if what == "commit":
					_board.commit()
		_talk.finish_typing()
		_notices.clear_toasts()
		await _settle()
		_talk.finish_typing()
		await _save(dir, shot[0])
	_talk.hide()
	_board.hide()
	_enter_scene("market")
	Mind.reset()


## The examine test: the chip as it comes up, turning, turned over with the
## etching found, without palette snap to compare, the flat tag, and the tin:
## shut, its catch found, open, and the slip taken out of it.
func _take_examine_shots(dir: String, only: String) -> void:
	_voice.mode = InnerVoice.Mode.NONE
	detective_x = 300.0
	facing = 1
	fog = RoomScene.Fog.STEPPED
	_shot_walk = -1
	_shot_sprint = false
	_examine.still = true
	var plan: Array[Array] = [
		# name, item, turn (euler), zoom, palette snap
		["examine-chip", 0, ExamineView.REST, ExamineView.ZOOM_START, true],
		["examine-chip-turning", 0, Vector3(-0.35, 1.9, 0.15), ExamineView.ZOOM_START, true],
		["examine-chip-etching", 0, Vector3(0.12, PI - 0.2, 0.05), 2.5, true],
		["examine-chip-no-snap", 0, Vector3(-0.35, 1.9, 0.15), ExamineView.ZOOM_START, false],
		["examine-tag", 1, Vector3(-0.25, -0.35, -0.08), 1.75, true],
		["examine-tag-back", 1, Vector3(0.2, PI + 0.45, 0.1), 1.75, true],
		["examine-tin", 2, ExamineView.REST, ExamineView.ZOOM_START, true],
		["examine-tin-catch", 2, Vector3(0.1, -1.42, 0.05), 2.5, true],
		["examine-tin-open", 2, Vector3(-0.22, 0.3, 0.0), ExamineView.ZOOM_START, true, "open"],
		["examine-slip", 2, Vector3(-0.15, 0.2, -0.05), 2.0, true, "taken"],
	]
	for shot: Array in plan:
		if not String(shot[0]).begins_with(only):
			continue
		_examine.items = ExamineItem.all()
		_examine.found.clear()
		_examine.opened.clear()
		_examine.taken.clear()
		_examine.open(shot[1])
		var state: String = shot[5] if shot.size() > 5 else ""
		if state != "":
			_examine.found[_examine.current().id] = true
			_examine.use()
			if state == "taken":
				_examine.use()
			_examine.open()
		_examine.set_turn(Basis.from_euler(shot[2]))
		_examine.zoom = shot[3]
		_examine.snap = shot[4]
		_examine.check_found(1.0)
		_examine.check_found(1.0)
		await _settle()
		await _save(dir, shot[0])
	_examine.close()
	_examine.still = false


func _only_prefix() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			return arg.trim_prefix("--only=")
	return ""
