class_name CaseBoard
extends Control
## The case board: the clues pinned as paper cards on a cork board under a
## lamp, the theories down the right, and amber string run from each clue
## picked to the theory it's meant to hold up. Pick the clues that back a
## theory, then commit it; it goes through `Case.commit_theory`. A theory holds
## with two or more clues that support it and nothing that doesn't. A failed
## chain just doesn't hold. A wrong theory can still hold, and the game plays
## it out.
##
## Every clue card looks the same, leftovers from someone else's memory
## included: the player has to judge them.
##
## Mouse: click clues and a theory, then Commit. Tab, C or Esc closes.

signal closed
## A theory was committed and held.
signal committed(theory_id: String)

const P = preload("res://game/art/art_palette.gd")
const LINES: Dictionary[TheoryCheck.Result, String] = {
	TheoryCheck.Result.NOT_ENOUGH: "Not enough holds it up.",
	TheoryCheck.Result.DOESNT_FIT: "One of those doesn't fit.",
	TheoryCheck.Result.MISSING_SUBJECT: "You don't have what that theory is about yet.",
}
const PAPER: Color = Color("a9a596")
const PAPER_PICKED: Color = Color("c4bfae")
const CARD_INK: Color = Color("0b0f17")
const THEORY: Color = Color("222c3a")
const FACT: Color = Color("33302a")
const TEXT: Color = Color("d4dce6")
## Board regions, in native pixels of the 640x360 frame.
const CLUES_RECT: Rect2 = Rect2(26, 46, 386, 250)
const THEORIES_RECT: Rect2 = Rect2(426, 46, 188, 244)
const MESSAGE_RECT: Rect2 = Rect2(26, 302, 430, 26)
const COMMIT_RECT: Rect2 = Rect2(474, 300, 140, 22)

var selected: Array[String] = []
var theory: String = ""

var _bg: TextureRect
var _dim: ColorRect
var _title: Label
var _clock: Label
var _scroll: ScrollContainer
var _grid: GridContainer
var _theories: VBoxContainer
var _message: Label
var _commit: Button
var _hint: Label
var _strings: Control
var _clue_cards: Dictionary[String, Button] = {}
var _theory_cards: Dictionary[String, Button] = {}
var _scale: int = 1
var _offset: Vector2 = Vector2.ZERO
var _font_px: int = 16


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim = ColorRect.new()
	_dim.color = Color(P.INK, 0.82)
	add_child(_dim)
	_bg = TextureRect.new()
	_bg.texture = ImageTexture.create_from_image(board_image())
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_bg)
	_title = _label(P.RAIN)
	_title.text = "CASE BOARD  ·  THE DROWNED MARKET"
	add_child(_title)
	_clock = _label(P.AMBER)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_clock)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_grid)
	_theories = VBoxContainer.new()
	add_child(_theories)
	_message = _label(P.AMBER)
	add_child(_message)
	_commit = Button.new()
	_commit.text = "Commit theory"
	_commit.pressed.connect(commit)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		_commit.add_theme_stylebox_override(state, _box(THEORY if state != "hover" else Color("2c394b"), P.AMBER if state in ["hover", "focus"] else P.AMBER_DIM, 1))
	_commit.add_theme_color_override("font_color", P.AMBER)
	_commit.add_theme_color_override("font_hover_color", P.AMBER)
	_commit.add_theme_color_override("font_disabled_color", Color(P.RAIN, 0.4))
	add_child(_commit)
	_hint = _label(Color(P.RAIN, 0.75))
	_hint.text = "Click the clues that back a theory, pick the theory, then commit.   Tab or Esc closes"
	add_child(_hint)
	_strings = Control.new()
	_strings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strings.draw.connect(_draw_strings)
	add_child(_strings)
	hide()


func _label(c: Color) -> Label:
	var l: Label = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(width)
	b.set_content_margin_all(6)
	return b


func is_open() -> bool:
	return visible


func open() -> void:
	_message.text = ""
	refresh()
	show()


func close() -> void:
	hide()
	closed.emit()


## Rebuilds the cards from the case.
func refresh() -> void:
	for c: Node in _grid.get_children() + _theories.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	_clue_cards.clear()
	_theory_cards.clear()
	_clock.text = "Case clock " + Case.clock_text(Case.minutes)
	if Case.clues.is_empty():
		_grid.add_child(_note("No clues yet. Look at things, talk to people, turn things over."))
	for id: String in Case.clues:
		var clue: Clue = CaseCatalog.clue(id)
		var card: Button = _card("%s\n%s\n— %s" % [clue.title.to_upper(), clue.text, clue.source])
		card.button_pressed = selected.has(id)
		card.toggled.connect(func(on: bool) -> void: toggle_clue(id, on))
		_clue_cards[id] = card
		_grid.add_child(card)
	var shown: Array[Theory] = Case.visible_theories()
	if shown.is_empty():
		_theories.add_child(_note("Theories appear as you find clues."))
	var group: ButtonGroup = ButtonGroup.new()
	for t: Theory in shown:
		var fact: bool = Case.has_fact(t.id)
		var card: Button = _theory_card(("FACT  " if fact else "") + t.statement, fact)
		card.button_group = group
		card.button_pressed = theory == t.id
		var theory_id: String = t.id
		card.pressed.connect(func() -> void: pick_theory(theory_id))
		_theory_cards[t.id] = card
		_theories.add_child(card)
	_restyle()
	_update_commit()


