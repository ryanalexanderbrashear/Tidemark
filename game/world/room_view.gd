class_name RoomView
extends Node2D
## Grey-box drawing for one room: sky and skyline (parallax), floor, ledges, the
## room's spots and the prompt over the nearest one. Placeholder art only.

const VIEW: Vector2 = Vector2(960, 540)
const FLOOR_Y: float = 470.0
const NEON: Array[Color] = [Color("3ee6d0"), Color("ff4fa0"), Color("ffb347")]

var room: RoomDef
var spots: Array[Spot] = []
var nearest: Spot
var camera_x: float = 0.0
var _clock: float = 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


static func draw_person(on: CanvasItem, at: Vector2, color: Color, hostile: bool) -> void:
	on.draw_rect(Rect2(at + Vector2(-10, -44), Vector2(20, 30)), color)
	on.draw_rect(Rect2(at + Vector2(-8, -14), Vector2(6, 14)), color)
	on.draw_rect(Rect2(at + Vector2(2, -14), Vector2(6, 14)), color)
	on.draw_circle(at + Vector2(0, -52), 8.0, color)
	if hostile:
		on.draw_rect(Rect2(at + Vector2(-5, -55), Vector2(10, 3)), Color("220000"))


static func _hash(i: float) -> float:
	var v: float = sin(i * 127.1) * 43758.5453
	return v - floorf(v)


func _draw() -> void:
	if room == null:
		return
	_draw_sky()
	draw_rect(Rect2(0, FLOOR_Y, room.width, VIEW.y - FLOOR_Y), room.floor_color)
	draw_rect(Rect2(0, FLOOR_Y, room.width, 2), Color(0.24, 0.9, 0.82, 0.25))
	if room.water:
		var x: float = 0.0
		while x < room.width:
			draw_rect(Rect2(x, FLOOR_Y + 18.0 + sin(_clock * 2.0 + x * 0.05) * 3.0, 30, 3), Color(0.12, 0.35, 0.43, 0.5))
			x += 40.0
	if room.limit > 0.0:
		draw_rect(Rect2(room.limit - 20.0, FLOOR_Y - 40.0, room.width, VIEW.y), Color(0.08, 0.31, 0.43, 0.8))
	for l: Rect2 in room.ledges:
		draw_rect(Rect2(l.position.x + 6, l.position.y + 10, 6, FLOOR_Y - l.position.y - 10), Color(0.16, 0.23, 0.31, 0.5))
		draw_rect(Rect2(l.end.x - 12, l.position.y + 10, 6, FLOOR_Y - l.position.y - 10), Color(0.16, 0.23, 0.31, 0.5))
		draw_rect(l, Color("2a3a50"))
		draw_rect(Rect2(l.position, Vector2(l.size.x, 2)), Color(0.24, 0.9, 0.82, 0.4))
	if room.id == "market":
		# The heat-sealed door is just wall until the optic shows it.
		draw_rect(Rect2(2200, FLOOR_Y - 160, 190, 160), Color("253038"))
		var y: float = FLOOR_Y - 160.0
		while y < FLOOR_Y:
			draw_rect(Rect2(2200, y, 190, 2), Color("1d262d"))
			y += 20.0
	for s: Spot in spots:
		_draw_spot(s)
	if nearest != null:
		_draw_prompt(nearest)
	if Case.optic_on:
		draw_rect(Rect2(camera_x, 0, VIEW.x, VIEW.y), Color(0.47, 0.08, 0.24, 0.22))


