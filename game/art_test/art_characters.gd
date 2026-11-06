class_name ArtCharacters
extends RefCounted
## The three people in the style test, drawn as pixel sprites. The detective here
## is the first sketch; ArtDetective is his closer-to-final pass. Each is lit from
## behind by the market's neon (magenta on the left edge, cyan on the right) and
## from above by the sodium lamps, so they read as silhouettes first and faces second.
##
## Their looks are placeholders made for this test, not canon: the docs don't
## describe what the detective, Osk or the fixer look like yet.

const P = preload("res://game/art_test/art_palette.gd")

const DETECTIVE_SIZE: Vector2i = Vector2i(32, 60)
const OSK_SIZE: Vector2i = Vector2i(40, 60)
const FIXER_SIZE: Vector2i = Vector2i(28, 64)
const WALK_FRAMES: int = 6

const COAT: Color = Color("1e2838")
const COAT_SHADE: Color = Color("131a26")
const COLLAR: Color = Color("2a3650")
const SHIRT: Color = Color("3a4556")
const PANTS: Color = Color("121825")
const PANTS_BACK: Color = Color("0c111b")
const SHOE: Color = Color("080b12")
const HAIR: Color = Color("0f131b")


## One frame of the detective, facing right. Frames 0..5 walk; idle uses 0 and 1
## (a one-pixel breath).
static func detective(frame: int, walking: bool) -> Image:
	var img: Image = Px.blank(DETECTIVE_SIZE.x, DETECTIVE_SIZE.y)
	var ph: float = TAU * float(frame % WALK_FRAMES) / float(WALK_FRAMES)
	var swing: float = sin(ph) if walking else 0.0
	var bob: int = (1 if frame % 3 == 1 else 0) if walking else (frame % 2)
	# Legs first, so the coat hangs over them.
	_leg(img, Vector2(14, 41 + bob), 14.0 - swing * 5.0, walking and cos(ph) < 0.0, PANTS_BACK)
	_leg(img, Vector2(18, 41 + bob), 18.0 + swing * 5.0, walking and cos(ph) > 0.0, PANTS)
	var b: float = float(bob)
	var hem: float = roundf(swing * 1.5)
	Px.poly(img, PackedVector2Array([
		Vector2(11, 15 + b), Vector2(21, 15 + b), Vector2(23, 18 + b), Vector2(23.5, 32 + b),
		Vector2(25 + hem, 48 + b), Vector2(19, 49 + b), Vector2(13, 49 + b), Vector2(7.5 + hem, 48 + b),
		Vector2(9, 32 + b), Vector2(9, 18 + b)]), COAT)
	# Shadowed back half, folds, belt, the open front.
	Px.poly(img, PackedVector2Array([Vector2(9, 18 + b), Vector2(12, 16 + b), Vector2(12, 49 + b), Vector2(7.5 + hem, 48 + b), Vector2(9, 32 + b)]), COAT_SHADE)
	Px.line(img, Vector2i(14, 34 + bob), Vector2i(14 + int(hem), 48 + bob), COAT_SHADE)
	Px.line(img, Vector2i(18, 35 + bob), Vector2i(19 + int(hem), 48 + bob), COAT_SHADE)
	Px.rect(img, 9, 31 + bob, 15, 1, COAT_SHADE)
	Px.dot(img, 20, 31 + bob, P.CONCRETE)
	Px.rect(img, 18, 16 + bob, 2, 9, SHIRT)
	Px.line(img, Vector2i(20, 17 + bob), Vector2i(21, 47 + bob), Color("27334a"))
	# Near arm, hand in the pocket.
	Px.line(img, Vector2i(21, 17 + bob), Vector2i(22, 30 + bob), COAT_SHADE)
	Px.line(img, Vector2i(20, 18 + bob), Vector2i(21, 30 + bob), COAT_SHADE)
	Px.rect(img, 19, 31 + bob, 4, 2, COAT_SHADE)
	# Shoulders catch the lamps above.
	Px.rect(img, 12, 15 + bob, 9, 1, Color("2c3a52"))
	# High collar, neck, head.
	Px.poly(img, PackedVector2Array([Vector2(10, 10 + b), Vector2(13, 9 + b), Vector2(14, 15 + b), Vector2(10, 16 + b)]), COLLAR)
	Px.poly(img, PackedVector2Array([Vector2(19, 10 + b), Vector2(21.5, 11 + b), Vector2(22, 16 + b), Vector2(18, 15 + b)]), COLLAR)
	Px.rect(img, 14, 11 + bob, 4, 4, P.SKIN_SHADE)
	Px.ellipse(img, 16.5, 7.0 + b, 5.0, 6.0, P.SKIN)
	Px.ellipse(img, 15.0, 4.8 + b, 5.2, 4.3, HAIR)
	Px.rect(img, 11, 4 + bob, 5, 7, HAIR)
	Px.poly(img, PackedVector2Array([Vector2(17, 5 + b), Vector2(21, 5 + b), Vector2(21.6, 9 + b), Vector2(20, 12.5 + b), Vector2(16.5, 12.5 + b), Vector2(16.5, 7 + b)]), P.SKIN)
	Px.line(img, Vector2i(16, 3 + bob), Vector2i(20, 4 + bob), HAIR)
	Px.rect(img, 17, 11 + bob, 4, 2, P.SKIN_SHADE)
	Px.rect(img, 16, 6 + bob, 1, 6, P.SKIN_SHADE)
	Px.rect(img, 18, 6 + bob, 3, 1, P.SKIN_SHADE)
	Px.dot(img, 21, 10 + bob, P.SKIN_SHADE)
	# The ocular implant: the one bright point on him.
	Px.dot(img, 19, 7 + bob, P.CYAN)
	Px.dot(img, 20, 7 + bob, P.CYAN_DIM)
	Px.dot(img, 18, 7 + bob, Color(P.CYAN_DIM, 0.6))
	_light(img)
	Px.dot(img, 19, 7 + bob, P.CYAN)
	return img


