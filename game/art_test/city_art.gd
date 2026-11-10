class_name CityArt
extends RefCounted
## Concept art of Halcyon Reach from a distance, drawn in code in the art test's
## style (ArtPalette, Px): one 640 x 360 establishing view across open water.
##
## The city as the Story doc has it: separate corporate arcologies on stilts,
## with open water and fog between them. Their lower decks make up the Waterline
## (neon, shanties, docks), joined by causeways and bridges; the tops of the
## tallest rise above the fog line as the Crown, each a broad terrace walled
## all round with a garden and buildings inside; the old city lies drowned below,
## and each arcology's legs stand in its hull, a caisson of watertight decks
## where the poor live, some above the water and some under it, scarred with
## the tidemarks of every rise. Kept apart from Midgar on
## purpose: no continuous deck, no numbered sectors, no single central tower.
##
## Drawn far to near, with fog between the depths. Everything is seeded, so the
## same code always draws the same city. Signs are placeholder words, not canon.

const P = preload("res://game/art/art_palette.gd")

const VIEW: Vector2i = Vector2i(640, 360)
## Where open water meets the far distance.
const HORIZON: int = 272
## The fog line: everything above FOG_TOP is the Crown, clear of the fog.
const FOG_TOP: int = 134
const FOG_BOTTOM: int = 190
const FOG_TINT: Color = Color("33435a")
## The Crown's own light: cold, clean, almost another world.
const CROWN_LIGHT: Color = Color("cfe9ff")

## Each arcology: centre x, its stilts' foot (where it meets the water), body
## width, top row, depth (0 far .. 1 near), shape, seed.
## Shapes: "setback" narrows in steps, "twin" is two shafts on one deck,
## "spire" tapers to a mast, "slab" is a plain block, "near" is the close one
## cropped by the frame, drawn floor by floor, and "sunk" is a dead arcology
## going down in the distance, its dome broken (width is its hull's).
const ARCOLOGIES: Array[Array] = [
	[92, 277, 30, 104, "setback", 1, 0.15],
	[300, 276, 24, 132, "slab", 2, 0.1],
	[452, 278, 32, 88, "spire", 3, 0.2],
	[462, 289, 110, 190, "sunk", 4, 0.35],
	[198, 293, 54, 56, "twin", 5, 0.55],
	[372, 297, 60, 72, "setback", 6, 0.6],
	[598, 352, 104, -20, "near", 7, 1.0],
]

## Far arcologies lost in the fog but for their Crowns: x, top row, width.
const FAR_CROWNS: Array[Array] = [[24, 118, 12], [162, 124, 10], [258, 114, 14], [338, 126, 9], [508, 116, 12], [404, 122, 8]]

## Causeways between Waterline decks: [from arcology, to arcology]. Indices into ARCOLOGIES.
const CAUSEWAYS: Array[Array] = [[0, 4], [4, 5], [1, 5], [5, 6], [2, 5]]

## Small neon on the Waterline decks: [arcology, offset from centre, word, color].
const DECK_SIGNS: Array[Array] = [
	[4, -30, "BAR", "magenta"], [4, 20, "PAWN", "amber"],
	[5, -26, "DECKS", "cyan"], [5, 26, "NOODLE", "magenta"],
	[6, -60, "HOTEL", "cyan"], [6, -18, "OPEN", "amber"],
]


static func depth_of(i: int) -> float:
	return ARCOLOGIES[i][6]


static func deck_y(i: int) -> int:
	var a: Array = ARCOLOGIES[i]
	return int(a[1]) - stilt_height(i)


static func stilt_height(i: int) -> int:
	return int(lerpf(9.0, 52.0, depth_of(i)))


static func deck_width(i: int) -> int:
	var a: Array = ARCOLOGIES[i]
	return int(float(a[2]) * 1.9)


## Arcologies whose tops clear the fog line, the Crown.
static func crown() -> Array[int]:
	var found: Array[int] = []
	for i: int in range(ARCOLOGIES.size()):
		if int(ARCOLOGIES[i][3]) < FOG_TOP:
			found.append(i)
	return found


## How wide an arcology's walled Crown is: a broad terrace, much wider than
## the shaft that carries it.
static func crown_width(i: int) -> int:
	var w: int = ARCOLOGIES[i][2]
	return int(float(w) * (1.7 if ARCOLOGIES[i][4] == "spire" else 1.95))


## How wide the shaft is where it meets the Crown. A setback narrows as it
## climbs, so its top step is the one the terrace and its struts must meet.
static func top_shaft_width(i: int) -> int:
	var w: int = ARCOLOGIES[i][2]
	if ARCOLOGIES[i][4] == "setback":
		return w - 2 * w / 4
	return w


## Where the struts under a Crown land: on the outer face of its top shaft.
static func strut_foot_x(i: int, side: int) -> int:
	return int(ARCOLOGIES[i][0]) + side * (top_shaft_width(i) / 2)


## The top of a Crown's wall. Above it, only the trees and the buildings inside.
static func rim_y(i: int) -> int:
	return int(ARCOLOGIES[i][3]) + int(lerpf(18.0, 30.0, depth_of(i)))


static func wall_height(i: int) -> int:
	return int(lerpf(6.0, 12.0, depth_of(i)))


## The flared underside that carries the terrace out over the shaft.
static func flare_height(i: int) -> int:
	return int(lerpf(6.0, 14.0, depth_of(i)))


static func sign_color(name: String) -> Color:
	match name:
		"magenta":
			return P.MAGENTA
		"amber":
			return P.AMBER
	return P.CYAN


## The whole view. `rain` adds a still of the rain, for screenshots; the scene
## draws live rain over the view instead.
static func compose(rain: bool = false) -> Image:
	var img: Image = sky()
	_beams(img)
	_water(img)
	var groups: Array[Array] = [
		# depth range, reflection row, fog after it
		[0.0, 0.3, HORIZON, 1.0],
		[0.3, 0.75, 295, 0.55],
		[0.75, 0.8, 320, 0.3],
		[0.8, 1.1, 352, 0.2],
	]
	for g: Array in groups:
		var layer: Image = Px.blank(VIEW.x, VIEW.y)
		if g[0] == 0.0:
			_drowned_city(layer)
			for c: Array in FAR_CROWNS:
				_far_crown(layer, c[0], c[1], c[2])
			_lighthouse(layer)
		if g[0] == 0.3:
			# The sunk arcology first, behind everything else at its distance.
			for i: int in range(ARCOLOGIES.size()):
				if ARCOLOGIES[i][4] == "sunk":
					_sunk_arcology(layer, i)
		for i: int in range(ARCOLOGIES.size()):
			var d: float = depth_of(i)
			if d >= g[0] and d < g[1] and ARCOLOGIES[i][4] != "sunk":
				_arcology(layer, i)
		for c: Array in CAUSEWAYS:
			var d: float = maxf(depth_of(c[0]), depth_of(c[1]))
			if d >= g[0] and d < g[1]:
				_causeway(layer, c[0], c[1])
		if g[0] == 0.3:
			_traffic(layer)
			_steeple(layer)
		if g[0] == 0.75:
			_chimney(layer)
			_bridge_arch(layer)
		if g[0] == 0.8:
			_moorings(layer)
		_reflect(img, layer, g[2])
		Px.stamp(img, layer, 0, 0)
		Px.stamp(img, fog(g[3]), 0, 0)
		if g[0] == 0.3:
			# The giant hologram ads hang in the air between the arcologies, in
			# front of the far fog, light enough to glow through what's left.
			var holo: Image = holograms()
			_reflect(img, holo, 295)
			Px.stamp(img, holo, 0, 0)
	_glints(img)
	if rain:
		rain_still(img)
	return img


static func sky() -> Image:
	var img: Image = Px.blank(VIEW.x, VIEW.y)
	Px.vgrad(img, 0, 0, VIEW.x, 140, P.INK, P.NAVY, 5)
	Px.vgrad(img, 0, 140, VIEW.x, HORIZON - 140, P.NAVY, Color("1d2238"), 4)
	# Low cloud, lit from below by the city: long flat banks, dithered at the ends.
	var rng: RandomNumberGenerator = _rng(41)
	for i: int in range(8):
		var cy: float = rng.randf_range(10.0, 92.0)
		var cx: float = rng.randf_range(0.0, float(VIEW.x))
		var rx: float = rng.randf_range(50.0, 120.0)
		var ry: float = rng.randf_range(3.0, 6.0)
		var c: Color = Color("111a2e").lerp(Color("19213a"), cy / 92.0)
		for yy: int in range(floori(cy - ry), ceili(cy + ry) + 1):
			for xx: int in range(floori(cx - rx), ceili(cx + rx) + 1):
				var dx: float = (xx + 0.5 - cx) / rx
				var dy: float = (yy + 0.5 - cy) / ry
				var dd: float = dx * dx + dy * dy
				if dd < 1.0 and (dd < 0.55 or Px.dither(xx, yy, (1.0 - dd) / 0.45)):
					Px.dot(img, xx, yy, Color(c, 0.55))
	return img


