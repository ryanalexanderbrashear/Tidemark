class_name RoomLayout
extends RefCounted
## Where everything in the case's rooms stands in native pixels (640 x 360).
##
## DrownedMarket lays its rooms out in grey-box world units (a 960 x 540
## screen, the floor at y 470). Rooms that are drawn (the market floor and
## Vale's stall) have their own layout: each spot stands where the art draws
## it, the market is 1280 px wide where the grey box's is 2600, and the floor
## is flat. Every other room is a stand-in until it's drawn: its grey-box
## layout scaled by SCALE, its floor on the same walkway height, its ledges and
## spawns kept.
##
## The case still speaks world units (Case.travel's arrival x, a room's exits);
## to_native() turns them into this layout's x: by SCALE in a stand-in room,
## and in a drawn room at the spot nearest it in the grey box (the art moves
## things around: an arrival through the heat-sealed door lands at that door
## wherever it's drawn), or at the room's end nearest it.

## Grey-box world units to native pixels in a stand-in room (540 -> 360).
const SCALE: float = 2.0 / 3.0
## Where feet go, in every room.
const WALK_Y: float = MarketArt.WALK_Y

## The rooms that are drawn, and how wide each is (native pixels).
const ROOM_WIDTHS: Dictionary[String, int] = {"market": 1280, "stall": 640}
## Where each drawn spot stands: [centre x, half width] in native pixels, per
## room. Placeholder layout.
const PLACES: Dictionary[String, Dictionary] = {
	"market": {
		"heat_door": Vector2(HEAT_DOOR_X, 20),
		"passenger_vale": Vector2(VALE_X, 10),
		"stall_door": Vector2(MarketArt.STALL_X + MarketArt.STALL_W / 2, 44),
		"osk": Vector2(OSK_X, 16),
		"cams": Vector2(CAM_X, 12),
		"fixer": Vector2(FIXER_X, 14),
		"back_room": Vector2(BACK_DOOR_X, 28),
		"tech": Vector2(TECH_X, 24),
	},
	"stall": {
		"stall_exit": Vector2(StallArt.EXIT_X, 20),
		"ledger": Vector2(StallArt.LEDGER_X, 18),
		"body": Vector2(StallArt.BODY_X, 40),
		"sample": Vector2(StallArt.SAMPLE_X, 14),
	},
}
const OSK_X: float = 512.0
const FIXER_X: float = 905.0
## Under the camera on its pole, looking back at Vale's stall.
const CAM_X: float = MarketArt.CAM_POLE_X - 16.0
## The fixer's back room: a steel door where a stall would be.
const BACK_DOOR_X: float = MarketArt.BACK_DOOR_X + 50.0
## The maintenance tech, kneeling at the failing pump.
const TECH_X: float = 1190.0
## The heat-sealed door: a boarded-up stall front that only the thermal optic
## shows for what it is.
const HEAT_DOOR_X: float = MarketArt.HEAT_STALL_X + 48.0
## Vale's passenger, at the edge of the fog west of her stall, once a deep
## reading has brought her back with him.
const VALE_X: float = 300.0
## How far past a spot's edge the detective can still use it, and how far
## above or below his feet it can be.
const REACH: float = 16.0
const REACH_Y: float = 46.0
## Where prompts sit over a drawn spot (native y): above everyone's heads, or
## under the camera on its pole; inside the stall, over the counter and floor.
const PROMPT_Y: float = 178.0
const PROMPT_Y_CAMS: float = 96.0
const PROMPT_Y_LOW: float = 222.0

## How far a reading's white comes in (see reading_depth).
const SURFACE_WHITE: float = 0.5
const DEEP_WHITE: float = 0.95

var market: DrownedMarket
## Per drawn room: grey-box x -> native x, for each spot and both ends.
var _anchors: Dictionary[String, Array] = {}