func _note(text: String) -> Label:
	var l: Label = _label(Color(P.RAIN, 0.8))
	l.text = text
	l.custom_minimum_size = Vector2(CLUES_RECT.size.x * 0.9 * _scale, 0)
	return l


func _card(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.toggle_mode = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_stylebox_override("normal", _box(PAPER, Color("6b685d"), 1))
	b.add_theme_stylebox_override("hover", _box(PAPER_PICKED, Color("6b685d"), 1))
	b.add_theme_stylebox_override("pressed", _box(PAPER_PICKED, P.AMBER, 2))
	b.add_theme_stylebox_override("hover_pressed", _box(PAPER_PICKED, P.AMBER, 2))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), P.AMBER_DIM, 1))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, CARD_INK)
	return b


func _theory_card(text: String, fact: bool) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.toggle_mode = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fill: Color = FACT if fact else THEORY
	var edge: Color = P.AMBER_DIM if fact else P.SLATE
	b.add_theme_stylebox_override("normal", _box(fill, edge, 1))
	b.add_theme_stylebox_override("hover", _box(fill.lightened(0.08), edge, 1))
	b.add_theme_stylebox_override("pressed", _box(fill.lightened(0.08), P.AMBER, 2))
	b.add_theme_stylebox_override("hover_pressed", _box(fill.lightened(0.08), P.AMBER, 2))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), P.AMBER_DIM, 1))
	var c: Color = P.AMBER if fact else TEXT
	for name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(name, c)
	return b


func toggle_clue(id: String, on: bool) -> void:
	if on and not selected.has(id):
		selected.append(id)
	elif not on:
		selected.erase(id)
	_update_commit()


func pick_theory(id: String) -> void:
	theory = id
	_update_commit()


func can_commit() -> bool:
	return theory != "" and not selected.is_empty() and not Case.has_fact(theory)


func _update_commit() -> void:
	_commit.disabled = not can_commit()
	_strings.queue_redraw()


## Tries the picked theory with the picked clues, through the case.
func commit() -> TheoryCheck.Result:
	if not can_commit():
		return TheoryCheck.Result.NOT_ENOUGH
	var tried: String = theory
	var result: TheoryCheck.Result = Case.commit_theory(tried, selected)
	var holds: bool = result == TheoryCheck.Result.HOLDS
	_message.add_theme_color_override("font_color", P.AMBER if holds else P.RAIN)
	_message.text = result_line(tried, result)
	if holds:
		selected.clear()
		committed.emit(tried)
	refresh()
	return result


# _input, not _unhandled_input: Tab is also the GUI's focus-next key, and the
# board's buttons would swallow it.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key: InputEventKey = event as InputEventKey
	var closing: bool = key != null and key.pressed and not key.echo and key.physical_keycode in [KEY_TAB, KEY_ESCAPE]
	if closing or event.is_action_pressed("case_board") or event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		close()


func _process(_delta: float) -> void:
	if visible:
		# Cards move when the list scrolls; the string follows them.
		_strings.queue_redraw()


## String from each picked clue's pin to the picked theory's pin, and a pin
## on every card.
func _draw_strings() -> void:
	var clip: Rect2 = _scroll.get_global_rect()
	var k: float = float(_scale)
	var to: Vector2 = Vector2.INF
	if _theory_cards.has(theory):
		var r: Rect2 = _theory_cards[theory].get_global_rect()
		to = Vector2(r.position.x, r.get_center().y) - _strings.global_position
	for id: String in _clue_cards:
		var r: Rect2 = _clue_cards[id].get_global_rect()
		var pin: Vector2 = Vector2(r.get_center().x, r.position.y + 3.0 * k)
		if not clip.has_point(pin):
			continue
		var at: Vector2 = pin - _strings.global_position
		if selected.has(id) and to != Vector2.INF:
			_strings.draw_polyline(_string(at, to), Color(P.AMBER, 0.85), maxf(1.0, k))
		_strings.draw_rect(Rect2(at - Vector2(k, k), Vector2(2.0 * k, 2.0 * k)), P.AMBER if selected.has(id) else P.STEEL)
	for id: String in _theory_cards:
		var r: Rect2 = _theory_cards[id].get_global_rect()
		var at: Vector2 = Vector2(r.position.x, r.get_center().y) - _strings.global_position
		_strings.draw_rect(Rect2(at - Vector2(k, k), Vector2(2.0 * k, 2.0 * k)), P.AMBER if id == theory else P.STEEL)