## Searchlights off the Crown, cold, sweeping the cloud.
static func _beams(img: Image) -> void:
	for b: Array in [[219, 36, -70, 0], [452, 46, 60, 0]]:
		var x: int = b[0]
		var y: int = b[1]
		var dx: int = b[2]
		for yy: int in range(0, y):
			var t: float = float(y - yy) / float(y)
			var bx: float = x + dx * t
			var half: float = 1.0 + t * 9.0
			for xx: int in range(floori(bx - half), ceili(bx + half)):
				if Px.dither(xx, yy, 0.5 * (1.0 - t * 0.7)):
					Px.dot(img, xx, yy, Color(CROWN_LIGHT, 0.12))


static func _water(img: Image) -> void:
	Px.vgrad(img, 0, HORIZON, VIEW.x, VIEW.y - HORIZON, Color("0c1626"), P.WATER, 4)


## The old city under the water: rooftops and a few dead towers breaking the
## surface along the horizon, with the odd window still lit by someone living there.
static func _drowned_city(img: Image) -> void:
	var rng: RandomNumberGenerator = _rng(17)
	var x: int = 0
	while x < VIEW.x:
		var w: int = rng.randi_range(8, 26)
		var h: int = rng.randi_range(1, 7)
		if rng.randf() < 0.12:
			h = rng.randi_range(10, 22)  # an old tower, gutted, still standing
		var c: Color = Color("152035") if rng.randf() < 0.5 else Color("18243a")
		Px.rect(img, x, HORIZON - h, w, h + 2, c)
		if h > 9:
			for wy: int in range(HORIZON - h + 2, HORIZON - 1, 3):
				if rng.randf() < 0.3:
					Px.rect(img, x + rng.randi_range(1, w - 2), wy, 1, 1, Color(P.AMBER, 0.5))
		elif rng.randf() < 0.25:
			Px.rect(img, x + rng.randi_range(1, w - 2), HORIZON - 1, 1, 1, Color(P.AMBER, 0.45))
		x += w + rng.randi_range(2, 14)


# ---------- Hologram ads ----------
# Giant floating advertisements, projected into the air between the arcologies.
# Each is see-through, cut by scanlines, with a band that slips sideways, and
# lights the fog around it. The products are placeholders, not canon.

## A whale gliding between the arcologies, facing left: the big ad, for the
## open sea nobody down here has seen in years.
const WHALE_AT: Vector2i = Vector2i(222, 146)
const WHALE_SCALE: float = 1.2
const WHALE: PackedVector2Array = [
	Vector2(0, 18), Vector2(4, 12), Vector2(14, 8), Vector2(30, 6), Vector2(50, 7),
	Vector2(66, 10), Vector2(78, 14), Vector2(88, 17), Vector2(95, 9), Vector2(101, 5),
	Vector2(99, 15), Vector2(103, 27), Vector2(96, 25), Vector2(88, 20), Vector2(78, 22),
	Vector2(60, 26), Vector2(40, 28), Vector2(22, 27), Vector2(10, 25), Vector2(3, 22),
]
const WHALE_FIN: PackedVector2Array = [Vector2(28, 24), Vector2(40, 26), Vector2(36, 38), Vector2(29, 35)]
## A panel ad hung under a drone, and a jellyfish drifting over the fog line.
const PANEL_AT: Vector2i = Vector2i(254, 74)
const JELLY_AT: Vector2i = Vector2i(500, 84)


## All the hologram ads on one see-through layer.
static func holograms() -> Image:
	var img: Image = Px.blank(VIEW.x, VIEW.y)
	_whale_ad(img)
	_panel_ad(img)
	_jelly_ad(img)
	return img


## The whale: cyan, its throat grooves and fin lit, a line of text under it.
static func _whale_ad(img: Image) -> void:
	var k: float = WHALE_SCALE
	var shape: Image = Px.blank(ceili(106 * k), ceili(46 * k))
	Px.poly(shape, _scaled(WHALE, k), P.CYAN_DIM.lerp(P.CYAN, 0.6))
	Px.poly(shape, _scaled(WHALE_FIN, k), P.CYAN)
	# The back, lit along its top edge.
	for i: int in range(9):
		Px.line(shape, Vector2i(WHALE[i] * k), Vector2i(WHALE[i + 1] * k), P.CYAN.lerp(Color.WHITE, 0.5))
	# Throat grooves along the belly, magenta.
	for g: int in range(3):
		var y: float = (21.0 + g * 2.0) * k
		Px.line(shape, Vector2i(roundi(6 * k), roundi(y)), Vector2i(roundi(44 * k), roundi(y + 2.0 * k)), P.MAGENTA)
	Px.dot(shape, roundi(10 * k), roundi(16 * k), Color.WHITE)  # the eye
	# A line of text under it, too far to read: just its shape.
	for i: int in range(9):
		Px.rect(shape, roundi(30 * k) + i * 5, roundi(42 * k), 4, 2, P.MAGENTA)
	var w: int = shape.get_width()
	var h: int = shape.get_height()
	Px.glow(img, WHALE_AT.x + w * 0.5, WHALE_AT.y + h * 0.5, w * 0.75, h * 1.1, P.CYAN, 0.12)
	_holo_stamp(img, shape, WHALE_AT.x, WHALE_AT.y, 0.55, 24)


static func _scaled(points: PackedVector2Array, k: float) -> PackedVector2Array:
	var out: PackedVector2Array = []
	for p: Vector2 in points:
		out.append(p * k)
	return out


## A panel ad under a drone: one word, a pill, cyan.
static func _panel_ad(img: Image) -> void:
	var shape: Image = Px.blank(56, 26)
	Px.rect(shape, 0, 0, 56, 1, P.CYAN)
	Px.rect(shape, 0, 25, 56, 1, P.CYAN)
	Px.rect(shape, 0, 0, 1, 26, P.CYAN)
	Px.rect(shape, 55, 0, 1, 26, P.CYAN)
	Px.screen(shape, 1, 1, 54, 24, P.CYAN_DIM, 0.5)
	Px.text_scaled(shape, 4, 4, "SLEEP", P.CYAN.lerp(Color.WHITE, 0.4), 2)
	# The pill: a capsule, half white, half cyan.
	Px.ellipse(shape, 47.0, 9.0, 4.5, 2.5, Color.WHITE)
	Px.ellipse(shape, 49.5, 9.0, 2.5, 2.5, P.CYAN)
	Px.text(shape, 4, 17, "DOSE DEEP", P.CYAN)
	Px.glow(img, PANEL_AT.x + 28, PANEL_AT.y + 13, 46, 26, P.CYAN, 0.14)
	_holo_stamp(img, shape, PANEL_AT.x, PANEL_AT.y, 0.6, 12)
	# The drone carrying it, solid, with its cables.
	var dx: int = PANEL_AT.x + 28
	var dy: int = PANEL_AT.y - 12
	Px.rect(img, dx - 5, dy, 10, 3, Color("0f1724"))
	Px.rect(img, dx - 8, dy - 1, 4, 1, Color("1e2a3c"))
	Px.rect(img, dx + 4, dy - 1, 4, 1, Color("1e2a3c"))
	Px.dot(img, dx, dy + 2, P.AMBER)
	Px.line(img, Vector2i(dx - 3, dy + 3), Vector2i(PANEL_AT.x + 2, PANEL_AT.y), Color("1e2a3c"))
	Px.line(img, Vector2i(dx + 3, dy + 3), Vector2i(PANEL_AT.x + 53, PANEL_AT.y), Color("1e2a3c"))


## A jellyfish drifting over the fog line, amber: an ad with no words at all.
static func _jelly_ad(img: Image) -> void:
	var shape: Image = Px.blank(32, 44)
	# The bell, its top half, with a bright rim.
	for y: int in range(0, 11):
		for x: int in range(0, 32):
			var dx: float = (x + 0.5 - 16.0) / 15.0
			var dy: float = (y + 0.5 - 11.0) / 11.0
			if dx * dx + dy * dy <= 1.0:
				Px.dot(shape, x, y, P.AMBER if dx * dx + dy * dy > 0.7 else Color(P.AMBER_DIM, 1.0))
	Px.rect(shape, 2, 10, 28, 1, P.AMBER.lerp(Color.WHITE, 0.5))
	# Tentacles, wavy.
	for k: int in range(6):
		var tx: int = 4 + k * 5
		for y: int in range(11, 40 - (k % 3) * 5):
			Px.dot(shape, tx + roundi(sin(y * 0.35 + k) * 1.5), y, Color(P.AMBER, 1.0 - float(y - 11) / 34.0))
	Px.glow(img, JELLY_AT.x + 16, JELLY_AT.y + 12, 34, 30, P.AMBER, 0.14)
	_holo_stamp(img, shape, JELLY_AT.x, JELLY_AT.y, 0.6, 18)


