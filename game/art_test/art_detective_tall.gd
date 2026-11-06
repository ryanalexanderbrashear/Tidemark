class_name ArtDetectiveTall
extends RefCounted
## A style draft of the same detective (the rain-worn tracer), pushed toward the
## look Alex likes in Replaced: taller and leaner with realistic proportions
## (about 6.5 heads, ~86 px at 640x360) and no ink outline. A first try at
## 8 heads made his head look too small (Alex, 2026-11-06), so it's larger now. He
## reads as a near-silhouette carved out by light: a hard cool rim from the neon
## behind him, warm sodium light on his top edges and profile, and the body
## falling off into shadow toward the feet. Only the cyan iris is bright.
##
## Same rig as ArtDetective (two-bone legs, walk frames picked by distance), at
## the larger size. Faces right; the scene flips him.

const P = preload("res://game/art_test/art_palette.gd")

const SIZE: Vector2i = Vector2i(48, 91)
const WALK_FRAMES: int = 8
const IDLE_FRAMES: int = 4
## Distance his body moves in one walk cycle, so planted feet don't slide.
const STRIDE: float = 48.0

const CX: float = 22.0
const SHOULDER_Y: float = 18.0
const BELT_Y: float = 40.0
const HIP_Y: float = 47.0
const ANKLE_Y: float = 85.0
const THIGH: float = 19.5
const SHIN: float = 19.5
const HEM_Y: float = 69.0

const COAT: Color = Color("1c2230")
const COAT_LIT: Color = Color("2b3446")
const COAT_SHADE: Color = Color("121722")
const COAT_DEEP: Color = Color("0a0e15")
const SWEATER: Color = Color("24232a")
const PANTS: Color = Color("141924")
const PANTS_FAR: Color = Color("0c1018")
const BOOT: Color = Color("080a0f")
const BRACE: Color = Color("3a4655")
const BRACE_LIT: Color = Color("8a97a6")
const SKIN: Color = Color("6e5650")
const SKIN_SHADE: Color = Color("47383a")
const HAIR: Color = Color("0d1017")
## The two lights that shape him.
const RIM: Color = Color("a6dde6")     # neon behind him, cool and hard
const WARM: Color = Color("e0a768")    # sodium lamps above and ahead

## The head in profile, facing right. Mostly shadow: the profile line carries
## the warm light (w), the back of the skull the cool rim (r).
const HEAD: Array[String] = [
	"....rrrrh....",
	"..rrhhhhhhw..",
	".rhhhhhhhhhw.",
	"rhhhhhhhhhhhw",
	"rhhhhhhhhhssw",
	"rhhhhhhmmbbsw",
	"rhhhhSmmcSssw",
	"rhhheSSmSSsssw",
	"rhpeSSSSSSsssw",
	"rhheSSSSSSSsS.",
	".rSSSSSzzzsw..",
	"..rSSSzzzzw...",
	"...SSSSzzw....",
]
const HEAD_AT: Vector2i = Vector2i(17, 2)
const HEAD_KEY: Dictionary[String, Color] = {
	"h": HAIR, "s": SKIN, "S": SKIN_SHADE, "e": Color("2e2427"), "z": Color("3a2f32"),
	"b": Color("1c1619"), "m": Color("56626f"), "c": P.CYAN, "p": BRACE,
	"w": Color("c49373"), "r": Color("5e8c98"),
}
const IRIS: Vector2i = Vector2i(8, 6)


static func walk(frame: int) -> Image:
	var f: int = posmod(frame, WALK_FRAMES)
	var bob: int = [1, 1, 0, 0, 1, 1, 0, 0][f]
	var arm: float = cos(TAU * float(f) / float(WALK_FRAMES))
	return _draw(bob, 1, _foot(f), _foot(f + 4), arm, 0, true)


static func idle(frame: int) -> Image:
	var f: int = posmod(frame, IDLE_FRAMES)
	var breath: int = [0, 0, 1, 1][f]
	var far: Array = [Vector2(CX - 3.0, ANKLE_Y), 0.0]
	var near: Array = [Vector2(CX + 3.0, ANKLE_Y), 0.0]
	return _draw(0, 0, far, near, -0.1, breath, false)


