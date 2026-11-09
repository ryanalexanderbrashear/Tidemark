class_name StallArt
extends RefCounted
## Draws the inside of Ines Vale's stall for the art test: one screen, the
## shutter sealed behind the detective, racks of recall along the back wall,
## her ledger on the counter, her body on the planks, and the scorch where
## something burned hot. The second room of the slice (sample case doc: the
## stall is the crime scene). Placeholder art drawn in code, like the market.
##
## The only blood in the room is hers, around her head.

const P = preload("res://game/art/art_palette.gd")

const SIZE: Vector2i = Vector2i(640, 360)
const WALK_Y: int = MarketArt.WALK_Y
## Where things stand (centre x, native pixels). ArtMarketFloor puts the
## case's stall spots here.
const EXIT_X: float = 34.0
const LEDGER_X: float = 206.0
const BODY_X: float = 372.0
const SAMPLE_X: float = 540.0
## The body sprite's size; it's its own sprite so the thermal optic can show
## what heat is left in it.
const BODY_SIZE: Vector2i = Vector2i(80, 22)
## The dying tube in the roof, and where its light falls.
const LAMP_X: int = 330


## The wall behind everything: the stall's back, under its tarp roof.
static func back() -> Image:
	var img: Image = Px.blank(SIZE.x, SIZE.y)
	Px.vgrad(img, 0, 0, SIZE.x, SIZE.y, P.INK, Color("0d121b"), 4)
	return img


## The stall's room: walls, racks, counter, floor. The body is separate.
static func room() -> Image:
	var img: Image = Px.blank(SIZE.x, SIZE.y)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2214
	# Roof: tarp sagging between joists, dripping.
	Px.rect(img, 0, 0, SIZE.x, 48, Color("0b0f16"))
	for jx: int in range(0, SIZE.x, 80):
		Px.rect(img, jx, 0, 6, 52, Color("070a10"))
	Px.cable(img, Vector2i(0, 46), Vector2i(SIZE.x, 46), 10, Color("1a1d26"))
	# Back wall: corrugated sheet, ribbed, stained where the water gets in.
	Px.rect(img, 0, 52, SIZE.x, WALK_Y - 52, Color("141a24"))
	for cx: int in range(2, SIZE.x, 5):
		Px.rect(img, cx, 54, 1, WALK_Y - 56, Color("19202c"))
	for i: int in range(14):
		var sx: int = rng.randi_range(60, SIZE.x - 20)
		Px.rect(img, sx, 56, rng.randi_range(2, 5), rng.randi_range(40, 140), Color("10151e"))
	# The shutter, seen from inside: sealed, light from the market leaking
	# under it.
	Px.rect(img, 0, 60, 62, WALK_Y - 60, Color("222934"))
	for sy: int in range(62, WALK_Y, 4):
		Px.rect(img, 0, sy, 62, 1, Color("181d26"))
	Px.rect(img, 31, 60, 1, WALK_Y - 60, Color("3a4556"))
	Px.rect(img, 0, WALK_Y - 2, 62, 2, P.AMBER_DIM)
	Px.glow(img, 31, WALK_Y, 50, 10, P.AMBER, 0.25)
	Px.rect(img, 62, 58, 4, WALK_Y - 58, Color("0b0f16"))
	# Racks of recall along the back wall, some knocked off.
	for ry: int in range(96, 216, 20):
		Px.rect(img, 80, ry, 500, 2, Color("232c3a"))
		Px.rect(img, 80, ry + 2, 500, 1, Color("0c1018"))
		var x: int = 84
		while x < 574:
			if rng.randf() < 0.78:
				var w: int = rng.randi_range(3, 7)
				var c: Color = [P.STEEL, Color("2a3442"), Color("3a3040"), P.CYAN_DIM][rng.randi_range(0, 3)]
				Px.rect(img, x, ry - 6, w, 6, c)
				if rng.randf() < 0.25:
					Px.dot(img, x + 1, ry - 5, P.CYAN)
				x += w + 1
			else:
				x += rng.randi_range(6, 18)
	for i: int in range(9):
		var fx: int = rng.randi_range(260, 600)
		Px.rect(img, fx, WALK_Y - 3, rng.randi_range(3, 6), 3, [P.STEEL, P.CYAN_DIM, Color("3a3040")][rng.randi_range(0, 2)])
	# Her reading rig: a chair with its headset hanging, cable to the rack.
	Px.rect(img, 452, WALK_Y - 52, 26, 6, Color("1b2230"))
	Px.rect(img, 474, WALK_Y - 86, 6, 40, Color("1b2230"))
	Px.rect(img, 456, WALK_Y - 46, 3, 46, Color("10151e"))
	Px.rect(img, 472, WALK_Y - 46, 3, 46, Color("10151e"))
	Px.cable(img, Vector2i(478, WALK_Y - 84), Vector2i(560, 150), 30, Color("0a0d14"))
	Px.ellipse(img, 470, WALK_Y - 40, 6, 3, Color("2a3442"))
	Px.dot(img, 468, WALK_Y - 41, P.CYAN_DIM)
	# Counter, with the ledger open under the lamp.
	var cy: int = WALK_Y - MarketArt.COUNTER_H
	Px.rect(img, 150, cy, 116, 4, Color("2a3442"))
	Px.rect(img, 154, cy + 4, 108, WALK_Y - cy - 4, Color("161c27"))
	Px.rect(img, 154, cy + 4, 108, 1, Color("0c1018"))
	var lx: int = int(LEDGER_X) - 12
	Px.rect(img, lx, cy - 3, 24, 3, Color("6f6c62"))
	Px.rect(img, lx + 11, cy - 4, 2, 4, Color("3a3830"))
	for row: int in range(2):
		Px.rect(img, lx + 2, cy - 2 + row, 8, 1, Color("3a3830"))
		Px.rect(img, lx + 14, cy - 2 + row, 8, 1, Color("3a3830"))
	Px.glow(img, LEDGER_X, cy - 2.0, 30, 10, P.AMBER, 0.2)
	# Scorch: something burned hot here, up the wall and across the planks.
	for i: int in range(260):
		var a: float = rng.randf() * TAU
		var r: float = pow(rng.randf(), 0.7)
		var sx: int = int(SAMPLE_X + cos(a) * r * 40.0)
		var sy: int = int(WALK_Y - 30 + sin(a) * r * 34.0)
		Px.dot(img, sx, mini(sy, WALK_Y + 3), Color("07080b") if r < 0.6 else Color(P.RUST, 0.7))
	for i: int in range(10):
		Px.dot(img, int(SAMPLE_X) + rng.randi_range(-22, 22), WALK_Y - rng.randi_range(2, 40), P.AMBER_DIM)
	# Floor: wet planks, the water lying in the dips.
	Px.rect(img, 0, WALK_Y, SIZE.x, SIZE.y - WALK_Y, Color("0b1019"))
	Px.rect(img, 0, WALK_Y, SIZE.x, 6, Color("1a2230"))
	Px.rect(img, 0, WALK_Y, SIZE.x, 1, Color("3a4658"))
	for px: int in range(0, SIZE.x, 22):
		Px.rect(img, px, WALK_Y + 1, 1, 5, Color("10161f"))
	for i: int in range(40):
		Px.rect(img, rng.randi_range(0, SIZE.x), WALK_Y + rng.randi_range(1, 4), rng.randi_range(3, 8), 1, Color(P.AMBER, 0.3) if rng.randf() < 0.5 else Color(P.RAIN, 0.25))
	Px.rect(img, 0, WALK_Y + 10, SIZE.x, SIZE.y - WALK_Y - 10, P.NIGHT)
	# Evidence markers round the body.
	for m: Array in [[BODY_X - 54.0, "1"], [BODY_X + 2.0, "2"], [BODY_X + 52.0, "3"], [SAMPLE_X - 28.0, "4"]]:
		var mx: int = int(m[0])
		Px.poly(img, PackedVector2Array([Vector2(mx, WALK_Y), Vector2(mx + 8, WALK_Y), Vector2(mx + 4, WALK_Y - 9)]), P.AMBER)
		Px.text(img, mx + 3, WALK_Y - 6, m[1], P.INK)
	# The lamp fixture (its light is drawn on its own, so it can stutter).
	Px.rect(img, LAMP_X - 10, 50, 20, 3, Color("1a1a1a"))
	Px.rect(img, LAMP_X - 8, 53, 16, 1, P.AMBER)
	return img


