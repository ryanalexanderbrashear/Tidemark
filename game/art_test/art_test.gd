class_name ArtTest
extends Node
## The Drowned Market style test (milestone M3 in Gameplay and Production): one
## stretch of the market floor drawn at target resolution, to settle the Look and
## Feel doc's open questions on game resolution, character size and how the
## detective's inner voice is shown. It doesn't touch the case.
##
## It also tries the fog, water and neon motif (Look and Feel doc, "Fog, water
## and neon"): neon signs behind thick fog, drawn two ways to compare. Stepped
## fog is pixel art like everything else; volumetric fog is drawn at the
## window's own resolution behind the crisp pixel-art playable layer.
##
## The detective starts as the tall, rim-lit draft of the "rain-worn tracer"
## (ArtDetectiveTall, toward Replaced's look), and Osk and the fixer are drawn to
## his scale. C cycles to the 64 px pass (ArtDetective) and to the first
## proof-of-concept sprite, to compare.
##
## X opens the examine test (ExamineView): the items in the detective's pockets,
## held up close and turned over by hand to find what's on their other side.
##
## It's also a playable slice of the case (ArtMarketFloor): the people and
## objects on the market floor are the case's own, so E talks to them in a
## styled box (ArtTalkBox), clues land in `Case`, Tab opens the case board
## (ArtBoard), and the chip's etching, found by turning it over, is a clue.
## Placeholder sound (ArtAmbience) plays under it, muffled while the detective
## is talking, at the board or holding something up.
##
## Keys: A/D move, E use, Tab case board, X examine items, R switches
## resolution, V switches the inner voice, F switches the fog, C switches the
## detective, N shows the next thought, H hides the key list.
## Screenshots: run with `-- --shots=<dir>` and it saves a fixed set and quits.

enum Voice { THOUGHT, CAPTION, NONE }
enum Fog { STEPPED, VOLUMETRIC, OFF }

const P = preload("res://game/art_test/art_palette.gd")
const WATER_SHADER = preload("res://game/art_test/water.gdshader")
const VOLUMETRIC_SHADER = preload("res://game/art_test/volumetric.gdshader")
const MAX_LIGHTS: int = 24

## The two resolutions on test: [size, camera top]. 640x360 scales by whole
## numbers to 720p, 1080p, 1440p and 4K; 480x270 only to 1080p and 4K.
const RESOLUTIONS: Array[Array] = [[Vector2i(640, 360), 0], [Vector2i(480, 270), 56]]
const VOICE_NAMES: Array[String] = ["thought text by the detective", "caption box", "silence"]
const FOG_NAMES: Array[String] = ["stepped pixel fog", "volumetric fog behind pixel art", "no fog"]
## Walking pace: about 1.5 walk cycles a second with ArtDetective's stride.
const SPEED: float = 54.0
const OSK_X: float = ArtMarketFloor.OSK_X
const FIXER_X: float = ArtMarketFloor.FIXER_X
const TECH_X: float = ArtMarketFloor.TECH_X
## Where prompts sit over a spot (native y): above everyone's heads, or under
## the camera on its pole.
const PROMPT_Y: float = 178.0
const PROMPT_Y_CAMS: float = 96.0
## Seconds a toast stays up.
const TOAST_TIME: float = 2.8

## Placeholder lines for the test. They lean on what the docs settle (Vale, the
## market, the badge), but they're not canon dialogue.
const THOUGHTS: Array[String] = [
	"Ines Vale sold other people's memories for a living. Somebody took the last one she had.",
	"The rain never stops down here. It just finds new ways in.",
	"Tape, a badge reader, a stall sealed with her inside. My badge still opens doors. For now.",
]

var res_index: int = 0
var voice: Voice = Voice.THOUGHT
var fog: Fog = Fog.STEPPED
var detective_x: float = ArtMarketFloor.START_X
enum Look { CLOSER, TALL, SKETCH }
const LOOK_NAMES: Array[String] = ["closer to final", "tall rim-lit draft", "first sketch"]
## The tall draft by default: Osk and the fixer are drawn to its scale.
var look: Look = Look.TALL
var facing: int = 1

