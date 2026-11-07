class_name ArtMarketFloor
extends RefCounted
## Makes the art test's market floor a room of the real case: the people and
## objects drawn there are the market room's spots from DrownedMarket, so
## talking, the gates and the clues all go through `Case` exactly as they do in
## the grey-box prototype. Only where each spot stands is new: the art test's
## market is 1280 px wide at 640x360, the prototype's is 2600 world units.
##
## Spots the art doesn't draw yet (Vale's passenger, the heat-sealed door) stay
## out of the scene. Doors to rooms the art test doesn't have (Vale's stall,
## Cold Storage) still open through the case; the scene says the room isn't
## built and keeps the detective on the market floor.

## Where each drawn spot stands on the art market: [centre x, half width] in
## native pixels. Placeholder layout for this test.
const PLACES: Dictionary[String, Vector2] = {
	"stall_door": Vector2(MarketArt.STALL_X + MarketArt.STALL_W / 2, 44),
	"osk": Vector2(OSK_X, 16),
	"cams": Vector2(CAM_X, 12),
	"fixer": Vector2(FIXER_X, 14),
	"back_room": Vector2(BACK_DOOR_X, 28),
	"tech": Vector2(TECH_X, 24),
}
const OSK_X: float = 512.0
const FIXER_X: float = 905.0
## Under the camera on its pole, looking back at Vale's stall.
const CAM_X: float = MarketArt.CAM_POLE_X - 16.0
## The fixer's back room: a steel door where a stall would be.
const BACK_DOOR_X: float = MarketArt.BACK_DOOR_X + 50.0
## The maintenance tech, kneeling at the failing pump.
const TECH_X: float = 1190.0
## How far past a spot's edge the detective can still use it.
const REACH: float = 16.0
## Where the detective starts: west of Vale's stall, where he came out.
const START_X: float = 300.0

## The art test's starting point in the case. Placeholder, not canon: the
## detective has just come out of Vale's stall, with her ledger read and the
## chip from her hand in his pocket. He hasn't turned the chip over yet, so its
## etching (clue "chip") is found by examining it (X).
const START_CLUES: Array[String] = ["ledger"]
const START_BEAT: String = "body_examined"

var market: DrownedMarket
var spots: Array[Spot] = []


func _init(from: DrownedMarket = null) -> void:
	market = from if from != null else DrownedMarket.new()
	for s: Spot in market.spots_in("market"):
		if PLACES.has(s.id):
			spots.append(s)


## Breaks the market's reference loop (its spots' actions point back at it),
## so it's freed when the scene goes.
func release() -> void:
	spots.clear()
	market.spots.clear()
	market.rooms.clear()


## Starts the case at the art test's starting point (see START_CLUES).
static func start_case() -> void:
	Case.reset()
	for id: String in START_CLUES:
		Case.find_clue(id)
	Case.reach(START_BEAT)
	Case.travel("market", START_X)


static func place(s: Spot) -> Vector2:
	return PLACES[s.id]


## The spot the detective at `x` can use, nearest first, or null.
func nearest(x: float) -> Spot:
	var best: Spot = null
	var best_d: float = INF
	for s: Spot in spots:
		if not s.is_visible():
			continue
		var p: Vector2 = place(s)
		var d: float = absf(p.x - x)
		if d <= p.y + REACH and d < best_d:
			best_d = d
			best = s
	return best


## The prompt shown over a spot.
static func prompt(s: Spot) -> String:
	return "E  " + s.label


## What the scene says when a door leads somewhere the art test hasn't drawn.
func unbuilt_room_line(room: String) -> String:
	var title: String = market.rooms[room].title if market.rooms.has(room) else room
	return "%s isn't drawn yet. The art test ends at the market floor." % title
