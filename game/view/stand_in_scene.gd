class_name StandInScene
extends RoomScene
## A room that isn't drawn yet, standing in at the game's resolution so the
## whole case plays in one look: the grey-box layout (RoomLayout) in flat
## pixel shapes, lit in the room's own colours. A sky with a far skyline in
## fog, the floor on the walkway, one-way ledges, doors as dark frames, objects
## as lit boxes, panels with their codes, and people as flat silhouettes in
## their spot's colour. Everything here is placeholder, to be replaced room by
## room as the art is drawn.

const P = preload("res://game/art/art_palette.gd")
const WATER_SHADER = preload("res://game/art/water.gdshader")
## How far the skyline moves for each pixel the camera does.
const SKYLINE_PARALLAX: float = 0.35
const WATER_Y: int = MarketArt.WATER_Y
## The stand-in people's figure (any of the cast's builds would do).
const FIGURE: String = "fixer"

var def: RoomDef
var layout: RoomLayout
var people: Dictionary[Spot, CastSprite] = {}
var _sky: Sprite2D
var _skyline: Sprite2D
var _room: Sprite2D
var _props: Props
var _water: ColorRect


func _init(room_def: RoomDef, room_layout: RoomLayout) -> void:
	def = room_def
	layout = room_layout
	id = def.id
	width = maxi(PixelView.NATIVE.x, layout.width(id))
	outdoors = def.water
	lamp_on = false


func _draw() -> void:
	_sky = sprite(_sky_image(), back)
	_skyline = sprite(_skyline_image(), back)
	_room = sprite(_room_image(), play)
	_props = Props.new()
	_props.scene = self
	play.add_child(_props)
	for s: Spot in layout.spots_in(id):
		if s.kind != Spot.Kind.PERSON:
			continue
		var anims: Array[String] = ["idle"]
		var p: CastSprite = CastSprite.new(FIGURE, anims, Color(s.color).darkened(0.55))
		play.add_child(p)
		people[s] = p
		warm(p)
	if def.water:
		_water = ColorRect.new()
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = WATER_SHADER
		mat.set_shader_parameter("back_tex", view.back.get_texture())
		mat.set_shader_parameter("view_size", Vector2(PixelView.NATIVE))
		mat.set_shader_parameter("line_y", float(WATER_Y))
		_water.material = mat
		_water.size = Vector2(PixelView.NATIVE.x, PixelView.NATIVE.y - WATER_Y)
		_water.position = Vector2(0, WATER_Y)
		over.add_child(_water)


func update(cam: float, time: float, _fog: int) -> void:
	view.set_volumetric(false)
	_skyline.position = Vector2(-floorf(cam * SKYLINE_PARALLAX), 0)
	_room.position = Vector2(-cam, 0)
	_props.position = Vector2(-cam, 0)
	_props.time = time
	_props.queue_redraw()
	var i: int = 0
	for s: Spot in people:
		var p: CastSprite = people[s]
		p.visible = s.is_visible()
		p.play_at("idle", time, i)
		p.place(RoomLayout.place(s).x, RoomLayout.feet_y(s), cam)
		i += 1


func _rng() -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash(id)
	return r


func _sky_image() -> Image:
	var img: Image = Px.blank(PixelView.NATIVE.x, PixelView.NATIVE.y)
	Px.vgrad(img, 0, 0, img.get_width(), img.get_height(), def.sky_top.darkened(0.3), def.sky_bottom, 6)
	return img


## Far towers in the room's own fog colour, so it reads as somewhere in the
## city without saying where.
func _skyline_image() -> Image:
	var w: int = PixelView.NATIVE.x + ceili(float(width - PixelView.NATIVE.x) * SKYLINE_PARALLAX) + 2
	var img: Image = Px.blank(w, PixelView.NATIVE.y)
	var rng: RandomNumberGenerator = _rng()
	var far: Color = def.sky_bottom.lerp(P.FOG, 0.18)
	var near: Color = def.sky_top.lerp(P.INK, 0.4)
	var x: int = -6
	while x < w:
		var tw: int = rng.randi_range(20, 54)
		var top: int = rng.randi_range(90, 220)
		Px.rect(img, x, top, tw, PixelView.NATIVE.y - top, far)
		for wy: int in range(top + 6, int(RoomLayout.WALK_Y) - 20, 9):
			for wx: int in range(x + 4, x + tw - 4, 7):
				if rng.randf() < 0.18:
					Px.dot(img, wx, wy, def.sky_bottom.lightened(0.35))
		x += tw + rng.randi_range(2, 14)
	x = -10
	while x < w:
		var tw: int = rng.randi_range(30, 80)
		var top: int = rng.randi_range(170, 250)
		Px.rect(img, x, top, tw, PixelView.NATIVE.y - top, near)
		x += tw + rng.randi_range(0, 30)
	return img


