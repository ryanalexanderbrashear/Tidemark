class_name CaseTablet
extends Control
## The evidence tablet (decided, Alex, 2026-11-13; it replaced the cork case
## board): an old Tracer Bureau slate with a CRT-style screen. Every clue
## reaches it as a capture: a document he photographed, a statement it
## recorded, a frame from his optic or a reading. The player reviews them,
## picks the ones that back a theory, and files the theory with the precinct
## through `Case.commit_theory`. Filing is the one confirm; a theory holds with
## two or more clues that support it and nothing that doesn't, and a wrong one
## that holds is played out.
##
## Tabs: Captures (grouped by place), Statements (recordings), Timeline (a
## placeholder until the reconstruction is built) and Theories (pick one, then
## File). The first open boots with the maker's logo (any key skips); every
## other open is a quarter-second CRT power-on.
##
## Every capture looks alike, leftovers from someone else's memory included:
## the player has to judge them.
##
## Mouse: click a capture to view it, Pick it, choose a theory, then File.
## Keys: Q and E switch tabs, P picks the capture on screen, Tab, C or Esc
## closes.

signal closed
## A theory was filed and held.
signal committed(theory_id: String)

const P = preload("res://game/art/art_palette.gd")
const PH: Array[Color] = TabletArt.PH
enum Tab { CAPTURES, STATEMENTS, TIMELINE, THEORIES }
const TAB_NAMES: Array[String] = ["CAPTURES", "STATEMENTS", "TIMELINE", "THEORIES"]
const LINES: Dictionary[TheoryCheck.Result, String] = {
	TheoryCheck.Result.NOT_ENOUGH: "Not enough holds it up.",
	TheoryCheck.Result.DOESNT_FIT: "One of those doesn't fit.",
	TheoryCheck.Result.MISSING_SUBJECT: "You don't have what that theory is about yet.",
}
## Seconds the full boot runs, and the power-on every other time.
const BOOT_TIME: float = 1.5
const POWER_TIME: float = 0.25
## Screen regions, in native pixels of the 640x360 frame.
const STATUS_RECT: Rect2 = Rect2(46, 27, 548, 11)
const TABS_RECT: Rect2 = Rect2(46, 40, 548, 14)
const LIST_RECT: Rect2 = Rect2(46, 60, 176, 254)
const VIEW_RECT: Rect2 = Rect2(232, 60, 362, 254)
const FOOTER_RECT: Rect2 = Rect2(46, 318, 548, 12)
const PHOTO_SIZE: Vector2i = Vector2i(362, 112)
const THUMB_SIZE: Vector2i = Vector2i(40, 25)
const TIMELINE_NOTE: String = "RECONSTRUCTION\n\nThe night before the body, rebuilt one lane per person, isn't built yet. For now the times are in the captures themselves."

## Clues picked to back the theory.
var selected: Array[String] = []
## The theory picked to file.
var theory: String = ""
var tab: Tab = Tab.CAPTURES
## The clue on screen in Captures or Statements.
var viewing: String = ""
## Boot in full on the next open: the first open of a case (and, once there
## is a car, after a drive).
var boot_next_open: bool = true
## The setting that turns the full boot off. There's no settings menu yet.
var full_boot: bool = true

