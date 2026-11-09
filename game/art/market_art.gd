class_name MarketArt
extends RefCounted
## Draws the Drowned Market's layers for the style test: a half-flooded bazaar
## under the stilts of a corporate arcology (sample case doc). Each layer is one
## Image at native resolution, wide enough for its parallax across the room.
##
## The room is 1280 x 360 native pixels: two screens at 640 x 360. Everything is
## seeded, so the same code always draws the same market.

const P = preload("res://game/art/art_palette.gd")

const ROOM: Vector2i = Vector2i(1280, 360)
const VIEW: Vector2i = Vector2i(640, 360)
const WALK_Y: int = 286     # where feet go
const WATER_Y: int = 300    # the waterline
const STALL_X: int = 352    # Vale's stall, left edge
const STALL_W: int = 120
## The fixer's back room door, the security camera pole and the failing pump
## (spots in ArtMarketFloor stand in front of them).
const BACK_DOOR_X: int = 972
const CAM_POLE_X: int = 716
const PUMP_X: int = 1214
## Sized for the cast's 8-head body (72 px is about 1.8 m, so 1 m is 40 px):
## a doorway about 2.1 m, a counter about 1 m.
const DOOR_H: int = 84
const COUNTER_H: int = 40
## The boarded stall front that hides the heat-sealed door to Cold Storage.
const HEAT_STALL_X: int = 148
const HEAT_STALL_W: int = 96

## Parallax factor for each back layer, by name.
## Fog bands (FogArt) move with the layer they sit in front of.
const PARALLAX: Dictionary[String, float] = {
	"sky": 0.0, "city": 0.2, "fog_far": 0.2, "signs": 0.35, "fog_signs": 0.35,
	"arcology": 0.5, "fog_mid": 0.5, "shanties": 0.78, "fog_low": 0.78, "market": 1.0, "front": 1.3,
}


static func layer_width(layer: String) -> int:
	return VIEW.x + ceili(float(ROOM.x - VIEW.x) * PARALLAX[layer])


static func sky() -> Image:
	var img: Image = Px.blank(VIEW.x, VIEW.y)
	Px.vgrad(img, 0, 0, VIEW.x, 200, P.INK, P.NAVY, 5)
	Px.vgrad(img, 0, 200, VIEW.x, 100, P.NAVY, Color("1d2238"), 4)
	Px.vgrad(img, 0, 300, VIEW.x, 60, Color("1d2238"), P.NIGHT, 3)
	return img


## Far towers seen through the gap below the arcology deck.
static func city() -> Image:
	var w: int = layer_width("city")
	var img: Image = Px.blank(w, VIEW.y)
	var rng: RandomNumberGenerator = _rng(11)
	var x: int = -10
	while x < w:
		var tw: int = rng.randi_range(18, 46)
		var top: int = rng.randi_range(70, 210)
		var c: Color = Color("0d1524") if rng.randf() < 0.5 else Color("101a2b")
		Px.rect(img, x, top, tw, VIEW.y - top, c)
		if rng.randf() < 0.3:
			Px.rect(img, x + tw / 2 - 1, top - rng.randi_range(10, 30), 2, 30, c)
		for i: int in range(rng.randi_range(4, 22)):
			var wx: int = x + 2 + rng.randi_range(0, tw - 4)
			var wy: int = top + 3 + rng.randi_range(0, 120)
			var lit: Color = [Color(P.AMBER, 0.5), Color(P.CYAN, 0.35), Color(P.RAIN, 0.3)][rng.randi_range(0, 2)]
			Px.rect(img, wx, wy, 1 + rng.randi_range(0, 1), 1, lit)
		if rng.randf() < 0.18:
			# A far billboard.
			var bc: Color = P.MAGENTA if rng.randf() < 0.6 else P.CYAN
			Px.rect(img, x + 3, top + 12, tw - 6, 9, Color(bc, 0.35))
			Px.glow(img, x + tw * 0.5, top + 16, tw, 18, bc, 0.12)
		x += tw + rng.randi_range(-6, 4)
	# City glow and haze over the base.
	Px.screen(img, 0, 190, w, 120, Color("2a2440"), 0.35)
	Px.screen(img, 0, 240, w, 70, Color("3a2a48"), 0.3)
	return img


