class_name TabletArt
extends RefCounted
## The evidence tablet's art, drawn in code at 640x360 until hand-drawn art
## replaces it: the bezel round the screen, the CRT glass laid over it
## (scanlines, dithered corners, a faint glare band), the boot
## screen, and the dithered photos the tablet's camera takes of each clue.
##
## The screen is one cyan phosphor at four tones; amber marks his notes and
## testimony, magenta marks what's picked. Blood red stays off it.

const P = preload("res://game/art/art_palette.gd")
## The screen inside the bezel, in native pixels.
const SCREEN: Rect2i = Rect2i(40, 26, 560, 308)
## Phosphor tones, darkest first: the screen's ground, rules, dim text, text,
## and the brightest highlight.
const PH: Array[Color] = [Color("04090c"), Color("0b2a33"), Color("167a8a"), Color("2ee6ff"), Color("c9fbff")]
## The four tones a captured photo is dithered to.
const PHOTO: Array[Color] = [Color("050b0e"), Color("0f3a46"), Color("1f8ea0"), Color("9ff4ff")]
const PICK: Color = P.MAGENTA
const NOTE: Color = P.AMBER
## Placeholder names on the boot screen (Alex, 2026-11-13: the maker is
## Diligence; the model name is for now). DESIGN-TBD: Q8
const MAKER: String = "DILIGENCE"
const MODEL: String = "CASEBOOK FIELD SLATE MK IV"
const ISSUED: String = "ISSUED TO TRACER G. HASKELL"


## The tablet held up in front of the room: a rugged bezel and a dark screen,
## transparent round the outside so the dimmed room shows.
static func frame() -> Image:
	var img: Image = Px.blank(640, 360)
	var body: Color = Color("141c28")
	Px.rect(img, 24, 10, 592, 340, body)
	Px.rect(img, 22, 12, 596, 336, body)
	Px.rect(img, 24, 10, 592, 1, Color("2a3a50"))
	Px.rect(img, 22, 12, 1, 336, Color("223044"))
	# Rubber bumpers on the corners.
	for c: Vector2i in [Vector2i(22, 10), Vector2i(602, 10), Vector2i(22, 334), Vector2i(602, 334)]:
		Px.rect(img, c.x + 1, c.y + 1, 14, 14, Color("0d131c"))
		Px.rect(img, c.x + 3, c.y + 3, 10, 1, Color("1f2b3b"))
	Px.rect(img, SCREEN.position.x - 2, SCREEN.position.y - 2, SCREEN.size.x + 4, SCREEN.size.y + 4, Color("0a0f16"))
	Px.rect(img, SCREEN.position.x, SCREEN.position.y, SCREEN.size.x, SCREEN.size.y, PH[0])
	# The camera on top, and a power light.
	Px.rect(img, 318, 14, 4, 4, Color("05080c"))
	Px.rect(img, 319, 15, 2, 2, Color("2a3a50"))
	Px.rect(img, 330, 15, 2, 2, Color("2bd96b"))
	Px.text(img, 42, 339, "TB-4", Color("3a4659"))
	Px.text(img, 598 - Px.text_width("TRACER BUREAU"), 339, "TRACER BUREAU", Color("3a4659"))
	return img


## The CRT glass over the screen: every other row darker, corners dithered
## dark, and a faint glare band.
static func glass() -> Image:
	var img: Image = Px.blank(640, 360)
	var s: Rect2i = SCREEN
	for y: int in range(s.size.y):
		for x: int in range(s.size.x):
			var a: float = 0.2 if y & 1 else 0.0
			var edge: int = mini(mini(x, y), mini(s.size.x - 1 - x, s.size.y - 1 - y))
			if edge < 12 and not Px.dither(x, y, float(edge) / 12.0):
				a = maxf(a, 0.45)
			if a > 0.0:
				img.set_pixel(s.position.x + x, s.position.y + y, Color(0, 0, 0, a))
				continue
			var g: float = x - y * 0.55 - 300.0
			if g > 0.0 and g < 24.0 and (x + y) % 4 == 0:
				img.set_pixel(s.position.x + x, s.position.y + y, Color(PH[4], 0.03))
	return img