## The floor, the ledges and the room's back wall in its floor colour.
func _room_image() -> Image:
	var img: Image = Px.blank(width, PixelView.NATIVE.y)
	var walk: int = int(RoomLayout.WALK_Y)
	var ground: Color = def.floor_color
	if def.water:
		# A narrow walkway over the water.
		Px.rect(img, 0, walk, width, 6, ground)
		Px.rect(img, 0, walk, width, 1, ground.lightened(0.3))
		for px: int in range(12, width, 48):
			Px.rect(img, px, walk + 6, 3, WATER_Y - walk - 6 + 20, ground.darkened(0.4))
	else:
		Px.rect(img, 0, walk, width, PixelView.NATIVE.y - walk, ground)
		Px.rect(img, 0, walk, width, 1, ground.lightened(0.35))
		for py: int in range(walk + 6, PixelView.NATIVE.y, 9):
			Px.rect(img, 0, py, width, 1, ground.darkened(0.25))
	for l: Rect2 in layout.ledges(id):
		var r: Rect2i = Rect2i(l)
		Px.rect(img, r.position.x, r.position.y, r.size.x, 5, ground.lightened(0.1))
		Px.rect(img, r.position.x, r.position.y, r.size.x, 1, ground.lightened(0.45))
		Px.rect(img, r.position.x, r.position.y + 5, r.size.x, 2, ground.darkened(0.45))
		for sx: int in [r.position.x + 4, r.end.x - 7]:
			Px.rect(img, sx, r.position.y + 7, 3, walk - r.position.y - 7, ground.darkened(0.5))
	return img


## The room's spots, drawn each frame so they show and hide with the case.
class Props:
	extends Node2D

	var scene: StandInScene
	var time: float = 0.0
	var _texts: Dictionary[String, ImageTexture] = {}

	func _draw() -> void:
		for s: Spot in scene.layout.spots_in(scene.id):
			if s.kind != Spot.Kind.PERSON:
				_draw_spot(s)

	func _draw_spot(s: Spot) -> void:
		var shown: bool = s.is_visible()
		var p: Vector2 = RoomLayout.place(s)
		var size: Vector2 = (s.size * RoomLayout.SCALE).round()
		var top_left: Vector2 = Vector2(roundf(p.x - size.x / 2.0), RoomLayout.feet_y(s) - size.y)
		var r: Rect2 = Rect2(top_left, size)
		var pulse: float = 0.6 + 0.4 * sin(time * 5.0)
		var color: Color = Color(s.color)
		if s.kind == Spot.Kind.PANEL:
			# Panels are always scenery; the board makes one usable.
			draw_rect(r, Color("1c2830"))
			draw_rect(Rect2(top_left + Vector2(3, 3), Vector2(size.x - 6, 4)), Color("3a5260"))
			_text(s.code, Vector2(p.x, top_left.y - 3), Color("88aaaa"))
			if shown and s.is_highlighted():
				draw_rect(r.grow(2), Color(P.AMBER, pulse), false, 1.0)
			return
		if not shown:
			return
		match s.kind:
			Spot.Kind.HEAT_DOOR:
				draw_rect(r, Color(1, 0.48, 0.18, 0.4))
				draw_rect(r, P.AMBER, false, 1.0)
			Spot.Kind.DOOR:
				draw_rect(r, P.INK)
				draw_rect(r, color.darkened(0.2), false, 1.0)
				draw_rect(Rect2(top_left + Vector2(size.x - 6, size.y * 0.5), Vector2(2, 2)), color)
				if s.is_highlighted():
					draw_rect(r.grow(2), Color(P.AMBER, pulse), false, 1.0)
			Spot.Kind.BODY:
				draw_rect(Rect2(top_left.x, top_left.y + size.y - 6, size.x, 6), Color("4a3438"))
			_:
				draw_rect(r, Color("101820"))
				draw_rect(Rect2(top_left + Vector2(2, 2), Vector2(size.x - 4, 4)), Color(color, 0.7))
				draw_rect(r, color.darkened(0.3), false, 1.0)

	## Small pixel text centred on `at` (its bottom edge).
	func _text(t: String, at: Vector2, c: Color) -> void:
		if not _texts.has(t):
			var img: Image = Px.blank(Px.text_width(t) + 2, 8)
			Px.text(img, 1, 1, t, c)
			_texts[t] = ImageTexture.create_from_image(img)
		var tex: ImageTexture = _texts[t]
		draw_texture(tex, (at - Vector2(tex.get_width() / 2.0, 8)).floor())