## The arcology overhead: its deck, its stilts, the strip lights under it.
static func arcology() -> Image:
	var w: int = layer_width("arcology")
	var img: Image = Px.blank(w, VIEW.y)
	var deck: Color = Color("0a111c")
	# Stilts first, the deck over them.
	for sx: int in [70, 400, 730]:
		_stilt(img, sx, 52)
	# Cross-bracing between the stilts.
	for pair: Array in [[118, 400], [448, 730]]:
		var a: int = pair[0]
		var z: int = pair[1]
		Px.line(img, Vector2i(a, 70), Vector2i(z, 150), Color("111a28"))
		Px.line(img, Vector2i(a, 71), Vector2i(z, 151), Color("111a28"))
		Px.line(img, Vector2i(a, 150), Vector2i(z, 70), Color("111a28"))
		Px.line(img, Vector2i(a, 151), Vector2i(z, 71), Color("111a28"))
	Px.rect(img, 0, 0, w, 44, deck)
	Px.vgrad(img, 0, 44, w, 10, deck, Color("141e2e"), 2)
	for rx: int in range(0, w, 32):
		Px.rect(img, rx, 30, 3, 20, Color("152031"))
	# Strip lights, cold and corporate, far above the market.
	for lx: int in range(12, w, 56):
		Px.rect(img, lx, 52, 18, 1, Color("bfefff"))
		Px.glow(img, lx + 9, 58, 26, 14, Color("9fdfff"), 0.18)
	# Mist so it sits back.
	Px.screen(img, 0, 120, w, 200, P.STORM, 0.28)
	return img


static func _stilt(img: Image, x: int, top: int) -> void:
	var sw: int = 48
	var face: Color = Color("151f2e")
	var lit: Color = Color("1f2b3d")
	Px.rect(img, x, top, sw, VIEW.y - top, face)
	Px.rect(img, x + sw - 8, top, 8, VIEW.y - top, lit)
	Px.rect(img, x, top, 3, VIEW.y - top, Color("0e1622"))
	var rng: RandomNumberGenerator = _rng(x)
	for i: int in range(18):
		var sx: int = x + rng.randi_range(4, sw - 6)
		var sy: int = top + rng.randi_range(0, 220)
		Px.rect(img, sx, sy, 1, rng.randi_range(8, 40), Color("2a384d"))
	for band: int in range(top + 40, VIEW.y, 64):
		Px.rect(img, x - 2, band, sw + 4, 3, Color("101826"))
	Px.text(img, x + 16, top + 70, "0" + str(x % 9 + 1), Color(P.AMBER_DIM, 0.6))


## Stacked shacks behind the market, lit windows, cables.
static func shanties() -> Image:
	var w: int = layer_width("shanties")
	var img: Image = Px.blank(w, VIEW.y)
	var rng: RandomNumberGenerator = _rng(23)
	var x: int = 0
	while x < w:
		var sw: int = rng.randi_range(40, 80)
		var floors: int = rng.randi_range(1, 3)
		var base: int = WATER_Y - 12
		for f: int in range(floors):
			var fh: int = rng.randi_range(26, 38)
			var fx: int = x + rng.randi_range(-4, 6)
			var fw: int = sw - rng.randi_range(0, 14)
			var top: int = base - fh
			Px.rect(img, fx, top, fw, fh, Color("0f1724"))
			Px.rect(img, fx - 2, top - 2, fw + 4, 2, Color("172133"))
			for wi: int in range(rng.randi_range(0, 3)):
				var wx: int = fx + 4 + rng.randi_range(0, maxi(fw - 12, 1))
				var c: Color = [P.AMBER_DIM, Color("3a5f6a"), P.MAGENTA_DIM][rng.randi_range(0, 2)]
				Px.rect(img, wx, top + 8, 6, 5, c)
				Px.glow(img, wx + 3, top + 10, 10, 8, c, 0.2)
			base = top - 2
		Px.rect(img, x + sw / 2, WATER_Y - 12, 3, 30, Color("0b121d"))
		x += sw + rng.randi_range(2, 14)
	for i: int in range(6):
		var a: int = rng.randi_range(0, w - 120)
		Px.cable(img, Vector2i(a, rng.randi_range(150, 200)), Vector2i(a + rng.randi_range(80, 160), rng.randi_range(150, 200)), 14, Color("0a101a"))
	Px.screen(img, 0, 150, w, 160, P.STORM, 0.12)
	return img


