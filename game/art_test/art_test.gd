class_name ArtTest
extends World
## The Drowned Market style test (milestone M3 in Gameplay and Production),
## now the sandbox for trying mechanics before they go in the game. It's the
## game itself (World), started on the market floor at the top of the case
## with the thermal optic already calibrated, plus what's only for trying
## things out:
##
## - G switches the fog: stepped pixel fog (the game's), volumetric fog drawn
##   at the window's own resolution behind the crisp pixel-art playable layer,
##   or none.
## - V switches how the inner voice shows: thought text by the detective (the
##   game's), a caption box, or silence. N brings up the next of its idle
##   thoughts.
## - X also holds test items: a pocket tin with a catch, and the slip inside.
## - H hides the key list.
##
## It opens on a caption, and walks onto the market floor; everything else
## (rooms, people, readings, the board, sound) is the game's.
##
## Screenshots: run with `-- --shots=<dir>` and it saves a fixed set and quits;
## `--only=<prefix>` saves only those whose names start with it.

const VOICE_NAMES: Array[String] = ["thought text by the detective", "caption box", "silence"]
const FOG_NAMES: Array[String] = ["stepped pixel fog", "volumetric fog behind pixel art", "no fog"]
## Where the detective starts: the west end of the market, walking in.
const START_X: float = 60.0
## Placeholder, not canon: he walks onto the market floor at the start of the
## case already carrying a calibrated thermal optic, so the optic can be tried
## without the trip to the precinct lab where Sato calibrates it.
const START_WITH_OPTIC: bool = true

## Placeholder lines for the test. They lean on what the docs settle (Vale, the
## market, the badge), but they're not canon dialogue.
const THOUGHTS: Array[String] = [
	"Ines Vale sold other people's memories for a living. Somebody took the last one she had.",
	"The rain never stops down here. It just finds new ways in.",
	"Tape, a badge reader, a stall sealed with her inside. My badge still opens doors. For now.",
]

var _keys: Label


## Starts the case at the sandbox's starting point (see START_WITH_OPTIC).
static func start_case() -> void:
	Case.reset()
	if START_WITH_OPTIC:
		Case.grant_optic()
	Case.travel("market", 0.0)


func _build() -> void:
	super._build()
	_keys = Label.new()
	_keys.add_theme_color_override("font_color", Color(P.RAIN, 0.8))
	add_child(_keys)
	move_child(_keys, _notices.get_index() + 1)


func _begin() -> void:
	_voice.thoughts.assign(THOUGHTS)
	start_case()
	_seen_market = true
	_voice.narrate(DrownedMarket.MARKET_OPENING)
	arrive("market", START_X)
	_notices.clear_toasts()


func _layout(native: Vector2i, zoom: int, offset: Vector2) -> void:
	super._layout(native, zoom, offset)
	_keys.add_theme_font_size_override("font_size", maxi(12, roundi(float(get_window().size.y) / 70.0)))
	_keys.position = offset + Vector2(12, 26)


func _process(delta: float) -> void:
	super._process(delta)
	_keys.text = "640x360 at x%d  |  voice: %s  |  fog: %s\nA/D move   Shift dash   W/Space jump   F stun pistol   E use   Tab board   T thermal   X examine   V voice   G fog   N next thought   H hide" % [_view.zoom, VOICE_NAMES[_voice.mode], FOG_NAMES[fog]]


func _sandbox_key(key: InputEventKey) -> bool:
	match key.physical_keycode:
		KEY_V:
			_voice.mode = ((_voice.mode + 1) % 3) as InnerVoice.Mode
		KEY_G:
			fog = ((fog + 1) % 3) as RoomScene.Fog
		KEY_N:
			_voice.next_thought()
		KEY_H:
			_keys.visible = not _keys.visible
		_:
			return false
	return true