## [ankle, heel lift] at walk frame `f`: planted and sliding back for half the
## cycle, swung forward for the other half.
static func _foot(f: int) -> Array:
	var i: int = posmod(f, WALK_FRAMES)
	var reach: float = STRIDE * 0.25
	if i <= 4:
		var heel: float = 3.0 if i == 4 else 0.0
		return [Vector2(CX + lerpf(reach, -reach, float(i) / 4.0), ANKLE_Y), heel]
	var swing: Array = [[-7.0, 4.0, 3.0], [0.0, 7.0, 0.0], [8.0, 3.0, -1.0]]
	var s: Array = swing[i - 5]
	return [Vector2(CX + float(s[0]), ANKLE_Y - float(s[1])), float(s[2])]


static func _draw(bob: int, lean: int, far: Array, near: Array, arm: float, breath: int, walking: bool) -> Image:
	var img: Image = Px.blank(SIZE.x, SIZE.y)
	var hip: Vector2 = Vector2(CX, HIP_Y + bob)
	_far_arm(img, bob, lean, arm, walking)
	var far_knee: Vector2 = _leg(img, hip + Vector2(-2, 0), far, PANTS_FAR, walking)
	var near_knee: Vector2 = _leg(img, hip + Vector2(2, 0), near, PANTS, walking)
	_coat(img, bob, lean, far_knee, near_knee, breath, walking)
	_near_arm(img, bob - breath, lean, arm, not walking)
	_head(img, bob - breath, lean)
	_light(img)
	var iris: Vector2i = HEAD_AT + IRIS + Vector2i(lean, bob - breath)
	img.set_pixelv(iris, P.CYAN)
	Px.dot(img, iris.x + 1, iris.y, Color(P.CYAN, 0.35))
	return img


static func _leg(img: Image, hip: Vector2, foot: Array, c: Color, bend: bool) -> Vector2:
	var ankle: Vector2 = foot[0]
	var knee: Vector2 = _knee(hip, ankle) if bend else (hip + ankle) * 0.5 + Vector2(0.7, 0)
	_limb(img, hip, knee, 3.4, 2.7, c)
	_limb(img, knee, ankle, 2.6, 1.9, c)
	# Shin brace: a thin plate down the front, catching a glint at the knee.
	var shin: Vector2 = ankle - knee
	var n: int = maxi(roundi(shin.length()), 1)
	for i: int in range(2, n - 2):
		var p: Vector2 = knee + shin * (float(i) / float(n)) + Vector2(1.6, 0)
		Px.dot(img, roundi(p.x), roundi(p.y), BRACE)
	Px.rect(img, roundi(knee.x) + 1, roundi(knee.y) - 1, 2, 3, BRACE)
	Px.dot(img, roundi(knee.x) + 2, roundi(knee.y) - 1, BRACE_LIT)
	_boot(img, ankle, foot[1])
	return knee


static func _knee(hip: Vector2, ankle: Vector2) -> Vector2:
	var d: Vector2 = ankle - hip
	var dist: float = d.length()
	var mid: Vector2 = hip + d * 0.5
	if dist >= THIGH + SHIN:
		return mid
	var side: Vector2 = Vector2(-d.y, d.x).normalized()
	if side.x < 0.0:
		side = -side
	return mid + side * sqrt(maxf(THIGH * THIGH - dist * dist * 0.25, 0.0))


static func _limb(img: Image, a: Vector2, b: Vector2, wa: float, wb: float, c: Color) -> void:
	var d: Vector2 = b - a
	var perp: Vector2 = Vector2(-d.y, d.x).normalized()
	Px.poly(img, PackedVector2Array([a + perp * wa, a - perp * wa, b - perp * wb, b + perp * wb]), c)
	Px.ellipse(img, b.x, b.y, wb, wb, c)


static func _boot(img: Image, ankle: Vector2, heel: float) -> void:
	var sole_y: float = ankle.y + 4.0
	var back: Vector2 = Vector2(ankle.x - 2.5, sole_y - maxf(heel, 0.0))
	var toe: Vector2 = Vector2(ankle.x + 6.5, sole_y - maxf(-heel, 0.0))
	Px.poly(img, PackedVector2Array([
		Vector2(ankle.x - 2.5, ankle.y - 1.0), Vector2(ankle.x + 2.5, ankle.y - 1.0),
		Vector2(ankle.x + 3.0, ankle.y + 1.0), toe + Vector2(0, -2.5), toe, back]), BOOT)


