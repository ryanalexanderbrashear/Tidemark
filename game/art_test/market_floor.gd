class_name ArtMarketFloor
extends RefCounted
## Makes the art test's rooms rooms of the real case: the people and objects
## drawn on the market floor and in Vale's stall are those rooms' spots from
## DrownedMarket, so talking, the gates, the readings and the clues all go
## through `Case` exactly as they do in the grey-box prototype. Only where each
## spot stands is new: the art market is 1280 px wide at 640x360 and the stall
## one screen, where the prototype's are 2600 and 960 world units.
##
## Doors to rooms the art test doesn't have (Cold Storage) still open through
## the case; the scene says the room isn't built and keeps the detective where
## he is.

## The rooms the art test draws, and how wide each is (native pixels).
const ROOM_WIDTHS: Dictionary[String, int] = {"market": 1280, "stall": 640}
## Where each drawn spot stands: [centre x, half width] in native pixels, per
## room. Placeholder layout for this test.
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
## Where the detective comes in through each room's door.
const ENTRY_X: Dictionary[String, float] = {"market": MarketArt.STALL_X + MarketArt.STALL_W / 2, "stall": StallArt.EXIT_X + 40}
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
## How far past a spot's edge the detective can still use it.
const REACH: float = 16.0
## Where the detective starts: the west end of the market, walking in.
const START_X: float = 60.0

## The art test's starting point in the case. Placeholder, not canon: the
## detective walks onto the market floor at the start of the case, already
## carrying a calibrated thermal optic, because the precinct lab where Sato
## calibrates it isn't drawn in the art test.
const START_WITH_OPTIC: bool = true

## How far a reading's white comes in (see reading_depth).
const SURFACE_WHITE: float = 0.5
const DEEP_WHITE: float = 0.95

var market: DrownedMarket
var spots: Dictionary[String, Array] = {}


func _init(from: DrownedMarket = null) -> void:
	market = from if from != null else DrownedMarket.new()
	# The chip doubles as the examine tutorial: her body gives the chip, and
	# turning it over (X) finds the etching.
	market.etching_by_examining = true
	for room: String in PLACES:
		var list: Array[Spot] = []
		for s: Spot in market.spots_in(room):
			if PLACES[room].has(s.id):
				list.append(s)
		spots[room] = list


## Breaks the market's reference loop (its spots' actions point back at it),
## so it's freed when the scene goes.
func release() -> void:
	spots.clear()
	market.spots.clear()
	market.rooms.clear()


## Starts the case at the art test's starting point (see START_WITH_OPTIC).
static func start_case() -> void:
	Case.reset()
	if START_WITH_OPTIC:
		Case.grant_optic()
	Case.travel("market", START_X)


static func is_drawn(room: String) -> bool:
	return ROOM_WIDTHS.has(room)


static func place(s: Spot) -> Vector2:
	return PLACES[s.room][s.id]


func spots_in(room: String) -> Array[Spot]:
	var out: Array[Spot] = []
	out.assign(spots.get(room, []))
	return out


## The spot the detective at `x` in `room` can use, nearest first, or null.
func nearest(room: String, x: float) -> Spot:
	var best: Spot = null
	var best_d: float = INF
	for s: Spot in spots_in(room):
		if not s.is_visible():
			continue
		var p: Vector2 = place(s)
		var d: float = absf(p.x - x)
		if d <= p.y + REACH and d < best_d:
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


## The examine tutorial: what the inner voice says once he has the chip
## and hasn't turned it over yet (after the body; again on leaving the stall).
const CHIP_HINT: String = "Something's scratched into that chip. Take it out and turn it over. (X)"
const CHIP_REMINDER: String = "That chip in my pocket. I still haven't looked at what's scratched on it. (X)"


## Whether he's carrying the chip without having found its etching.
static func chip_unexamined() -> bool:
	return Case.is_set("has_chip") and not Case.has_clue("chip")


## The prompt shown over a spot.
static func prompt(s: Spot) -> String:
	return "E  " + s.label


## What the scene says when a door leads somewhere the art test hasn't drawn.
func unbuilt_room_line(room: String) -> String:
	var title: String = market.rooms[room].title if market.rooms.has(room) else room
	return "%s isn't drawn yet. The art test ends here." % title
