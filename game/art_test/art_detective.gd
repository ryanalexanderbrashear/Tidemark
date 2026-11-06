class_name ArtDetective
extends RefCounted
## The detective, closer to final: the "rain-worn tracer" look Alex picked on
## 2026-11-06. An open storm coat to the knee, no hat, short dark hair and
## stubble. His three implants show: a steel plate round the eye with a cyan
## iris (the one bright point on him), the reading port behind the ear, and
## steel braces down the shins below the coat. About 64 px tall at 640x360.
##
## Drawn in code like the rest of the art test: a two-bone leg rig for an
## 8-frame walk that keeps his feet planted, a hand-placed head, and the
## market's light (sodium from above, magenta and cyan neon from behind).
## Faces right; the scene flips him.

const P = preload("res://game/art_test/art_palette.gd")

const SIZE: Vector2i = Vector2i(40, 68)
const WALK_FRAMES: int = 8
const IDLE_FRAMES: int = 4
## How far his body moves in one walk cycle, in pixels, so each walk frame can
## be picked by distance and the planted foot doesn't slide.
const STRIDE: float = 36.0

const HIP_Y: float = 37.0
const ANKLE_Y: float = 63.0
const THIGH: float = 13.5
const SHIN: float = 13.5
const CX: float = 20.0
const HEM_Y: float = 51.0

const COAT: Color = Color("232b38")
const COAT_LIT: Color = Color("323c4e")
const COAT_SHADE: Color = Color("171d28")
const COAT_DEEP: Color = Color("0e131b")
const LINING: Color = Color("2c1e22")
const SWEATER: Color = Color("2f2d30")
const SWEATER_SHADE: Color = Color("1f1e22")
const PANTS: Color = Color("1a1f29")
const PANTS_FAR: Color = Color("10141b")
const BOOT: Color = Color("0a0c11")
const BOOT_LIT: Color = Color("262a33")
const BRACE: Color = Color("4b5868")
const BRACE_LIT: Color = Color("7d8a99")
const BRACE_SHADE: Color = Color("2b3440")
const HAIR: Color = Color("12151c")
const HAIR_LIT: Color = Color("272c36")
const SKIN_LIT: Color = Color("b8927d")
const SKIN: Color = Color("94725f")
const SKIN_SHADE: Color = Color("634c44")
const SKIN_DEEP: Color = Color("3e3033")
const STUBBLE: Color = Color("6e5853")
const PLATE: Color = Color("6a7686")
const PLATE_LIT: Color = Color("a3afbd")

## The head in profile, facing right, one character per pixel. Its top-left
## sits at HEAD_AT plus the body's bob and lean.
const HEAD: Array[String] = [
	"......ooooo...",
	"...oooHHHHHo..",
	"..ohhhhhhhHHo.",
	".ohhhhhhhhhhko",
	"oqhhhhhhhhsskr",
	"oqhhhhsmMMbbkr",
	"oqffeSsmmcSskr",
	"oqffedssmCsskkr",
	"oqffeSssssssSSo",
	"oplSSsszzzsZsr",
	".oSSSszzzzzsr.",
	"..oSSzzzzzsro.",
	"...ooSSSSSoo..",
]
const HEAD_AT: Vector2i = Vector2i(13, 1)
## The head carries its own light: the lamps on top of the hair, magenta on the
## back of the skull, cyan along the face, so the face stays readable. Hair is
## short at the back and sides (f), longer on top.
const HEAD_KEY: Dictionary[String, Color] = {
	"o": Color("05080f"), "h": HAIR, "H": HAIR_LIT, "f": Color("2b2428"), "q": Color("4d2238"),
	"k": SKIN_LIT, "s": SKIN, "S": SKIN_SHADE, "e": SKIN_SHADE, "d": SKIN_DEEP,
	"z": STUBBLE, "Z": Color("3e3033"), "b": Color("2a2224"), "m": PLATE, "M": PLATE_LIT,
	"c": P.CYAN, "C": Color("1b6f84"), "r": Color("7fa9b0"), "p": BRACE_SHADE, "l": Color("1b6f84"),
}
## Where the iris is in HEAD, so it can be redrawn bright last.
const IRIS: Vector2i = Vector2i(9, 6)