## A string pinned at both ends, sagging under its own weight.
func _string(from: Vector2, to: Vector2) -> PackedVector2Array:
	var sag: float = from.distance_to(to) * 0.12 + 6.0 * float(_scale)
	var pts: PackedVector2Array = []
	for i: int in range(17):
		var t: float = float(i) / 16.0
		pts.append(from.lerp(to, t) + Vector2(0, sag * 4.0 * t * (1.0 - t)))
	return pts


# ---------- layout ----------

## Puts the board on the game's pixel grid: `native` is the game's
## resolution, shown at whole-number `scale` from `offset`.
func layout(native: Vector2i, scale: int, offset: Vector2) -> void:
	_scale = scale
	_offset = offset
	var win: Vector2 = Vector2(get_window().size)
	position = Vector2.ZERO
	size = win
	_dim.position = Vector2.ZERO
	_dim.size = win
	# The board is drawn for 640x360; at 480x270 it's shown at the same size.
	var k: float = float(scale) * float(native.x) / 640.0
	_bg.position = offset
	_bg.size = Vector2(640, 360) * k
	_font_px = roundi(win.y / 46.0)
	_place(_title, Rect2(26, 12, 400, 20), k)
	_place(_clock, Rect2(430, 12, 184, 20), k)
	_place(_scroll, CLUES_RECT, k)
	_place(_theories, THEORIES_RECT, k)
	_place(_message, MESSAGE_RECT, k)
	_place(_commit, COMMIT_RECT, k)
	_place(_hint, Rect2(16, 340, 608, 16), k)
	_restyle()


func _place(c: Control, r: Rect2, k: float) -> void:
	c.position = _offset + r.position * k
	c.size = r.size * k


func _restyle() -> void:
	if _grid == null:
		return
	var small: int = maxi(10, roundi(_font_px * 0.7))
	for l: Label in [_title, _clock]:
		l.add_theme_font_size_override("font_size", roundi(_font_px * 0.9))
	_message.add_theme_font_size_override("font_size", small)
	_hint.add_theme_font_size_override("font_size", maxi(10, roundi(_font_px * 0.6)))
	_commit.add_theme_font_size_override("font_size", small)
	var gap: int = maxi(4, _scale * 4)
	_grid.add_theme_constant_override("h_separation", gap)
	_grid.add_theme_constant_override("v_separation", gap)
	_theories.add_theme_constant_override("separation", gap)
	var card_w: float = (_scroll.size.x - gap * 3.0) / 3.0
	for c: Node in _grid.get_children():
		var b: Button = c as Button
		if b != null:
			b.add_theme_font_size_override("font_size", small)
			b.custom_minimum_size = Vector2(card_w, 0)
	for c: Node in _theories.get_children():
		var b: Button = c as Button
		if b != null:
			b.add_theme_font_size_override("font_size", small)
			b.custom_minimum_size = Vector2(_theories.size.x, 0)


# ---------- art ----------

## The board behind the cards: a dark wall, a framed cork board under a lamp,
## at 640x360.
static func board_image() -> Image:
	var img: Image = Px.blank(640, 360)
	Px.vgrad(img, 0, 0, 640, 360, P.NIGHT, P.INK, 4)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1407
	# Frame and cork.
	Px.rect(img, 14, 36, 612, 298, Color("120f0d"))
	Px.rect(img, 17, 39, 606, 292, Color("2b241f"))
	for i: int in range(5200):
		var x: int = rng.randi_range(17, 622)
		var y: int = rng.randi_range(39, 330)
		Px.dot(img, x, y, Color("352c25") if rng.randf() < 0.55 else Color("221c18"))
	# The theories hang on a strip of their own.
	Px.rect(img, 420, 40, 1, 290, Color("1a1512"))
	# Lamp over the board.
	Px.rect(img, 300, 0, 40, 4, Color("0c0f14"))
	Px.rect(img, 312, 4, 16, 2, P.AMBER)
	Px.glow(img, 320, 60, 300, 140, P.AMBER, 0.12)
	Px.glow(img, 320, 6, 30, 8, P.AMBER, 0.3)
	return img


## What the board says after trying to commit `theory_id`.
static func result_line(theory_id: String, result: TheoryCheck.Result) -> String:
	if result != TheoryCheck.Result.HOLDS:
		return LINES[result]
	var t: Theory = CaseCatalog.theory(theory_id)
	var line: String = t.committed_line
	if t.id == "left":
		line += " The judge signs a warrant for his apartment." if Case.clearance else " The damage to your badge is done, though."
	return line
