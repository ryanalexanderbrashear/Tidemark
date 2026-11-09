class_name Notices
extends Control
## The few words the game puts over the picture: toasts from the case (a new
## clue, a door that won't open) one after another near the top, the prompt
## over whatever the detective can use, and the status line in the top right
## corner (the case clock and the like).

const P = preload("res://game/art/art_palette.gd")
const TEXT: Color = Color("d4dce6")
## Seconds a toast stays up.
const TOAST_TIME: float = 2.8

## The toast now up and those waiting behind it.
var toasts: Array[String] = []
var _toast_time: float = 0.0
var _toast: Label
var _prompt: Label
var _status: Label


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status = outlined(P.AMBER)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status.visible = true
	add_child(_status)
	_prompt = outlined(TEXT)
	add_child(_prompt)
	_toast = outlined(P.AMBER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_toast)


## A label in the game's outlined text.
static func outlined(c: Color) -> Label:
	var l: Label = Label.new()
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(P.INK, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.visible = false
	return l


func toast(text: String) -> void:
	toasts.append(text)
	if toasts.size() == 1:
		_toast_time = TOAST_TIME


func clear_toasts() -> void:
	toasts.clear()
	_toast.visible = false


func _restyle(view: PixelView) -> void:
	var font_px: int = view.font_px()
	for l: Label in [_prompt, _toast, _status]:
		l.add_theme_font_size_override("font_size", roundi(font_px * 0.85))
		l.add_theme_constant_override("outline_size", maxi(2, font_px / 5))


## Counts the toast down. While `only_clues`, only news of a clue shows (the
## detective is holding something up close).
func update_toast(view: PixelView, delta: float, only_clues: bool = false) -> void:
	_restyle(view)
	if toasts.is_empty():
		_toast.visible = false
		return
	_toast_time -= delta
	if _toast_time <= 0.0:
		toasts.pop_front()
		_toast_time = TOAST_TIME
		if toasts.is_empty():
			_toast.visible = false
			return
	_toast.visible = not only_clues or toasts[0].begins_with("New clue")
	_toast.text = toasts[0]
	var width: float = minf(view.shown.x * 0.7, 1200.0)
	_toast.size = Vector2(width, 0)
	_toast.position = view.offset + Vector2((view.shown.x - width) * 0.5, view.shown.y * 0.05)


## Shows `text` centred over `at` (native pixels, in view), or hides the
## prompt when `text` is "".
func prompt(view: PixelView, text: String, at: Vector2 = Vector2.ZERO) -> void:
	_prompt.visible = text != ""
	if text == "":
		return
	_prompt.text = text
	_prompt.reset_size()
	var w: float = _prompt.size.x
	_prompt.position = view.to_window(at) - Vector2(w * 0.5, _prompt.size.y)
	_prompt.position.x = clampf(_prompt.position.x, view.offset.x + 8.0, view.offset.x + view.shown.x - w - 8.0)


func prompt_text() -> String:
	return _prompt.text if _prompt.visible else ""


func status(view: PixelView, text: String) -> void:
	_status.text = text
	_status.reset_size()
	_status.position = view.offset + Vector2(view.shown.x - _status.size.x - 14.0, 8.0)