## Puts a hologram on `dst`: see-through, every other row dimmer, and one
## band of rows `slip` rows down shifted sideways, as if the signal skipped.
static func _holo_stamp(dst: Image, src: Image, x: int, y: int, alpha: float, slip: int) -> void:
	for yy: int in range(src.get_height()):
		var shift: int = 2 if yy >= slip and yy < slip + 3 else 0
		var row: float = alpha if yy % 2 == 0 else alpha * 0.45
		for xx: int in range(src.get_width()):
			var c: Color = src.get_pixel(xx, yy)
			if c.a <= 0.0:
				continue
			Px.dot(dst, x + xx + shift, y + yy, Color(c, c.a * row))


# ---------- Port Patience ----------
# The drowned city under Halcyon Reach (Story doc, decided 2026-11-07). A few of
# its landmarks still break the surface between the arcologies, so players
# see it before anyone names it.

const OLD_STONE: Color = Color("5f6a78")  # weathered white paint, greyed by fog
const OLD_BRICK: Color = Color("2c2429")
const OLD_IRON: Color = Color("2c3748")
## Where the landmarks stand: the steeple between the two near arcologies, the
## lighthouse far out on the left, the chimney and bridge arch closer in.
const STEEPLE: Vector2i = Vector2i(272, 292)
const LIGHTHOUSE: Vector2i = Vector2i(34, 273)
const CHIMNEY: Vector2i = Vector2i(128, 318)
const BRIDGE: Vector3i = Vector3i(262, 344, 321)  # left x, right x, waterline


## The meeting-house steeple, leaning a little, standing out of open water:
## the one shape players learn to find on every skyline.
static func _steeple(img: Image) -> void:
	var bx: int = STEEPLE.x
	var base: int = STEEPLE.y
	var face: Color = OLD_STONE
	var shade: Color = OLD_STONE.darkened(0.4)
	var tower: int = 24     # clapboard tower above the water
	var belfry: int = 12
	var spire: int = 26
	var w: int = 10
	for y: int in range(base - tower - belfry - spire, base + 1):
		var up: int = base - y
		var x: int = bx + up / 16   # the lean: a pixel every 16 rows
		if up < tower:
			Px.rect(img, x, y, w, 1, shade if up % 3 == 0 else face)
			Px.rect(img, x + w - 3, y, 3, 1, shade)
			if up > 8 and up < 16:
				Px.rect(img, x + 3, y, 3, 1, P.INK)  # a tall window, dark
		elif up < tower + 2:
			Px.rect(img, x - 1, y, w + 2, 1, face)  # cornice
		elif up < tower + belfry:
			# The bell-loft: corner posts, an arched opening, the dark inside.
			Px.rect(img, x + 1, y, w - 2, 1, face)
			var open_top: int = tower + belfry - 3
			if up < open_top:
				Px.rect(img, x + 3, y, w - 6, 1, P.INK)
			elif up == open_top:
				Px.rect(img, x + 4, y, w - 8, 1, P.INK)
			Px.dot(img, x + w - 2, y, shade)
		elif up < tower + belfry + 2:
			Px.rect(img, x, y, w, 1, face)
		else:
			var t: float = float(up - tower - belfry - 2) / float(spire - 2)
			var half: float = (float(w) * 0.5 - 1.0) * (1.0 - t) + 0.5
			var cx: float = x + w * 0.5
			for xx: int in range(floori(cx - half), ceili(cx + half)):
				Px.dot(img, xx, y, face if xx < floori(cx) else shade)
	# The weathervane, bent.
	var top: int = base - tower - belfry - spire
	var tip: Vector2i = Vector2i(bx + (tower + belfry + spire) / 16 + w / 2, top)
	Px.line(img, tip, tip + Vector2i(0, -4), shade)
	Px.line(img, tip + Vector2i(0, -4), tip + Vector2i(3, -5), shade)
	# Wet black where the water laps it, and its own pale tidemark.
	Px.rect(img, bx, base - 1, w, 2, Color("05080f"))
	Px.rect(img, bx, base - 6, w, 1, Color(P.GLINT, 0.45))


## A lighthouse far out, dark, its lamp long dead.
static func _lighthouse(img: Image) -> void:
	var x: int = LIGHTHOUSE.x
	var base: int = LIGHTHOUSE.y
	var c: Color = Color("2a3446")
	for y: int in range(base - 22, base + 1):
		var up: int = base - y
		var half: int = 3 if up < 10 else 2
		Px.rect(img, x - half, y, half * 2 + 1, 1, c if (up / 5) % 2 == 0 else c.lightened(0.12))
	# Gallery and the dead lamp room.
	Px.rect(img, x - 3, base - 23, 7, 1, c)
	Px.rect(img, x - 1, base - 27, 3, 4, P.INK)
	Px.dot(img, x, base - 26, Color(P.GLINT, 0.25))  # glass catching the city, nothing more
	Px.rect(img, x - 2, base - 28, 5, 1, c)
	Px.dot(img, x, base - 29, c)


## A brick mill chimney, closer in, its top broken off.
static func _chimney(img: Image) -> void:
	var x: int = CHIMNEY.x
	var base: int = CHIMNEY.y
	var h: int = 52
	for y: int in range(base - h, base + 1):
		var up: int = base - y
		var w: int = 9 if up < 34 else 8
		if up > h - 5:
			w = 10  # the corbelled band near the top
		var c: Color = OLD_BRICK if up % 7 != 0 else OLD_BRICK.darkened(0.3)
		Px.rect(img, x - w / 2, y, w, 1, c)
		Px.dot(img, x + w - w / 2 - 1, y, OLD_BRICK.lightened(0.15))
	# The broken top: a ragged edge.
	for k: int in range(5):
		Px.dot(img, x - 3 + k * 2, base - h - [1, 0, 2, 0, 1][k], OLD_BRICK)
	Px.rect(img, x - 5, base - 1, 10, 2, Color("05080f"))
	Px.rect(img, x - 5, base - 7, 10, 1, Color(P.GLINT, 0.4))


## The top of an old iron bridge arch, the rest of the bridge under water.
static func _bridge_arch(img: Image) -> void:
	var x0: int = BRIDGE.x
	var x1: int = BRIDGE.y
	var water: int = BRIDGE.z
	var span: float = float(x1 - x0)
	var rise: float = 20.0
	var last_top: Vector2i = Vector2i(x0, water)
	var last_low: Vector2i = Vector2i(x0, water)
	for k: int in range(0, int(span) + 1):
		var t: float = float(k) / span
		var arc: float = rise * 4.0 * t * (1.0 - t)
		var top: Vector2i = Vector2i(x0 + k, water - roundi(arc))
		var low: Vector2i = Vector2i(x0 + k, water - roundi(arc * 0.6))
		Px.line(img, last_top, top, OLD_IRON)
		Px.dot(img, top.x, top.y - 1, Color(P.RAIN, 0.35))
		Px.line(img, last_low, low, OLD_IRON)
		# The lattice between the two chords.
		if k % 6 == 0 and k > 0:
			Px.line(img, top, Vector2i(x0 + k - 6, water - roundi(rise * 4.0 * (float(k - 6) / span) * (1.0 - float(k - 6) / span) * 0.6)), OLD_IRON)
		last_top = top
		last_low = low
	# Rust where the paint has gone, picked out by the city's light.
	for k: int in range(8, int(span) - 6, 11):
		var t: float = float(k) / span
		Px.dot(img, x0 + k, water - roundi(rise * 4.0 * t * (1.0 - t)), Color(P.RUST, 0.9))


