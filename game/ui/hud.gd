class_name Hud
extends Control
## Top bar (clock, badge, health, optic, symptoms, room) and the toast line at the bottom.

const TOAST_SECONDS: float = 3.6
const THOUGHT: Color = Color("c9b6ff")
const TIER_COLORS: Array[Color] = [UiTheme.DIM, UiTheme.WARN, Color("ff8a5a"), UiTheme.BAD]

var detective: Detective
var room_title: String = ""
var _bar: Label
var _badge: Label
var _hp: Label
var _optic: Label
var _mind: Label
var _room: Label
var _toast: Label
var _toast_left: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back: ColorRect = ColorRect.new()
	back.color = Color(0.03, 0.05, 0.08, 0.85)
	back.position = Vector2.ZERO
	back.size = Vector2(960, 32)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(12, 5)
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	_bar = UiTheme.label("", 15, UiTheme.WARN)
	_badge = UiTheme.label("", 15)
	_hp = UiTheme.label("", 15, UiTheme.NEON)
	_optic = UiTheme.label("", 15)
	_mind = UiTheme.label("", 15)
	_room = UiTheme.label("", 13, UiTheme.DIM)
	for l: Label in [_bar, _badge, _hp, _optic, _mind, _room]:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(l)
	_toast = UiTheme.label("", 14)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(80, 490)
	_toast.size = Vector2(800, 40)
	add_child(_toast)
	var help: Label = UiTheme.label("Tab: case board   Q: take a pill", 12, UiTheme.DIM)
	help.autowrap_mode = TextServer.AUTOWRAP_OFF
	help.position = Vector2(740, 518)
	add_child(help)


func toast(text: String) -> void:
	_toast.add_theme_color_override("font_color", UiTheme.TEXT)
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS


## The detective's inner voice: text only, set apart from the toast's notices.
func thought(text: String) -> void:
	_toast.add_theme_color_override("font_color", THOUGHT)
	_toast.text = "\u201c" + text + "\u201d"
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			_toast.modulate.a = 0.0
	if Case.has_beat("second_victim"):
		_bar.text = "%s  KILLER STRUCK AGAIN" % Case.clock_text(Case.minutes)
		_bar.add_theme_color_override("font_color", UiTheme.BAD)
	else:
		_bar.text = Case.clock_text(Case.minutes)
		_bar.add_theme_color_override("font_color", UiTheme.WARN)
	_badge.text = "BADGE " + ("ACTIVE" if Case.clearance else "REVOKED")
	_badge.add_theme_color_override("font_color", UiTheme.OK if Case.clearance else UiTheme.BAD)
	if detective != null:
		_hp.text = "HP " + "■".repeat(detective.hp) + "□".repeat(Detective.MAX_HP - detective.hp)
	_optic.text = "OPTIC " + ("ON" if Case.optic_on else ("off" if Case.has_optic else "--"))
	_optic.add_theme_color_override("font_color", Color("ff7a2f") if Case.optic_on else (UiTheme.TEXT if Case.has_optic else UiTheme.DIM))
	var lvl: int = Mind.level()
	_mind.text = "BLEED %d/%d  PILLS %d" % [lvl, Mind.tuning.bleed_max, Mind.pills]
	_mind.add_theme_color_override("font_color", TIER_COLORS[Mind.tier()])
	_room.text = room_title
