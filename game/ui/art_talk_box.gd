class_name ArtTalkBox
extends Control
## The art test's dialogue box: the case's own Talks (DrownedMarket), shown in
## the scene's style instead of the prototype's plain panel. A box low on the
## screen in the caption's navy and amber, the speaker's name over the line, the
## line typed out, and the choices under it.
##
## Keys: W/S or arrows choose, E, Enter or Space pick (or finish the typing),
## 1-9 pick directly, Esc leaves when there's a choice that just closes.

signal closed

const P = preload("res://game/art/art_palette.gd")
## Characters a second as a line types out.
const TYPE_SPEED: float = 70.0
const TEXT: Color = Color("d4dce6")

var talk: Talk
var selected: int = 0
## Characters of the line shown so far.
var typed: float = 0.0

var _panel: PanelContainer
var _who: Label
var _text: Label
var _options: VBoxContainer
var _rows: Array[Label] = []
var _font_px: int = 16
var _shown: Vector2 = Vector2(640, 360)
var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(P.NAVY, 0.94)
	box.border_color = P.AMBER_DIM
	box.border_width_left = 4
	box.border_width_top = 1
	box.shadow_color = Color(P.INK, 0.6)
	box.shadow_size = 6
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)
	_who = _label(P.AMBER)
	col.add_child(_who)
	_text = _label(TEXT)
	col.add_child(_text)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 2)
	col.add_child(_options)
	hide()


func _label(c: Color) -> Label:
	var l: Label = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", c)
	return l


func show_talk(t: Talk) -> void:
	talk = t
	selected = 0
	typed = 0.0
	_who.text = t.speaker.to_upper()
	_text.text = t.text
	_text.visible_characters = 0
	for c: Node in _options.get_children():
		_options.remove_child(c)
		c.queue_free()
	_rows.clear()
	for i: int in range(t.options.size()):
		var row: Label = _label(P.RAIN)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_input.bind(i))
		row.mouse_entered.connect(func() -> void: _select(i))
		_options.add_child(row)
		_rows.append(row)
	show()
	_update_rows()
	_restyle()
	# Once more after the container has sorted the new rows.
	_restyle.call_deferred()


func finish_typing() -> void:
	if talk != null:
		typed = float(talk.text.length())
		_text.visible_characters = -1
		_update_rows()


func is_typing() -> bool:
	return talk != null and typed < float(talk.text.length())


## Picks a choice: plays its action and shows what it leads to, or closes.
func pick(index: int) -> void:
	if talk == null or index < 0 or index >= talk.options.size():
		return
	var next: Talk = talk.options[index].pick()
	if next != null and not Case.closed:
		show_talk(next)
	else:
		hide()
		talk = null
		closed.emit()


func _select(i: int) -> void:
	selected = clampi(i, 0, maxi(0, _rows.size() - 1))
	_update_rows()


func _on_row_input(event: InputEvent, i: int) -> void:
	var b: InputEventMouseButton = event as InputEventMouseButton
	if b != null and b.pressed and b.button_index == MOUSE_BUTTON_LEFT and not is_typing():
		accept_event()
		pick(i)


func _process(delta: float) -> void:
	if not visible or talk == null:
		return
	if is_typing():
		typed = minf(typed + delta * TYPE_SPEED, float(talk.text.length()))
		_text.visible_characters = int(typed)
		_update_rows()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or talk == null:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Everything goes to the box while it's up, not to the market behind it.
	get_viewport().set_input_as_handled()
	if is_typing():
		if key.physical_keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			finish_typing()
		return
	var n: int = key.physical_keycode - KEY_1
	if n >= 0 and n < 9:
		pick(n)
		return
	match key.physical_keycode:
		KEY_W, KEY_UP:
			_select(posmod(selected - 1, _rows.size()))
		KEY_S, KEY_DOWN:
			_select(posmod(selected + 1, _rows.size()))
		KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			pick(selected)
		KEY_ESCAPE:
			var leave: int = _closing_option()
			if leave >= 0:
				pick(leave)


## The last choice that just closes the box, or -1.
func _closing_option() -> int:
	for i: int in range(talk.options.size() - 1, -1, -1):
		if not talk.options[i].action.is_valid():
			return i
	return -1


func _update_rows() -> void:
	var ready_to_pick: bool = not is_typing()
	for i: int in range(_rows.size()):
		var on: bool = i == selected and ready_to_pick
		_rows[i].text = "%s %d  %s" % ["›" if on else " ", i + 1, talk.options[i].label]
		_rows[i].add_theme_color_override("font_color", P.AMBER if on else (P.RAIN if ready_to_pick else Color(P.RAIN, 0.35)))


## Sits the box on the game's pixel grid: `native` resolution shown at
## whole-number `scale` from `offset`.
func layout(native: Vector2i, scale: int, offset: Vector2) -> void:
	_shown = Vector2(native * scale)
	_offset = offset
	_font_px = roundi(float(get_window().size.y) / 46.0)
	_restyle()


func _restyle() -> void:
	if _panel == null:
		return
	var labels: Array[Label] = [_who, _text]
	labels.append_array(_rows)
	for l: Label in labels:
		l.add_theme_font_size_override("font_size", _font_px)
	_who.add_theme_font_size_override("font_size", roundi(_font_px * 0.85))
	var box: StyleBoxFlat = _panel.get_theme_stylebox("panel") as StyleBoxFlat
	box.set_content_margin_all(_font_px * 0.8)
	box.content_margin_left = _font_px * 1.2
	var width: float = minf(_shown.x * 0.62, 1100.0)
	# Wrapping labels need their width up front to know how tall they are.
	var inner: float = width - box.content_margin_left - box.content_margin_right
	for l: Label in labels:
		l.custom_minimum_size = Vector2(inner, 0)
	_panel.size = Vector2(width, 0)
	_panel.reset_size()
	# Full text measured so the box doesn't grow as it types.
	var h: float = _panel.get_combined_minimum_size().y
	_panel.size = Vector2(width, h)
	_panel.position = _offset + Vector2((_shown.x - width) * 0.5, _shown.y - h - _shown.y * 0.04)