var _booting: float = 0.0
var _powering: float = 0.0
var _dim: ColorRect
var _frame: TextureRect
var _status: Label
var _clock: Label
var _tabs: Array[Button] = []
var _scroll: ScrollContainer
var _list: VBoxContainer
var _view: VBoxContainer
var _view_title: Label
var _view_meta: Label
var _photo: TextureRect
var _view_text: Label
var _pick: Button
var _file_panel: VBoxContainer
var _statement: Label
var _backed: Label
var _message: Label
var _file: Button
var _note: Label
var _footer: Label
var _boot: TextureRect
var _glass: TextureRect
var _power: Control
var _clue_cards: Dictionary[String, Button] = {}
var _theory_cards: Dictionary[String, Button] = {}
var _photos: Dictionary[String, ImageTexture] = {}
var _scale: int = 1
var _k: float = 1.0
var _offset: Vector2 = Vector2.ZERO
var _font_px: int = 16


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim = ColorRect.new()
	_dim.color = Color(P.INK, 0.72)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_frame = _image(TabletArt.frame())
	add_child(_frame)
	_status = _label(PH[2])
	_status.text = "TRACER BUREAU     CASE 1  ·  THE DROWNED MARKET"
	add_child(_status)
	_clock = _label(P.AMBER)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_clock)
	var group: ButtonGroup = ButtonGroup.new()
	for i: int in range(TAB_NAMES.size()):
		var b: Button = Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		var which: Tab = i as Tab
		b.pressed.connect(func() -> void: show_tab(which))
		_tabs.append(b)
		add_child(b)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_view = VBoxContainer.new()
	add_child(_view)
	_view_title = _label(PH[3])
	_view_meta = _label(PH[2])
	_photo = TextureRect.new()
	_photo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_SCALE
	_view_text = _label(PH[3])
	_pick = Button.new()
	_pick.toggle_mode = true
	_pick.focus_mode = Control.FOCUS_NONE
	_pick.toggled.connect(func(on: bool) -> void:
		if viewing != "":
			toggle_clue(viewing, on))
	for c: Control in [_view_title, _view_meta, _photo, _view_text, _pick]:
		_view.add_child(c)
	_file_panel = VBoxContainer.new()
	add_child(_file_panel)
	_statement = _label(PH[4])
	_backed = _label(PH[3])
	_message = _label(P.AMBER)
	_file = Button.new()
	_file.text = "FILE WITH THE PRECINCT"
	_file.focus_mode = Control.FOCUS_NONE
	_file.pressed.connect(commit)
	for c: Control in [_statement, _backed, _message, _file]:
		_file_panel.add_child(c)
	_note = _label(PH[3])
	_note.text = TIMELINE_NOTE
	add_child(_note)
	_footer = _label(PH[2])
	add_child(_footer)
	_boot = _image(TabletArt.boot())
	add_child(_boot)
	_glass = _image(TabletArt.glass())
	add_child(_glass)
	_power = Control.new()
	_power.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power.draw.connect(_draw_power)
	add_child(_power)
	hide()


func _label(c: Color) -> Label:
	var l: Label = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _image(img: Image) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = ImageTexture.create_from_image(img)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(maxi(1, _scale / 2))
	b.set_content_margin_all(3.0 * _k)
	return b


## Styles a button: `edge` for its border and `ink` for its text, filled with
## `fill`; hover brightens the border.
func _style(b: Button, fill: Color, edge: Color, ink: Color) -> void:
	for state: String in ["normal", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, _box(fill, edge))
	b.add_theme_stylebox_override("hover", _box(fill, PH[3] if edge != P.MAGENTA else P.MAGENTA))
	b.add_theme_stylebox_override("hover_pressed", _box(fill, PH[3] if edge != P.MAGENTA else P.MAGENTA))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_disabled_color", PH[1])


func is_open() -> bool:
	return visible


func is_booting() -> bool:
	return _booting > 0.0


func open() -> void:
	_message.text = ""
	refresh()
	show()
	if full_boot and boot_next_open:
		boot_next_open = false
		_booting = BOOT_TIME
		_boot.show()
	else:
		_boot.hide()
		_powering = POWER_TIME


## Ends the boot at once (any key does this).
func skip_boot() -> void:
	_booting = 0.0
	_powering = 0.0
	_boot.hide()
	_power.queue_redraw()


func close() -> void:
	skip_boot()
	hide()
	closed.emit()


func show_tab(t: Tab) -> void:
	tab = t
	if (t == Tab.CAPTURES or t == Tab.STATEMENTS) and not _clues_on(t).has(viewing):
		var ids: Array[String] = _clues_on(t)
		viewing = ids[0] if not ids.is_empty() else ""
	refresh()


## The clues a tab lists: statements on Statements, every other capture on
## Captures.
func _clues_on(t: Tab) -> Array[String]:
	var out: Array[String] = []
	for id: String in Case.clues:
		var statement: bool = TabletArt.kind(CaseCatalog.clue(id)) == TabletArt.Kind.STATEMENT
		if (t == Tab.STATEMENTS) == statement:
			out.append(id)
	return out


