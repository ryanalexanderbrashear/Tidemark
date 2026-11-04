class_name Px
extends RefCounted
## Small pixel-art drawing kit for the art test: every layer and sprite in the
## Drowned Market style test is drawn into an Image with these, at native
## resolution, so the look can be tuned in code until hand-drawn art replaces it.

## 4x4 ordered-dither thresholds (0..15).
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

## A 3x5 font for signs: each glyph is five rows of three bits, top row first.
const FONT: Dictionary[String, Array] = {
	"A": [2, 5, 7, 5, 5], "B": [6, 5, 6, 5, 6], "C": [3, 4, 4, 4, 3], "D": [6, 5, 5, 5, 6],
	"E": [7, 4, 6, 4, 7], "F": [7, 4, 6, 4, 4], "G": [3, 4, 5, 5, 3], "H": [5, 5, 7, 5, 5],
	"I": [7, 2, 2, 2, 7], "J": [1, 1, 1, 5, 2], "K": [5, 5, 6, 5, 5], "L": [4, 4, 4, 4, 7],
	"M": [5, 7, 7, 5, 5], "N": [6, 5, 5, 5, 5], "O": [2, 5, 5, 5, 2], "P": [6, 5, 6, 4, 4],
	"Q": [2, 5, 5, 6, 3], "R": [6, 5, 6, 5, 5], "S": [3, 4, 2, 1, 6], "T": [7, 2, 2, 2, 2],
	"U": [5, 5, 5, 5, 7], "V": [5, 5, 5, 5, 2], "W": [5, 5, 7, 7, 5], "X": [5, 5, 2, 5, 5],
	"Y": [5, 5, 2, 2, 2], "Z": [7, 1, 2, 4, 7], "0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7],
	"2": [6, 1, 2, 4, 7], "3": [6, 1, 2, 1, 6], "4": [5, 5, 7, 1, 1], "5": [7, 4, 6, 1, 6],
	"6": [3, 4, 7, 5, 7], "7": [7, 1, 2, 2, 2], "8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 6],
	"-": [0, 0, 7, 0, 0], " ": [0, 0, 0, 0, 0],
}


static func blank(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


static func inside(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()


static func dither(x: int, y: int, t: float) -> bool:
	return t * 16.0 > float(BAYER[(y & 3) * 4 + (x & 3)])


## Alpha-blends one pixel over what is there.
static func dot(img: Image, x: int, y: int, c: Color) -> void:
	if not inside(img, x, y) or c.a <= 0.0:
		return
	if c.a >= 1.0:
		img.set_pixel(x, y, c)
		return
	var under: Color = img.get_pixel(x, y)
	var a: float = c.a + under.a * (1.0 - c.a)
	var rgb: Color = (Color(c.r, c.g, c.b) * c.a + Color(under.r, under.g, under.b) * under.a * (1.0 - c.a)) / maxf(a, 0.0001)
	img.set_pixel(x, y, Color(rgb.r, rgb.g, rgb.b, a))


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if c.a >= 1.0:
		img.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height())), c)
		return
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			dot(img, xx, yy, c)


## Vertical gradient from `top` to `bottom`, ordered-dithered between the two.
static func vgrad(img: Image, x: int, y: int, w: int, h: int, top: Color, bottom: Color, steps: int = 6) -> void:
	for yy: int in range(y, y + h):
		var t: float = float(yy - y) / maxf(float(h - 1), 1.0) * float(steps)
		var band: float = floorf(t)
		var frac: float = t - band
		var c0: Color = top.lerp(bottom, band / float(steps))
		var c1: Color = top.lerp(bottom, minf(band + 1.0, float(steps)) / float(steps))
		for xx: int in range(x, x + w):
			dot(img, xx, yy, c1 if dither(xx, yy, frac) else c0)


## Dithered rectangle at partial coverage `t` (0..1), for haze and wet sheen.
static func screen(img: Image, x: int, y: int, w: int, h: int, c: Color, t: float) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			if dither(xx, yy, t):
				dot(img, xx, yy, c)


