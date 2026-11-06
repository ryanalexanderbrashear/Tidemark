class_name ExamineView
extends Control
## The examine test: the detective holds an item up to his eyes and turns it
## over. Each item is a small 3D box with pixel-art faces (ExamineItem),
## rendered into a SubViewport at the game's own resolution, so one texel is one
## game pixel at zoom 1, then snapped to the art palette with an ink outline
## (examine.gdshader). The look stays pixel art; the turning is real.
##
## A hidden detail is found by holding its face toward the camera for a moment.
##
## Keys: drag or W/A/S/D (arrows) turn, Q/E roll, wheel or +/- zoom, Tab next
## item, R straighten, P palette snap on/off, X or Esc put it away.

signal closed

const P = preload("res://game/art_test/art_palette.gd")
const SNAP_SHADER = preload("res://game/art_test/examine.gdshader")
const FOV: float = 30.0
## Items come up at 1.5 texels a game pixel: held near the eyes.
const ZOOM_START: float = 1.5
const ZOOM_MIN: float = 1.0
const ZOOM_MAX: float = 3.0
## Radians turned per game pixel dragged.
const DRAG_TURN: float = 0.018
## Radians a second while a turn key is held.
const KEY_TURN: float = 2.6
## How fast a flicked item slows down (per second).
const FRICTION: float = 5.0
## A face counts as toward the camera within about 30 degrees.
const FOUND_DOT: float = 0.86
## Seconds the detail's face has to stay toward the camera.
const FOUND_HOLD: float = 0.3
const LIFT_TIME: float = 0.35
## The angle an item first comes up at: a little turned, like it's in a hand.
const REST: Vector3 = Vector3(-0.18, 0.32, 0.04)

var items: Array[ExamineItem] = []
var index: int = 0
var zoom: float = ZOOM_START
var snap: bool = true:
	set(value):
		snap = value
		if _screen != null:
			(_screen.material as ShaderMaterial).set_shader_parameter("snap", value)
## Details found so far, by item id.
var found: Dictionary[String, bool] = {}

var _view: SubViewport
var _camera: Camera3D
## _hand sways a little; _item is the box the player turns inside it.
var _hand: Node3D
var _item: Node3D
var _screen: TextureRect
var _dim: ColorRect
var _title: Label
var _notes: Label
var _thought: Label
var _hint: Label
var _spin: Vector3 = Vector3.ZERO
var _dragging: bool = false
var _facing_time: float = 0.0
var _lift: float = 1.0
var _time: float = 0.0
var _thought_time: float = 0.0
var _native: Vector2i = Vector2i(640, 360)
var _scale: int = 1
var _offset: Vector2 = Vector2.ZERO
## Screenshots only: holds still (no sway, no lift).
var still: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	items = ExamineItem.all()

	_dim = ColorRect.new()
	_dim.color = Color(P.INK, 0.82)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.transparent_bg = true
	_view.msaa_3d = Viewport.MSAA_DISABLED
	_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_view)
	_build_stage()

	_screen = TextureRect.new()
	_screen.texture = _view.get_texture()
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SNAP_SHADER
	var pal: PackedVector3Array = palette_vectors()
	mat.set_shader_parameter("palette_size", pal.size())
	pal.resize(32)
	mat.set_shader_parameter("palette", pal)
	mat.set_shader_parameter("outline_color", P.INK)
	_screen.material = mat
	add_child(_screen)

	_title = _label(Color(P.AMBER))
	_notes = _label(Color("d4dce6"))
	_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thought = _label(Color("d4dce6"))
	_thought.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thought.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thought.add_theme_color_override("font_outline_color", Color(P.INK, 0.9))
	_hint = _label(Color(P.RAIN, 0.8))
	_hint.text = "drag or WASD turn   Q/E roll   wheel zoom   Tab next item   R straighten   P palette snap   X put away"


## Every palette colour the close-up may use: the cool greys, the neons and
## amber. Blood red is left out, so nothing the detective handles turns red by
## accident of lighting; rust, tarp green and skin are left out because grey
## metal under the warm lamp snapped to them and read as the wrong material.
static func palette_vectors() -> PackedVector3Array:
	var out: PackedVector3Array = []
	for c: Color in [P.NAVY, P.STORM, P.CONCRETE, P.RAIN, P.MAGENTA, P.CYAN, P.AMBER,
			P.INK, P.NIGHT, P.DEEP, P.SLATE, P.STEEL, P.FOG,
			P.AMBER_DIM, P.MAGENTA_DIM, P.CYAN_DIM, P.GLINT]:
		out.append(Vector3(c.r, c.g, c.b))
	return out


