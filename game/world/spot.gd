class_name Spot
extends RefCounted
## Something in a room the detective can use: a person, a door, an object.

enum Kind { PERSON, DOOR, OBJECT, BODY, PANEL, HEAT_DOOR }

var id: String
var room: String
var kind: Kind
var label: String
var x: float
## Bottom edge. Defaults to the floor.
var y: float
var size: Vector2
var color: Color
## -> bool. Hidden spots can't be used and aren't drawn (panels are always drawn).
var visible_when: Callable
## -> bool. Pulses to tell the player their board found something here.
var highlight_when: Callable
## -> Talk (or null).
var action: Callable
## Text drawn on a panel.
var code: String = ""


func is_visible() -> bool:
	return not visible_when.is_valid() or bool(visible_when.call())


func is_highlighted() -> bool:
	return highlight_when.is_valid() and bool(highlight_when.call())


func use() -> Talk:
	return action.call() as Talk


func center() -> Vector2:
	return Vector2(x + size.x / 2.0, y - size.y / 2.0)
