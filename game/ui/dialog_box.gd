class_name DialogBox
extends Control
## Shows a Talk and its choices. Number keys pick a choice; Esc closes a box
## whose only choice closes it.

signal closed

var talk: Talk
var _who: Label
var _text: Label
var _options: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var parts: Array[Control] = UiTheme.modal(560)
	add_child(parts[0])
	var box: VBoxContainer = parts[1] as VBoxContainer
	_who = UiTheme.label("", 20, UiTheme.WARN)
	_text = UiTheme.label("")
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 6)
	box.add_child(_who)
	box.add_child(_text)
	box.add_child(_options)
	hide()


func show_talk(t: Talk) -> void:
	talk = t
	_who.text = t.speaker
	_text.text = t.text
	for c: Node in _options.get_children():
		c.queue_free()
	var i: int = 1
	for o: TalkOption in t.options:
		var b: Button = Button.new()
		b.text = "%d.  %s" % [i, o.label]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_pick.bind(o))
		_options.add_child(b)
		i += 1
	show()
	(_options.get_child(0) as Button).grab_focus.call_deferred()


func _pick(o: TalkOption) -> void:
	var next: Talk = o.pick()
	if next != null and not Case.closed:
		show_talk(next)
	else:
		hide()
		closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo:
		var n: int = key.keycode - KEY_1
		if n >= 0 and n < talk.options.size():
			get_viewport().set_input_as_handled()
			_pick(talk.options[n])
			return
	if event.is_action_pressed("back") and talk.options.size() == 1 and not talk.options[0].action.is_valid():
		get_viewport().set_input_as_handled()
		_pick(talk.options[0])