## The lamp's light on its own, to stutter like the one outside.
static func lamp() -> Image:
	var img: Image = Px.blank(SIZE.x, SIZE.y)
	Px.glow(img, LAMP_X, 90, 150, 70, P.AMBER, 0.16)
	Px.glow(img, LAMP_X, WALK_Y, 120, 14, P.AMBER, 0.2)
	return img


## Ines Vale on the planks, face down, an arm out. The blood is hers.
static func body() -> Image:
	var img: Image = Px.blank(BODY_SIZE.x, BODY_SIZE.y)
	var floor_y: int = BODY_SIZE.y - 3
	# Blood first, under her head and spreading along the boards.
	Px.ellipse(img, 14, floor_y + 1, 13, 3, P.BLOOD)
	Px.rect(img, 2, floor_y + 1, 30, 1, P.BLOOD)
	Px.rect(img, 26, floor_y + 2, 10, 1, Color(P.BLOOD, 0.7))
	# Legs, coat, back.
	Px.rect(img, 50, floor_y - 3, 20, 3, Color("1c222c"))
	Px.rect(img, 68, floor_y - 3, 5, 3, Color("080b12"))
	Px.poly(img, PackedVector2Array([Vector2(20, floor_y - 6), Vector2(50, floor_y - 7), Vector2(53, floor_y), Vector2(18, floor_y)]), Color("2b2a33"))
	Px.rect(img, 22, floor_y - 7, 28, 1, Color("3a3946"))
	# Hair, wet, fanned on the boards.
	Px.ellipse(img, 15, floor_y - 3, 7, 4, Color("120f14"))
	for i: int in range(5):
		Px.rect(img, 3 + i * 3, floor_y - 1, 2, 2, Color("120f14"))
	# The arm reaching out, the chip in her hand.
	Px.rect(img, 28, floor_y - 2, 1, 2, P.SKIN_SHADE)
	Px.line(img, Vector2i(30, floor_y - 1), Vector2i(46, floor_y + 1), P.SKIN_SHADE)
	Px.rect(img, 46, floor_y, 3, 2, P.SKIN)
	Px.rect(img, 49, floor_y, 4, 2, P.STEEL)
	Px.dot(img, 50, floor_y, P.CYAN_DIM)
	Px.rim(img, P.INK, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(P.AMBER, 0.3))
	return img