## The boot screen, at the screen's size: the maker's logo (a wired hive
## cell), the model, who it's issued to, and the self-check.
static func boot() -> Image:
	var w: int = SCREEN.size.x
	var h: int = SCREEN.size.y
	var img: Image = Px.blank(w, h)
	Px.rect(img, 0, 0, w, h, Color("03070a"))
	var c: Vector2 = Vector2(w / 2.0, 112.0)
	Px.glow(img, c.x, c.y, 90, 90, PH[1], 0.9)
	Px.glow(img, c.x, c.y, 46, 46, PH[2], 0.35)
	var outer: Array[Vector2i] = _hex(c, 26.0)
	var inner: Array[Vector2i] = _hex(c, 15.0)
	for i: int in range(6):
		var j: int = (i + 1) % 6
		Px.line(img, outer[i], outer[j], PH[3])
		Px.line(img, outer[i] + Vector2i(1, 0), outer[j] + Vector2i(1, 0), PH[3])
		Px.line(img, inner[i], inner[j], PH[2])
	# Wires out of three corners, each ending on a node.
	for k: int in [0, 2, 4]:
		var p: Vector2i = outer[k]
		var bend: Vector2i = p + (Vector2i(0, -12) if k == 0 else Vector2i(18 if k == 2 else -18, 8))
		var end: Vector2i = bend + (Vector2i(14, 0) if k == 0 else Vector2i(0, 10))
		Px.line(img, p, bend, PH[2])
		Px.line(img, bend, end, PH[2])
		Px.rect(img, end.x - 1, end.y - 1, 3, 3, PH[4])
	Px.rect(img, int(c.x) - 2, int(c.y) - 2, 4, 4, PH[4])
	var spaced: String = " ".join(MAKER.split(""))
	Px.text_scaled(img, int((w - Px.text_width(spaced) * 2) / 2.0), 150, spaced, PH[3], 2)
	Px.text(img, int((w - Px.text_width(MODEL)) / 2.0), 168, MODEL, PH[2])
	Px.text(img, int((w - Px.text_width(ISSUED)) / 2.0), 177, ISSUED, PH[2])
	Px.rect(img, w / 2 - 80, 194, 160, 1, PH[2])
	Px.rect(img, w / 2 - 80, 200, 160, 1, PH[2])
	Px.rect(img, w / 2 - 80, 194, 1, 7, PH[2])
	Px.rect(img, w / 2 + 79, 194, 1, 7, PH[2])
	for x: int in range(156):
		for y: int in range(3):
			if x < 92 or (x < 104 and Px.dither(x, y, 0.5)):
				Px.dot(img, w / 2 - 78 + x, 196 + y, PH[3])
	var log: Array[String] = ["MEM CHECK ........... OK", "OPTIC LINK .......... OK", "READING PORT ........ OK", "CASE SYNC ........... DROWNED MARKET"]
	for i: int in range(log.size()):
		Px.text(img, 12, h - 46 + i * 8, log[i], PH[3] if i == log.size() - 1 else PH[2])
	Px.text(img, w - 12 - Px.text_width("ANY KEY SKIPS"), h - 14, "ANY KEY SKIPS", PH[1])
	return img


static func _hex(c: Vector2, r: float) -> Array[Vector2i]:
	var pts: Array[Vector2i] = []
	for i: int in range(6):
		var a: float = PI / 3.0 * i - PI / 2.0
		pts.append(Vector2i(roundi(c.x + r * cos(a)), roundi(c.y + r * sin(a))))
	return pts


# ---------- captures ----------

## What kind of capture a clue makes, from where it came from.
enum Kind { DOCUMENT, STATEMENT, READING, THERMAL, CAMERA }


static func kind(clue: Clue) -> Kind:
	if clue.text.begins_with("\""):
		return Kind.STATEMENT
	if clue.source == "Memory reading":
		return Kind.READING
	if clue.source == "Thermal optic":
		return Kind.THERMAL
	if clue.source.to_lower().contains("cam"):
		return Kind.CAMERA
	return Kind.DOCUMENT


## The photo the tablet took of `clue`, `w` x `h`, dithered to the phosphor.
## Drawn in grey first, then dithered, so every capture shares one look.
## Placeholder art: one scene per kind, varied by the clue's id.
static func photo(clue: Clue, w: int, h: int) -> Image:
	var img: Image = Px.blank(w, h)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(clue.id)
	match kind(clue):
		Kind.STATEMENT:
			_waveform(img, rng)
		Kind.READING:
			_reading(img, rng)
		Kind.THERMAL:
			_thermal(img)
		Kind.CAMERA:
			_camera(img)
		_:
			_document(img, rng, clue.title)
	return dithered(img, PHOTO)


## `img`'s brightness mapped onto `tones` with a 4x4 ordered dither.
static func dithered(img: Image, tones: Array[Color]) -> Image:
	var out: Image = Px.blank(img.get_width(), img.get_height())
	var n: int = tones.size() - 1
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			var v: float = clampf(img.get_pixel(x, y).get_luminance(), 0.0, 1.0) * n
			var base: int = floori(v)
			var step: int = mini(n, base + (1 if Px.dither(x, y, v - base) else 0))
			out.set_pixel(x, y, tones[step])
	return out


static func _g(v: float) -> Color:
	return Color(v, v, v)