## One arcology: stilts with their tidemarks, the Waterline deck on them, the
## body rising into the fog and, for the tallest, a Crown above it.
static func _arcology(img: Image, i: int) -> void:
	var a: Array = ARCOLOGIES[i]
	var cx: int = a[0]
	var w: int = a[2]
	var top: int = a[3]
	var shape: String = a[4]
	var d: float = depth_of(i)
	var rng: RandomNumberGenerator = _rng(int(a[5]) * 97)
	# Far things sit back in the haze: lighter and bluer.
	var body: Color = Color("1b2840").lerp(Color("0a111c"), d)
	var lit_side: Color = Color("24344d").lerp(Color("172234"), d)
	var dark_side: Color = body.darkened(0.25)
	var deck: int = deck_y(i)
	_stilts(img, i, body, dark_side)
	_hull(img, i, body, rng)
	var x0: int = cx - w / 2
	if shape == "near":
		_near_tower(img, i, body, lit_side, dark_side, rng)
		_deck(img, i, body, lit_side, rng)
		return
	# The podium: the arcology's lower town, wider than its tower, stacked
	# up from the deck in tiers, lit warm by the people who live in it.
	var pod_h: int = int(lerpf(14.0, 46.0, d))
	var pod_w: int = int(float(w) * 1.45)
	for tier: int in range(3):
		var tw: int = pod_w - tier * (pod_w - w) / 3
		var ty: int = deck - pod_h + tier * pod_h / 3
		_tier(img, cx - tw / 2, deck - pod_h * (3 - tier) / 3, tw, pod_h / 3 + 1, body, lit_side, rng, d)
	# The body, up to the Crown if it reaches one.
	var crowned: bool = top < FOG_TOP
	var rim: int = rim_y(i) if crowned else top
	var under: int = rim + wall_height(i) + flare_height(i) if crowned else top
	match shape:
		"twin":
			var sw: int = w * 2 / 5
			_shaft(img, x0, under - 2, sw, deck, body, lit_side, dark_side, rng, d)
			_shaft(img, x0 + w - sw, under - 2, sw, deck, body, lit_side, dark_side, rng, d)
			# A skybridge between the shafts, under the Crown.
			for by: int in [under + 22, under + 60]:
				Px.rect(img, x0 + sw, by, w - 2 * sw, 3, body)
				Px.rect(img, x0 + sw, by + 1, w - 2 * sw, 1, Color(CROWN_LIGHT, 0.5))
		"setback":
			var steps: int = 3
			var seg: int = (deck - under) / steps
			for s: int in range(steps):
				var sw: int = w - s * w / 4
				var sy: int = deck - (s + 1) * seg if s < steps - 1 else under - 2
				_shaft(img, cx - sw / 2, sy, sw, deck - s * seg, body, lit_side, dark_side, rng, d)
		_:
			_shaft(img, x0, under - 2, w, deck, body, lit_side, dark_side, rng, d)
	if crowned:
		_walled_crown(img, i, body, lit_side, dark_side, rng)
	_deck(img, i, body, lit_side, rng)


## One tier of an arcology's podium: a band of habitation with warm windows.
static func _tier(img: Image, x: int, y: int, w: int, h: int, body: Color, lit_side: Color, rng: RandomNumberGenerator, d: float) -> void:
	Px.rect(img, x, y, w, h, body.darkened(0.05))
	Px.rect(img, x, y, w, 1, lit_side)
	var step: int = 2 if d < 0.5 else 3
	for wy: int in range(y + 2, y + h - 1, 2):
		for wx: int in range(x + 1, x + w - 1, step):
			if rng.randf() < 0.16:
				var c: Color = [Color(P.AMBER, 0.55), Color(P.AMBER_DIM, 0.8), Color(P.MAGENTA, 0.35), Color("3a5f6a")][rng.randi_range(0, 3)]
				Px.dot(img, wx, wy, c)


## The close arcology, cropped by the frame: floor bands, ribs, a cold rim on
## its lit edge, and a hologram ad half eaten by the fog.
static func _near_tower(img: Image, i: int, body: Color, lit_side: Color, dark_side: Color, rng: RandomNumberGenerator) -> void:
	var a: Array = ARCOLOGIES[i]
	var cx: int = a[0]
	var w: int = a[2]
	var deck: int = deck_y(i)
	var x0: int = cx - w / 2
	# Podium, flaring out over the deck.
	for tier: int in range(3):
		var tw: int = w + 34 - tier * 12
		var th: int = 14
		var ty: int = deck - 7 - (tier + 1) * th
		_tier(img, cx - tw / 2, ty, tw, th + 1, body, lit_side, rng, 1.0)
	var top_body: int = deck - 7 - 3 * 14
	Px.rect(img, x0, 0, w, top_body, body)
	# Floor bands, each with a strip of windows, some floors dark.
	for fy: int in range(top_body - 10, 0, -10):
		Px.rect(img, x0, fy, w, 1, dark_side)
		var lit_floor: bool = rng.randf() < 0.55
		for wx: int in range(x0 + 3, x0 + w - 3, 3):
			if lit_floor and rng.randf() < 0.45:
				var c: Color = Color(CROWN_LIGHT, 0.45) if fy < FOG_TOP else [Color(P.AMBER, 0.45), Color(P.CYAN, 0.3)][rng.randi_range(0, 1)]
				Px.rect(img, wx, fy + 4, 2, 2, c)
			elif rng.randf() < 0.05:
				Px.rect(img, wx, fy + 4, 2, 2, Color(P.RAIN, 0.2))
	# Ribs.
	for rx: int in range(x0 + 14, x0 + w, 22):
		Px.rect(img, rx, 0, 3, top_body, dark_side.darkened(0.3))
		Px.rect(img, rx + 3, 0, 1, top_body, lit_side)
	# Cold rim light on the left edge, from the Crown lights across the water.
	Px.rect(img, x0, 0, 1, top_body, Color(CROWN_LIGHT, 0.5))
	Px.rect(img, x0 + 1, 0, 1, top_body, Color(P.CYAN_DIM, 0.6))
	Px.rect(img, x0 + 2, 0, 3, top_body, dark_side)
	# A hologram ad on the face, just under the fog line.
	var hx: int = x0 + 12
	var hy: int = 186
	Px.rect(img, hx - 2, hy - 3, 56, 17, Color(P.MAGENTA_DIM, 0.55))
	Px.text_scaled(img, hx + 1, hy, "RECALL", Color(P.MAGENTA, 0.9), 2)
	for sy: int in range(hy - 3, hy + 14, 2):
		Px.rect(img, hx - 2, sy, 56, 1, Color(P.INK, 0.35))
	Px.glow(img, hx + 26, hy + 5, 50, 28, P.MAGENTA, 0.16)


## A far Crown in the fog: just the top of an arcology, cold and clean.
static func _far_crown(img: Image, x: int, top: int, w: int) -> void:
	var c: Color = Color("18233a")
	Px.rect(img, x, top, w, HORIZON - 20 - top, c)
	Px.rect(img, x + w - 2, top, 2, HORIZON - 20 - top, Color("202e48"))
	# A walled terrace too, too far to see more than its wall and a few treetops.
	Px.rect(img, x - 3, top, w + 6, 2, Color("223049"))
	Px.rect(img, x - 3, top, w + 6, 1, Color(CROWN_LIGHT, 0.4))
	for tx: int in range(x - 2, x + w + 3, 2):
		if (tx * 5) % 3 != 0:
			Px.dot(img, tx, top - 1, Color(LEAF_LIT, 0.8))
	_dome(img, x + w * 0.5, float(top), w * 0.5 + 2.0, 6.0, 0.0)
	for wy: int in range(top + 3, FOG_TOP + 4, 3):
		for wx: int in range(x + 1, x + w - 2, 2):
			if (wx * 7 + wy * 13) % 5 == 0:
				Px.dot(img, wx, wy, Color(CROWN_LIGHT, 0.3))
	Px.glow(img, x + w * 0.5, top, w, 6, CROWN_LIGHT, 0.08)


static func _shaft(img: Image, x: int, top: int, w: int, bottom: int, body: Color, lit_side: Color, dark_side: Color, rng: RandomNumberGenerator, d: float) -> void:
	Px.rect(img, x, top, w, bottom - top, body)
	var edge: int = maxi(1, w / 7)
	Px.rect(img, x + w - edge, top, edge, bottom - top, lit_side)
	Px.rect(img, x, top, maxi(1, edge / 2), bottom - top, dark_side)
	# Windows: sparse and dim low down, richer and colder up in the Crown.
	var step_y: int = 3 if d < 0.5 else 4
	for wy: int in range(top + 3, bottom - 2, step_y):
		var up: bool = wy < FOG_TOP
		var chance: float = 0.34 if up else 0.08
		for wx: int in range(x + 2, x + w - edge - 1, 2 if d < 0.5 else 3):
			if rng.randf() < chance:
				var c: Color = Color(CROWN_LIGHT, 0.55) if up else [Color(P.AMBER, 0.4), Color(P.CYAN, 0.3), Color(P.RAIN, 0.25)][rng.randi_range(0, 2)]
				Px.rect(img, wx, wy, 1 if d < 0.5 else 2, 1, c)
	# Cold strip lights down the lit edge, corporate.
	if w > 18:
		for sy: int in range(top + 6, bottom - 4, 9):
			Px.dot(img, x + w - edge - 1, sy, Color(CROWN_LIGHT, 0.4))


## Greens for the Crown's gardens, muted so they sit in the night palette.
const LEAF: Color = Color("1b332f")
const LEAF_LIT: Color = Color("3d6656")
const LEAF_RIM: Color = Color("7fb8a4")