static func line(img: Image, from: Vector2i, to: Vector2i, c: Color) -> void:
	var d: Vector2i = to - from
	var n: int = maxi(absi(d.x), absi(d.y))
	for i: int in range(n + 1):
		var t: float = float(i) / maxf(float(n), 1.0)
		dot(img, roundi(lerpf(from.x, to.x, t)), roundi(lerpf(from.y, to.y, t)), c)


## A sagging cable between two points.
static func cable(img: Image, from: Vector2i, to: Vector2i, sag: float, c: Color) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	var n: int = maxi(absi(to.x - from.x), 2)
	var last: Vector2i = from
	for i: int in range(n + 1):
		var t: float = float(i) / float(n)
		var p: Vector2i = Vector2i(roundi(lerpf(from.x, to.x, t)), roundi(lerpf(from.y, to.y, t) + sag * 4.0 * t * (1.0 - t)))
		line(img, last, p, c)
		last = p
		pts.append(Vector2(p))
	return pts


static func poly(img: Image, points: PackedVector2Array, c: Color) -> void:
	var box: Rect2 = Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		box = box.expand(p)
	for yy: int in range(floori(box.position.y), ceili(box.end.y) + 1):
		for xx: int in range(floori(box.position.x), ceili(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), points):
				dot(img, xx, yy, c)


static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy: int in range(floori(cy - ry), ceili(cy + ry) + 1):
		for xx: int in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx: float = (xx + 0.5 - cx) / rx
			var dy: float = (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				dot(img, xx, yy, c)


## A pool of light in three dithered bands, brightest at the centre. Drawn with
## alpha, so it reads as light on whatever is under it.
static func glow(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color, strength: float = 0.5) -> void:
	for yy: int in range(floori(cy - ry), ceili(cy + ry) + 1):
		for xx: int in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx: float = (xx + 0.5 - cx) / rx
			var dy: float = (yy + 0.5 - cy) / ry
			var d: float = sqrt(dx * dx + dy * dy)
			if d >= 1.0:
				continue
			var level: float = (1.0 - d) * 3.0
			var band: float = floorf(level)
			if dither(xx, yy, level - band):
				band += 1.0
			if band <= 0.0:
				continue
			dot(img, xx, yy, Color(c, strength * band / 3.0))


static func text_width(s: String) -> int:
	return s.length() * 4 - 1


static func text(img: Image, x: int, y: int, s: String, c: Color) -> void:
	var cx: int = x
	for ch: String in s.to_upper():
		var rows: Array = FONT.get(ch, FONT[" "])
		for r: int in range(5):
			var bits: int = rows[r]
			for b: int in range(3):
				if bits & (4 >> b):
					dot(img, cx + b, y + r, c)
		cx += 4


## Copies `src` onto `dst` at (x, y), blending alpha.
static func stamp(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))


static func is_solid(img: Image, x: int, y: int) -> bool:
	return inside(img, x, y) and img.get_pixel(x, y).a > 0.5


## Darkens the outermost pixels of a sprite and lights its edges from behind:
## `left` on edges facing left, `right` on edges facing right, `top` on top edges.
static func rim(img: Image, outline: Color, left: Color, right: Color, top: Color) -> void:
	var src: Image = img.duplicate() as Image
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			if not is_solid(src, x, y):
				continue
			var open_l: bool = not is_solid(src, x - 1, y)
			var open_r: bool = not is_solid(src, x + 1, y)
			var open_t: bool = not is_solid(src, x, y - 1)
			var open_b: bool = not is_solid(src, x, y + 1)
			if open_l or open_r or open_t or open_b:
				img.set_pixel(x, y, outline)
			if open_r and right.a > 0.0:
				dot(img, x - 1, y, right)
			if open_l and left.a > 0.0:
				dot(img, x + 1, y, left)
			if open_t and top.a > 0.0:
				dot(img, x, y + 1, top)
