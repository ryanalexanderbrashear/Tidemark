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
##
## Fights can zoom out (set_view_width): the world viewports are MAX_VIEW big,
## with the 640 x 360 frame everything is drawn in (the "base frame") at
## MARGIN inside them, and the screen shows `view_size` of it around that
## frame, scaled to the same picture. Scaled by a whole number it's plain
## nearest pixels; in between, a sharp-bilinear filter (present.gdshader)
## keeps every pixel the same size and blends only its edges.

signal laid_out(native: Vector2i, scale: int, offset: Vector2)

const P = preload("res://game/art/art_palette.gd")
const VOLUMETRIC_SHADER = preload("res://game/art/volumetric.gdshader")
const HEAT_SHADER = preload("res://game/art/heat.gdshader")
const THERMAL_SHADER = preload("res://game/art/thermal.gdshader")
const READING_SHADER = preload("res://game/art/reading_fog.gdshader")
const PRESENT_SHADER = preload("res://game/art/present.gdshader")
## The game's resolution: scales by whole numbers to 720p, 1080p, 1440p and 4K.
const NATIVE: Vector2i = Vector2i(640, 360)
## The most world a zoomed-out view shows: one and a half times the frame.
const MAX_VIEW: Vector2i = Vector2i(960, 540)
## Where the base frame's top-left sits in the world viewports. A zoomed view
## grows evenly left and right, and two thirds of its extra height above the
## frame, a third below.
const MARGIN: Vector2i = Vector2i(160, 120)
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
## How much of the world the picture shows now (native px): NATIVE, or more
## in a zoomed-out fight, up to MAX_VIEW. Always 16:9.
var view_size: Vector2 = Vector2(NATIVE)

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
	vol.set_shader_parameter("tex_size", Vector2(MAX_VIEW))
	vol.set_shader_parameter("margin", Vector2(MARGIN))
	_back_screen.material = vol
	_screen = _screen_of(play)
	_screen.material = _present_material()

	_thermal = _overlay(THERMAL_SHADER)
	_thermal.visible = false
	_heat_screen = _screen_of(heat)
	_heat_screen.material = _present_material()
	_heat_screen.visible = false
	_reading = _overlay(READING_SHADER)
	(_reading.material as ShaderMaterial).set_shader_parameter("native", Vector2(NATIVE))
	_reading.visible = false
	_fade = ColorRect.new()
	_fade.color = Color(P.INK, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _ready() -> void:
	# The base frame sits at MARGIN in each world viewport (set here: a
	# viewport takes a canvas transform only once it's in the tree).
	for v: SubViewport in [back, play, heat]:
		v.canvas_transform = Transform2D(0.0, Vector2(MARGIN))
	# The view does its own whole-number scaling.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size_changed.connect(layout)
	layout.call_deferred()


func _viewport(see_through: bool) -> SubViewport:
	var v: SubViewport = SubViewport.new()
	v.size = MAX_VIEW
	v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	v.snap_2d_transforms_to_pixel = true
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	v.transparent_bg = see_through
	add_child(v)
	return v


func _screen_of(v: SubViewport) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = v.get_texture()
	# Linear so present.gdshader can blend pixel edges when the scale isn't
	# a whole number; at whole numbers it samples pixel centres only.
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _present_material() -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = PRESENT_SHADER
	m.set_shader_parameter("tex_size", Vector2(MAX_VIEW))
	return m


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
	_show_region()
	laid_out.emit(NATIVE, zoom, offset)


## Shows `width` native px of the world across the picture (NATIVE.x up to
## MAX_VIEW.x), the height to match.
func set_view_width(width: float) -> void:
	var w: float = clampf(width, float(NATIVE.x), float(MAX_VIEW.x))
	view_size = Vector2(w, w * float(NATIVE.y) / float(NATIVE.x))
	_show_region()


## The part of the world viewports on screen now, in their pixels: the base
## frame when not zoomed, starting on a whole pixel.
func region() -> Rect2:
	var extra: Vector2 = view_size - Vector2(NATIVE)
	var up: float = float(MARGIN.y) / float(MAX_VIEW.y - NATIVE.y)
	var at: Vector2 = Vector2(MARGIN) - Vector2(extra.x * 0.5, extra.y * up)
	return Rect2(at.round(), view_size)


## Window pixels per world pixel now: `zoom` when not zoomed out.
func pixel_scale() -> float:
	return shown.x / view_size.x


func _show_region() -> void:
	var r: Rect2 = region()
	var uv: Vector4 = Vector4(r.position.x / MAX_VIEW.x, r.position.y / MAX_VIEW.y, r.size.x / MAX_VIEW.x, r.size.y / MAX_VIEW.y)
	for c: TextureRect in [_back_screen, _screen, _heat_screen]:
		var m: ShaderMaterial = c.material as ShaderMaterial
		m.set_shader_parameter("region", uv)
		m.set_shader_parameter("scale", pixel_scale())


## A point in the base frame (native px) in window pixels.
func to_window(native: Vector2) -> Vector2:
	var r: Rect2 = region()
	return offset + (native + Vector2(MARGIN) - r.position) * pixel_scale()


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


## The picture at world pixels: the two world viewports stacked, cut to the
## part on screen (view_size; NATIVE when not zoomed), without volumetric
## light, which only exists at window resolution.
func native_image() -> Image:
	var img: Image = back.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var front: Image = play.get_texture().get_image()
	front.convert(Image.FORMAT_RGBA8)
	img.blend_rect(front, Rect2i(Vector2i.ZERO, front.get_size()), Vector2i.ZERO)
	var r: Rect2 = region()
	return img.get_region(Rect2i(Vector2i(r.position), Vector2i(r.size.round())))
