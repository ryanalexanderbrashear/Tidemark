class_name FogArt
extends RefCounted
## Fog, water and neon for the style test (Look and Feel doc, "Fog, water and
## neon"): big neon signs on towers behind the market, and the fog between the
## back layers that swallows them.
##
## Stepped fog is drawn into Images at native resolution like the rest of the
## art test: flat bands of one tint, dithered only where one band meets the
## next, so it stays crisp after whole-number scaling. Each light inside a band
## tints the fog around it in stepped rings, so a sign reads three times: its
## shape, its glow in the fog, and its reflection in the water below.

const P = preload("res://game/art/art_palette.gd")

## Fog's own color, between storm blue and wet concrete.
const FOG_TINT: Color = Color("33435a")

## Each fog band: the layer it sits in front of (and moves with), its top and
## bottom rows, and its thinnest and thickest alpha. Fog thickens toward the
## water it rises off.
const BANDS: Dictionary[String, Array] = {
	"fog_far": ["city", 60, 300, 0.18, 0.55],
	"fog_signs": ["signs", 50, 300, 0.30, 0.62],
	"fog_mid": ["arcology", 100, 300, 0.10, 0.42],
	"fog_low": ["shanties", 190, 300, 0.04, 0.40],
}

## Signs on the towers behind the market: x in the signs layer, top row, the
## word, its color, and whether it hangs vertically. Placeholder words, not canon.
const SIGNS: Array[Array] = [
	[60, 70, "HOTEL", "cyan", true],
	[210, 92, "PAWN", "magenta", false],
	[372, 64, "DIVE", "amber", true],
	[520, 84, "KARAOKE", "magenta", false],
	[700, 72, "NOODLE", "cyan", true],
	[790, 100, "OPEN", "amber", false],
]

## Fog moves: each band's drifting wisps cross at this many native px a second.
const DRIFT: Dictionary[String, float] = {"fog_far": 1.5, "fog_signs": 2.5, "fog_mid": 4.0, "fog_low": 6.0}
const WISP_TILE: int = 320


static func sign_color(name: String) -> Color:
	match name:
		"magenta":
			return P.MAGENTA
		"amber":
			return P.AMBER
	return P.CYAN


## Where a sign's light sits, its centre in the signs layer, and how far its glow spreads.
static func sign_light(s: Array) -> Vector3:
	var word: String = s[2]
	var vertical: bool = s[4]
	var scale: int = 2
	var w: int = 3 * scale if vertical else Px.text_width(word) * scale
	var h: int = (word.length() * 6 - 1) * scale if vertical else 5 * scale
	return Vector3(float(s[0]) + w * 0.5, float(s[1]) + h * 0.5, maxf(w, h) * 0.5 + 34.0)


## The towers behind the market and the neon on them, drawn sharp; the fog
## in front (fog_signs) takes their letters first, then their shape.
static func signs() -> Image:
	var w: int = MarketArt.layer_width("signs")
	var img: Image = Px.blank(w, MarketArt.VIEW.y)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 31
	# A dark slab behind each sign, so the neon hangs on something.
	for s: Array in SIGNS:
		var l: Vector3 = sign_light(s)
		var tw: int = rng.randi_range(46, 70)
		var tx: int = int(l.x) - tw / 2 + rng.randi_range(-8, 8)
		var top: int = int(s[1]) - rng.randi_range(14, 26)
		Px.rect(img, tx, top, tw, MarketArt.VIEW.y - top, Color("0c1422"))
		Px.rect(img, tx + tw - 4, top, 4, MarketArt.VIEW.y - top, Color("121c2c"))
		for i: int in range(rng.randi_range(3, 9)):
			var wx: int = tx + 3 + rng.randi_range(0, tw - 6)
			var wy: int = top + 30 + rng.randi_range(0, 140)
			Px.rect(img, wx, wy, 2, 1, Color(P.AMBER, 0.35))
	for s: Array in SIGNS:
		_neon(img, s)
	return img


static func _neon(img: Image, s: Array) -> void:
	var word: String = s[2]
	var c: Color = sign_color(s[3])
	var x: int = s[0]
	var y: int = s[1]
	var vertical: bool = s[4]
	var l: Vector3 = sign_light(s)
	var bw: int = int((l.x - x) * 2.0)
	var bh: int = int((l.y - y) * 2.0)
	Px.rect(img, x - 4, y - 4, bw + 8, bh + 8, Color("070a10"))
	if vertical:
		for i: int in range(word.length()):
			Px.text_scaled(img, x, y + i * 12, word[i], c, 2)
	else:
		Px.text_scaled(img, x, y, word, c, 2)
	# Tube highlight: the brightest rows of the letters.
	var lit: Color = c.lerp(Color.WHITE, 0.55)
	for yy: int in range(y, y + bh):
		for xx: int in range(x, x + bw):
			if img.get_pixel(xx, yy).is_equal_approx(c) and (xx + yy) % 2 == 0:
				img.set_pixel(xx, yy, lit)