static func _document(img: Image, rng: RandomNumberGenerator, title: String) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	Px.rect(img, 0, 0, w, h, _g(0.09))
	for i: int in range(w * h / 25):
		Px.dot(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), _g(rng.randf_range(0.08, 0.2)))
	var px: int = int(w * 0.08)
	var py: int = int(h * 0.06)
	Px.vgrad(img, px, py, w - px * 2, h - py * 2, _g(0.8), _g(0.5), 5)
	for y: int in range(py + 12, h - py - 3, 6):
		Px.rect(img, px + 4, y, w - px * 2 - 8, 1, _g(0.42))
		if y > py + 12 and w > 80:
			Px.rect(img, px + 6, y - 4, rng.randi_range(20, w - px * 2 - 24), 3, _g(0.25))
	if w > 80:
		Px.text(img, px + 6, py + 4, title, _g(0.1))
	Px.glow(img, w * 0.8, h * 0.18, w * 0.3, h * 0.35, Color.WHITE, 0.5)


static func _waveform(img: Image, rng: RandomNumberGenerator) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	Px.rect(img, 0, 0, w, h, _g(0.05))
	Px.rect(img, 0, h / 2, w, 1, _g(0.25))
	for x: int in range(2, w - 2, 3):
		var a: float = absf(sin(x * 0.11 + rng.randf()) * 0.6 + rng.randf_range(-0.3, 0.3))
		var bar: int = maxi(1, int(a * h * 0.4))
		Px.rect(img, x, h / 2 - bar, 2, bar * 2, _g(0.75))


static func _reading(img: Image, rng: RandomNumberGenerator) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	Px.vgrad(img, 0, 0, w, h, _g(0.3), _g(0.06), 5)
	Px.poly(img, PackedVector2Array([Vector2(0, 0), Vector2(w * 0.38, h * 0.3), Vector2(w * 0.38, h * 0.85), Vector2(0, h)]), _g(0.14))
	Px.poly(img, PackedVector2Array([Vector2(w, 0), Vector2(w * 0.62, h * 0.3), Vector2(w * 0.62, h * 0.85), Vector2(w, h)]), _g(0.14))
	Px.vgrad(img, int(w * 0.44), int(h * 0.33), int(w * 0.12), int(h * 0.52), _g(0.65), _g(0.35), 3)
	# Memories can be edited: torn rows and noise.
	var copy: Image = img.duplicate()
	for k: int in range(maxi(3, h / 10)):
		var y: int = rng.randi_range(0, h - 1)
		var shift: int = rng.randi_range(-w / 8, w / 8)
		for yy: int in range(y, mini(h, y + rng.randi_range(1, 3))):
			for x: int in range(w):
				img.set_pixel(x, yy, copy.get_pixel(clampi(x - shift, 0, w - 1), yy))
	for i: int in range(w * h / 6):
		var x: int = rng.randi_range(0, w - 1)
		var y: int = rng.randi_range(0, h - 1)
		img.set_pixel(x, y, img.get_pixel(x, y).lightened(rng.randf_range(-0.2, 0.2)))


static func _thermal(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	Px.rect(img, 0, 0, w, h, _g(0.05))
	Px.rect(img, 0, int(h * 0.7), w, h - int(h * 0.7), _g(0.12))
	for i: int in range(4):
		Px.glow(img, w * 0.5, h * 0.66, w * (0.34 - i * 0.07), h * (0.1 - i * 0.015), Color.WHITE, 0.35)
	Px.glow(img, w * 0.22, h * 0.64, h * 0.16, h * 0.13, Color.WHITE, 0.6)


static func _camera(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	Px.rect(img, 0, 0, w, h, _g(0.06))
	Px.vgrad(img, 0, int(h * 0.62), w, h - int(h * 0.62), _g(0.15), _g(0.28), 4)
	Px.poly(img, PackedVector2Array([Vector2(w * 0.05, h * 0.25), Vector2(w * 0.42, h * 0.25), Vector2(w * 0.38, h * 0.42), Vector2(w * 0.09, h * 0.42)]), _g(0.3))
	Px.rect(img, int(w * 0.1), int(h * 0.42), int(w * 0.28), int(h * 0.25), _g(0.1))
	Px.glow(img, w * 0.24, h * 0.42, w * 0.3, h * 0.5, Color.WHITE, 0.45)
	var fx: float = w * 0.64
	var s: float = h / 100.0
	Px.ellipse(img, fx, h * 0.36, 5 * s, 5 * s, _g(0.02))
	Px.rect(img, int(fx - 6 * s), int(h * 0.36 + 5 * s), int(12 * s), int(24 * s), _g(0.02))
	Px.poly(img, PackedVector2Array([Vector2(fx - 5 * s, h * 0.36 + 28 * s), Vector2(fx - 11 * s, h * 0.36 + 52 * s), Vector2(fx - 6 * s, h * 0.36 + 52 * s), Vector2(fx, h * 0.36 + 32 * s), Vector2(fx + 8 * s, h * 0.36 + 52 * s), Vector2(fx + 13 * s, h * 0.36 + 52 * s), Vector2(fx + 5 * s, h * 0.36 + 28 * s)]), _g(0.02))
	for y: int in range(0, h, 3):
		Px.rect(img, 0, y, w, 1, Color(0, 0, 0, 0.25))
	if w > 80:
		Px.text(img, 4, 4, "CAM 03", _g(0.95))