static func _coat(img: Image, bob: int, lean: int, far_knee: Vector2, near_knee: Vector2, breath: int, walking: bool) -> void:
	var b: float = float(bob)
	var l: float = float(lean)
	var top: float = SHOULDER_Y + b - float(breath)
	var belt: float = BELT_Y + b
	var lead: float = maxf(far_knee.x, near_knee.x)
	var trail: float = minf(far_knee.x, near_knee.x)
	var front_x: float = maxf(lead + 3.5, CX + 9.0)
	var back_x: float = minf(trail - 4.0, CX - 10.0) - (2.0 if walking else 0.0)
	var hem: float = HEM_Y + b
	Px.poly(img, PackedVector2Array([
		Vector2(CX - 6 + l, top - 0.5), Vector2(CX + 4 + l, top), Vector2(CX + 7 + l, top + 2.5),
		Vector2(CX + 8 + l, top + 11), Vector2(CX + 6.5 + l * 0.5, belt), Vector2(CX + 7 + l * 0.5, belt + 3),
		Vector2(front_x, hem), Vector2(front_x - 1.5, hem + 1.0), Vector2(back_x + 1.5, hem + 2.5),
		Vector2(back_x, hem + 1.5), Vector2(CX - 9.5, belt + 10), Vector2(CX - 7.5, belt + 2),
		Vector2(CX - 7.5, belt), Vector2(CX - 9 + l, top + 8), Vector2(CX - 8.5 + l, top + 2)]), COAT)
	# Shadow side and the fall-off toward the hem.
	Px.poly(img, PackedVector2Array([
		Vector2(CX - 8.5 + l, top + 2), Vector2(CX - 5 + l, top), Vector2(CX - 4.5, belt),
		Vector2(CX - 3, hem + 2), Vector2(back_x + 1.5, hem + 2.5), Vector2(back_x, hem + 1.5),
		Vector2(CX - 9.5, belt + 10), Vector2(CX - 7.5, belt + 2), Vector2(CX - 9 + l, top + 8)]), COAT_SHADE)
	# Open front over the sweater, the lapel's edge, the belt.
	Px.poly(img, PackedVector2Array([
		Vector2(CX + 4 + l, top + 1), Vector2(CX + 7 + l, top + 3), Vector2(CX + 8 + l, top + 11),
		Vector2(CX + 6.5 + l * 0.5, belt), Vector2(CX + 5 + l * 0.5, belt), Vector2(CX + 4.5 + l, top + 9)]), SWEATER)
	Px.line(img, Vector2i(roundi(CX + 4 + l), roundi(top + 1)), Vector2i(roundi(CX + 4.5 + l * 0.5), roundi(belt - 1)), COAT_LIT)
	Px.rect(img, roundi(CX - 7.5), roundi(belt), 15, 2, COAT_DEEP)
	Px.line(img, Vector2i(roundi(CX - 7.5), roundi(belt + 1)), Vector2i(roundi(CX - 9.0) - (1 if walking else 0), roundi(belt + 10)), COAT_DEEP)
	# The skirt parts over the leading knee; folds hang toward each knee.
	var split: Vector2i = Vector2i(roundi(CX + 6 + l * 0.5), roundi(belt + 3))
	Px.line(img, split, Vector2i(roundi(front_x - 2.0), roundi(hem)), COAT_LIT)
	Px.line(img, Vector2i(roundi(CX - 2), roundi(belt + 6)), Vector2i(roundi(trail), roundi(hem)), COAT_DEEP)
	Px.line(img, Vector2i(roundi(CX + 2), roundi(belt + 8)), Vector2i(roundi(lead - 1.0), roundi(hem)), COAT_SHADE)
	# Collar turned up behind the neck.
	Px.poly(img, PackedVector2Array([
		Vector2(CX - 7 + l, top + 1.5), Vector2(CX - 5.5 + l, top - 4), Vector2(CX - 2 + l, top - 3),
		Vector2(CX - 1 + l, top + 1)]), COAT_SHADE)
	Px.poly(img, PackedVector2Array([
		Vector2(CX + 3 + l, top - 1.5), Vector2(CX + 5.5 + l, top - 1), Vector2(CX + 6.5 + l, top + 3), Vector2(CX + 3.5 + l, top + 2)]), COAT_LIT)