## Rebuilds the screen from the case.
func refresh() -> void:
	for c: Node in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_clue_cards.clear()
	_theory_cards.clear()
	_clock.text = "CASE CLOCK " + Case.clock_text(Case.minutes)
	for i: int in range(_tabs.size()):
		var n: int = _clues_on(i as Tab).size() if i <= Tab.STATEMENTS else 0
		_tabs[i].text = TAB_NAMES[i] + ("  %d" % n if n > 0 else "")
		_tabs[i].set_pressed_no_signal(i == tab)
		_style(_tabs[i], PH[3] if i == tab else PH[0], PH[3] if i == tab else PH[1], PH[0] if i == tab else PH[2])
	var lists: bool = tab != Tab.TIMELINE
	_scroll.visible = lists
	_view.visible = tab == Tab.CAPTURES or tab == Tab.STATEMENTS
	_file_panel.visible = tab == Tab.THEORIES
	_note.visible = tab == Tab.TIMELINE
	match tab:
		Tab.CAPTURES, Tab.STATEMENTS:
			_fill_clues()
		Tab.THEORIES:
			_fill_theories()
	_footer.text = "Q / E  TABS     P  PICK     TAB  CLOSE          PICKED %d" % selected.size()
	_restyle()


func _fill_clues() -> void:
	var ids: Array[String] = _grouped(_clues_on(tab))
	if ids.is_empty():
		_list.add_child(_small(_label(PH[2]), "Nothing here yet. Look at things, talk to people, turn things over."))
	if viewing == "" or not ids.has(viewing):
		viewing = ids[0] if not ids.is_empty() else ""
	var place: String = ""
	for id: String in ids:
		var clue: Clue = CaseCatalog.clue(id)
		if clue.source != place:
			place = clue.source
			_list.add_child(_small(_label(PH[2]), place.to_upper()))
		var card: Button = Button.new()
		card.text = clue.title
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.focus_mode = Control.FOCUS_NONE
		card.icon = _photo_of(clue, THUMB_SIZE)
		card.expand_icon = true
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var picked: bool = selected.has(id)
		var edge: Color = P.MAGENTA if picked else (PH[3] if id == viewing else PH[1])
		_style(card, PH[0], edge, P.MAGENTA if picked else PH[3])
		card.pressed.connect(func() -> void: view_clue(id))
		_clue_cards[id] = card
		_list.add_child(card)
	_show_viewing()


## `ids` with each place's captures together, places in the order first found.
func _grouped(ids: Array[String]) -> Array[String]:
	var places: Array[String] = []
	var by_place: Dictionary[String, Array] = {}
	for id: String in ids:
		var place: String = CaseCatalog.clue(id).source
		if not by_place.has(place):
			places.append(place)
			by_place[place] = []
		by_place[place].append(id)
	var out: Array[String] = []
	for place: String in places:
		for id: String in by_place[place]:
			out.append(id)
	return out


func _show_viewing() -> void:
	if viewing == "":
		_view_title.text = ""
		_view_meta.text = ""
		_view_text.text = ""
		_photo.texture = null
		_pick.visible = false
		return
	var clue: Clue = CaseCatalog.clue(viewing)
	var k: TabletArt.Kind = TabletArt.kind(clue)
	_view_title.text = clue.title.to_upper()
	_view_meta.text = "%s  ·  %s" % [["PHOTO", "RECORDING", "RECALL FRAME (WEAKER)", "THERMAL FRAME", "FOOTAGE"][k], clue.source.to_upper()]
	_photo.texture = _photo_of(clue, PHOTO_SIZE)
	_view_text.text = clue.text
	_pick.visible = true
	var picked: bool = selected.has(viewing)
	_pick.set_pressed_no_signal(picked)
	_pick.text = "PICKED TO BACK A THEORY" if picked else "PICK TO BACK A THEORY  (P)"
	_style(_pick, Color(P.MAGENTA, 0.18) if picked else PH[0], P.MAGENTA if picked else PH[2], P.MAGENTA if picked else PH[3])


func _photo_of(clue: Clue, size: Vector2i) -> ImageTexture:
	var key: String = "%s@%d" % [clue.id, size.x]
	if not _photos.has(key):
		_photos[key] = ImageTexture.create_from_image(TabletArt.photo(clue, size.x, size.y))
	return _photos[key]


