class_name RoomScene
extends RefCounted
## One drawn room in a PixelView: its nodes in the back and play viewports
## (and over the people, in `over`), shown only while the detective is in it.
## Subclasses draw a room and move it with the camera each frame.
##
## The room's own people stand in `play`; the detective, who walks between
## rooms, stands in the view's `people`, in front of them and behind `over`.

enum Fog { STEPPED, VOLUMETRIC, OFF }

## The case's room id (DrownedMarket).
var id: String
## Width in native pixels.
var width: int = PixelView.NATIVE.x
## Where feet go.
var walk_y: float = MarketArt.WALK_Y
## Rain falls here (the room is open to the sky).
var outdoors: bool = false
## Where the room's light hangs (x), for the lamp hum, and whether it's lit
## now.
var lamp_x: float = 0.0
var lamp_on: bool = true

var view: PixelView
var back: Node2D
var play: Node2D
var over: Node2D
## What's warm in this room, for the thermal optic: sprite -> its heat sprite.
var heat_of: Dictionary[Sprite2D, Sprite2D] = {}


func build(into: PixelView) -> void:
	view = into
	back = _node(view.back)
	play = _node(view.rooms)
	over = _node(view.over)
	_draw()
	set_shown(false)


## Draws the room into back, play and over. Overridden.
func _draw() -> void:
	pass


## Shows or hides everything this room drew.
func set_shown(on: bool) -> void:
	for n: CanvasItem in [back, play, over]:
		n.visible = on
	for h: Sprite2D in heat_of.values():
		h.visible = on


## Where the camera sits for the detective at `x`: centred on him, held
## inside the room, on whole pixels.
func cam_x(x: float) -> float:
	return floorf(clampf(x - PixelView.NATIVE.x * 0.5, 0.0, float(maxi(0, width - PixelView.NATIVE.x))))


## Moves the room for the camera and the clock. `fog` is a Fog. Overridden.
func update(_cam: float, _time: float, _fog: int) -> void:
	pass


## Copies each warm sprite into the heat picture.
func update_heat() -> void:
	for src: Sprite2D in heat_of:
		var h: Sprite2D = heat_of[src]
		h.visible = src.is_visible_in_tree()
		h.texture = src.texture
		h.position = src.position
		h.flip_h = src.flip_h


## Marks `s` as warm.
func warm(s: Sprite2D, amount: float = 1.0) -> void:
	heat_of[s] = view.heat_sprite(amount)


func _node(into: Node) -> Node2D:
	var n: Node2D = Node2D.new()
	into.add_child(n)
	return n


func sprite(img: Image, into: Node) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.centered = false
	s.texture = ImageTexture.create_from_image(img)
	into.add_child(s)
	return s


static func additive() -> CanvasItemMaterial:
	var m: CanvasItemMaterial = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
