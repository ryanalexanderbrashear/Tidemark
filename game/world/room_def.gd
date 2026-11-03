class_name RoomDef
extends RefCounted
## A room's layout in grey-box: size, colors, one-way ledges, exits and spawns.

var id: String
var title: String
var width: float
var sky_top: Color
var sky_bottom: Color
var floor_color: Color
var water: bool = false
## One-way ledges as Rect2(x, top y, width, thickness).
var ledges: Array[Rect2] = []
## Walking off the left/right edge leads here: room id and arrival x.
var exit_left: String = ""
var exit_left_x: float = 0.0
var exit_right: String = ""
var exit_right_x: float = 0.0
## A hard stop short of the right edge (deep water). 0 means none.
var limit: float = 0.0
var limit_line: String = ""
## Where hostiles stand, in spawn order, and what they are.
var spawns: Array[Vector2] = []
var spawn_kind: String = "thug"


static func make(room_id: String, room_title: String, w: float, top: Color, bottom: Color, ground: Color) -> RoomDef:
	var r: RoomDef = RoomDef.new()
	r.id = room_id
	r.title = room_title
	r.width = w
	r.sky_top = top
	r.sky_bottom = bottom
	r.floor_color = ground
	return r


func ledge(x: float, y: float, w: float) -> RoomDef:
	ledges.append(Rect2(x, y, w, 10.0))
	return self


func exits(left: String, left_x: float, right: String, right_x: float) -> RoomDef:
	exit_left = left
	exit_left_x = left_x
	exit_right = right
	exit_right_x = right_x
	return self


func right_limit() -> float:
	return limit if limit > 0.0 else width