## One walk frame (0..7). Frame 0 has the far foot planted forward.
static func walk(frame: int) -> Image:
	var f: int = posmod(frame, WALK_FRAMES)
	# Lowest just after each contact, highest as the legs pass.
	var bob: int = [1, 1, 0, 0, 1, 1, 0, 0][f]
	# The near arm swings against the near leg, so it is forward with the far leg.
	var arm: float = cos(TAU * float(f) / float(WALK_FRAMES))
	return _draw(bob, 1, _foot(f), _foot(f + 4), arm, 0, true)


## One idle frame (0..3): standing, weight on the back foot, a slow breath.
static func idle(frame: int) -> Image:
	var f: int = posmod(frame, IDLE_FRAMES)
	var breath: int = [0, 0, 1, 1][f]
	var far: Array = [Vector2(CX - 2.0, ANKLE_Y), 0.0]
	var near: Array = [Vector2(CX + 2.5, ANKLE_Y), 0.0]
	return _draw(0, 0, far, near, -0.1, breath, false)


## Where one foot is at walk frame `f`: [ankle, heel lift]. Planted for half the
## cycle, sliding back at the body's speed; swung forward for the other half.
static func _foot(f: int) -> Array:
	var i: int = posmod(f, WALK_FRAMES)
	var reach: float = STRIDE * 0.25
	if i <= 4:
		var x: float = lerpf(reach, -reach, float(i) / 4.0)
		var heel: float = 2.0 if i == 4 else 0.0
		return [Vector2(CX + x, ANKLE_Y), heel]
	var swing: Array = [[-5.0, 3.0, 2.0], [0.0, 5.0, 0.0], [6.0, 2.0, -1.0]]
	var s: Array = swing[i - 5]
	return [Vector2(CX + float(s[0]), ANKLE_Y - float(s[1])), float(s[2])]


static func _draw(bob: int, lean: int, far: Array, near: Array, arm: float, breath: int, walking: bool) -> Image:
	var img: Image = Px.blank(SIZE.x, SIZE.y)
	var hip: Vector2 = Vector2(CX, HIP_Y + bob)
	_far_arm(img, bob, lean, arm, walking)
	var far_knee: Vector2 = _leg(img, hip + Vector2(-1.5, 0), far, PANTS_FAR, true, walking)
	var near_knee: Vector2 = _leg(img, hip + Vector2(1.5, 0), near, PANTS, false, walking)
	_coat(img, bob, lean, far_knee, near_knee, breath, walking)
	_near_arm(img, bob - breath, lean, arm, not walking)
	_light(img)
	_head(img, bob - breath, lean)
	_collar(img, bob - breath, lean)
	return img


## A leg from hip to ankle, bending at the knee, with the boot and the steel
## brace down the front of the shin. Returns the knee, for the coat's hem.
static func _leg(img: Image, hip: Vector2, foot: Array, c: Color, is_far: bool, bend: bool) -> Vector2:
	var ankle: Vector2 = foot[0]
	var heel: float = foot[1]
	# Standing, the knees lock; walking, they bend forward.
	var knee: Vector2 = _knee(hip, ankle) if bend else (hip + ankle) * 0.5 + Vector2(0.5, 0)
	_limb(img, hip, knee, 2.7, 2.2, c)
	_limb(img, knee, ankle, 2.2, 1.6, c)
	# Brace: a plate along the shin's front edge and a cap over the knee.
	var steel: Color = BRACE_SHADE if is_far else BRACE
	var lit: Color = BRACE if is_far else BRACE_LIT
	var shin: Vector2 = ankle - knee
	var n: int = maxi(roundi(shin.length()), 1)
	for i: int in range(1, n - 1):
		var p: Vector2 = knee + shin * (float(i) / float(n)) + Vector2(1.2, 0)
		Px.dot(img, roundi(p.x), roundi(p.y), lit if i % 5 == 2 else steel)
		Px.dot(img, roundi(p.x) - 1, roundi(p.y), BRACE_SHADE)
	Px.rect(img, roundi(knee.x), roundi(knee.y) - 1, 2, 3, steel)
	Px.dot(img, roundi(knee.x) + 1, roundi(knee.y) - 1, lit)
	_boot(img, ankle, heel, is_far)
	return knee


