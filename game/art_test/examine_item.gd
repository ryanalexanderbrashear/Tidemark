class_name ExamineItem
extends RefCounted
## One thing the detective can hold up and turn over in the examine view: a box
## (a slab, for paper and tags) with a pixel-art image on each of its six faces,
## and at most one hidden detail on one face, found by turning that face to
## the camera. Rotation test only: real items will be data, and finding a
## detail would hand the case a clue through `Case`.

## Texels per world unit. At zoom 1 one texel is one game pixel, so close-ups
## sit on the same pixel grid as the market behind them.
const TEXELS: float = 100.0
## Faces by the local direction they point.
const FACES: Dictionary[String, Vector3] = {
	"front": Vector3.BACK, "back": Vector3.FORWARD,
	"right": Vector3.RIGHT, "left": Vector3.LEFT,
	"top": Vector3.UP, "bottom": Vector3.DOWN,
}

const P = preload("res://game/art_test/art_palette.gd")

var id: String = ""
var title: String = ""
## Width, height and thickness in world units.
var size: Vector3 = Vector3.ONE
var faces: Dictionary[String, Image] = {}
var metallic: float = 0.0
var roughness: float = 0.7
## What the detective sees at a glance.
var notes: Array[String] = []
## The face the hidden detail is on ("" for none), and what finding it adds.
var detail_face: String = ""
var detail_note: String = ""
var detail_thought: String = ""

## Items that open: the front face is a lid hinged on its left edge, and it
## only opens once the hidden detail (the catch) has been found.
var opens: bool = false
## Inside the item: the floor with what's in it, the floor once it's taken
## out, the underside of the lid, and the inner walls.
var inside: Image
var inside_empty: Image
var lid_inside: Image
var wall_inside: Color = P.DEEP
var open_note: String = ""
## What can be taken out once it's open (null: nothing).
var contains: ExamineItem


## The pixel size a face's image has to be.
func face_size(face: String) -> Vector2i:
	var n: Vector3 = FACES[face]
	var w: float = size.z if n.x != 0.0 else size.x
	var h: float = size.z if n.y != 0.0 else size.y
	return Vector2i(roundi(w * TEXELS), roundi(h * TEXELS))


## How squarely a face looks at the camera (1: straight on, below 0: away),
## with the item turned by `turn`. The camera looks down -Z.
static func facing(turn: Basis, face: String) -> float:
	return (turn * FACES[face]).normalized().dot(Vector3.BACK)


static func all() -> Array[ExamineItem]:
	return [chip(), tag(), tin()]


# ---------- the calling card ----------

## The wiped memory chip left on Vale (clue "chip"). The CS-14-07 etching is
## on the back, so it only turns up when the player turns the chip over.
static func chip() -> ExamineItem:
	var it: ExamineItem = ExamineItem.new()
	it.id = "chip"
	it.title = "Memory chip"
	it.size = Vector3(1.2, 0.8, 0.1)
	it.metallic = 0.3
	it.roughness = 0.5
	it.notes = ["A blank memory chip, wiped."]
	it.detail_face = "back"
	it.detail_note = "Etched on the casing: CS-14-07."
	# Placeholder line, not canon dialogue.
	it.detail_thought = "Scratched in by hand, not stamped at a factory. Someone meant this to be read."
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1407

	var front: Image = _casing(it.face_size("front"), rng)
	# Gold contacts along the connector end.
	Px.rect(front, 106, 12, 10, 56, P.DEEP)
	for y: int in range(14, 66, 3):
		Px.rect(front, 107, y, 8, 2, P.AMBER_DIM)
		Px.dot(front, 107, y, P.AMBER)
	# The label, scraped half off when it was wiped.
	Px.rect(front, 10, 12, 80, 44, P.FOG)
	Px.rect(front, 10, 12, 80, 1, P.RAIN)
	Px.rect(front, 10, 13, 80, 6, P.CYAN_DIM)
	for y: int in range(24, 54, 5):
		Px.rect(front, 14, y, 72, 1, Color(P.CONCRETE, 0.6))
	for i: int in range(220):
		var x: int = rng.randi_range(40, 89)
		var y: int = rng.randi_range(12, 55)
		Px.rect(front, x, y, rng.randi_range(1, 4), 1, P.STEEL)
	Px.screen(front, 52, 12, 38, 44, P.STEEL, 0.55)
	# A dead status light.
	Px.rect(front, 96, 18, 3, 3, P.SLATE)
	Px.dot(front, 97, 19, P.CYAN_DIM)
	it.faces["front"] = front

	var back: Image = _casing(it.face_size("back"), rng)
	for y: int in range(10, 50, 4):
		Px.rect(back, 14, y, 92, 1, P.SLATE)
		Px.rect(back, 14, y + 1, 92, 1, Color(P.CONCRETE, 0.5))
	for at: Vector2i in [Vector2i(6, 6), Vector2i(111, 6), Vector2i(6, 71), Vector2i(111, 71)]:
		Px.ellipse(back, at.x + 1.5, at.y + 1.5, 2.5, 2.5, P.CONCRETE)
		Px.dot(back, at.x + 1, at.y + 1, P.DEEP)
		Px.dot(back, at.x + 2, at.y + 2, P.DEEP)
	# The etching: thin, hand-scratched strokes with a groove shadow under them.
	var code: String = "CS-14-07"
	var ex: int = 60
	var ey: int = 60
	for i: int in range(code.length()):
		var jitter: int = (i * 7) % 3 - 1
		Px.text(back, ex + i * 5, ey + jitter + 1, code[i], P.DEEP)
		Px.text(back, ex + i * 5, ey + jitter, code[i], P.RAIN)
	Px.line(back, Vector2i(ex - 2, ey + 9), Vector2i(ex + 40, ey + 8), Color(P.RAIN, 0.5))
	it.faces["back"] = back

	for face: String in ["left", "top", "bottom"]:
		it.faces[face] = _edge(it.face_size(face))
	var conn: Image = _edge(it.face_size("right"))
	Px.rect(conn, 2, 12, 6, 56, P.INK)
	for y: int in range(14, 66, 3):
		Px.rect(conn, 3, y, 4, 1, P.AMBER_DIM)
	it.faces["right"] = conn
	return it