func _fill_theories() -> void:
	var shown: Array[Theory] = Case.visible_theories()
	if shown.is_empty():
		_list.add_child(_small(_label(PH[2]), "Theories appear as you find clues."))
	var group: ButtonGroup = ButtonGroup.new()
	for t: Theory in shown:
		var fact: bool = Case.has_fact(t.id)
		var card: Button = Button.new()
		card.text = ("FILED  " if fact else "") + t.statement
		card.toggle_mode = true
		card.button_group = group
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.focus_mode = Control.FOCUS_NONE
		card.set_pressed_no_signal(theory == t.id)
		var on: bool = theory == t.id
		_style(card, Color(P.MAGENTA, 0.14) if on else PH[0], P.MAGENTA if on else (P.AMBER_DIM if fact else PH[1]), P.AMBER if fact else PH[3])
		var theory_id: String = t.id
		card.pressed.connect(func() -> void: pick_theory(theory_id))
		_theory_cards[t.id] = card
		_list.add_child(card)
	var picked: Theory = CaseCatalog.theory(theory) if theory != "" else null
	_statement.text = picked.statement if picked != null else "Pick a theory."
	var titles: Array[String] = []
	for id: String in selected:
		titles.append("·  " + CaseCatalog.clue(id).title)
	_backed.text = "BACKED BY\n" + ("\n".join(titles) if not titles.is_empty() else "Nothing picked. Pick captures or statements to back it.")
	_file.disabled = not can_commit()
	_style(_file, PH[0], P.MAGENTA if can_commit() else PH[1], P.MAGENTA if can_commit() else PH[1])


func _small(l: Label, text: String) -> Label:
	l.text = text
	return l


## Shows `id` in the viewer.
func view_clue(id: String) -> void:
	viewing = id
	refresh()


func toggle_clue(id: String, on: bool) -> void:
	if on and not selected.has(id):
		selected.append(id)
	elif not on:
		selected.erase(id)
	if visible:
		refresh()


func pick_theory(id: String) -> void:
	theory = id
	if visible:
		refresh()


func can_commit() -> bool:
	return theory != "" and not selected.is_empty() and not Case.has_fact(theory)


## Files the picked theory with the picked clues, through the case.
func commit() -> TheoryCheck.Result:
	if not can_commit():
		return TheoryCheck.Result.NOT_ENOUGH
	var tried: String = theory
	var result: TheoryCheck.Result = Case.commit_theory(tried, selected)
	var holds: bool = result == TheoryCheck.Result.HOLDS
	if holds:
		selected.clear()
		committed.emit(tried)
	refresh()
	_message.add_theme_color_override("font_color", P.AMBER if holds else PH[3])
	_message.text = result_line(tried, result)
	return result


# _input, not _unhandled_input: Tab is also the GUI's focus-next key.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key: InputEventKey = event as InputEventKey
	var pressed: bool = key != null and key.pressed and not key.echo
	if is_booting():
		if pressed or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
			skip_boot()
			get_viewport().set_input_as_handled()
		return
	var closing: bool = pressed and key.physical_keycode in [KEY_TAB, KEY_ESCAPE]
	if closing or event.is_action_pressed("case_board") or event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		close()
	elif pressed and key.physical_keycode in [KEY_Q, KEY_E]:
		get_viewport().set_input_as_handled()
		show_tab(wrapi(tab + (1 if key.physical_keycode == KEY_E else -1), 0, TAB_NAMES.size()) as Tab)
	elif pressed and key.physical_keycode == KEY_P and viewing != "" and _view.visible:
		get_viewport().set_input_as_handled()
		toggle_clue(viewing, not selected.has(viewing))


func _process(delta: float) -> void:
	if _booting > 0.0:
		_booting -= delta
		if _booting <= 0.0:
			skip_boot()
	if _powering > 0.0:
		_powering = maxf(0.0, _powering - delta)
		_power.queue_redraw()


## The CRT power-on: a bright line, the picture opening out of it, then one
## overexposed flash.
func _draw_power() -> void:
	if _powering <= 0.0:
		return
	var r: Rect2 = Rect2(_offset + Vector2(TabletArt.SCREEN.position) * _k, Vector2(TabletArt.SCREEN.size) * _k)
	var t: float = 1.0 - _powering / POWER_TIME
	if t < 0.35:
		_power.draw_rect(r, PH[0])
		var lw: float = r.size.x * 0.6
		_power.draw_rect(Rect2(r.position.x + (r.size.x - lw) / 2.0, r.get_center().y - _k, lw, 2.0 * _k), PH[4])
	elif t < 0.75:
		var band: float = r.size.y * (t - 0.35) / 0.4
		var top: float = r.get_center().y - band / 2.0
		_power.draw_rect(Rect2(r.position, Vector2(r.size.x, top - r.position.y)), PH[0])
		_power.draw_rect(Rect2(Vector2(r.position.x, top + band), Vector2(r.size.x, r.end.y - top - band)), PH[0])
	else:
		_power.draw_rect(r, Color(PH[4], 0.45 * (1.0 - (t - 0.75) / 0.25)))