static func _head(img: Image, bob: int, lean: int) -> void:
	var at: Vector2i = HEAD_AT + Vector2i(lean, bob)
	Px.rect(img, at.x + 3, at.y + 11, 6, 5, SKIN_SHADE)
	Px.dot(img, at.x + 8, at.y + 12, Color("c49373"))
	for y: int in range(HEAD.size()):
		var row: String = HEAD[y]
		for x: int in range(row.length()):
			var ch: String = row[x]
			if HEAD_KEY.has(ch):
				img.set_pixel(at.x + x, at.y + y, HEAD_KEY[ch])


static func _arm(img: Image, sh: Vector2, swing: float, bend: float, c: Color) -> Array[Vector2]:
	var elbow: Vector2 = sh + Vector2(sin(swing), cos(swing)) * 14.0
	var hand: Vector2 = elbow + Vector2(sin(swing + bend), cos(swing + bend)) * 12.0
	_limb(img, sh, elbow, 2.9, 2.4, c)
	_limb(img, elbow, hand, 2.4, 1.9, c)
	return [elbow, hand]


static func _far_arm(img: Image, bob: int, lean: int, arm: float, walking: bool) -> void:
	if walking:
		_arm(img, Vector2(CX - 3 + lean, SHOULDER_Y + 3 + bob), -arm * 0.3, maxf(-arm, 0.0) * 0.4 + 0.1, COAT_DEEP)


static func _near_arm(img: Image, bob: int, lean: int, arm: float, pocket: bool) -> void:
	var sh: Vector2 = Vector2(CX + lean, SHOULDER_Y + 2 + bob)
	var swing: float = -0.12 if pocket else arm * 0.3
	var bend: float = 0.7 if pocket else maxf(arm, 0.0) * 0.4 + 0.1
	_arm(img, sh + Vector2(-1.5, 0), swing, bend, COAT_DEEP)
	var joints: Array[Vector2] = _arm(img, sh, swing, bend, COAT)
	var elbow: Vector2 = joints[0]
	var hand: Vector2 = joints[1]
	# The sleeve's top catches the lamps.
	Px.line(img, Vector2i(roundi(sh.x) + 2, roundi(sh.y) - 1), Vector2i(roundi(elbow.x) + 2, roundi(elbow.y)), COAT_LIT)
	if pocket:
		Px.line(img, Vector2i(roundi(hand.x) - 1, roundi(hand.y) - 2), Vector2i(roundi(hand.x) + 3, roundi(hand.y) + 1), COAT_DEEP)
		return
	Px.rect(img, roundi(hand.x) - 1, roundi(hand.y), 3, 4, SKIN_SHADE)
	Px.dot(img, roundi(hand.x) + 1, roundi(hand.y) + 1, Color("c49373"))


## No outline. Edges facing the neon behind him (left) get a hard cool rim,
## edges facing up or ahead get the warm lamps, and everything else darkens
## toward his feet, away from the lamps.
static func _light(img: Image) -> void:
	var src: Image = img.duplicate() as Image
	var h: float = float(img.get_height())
	for y: int in range(img.get_height()):
		var fall: float = lerpf(1.08, 0.62, clampf((float(y) - 10.0) / (h - 10.0), 0.0, 1.0))
		for x: int in range(img.get_width()):
			if not Px.is_solid(src, x, y):
				continue
			var c: Color = src.get_pixel(x, y)
			if c == P.CYAN:
				continue
			c = Color(c.r * fall, c.g * fall, c.b * fall)
			var open_l: bool = not Px.is_solid(src, x - 1, y)
			var open_r: bool = not Px.is_solid(src, x + 1, y)
			var open_t: bool = not Px.is_solid(src, x, y - 1)
			if open_l:
				c = c.lerp(RIM, 0.62 if y < int(HEM_Y) else 0.38)
			elif not Px.is_solid(src, x - 2, y):
				c = c.lerp(RIM, 0.16)
			if open_t:
				c = c.lerp(WARM, 0.45)
			elif open_r and y < int(BELT_Y):
				c = c.lerp(WARM, 0.22)
			img.set_pixel(x, y, c)