static func _leg(img: Image, hip: Vector2, foot_x: float, lifted: bool, c: Color) -> void:
	var ankle: Vector2 = Vector2(foot_x, 56.0 - (2.0 if lifted else 0.0))
	var knee: Vector2 = Vector2((hip.x + ankle.x) * 0.5 + 1.5, (hip.y + ankle.y) * 0.5)
	for seg: Array in [[hip, knee], [knee, ankle]]:
		var a: Vector2 = seg[0]
		var z: Vector2 = seg[1]
		Px.poly(img, PackedVector2Array([a + Vector2(-2.2, 0), a + Vector2(2.2, 0), z + Vector2(2.0, 0), z + Vector2(-2.0, 0)]), c)
	Px.rect(img, roundi(ankle.x) - 2, roundi(ankle.y), 7, 3, SHOE)


## Osk, the rival broker: short and broad, a clear rain poncho, a lit umbrella.
## Faces left, toward Vale's stall.
static func osk(frame: int) -> Image:
	var img: Image = Px.blank(OSK_SIZE.x, OSK_SIZE.y)
	var b: int = frame % 2
	var fb: float = float(b)
	Px.rect(img, 13, 50, 5, 7, PANTS_BACK)
	Px.rect(img, 20, 50, 5, 7, PANTS)
	Px.rect(img, 11, 56, 7, 3, SHOE)
	Px.rect(img, 19, 56, 7, 3, SHOE)
	var jacket: Color = Color("3a2724")
	var jacket_dark: Color = Color("261a19")
	Px.poly(img, PackedVector2Array([Vector2(10, 29 + fb), Vector2(28, 29 + fb), Vector2(30, 35 + fb), Vector2(29, 51), Vector2(9, 51), Vector2(8, 35 + fb)]), jacket)
	Px.poly(img, PackedVector2Array([Vector2(20, 29 + fb), Vector2(28, 29 + fb), Vector2(30, 35 + fb), Vector2(29, 51), Vector2(21, 51)]), jacket_dark)
	Px.rect(img, 9, 44, 21, 1, jacket_dark)
	Px.line(img, Vector2i(17, 30 + b), Vector2i(17, 50), Color("5a3a30"))
	# Near arm hangs, holding a broker's memory case.
	Px.line(img, Vector2i(10, 31 + b), Vector2i(9, 43), jacket_dark)
	Px.line(img, Vector2i(11, 31 + b), Vector2i(10, 43), jacket_dark)
	Px.rect(img, 6, 43, 7, 5, P.STEEL)
	Px.rect(img, 7, 44, 5, 1, P.CYAN_DIM)
	# Arm up to the umbrella.
	Px.line(img, Vector2i(26, 31 + b), Vector2i(27, 20), Color("3b231d"))
	Px.line(img, Vector2i(27, 31 + b), Vector2i(28, 20), Color("3b231d"))
	Px.rect(img, 26, 18, 3, 3, P.SKIN_SHADE)
	# Bald head, goggles pushed up, heavy jaw.
	Px.ellipse(img, 17.5, 23.0 + fb, 5.0, 5.5, P.SKIN)
	Px.rect(img, 13, 26 + b, 9, 3, P.SKIN_SHADE)
	Px.rect(img, 12, 20 + b, 11, 1, Color("1a1410"))
	Px.rect(img, 13, 19 + b, 2, 2, Color("4a3a20"))
	Px.rect(img, 16, 19 + b, 2, 2, Color("4a3a20"))
	Px.dot(img, 13, 19 + b, P.AMBER_DIM)
	Px.dot(img, 14, 23 + b, P.INK)
	Px.dot(img, 13, 24 + b, P.SKIN_SHADE)
	# The umbrella.
	Px.line(img, Vector2i(27, 4), Vector2i(27, 20), P.STEEL)
	for y: int in range(7):
		var half: float = 15.0 * sqrt(1.0 - pow(float(6 - y) / 7.0, 2.0))
		Px.rect(img, roundi(25.0 - half), 3 + y, roundi(half * 2.0), 1, Color("161f2e") if y < 6 else Color("0e1520"))
	for rib: int in [12, 19, 25, 31, 37]:
		Px.line(img, Vector2i(25, 3), Vector2i(rib, 9), Color("223047"))
	# Poncho over everything, then the light.
	Px.line(img, Vector2i(13, 31 + b), Vector2i(12, 42), Color(P.RAIN, 0.35))
	Px.line(img, Vector2i(23, 31 + b), Vector2i(25, 42), Color(P.RAIN, 0.25))
	Px.rect(img, 10, 29 + b, 18, 1, Color(P.RAIN, 0.3))
	_light(img)
	# LED trim on the umbrella's edge, drawn after the rim so it stays bright.
	for x: int in range(11, 40, 2):
		Px.dot(img, x, 9, P.CYAN if (x + frame) % 6 != 0 else P.CYAN_DIM)
	return img