## Two viewports at native resolution: the background (sky to shanties, with
## the fog between) and the playable layer in front of it (market, people,
## water, rain), which is see-through where the market has gaps.
var _back: SubViewport
var _view: SubViewport
var _back_screen: TextureRect
var _screen: TextureRect
var _layers: Dictionary[String, Sprite2D] = {}
var _wisps: Dictionary[String, Sprite2D] = {}
var _detective: Sprite2D
var _osk: Sprite2D
var _fixer: Sprite2D
var _tech: Sprite2D
var _holo: Sprite2D
var _lamp: Sprite2D
var _water: ColorRect
var _rain: ArtRain
var _det_frames: Array[ImageTexture] = []
var _det_walk: Array[ImageTexture] = []
var _det_idle: Array[ImageTexture] = []
var _tall_walk: Array[ImageTexture] = []
var _tall_idle: Array[ImageTexture] = []
var _osk_frames: Array[ImageTexture] = []
var _fixer_frames: Array[ImageTexture] = []
var _tech_frames: Array[ImageTexture] = []
var _holo_frames: Array[ImageTexture] = []
var _thought: Label
var _caption: PanelContainer
var _caption_label: Label
var _keys: Label
var _examine: ExamineView
var _talk: ArtTalkBox
var _board: ArtBoard
var _sound: ArtAmbience
var _floor: ArtMarketFloor
var _prompt: Label
var _toast: Label
var _toasts: Array[String] = []
var _toast_time: float = 0.0
var _line: int = 0
## After the opening thoughts have each played once, the voice goes quiet
## until N asks for another.
var _quiet: bool = false
var _thoughts_shown: int = 1
var _typed: float = 0.0
var _time: float = 0.0
var _walk_time: float = 0.0
## Distance walked, so ArtDetective's walk frames keep the planted foot still.
var _walk_dist: float = 0.0
## Screenshots only: shows this walk frame instead of standing (-1: off).
var _shot_walk: int = -1
var _scale: int = 1
var _shooting: bool = false
var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	# The case starts before the scene listens, so its starting clues don't toast.
	ArtMarketFloor.start_case()
	_floor = ArtMarketFloor.new()
	_build()
	Case.notice.connect(toast)
	Case.travel_requested.connect(_on_travel)
	Case.announcement.connect(func(who: String, text: String, at: String) -> void:
		_show_talk.call_deferred(Talk.say(who, at + ".  " + text)))
	# Only listen for resizes once the screen exists: building the art takes a
	# few seconds, and a resize in that time used to call _layout on nothing.
	get_window().size_changed.connect(_layout)
	_apply_resolution()
	var shots: String = _shots_dir()
	if shots != "":
		_take_shots.call_deferred(shots)


func _exit_tree() -> void:
	_floor.release()


