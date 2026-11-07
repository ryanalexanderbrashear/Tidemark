class_name CaseBoard
extends Control
## The case board: pick the clues that back a theory, then commit it. A theory
## holds with two or more clues that support it and nothing that doesn't. A
## failed chain just doesn't hold. A wrong theory can still hold, and the game plays it out.

signal closed

const LINES: Dictionary[TheoryCheck.Result, String] = {
	TheoryCheck.Result.NOT_ENOUGH: "Not enough holds it up.",
	TheoryCheck.Result.DOESNT_FIT: "One of those doesn't fit.",
	TheoryCheck.Result.MISSING_SUBJECT: "You don't have what that theory is about yet.",
}

var _selected: Array[String] = []
var _theory: String = ""
var _clue_list: VBoxContainer
var _theory_list: VBoxContainer
var _message: Label
var _commit: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var parts: Array[Control] = UiTheme.modal(900)
	add_child(parts[0])
	var box: VBoxContainer = parts[1] as VBoxContainer
	box.add_child(UiTheme.label("Case board", 24, UiTheme.NEON))
	var cols: HBoxContainer = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	box.add_child(cols)
	_clue_list = _column(cols, "Clues: pick the ones that back your theory")
	_theory_list = _column(cols, "Theories")
	var foot: HBoxContainer = HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	box.add_child(foot)
	_message = UiTheme.label("", 14, UiTheme.WARN)
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_message)
	_commit = Button.new()
	_commit.text = "Commit theory"
	_commit.pressed.connect(_on_commit)
	foot.add_child(_commit)
	var close: Button = Button.new()
	close.text = "Close (Tab)"
	close.pressed.connect(close_board)
	foot.add_child(close)
	hide()


func _column(parent: Container, heading: String) -> VBoxContainer:
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UiTheme.label(heading.to_upper(), 12, UiTheme.DIM))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	parent.add_child(col)
	return list


func open_board() -> void:
	_message.text = ""
	_refresh()
	show()


func close_board() -> void:
	hide()
	closed.emit()


func _refresh() -> void:
	for c: Node in _clue_list.get_children():
		c.queue_free()
	for c: Node in _theory_list.get_children():
		c.queue_free()
	if Case.clues.is_empty():
		_clue_list.add_child(UiTheme.label("No clues yet. Examine things and talk to people.", 13, UiTheme.DIM))
	for id: String in Case.clues:
		var clue: Clue = CaseCatalog.clue(id)
		var b: Button = _card("%s\n%s\n— %s" % [clue.title.to_upper(), clue.text, clue.source])
		b.toggle_mode = true
		b.button_pressed = _selected.has(id)
		b.toggled.connect(func(on: bool) -> void:
			if on and not _selected.has(id):
				_selected.append(id)
			elif not on:
				_selected.erase(id)
			_update_commit())
		_clue_list.add_child(b)
	var shown: Array[Theory] = Case.visible_theories()
	if shown.is_empty():
		_theory_list.add_child(UiTheme.label("Theories appear as you find clues.", 13, UiTheme.DIM))
	var group: ButtonGroup = ButtonGroup.new()
	for t: Theory in shown:
		var committed: bool = Case.has_fact(t.id)
		var b: Button = _card(("COMMITTED  " if committed else "") + t.statement)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = _theory == t.id
		if committed:
			b.add_theme_color_override("font_color", UiTheme.OK)
		var theory_id: String = t.id
		b.pressed.connect(func() -> void:
			_theory = theory_id
			_update_commit())
		_theory_list.add_child(b)
	_update_commit()


func _card(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 13)
	return b


func _update_commit() -> void:
	_commit.disabled = _theory == "" or _selected.is_empty() or Case.has_fact(_theory)


func _on_commit() -> void:
	var result: TheoryCheck.Result = Case.commit_theory(_theory, _selected)
	_message.add_theme_color_override("font_color", UiTheme.OK if result == TheoryCheck.Result.HOLDS else UiTheme.WARN)
	_message.text = result_line(_theory, result)
	if result == TheoryCheck.Result.HOLDS:
		_selected.clear()
	_refresh()


## What the board says after trying to commit `theory_id`. Shared with the art
## test's board, so both say the same thing.
static func result_line(theory_id: String, result: TheoryCheck.Result) -> String:
	if result != TheoryCheck.Result.HOLDS:
		return LINES[result]
	var t: Theory = CaseCatalog.theory(theory_id)
	var line: String = t.committed_line
	if t.id == "left":
		line += " The judge signs a warrant for his apartment." if Case.clearance else " The damage to your badge is done, though."
	return line


# _input, not _unhandled_input: Tab is also the GUI's focus-next key, and the
# board's buttons would swallow it.
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("case_board") or event.is_action_pressed("back")):
		get_viewport().set_input_as_handled()
		close_board()