# ---------- layout ----------

## Puts the tablet on the game's pixel grid: `native` is the game's
## resolution, shown at whole-number `scale` from `offset`.
func layout(native: Vector2i, scale: int, offset: Vector2) -> void:
	_scale = scale
	_offset = offset
	var win: Vector2 = Vector2(get_window().size)
	position = Vector2.ZERO
	size = win
	_dim.position = Vector2.ZERO
	_dim.size = win
	# The tablet is drawn for 640x360; at 480x270 it's shown at the same size.
	_k = float(scale) * float(native.x) / 640.0
	_font_px = roundi(win.y / 46.0)
	for t: TextureRect in [_frame, _glass]:
		t.position = offset
		t.size = Vector2(640, 360) * _k
	_place(_boot, Rect2(TabletArt.SCREEN))
	_place(_power, Rect2(0, 0, 640, 360))
	_power.position = Vector2.ZERO
	_power.size = win
	_place(_status, STATUS_RECT)
	_place(_clock, STATUS_RECT)
	var x: float = TABS_RECT.position.x
	for b: Button in _tabs:
		_place(b, Rect2(x, TABS_RECT.position.y, 92, TABS_RECT.size.y))
		x += 96
	_place(_scroll, LIST_RECT)
	_place(_view, VIEW_RECT)
	_place(_file_panel, VIEW_RECT)
	_place(_note, Rect2(LIST_RECT.position, Vector2(VIEW_RECT.end.x - LIST_RECT.position.x, LIST_RECT.size.y)))
	_place(_footer, FOOTER_RECT)
	_photo.custom_minimum_size = Vector2(PHOTO_SIZE) * _k
	refresh()


func _place(c: Control, r: Rect2) -> void:
	c.position = _offset + r.position * _k
	c.size = r.size * _k


func _restyle() -> void:
	if _list == null:
		return
	var tiny: int = maxi(9, roundi(_font_px * 0.55))
	var small: int = maxi(10, roundi(_font_px * 0.68))
	for l: Label in [_status, _clock, _footer, _view_meta]:
		l.add_theme_font_size_override("font_size", tiny)
	for l: Label in [_view_text, _backed, _message, _note]:
		l.add_theme_font_size_override("font_size", small)
	for l: Label in [_view_title, _statement]:
		l.add_theme_font_size_override("font_size", roundi(_font_px * 0.9))
	for b: Button in _tabs + [_pick, _file]:
		b.add_theme_font_size_override("font_size", tiny)
	var gap: int = maxi(3, roundi(3.0 * _k))
	_list.add_theme_constant_override("separation", gap)
	_view.add_theme_constant_override("separation", gap)
	_file_panel.add_theme_constant_override("separation", gap * 2)
	for c: Node in _list.get_children():
		var b: Button = c as Button
		var l: Label = c as Label
		if b != null:
			b.add_theme_font_size_override("font_size", small)
			b.add_theme_constant_override("icon_max_width", roundi(THUMB_SIZE.x * _k))
			b.custom_minimum_size = Vector2(LIST_RECT.size.x * _k - gap * 3, THUMB_SIZE.y * _k + 6.0 * _k if b.icon != null else 0.0)
		elif l != null:
			l.add_theme_font_size_override("font_size", tiny)
			l.custom_minimum_size = Vector2(LIST_RECT.size.x * _k - gap * 3, 0)


## What the tablet says after filing `theory_id`.
static func result_line(theory_id: String, result: TheoryCheck.Result) -> String:
	if result != TheoryCheck.Result.HOLDS:
		return LINES[result]
	var t: Theory = CaseCatalog.theory(theory_id)
	var line: String = t.committed_line
	if t.id == "left":
		line += " The judge signs a warrant for his apartment." if Case.clearance else " The damage to your badge is done, though."
	return line