func _build() -> void:
	var back: ColorRect = ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)

	_back = _viewport(false)
	_view = _viewport(true)

	_layers["sky"] = _sprite(MarketArt.sky(), _back)
	_layers["city"] = _sprite(MarketArt.city(), _back)
	_fog_band("fog_far")
	_layers["signs"] = _sprite(FogArt.signs(), _back)
	_fog_band("fog_signs")
	_layers["arcology"] = _sprite(MarketArt.arcology(), _back)
	_fog_band("fog_mid")
	_layers["shanties"] = _sprite(MarketArt.shanties(), _back)
	_fog_band("fog_low")
	for f: int in range(8):
		_holo_frames.append(ImageTexture.create_from_image(MarketArt.hologram(f)))
	_holo = Sprite2D.new()
	_holo.centered = false
	_holo.material = _additive()
	_back.add_child(_holo)
	_layers["market"] = _sprite(MarketArt.market())

	_lamp = _sprite(_lamp_image())
	_lamp.material = _additive()

	for f: int in range(ArtCharacters.WALK_FRAMES):
		_det_frames.append(ImageTexture.create_from_image(ArtCharacters.detective(f, true)))
	for f: int in range(2):
		_det_frames.append(ImageTexture.create_from_image(ArtCharacters.detective(f, false)))
		_osk_frames.append(ImageTexture.create_from_image(ArtCharacters.osk(f)))
		_fixer_frames.append(ImageTexture.create_from_image(ArtCharacters.fixer(f)))
		_tech_frames.append(ImageTexture.create_from_image(ArtCharacters.tech(f)))
	for f: int in range(ArtDetective.WALK_FRAMES):
		_det_walk.append(ImageTexture.create_from_image(ArtDetective.walk(f)))
	for f: int in range(ArtDetective.IDLE_FRAMES):
		_det_idle.append(ImageTexture.create_from_image(ArtDetective.idle(f)))
	for f: int in range(ArtDetectiveTall.WALK_FRAMES):
		_tall_walk.append(ImageTexture.create_from_image(ArtDetectiveTall.walk(f)))
	for f: int in range(ArtDetectiveTall.IDLE_FRAMES):
		_tall_idle.append(ImageTexture.create_from_image(ArtDetectiveTall.idle(f)))
	_osk = _sprite(_osk_frames[0].get_image())
	_fixer = _sprite(_fixer_frames[0].get_image())
	_tech = _sprite(_tech_frames[0].get_image())
	_detective = _sprite(_det_frames[0].get_image())

	_water = ColorRect.new()
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("back_tex", _back.get_texture())
	_water.material = mat
	_view.add_child(_water)

	_layers["front"] = _sprite(MarketArt.front())

	var rain_layer: CanvasLayer = CanvasLayer.new()
	_view.add_child(rain_layer)
	_rain = ArtRain.new()
	rain_layer.add_child(_rain)

	_back_screen = TextureRect.new()
	_back_screen.texture = _back.get_texture()
	_back_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_back_screen.stretch_mode = TextureRect.STRETCH_SCALE
	var vol: ShaderMaterial = ShaderMaterial.new()
	vol.shader = VOLUMETRIC_SHADER
	vol.set_shader_parameter("back_soft", _back.get_texture())
	vol.set_shader_parameter("fog_color", FogArt.FOG_TINT)
	_back_screen.material = vol
	add_child(_back_screen)

	_screen = TextureRect.new()
	_screen.texture = _view.get_texture()
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_screen)

	_thought = Label.new()
	_thought.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thought.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thought.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_thought.add_theme_color_override("font_color", Color("d4dce6"))
	_thought.add_theme_color_override("font_outline_color", Color(P.INK, 0.9))
	add_child(_thought)

	_caption = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(P.NAVY, 0.9)
	box.border_color = P.AMBER_DIM
	box.border_width_left = 4
	add_child(_caption)
	_caption.add_theme_stylebox_override("panel", box)
	_caption_label = Label.new()
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.add_theme_color_override("font_color", Color("d4dce6"))
	_caption.add_child(_caption_label)

	_keys = Label.new()
	_keys.add_theme_color_override("font_color", Color(P.RAIN, 0.8))
	add_child(_keys)

	_prompt = _outlined(Color("d4dce6"))
	add_child(_prompt)
	_toast = _outlined(P.AMBER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_toast)

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


func _outlined(c: Color) -> Label:
	var l: Label = Label.new()
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(P.INK, 0.9))
	l.visible = false
	return l


func _viewport(see_through: bool) -> SubViewport:
	var v: SubViewport = SubViewport.new()
	v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	v.snap_2d_transforms_to_pixel = true
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	v.transparent_bg = see_through
	add_child(v)
	return v


func _sprite(img: Image, into: SubViewport = null) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.centered = false
	s.texture = ImageTexture.create_from_image(img)
	(into if into != null else _view).add_child(s)
	return s


## A stepped fog band and the wisps that drift across it.
func _fog_band(band: String) -> void:
	_layers[band] = _sprite(FogArt.band(band), _back)
	var w: Sprite2D = _sprite(FogArt.wisps(band), _back)
	w.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	w.region_enabled = true
	_wisps[band] = w


func _additive() -> CanvasItemMaterial:
	var m: CanvasItemMaterial = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


## The lamp over Vale's stall, on its own so it can stutter.
func _lamp_image() -> Image:
	var img: Image = Px.blank(MarketArt.STALL_W + 40, 90)
	Px.glow(img, img.get_width() * 0.5, 22, MarketArt.STALL_W * 0.45, 40, P.AMBER, 0.18)
	Px.rect(img, img.get_width() / 2 - 4, 2, 8, 2, P.AMBER)
	return img


func _apply_resolution() -> void:
	var size: Vector2i = RESOLUTIONS[res_index][0]
	_back.size = size
	_view.size = size
	var vol: ShaderMaterial = _back_screen.material as ShaderMaterial
	vol.set_shader_parameter("view_size", Vector2(size))
	_water.size = Vector2(size.x, size.y)
	var mat: ShaderMaterial = _water.material as ShaderMaterial
	mat.set_shader_parameter("view_size", Vector2(size))
	_rain.view_size = size
	_rain.reset()
	_layout()