static func _casing(px: Vector2i, rng: RandomNumberGenerator) -> Image:
	var img: Image = Px.blank(px.x, px.y)
	img.fill(P.STEEL)
	Px.rect(img, 0, 0, px.x, 1, P.CONCRETE)
	Px.rect(img, 0, 0, 1, px.y, P.CONCRETE)
	Px.rect(img, 0, px.y - 1, px.x, 1, P.SLATE)
	Px.rect(img, px.x - 1, 0, 1, px.y, P.SLATE)
	Px.rect(img, 2, 2, px.x - 4, 1, Color(P.CONCRETE, 0.5))
	for i: int in range(40):
		Px.dot(img, rng.randi_range(2, px.x - 3), rng.randi_range(2, px.y - 3), Color(P.RAIN, 0.35))
	return img


static func _edge(px: Vector2i) -> Image:
	var img: Image = Px.blank(px.x, px.y)
	img.fill(P.SLATE)
	if px.x < px.y:
		Px.rect(img, px.x / 2, 0, 1, px.y, P.DEEP)
	else:
		Px.rect(img, 0, px.y / 2, px.x, 1, P.DEEP)
	return img


# ---------- the drawer tag ----------

## The ID tag from the case in Vale's rented drawer (clue "tag"). A flat item:
## the same box, thin enough to read as a slab you flip like paper.
static func tag() -> ExamineItem:
	var it: ExamineItem = ExamineItem.new()
	it.id = "tag"
	it.title = "Storage case ID tag"
	it.size = Vector3(1.0, 0.5, 0.03)
	it.roughness = 0.85
	it.notes = ["From the empty case in Vale's rented drawer.", "It reads \"D. Marr\", not Vale."]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 88

	var front: Image = _card(it.face_size("front"), rng)
	Px.text_scaled(front, 26, 9, "D. MARR", P.INK, 2)
	for x: int in range(26, 86):
		if (x * 5 + x / 3) % 4 != 0:
			Px.rect(front, x, 26, 1, 12, P.NAVY if x % 3 != 0 else P.SLATE)
	Px.text(front, 26, 41, "ID", P.SLATE)
	it.faces["front"] = front

	var back: Image = _card(it.face_size("back"), rng)
	for i: int in range(6):
		var a: Vector2i = Vector2i(rng.randi_range(22, 90), rng.randi_range(6, 44))
		Px.line(back, a, a + Vector2i(rng.randi_range(4, 12), rng.randi_range(-2, 2)), Color(P.CONCRETE, 0.7))
	Px.screen(back, 60, 28, 26, 14, P.CONCRETE, 0.3)
	it.faces["back"] = back
	for face: String in ["left", "right", "top", "bottom"]:
		var e: Image = Px.blank(it.face_size(face).x, it.face_size(face).y)
		e.fill(P.CONCRETE)
		it.faces[face] = e
	return it


## Pale plastic with a punched hole on the left (the hole is see-through).
static func _card(px: Vector2i, rng: RandomNumberGenerator) -> Image:
	var img: Image = Px.blank(px.x, px.y)
	img.fill(P.RAIN)
	Px.rect(img, 0, 0, px.x, 1, P.GLINT)
	Px.rect(img, 0, px.y - 1, px.x, 1, P.FOG)
	Px.rect(img, px.x - 1, 0, 1, px.y, P.FOG)
	for i: int in range(30):
		Px.dot(img, rng.randi_range(1, px.x - 2), rng.randi_range(1, px.y - 2), Color(P.FOG, 0.6))
	Px.ellipse(img, 11.5, px.y * 0.5, 6.5, 6.5, P.FOG)
	var hole: float = 4.5
	for y: int in range(px.y):
		for x: int in range(24):
			var d: Vector2 = Vector2(x + 0.5 - 11.5, y + 0.5 - px.y * 0.5)
			if d.length() <= hole:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return img