## A Crown: a terrace walled all round, a garden inside it, and the clean,
## lit buildings of the people who live up here rising out of the trees. From
## below you see the wall, the treetops over it and the towers over those.
static func _walled_crown(img: Image, i: int, body: Color, lit_side: Color, dark_side: Color, rng: RandomNumberGenerator) -> void:
	var a: Array = ARCOLOGIES[i]
	var cx: int = a[0]
	var shaft_w: int = top_shaft_width(i)
	var top: int = a[3]
	var d: float = depth_of(i)
	var cw: int = crown_width(i)
	var rim: int = rim_y(i)
	var wh: int = wall_height(i)
	var fh: int = flare_height(i)
	var x0: int = cx - cw / 2
	var stone: Color = Color("26344b").lerp(Color("1a2638"), d)
	# A soft cold glow over the garden.
	Px.glow(img, cx, rim - 4, cw * 0.65, 16, CROWN_LIGHT, 0.1)
	# The buildings inside the walls: one tallest, the rest lower, all lit clean.
	var count: int = maxi(4, cw / 8)
	var hero: int = rng.randi_range(1, count - 2)
	for k: int in range(count):
		var bw: int = maxi(3, int(rng.randi_range(4, 10) * lerpf(0.7, 1.2, d)))
		var bx: int = x0 + 4 + int(float(cw - 8 - bw) * (float(k) + rng.randf_range(0.1, 0.9)) / float(count))
		var bt: int = top if k == hero else rim - rng.randi_range(7, maxi(8, (rim - top) * 4 / 5))
		var tone: Color = Color("1e2b42").lerp(Color("121c2d"), d)
		Px.rect(img, bx, bt, bw, rim - bt + 1, tone)
		Px.rect(img, bx + bw - 1, bt, 1, rim - bt + 1, tone.lightened(0.15))
		Px.rect(img, bx, bt, bw, 1, Color(CROWN_LIGHT, 0.7))
		for wy: int in range(bt + 2, rim - 1, 2):
			for wx: int in range(bx + 1, bx + bw - 1, 2):
				if rng.randf() < 0.45:
					Px.dot(img, wx, wy, Color(CROWN_LIGHT, 0.6))
		if k == hero:
			if a[4] == "spire":
				var pts: PackedVector2Array = [Vector2(bx, bt + 1), Vector2(bx + bw * 0.5, bt - 14), Vector2(bx + bw, bt + 1)]
				Px.poly(img, pts, tone)
				var tip: int = bx + bw / 2
				Px.line(img, Vector2i(tip, bt - 14), Vector2i(tip, bt - 30), lit_side)
				Px.dot(img, tip, bt - 31, Color(P.MAGENTA, 0.9))
				Px.glow(img, tip, bt - 31, 6, 5, P.MAGENTA, 0.25)
			else:
				var mx: int = bx + bw / 2
				Px.line(img, Vector2i(mx, bt - 1), Vector2i(mx, bt - rng.randi_range(6, 12)), Color("2a3a52"))
	# The garden: treetops over the wall, a rim of cold light on their crowns.
	var tx: float = float(x0 + 2)
	while tx < float(x0 + cw - 2):
		var rx: float = rng.randf_range(2.0, 4.0) * lerpf(0.8, 1.3, d)
		var ry: float = rng.randf_range(2.5, 4.5) * lerpf(0.8, 1.3, d)
		var ty: float = float(rim) - ry * 0.5 - rng.randf_range(0.0, 3.0)
		Px.ellipse(img, tx, ty, rx, ry, LEAF)
		Px.rect(img, int(tx - rx * 0.5), int(ty - ry + 0.5), maxi(1, int(rx)), 1, LEAF_LIT)
		if rng.randf() < 0.4:
			Px.dot(img, int(tx), int(ty - ry + 0.5), Color(LEAF_RIM, 0.8))
		tx += rx * rng.randf_range(0.9, 1.6)
	# The wall, all round the terrace, with bastions at the corners.
	Px.rect(img, x0, rim, cw, wh, stone)
	Px.rect(img, x0, rim, cw, 1, Color(CROWN_LIGHT, 0.5))
	Px.rect(img, x0 + cw - 2, rim, 2, wh, stone.lightened(0.12))
	# Buttresses down the wall's face.
	for bx: int in range(x0 + 6, x0 + cw - 4, 12):
		Px.rect(img, bx, rim + 1, 2, wh - 1, stone.darkened(0.25))
	for bx: int in [x0 - 1, x0 + cw - 3]:
		Px.rect(img, bx, rim - 3, 4, wh + 3, stone)
		Px.rect(img, bx, rim - 3, 4, 1, Color(CROWN_LIGHT, 0.6))
	for sx: int in range(x0 + 4, x0 + cw - 4, 5 if d < 0.5 else 4):
		if rng.randf() < 0.6:
			Px.dot(img, sx, rim + wh / 2, Color(CROWN_LIGHT, 0.45))
	# The flared underside, carrying the terrace out over the shaft.
	var bottom_w: float = float(shaft_w) + 2.0
	var pts: PackedVector2Array = [
		Vector2(x0, rim + wh), Vector2(x0 + cw, rim + wh),
		Vector2(cx + bottom_w * 0.5, rim + wh + fh), Vector2(cx - bottom_w * 0.5, rim + wh + fh),
	]
	Px.poly(img, pts, dark_side)
	for k: int in range(1, 4):
		var t: float = float(k) / 4.0
		var from: Vector2i = Vector2i(roundi(lerpf(x0, cx - bottom_w * 0.5, 0.0) + cw * t), rim + wh)
		var to: Vector2i = Vector2i(roundi(cx - bottom_w * 0.5 + bottom_w * t), rim + wh + fh)
		Px.line(img, from, to, body)
	# Struts from the terrace's outer edges back down to the shaft, so the
	# overhang is carried by the core, with cables from the lip to the shaft.
	var thick: int = 2 if d < 0.5 else 3
	var reach: float = float(cw - shaft_w) * 0.5
	for side: int in [-1, 1]:
		var shaft_edge: int = strut_foot_x(i, side)
		for k: int in range(2):
			var sx: int = cx + side * (cw / 2 - 3 - k * int(reach * 0.45))
			var from: Vector2i = Vector2i(sx, rim + wh + 1)
			var to: Vector2i = Vector2i(shaft_edge, rim + wh + fh + roundi(reach * (0.95 - 0.4 * k)))
			for t: int in range(thick):
				Px.line(img, from + Vector2i(0, t), to + Vector2i(0, t), dark_side)
			Px.line(img, from + Vector2i(0, -1), to + Vector2i(0, -1), Color(CROWN_LIGHT, 0.3))
			# A collar where the strut meets the shaft.
			Px.rect(img, to.x - 1 if side > 0 else to.x - 1, to.y - 1, 3, 3, lit_side)
		# Tension cables from the lip down to the shaft, thin and taut.
		var lip: Vector2i = Vector2i(cx + side * (cw / 2 - 1), rim + wh)
		Px.line(img, lip, Vector2i(shaft_edge, rim + wh + fh + roundi(reach * 1.4)), Color(P.RAIN, 0.3))
	# Lights under the terrace's lip.
	for lx: int in range(x0 + 2, x0 + cw - 2, 4):
		Px.dot(img, lx, rim + wh, Color(P.CYAN, 0.55))
	# A landing pad off one side of the wall.
	var pad_w: int = maxi(8, cw / 5)
	var left: bool = rng.randf() < 0.5
	var py: int = rim + 1
	var px: int = x0 - pad_w + 1 if left else x0 + cw - 1
	Px.rect(img, px, py, pad_w, 2, stone)
	for lx: int in range(px, px + pad_w, 3):
		Px.dot(img, lx, py - 1, Color(P.CYAN, 0.8))
	# The dome: glass on a lattice over the whole garden, rain running off it.
	# A wide terrace gets a second, smaller dome beside the first.
	var ry: float = float(rim - top) + 5.0
	_dome(img, float(cx), float(rim), cw * 0.5 - 1.0, ry, d)
	if cw > 80:
		_dome(img, float(x0 + cw / 4), float(rim), cw * 0.24, ry * 0.55, d)


## Glass for the domes: a cold sea-green, so the glass reads apart from the night.
const GLASS: Color = Color("3f7f7c")
const GLASS_LIT: Color = Color("9fd8cf")