## Two-bone knee: the knee bends forward (to the right), as knees do.
static func _knee(hip: Vector2, ankle: Vector2) -> Vector2:
	var d: Vector2 = ankle - hip
	var dist: float = d.length()
	var mid: Vector2 = hip + d * 0.5
	if dist >= THIGH + SHIN:
		return mid
	var h: float = sqrt(maxf(THIGH * THIGH - dist * dist * 0.25, 0.0))
	var side: Vector2 = Vector2(-d.y, d.x).normalized()
	if side.x < 0.0:
		side = -side
	return mid + side * h


static func _limb(img: Image, a: Vector2, b: Vector2, wa: float, wb: float, c: Color) -> void:
	var d: Vector2 = b - a
	var perp: Vector2 = Vector2(-d.y, d.x).normalized()
	Px.poly(img, PackedVector2Array([a + perp * wa, a - perp * wa, b - perp * wb, b + perp * wb]), c)
	Px.ellipse(img, b.x, b.y, wb, wb, c)


## A low boot. `heel` > 0 lifts the heel (toe-off); < 0 lifts the toe (reaching).
static func _boot(img: Image, ankle: Vector2, heel: float, is_far: bool) -> void:
	var sole_y: float = ankle.y + 3.0
	var back: Vector2 = Vector2(ankle.x - 2.0, sole_y - maxf(heel, 0.0))
	var toe: Vector2 = Vector2(ankle.x + 5.0, sole_y - maxf(-heel, 0.0))
	Px.poly(img, PackedVector2Array([
		Vector2(ankle.x - 2.0, ankle.y - 1.0), Vector2(ankle.x + 2.0, ankle.y - 1.0),
		Vector2(ankle.x + 2.5, ankle.y + 0.5), toe + Vector2(0, -2.0), toe, back]), BOOT)
	if not is_far:
		Px.line(img, Vector2i(roundi(ankle.x) + 1, roundi(ankle.y)), Vector2i(roundi(toe.x) - 1, roundi(toe.y) - 2), BOOT_LIT)


