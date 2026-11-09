class_name StallScene
extends RoomScene
## Vale's stall, the crime scene (StallArt): one screen, no parallax, no fog or
## rain inside. Her body lies under the stall's own stuttering lamp, with a
## little of her heat left in it for the thermal optic.

## How much heat is left in the body (the thermal read gives time of death).
const BODY_HEAT: float = 0.35

var lamp: Sprite2D
var body: Sprite2D


func _init() -> void:
	id = "stall"
	width = StallArt.SIZE.x
	lamp_x = StallArt.LAMP_X


func _draw() -> void:
	sprite(StallArt.back(), back)
	sprite(StallArt.room(), play)
	lamp = sprite(StallArt.lamp(), play)
	lamp.material = additive()
	body = sprite(StallArt.body(), play)
	warm(body, BODY_HEAT)


func update(cam: float, time: float, _fog: int) -> void:
	view.set_volumetric(false)
	lamp.position = Vector2(-cam, 0)
	lamp.visible = sin(time * 19.0) + sin(time * 5.1) > -1.5
	lamp_on = lamp.visible
	body.position = Vector2(floorf(StallArt.BODY_X - StallArt.BODY_SIZE.x * 0.5 - cam), MarketArt.WALK_Y - StallArt.BODY_SIZE.y + 3)