func _draw_sky() -> void:
	var r: Rect2 = Rect2(camera_x, 0, VIEW.x, VIEW.y)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, 0), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([room.sky_top, room.sky_top, room.sky_bottom, room.sky_bottom]))
	for layer: int in 2:
		var parallax: float = 0.5 if layer == 1 else 0.25
		var shade: Color = Color(0.04, 0.05, 0.09, 0.85) if layer == 1 else Color(0.08, 0.1, 0.17, 0.7)
		for i: int in 40:
			var w: float = 60.0 + _hash(i + layer * 50) * 90.0
			var h: float = 120.0 + _hash(i * 3 + layer) * 240.0
			var x: float = camera_x + i * 110.0 - camera_x * parallax - 300.0
			if x < camera_x - 200.0 or x > camera_x + VIEW.x + 200.0:
				continue
			var top: float = FLOOR_Y - h - (0.0 if layer == 1 else 40.0)
			draw_rect(Rect2(x, top, w, h + 40.0), shade)
			if _hash(i * 7 + layer) > 0.55:
				var c: Color = NEON[i % 3]
				c.a = 0.5 + 0.3 * sin(_clock * 2.0 + i)
				draw_rect(Rect2(x + 8, top + 20, w - 16, 4), c)
	# Rain.
	for i: int in 60:
		var rx: float = camera_x + fposmod(_hash(i) * VIEW.x + _clock * 60.0 * (i % 3 + 1), VIEW.x)
		var ry: float = fposmod(_hash(i + 9) * VIEW.y + _clock * 500.0, VIEW.y)
		draw_line(Vector2(rx, ry), Vector2(rx - 4, ry + 14), Color(0.6, 0.75, 0.86, 0.18), 1.0)


func _draw_spot(s: Spot) -> void:
	var shown: bool = s.is_visible()
	var top_left: Vector2 = Vector2(s.x, s.y - s.size.y)
	var pulse: float = 0.6 + 0.4 * sin(_clock * 5.0)
	match s.kind:
		Spot.Kind.PANEL:
			# Panels are always scenery; the board makes one usable.
			draw_rect(Rect2(top_left, s.size), Color("33444f"))
			draw_rect(Rect2(top_left + Vector2(4, 4), Vector2(s.size.x - 8, 8)), Color("55707e"))
			_text(s.code, top_left + Vector2(-6, -4), 9, Color("88aaaa"))
			if shown and s.is_highlighted():
				draw_rect(Rect2(top_left - Vector2(4, 4), s.size + Vector2(8, 8)), Color(1, 0.7, 0.28, pulse), false, 2.0)
			return
		_:
			pass
	if not shown:
		return
	match s.kind:
		Spot.Kind.PERSON:
			draw_person(self, Vector2(s.x + s.size.x / 2.0, s.y), s.color, false)
		Spot.Kind.HEAT_DOOR:
			draw_rect(Rect2(top_left, s.size), Color(1, 0.48, 0.18, 0.55))
			draw_rect(Rect2(top_left, s.size), Color("ffb347"), false, 2.0)
		Spot.Kind.DOOR:
			draw_rect(Rect2(top_left, s.size), Color("0c121b"))
			draw_rect(Rect2(top_left, s.size), s.color, false, 2.0)
			if s.is_highlighted():
				draw_rect(Rect2(top_left - Vector2(4, 4), s.size + Vector2(8, 8)), Color(1, 0.7, 0.28, pulse), false, 2.0)
			if s.id == "stall_door":
				draw_line(Vector2(s.x - 8, s.y - 60), Vector2(s.x + s.size.x + 8, s.y - 30), Color("ffd400"), 3.0)
		Spot.Kind.BODY:
			draw_rect(Rect2(s.x, s.y - 14, s.size.x, 14), Color("ff7a2f") if Case.optic_on else Color("6a4a50"))
			draw_rect(Rect2(s.x + s.size.x - 8, s.y - 18, 6, 4), Color("dddddd"))
		_:
			draw_rect(Rect2(top_left, s.size), Color("16202c"))
			var band: Color = s.color
			band.a = 0.7
			draw_rect(Rect2(top_left + Vector2(4, 4), Vector2(s.size.x - 8, 10)), band)
			draw_rect(Rect2(top_left, s.size), s.color, false, 1.0)


func _draw_prompt(s: Spot) -> void:
	var font: Font = ThemeDB.fallback_font
	var line: String = "E  " + s.label
	var w: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 14.0
	var top: float = s.y - s.size.y - (32.0 if s.kind == Spot.Kind.PERSON else 26.0)
	var r: Rect2 = Rect2(s.x + s.size.x / 2.0 - w / 2.0, top, w, 20)
	draw_rect(r, Color(0.03, 0.05, 0.08, 0.92))
	draw_rect(r, Color("3ee6d0"), false, 1.0)
	_text(line, r.position + Vector2(7, 15), 13, Color("d7e2ee"))


func _text(t: String, at: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