static func _coat(img: Image, bob: int, lean: int, far_knee: Vector2, near_knee: Vector2, breath: int, walking: bool) -> void:
	var b: float = float(bob)
	var l: float = float(lean)
	var top: float = 15.0 + b - float(breath)
	var lead: float = maxf(far_knee.x, near_knee.x)
	var trail: float = minf(far_knee.x, near_knee.x)
	var front_x: float = maxf(lead + 3.0, 27.5)
	var back_x: float = minf(trail - 3.5, 11.0) - (1.5 if walking else 0.0)
	var hem: float = HEM_Y + b
	var belt: float = 30.0 + b
	Px.poly(img, PackedVector2Array([
		Vector2(14 + l, top - 0.5), Vector2(24 + l, top), Vector2(26.5 + l, top + 2),
		Vector2(27.5 + l, top + 8), Vector2(26.5 + l * 0.5, belt), Vector2(27 + l * 0.5, belt + 3),
		Vector2(front_x, hem), Vector2(front_x - 1.0, hem + 1.0), Vector2(back_x + 1.0, hem + 2.0),
		Vector2(back_x, hem + 1.0), Vector2(11, belt + 9), Vector2(12.5, belt + 2), Vector2(12.5, belt),
		Vector2(11 + l, top + 6), Vector2(11.5 + l, top + 2)]), COAT)
	# The back of the coat, away from the lamps.
	Px.poly(img, PackedVector2Array([
		Vector2(11.5 + l, top + 2), Vector2(15 + l, top), Vector2(15.5, belt), Vector2(16.5, hem + 1),
		Vector2(back_x + 1.0, hem + 2.0), Vector2(back_x, hem + 1.0), Vector2(11, belt + 9),
		Vector2(12.5, belt + 2), Vector2(12.5, belt), Vector2(11 + l, top + 6)]), COAT_SHADE)
	# Open front: the sweater between the lapel and the front edge, down to the belt.
	Px.poly(img, PackedVector2Array([
		Vector2(24 + l, top + 1), Vector2(26.5 + l, top + 2.5), Vector2(27.5 + l, top + 8),
		Vector2(26.5 + l * 0.5, belt), Vector2(25 + l * 0.5, belt), Vector2(24.5 + l, top + 7)]), SWEATER)
	Px.line(img, Vector2i(roundi(26 + l), roundi(top + 9)), Vector2i(roundi(26 + l * 0.5), roundi(belt - 1)), SWEATER_SHADE)
	Px.line(img, Vector2i(roundi(24 + l), roundi(top + 1)), Vector2i(roundi(24.5 + l * 0.5), roundi(belt - 1)), COAT_LIT)
	# Below the belt the coat parts over the leading knee: its edge catches the
	# light and, when walking, a sliver of lining shows.
	var split: Vector2i = Vector2i(roundi(26 + l * 0.5), roundi(belt + 3))
	if walking:
		Px.poly(img, PackedVector2Array([Vector2(split) + Vector2(0, 4), Vector2(front_x - 0.5, hem - 0.5), Vector2(front_x - 2.0, hem)]), LINING)
	Px.line(img, split, Vector2i(roundi(front_x - 2.0), roundi(hem)), COAT_LIT)
	# Folds that hang from the belt toward each knee.
	Px.line(img, Vector2i(19, roundi(belt + 5)), Vector2i(roundi(trail + 1.0), roundi(hem)), COAT_SHADE)
	Px.line(img, Vector2i(22, roundi(belt + 7)), Vector2i(roundi(lead - 1.0), roundi(hem)), COAT_SHADE)
	Px.line(img, Vector2i(17, roundi(top + 3)), Vector2i(17, roundi(belt - 1)), COAT_DEEP)
	# Belt with its buckle, and the loose tail at the back.
	Px.rect(img, 12, roundi(belt), 15, 2, COAT_DEEP)
	Px.rect(img, 21, roundi(belt), 2, 2, BRACE_SHADE)
	Px.line(img, Vector2i(12, roundi(belt + 1)), Vector2i(11 - (1 if walking else 0), roundi(belt + 7)), COAT_DEEP)
	# Shoulders take the sodium light from above.
	Px.rect(img, roundi(15 + l), roundi(top), 9, 1, COAT_LIT)


## The turned-up collar, drawn over the back of the neck and jaw.
static func _collar(img: Image, bob: int, lean: int) -> void:
	var top: float = 15.0 + float(bob)
	var l: float = float(lean)
	Px.poly(img, PackedVector2Array([
		Vector2(13 + l, top + 1.5), Vector2(14 + l, top - 2.5), Vector2(17 + l, top - 1.5),
		Vector2(19 + l, top + 1)]), COAT_SHADE)
	Px.line(img, Vector2i(roundi(14 + l), roundi(top - 2.5)), Vector2i(roundi(16.5 + l), roundi(top - 1.5)), COAT_LIT)
	Px.dot(img, roundi(13 + l), roundi(top - 1), Color(P.MAGENTA, 0.5))
	Px.dot(img, roundi(13 + l), roundi(top), Color(P.MAGENTA, 0.5))
	Px.poly(img, PackedVector2Array([
		Vector2(22.5 + l, top - 1), Vector2(24.5 + l, top - 0.5), Vector2(25.5 + l, top + 3), Vector2(23 + l, top + 2)]), COAT_LIT)


static func _head(img: Image, bob: int, lean: int) -> void:
	var at: Vector2i = HEAD_AT + Vector2i(lean, bob)
	# Neck, under the collar.
	Px.rect(img, at.x + 5, at.y + 12, 5, 3, SKIN_SHADE)
	Px.rect(img, at.x + 8, at.y + 12, 2, 2, SKIN)
	Px.dot(img, at.x + 10, at.y + 12, SKIN_SHADE)
	for y: int in range(HEAD.size()):
		var row: String = HEAD[y]
		for x: int in range(row.length()):
			var ch: String = row[x]
			if HEAD_KEY.has(ch):
				Px.dot(img, at.x + x, at.y + y, HEAD_KEY[ch])


