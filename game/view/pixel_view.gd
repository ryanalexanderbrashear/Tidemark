class_name PixelView
extends Control
## The game's picture: everything is drawn at native resolution (640 x 360,
## settled in the Look and Feel doc) and scaled up by a whole number to fit
## the window, centred, with black bars where it doesn't divide evenly.
##
## Two viewports hold the world: `back` (sky to shanties, with the fog between)
## and `play` in front of it (rooms, people, water, rain), which is see-through
## where a room has gaps. Over them sit the full-screen effects the case uses:
## the thermal optic (`heat` mirrors what's warm), a reading's white, and the
## fade between rooms. Volumetric fog, when a room asks for it, is drawn at the
## window's own resolution behind the crisp playable layer.
##
## UI that wants to line up with the pixels (talk box, board, examine view)
## listens to `laid_out` and places itself with `zoom` and `offset`.

signal laid_out(native: Vector2i, scale: int, offset: Vector2)

const P = preload("res://game/art/art_palette.gd")
const VOLUMETRIC_SHADER = preload("res://game/art/volumetric.gdshader")
const HEAT_SHADER = preload("res://game/art/heat.gdshader")
const THERMAL_SHADER = preload("res://game/art/thermal.gdshader")
const READING_SHADER = preload("res://game/art/reading_fog.gdshader")
## The game's resolution: scales by whole numbers to 720p, 1080p, 1440p and 4K.
const NATIVE: Vector2i = Vector2i(640, 360)
## The most fog lights the volumetric shader takes.
const MAX_LIGHTS: int = 24

var back: SubViewport
var play: SubViewport
## The play viewport's three depths: the rooms, the people walking between
## them (the detective), and what's in front of everyone (water, railings).
var rooms: Node2D
var people: Node2D
var over: Node2D
## What's warm, for the thermal optic: sprites made by heat_sprite().
var heat: SubViewport
## Whole-number scale from native to window pixels, and where the picture's
## top-left corner sits in the window.
var zoom: int = 1
var offset: Vector2 = Vector2.ZERO
## The picture's size in window pixels.
var shown: Vector2 = Vector2(NATIVE)

var _back_screen: TextureRect
var _screen: TextureRect
var _thermal: ColorRect
var _heat_screen: TextureRect
var _reading: ColorRect
var _fade: ColorRect


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var black: ColorRect = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	back = _viewport(false)
	play = _viewport(true)
	heat = _viewport(true)
	rooms = Node2D.new()
	people = Node2D.new()
	over = Node2D.new()
	for n: Node2D in [rooms, people, over]:
		play.add_child(n)

	_back_screen = _screen_of(back)
	var vol: ShaderMaterial = ShaderMaterial.new()
	vol.shader = VOLUMETRIC_SHADER
	vol.set_shader_parameter("back_soft", back.get_texture())
	vol.set_shader_parameter("fog_color", FogArt.FOG_TINT)
	vol.set_shader_parameter("view_size", Vector2(NATIVE))
	_back_screen.material = vol
	_screen = _screen_of(play)

	_thermal = _overlay(THERMAL_SHADER)
	_thermal.visible = false
	_heat_screen = _screen_of(heat)
	_heat_screen.visible = false
	_reading = _overlay(READING_SHADER)
	(_reading.material as ShaderMaterial).set_shader_parameter("native", Vector2(NATIVE))
	_reading.visible = false
	_fade = ColorRect.new()
	_fade.color = Color(P.INK, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _ready() -> void:
	# The view does its own whole-number scaling.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size_changed.connect(layout)
	layout.call_deferred()


func _viewport(see_through: bool) -> SubViewport:
	var v: SubViewport = SubViewport.new()
	v.size = NATIVE
	v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	v.snap_2d_transforms_to_pixel = true
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	v.transparent_bg = see_through
	add_child(v)
	return v


func _screen_of(v: SubViewport) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = v.get_texture()
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _overlay(shader: Shader) -> ColorRect:
	var c: ColorRect = ColorRect.new()
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = shader
	c.material = m
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func layout() -> void:
	var win: Vector2i = get_window().size
	zoom = maxi(1, mini(win.x / NATIVE.x, win.y / NATIVE.y))
	shown = Vector2(NATIVE * zoom)
	offset = ((Vector2(win) - shown) * 0.5).floor()
	for c: Control in [_back_screen, _screen, _thermal, _heat_screen, _reading]:
		c.position = offset
		c.size = shown
	_fade.position = Vector2.ZERO
	_fade.size = Vector2(win)
	laid_out.emit(NATIVE, zoom, offset)


## A native-pixel point in window pixels.
func to_window(native: Vector2) -> Vector2:
	return offset + native * float(zoom)


## A text size that reads well at this window height.
func font_px() -> int:
	return roundi(float(get_window().size.y) / 46.0)


## A sprite in the heat picture, glowing at `amount` (1 is a living body).
func heat_sprite(amount: float) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.centered = false
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = HEAT_SHADER
	m.set_shader_parameter("heat", amount)
	s.material = m
	heat.add_child(s)
	return s


## The thermal optic's picture over everything.
func set_thermal(on: bool) -> void:
	_thermal.visible = on
	_heat_screen.visible = on


## A reading's white, from 0 (none) to 1.
func set_reading(amount: float, time: float) -> void:
	var m: ShaderMaterial = _reading.material as ShaderMaterial
	m.set_shader_parameter("amount", amount)
	m.set_shader_parameter("time", time)
	_reading.visible = amount > 0.001


## How far faded to black (0 clear, 1 black).
func set_fade(amount: float) -> void:
	_fade.color = Color(P.INK, amount)


## Volumetric fog behind the playable layer, lit by `lights` ([positions,
## colours] in native screen pixels, as FogLights builds them), or off.
func set_volumetric(on: bool, water_y: float = 0.0, lights: Array = []) -> void:
	var vol: ShaderMaterial = _back_screen.material as ShaderMaterial
	vol.set_shader_parameter("volumetric", on)
	vol.set_shader_parameter("water_y", water_y)
	if not on or lights.size() < 2:
		return
	var pos: PackedVector4Array = lights[0]
	var col: PackedVector4Array = lights[1]
	var count: int = mini(pos.size(), MAX_LIGHTS)
	pos.resize(MAX_LIGHTS)
	col.resize(MAX_LIGHTS)
	vol.set_shader_parameter("light_count", count)
	vol.set_shader_parameter("light_pos", pos)
	vol.set_shader_parameter("light_col", col)


## The native frame: the two world viewports stacked (without volumetric
## light, which only exists at window resolution).
func native_image() -> Image:
	var img: Image = back.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var front: Image = play.get_texture().get_image()
	front.convert(Image.FORMAT_RGBA8)
	img.blend_rect(front, Rect2i(Vector2i.ZERO, front.get_size()), Vector2i.ZERO)
	return img