## The playable layer: the walkway, the stalls along it, Vale's stall.
static func market() -> Image:
	var img: Image = Px.blank(ROOM.x, VIEW.y)
	var rng: RandomNumberGenerator = _rng(5)
	# Stalls along the back of the walkway.
	var stalls: Array[Array] = [
		[24, 110, 130, "DECKS"], [HEAT_STALL_X, HEAT_STALL_W, 112, ""], [252, 92, 140, "RECALL"],
		[STALL_X, STALL_W, 128, ""], [STALL_X + STALL_W + 6, 104, 118, "BUY SELL"],
		[590, 120, 150, ""], [722, 88, 120, ""], [826, 130, 136, "MEMORIES"],
		[BACK_DOOR_X, 100, 128, ""], [1086, 120, 132, "OPEN"],
	]
	for s: Array in stalls:
		if s[0] == STALL_X:
			_vale_stall(img)
		elif s[0] == HEAT_STALL_X:
			_boarded(img, s[0], s[1], s[2])
		elif s[0] == BACK_DOOR_X:
			_back_door(img, s[0], s[1], s[2])
		else:
			_stall(img, s[0], s[1], s[2], s[3], rng)
	_pump(img)
	_camera_pole(img)
	# Strings of bulbs over the walkway.
	for span: Array in [[0, 260, 150], [260, 600, 140], [600, 930, 152], [930, 1280, 146]]:
		var pts: PackedVector2Array = Px.cable(img, Vector2i(span[0], span[2]), Vector2i(span[1], span[2] - 4), 22, Color("070b12"))
		for i: int in range(6, pts.size(), 18):
			var p: Vector2 = pts[i]
			var bulb: Color = P.AMBER if (i / 18) % 4 != 2 else P.MAGENTA
			Px.dot(img, int(p.x), int(p.y) + 1, bulb)
			Px.dot(img, int(p.x), int(p.y) + 2, Color(bulb, 0.6))
			Px.glow(img, p.x + 0.5, p.y + 3, 9, 7, bulb, 0.18)
	_walkway(img)
	return img


static func _stall(img: Image, x: int, w: int, h: int, sign: String, rng: RandomNumberGenerator) -> void:
	var top: int = WALK_Y - h
	var body: Color = [Color("141d2b"), Color("161c26"), Color("121a22")][rng.randi_range(0, 2)]
	Px.rect(img, x, top, w, h, body)
	# Corrugated sides.
	for cx: int in range(x + 2, x + w - 1, 4):
		Px.rect(img, cx, top + 4, 1, h - 4, Color(body.lightened(0.12), 0.8))
	# Awning or tarp roof, dripping.
	var awning: Color = [P.TARP, Color("2a2b3c"), Color("33282c"), Color("1f3133")][rng.randi_range(0, 3)]
	Px.poly(img, PackedVector2Array([Vector2(x - 8, top + 4), Vector2(x + w + 8, top + 4), Vector2(x + w + 2, top - 8), Vector2(x - 2, top - 8)]), awning)
	Px.rect(img, x - 8, top + 4, w + 16, 1, awning.darkened(0.4))
	for dx: int in range(x - 6, x + w + 6, 7):
		if rng.randf() < 0.45:
			Px.rect(img, dx, top + 5, 1, rng.randi_range(1, 3), Color(P.RAIN, 0.4))
	# Counter with an open front and a lamp.
	var counter_y: int = WALK_Y - COUNTER_H
	Px.rect(img, x + 6, top + 18, w - 12, counter_y - top - 18, Color("0a0f17"))
	Px.rect(img, x + 4, counter_y, w - 8, 4, Color("2a3442"))
	Px.rect(img, x + 4, counter_y + 4, w - 8, WALK_Y - counter_y - 4, body.darkened(0.2))
	var lamp: Color = P.AMBER if rng.randf() < 0.7 else Color("9fdfff")
	Px.rect(img, x + w / 2 - 3, top + 18, 6, 2, Color("1a1a1a"))
	Px.rect(img, x + w / 2 - 2, top + 20, 4, 1, lamp)
	Px.glow(img, x + w * 0.5, counter_y - 10.0, w * 0.45, 26, lamp, 0.26)
	Px.glow(img, x + w * 0.5, float(counter_y), w * 0.45, 6, lamp, 0.3)
	# Wares: chips and decks on the counter, racks behind.
	for i: int in range(rng.randi_range(3, 7)):
		var wx: int = x + 8 + rng.randi_range(0, w - 20)
		Px.rect(img, wx, counter_y - 3, rng.randi_range(2, 6), 3, [P.STEEL, P.CYAN_DIM, Color("3a3040"), P.AMBER_DIM][rng.randi_range(0, 3)])
	for ry: int in range(top + 26, counter_y - 6, 9):
		Px.rect(img, x + 10, ry, w - 20, 1, Color("1b2535"))
		for i: int in range(rng.randi_range(2, 6)):
			Px.rect(img, x + 12 + rng.randi_range(0, w - 26), ry - 3, 2, 3, Color(P.CYAN_DIM, 0.7) if rng.randf() < 0.3 else Color("273244"))
	if sign != "":
		_sign(img, x + w / 2, top - 22, sign, P.MAGENTA if rng.randf() < 0.55 else P.CYAN)