func _layout() -> void:
	if _keys == null:
		return
	var win: Vector2i = get_window().size
	var size: Vector2i = _view.size
	_scale = maxi(1, mini(win.x / size.x, win.y / size.y))
	var shown: Vector2 = Vector2(size * _scale)
	_offset = ((Vector2(win) - shown) * 0.5).floor()
	_screen.position = _offset
	_screen.size = shown
	_back_screen.position = _offset
	_back_screen.size = shown
	var font_px: int = roundi(float(win.y) / 46.0)
	_thought.add_theme_font_size_override("font_size", font_px)
	_thought.add_theme_constant_override("outline_size", maxi(2, font_px / 5))
	_caption_label.add_theme_font_size_override("font_size", font_px)
	var box: StyleBoxFlat = _caption.get_theme_stylebox("panel") as StyleBoxFlat
	box.set_content_margin_all(font_px * 0.8)
	box.content_margin_left = font_px * 1.2
	_keys.add_theme_font_size_override("font_size", maxi(12, roundi(float(win.y) / 70.0)))
	_keys.position = _offset + Vector2(12, 8)
	_examine.layout(size, _scale, _offset)
	_talk.layout(size, _scale, _offset)
	_board.layout(size, _scale, _offset)
	for l: Label in [_prompt, _toast]:
		l.add_theme_font_size_override("font_size", roundi(font_px * 0.85))
		l.add_theme_constant_override("outline_size", maxi(2, font_px / 5))


func _process(delta: float) -> void:
	_time += delta
	# The detective stands still while he has something in his hands, is
	# talking, or is at the board.
	var dir: float = 0.0 if busy() else Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		detective_x = clampf(detective_x + dir * SPEED * delta, 20.0, float(MarketArt.ROOM.x - 20))
		_walk_time += delta
		_walk_dist += SPEED * delta
	else:
		_walk_time = 0.0
		_walk_dist = 0.0
	if not _shooting:
		_typed += delta * 38.0
	if _typed > THOUGHTS[_line].length() + 140.0 and not _shooting and not _quiet:
		if _thoughts_shown < THOUGHTS.size():
			_next_line()
		else:
			_quiet = true
	_update_world(dir != 0.0 or _shot_walk >= 0)
	_update_voice()
	_update_prompt()
	_update_toast(delta)
	_sound.muffled = busy()
	_sound.update(delta, detective_x - (MarketArt.STALL_X + MarketArt.STALL_W * 0.5), _lamp.visible)


## True while something is up in front of the market: an item close-up, a
## dialogue box or the case board.
func busy() -> bool:
	return _examine.is_open() or _talk.visible or _board.is_open()


# ---------- the case ----------

## E: uses the spot the detective is standing at.
func interact() -> void:
	var s: Spot = _floor.nearest(detective_x)
	if s == null:
		return
	var t: Talk = s.use()
	if t != null and not Case.closed:
		_show_talk(t)


func _show_talk(t: Talk) -> void:
	_sound.play("talk")
	_talk.show_talk(t)


func open_board() -> void:
	_sound.play("board")
	_board.open()


## A door led out of the market: the art test has no other room yet, so the
## detective stays here and the scene says so (after the door's own line).
func _on_travel(room: String, _x: float) -> void:
	if room == "market":
		return
	toast.call_deferred(_floor.unbuilt_room_line(room))
	Case.travel.call_deferred("market", detective_x)


func _on_detail_found(it: ExamineItem) -> void:
	_sound.play("found")
	if it.clue != "":
		Case.find_clue(it.clue)


func toast(text: String) -> void:
	_toasts.append(text)
	if _toasts.size() == 1:
		_toast_time = TOAST_TIME


func _update_toast(delta: float) -> void:
	if _toasts.is_empty():
		_toast.visible = false
		return
	_toast_time -= delta
	if _toast_time <= 0.0:
		_toasts.pop_front()
		_toast_time = TOAST_TIME
		if _toasts.is_empty():
			_toast.visible = false
			return
	_toast.visible = not _examine.is_open() or _toasts[0].begins_with("New clue")
	_toast.text = _toasts[0]
	var width: float = minf(_screen.size.x * 0.7, 1200.0)
	_toast.size = Vector2(width, 0)
	_toast.position = _offset + Vector2((_screen.size.x - width) * 0.5, _screen.size.y * 0.05)