## A glass-lattice dome: a flattened half-ellipse standing on row `base`, the
## glass a dither so what's under it shows through, the lattice in lit lines,
## and a bright crescent where the city's light catches the top.
static func _dome(img: Image, cx: float, base: float, rx: float, ry: float, d: float) -> void:
	var cell: float = lerpf(5.0, 8.0, d)
	for y: int in range(floori(base - ry), int(base)):
		for x: int in range(floori(cx - rx), ceili(cx + rx)):
			var u: float = (x + 0.5 - cx) / rx
			var v: float = (base - (y + 0.5)) / ry
			var r: float = u * u + v * v
			if r > 1.0:
				continue
			# The lattice runs along the dome's curve: meridians and rings.
			var lon: float = asin(clampf(u / sqrt(maxf(1.0 - v * v, 0.0001)), -1.0, 1.0)) * rx / cell
			var lat: float = v * ry / (cell * 0.7)
			var on_line: bool = absf(lon - roundf(lon)) < 0.12 or absf(lat - roundf(lat)) < 0.14
			if r > 0.9:
				Px.dot(img, x, y, Color(GLASS_LIT, 0.55))  # the rim of the glass
			elif on_line:
				Px.dot(img, x, y, Color(GLASS_LIT, 0.28))
			elif Px.dither(x, y, 0.35):
				Px.dot(img, x, y, Color(GLASS, 0.45))
			# The crescent of light on the upper left.
			if u < -0.1 and v > 0.45 and r > 0.7 and r <= 0.9:
				Px.dot(img, x, y, Color(CROWN_LIGHT, 0.45))


## A dead arcology going down far out on the water: its hull tilted, the
## dome over it broken open, its legs already gone under.
static func _sunk_arcology(img: Image, i: int) -> void:
	var a: Array = ARCOLOGIES[i]
	var cx: float = float(a[0])
	var base: float = float(a[1])
	var rx: float = float(a[2]) * 0.78
	var ry: float = rx * 0.62
	var tilt: float = 0.13   # radians, right side down
	var hull: Color = Color("152136")
	var ring: Color = Color("0f1828")
	var cs: float = cos(tilt)
	var sn: float = sin(tilt)
	for y: int in range(floori(base - rx), int(base)):
		for x: int in range(floori(cx - rx - 4), ceili(cx + rx + 4)):
			var px: float = x + 0.5 - cx
			var py: float = y + 0.5 - (base + 6.0)
			var u: float = (px * cs + py * sn) / rx
			var v: float = -(-px * sn + py * cs) / ry
			if v < -0.35 or u * u + v * v > 1.0:
				continue
			var c: Color = hull
			if v < 0.12:
				c = ring  # the hull's structural ring, under the dome
				if v > 0.02 and v < 0.07 and int(x) % 3 == 0:
					c = Color("0b111c")  # dead windows
			else:
				var lon: float = u * 13.0
				var lat: float = v * 8.0
				if absf(lon - roundf(lon)) < 0.1 or absf(lat - roundf(lat)) < 0.12:
					c = Color("2f4a55")
				# Panes gone: the dark inside showing through.
				var hole: int = (int(floorf(lon + 13.0)) * 31 + int(floorf(lat)) * 17) % 7
				if hole == 0 or (u > 0.3 and hole < 3):
					c = Color("0a1019")
			Px.dot(img, x, y, c)
	# Water breaking against it.
	var rng: RandomNumberGenerator = _rng(61)
	for k: int in range(26):
		var fx: int = int(cx - rx) + rng.randi_range(0, int(rx * 2.0))
		Px.rect(img, fx, int(base) - 1 - rng.randi_range(0, 2), rng.randi_range(1, 4), 1, Color(P.RAIN, 0.45))


## The legs: an arcade of arches under the deck, the end legs curving out
## like buttresses as they go down into the water.
static func _stilts(img: Image, i: int, body: Color, dark_side: Color) -> void:
	var a: Array = ARCOLOGIES[i]
	var cx: int = a[0]
	var foot: int = a[1]
	var d: float = depth_of(i)
	var dw: int = deck_width(i)
	var deck: int = deck_y(i)
	var legs: int = maxi(3, dw / 16)
	var leg_w: int = maxi(2, int(lerpf(2.0, 12.0, d)))
	var x0: int = cx - dw / 2 + 2
	var span: float = float(dw - 4 - leg_w) / float(legs - 1)
	var h: int = foot - deck
	var flare: int = maxi(1, leg_w)
	var lit: Color = body.lightened(0.08)
	var xs: Array[int] = []
	for l: int in range(legs):
		xs.append(x0 + roundi(span * l))
	# The spandrels: solid between the deck and each arch's curve.
	var spring: float = float(deck) + float(h) * 0.7
	for l: int in range(legs - 1):
		var left: int = xs[l] + leg_w
		var right: int = xs[l + 1]
		var half: float = float(right - left) * 0.5
		var mid: float = float(left) + half
		for x: int in range(left, right):
			var u: float = (x + 0.5 - mid) / half
			var y_arch: float = spring - (spring - float(deck) - 2.0) * sqrt(maxf(0.0, 1.0 - u * u))
			Px.rect(img, x, deck, 1, int(y_arch) - deck, dark_side)
			Px.dot(img, x, int(y_arch), lit)  # the arch's lit edge
	# The legs, flaring at the foot; the end legs lean outward as they go down.
	for l: int in range(legs):
		for y: int in range(deck, foot + 2):
			var t: float = float(y - deck) / float(maxi(h, 1))
			var lean: int = 0
			if l == 0:
				lean = -roundi(float(flare) * t * t * 1.5)
			elif l == legs - 1:
				lean = roundi(float(flare) * t * t * 1.5)
			var widen: int = roundi(float(flare) * maxf(0.0, t - 0.75) * 2.0)
			var lx: int = xs[l] + lean - widen / 2
			Px.rect(img, lx, y, leg_w + widen, 1, dark_side)
			Px.dot(img, lx + leg_w + widen - 1, y, lit)
		_tidemarks(img, xs[l] + (-roundi(flare * 1.5) if l == 0 else (roundi(flare * 1.5) if l == legs - 1 else 0)) - flare / 2, leg_w + flare, foot, d)


## How tall the hull is above the water: the lower part of the legs stands in it.
static func hull_height(i: int) -> int:
	return roundi(float(stilt_height(i)) * 0.62)


## How wide the hull is: a little wider than the deck it carries.
static func hull_width(i: int) -> int:
	return deck_width(i) + maxi(2, int(lerpf(2.0, 14.0, depth_of(i))))


## The hull: where its legs meet the sea, each arcology stands in a caisson of
## watertight decks, sealed from each other by bulkheads and floodgates and kept
## dry by the Sump's pumps. The poor live in its old lower decks: a row or two
## of small warm windows just above the water (the Freeboard's kind of
## tenement), the bottom deck dark and half under, written off at the last rise,
## its gate open to the sea. Tidemarks run across the whole face; a sluice gate
## and an outfall pipe sit at the waterline, and the decks already under show
## as dim shapes in the water.
static func _hull(img: Image, i: int, body: Color, rng: RandomNumberGenerator) -> void:
	var a: Array = ARCOLOGIES[i]
	var cx: int = a[0]
	var foot: int = a[1]
	var d: float = depth_of(i)
	var hw: int = hull_width(i)
	var hh: int = hull_height(i)
	var x0: int = cx - hw / 2
	var top: int = foot - hh
	var unit: float = lerpf(0.4, 2.0, d)
	var plate: Color = body.darkened(0.15)
	var seam: Color = body.darkened(0.4)
	var lit: Color = body.lightened(0.1)
	# The face: plates of the caisson, its top edge catching a little light.
	Px.rect(img, x0, top, hw, hh + 2, plate)
	Px.rect(img, x0, top, hw, 1, lit)
	Px.dot(img, x0, top, seam)
	Px.dot(img, x0 + hw - 1, top, seam)
	# Bulkhead seams: the decks run across, the frames go down.
	var deck_h: int = maxi(2, roundi(5.0 * unit))
	var decks: int = maxi(1, hh / deck_h)
	for k: int in range(1, decks + 1):
		var y: int = top + k * deck_h
		if y < foot:
			Px.rect(img, x0, y, hw, 1, seam)
	var frame: int = maxi(4, roundi(14.0 * unit))
	for x: int in range(x0 + frame, x0 + hw - 1, frame):
		Px.rect(img, x, top + 1, 1, hh, Color(seam, 0.6))
	# The lived-in decks: the upper ones lit warm through small windows. The
	# lowest one, right at the water, is the deck written off at the last rise.
	var win: int = maxi(1, roundi(unit))
	for k: int in range(decks):
		var wy: int = top + k * deck_h + maxi(1, deck_h / 2 - win / 2)
		if wy + win > foot - 1:
			continue
		var bottom_deck: bool = wy + deck_h >= foot - 1
		var step: int = maxi(2, roundi(4.0 * unit))
		for wx: int in range(x0 + 2, x0 + hw - 2 - win, step):
			if bottom_deck:
				# Dark windows, the stain of the water that stood in them.
				Px.rect(img, wx, wy, win, win, Color("04070d"))
			elif rng.randf() < 0.7:
				var c: Color = [P.AMBER, P.AMBER, P.AMBER_DIM, Color("6fb3c0"), P.MAGENTA_DIM][rng.randi_range(0, 4)]
				Px.rect(img, wx, wy, win, win, Color(c, lerpf(0.7, 1.0, d)))
			else:
				Px.rect(img, wx, wy, win, win, seam)
	# A warm haze off the lived-in decks, low over the water.
	Px.glow(img, cx, top + hh * 0.4, hw * 0.5, 4.0 + 8.0 * d, P.AMBER, 0.08 + 0.07 * d)
	# The tidemarks of each rise, pale lines across the whole hull, the oldest
	# lowest. Below the lowest the plates are wet black.
	var scale: float = lerpf(0.5, 3.0, d)
	Px.rect(img, x0, foot - roundi(1.0 * scale), hw, roundi(1.0 * scale) + 2, Color("05080f"))
	var marks: Array[float] = [3.0, 6.5, 10.5]
	for m: int in range(marks.size()):
		var y: int = foot - roundi(marks[m] * scale)
		if y <= top:
			continue
		var c: Color = Color(P.RAIN, lerpf(0.5, 0.25, float(m) / 2.0) * lerpf(0.6, 1.0, d))
		Px.rect(img, x0, y, hw, 1, c)
		if scale >= 2.0:
			Px.screen(img, x0, y + 1, hw, 2, Color(P.RAIN, 0.15), 0.5)
	if d < 0.3:
		return
	# A sluice gate at the waterline: a barred gate in a heavier frame.
	var gw: int = maxi(4, roundi(9.0 * unit))
	var gh: int = maxi(3, roundi(7.0 * unit))
	var gx: int = x0 + hw / 4 - gw / 2
	var gy: int = foot - gh + roundi(unit)
	Px.rect(img, gx - 1, gy - 1, gw + 2, gh + 1, seam)
	Px.rect(img, gx, gy, gw, gh, Color("04070d"))
	for bx: int in range(gx + 1, gx + gw, maxi(2, roundi(2.0 * unit))):
		Px.rect(img, bx, gy, 1, gh, Color(P.RUST, 0.9))
	Px.rect(img, gx - 1, gy - 1, gw + 2, 1, lit)
	# An outfall pipe: the pumps throwing the sea back out, a pale spill under it.
	var px: int = x0 + hw * 3 / 4
	var pr: int = maxi(1, roundi(2.0 * unit))
	var py: int = foot - roundi(6.0 * scale)
	if py > top + pr:
		Px.rect(img, px - pr, py - pr, pr * 2 + 1, pr * 2 + 1, seam)
		Px.rect(img, px - pr + 1, py - pr + 1, maxi(1, pr * 2 - 1), maxi(1, pr * 2 - 1), Color("04070d"))
		for y: int in range(py + pr, foot + 1):
			if (y + px) % 2 == 0:
				Px.dot(img, px, y, Color(P.RAIN, 0.45))
	# The decks already under: dim window rows below the surface.
	for k: int in range(1, 3):
		var uy: int = foot + k * deck_h - 1
		for wx: int in range(x0 + 3, x0 + hw - 3, maxi(3, roundi(5.0 * unit))):
			Px.dot(img, wx, uy, Color(P.STEEL, 0.35 / float(k)))


