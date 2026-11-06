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
	return [chip(), tag()]


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