func _update_prompt() -> void:
	var s: Spot = null if busy() else _floor.nearest(detective_x)
	_prompt.visible = s != null
	if s == null:
		return
	_prompt.text = ArtMarketFloor.prompt(s)
	_prompt.reset_size()
	var cam_top: int = RESOLUTIONS[res_index][1]
	var at: Vector2 = Vector2(ArtMarketFloor.place(s).x - _cam_x(), (PROMPT_Y_CAMS if s.id == "cams" else PROMPT_Y) - cam_top)
	var w: float = _prompt.size.x
	_prompt.position = _offset + at * float(_scale) - Vector2(w * 0.5, _prompt.size.y)
	_prompt.position.x = clampf(_prompt.position.x, _offset.x + 8.0, _offset.x + _screen.size.x - w - 8.0)


func _cam_x() -> float:
	return floorf(clampf(detective_x - _view.size.x * 0.5, 0.0, float(MarketArt.ROOM.x - _view.size.x)))


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or busy():
		return
	match key.physical_keycode:
		KEY_E, KEY_ENTER, KEY_KP_ENTER:
			interact()
		KEY_TAB:
			open_board()
		KEY_R:
			res_index = (res_index + 1) % RESOLUTIONS.size()
			_apply_resolution()
		KEY_V:
			voice = ((voice + 1) % 3) as Voice
		KEY_F:
			fog = ((fog + 1) % 3) as Fog
		KEY_C:
			look = ((look + 1) % 3) as Look
		KEY_N:
			_quiet = false
			_next_line()
		KEY_H:
			_keys.visible = not _keys.visible
		KEY_X:
			_examine.open()


func _next_line() -> void:
	_line = (_line + 1) % THOUGHTS.size()
	_thoughts_shown += 1
	_typed = 0.0


func _update_world(walking: bool) -> void:
	var size: Vector2i = _view.size
	var cam_top: int = RESOLUTIONS[res_index][1]
	var cam_x: float = clampf(detective_x - size.x * 0.5, 0.0, float(MarketArt.ROOM.x - size.x))
	cam_x = floorf(cam_x)
	var max_scroll: float = float(MarketArt.ROOM.x - MarketArt.VIEW.x)
	for layer: String in _layers:
		var factor: float = MarketArt.PARALLAX[layer]
		# Back layers are drawn for the 640-wide view; keep them centred on it.
		var lx: float = -floorf(cam_x * factor) if layer == "market" else -floorf(cam_x / max_scroll * max_scroll * factor)
		if layer == "sky":
			lx = 0.0
		_layers[layer].position = Vector2(lx, -cam_top)
	var market_x: float = -cam_x
	_lamp.position = Vector2(market_x + MarketArt.STALL_X - 20, MarketArt.WALK_Y - 128 + 6 - cam_top)
	# A failing tube: mostly on, sometimes off for a beat.
	var flick: float = sin(_time * 23.0) + sin(_time * 7.3)
	_lamp.visible = flick > -1.4
	_holo.texture = _holo_frames[int(_time * 8.0) % _holo_frames.size()]
	_holo.position = Vector2(market_x + 602, 58 - cam_top)
	_holo.modulate.a = 0.85 if fmod(_time, 3.7) > 0.12 else 0.3
	_update_fog(cam_top)

	var breath: int = int(_time * 1.6) % 2
	if look != Look.SKETCH:
		var tall: bool = look == Look.TALL
		var walks: Array[ImageTexture] = _tall_walk if tall else _det_walk
		var idles: Array[ImageTexture] = _tall_idle if tall else _det_idle
		var stride: float = ArtDetectiveTall.STRIDE if tall else ArtDetective.STRIDE
		var walk_frame: int = int(_walk_dist / (stride / float(walks.size()))) % walks.size()
		if _shot_walk >= 0:
			walk_frame = _shot_walk
		_detective.texture = walks[walk_frame] if walking else idles[int(_time * 2.0) % idles.size()]
	else:
		var walk_frame: int = int(_walk_time * 10.0) % ArtCharacters.WALK_FRAMES
		_detective.texture = _det_frames[walk_frame] if walking else _det_frames[ArtCharacters.WALK_FRAMES + breath]
	_detective.flip_h = facing < 0
	_place(_detective, detective_x, _detective_size(), market_x, cam_top)
	_osk.texture = _osk_frames[breath]
	_place(_osk, OSK_X, ArtCharacters.OSK_SIZE, market_x, cam_top)
	_fixer.texture = _fixer_frames[(breath + 1) % 2]
	_fixer.flip_h = true
	_place(_fixer, FIXER_X, ArtCharacters.FIXER_SIZE, market_x, cam_top)
	# The tech works the wrench a notch at a time.
	_tech.texture = _tech_frames[int(_time * 1.1) % 2]
	_place(_tech, TECH_X, ArtCharacters.TECH_SIZE, market_x, cam_top)

	_water.position = Vector2(0, MarketArt.WATER_Y - cam_top)
	(_water.material as ShaderMaterial).set_shader_parameter("line_y", float(MarketArt.WATER_Y - cam_top))
	_rain.walk_y = MarketArt.WALK_Y - cam_top
	_rain.water_y = MarketArt.WATER_Y - cam_top