## A neon sign: tube letters, a dark backing, light spilling on the wall.
static func _sign(img: Image, cx: int, y: int, word: String, c: Color) -> void:
	var tw: int = Px.text_width(word)
	var x: int = cx - tw / 2
	Px.rect(img, x - 3, y - 3, tw + 6, 11, Color("0a0d14"))
	Px.glow(img, cx, y + 2, tw * 0.9 + 8, 16, c, 0.28)
	Px.text(img, x + 1, y + 1, word, Color(c, 0.35))
	Px.text(img, x, y, word, c)


## Ines Vale's stall: shutter down, police tape, a badge reader, one dying lamp,
## and the only blood in the room.
static func _vale_stall(img: Image) -> void:
	var x: int = STALL_X
	var w: int = STALL_W
	var h: int = 128
	var top: int = WALK_Y - h
	Px.rect(img, x, top, w, h, Color("161a24"))
	Px.poly(img, PackedVector2Array([Vector2(x - 8, top + 4), Vector2(x + w + 8, top + 4), Vector2(x + w + 2, top - 8), Vector2(x - 2, top - 8)]), Color("2e2a30"))
	Px.rect(img, x - 8, top + 4, w + 16, 1, Color("17141a"))
	# Shutter, pulled down and sealed.
	Px.rect(img, x + 8, top + 16, w - 16, h - 16, Color("262d38"))
	for sy: int in range(top + 18, WALK_Y, 4):
		Px.rect(img, x + 8, sy, w - 16, 1, Color("1a2029"))
	Px.rect(img, x + 8, WALK_Y - 3, w - 16, 3, Color("12161e"))
	# The seal: a cold-welded seam down the middle.
	Px.rect(img, x + w / 2, top + 16, 1, h - 16, Color("3a4556"))
	# Something dark has run out from under it.
	for i: int in range(5):
		Px.rect(img, x + 46 + i * 5, WALK_Y - 1, 3 + (i % 2) * 3, 1, P.BLOOD)
	Px.rect(img, x + 52, WALK_Y, 14, 2, P.BLOOD)
	Px.rect(img, x + 58, WALK_Y + 2, 5, 1, Color(P.BLOOD, 0.7))
	# Police tape, two strips across the front, sagging and wet.
	Px.cable(img, Vector2i(x + 2, top + 40), Vector2i(x + w - 2, top + 70), 6, P.AMBER)
	Px.cable(img, Vector2i(x + 2, top + 41), Vector2i(x + w - 2, top + 71), 6, P.AMBER_DIM)
	Px.cable(img, Vector2i(x + 2, top + 74), Vector2i(x + w - 2, top + 50), 6, P.AMBER)
	Px.cable(img, Vector2i(x + 2, top + 75), Vector2i(x + w - 2, top + 51), 6, P.AMBER_DIM)
	for tx: int in range(x + 10, x + w - 8, 12):
		Px.dot(img, tx, top + 44 + (tx - x) / 4, P.INK)
	# Badge reader by the shutter, waiting for a detective's badge.
	Px.rect(img, x + w - 6, top + 52, 6, 12, Color("0c1018"))
	Px.rect(img, x + w - 5, top + 54, 4, 2, P.CYAN)
	Px.rect(img, x + w - 5, top + 58, 4, 4, Color("1b2535"))
	Px.glow(img, x + w - 3, top + 55, 10, 8, P.CYAN, 0.25)


