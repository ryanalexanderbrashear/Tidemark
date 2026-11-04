class_name BleedOverlay
extends Control
## Bleed-through on screen: the room flickers and tears more as the felt symptom
## level rises, and at severe a figure that isn't there shows for a moment.
## Grey-box stand-in for the full-screen effect the Look and Feel doc proposes.

const SIZE: Vector2 = Vector2(960, 540)
const FIGURE: Color = Color(0.82, 0.88, 1.0)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next: float = 0.0
var _tears: Array[Rect2] = []
var _figure_x: float = -1.0
var _wash: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_next -= delta
	if _next > 0.0:
		return
	var tier: int = Mind.tier()
	_tears.clear()
	_figure_x = -1.0
	_wash = 0.0
	_next = _rng.randf_range(0.08, 0.2)
	if tier > MindState.Tier.CLEAR and _rng.randf() < 0.12 * tier:
		_wash = 0.04 * tier
		for i: int in _rng.randi_range(0, tier * 2):
			var h: float = _rng.randf_range(2.0, 6.0 + 6.0 * tier)
			_tears.append(Rect2(0, _rng.randf_range(40.0, SIZE.y - 20.0), SIZE.x, h))
		if tier == MindState.Tier.SEVERE and _rng.randf() < 0.35:
			_figure_x = _rng.randf_range(120.0, SIZE.x - 120.0)
	else:
		_next = _rng.randf_range(0.6, 2.4 - 0.4 * tier)
	queue_redraw()


func _draw() -> void:
	var tier: int = Mind.tier()
	if tier == MindState.Tier.CLEAR:
		return
	# A cold edge that closes in with the tier.
	var edge: float = 18.0 * tier
	var shade: Color = Color(0.25, 0.35, 0.6, 0.06 * tier)
	draw_rect(Rect2(0, 0, SIZE.x, edge), shade)
	draw_rect(Rect2(0, SIZE.y - edge, SIZE.x, edge), shade)
	draw_rect(Rect2(0, 0, edge, SIZE.y), shade)
	draw_rect(Rect2(SIZE.x - edge, 0, edge, SIZE.y), shade)
	if _wash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.7, 0.8, 1.0, _wash))
	for r: Rect2 in _tears:
		draw_rect(r, Color(0.75, 0.85, 1.0, 0.12))
		draw_rect(Rect2(r.position + Vector2(_rng.randf_range(-12, 12), 0), Vector2(r.size.x, 1)), Color(1, 0.35, 0.45, 0.25))
	if _figure_x >= 0.0:
		var c: Color = Color(FIGURE, 0.18)
		draw_rect(Rect2(_figure_x - 12, 404, 24, 66), c)
		draw_circle(Vector2(_figure_x, 392), 11.0, c)