static func _arm(img: Image, sh: Vector2, swing: float, bend: float, c: Color) -> Vector2:
	var elbow: Vector2 = sh + Vector2(sin(swing), cos(swing)) * 10.0
	var hand: Vector2 = elbow + Vector2(sin(swing + bend), cos(swing + bend)) * 8.5
	_limb(img, sh, elbow, 2.4, 2.0, c)
	_limb(img, elbow, hand, 2.0, 1.6, c)
	return hand


static func _far_arm(img: Image, bob: int, lean: int, arm: float, walking: bool) -> void:
	if not walking:
		return
	var hand: Vector2 = _arm(img, Vector2(18 + lean, 18 + bob), -arm * 0.35, maxf(-arm, 0.0) * 0.4 + 0.1, COAT_DEEP)
	Px.rect(img, roundi(hand.x) - 1, roundi(hand.y) + 1, 2, 2, SKIN_DEEP)


## The near arm. Standing, his hand is in the coat pocket.
static func _near_arm(img: Image, bob: int, lean: int, arm: float, pocket: bool) -> void:
	var sh: Vector2 = Vector2(20 + lean, 17 + bob)
	var swing: float = -0.12 if pocket else arm * 0.35
	var bend: float = 0.75 if pocket else maxf(arm, 0.0) * 0.4 + 0.1
	var elbow: Vector2 = sh + Vector2(sin(swing), cos(swing)) * 10.0
	# A dark seam first, so the sleeve separates from the coat behind it.
	_arm(img, sh + Vector2(-1, 0), swing, bend, COAT_DEEP)
	var hand: Vector2 = _arm(img, sh, swing, bend, COAT)
	# Light along the sleeve's front and top.
	Px.line(img, Vector2i(roundi(sh.x) + 1, roundi(sh.y) - 1), Vector2i(roundi(elbow.x) + 2, roundi(elbow.y)), COAT_LIT)
	Px.rect(img, roundi(sh.x) - 1, roundi(sh.y) - 2, 3, 1, COAT_LIT)
	var hx: int = roundi(hand.x)
	var hy: int = roundi(hand.y)
	if pocket:
		# The wrist disappears into the pocket's slit.
		Px.line(img, Vector2i(hx - 1, hy - 2), Vector2i(hx + 2, hy + 1), COAT_DEEP)
		Px.dot(img, hx + 2, hy, COAT_LIT)
		return
	# Cuff and a bare hand.
	Px.rect(img, hx - 2, hy - 1, 4, 1, COAT_SHADE)
	Px.rect(img, hx - 1, hy, 3, 3, SKIN)
	Px.dot(img, hx + 1, hy, SKIN_LIT)
	Px.dot(img, hx - 1, hy + 2, SKIN_SHADE)
	Px.dot(img, hx, hy + 3, SKIN_SHADE)


## Edge light for the body: an ink outline, neon from behind and sodium from
## above. Softer below the coat, where thin legs would drown in rim light.
static func _light(img: Image) -> void:
	var src: Image = img.duplicate() as Image
	for y: int in range(img.get_height()):
		var soft: bool = y > int(HEM_Y) + 1
		var left: Color = Color(P.MAGENTA, 0.16 if soft else 0.4)
		var right: Color = Color(P.CYAN, 0.18 if soft else 0.34)
		for x: int in range(img.get_width()):
			if not Px.is_solid(src, x, y):
				continue
			var open_l: bool = not Px.is_solid(src, x - 1, y)
			var open_r: bool = not Px.is_solid(src, x + 1, y)
			var open_t: bool = not Px.is_solid(src, x, y - 1)
			var open_b: bool = not Px.is_solid(src, x, y + 1)
			if open_l or open_r or open_t or open_b:
				img.set_pixel(x, y, P.INK)
			if open_r:
				Px.dot(img, x - 1, y, right)
			if open_l:
				Px.dot(img, x + 1, y, left)
			if open_t and not soft:
				Px.dot(img, x, y + 1, Color(P.AMBER, 0.14))