## The fixer's back room: a steel door set into a blank wall where a stall
## would be, a slot at eye height, and the fixer's magenta over the frame.
static func _back_door(img: Image, x: int, w: int, h: int) -> void:
	var top: int = WALK_Y - h
	Px.rect(img, x, top, w, h, Color("12161f"))
	for cx: int in range(x + 3, x + w - 2, 6):
		Px.rect(img, cx, top + 2, 1, h - 2, Color("171c27"))
	Px.rect(img, x - 4, top, w + 8, 3, Color("0c1018"))
	var dx: int = x + w / 2 - 16
	var dw: int = 32
	var dtop: int = WALK_Y - DOOR_H
	# Frame, door, rivets, a scuffed kick plate.
	Px.rect(img, dx - 3, dtop - 3, dw + 6, DOOR_H + 3, Color("0a0d14"))
	Px.rect(img, dx, dtop, dw, DOOR_H, Color("2a3240"))
	Px.rect(img, dx, dtop, dw, 1, Color("3c4656"))
	Px.rect(img, dx + dw - 1, dtop, 1, DOOR_H, Color("1c222d"))
	for ry: int in [dtop + 4, dtop + DOOR_H / 2, dtop + DOOR_H - 6]:
		Px.dot(img, dx + 3, ry, P.CONCRETE)
		Px.dot(img, dx + dw - 4, ry, P.CONCRETE)
	Px.rect(img, dx + 2, WALK_Y - 11, dw - 4, 9, Color("222934"))
	for i: int in range(5):
		Px.rect(img, dx + 4 + i * 5, WALK_Y - 9 + (i % 2), 3, 1, Color("303a48"))
	# The slot at eye height, shut, with light behind it; the handle at hip height.
	Px.rect(img, dx + 7, dtop + 13, dw - 14, 3, Color("07090e"))
	Px.rect(img, dx + 8, dtop + 15, dw - 16, 1, Color(P.MAGENTA_DIM, 0.9))
	Px.rect(img, dx + dw - 6, WALK_Y - 42, 2, 6, Color("151a22"))
	# A strip of magenta over the frame and its spill.
	Px.rect(img, dx - 2, dtop - 8, dw + 4, 2, P.MAGENTA)
	Px.glow(img, dx + dw * 0.5, dtop - 6.0, dw * 0.9, 14, P.MAGENTA, 0.3)
	Px.glow(img, dx + dw * 0.5, float(WALK_Y), dw * 0.8, 6, P.MAGENTA, 0.12)
	Px.text(img, dx + dw / 2 - Px.text_width("PRIVATE") / 2, dtop + 28, "PRIVATE", Color(P.RAIN, 0.35))