func _init(from: DrownedMarket = null) -> void:
	market = from if from != null else DrownedMarket.new()
	for room: String in PLACES:
		var pairs: Array[Vector2] = [Vector2(0, 0), Vector2(market.rooms[room].width, ROOM_WIDTHS[room])]
		for s: Spot in market.spots_in(room):
			if PLACES[room].has(s.id):
				pairs.append(Vector2(s.x + s.size.x / 2.0, PLACES[room][s.id].x))
		_anchors[room] = pairs


## Breaks the market's reference loop (its spots' actions point back at it),
## so it's freed when the scene goes.
func release() -> void:
	market.spots.clear()
	market.rooms.clear()


static func is_drawn(room: String) -> bool:
	return ROOM_WIDTHS.has(room)


## The room's width in native pixels.
func width(room: String) -> int:
	if is_drawn(room):
		return ROOM_WIDTHS[room]
	return roundi(market.rooms[room].width * SCALE)


## A grey-box x in `room` as a native x.
func to_native(room: String, world_x: float) -> float:
	if not is_drawn(room):
		return world_x * SCALE
	var best: Vector2 = Vector2(INF, 0.0)
	for a: Vector2 in _anchors[room]:
		if absf(a.x - world_x) < absf(best.x - world_x):
			best = a
	return clampf(best.y, RoomLayout.REACH, float(ROOM_WIDTHS[room]) - RoomLayout.REACH)


## A grey-box height (y, down from the top) in a stand-in room, as native y,
## with the floor on the walkway.
static func y_to_native(world_y: float) -> float:
	return WALK_Y - (DrownedMarket.FLOOR_Y - world_y) * SCALE


## Where `s` stands: [centre x, half width] in native pixels.
static func place(s: Spot) -> Vector2:
	if PLACES.has(s.room) and PLACES[s.room].has(s.id):
		return PLACES[s.room][s.id]
	return Vector2((s.x + s.size.x / 2.0) * SCALE, s.size.x / 2.0 * SCALE)


## The height of `s`'s bottom edge (native y). Drawn rooms are flat.
static func feet_y(s: Spot) -> float:
	if is_drawn(s.room):
		return WALK_Y
	return y_to_native(s.y)


## Where the prompt over `s` sits (native y).
static func prompt_y(s: Spot) -> float:
	if s.id == "cams":
		return PROMPT_Y_CAMS
	if s.room == "stall" and s.id != "stall_exit":
		return PROMPT_Y_LOW
	if is_drawn(s.room):
		return PROMPT_Y
	return feet_y(s) - (WALK_Y - PROMPT_Y)


## The prompt shown over a spot.
static func prompt(s: Spot) -> String:
	return "E  " + s.label


## The one-way ledges of a stand-in room, in native pixels. Drawn rooms have
## none yet.
func ledges(room: String) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if is_drawn(room):
		return out
	for l: Rect2 in market.rooms[room].ledges:
		out.append(Rect2(l.position.x * SCALE, y_to_native(l.position.y), l.size.x * SCALE, 4.0))
	return out


## Where a room's hostiles stand, in native pixels.
func spawns(room: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p: Vector2 in market.rooms[room].spawns:
		out.append(Vector2(to_native(room, p.x), y_to_native(p.y)))
	return out


func spots_in(room: String) -> Array[Spot]:
	return market.spots_in(room)


## The spot the detective at `x`, feet at `feet`, in `room` can use, nearest
## first, or null.
func nearest(room: String, x: float, feet: float = WALK_Y) -> Spot:
	var best: Spot = null
	var best_d: float = INF
	for s: Spot in spots_in(room):
		if not s.is_visible():
			continue
		var p: Vector2 = place(s)
		var d: float = absf(p.x - x)
		if d <= p.y + REACH and absf(feet_y(s) - feet) <= REACH_Y and d < best_d:
			best_d = d
			best = s
	return best


## How far a reading's white comes in while `t` is up: 0 when it isn't a
## reading, part way for a surface reading, nearly all the way for a deep one.
static func reading_depth(t: Talk) -> float:
	if t == null:
		return 0.0
	for r: Reading in CaseCatalog.all_readings():
		if t.speaker == r.title:
			if t.text == r.deep_text:
				return DEEP_WHITE
			return SURFACE_WHITE
	return 0.0