func _pockets() -> Array[ExamineItem]:
	var items: Array[ExamineItem] = super._pockets()
	items.append(ExamineItem.tin())
	if _examine.taken.get("tin", false):
		items.append(ExamineItem.slip())
	return items


# ---------- screenshots ----------

func _ready() -> void:
	super._ready()
	var shots: String = _arg("--shots=")
	if shots != "":
		_take_shots.call_deferred(shots)


func _arg(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


func _save(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("%s.png" % name))


## Holds the detective at `x`, facing `face`, in `frame` of `anim` (or
## standing), and lets the picture settle.
func _hold(x: float, face: int, anim: String = "", frame: int = 0) -> void:
	detective.position = Vector2(x, RoomLayout.WALK_Y)
	detective.velocity = Vector2.ZERO
	detective.facing = face
	detective.set_physics_process(false)
	_time = 1.0
	(_scenes["market"] as MarketScene).rain.warm(2.0)
	for i: int in range(4):
		await get_tree().process_frame
		detective.sprite.show_frame(anim if anim != "" else "idle", frame)
		detective.sprite.flip_h = face < 0
	detective.set_physics_process(true)


## Stops him partway through a dash, his afterimages trailing behind.
func _mid_dash() -> void:
	detective._start_dash(float(detective.facing))
	for i: int in range(6):
		await get_tree().physics_frame
	detective.set_physics_process(false)
	await get_tree().process_frame
	detective.set_physics_process(true)


func _take_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	_keys.visible = false
	_voice.still = true
	_voice.narration = ""
	_notices.clear_toasts()
	var plan: Array[Array] = [
		# name, voice, detective x, facing, line, fog[, anim, frame]
		["640-thought", InnerVoice.Mode.THOUGHT, 300.0, 1, 2, RoomScene.Fog.STEPPED],
		["640-caption", InnerVoice.Mode.CAPTION, 300.0, 1, 0, RoomScene.Fog.STEPPED],
		["640-silent", InnerVoice.Mode.NONE, 760.0, 1, 0, RoomScene.Fog.STEPPED],
		["fog-market-off", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.OFF],
		["fog-market-stepped", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.STEPPED],
		["fog-market-volumetric", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.VOLUMETRIC],
		["fog-fixer-off", InnerVoice.Mode.NONE, 1100.0, -1, 0, RoomScene.Fog.OFF],
		["fog-fixer-stepped", InnerVoice.Mode.NONE, 1100.0, -1, 0, RoomScene.Fog.STEPPED],
		["fog-fixer-volumetric", InnerVoice.Mode.NONE, 1100.0, -1, 0, RoomScene.Fog.VOLUMETRIC],
		["detective-walk", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.STEPPED, "walk", 1],
		["detective-run", InnerVoice.Mode.NONE, 300.0, 1, 0, RoomScene.Fog.STEPPED, "run", 3],
		["detective-run-left", InnerVoice.Mode.NONE, 640.0, -1, 0, RoomScene.Fog.STEPPED, "run", 0],
		["detective-dash", InnerVoice.Mode.NONE, 260.0, 1, 0, RoomScene.Fog.STEPPED],
		["npcs-osk", InnerVoice.Mode.NONE, 440.0, 1, 0, RoomScene.Fog.STEPPED],
		["npcs-fixer", InnerVoice.Mode.NONE, 830.0, 1, 0, RoomScene.Fog.STEPPED],
		["npcs-tech", InnerVoice.Mode.NONE, 1120.0, 1, 0, RoomScene.Fog.STEPPED],
	]
	var only: String = _arg("--only=")
	for shot: Array in plan:
		if not String(shot[0]).begins_with(only):
			continue
		_voice.mode = shot[1]
		_voice.line = shot[4]
		_voice.quiet = false
		_voice.said = ""
		fog = shot[5]
		_voice.typed = 9999.0
		await _hold(shot[2], shot[3], shot[6] if shot.size() > 6 else "", shot[7] if shot.size() > 7 else 0)
		if shot[0] == "detective-dash":
			await _mid_dash()
		await _save(dir, shot[0])
		_view.native_image().save_png(dir.path_join("%s-native.png" % shot[0]))
	if "examine".begins_with(only) or only.begins_with("examine"):
		await _take_examine_shots(dir, only)
	if "scene".begins_with(only) or only.begins_with("scene"):
		await _take_scene_shots(dir, only)
	if "rooms".begins_with(only) or only.begins_with("rooms"):
		await _take_room_shots(dir, only)
	get_tree().quit()


## The playable slice: the opening caption, the stall door, inside the stall
## (plain and thermal), a surface and a deep reading of the body, Vale's
## passenger at the fog's edge afterwards (plain and thermal, where she shows
## no heat and the heat-sealed door shows), talking to Osk, the fixer and the
## tech, and the case board before and after a theory holds.
func _take_scene_shots(dir: String, only: String) -> void:
	fog = RoomScene.Fog.STEPPED
	var plan: Array[Array] = [
		# name, room, detective x, facing, what happens
		["scene-caption", "market", START_X, 1, "caption"],
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
		start_case()
		_reset_scene(shot[1], shot[2])
		var what: String = shot[4]
		if what.contains("vale"):
			Case.read_memory("vale", true)
		if what.contains("optic"):
			Case.toggle_optic()
		match what:
			"caption":
				_voice.mode = InnerVoice.Mode.THOUGHT
				_voice.narrate(DrownedMarket.MARKET_OPENING)
				_voice.typed = 9999.0
			"talk":
				interact()
			"fixer":
				Case.find_clue("chip")
				interact()
			"surface", "deep":
				var t: Talk = market.spot("body").use()
				_show_talk(t.choose("Surface reading" if what == "surface" else "Deep reading"))
			"board", "commit":
				for id: String in ["ledger", "chip", "rival", "fixerfmt"]:
					Case.find_clue(id)
				_board.open()
				_board.selected.assign(["ledger", "rival"])
				_board.theory = "stolen"
				_board.refresh()
				if what == "commit":
					_board.commit()
		_talk.finish_typing()
		_notices.clear_toasts()
		await _hold(shot[2], shot[3])
		_talk.finish_typing()
		reading_amount = RoomLayout.reading_depth(_talk.talk) if _talk.visible else 0.0
		_view.set_reading(reading_amount, _time)
		await _save(dir, shot[0])
	_talk.hide()
	_board.hide()
	Mind.reset()


## Puts the detective in `id` at native `x` with nothing up.
func _reset_scene(id: String, x: float) -> void:
	arrive(id, x)
	_talk.hide()
	_board.hide()
	_board.selected.clear()
	_board.theory = ""
	_voice.narration = ""
	_voice.said = ""
	_voice.quiet = true
	_voice.mode = InnerVoice.Mode.NONE


## Every stand-in room, to check how they read next to the drawn ones.
func _take_room_shots(dir: String, only: String) -> void:
	fog = RoomScene.Fog.STEPPED
	for id: String in market.rooms:
		if RoomLayout.is_drawn(id) or not ("rooms-" + id).begins_with(only):
			continue
		Mind.reset()
		start_case()
		Case.spawn_hostiles(id, 3)
		_reset_scene(id, 160.0)
		_notices.clear_toasts()
		await _hold(160.0, 1)
		await _save(dir, "rooms-" + id)


## The examine test: the chip as it comes up, turning, turned over with the
## etching found, without palette snap to compare, the flat tag, and the tin:
## shut, its catch found, open, and the slip taken out of it.
func _take_examine_shots(dir: String, only: String) -> void:
	_voice.mode = InnerVoice.Mode.NONE
	fog = RoomScene.Fog.STEPPED
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
		await _hold(300.0, 1)
		await _save(dir, shot[0])
	_examine.close()
	_examine.still = false