## A stall front boarded over: plank on plank, nailed shut, a warning
## stencil. Nothing to look at, unless you can see heat.
static func _boarded(img: Image, x: int, w: int, h: int) -> void:
	var top: int = WALK_Y - h
	Px.poly(img, PackedVector2Array([Vector2(x - 8, top + 4), Vector2(x + w + 8, top + 4), Vector2(x + w + 2, top - 8), Vector2(x - 2, top - 8)]), Color("232a33"))
	Px.rect(img, x, top + 4, w, h - 4, Color("131820"))
	var rng: RandomNumberGenerator = _rng(148)
	for by: int in range(top + 8, WALK_Y - 2, 9):
		var shift: int = rng.randi_range(-3, 3)
		Px.rect(img, x + 2 + shift, by, w - 4, 7, Color("1d232c") if rng.randf() < 0.5 else Color("1a2029"))
		Px.rect(img, x + 2 + shift, by, w - 4, 1, Color("29313c"))
		for nx: int in [x + 6 + shift, x + w - 8 + shift]:
			Px.dot(img, nx, by + 3, P.CONCRETE)
	Px.text(img, x + w / 2 - Px.text_width("KEEP OUT") / 2, top + 50, "KEEP OUT", Color(P.AMBER_DIM, 0.8))


## What the thermal optic sees in the boarded stall: the outline of a door
## behind the planks, still hot along its seal.
static func heat_seam() -> Image:
	var w: int = 44
	var h: int = DOOR_H
	var img: Image = Px.blank(w, h)
	for y: int in range(h):
		for x: int in range(w):
			var edge: bool = x < 3 or x >= w - 3 or y < 3
			if edge:
				Px.dot(img, x, y, Color(1, 1, 1, 1.0 if (x + y) % 5 != 0 else 0.7))
			elif x == w / 2 or x == w / 2 - 1:
				Px.dot(img, x, y, Color(1, 1, 1, 0.55))
	return img


## The market's failing pump at the east end: a boxy housing, pipes down
## into the water, a hazard band and a work lamp left on the planks.
static func _pump(img: Image) -> void:
	var x: int = PUMP_X
	var w: int = 46
	var top: int = WALK_Y - 64
	for px: int in [x + 6, x + 30]:
		Px.rect(img, px, top - 70, 7, 70, Color("161d28"))
		Px.rect(img, px + 1, top - 70, 1, 70, Color("2a3442"))
		Px.rect(img, px - 1, top - 40, 9, 3, Color("0d1118"))
	Px.rect(img, x, top, w, 64, Color("1d2632"))
	Px.rect(img, x, top, w, 2, Color("3a4658"))
	Px.rect(img, x + w - 3, top, 3, 64, Color("141a24"))
	for hx: int in range(x + 2, x + w - 4, 6):
		Px.rect(img, hx, top + 10, 3, 4, P.AMBER_DIM)
		Px.rect(img, hx + 3, top + 10, 3, 4, P.INK)
	# A gauge with its needle pinned in the amber.
	Px.ellipse(img, x + 14, top + 28, 6, 6, Color("0c1018"))
	Px.ellipse(img, x + 14, top + 28, 5, 5, Color("4a5563"))
	Px.line(img, Vector2i(x + 14, top + 28), Vector2i(x + 18, top + 24), P.AMBER)
	# Access panel hanging open, and leaking.
	Px.rect(img, x + 24, top + 22, 16, 22, Color("07090e"))
	Px.rect(img, x + 40, top + 22, 3, 22, Color("2a3442"))
	for i: int in range(5):
		Px.rect(img, x + 27 + i * 3, top + 44 + i % 2, 1, 2 + i % 3, Color(P.RAIN, 0.5))
	# Pipes down into the water.
	for px: int in [x + 8, x + 34]:
		Px.rect(img, px, WALK_Y, 5, WATER_Y - WALK_Y + 4, Color("10161f"))
	# The work lamp on the planks, throwing light up the housing.
	Px.rect(img, x - 6, WALK_Y - 5, 5, 5, Color("1a1a1a"))
	Px.rect(img, x - 5, WALK_Y - 5, 3, 1, P.AMBER)
	Px.glow(img, x + 4, WALK_Y - 18.0, 34, 22, P.AMBER, 0.22)


