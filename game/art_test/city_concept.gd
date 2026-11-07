class_name CityConcept
extends Node
## Concept view of Halcyon Reach from a distance (CityArt), with the art test's
## live rain falling over it and a few cars crossing between the Crown's pads.
## Not a playable room: a picture to judge the city's silhouette and light by.
## Open scenes/city_concept.tscn and press F6. Esc quits.

const P = preload("res://game/art_test/art_palette.gd")

## Cars crossing: start x, row, speed in native px a second, color.
const CARS: Array[Array] = [[-20.0, 70.0, 18.0, CityArt.CROWN_LIGHT], [660.0, 104.0, -12.0, P.CYAN], [-40.0, 52.0, 9.0, P.MAGENTA]]

var _view: SubViewport
var _screen: TextureRect
var _cars: Array[Sprite2D] = []


func _ready() -> void:
	# The scene scales itself by whole pixels, so the project's stretch is off here.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_view = SubViewport.new()
	_view.size = CityArt.VIEW
	_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_view.snap_2d_transforms_to_pixel = true
	add_child(_view)
	var city: Sprite2D = Sprite2D.new()
	city.centered = false
	city.texture = ImageTexture.create_from_image(CityArt.compose(false))
	_view.add_child(city)
	for c: Array in CARS:
		var s: Sprite2D = Sprite2D.new()
		s.texture = ImageTexture.create_from_image(_car(c[3], signf(c[2])))
		s.position = Vector2(c[0], c[1])
		_view.add_child(s)
		_cars.append(s)
	var rain: ArtRain = ArtRain.new()
	rain.view_size = CityArt.VIEW
	rain.walk_y = CityArt.HORIZON
	rain.water_y = CityArt.HORIZON
	_view.add_child(rain)
	_screen = TextureRect.new()
	_screen.texture = _view.get_texture()
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_screen)
	get_window().size_changed.connect(_layout)
	_layout()


func _process(delta: float) -> void:
	for i: int in range(_cars.size()):
		var speed: float = CARS[i][2]
		var s: Sprite2D = _cars[i]
		s.position.x += speed * delta
		if speed > 0.0 and s.position.x > CityArt.VIEW.x + 30:
			s.position.x = -30.0
		elif speed < 0.0 and s.position.x < -30.0:
			s.position.x = CityArt.VIEW.x + 30


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


## Whole-number scaling only, centred, so the pixels stay square.
func _layout() -> void:
	var win: Vector2i = get_window().size
	var scale: int = maxi(1, mini(win.x / CityArt.VIEW.x, win.y / CityArt.VIEW.y))
	var shown: Vector2 = Vector2(CityArt.VIEW * scale)
	_screen.position = ((Vector2(win) - shown) * 0.5).floor()
	_screen.size = shown


## A car: two lights and a fading trail behind them.
static func _car(c: Color, dir: float) -> Image:
	var img: Image = Px.blank(24, 7)
	var head: int = 20 if dir > 0.0 else 3
	for k: int in range(14):
		Px.dot(img, head - int(dir) * (k + 1), 3, Color(c, 0.45 * (1.0 - k / 14.0)))
	Px.rect(img, head, 3, 2, 1, c)
	Px.glow(img, head + 1, 3, 4, 3, c, 0.25)
	return img