# ---------- something hidden inside ----------

## A test item, not from the case: a pocket tin with a catch on its right edge.
## Turn it to find the catch, open it, and take out what's inside.
static func tin() -> ExamineItem:
	var it: ExamineItem = ExamineItem.new()
	it.id = "tin"
	it.title = "Pocket tin (test item)"
	it.size = Vector3(0.9, 0.6, 0.22)
	it.metallic = 0.35
	it.roughness = 0.4
	it.notes = ["A test item, not from the case.", "Dented, and heavier than it looks."]
	it.detail_face = "right"
	it.detail_note = "A slide catch on the side. It opens."
	# Placeholder line, not canon dialogue.
	it.detail_thought = "Somebody filed the catch down so it sits flush. Not meant to be found."
	it.opens = true
	it.open_note = "Inside: a slip of paper, folded small."
	it.contains = slip()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2207

	var lid: Image = _casing(it.face_size("front"), rng)
	Px.rect(lid, 6, 6, 78, 48, P.SLATE)
	Px.rect(lid, 7, 7, 76, 46, P.STEEL)
	for i: int in range(5):
		Px.ellipse(lid, rng.randf_range(15, 75), rng.randf_range(12, 48), 3.5, 2.5, Color(P.SLATE, 0.8))
	it.faces["front"] = lid
	var back: Image = _casing(it.face_size("back"), rng)
	it.faces["back"] = back
	for face: String in ["left", "top", "bottom"]:
		it.faces[face] = _edge(it.face_size(face))
	# The catch: a thin slider filed flush with the edge, only a glint and a notch.
	var side: Image = _edge(it.face_size("right"))
	Px.rect(side, 6, 22, 10, 16, P.STEEL)
	Px.rect(side, 6, 22, 10, 1, P.GLINT)
	Px.rect(side, 10, 28, 2, 4, P.INK)
	it.faces["right"] = side

	var inside_px: Vector2i = it.face_size("front")
	it.inside_empty = Px.blank(inside_px.x, inside_px.y)
	it.inside_empty.fill(P.DEEP)
	Px.rect(it.inside_empty, 4, 4, inside_px.x - 8, inside_px.y - 8, P.NIGHT)
	it.inside = it.inside_empty.duplicate() as Image
	var paper: Image = it.contains.faces["front"]
	var small: Image = paper.duplicate() as Image
	small.resize(paper.get_width() * 3 / 4, paper.get_height() * 3 / 4, Image.INTERPOLATE_NEAREST)
	Px.stamp(it.inside, small, 16, 14)
	it.lid_inside = Px.blank(inside_px.x, inside_px.y)
	it.lid_inside.fill(P.SLATE)
	Px.rect(it.lid_inside, 3, 3, inside_px.x - 6, inside_px.y - 6, P.STEEL)
	return it


## What's in the tin: a folded slip of paper, scribbled on. Placeholder: it
## says nothing yet, because what it says would be canon.
static func slip() -> ExamineItem:
	var it: ExamineItem = ExamineItem.new()
	it.id = "slip"
	it.title = "Folded slip (test item)"
	it.size = Vector3(0.7, 0.45, 0.01)
	it.roughness = 0.95
	it.notes = ["Taken out of the pocket tin.", "Placeholder scribbles: what it says is for the case to decide."]
	var front: Image = Px.blank(it.face_size("front").x, it.face_size("front").y)
	front.fill(P.RAIN)
	Px.rect(front, 0, 0, front.get_width(), 1, P.GLINT)
	Px.rect(front, front.get_width() / 2, 0, 1, front.get_height(), P.FOG)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 31
	for row: int in range(4):
		var y: int = 9 + row * 8
		var x: int = 6
		while x < 62:
			var w: int = rng.randi_range(3, 9)
			Px.line(front, Vector2i(x, y + rng.randi_range(-1, 1)), Vector2i(x + w, y + rng.randi_range(-1, 1)), P.NAVY)
			x += w + rng.randi_range(2, 4)
	it.faces["front"] = front
	var back: Image = Px.blank(it.face_size("back").x, it.face_size("back").y)
	back.fill(P.RAIN)
	Px.rect(back, back.get_width() / 2, 0, 1, back.get_height(), P.FOG)
	it.faces["back"] = back
	for face: String in ["left", "right", "top", "bottom"]:
		var e: Image = Px.blank(maxi(1, it.face_size(face).x), maxi(1, it.face_size(face).y))
		e.fill(P.FOG)
		it.faces[face] = e
	return it