## A security camera on a pole between two stalls, turned back toward Vale's.
static func _camera_pole(img: Image) -> void:
	var x: int = CAM_POLE_X
	Px.rect(img, x - 1, 112, 3, WALK_Y - 112, Color("0c1119"))
	Px.rect(img, x, 112, 1, WALK_Y - 112, Color("222c3a"))
	Px.rect(img, x - 3, WALK_Y - 4, 7, 4, Color("0c1119"))
	# Arm and housing, looking left and down.
	Px.rect(img, x - 8, 112, 9, 2, Color("1a2230"))
	Px.poly(img, PackedVector2Array([Vector2(x - 22, 112), Vector2(x - 6, 109), Vector2(x - 6, 117), Vector2(x - 20, 119)]), Color("2a3442"))
	Px.rect(img, x - 21, 112, 14, 1, Color("3c4656"))
	Px.rect(img, x - 24, 113, 3, 5, Color("0a0d14"))
	Px.dot(img, x - 23, 115, P.CYAN)
	Px.glow(img, x - 23, 115, 6, 5, P.CYAN, 0.3)
	# Its status light, still blinking for whoever pulls the feed.
	Px.dot(img, x - 9, 111, P.AMBER)


## Wet planks over the water, posts going down into it.
static func _walkway(img: Image) -> void:
	Px.rect(img, 0, WALK_Y, ROOM.x, 6, Color("1a2230"))
	Px.rect(img, 0, WALK_Y, ROOM.x, 1, Color("3a4658"))
	Px.rect(img, 0, WALK_Y + 6, ROOM.x, 4, Color("0d131d"))
	var rng: RandomNumberGenerator = _rng(41)
	for px: int in range(0, ROOM.x, 22):
		Px.rect(img, px, WALK_Y + 1, 1, 5, Color("10161f"))
	# Wet sheen catching the neon.
	for i: int in range(120):
		var sx: int = rng.randi_range(0, ROOM.x)
		var c: Color = [Color(P.AMBER, 0.45), Color(P.MAGENTA, 0.4), Color(P.CYAN, 0.35), Color(P.RAIN, 0.3)][rng.randi_range(0, 3)]
		Px.rect(img, sx, WALK_Y + rng.randi_range(1, 4), rng.randi_range(2, 6), 1, c)
	for post: int in range(10, ROOM.x, 64):
		Px.rect(img, post, WALK_Y + 10, 5, WATER_Y - WALK_Y - 6, Color("0b1019"))


## Close foreground: dark pipes and hanging cable that frame the shot.
static func front() -> Image:
	var w: int = layer_width("front")
	var img: Image = Px.blank(w, VIEW.y)
	for fx: int in [8, 760, 1180]:
		Px.rect(img, fx, 0, 10, VIEW.y, Color("03050a"))
		Px.rect(img, fx + 9, 0, 1, VIEW.y, Color(P.MAGENTA_DIM, 0.8))
		Px.rect(img, fx - 4, 90, 18, 4, Color("03050a"))
	Px.cable(img, Vector2i(-10, 18), Vector2i(220, 30), 40, Color("03050a"))
	Px.cable(img, Vector2i(560, 8), Vector2i(900, 14), 50, Color("03050a"))
	Px.cable(img, Vector2i(561, 9), Vector2i(901, 15), 50, Color("03050a"))
	return img


## The hologram over the market: a turning head made of scanlines. `frame`
## shifts the scanlines and breaks the image now and then.
static func hologram(frame: int) -> Image:
	var img: Image = Px.blank(96, 112)
	var head: Image = Px.blank(96, 112)
	Px.ellipse(head, 48, 42, 20, 26, P.CYAN)
	Px.rect(head, 38, 62, 20, 16, P.CYAN)
	Px.poly(head, PackedVector2Array([Vector2(14, 110), Vector2(82, 110), Vector2(70, 80), Vector2(26, 80)]), P.CYAN)
	for y: int in range(112):
		var on: bool = (y + frame) % 3 != 0
		var glitch: int = 4 if (y / 7 + frame) % 11 == 0 else 0
		for x: int in range(96):
			if head.get_pixel(x, y).a > 0.0 and on:
				Px.dot(img, x + glitch, y, Color(P.CYAN, 0.5 if y % 2 == 0 else 0.3))
	# A band across the eyes, where the memory plays.
	Px.rect(img, 30, 38, 36, 4, Color(P.MAGENTA, 0.7))
	Px.text(img, 48 - Px.text_width("RECALL") / 2, 2, "RECALL", Color(P.CYAN, 0.9))
	return img


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