func _update_fog(cam_top: int) -> void:
	var stepped: bool = fog == Fog.STEPPED
	for band: String in FogArt.BANDS:
		_layers[band].visible = stepped
		var w: Sprite2D = _wisps[band]
		w.visible = stepped
		w.position = _layers[band].position
		var drift: float = floorf(_time * FogArt.DRIFT[band])
		w.region_rect = Rect2(-drift, 0, MarketArt.layer_width(band), MarketArt.VIEW.y)
	var vol: ShaderMaterial = _back_screen.material as ShaderMaterial
	vol.set_shader_parameter("volumetric", fog == Fog.VOLUMETRIC)
	vol.set_shader_parameter("water_y", float(MarketArt.WATER_Y - cam_top))
	if fog != Fog.VOLUMETRIC:
		return
	# The same lights the stepped fog is tinted by, moved to the screen.
	var pos: PackedVector4Array = []
	var col: PackedVector4Array = []
	var view_w: float = float(_view.size.x)
	var signs_at: Vector2 = _layers["signs"].position
	for s: Array in FogArt.SIGNS:
		var l: Vector3 = FogArt.sign_light(s)
		var c: Color = FogArt.sign_color(s[3])
		var at: Vector2 = signs_at + Vector2(l.x, l.y)
		if at.x > -80.0 and at.x < view_w + 80.0:
			pos.append(Vector4(at.x, at.y, l.z * 1.3, 0.32))
			col.append(Vector4(c.r, c.g, c.b, 1.0))
	var arc_at: Vector2 = _layers["arcology"].position
	for g: Array in FogArt.lights("fog_mid"):
		var at: Vector2 = arc_at + Vector2(g[0], g[1])
		if at.x > -60.0 and at.x < view_w + 60.0 and pos.size() < MAX_LIGHTS:
			var c: Color = g[3]
			pos.append(Vector4(at.x, at.y, 150.0, 0.09))
			col.append(Vector4(c.r, c.g, c.b, 2.0))
	if pos.size() < MAX_LIGHTS:
		var h: Vector2 = _holo.position + Vector2(48, 44)
		pos.append(Vector4(h.x, h.y, 60.0, 0.18))
		col.append(Vector4(P.CYAN.r, P.CYAN.g, P.CYAN.b, 1.0))
	var count: int = mini(pos.size(), MAX_LIGHTS)
	pos.resize(MAX_LIGHTS)
	col.resize(MAX_LIGHTS)
	vol.set_shader_parameter("light_count", count)
	vol.set_shader_parameter("light_pos", pos)
	vol.set_shader_parameter("light_col", col)


func _detective_size() -> Vector2i:
	match look:
		Look.CLOSER:
			return ArtDetective.SIZE
		Look.TALL:
			return ArtDetectiveTall.SIZE
	return ArtCharacters.DETECTIVE_SIZE


func _place(s: Sprite2D, x: float, size: Vector2i, market_x: float, cam_top: int) -> void:
	# Feet on the walkway; sprites' last two rows are below the shoe line.
	s.position = Vector2(floorf(market_x + x - size.x * 0.5), MarketArt.WALK_Y - size.y + 2 - cam_top)


