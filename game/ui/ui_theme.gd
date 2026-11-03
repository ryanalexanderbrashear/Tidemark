class_name UiTheme
extends RefCounted
## The prototype's one UI theme: dark panels, neon accents, plain buttons.

const INK: Color = Color("0b0f17")
const PANEL: Color = Color("121a26")
const LINE: Color = Color("2a3a50")
const TEXT: Color = Color("d7e2ee")
const DIM: Color = Color("7f93aa")
const NEON: Color = Color("3ee6d0")
const WARN: Color = Color("ffb347")
const BAD: Color = Color("ff5a6e")
const OK: Color = Color("7cf29a")


static func make() -> Theme:
	var t: Theme = Theme.new()
	t.default_font_size = 15
	var panel: StyleBoxFlat = _box(PANEL, LINE)
	panel.set_content_margin_all(16)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("normal", "Button", _box(Color("1a2636"), LINE))
	t.set_stylebox("hover", "Button", _box(Color("1f2e40"), NEON))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), NEON))
	t.set_stylebox("pressed", "Button", _box(Color("2a2110"), WARN))
	t.set_stylebox("disabled", "Button", _box(Color("141c27"), LINE))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", DIM)
	t.set_color("font_color", "Label", TEXT)
	return t


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(1)
	b.set_content_margin_all(8)
	return b


static func label(text: String, size: int = 15, color: Color = TEXT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A centered modal panel of the given width, inside a full-screen dimmer.
static func modal(width: float) -> Array[Control]:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	return [dim, box]