## The fixer: tall, thin, hooded, a magenta visor where the face should be.
static func fixer(frame: int) -> Image:
	var img: Image = Px.blank(FIXER_SIZE.x, FIXER_SIZE.y)
	var b: float = float(frame % 2)
	var bi: int = frame % 2
	Px.line(img, Vector2i(12, 46), Vector2i(12, 60), PANTS_BACK)
	Px.line(img, Vector2i(13, 46), Vector2i(13, 60), PANTS_BACK)
	Px.line(img, Vector2i(16, 46), Vector2i(16, 60), PANTS)
	Px.line(img, Vector2i(17, 46), Vector2i(17, 60), PANTS)
	Px.rect(img, 10, 60, 5, 3, SHOE)
	Px.rect(img, 15, 60, 5, 3, SHOE)
	var coat: Color = Color("1d1828")
	Px.poly(img, PackedVector2Array([Vector2(9, 15 + b), Vector2(19, 15 + b), Vector2(21, 21 + b), Vector2(20.5, 47), Vector2(17, 51), Vector2(10, 51), Vector2(7.5, 47), Vector2(7, 21 + b)]), coat)
	Px.rect(img, 8, 27 + bi, 13, 3, Color("15111e"))
	Px.rect(img, 8, 30 + bi, 13, 1, Color("2a2238"))
	Px.line(img, Vector2i(14, 31), Vector2i(14, 50), Color("15111e"))
	# Hood and the dark inside it.
	Px.ellipse(img, 14.0, 10.0 + b, 6.0, 7.0, Color("221c30"))
	Px.ellipse(img, 15.0, 11.0 + b, 3.6, 4.4, P.INK)
	_light(img)
	# Cables over the shoulder, and the visor.
	for i: int in range(4):
		Px.dot(img, 10 + (i % 2), 17 + i * 4 + bi, P.MAGENTA_DIM)
	Px.rect(img, 13, 10 + bi, 5, 1, P.MAGENTA)
	Px.dot(img, 12, 10 + bi, P.MAGENTA_DIM)
	return img


static func _light(img: Image) -> void:
	Px.rim(img, P.INK, Color(P.MAGENTA, 0.42), Color(P.CYAN, 0.36), Color(P.AMBER, 0.28))