## The tidemarks: pale lines left on a stilt by each rise of the water, oldest
## lowest and furthest gone. Below the lowest the stilt is wet black.
static func _tidemarks(img: Image, x: int, w: int, foot: int, d: float) -> void:
	var scale: float = lerpf(0.5, 3.0, d)
	Px.rect(img, x, foot - roundi(2.0 * scale), w, roundi(2.0 * scale) + 2, Color("05080f"))
	var marks: Array[float] = [3.0, 6.5, 10.5]
	for m: int in range(marks.size()):
		var y: int = foot - roundi(marks[m] * scale)
		var c: Color = Color(P.RAIN, lerpf(0.55, 0.3, float(m) / 2.0) * lerpf(0.6, 1.0, d))
		if scale >= 2.0:
			Px.rect(img, x, y, w, 1, c)
			Px.screen(img, x, y + 1, w, 2, Color(P.RAIN, 0.2), 0.5)
		else:
			Px.rect(img, x, y, w, 1, Color(c, c.a * 0.7))


## The Waterline deck: a platform wider than the tower, crowded with shacks and
## neon, the only part of the arcology the people below can reach.
static func _deck(img: Image, i: int, body: Color, lit_side: Color, rng: RandomNumberGenerator) -> void:
	var a: Array = ARCOLOGIES[i]
	var cx: int = a[0]
	var d: float = depth_of(i)
	var dw: int = deck_width(i)
	var deck: int = deck_y(i)
	var thick: int = maxi(2, int(lerpf(2.0, 7.0, d)))
	var x0: int = cx - dw / 2
	Px.rect(img, x0, deck - thick, dw, thick, body.darkened(0.1))
	Px.rect(img, x0, deck - thick, dw, 1, lit_side)
	# Shacks on the deck.
	var sx: int = x0 + 1
	var unit: float = lerpf(0.35, 1.6, d)
	while sx < x0 + dw - 3:
		var sw: int = maxi(3, int(rng.randi_range(5, 12) * unit))
		var sh: int = maxi(2, int(rng.randi_range(3, 8) * unit))
		sw = mini(sw, x0 + dw - 1 - sx)
		Px.rect(img, sx, deck - thick - sh, sw, sh, Color("101827").lerp(Color("1a263a"), 1.0 - d))
		if rng.randf() < 0.6:
			var c: Color = [P.AMBER_DIM, Color("3a5f6a"), P.MAGENTA_DIM, P.AMBER][rng.randi_range(0, 3)]
			var ww: int = maxi(1, int(2.0 * unit))
			Px.rect(img, sx + rng.randi_range(0, maxi(0, sw - ww)), deck - thick - sh + maxi(1, sh / 3), ww, maxi(1, int(unit)), c)
		sx += sw + rng.randi_range(0, 3)
	# String lights along the deck edge.
	for lx: int in range(x0 + 2, x0 + dw - 2, maxi(2, int(5 * unit))):
		var c: Color = P.AMBER if rng.randf() < 0.7 else P.MAGENTA
		Px.dot(img, lx, deck - thick + 1 + (1 if lx % 3 == 0 else 0), Color(c, 0.8))
	# The deck's spill of light down into the water and up into the fog.
	var warm: Color = P.AMBER if i % 2 == 0 else P.MAGENTA
	Px.glow(img, cx, deck - thick, dw * 0.6, 18 + 20 * d, warm, 0.1 + 0.08 * d)
	for s: Array in DECK_SIGNS:
		if s[0] == i:
			_deck_sign(img, cx + int(s[1]), deck - thick, s[2], sign_color(s[3]), d)
	if d < 0.3:
		# Far decks: just a few points of neon.
		for k: int in range(3):
			var c: Color = [P.MAGENTA, P.CYAN, P.AMBER][rng.randi_range(0, 2)]
			Px.rect(img, x0 + rng.randi_range(2, dw - 4), deck - thick - rng.randi_range(3, 6), 1, 2, c)


static func _deck_sign(img: Image, x: int, base: int, word: String, c: Color, d: float) -> void:
	var tall: int = word.length() * 6 - 1
	var top: int = base - tall - int(lerpf(6.0, 22.0, d))
	var w: int = 3
	if d >= 0.8:
		# Close enough to read: a vertical sign in the 3x5 font, on a dark plate.
		Px.rect(img, x - 2, top - 2, w + 4, tall + 4, Color("070a10"))
		for k: int in range(word.length()):
			Px.text(img, x, top + k * 6, word[k], c)
		Px.rect(img, x, top + tall + 2, 1, base - top - tall - 2, Color("1a2436"))
		Px.glow(img, x + 1.5, top + tall * 0.5, 14, tall * 0.5 + 10, c, 0.2)
	else:
		# Too far to read: the letters have gone and only the shape of the tube is left.
		var h: int = tall / 3
		Px.rect(img, x, top + tall - h, 1, h, c)
		Px.rect(img, x + 1, top + tall - h, 1, h, Color(c, 0.5))
		Px.glow(img, x + 1, top + tall - h * 0.5, 9, h * 0.5 + 6, c, 0.2)