func _update_voice() -> void:
	var line: String = THOUGHTS[_line]
	var shown: String = line.substr(0, int(_typed))
	var speaking: bool = not _quiet and not busy()
	_thought.visible = voice == Voice.THOUGHT and speaking
	_caption.visible = voice == Voice.CAPTION and speaking
	var win: Vector2 = Vector2(get_window().size)
	if voice == Voice.THOUGHT:
		_thought.text = shown
		var width: float = minf(win.x * 0.36, 640.0)
		var cam_top: int = RESOLUTIONS[res_index][1]
		var cam_x: float = floorf(clampf(detective_x - _view.size.x * 0.5, 0.0, float(MarketArt.ROOM.x - _view.size.x)))
		var head: Vector2 = Vector2(detective_x - cam_x, MarketArt.WALK_Y - _detective_size().y - 6 - cam_top)
		var at: Vector2 = _offset + head * float(_scale)
		_thought.size = Vector2(width, 10)
		_thought.reset_size()
		_thought.size.x = width
		var h: float = _thought.get_combined_minimum_size().y
		_thought.position = Vector2(clampf(at.x - width * 0.5, _offset.x + 16.0, _offset.x + _screen.size.x - width - 16.0), at.y - h)
	elif voice == Voice.CAPTION:
		_caption_label.text = shown
		var width: float = minf(_screen.size.x * 0.5, 900.0)
		_caption.size = Vector2(width, 0)
		_caption.reset_size()
		_caption.size.x = width
		var h: float = _caption.get_combined_minimum_size().y
		# Reserve the full line's height so the box doesn't grow as it types.
		_caption_label.text = line
		h = _caption.get_combined_minimum_size().y
		_caption_label.text = shown
		_caption.size = Vector2(width, h)
		_caption.position = _offset + Vector2(_screen.size.x * 0.04, _screen.size.y - h - _screen.size.y * 0.05)
	var res: Vector2i = _view.size
	_keys.text = "%dx%d at x%d  |  voice: %s  |  fog: %s  |  detective: %s  |  case clock %s\nA/D move   E use   Tab case board   X examine items   R resolution   V voice   F fog   C detective   N next thought   H hide" % [res.x, res.y, _scale, VOICE_NAMES[voice], FOG_NAMES[fog], LOOK_NAMES[look], Case.clock_text(Case.minutes)]


# ---------- screenshots ----------

func _shots_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			return arg.trim_prefix("--shots=")
	return ""


func _take_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	_keys.visible = false
	_shooting = true
	var plan: Array[Array] = [
		# name, resolution, voice, detective x, facing, line, fog[, walk frame, look]
		["640-thought", 0, Voice.THOUGHT, 300.0, 1, 2, Fog.STEPPED],
		["640-caption", 0, Voice.CAPTION, 300.0, 1, 0, Fog.STEPPED],
		["640-silent", 0, Voice.NONE, 760.0, 1, 0, Fog.STEPPED],
		["480-thought", 1, Voice.THOUGHT, 300.0, 1, 2, Fog.STEPPED],
		["480-caption", 1, Voice.CAPTION, 300.0, 1, 0, Fog.STEPPED],
		["480-silent", 1, Voice.NONE, 760.0, 1, 0, Fog.STEPPED],
		["fog-market-off", 0, Voice.NONE, 300.0, 1, 0, Fog.OFF],
		["fog-market-stepped", 0, Voice.NONE, 300.0, 1, 0, Fog.STEPPED],
		["fog-market-volumetric", 0, Voice.NONE, 300.0, 1, 0, Fog.VOLUMETRIC],
		["fog-fixer-off", 0, Voice.NONE, 1100.0, -1, 0, Fog.OFF],
		["fog-fixer-stepped", 0, Voice.NONE, 1100.0, -1, 0, Fog.STEPPED],
		["fog-fixer-volumetric", 0, Voice.NONE, 1100.0, -1, 0, Fog.VOLUMETRIC],
		["detective-idle", 0, Voice.NONE, 300.0, 1, 0, Fog.STEPPED, -1, Look.CLOSER],
		["detective-walk", 0, Voice.NONE, 300.0, 1, 0, Fog.STEPPED, 1, Look.CLOSER],
		["detective-walk-left", 0, Voice.NONE, 640.0, -1, 0, Fog.STEPPED, 6, Look.CLOSER],
		["detective-thought", 0, Voice.THOUGHT, 300.0, 1, 2, Fog.STEPPED, -1, Look.CLOSER],
		["detective-first-sketch", 0, Voice.NONE, 300.0, 1, 0, Fog.STEPPED, -1, Look.SKETCH],
		["detective-tall-idle", 0, Voice.NONE, 300.0, 1, 0, Fog.STEPPED, -1, Look.TALL],
		["detective-tall-walk", 0, Voice.NONE, 300.0, 1, 0, Fog.STEPPED, 1, Look.TALL],
		["detective-tall-volumetric", 0, Voice.NONE, 300.0, 1, 0, Fog.VOLUMETRIC, 6, Look.TALL],
		["npcs-osk", 0, Voice.NONE, 440.0, 1, 0, Fog.STEPPED, -1, Look.TALL],
		["npcs-fixer", 0, Voice.NONE, 830.0, 1, 0, Fog.STEPPED, -1, Look.TALL],
	]
	var only: String = _only_prefix()
	for shot: Array in plan:
		if not String(shot[0]).begins_with(only):
			continue
		res_index = shot[1]
		_apply_resolution()
		voice = shot[2]
		detective_x = shot[3]
		facing = shot[4]
		_line = shot[5]
		fog = shot[6]
		_shot_walk = shot[7] if shot.size() > 7 else -1
		look = shot[8] if shot.size() > 8 else Look.TALL
		_typed = 9999.0
		_time = 1.0
		_rain.warm(2.0)
		for i: int in range(4):
			await get_tree().process_frame
		_typed = 9999.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("%s.png" % shot[0]))
		# The native frame is the two viewports stacked (without volumetric light,
		# which only exists at window resolution).
		var native: Image = _back.get_texture().get_image()
		native.convert(Image.FORMAT_RGBA8)
		var front: Image = _view.get_texture().get_image()
		front.convert(Image.FORMAT_RGBA8)
		native.blend_rect(front, Rect2i(Vector2i.ZERO, front.get_size()), Vector2i.ZERO)
		native.save_png(dir.path_join("%s-native.png" % shot[0]))
	if "examine".begins_with(only) or only.begins_with("examine"):
		await _take_examine_shots(dir, only)
	if "scene".begins_with(only) or only.begins_with("scene"):
		await _take_scene_shots(dir, only)
	get_tree().quit()