## The lights inside a fog band, in that band's own coordinates: x, y, radius, color.
static func lights(band: String) -> Array[Array]:
	var found: Array[Array] = []
	match band:
		"fog_signs":
			for s: Array in SIGNS:
				var l: Vector3 = sign_light(s)
				found.append([l.x, l.y, l.z, sign_color(s[3])])
		"fog_mid":
			# The arcology's strip lights (MarketArt.arcology), cold and corporate.
			for lx: int in range(12, MarketArt.layer_width("arcology"), 56):
				found.append([lx + 9.0, 54.0, 22.0, Color("9fdfff")])
	return found


## One stepped fog band, the width of the layer it sits in front of.
static func band(name: String) -> Image:
	var spec: Array = BANDS[name]
	var w: int = MarketArt.layer_width(spec[0])
	var img: Image = Px.blank(w, MarketArt.VIEW.y)
	var top: int = spec[1]
	var bottom: int = spec[2]
	var thin: float = spec[3]
	var thick: float = spec[4]
	var glows: Array[Array] = lights(name)
	for y: int in range(MarketArt.VIEW.y):
		var a: float = _band_alpha(y, top, bottom, thin, thick)
		for x: int in range(w):
			var c: Color = FOG_TINT
			var alpha: float = a
			for g: Array in glows:
				var ring: int = _ring(x, y, g)
				if ring > 0:
					# Lit fog: each ring nearer the light is brighter and takes more
					# of its color. Three rings, stepped, never a smooth falloff.
					var lc: Color = g[3]
					c = FOG_TINT.lerp(lc, 0.24 * ring)
					alpha = maxf(alpha, 0.12) + 0.08 * ring
					break
			if alpha > 0.0:
				Px.dot(img, x, y, Color(c, alpha))
	return img


## Fog alpha at row `y`: four flat steps from thin to thick, with a dithered
## seam two rows tall where one step meets the next.
static func _band_alpha(y: int, top: int, bottom: int, thin: float, thick: float) -> float:
	if y < top - 4:
		return 0.0
	var t: float = clampf(float(y - top) / float(bottom - top), 0.0, 1.0)
	var steps: float = 4.0
	var level: float = floorf(t * steps)
	var frac: float = t * steps - level
	if frac > 0.85 and Px.dither(0, y, (frac - 0.85) / 0.15):
		level += 1.0
	if y < top:
		return thin * 0.5 if Px.dither(y, y, 0.5) else 0.0
	return lerpf(thin, thick, minf(level, steps) / steps)


## Which of three halo rings (3 nearest) a pixel falls in, 0 if outside.
static func _ring(x: int, y: int, g: Array) -> int:
	var d: float = Vector2(x + 0.5 - g[0], (y + 0.5 - g[1]) * 1.3).length() / float(g[2])
	if d >= 1.0:
		return 0
	var level: float = (1.0 - d) * 3.0
	var ring: int = int(floorf(level))
	if Px.dither(x, y, level - ring):
		ring += 1
	return mini(ring, 3)


## Drifting wisps for a band: long flat smears of fog, tileable sideways so the
## band can scroll forever. Each is one tint with dithered ends.
static func wisps(name: String) -> Image:
	var spec: Array = BANDS[name]
	var img: Image = Px.blank(WISP_TILE, MarketArt.VIEW.y)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = name.hash()
	var top: int = spec[1]
	var bottom: int = spec[2]
	for i: int in range(10):
		var cx: float = rng.randf_range(0.0, float(WISP_TILE))
		var cy: float = rng.randf_range(float(top) + 20.0, float(bottom))
		var rx: float = rng.randf_range(40.0, 110.0)
		var ry: float = rng.randf_range(3.0, 8.0)
		var alpha: float = rng.randf_range(0.10, 0.20)
		for yy: int in range(floori(cy - ry), ceili(cy + ry) + 1):
			for xx: int in range(floori(cx - rx), ceili(cx + rx) + 1):
				var dx: float = (xx + 0.5 - cx) / rx
				var dy: float = (yy + 0.5 - cy) / ry
				var d: float = dx * dx + dy * dy
				if d >= 1.0:
					continue
				if d > 0.6 and not Px.dither(xx, yy, (1.0 - d) / 0.4):
					continue
				Px.dot(img, posmod(xx, WISP_TILE), yy, Color(P.FOG, alpha))
	return img