func _label(c: Color) -> Label:
	var l: Label = Label.new()
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


## Lit like the market: the stall's amber lamp above, cyan neon behind, a
## little magenta bounce from below.
func _build_stage() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = P.STORM
	env.ambient_light_energy = 0.9
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	_view.add_child(world_env)

	_camera = Camera3D.new()
	_camera.fov = FOV
	_view.add_child(_camera)

	var key: DirectionalLight3D = DirectionalLight3D.new()
	key.light_color = Color(P.AMBER).lerp(Color.WHITE, 0.7)
	key.light_energy = 1.25
	key.basis = Basis.looking_at(Vector3(0.45, -0.7, -0.75).normalized())
	_view.add_child(key)
	var rim: OmniLight3D = OmniLight3D.new()
	rim.light_color = P.CYAN
	rim.light_energy = 3.0
	rim.omni_range = 5.0
	rim.position = Vector3(1.8, 0.7, -1.0)
	_view.add_child(rim)
	var bounce: OmniLight3D = OmniLight3D.new()
	bounce.light_color = P.MAGENTA
	bounce.light_energy = 0.9
	bounce.omni_range = 5.0
	bounce.position = Vector3(-1.9, -1.4, 1.2)
	_view.add_child(bounce)

	_hand = Node3D.new()
	_view.add_child(_hand)
	_item = Node3D.new()
	_hand.add_child(_item)


# ---------- opening, closing, switching ----------

func open(at: int = -1) -> void:
	if at >= 0:
		index = at
	visible = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_show_item()


func close() -> void:
	visible = false
	_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_dragging = false
	closed.emit()


func is_open() -> bool:
	return visible


func next_item() -> void:
	index = (index + 1) % items.size()
	_show_item()


func current() -> ExamineItem:
	return items[index]


func _show_item() -> void:
	for c: Node in _item.get_children():
		c.queue_free()
	var it: ExamineItem = current()
	for face: String in ExamineItem.FACES:
		_item.add_child(_face_mesh(it, face))
	_item.basis = Basis.from_euler(REST)
	_spin = Vector3.ZERO
	_facing_time = 0.0
	_thought_time = 0.0
	zoom = ZOOM_START
	_lift = 0.0 if not still else 1.0
	_update_text()


func _face_mesh(it: ExamineItem, face: String) -> MeshInstance3D:
	var n: Vector3 = ExamineItem.FACES[face]
	var px: Vector2i = it.face_size(face)
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(px) / ExamineItem.TEXELS
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(it.faces[face])
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.metallic = it.metallic
	mat.roughness = it.roughness
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	quad.material = mat
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = quad
	# Top and bottom faces keep the item's front as their "up", so their
	# images read the right way round when the item is tipped toward you.
	var up: Vector3 = Vector3.UP if n.y == 0.0 else Vector3.FORWARD * n.y
	m.basis = Basis(up.cross(n), up, n)
	m.position = n * it.size * 0.5
	return m


# ---------- turning ----------

## Turns the item about the camera's axes: x tips it toward or away, y spins
## it left or right, z rolls it.
func turn(by: Vector3) -> void:
	var b: Basis = _item.basis
	if by.y != 0.0:
		b = Basis(Vector3.UP, by.y) * b
	if by.x != 0.0:
		b = Basis(Vector3.RIGHT, by.x) * b
	if by.z != 0.0:
		b = Basis(Vector3.BACK, by.z) * b
	_item.basis = b.orthonormalized()


func set_turn(b: Basis) -> void:
	_item.basis = b.orthonormalized()
	_spin = Vector3.ZERO


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = button.pressed
			if _dragging:
				_spin = Vector3.ZERO
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(0.15)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(-0.15)
		accept_event()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _dragging:
		# Measured in game pixels, so it feels the same at any window size.
		var d: Vector2 = motion.relative / float(_scale)
		var by: Vector3 = Vector3(d.y, d.x, 0.0) * DRAG_TURN
		turn(by)
		var dt: float = maxf(get_process_delta_time(), 1.0 / 240.0)
		_spin = _spin.lerp(by / dt, 0.5)
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_X, KEY_ESCAPE:
			close()
		KEY_TAB:
			next_item()
		KEY_R:
			_item.basis = Basis.from_euler(REST)
			_spin = Vector3.ZERO
		KEY_P:
			snap = not snap
		KEY_EQUAL, KEY_KP_ADD:
			_zoom_by(0.25)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_zoom_by(-0.25)
	# Everything goes to the item while it's up, not to the market behind it.
	get_viewport().set_input_as_handled()