## The playable market floor: a prompt, talking to Osk, the fixer once the
## chip's etching is found, the tech, and the case board before and after a
## theory holds.
func _take_scene_shots(dir: String, only: String) -> void:
	res_index = 0
	_apply_resolution()
	voice = Voice.NONE
	fog = Fog.STEPPED
	look = Look.TALL
	_shot_walk = -1
	_quiet = true
	var plan: Array[Array] = [
		# name, detective x, facing, what happens
		["scene-prompt-osk", 484.0, 1, ""],
		["scene-talk-osk", 484.0, 1, "talk"],
		["scene-talk-fixer", 876.0, 1, "fixer"],
		["scene-talk-tech", 1160.0, 1, "talk"],
		["scene-board", 880.0, 1, "board"],
		["scene-board-committed", 880.0, 1, "commit"],
	]
	for shot: Array in plan:
		if not String(shot[0]).begins_with(only):
			continue
		ArtMarketFloor.start_case()
		_talk.hide()
		_board.hide()
		_board.selected.clear()
		_board.theory = ""
		detective_x = shot[1]
		facing = shot[2]
		match String(shot[3]):
			"talk":
				interact()
			"fixer":
				Case.find_clue("chip")
				interact()
			"board", "commit":
				for id: String in ["chip", "rival", "fixerfmt"]:
					Case.find_clue(id)
				open_board()
				_board.selected.assign(["ledger", "rival"])
				_board.theory = "stolen"
				_board.refresh()
				if shot[3] == "commit":
					_board.commit()
		_talk.finish_typing()
		_toasts.clear()
		_time = 1.0
		_rain.warm(2.0)
		for i: int in range(4):
			await get_tree().process_frame
		_talk.finish_typing()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("%s.png" % shot[0]))
	_talk.hide()
	_board.hide()


## The examine test: the chip as it comes up, turning, turned over with the
## etching found, without palette snap to compare, the flat tag, and the tin:
## shut, its catch found, open, and the slip taken out of it.
func _take_examine_shots(dir: String, only: String) -> void:
	res_index = 0
	_apply_resolution()
	voice = Voice.NONE
	detective_x = 300.0
	facing = 1
	fog = Fog.STEPPED
	look = Look.TALL
	_shot_walk = -1
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
		_time = 1.0
		_rain.warm(2.0)
		for i: int in range(4):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("%s.png" % shot[0]))
	_examine.close()
	_examine.still = false


func _only_prefix() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			return arg.trim_prefix("--only=")
	return ""