## A causeway between two decks: a walkway on piers, lamps along it.
static func _causeway(img: Image, from: int, to: int) -> void:
	var a: int = from
	var b: int = to
	if int(ARCOLOGIES[a][0]) > int(ARCOLOGIES[b][0]):
		a = to
		b = from
	var ya: int = deck_y(a) - 1
	var yb: int = deck_y(b) - 1
	var xa: int = int(ARCOLOGIES[a][0]) + deck_width(a) / 2 - 1
	var xb: int = int(ARCOLOGIES[b][0]) - deck_width(b) / 2 + 1
	if xb <= xa:
		return
	var d: float = maxf(depth_of(a), depth_of(b))
	var c: Color = Color("17233a").lerp(Color("0c1422"), d)
	var pts: PackedVector2Array = Px.cable(img, Vector2i(xa, ya), Vector2i(xb, yb), 3.0, c)
	var thick: int = 1 if d < 0.5 else 2
	for p: Vector2 in pts:
		Px.rect(img, int(p.x), int(p.y), 1, thick, c)
	# Piers down to the water, and lamps.
	var foot_a: int = int(ARCOLOGIES[a][1])
	var foot_b: int = int(ARCOLOGIES[b][1])
	var gap: int = 14 if d < 0.5 else 22
	for k: int in range(gap / 2, pts.size(), gap):
		var p: Vector2 = pts[k]
		var t: float = float(k) / float(pts.size() - 1)
		var foot: int = roundi(lerpf(foot_a, foot_b, t))
		Px.rect(img, int(p.x), int(p.y) + thick, 1 + thick / 2, foot - int(p.y) - thick, c)
		Px.rect(img, int(p.x), foot - 1, 1 + thick / 2, 1, Color(P.RAIN, 0.3))
	for k: int in range(3, pts.size(), 7):
		var p: Vector2 = pts[k]
		Px.dot(img, int(p.x), int(p.y) - 1, Color(P.AMBER, 0.75))


## Cars between the Crown's pads: a light and a short trail, and a tail light
## crossing low over the fog.
static func _traffic(img: Image) -> void:
	var cars: Array[Array] = [[250, 62, 14, CROWN_LIGHT], [410, 96, -18, P.CYAN], [138, 110, 22, P.MAGENTA], [505, 46, -10, CROWN_LIGHT]]
	for car: Array in cars:
		var x: int = car[0]
		var y: int = car[1]
		var trail: int = car[2]
		var c: Color = car[3]
		var dir: int = signi(trail)
		for k: int in range(absi(trail)):
			Px.dot(img, x - dir * k, y + (k / 6), Color(c, 0.5 * (1.0 - float(k) / absf(trail))))
		Px.rect(img, x, y, 2, 1, c)
		Px.glow(img, x + 1, y, 5, 4, c, 0.2)


## Mooring posts in the near water, marked like the stilts.
static func _moorings(img: Image) -> void:
	for p: Array in [[28, 316, 5], [44, 322, 4], [226, 338, 6]]:
		var x: int = p[0]
		var top: int = p[1]
		var w: int = p[2]
		Px.rect(img, x, top, w, VIEW.y - top, Color("0b121e"))
		Px.rect(img, x + w - 1, top, 1, VIEW.y - top, Color("1a2638"))
		for m: int in range(3):
			Px.rect(img, x, top + 8 + m * 6, w, 1, Color(P.RAIN, 0.45 - 0.1 * m))
	# A lamp on the first post.
	Px.rect(img, 29, 310, 3, 2, P.AMBER)
	Px.glow(img, 30, 311, 20, 16, P.AMBER, 0.22)


## Fog over everything drawn so far at one depth. `amount` 1 is the far fog,
## lower is thinner fog nearer the eye. The fog line has a rolling top; above
## it the air is clear (the Crown). Below it the Waterline shows through thin
## haze, and a low mist lies on the water.
static func fog(amount: float) -> Image:
	var img: Image = Px.blank(VIEW.x, VIEW.y)
	var lights: Array[Array] = []
	for s: Array in DECK_SIGNS:
		var i: int = s[0]
		lights.append([float(int(ARCOLOGIES[i][0]) + int(s[1])), float(deck_y(i) - 20), 30.0 + 20.0 * depth_of(i), sign_color(s[3])])
	for x: int in range(VIEW.x):
		var roll: int = _roll(x)
		for y: int in range(VIEW.y):
			var a: float = _fog_alpha(x, y, roll) * amount * _drift(x, y)
			if a <= 0.0:
				continue
			var c: Color = FOG_TINT
			# The top of the fog catches the Crown's light.
			if y <= FOG_TOP + roll + 1 and y >= FOG_TOP + roll - 1:
				c = FOG_TINT.lerp(CROWN_LIGHT, 0.25)
			for g: Array in lights:
				var ring: int = _ring(x, y, g)
				if ring > 0:
					c = c.lerp(g[3], 0.18 * ring)
					a = minf(a + 0.05 * ring, 0.9)
					break
			Px.dot(img, x, y, Color(c, a))
	return img


## Slow banks in the fog: some stretches thicker, some thinner, in flat
## steps with a dithered seam, so the fog sea isn't one even wall.
static func _drift(x: int, y: int) -> float:
	var v: float = sin(x * 0.011 + y * 0.03) * 0.5 + sin(x * 0.031 - y * 0.05 + 2.0) * 0.5
	var t: float = (v + 1.0) * 2.0
	var level: float = floorf(t)
	if Px.dither(x, y, t - level):
		level += 1.0
	return 0.75 + 0.1 * level


## The rolling top of the fog: a few long swells, stepped to two-pixel rows.
static func _roll(x: int) -> int:
	var v: float = sin(x * 0.021) * 5.0 + sin(x * 0.057 + 1.3) * 3.0 + sin(x * 0.13 + 0.4) * 1.5
	return int(floorf(v / 2.0)) * 2


static func _fog_alpha(x: int, y: int, roll: int) -> float:
	var top: int = FOG_TOP + roll
	var a: float = 0.0
	if y >= top - 2 and y < top:
		a = 0.35 if Px.dither(x, y, 0.5) else 0.0
	elif y >= top:
		# The fog sea: stepped thicker into its heart, thinning out below.
		# Stepped from the top of the fog down to the Waterline: thick in its
		# heart, thinning in flat bands with dithered seams below it.
		var steps: Array[float] = [0.45, 0.6, 0.72, 0.78, 0.66, 0.5, 0.36, 0.24, 0.16, 0.12]
		var t: float = clampf(float(y - top) / float(HORIZON - 14 - top), 0.0, 0.999) * steps.size()
		var s: int = int(t)
		a = steps[s]
		if s + 1 < steps.size() and t - s > 0.7 and Px.dither(x, y, (t - s - 0.7) / 0.3):
			a = steps[s + 1]
	# Low mist on the water near the horizon.
	if y >= HORIZON - 10 and y < HORIZON + 8:
		a = maxf(a, 0.3 if Px.dither(x, y, 0.75) else 0.2)
	if y >= HORIZON + 8:
		a = maxf(a, 0.12 if Px.dither(x, y, 0.4) else 0.0)
	return a * 0.75


static func _ring(x: int, y: int, g: Array) -> int:
	var d: float = Vector2(x + 0.5 - g[0], (y + 0.5 - g[1]) * 1.3).length() / float(g[2])
	if d >= 1.0:
		return 0
	var level: float = (1.0 - d) * 3.0
	var ring: int = int(floorf(level))
	if Px.dither(x, y, level - ring):
		ring += 1
	return mini(ring, 3)


## Mirrors a layer in the water below `axis`, darkened, broken into ripples and
## fading with distance.
static func _reflect(dst: Image, layer: Image, axis: int) -> void:
	for y: int in range(axis, VIEW.y):
		var dy: int = y - axis
		var sy: int = axis - 1 - dy
		if sy < 0:
			break
		var fade: float = 1.0 - float(dy) / 90.0
		if fade <= 0.0:
			break
		var shift: int = [0, 1, 0, -1, 0, 2, -1, 0][(y / 2) % 8] if dy > 2 else 0
		for x: int in range(VIEW.x):
			var c: Color = layer.get_pixel(clampi(x + shift, 0, VIEW.x - 1), sy)
			if c.a <= 0.0:
				continue
			if not Px.dither(x, y, fade * 0.9):
				continue
			var bright: float = c.get_luminance()
			Px.dot(dst, x, y, Color(c.darkened(0.55 - bright * 0.3), c.a * 0.7))


## Glints on the water: short flat streaks where the neon catches ripples.
static func _glints(img: Image) -> void:
	var rng: RandomNumberGenerator = _rng(53)
	for k: int in range(120):
		var x: int = rng.randi_range(0, VIEW.x - 1)
		var y: int = rng.randi_range(HORIZON + 2, VIEW.y - 1)
		var c: Color = img.get_pixel(x, y)
		if c.get_luminance() < 0.09:
			continue
		Px.rect(img, x, y, rng.randi_range(2, 6), 1, Color(c.lightened(0.35), 0.5))


## A still of the rain over the view, like ArtRain's two depths of streaks.
static func rain_still(img: Image) -> void:
	var rng: RandomNumberGenerator = _rng(7)
	var count: int = int(VIEW.x * VIEW.y / 900.0)
	for k: int in range(count):
		var depth: float = rng.randf()
		var x: int = rng.randi_range(-20, VIEW.x + 20)
		var y: int = rng.randi_range(0, VIEW.y)
		var length: int = int(lerpf(3.0, 9.0, depth))
		var c: Color = Color(P.RAIN, lerpf(0.1, 0.36, depth))
		for s: int in range(length):
			Px.dot(img, x + s / 4, y - s, c)


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	return rng