func _zoom_by(amount: float) -> void:
	zoom = clampf(zoom + amount, ZOOM_MIN, ZOOM_MAX)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	var keys: Vector3 = Vector3(
		_held(KEY_S, KEY_DOWN) - _held(KEY_W, KEY_UP),
		_held(KEY_D, KEY_RIGHT) - _held(KEY_A, KEY_LEFT),
		_held(KEY_Q, KEY_NONE) - _held(KEY_E, KEY_NONE))
	if keys != Vector3.ZERO:
		turn(keys * KEY_TURN * delta)
		_spin = Vector3.ZERO
	elif not _dragging and _spin.length() > 0.01:
		turn(_spin * delta)
		_spin *= exp(-FRICTION * delta)
	_lift = minf(1.0, _lift + delta / LIFT_TIME)
	check_found(delta)
	if _thought_time > 0.0:
		_thought_time -= delta
	_update_stage()
	_update_text()


func _held(a: Key, b: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(a) or (b != KEY_NONE and Input.is_physical_key_pressed(b)) else 0.0


## Counts how long the hidden detail's face has been toward the camera, and
## marks it found once that's long enough.
func check_found(delta: float) -> void:
	var it: ExamineItem = current()
	if it.detail_face == "" or found.get(it.id, false):
		return
	if ExamineItem.facing(_item.basis, it.detail_face) >= FOUND_DOT:
		_facing_time += delta
		if _facing_time >= FOUND_HOLD:
			found[it.id] = true
			_thought_time = 6.0
	else:
		_facing_time = 0.0


func _update_stage() -> void:
	# The camera comes closer to zoom, so one texel is `zoom` game pixels.
	var visible_h: float = float(_native.y) / ExamineItem.TEXELS
	_camera.position = Vector3(0, 0, visible_h * 0.5 / tan(deg_to_rad(FOV * 0.5)) / zoom)
	var t: float = 1.0 - pow(1.0 - _lift, 3.0)
	var sway: float = 0.0 if still else 1.0
	_hand.position = Vector3(0, lerpf(-2.0, 0.0, t) + sin(_time * 1.3) * 0.012 * sway, 0)
	_hand.rotation = Vector3(sin(_time * 0.9) * 0.015 * sway, (1.0 - t) * 0.9, sin(_time * 0.7) * 0.01 * sway)


# ---------- layout and text ----------

## Puts the close-up on the game's pixel grid: `native` is the game's
## resolution, shown at whole-number `scale` from `offset`.
func layout(native: Vector2i, scale: int, offset: Vector2) -> void:
	_native = native
	_scale = scale
	_offset = offset
	_view.size = native
	var win_size: Vector2 = Vector2(get_window().size)
	position = Vector2.ZERO
	size = win_size
	_dim.position = Vector2.ZERO
	_dim.size = win_size
	_screen.position = offset
	_screen.size = Vector2(native * scale)
	var win: Vector2 = Vector2(get_window().size)
	var font_px: int = roundi(win.y / 46.0)
	for l: Label in [_title, _notes, _thought]:
		l.add_theme_font_size_override("font_size", font_px)
	_title.add_theme_font_size_override("font_size", roundi(font_px * 1.25))
	_thought.add_theme_constant_override("outline_size", maxi(2, font_px / 5))
	_hint.add_theme_font_size_override("font_size", maxi(12, roundi(win.y / 70.0)))
	var shown: Vector2 = Vector2(native * scale)
	var margin: float = shown.y * 0.05
	_title.position = offset + Vector2(margin, margin)
	_notes.position = _title.position + Vector2(0, font_px * 2.0)
	_notes.size = Vector2(shown.x * 0.32, 0)
	_thought.size = Vector2(shown.x * 0.5, 0)
	_thought.position = offset + Vector2(shown.x * 0.25, shown.y * 0.82)
	_hint.position = offset + Vector2(margin, shown.y - margin - _hint.get_combined_minimum_size().y)


func _update_text() -> void:
	var it: ExamineItem = current()
	_title.text = it.title
	var lines: Array[String] = it.notes.duplicate()
	if found.get(it.id, false):
		lines.append("")
		lines.append("Found: " + it.detail_note)
	var names: Array[String] = []
	for i: int in range(items.size()):
		names.append(("[%s]" if i == index else "%s") % items[i].title)
	lines.append("")
	lines.append("Pockets: " + "  ".join(PackedStringArray(names)))
	_notes.text = "\n".join(PackedStringArray(lines))
	_thought.visible = _thought_time > 0.0 or (still and found.get(it.id, false))
	_thought.text = it.detail_thought
