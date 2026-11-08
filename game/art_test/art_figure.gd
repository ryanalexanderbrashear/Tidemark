class_name ArtFigure
extends RefCounted
## A person drawn the way ArtDetectiveTall is: realistic proportions (about 6.5
## heads), no ink outline, a hard cool rim from the neon behind and warm sodium
## light on the top edges and profile, falling off into shadow toward the feet.
## The cast (ArtCast) is built on this one rig, so everyone shares the
## detective's scale and light and only their build, clothes, head and props
## differ.
##
## Everyone faces right; the scene flips them. Soles sit on the third row from
## the bottom, like every sprite in the art test.
##
## draw() can also hand back each part on its own layer (legs, body, head...),
## which is what the sprite exporter writes into Aseprite files.

const P = preload("res://game/art_test/art_palette.gd")

## Layers, back to front. Every pixel belongs to the last part drawn over it.
const PARTS: Array[String] = ["props back", "far arm", "legs", "body", "near arm", "head", "props", "lights"]

const RIM: Color = Color("a6dde6")
const WARM: Color = Color("e0a768")


## A character's build, clothes and head. Lengths are in pixels at 640x360.
class Build:
	var size: Vector2i = Vector2i(48, 91)
	var cx: float = 22.0
	var shoulder_y: float = 18.0
	var belt_y: float = 40.0
	var hip_y: float = 47.0
	var ankle_y: float = 85.0
	var thigh: float = 19.5
	var shin: float = 19.5
	var upper_arm: float = 14.0
	var forearm: float = 12.0
	## Distance the body moves in one walk cycle, so planted feet don't slide.
	var stride: float = 48.0
	## Half-widths of the torso: chest front and back at the shoulders, then at the belt.
	var chest_front: float = 8.0
	var chest_back: float = 9.0
	var waist_front: float = 6.5
	var waist_back: float = 7.5
	## Where the outer layer ends. Well below the hips it's a long coat whose
	## skirt parts over the knees; near the hips it's a jacket.
	var hem_y: float = 69.0
	var open_front: bool = true
	var belt: bool = true
	var collar: bool = true
	var leg_w: Array[float] = [3.4, 2.7, 2.6, 1.9]
	var arm_w: Array[float] = [2.9, 2.4, 1.9]
	## How tall the boot's heel is (0 for flat soles).
	var heel: float = 0.0

	var coat: Color = Color("1c2230")
	var coat_lit: Color = Color("2b3446")
	var coat_shade: Color = Color("121722")
	var coat_deep: Color = Color("0a0e15")
	var inner: Color = Color("24232a")
	var pants: Color = Color("141924")
	var pants_far: Color = Color("0c1018")
	var boot: Color = Color("080a0f")
	var skin: Color = Color("6e5650")
	var skin_shade: Color = Color("47383a")
	## Hands: skin, or gloves.
	var hand: Color = Color("47383a")
	var hand_lit: Color = Color("c49373")

	## The head in profile facing right, one character per pixel, keyed by `head_key`.
	var head: Array[String] = []
	var head_key: Dictionary[String, Color] = {}
	## Keys that glow (eyes, visors, lamps): drawn after the light, so they stay bright.
	var glow_keys: String = ""
	var head_at: Vector2i = Vector2i(17, 2)
	## The neck under the head: offset from head_at and size.
	var neck: Rect2i = Rect2i(3, 11, 6, 5)

	## Hooks for props, each called as hook(img, build, pose, joints):
	## behind everything, in front of the body, and after the light.
	var props_back: Callable = Callable()
	var props_front: Callable = Callable()
	var props_glow: Callable = Callable()
	## Called on the finished frame, for effects like a passenger coming apart.
	var finish: Callable = Callable()

	## Sets the body's heights from a stature (1.0 = the detective) on a canvas
	## of `canvas` with soles on its third row from the bottom.
	func proportion(canvas: Vector2i, stature: float, centre: float) -> void:
		size = canvas
		cx = centre
		var sole: float = float(canvas.y) - 2.0
		ankle_y = sole - 4.0
		hip_y = sole - 42.0 * stature
		belt_y = sole - 49.0 * stature
		shoulder_y = sole - 71.0 * stature
		thigh = 19.5 * stature
		shin = 19.5 * stature
		upper_arm = 14.0 * stature
		forearm = 12.0 * stature
		stride = 48.0 * stature
		hem_y = sole - 20.0 * stature
		head_at = Vector2i(roundi(centre) - 5, roundi(shoulder_y) - 16)


## One frame's pose. Positions are in canvas pixels.
class Pose:
	var bob: int = 0
	## Shoulders and head rise by this much on the in-breath.
	var breath: int = 0
	## Shoulders and head shift forward by this much (a hunch, a lean).
	var lean: int = 0
	## Lowers the hips (kneeling, crouching).
	var drop: float = 0.0
	var far_foot: Vector2 = Vector2.ZERO
	var near_foot: Vector2 = Vector2.ZERO
	var far_heel: float = 0.0
	var near_heel: float = 0.0
	## Which way each knee bends (forward, unless kneeling).
	var far_knee: Vector2 = Vector2(1, 0)
	var near_knee: Vector2 = Vector2(1, 0)
	## The far foot points back (kneeling on it).
	var far_toe_back: bool = false
	## Arms swing by angle (radians from hanging straight down, forward is
	## positive) and bend at the elbow...
	var far_swing: float = 0.0
	var far_bend: float = 0.2
	var near_swing: float = -0.12
	var near_bend: float = 0.7
	## ...unless a hand is pinned to a point (NAN: not pinned). The elbow then
	## bends toward `*_elbow` (a direction).
	var far_hand: Vector2 = Vector2(NAN, NAN)
	var near_hand: Vector2 = Vector2(NAN, NAN)
	var far_elbow: Vector2 = Vector2(-1, 0.4)
	var near_elbow: Vector2 = Vector2(-1, 0.4)
	## The near hand is in a pocket: no hand drawn, a pocket line instead.
	var pocket: bool = true
	var far_arm: bool = true
	var walking: bool = false
	## For props that animate (an LED chase, a wrench turning).
	var frame: int = 0


# ---------- poses ----------

static func idle_pose(b: Build, frame: int) -> Pose:
	var p: Pose = Pose.new()
	p.frame = frame
	p.breath = [0, 0, 1, 1][posmod(frame, 4)]
	p.far_foot = Vector2(b.cx - 3.0, b.ankle_y)
	p.near_foot = Vector2(b.cx + 3.0, b.ankle_y)
	p.far_arm = false
	p.near_swing = -0.12
	p.near_bend = 0.7
	p.pocket = true
	return p


static func walk_pose(b: Build, frame: int) -> Pose:
	var f: int = posmod(frame, 8)
	var p: Pose = Pose.new()
	p.frame = frame
	p.walking = true
	p.bob = [1, 1, 0, 0, 1, 1, 0, 0][f]
	var arm: float = cos(TAU * float(f) / 8.0)
	var far: Array = _foot(b, f)
	var near: Array = _foot(b, f + 4)
	p.far_foot = far[0]
	p.far_heel = far[1]
	p.near_foot = near[0]
	p.near_heel = near[1]
	p.far_swing = -arm * 0.3
	p.far_bend = maxf(-arm, 0.0) * 0.4 + 0.1
	p.near_swing = arm * 0.3
	p.near_bend = maxf(arm, 0.0) * 0.4 + 0.1
	p.pocket = false
	return p


## [ankle, heel lift] at walk frame `f`: planted and sliding back for half the
## cycle, swung forward for the other half (as ArtDetectiveTall walks).
static func _foot(b: Build, f: int) -> Array:
	var i: int = posmod(f, 8)
	var reach: float = b.stride * 0.25
	var k: float = b.stride / 48.0
	if i <= 4:
		var heel: float = 3.0 if i == 4 else 0.0
		return [Vector2(b.cx + lerpf(reach, -reach, float(i) / 4.0), b.ankle_y), heel]
	var swing: Array = [[-7.0, 4.0, 3.0], [0.0, 7.0, 0.0], [8.0, 3.0, -1.0]]
	var s: Array = swing[i - 5]
	return [Vector2(b.cx + float(s[0]) * k, b.ankle_y - float(s[1]) * k), float(s[2])]


# ---------- drawing ----------

## Draws one frame. If `layers` is given, it's filled with one image per part
## (PARTS), together making up the returned frame.
static func draw(b: Build, p: Pose, layers: Variant = null) -> Image:
	var img: Image = Px.blank(b.size.x, b.size.y)
	var split: bool = layers is Dictionary
	var owner: PackedByteArray = PackedByteArray()
	owner.resize(b.size.x * b.size.y)
	owner.fill(255)
	var j: Dictionary[String, Vector2] = _joints(b, p)
	var snap: Image = img.duplicate() as Image if split else null
	if b.props_back.is_valid():
		b.props_back.call(img, b, p, j)
	snap = _claim(img, snap, owner, 0)
	if p.far_arm:
		_arm(img, b, j["far_shoulder"], j["far_elbow"], j["far_hand"], b.coat_deep, b.coat_deep, false, false)
	snap = _claim(img, snap, owner, 1)
	var bend: bool = p.walking or p.drop > 0.0
	j["far_knee"] = _leg(img, b, j["hip"] + Vector2(-2, 0), p.far_foot, p.far_heel, b.pants_far, bend, p.far_knee, p.far_toe_back)
	j["near_knee"] = _leg(img, b, j["hip"] + Vector2(2, 0), p.near_foot, p.near_heel, b.pants, bend, p.near_knee, false)
	snap = _claim(img, snap, owner, 2)
	_torso(img, b, p, j)
	snap = _claim(img, snap, owner, 3)
	_arm(img, b, j["near_shoulder"], j["near_elbow"], j["near_hand"], b.coat, b.coat_lit, p.pocket, true)
	snap = _claim(img, snap, owner, 4)
	_head(img, b, j)
	snap = _claim(img, snap, owner, 5)
	if b.props_front.is_valid():
		b.props_front.call(img, b, p, j)
	_claim(img, snap, owner, 6)
	_light(img, b)
	snap = img.duplicate() as Image if split else null
	_head_glow(img, b, j)
	if b.props_glow.is_valid():
		b.props_glow.call(img, b, p, j)
	_claim(img, snap, owner, 7)
	if b.finish.is_valid():
		b.finish.call(img, b, p, j)
	if split:
		_split(img, owner, layers)
	return img


## Where the body's joints are this frame.
static func _joints(b: Build, p: Pose) -> Dictionary[String, Vector2]:
	var j: Dictionary[String, Vector2] = {}
	var up: float = float(p.bob - p.breath) + p.drop
	j["hip"] = Vector2(b.cx, b.hip_y + float(p.bob) + p.drop)
	j["top"] = Vector2(b.cx + float(p.lean), b.shoulder_y + up)
	j["head"] = Vector2(b.head_at) + Vector2(float(p.lean), up)
	j["near_shoulder"] = Vector2(b.cx + float(p.lean), b.shoulder_y + 2.0 + up)
	j["far_shoulder"] = Vector2(b.cx - 3.0 + float(p.lean), b.shoulder_y + 3.0 + up)
	for side: String in ["far", "near"]:
		var sh: Vector2 = j[side + "_shoulder"]
		var pin: Vector2 = p.far_hand if side == "far" else p.near_hand
		var joints: Array[Vector2] = []
		if is_nan(pin.x):
			var swing: float = p.far_swing if side == "far" else p.near_swing
			var bend: float = p.far_bend if side == "far" else p.near_bend
			var elbow: Vector2 = sh + Vector2(sin(swing), cos(swing)) * b.upper_arm
			joints = [elbow, elbow + Vector2(sin(swing + bend), cos(swing + bend)) * b.forearm]
		else:
			joints = _reach(sh, pin, b.upper_arm, b.forearm, p.far_elbow if side == "far" else p.near_elbow)
		j[side + "_elbow"] = joints[0]
		j[side + "_hand"] = joints[1]
	return j


## Two-bone reach from `from` toward `to`, the middle joint bending toward `bias`.
static func _reach(from: Vector2, to: Vector2, a: float, c: float, bias: Vector2) -> Array[Vector2]:
	var d: Vector2 = to - from
	var dist: float = clampf(d.length(), 0.01, a + c - 0.01)
	var dir: Vector2 = d.normalized()
	var end: Vector2 = from + dir * dist
	var along: float = (a * a - c * c + dist * dist) / (2.0 * dist)
	var out: float = sqrt(maxf(a * a - along * along, 0.0))
	var side: Vector2 = Vector2(-dir.y, dir.x)
	if side.dot(bias) < 0.0:
		side = -side
	return [from + dir * along + side * out, end]


static func _leg(img: Image, b: Build, hip: Vector2, ankle: Vector2, heel: float, c: Color, bend: bool, bias: Vector2, toe_back: bool) -> Vector2:
	var knee: Vector2
	if bend:
		var r: Array[Vector2] = _reach(hip, ankle, b.thigh, b.shin, bias)
		knee = r[0]
	else:
		knee = (hip + ankle) * 0.5 + Vector2(0.7, 0)
	_limb(img, hip, knee, b.leg_w[0], b.leg_w[1], c)
	_limb(img, knee, ankle, b.leg_w[2], b.leg_w[3], c)
	if toe_back:
		# Up on the toes behind, sole facing back.
		Px.poly(img, PackedVector2Array([ankle + Vector2(-2, -2), ankle + Vector2(2, -2), ankle + Vector2(-3, 4), ankle + Vector2(-7, 4)]), b.boot)
		return knee
	_boot(img, b, ankle, heel)
	return knee


static func _limb(img: Image, a: Vector2, z: Vector2, wa: float, wz: float, c: Color) -> void:
	var d: Vector2 = z - a
	if d.length() < 0.01:
		return
	var perp: Vector2 = Vector2(-d.y, d.x).normalized()
	Px.poly(img, PackedVector2Array([a + perp * wa, a - perp * wa, z - perp * wz, z + perp * wz]), c)
	Px.ellipse(img, z.x, z.y, wz, wz, c)


static func _boot(img: Image, b: Build, ankle: Vector2, lift: float) -> void:
	var sole_y: float = ankle.y + 4.0
	var back: Vector2 = Vector2(ankle.x - 2.5, sole_y - maxf(lift, 0.0))
	var toe: Vector2 = Vector2(ankle.x + 6.0, sole_y - maxf(-lift, 0.0))
	if b.heel > 0.0:
		# A heeled boot: the heel is a post under the back, the toe tips down to the floor.
		Px.poly(img, PackedVector2Array([
			Vector2(ankle.x - 2.0, ankle.y - 2.0), Vector2(ankle.x + 2.0, ankle.y - 2.0),
			Vector2(ankle.x + 3.0, ankle.y + 1.5), toe + Vector2(0, -1.5), toe, Vector2(ankle.x + 1.0, sole_y - b.heel - maxf(lift, 0.0)),
			Vector2(ankle.x - 1.0, sole_y - b.heel - maxf(lift, 0.0)), Vector2(ankle.x - 1.0, sole_y - maxf(lift, 0.0)),
			back, Vector2(ankle.x - 2.5, sole_y - b.heel - 1.0 - maxf(lift, 0.0))]), b.boot)
		return
	Px.poly(img, PackedVector2Array([
		Vector2(ankle.x - 2.5, ankle.y - 1.0), Vector2(ankle.x + 2.5, ankle.y - 1.0),
		Vector2(ankle.x + 3.0, ankle.y + 1.0), toe + Vector2(0, -2.5), toe, back]), b.boot)


static func _torso(img: Image, b: Build, p: Pose, j: Dictionary[String, Vector2]) -> void:
	var top: float = j["top"].y
	var l: float = float(p.lean)
	var cx: float = b.cx
	var belt: float = b.belt_y + float(p.bob) + p.drop
	var hem: float = b.hem_y + float(p.bob) + p.drop
	var long: bool = b.hem_y > b.hip_y + 8.0
	var fk: Vector2 = j["far_knee"]
	var nk: Vector2 = j["near_knee"]
	var lead: float = maxf(fk.x, nk.x)
	var trail: float = minf(fk.x, nk.x)
	var front_x: float = cx + b.waist_front + 1.0
	var back_x: float = cx - b.waist_back - 1.0
	if long:
		front_x = maxf(lead + 3.5, cx + b.waist_front + 2.5)
		back_x = minf(trail - 4.0, cx - b.waist_back - 2.5) - (2.0 if p.walking else 0.0)
	var shape: PackedVector2Array = PackedVector2Array([
		Vector2(cx - b.chest_back + 3.0 + l, top - 0.5), Vector2(cx + b.chest_front - 4.0 + l, top),
		Vector2(cx + b.chest_front - 1.0 + l, top + 2.5), Vector2(cx + b.chest_front + l, top + 11.0),
		Vector2(cx + b.waist_front + l * 0.5, belt), Vector2(cx + b.waist_front + 0.5 + l * 0.5, belt + 3.0),
		Vector2(front_x, hem), Vector2(front_x - 1.5, hem + 1.0), Vector2(back_x + 1.5, hem + 2.5 if long else hem + 1.0),
		Vector2(back_x, hem + (1.5 if long else 0.0)), Vector2(cx - b.waist_back - (2.0 if long else 0.5), belt + (10.0 if long else 4.0)),
		Vector2(cx - b.waist_back, belt + 2.0), Vector2(cx - b.waist_back, belt), Vector2(cx - b.chest_back + l, top + 8.0),
		Vector2(cx - b.chest_back + 0.5 + l, top + 2.0)])
	Px.poly(img, shape, b.coat)
	# Shadow side, falling off toward the hem.
	Px.poly(img, PackedVector2Array([
		Vector2(cx - b.chest_back + 0.5 + l, top + 2.0), Vector2(cx - b.chest_back + 4.0 + l, top), Vector2(cx - b.waist_back + 3.0, belt),
		Vector2(cx - 3.0, hem + 2.0), Vector2(back_x + 1.5, hem + 2.5 if long else hem + 1.0), Vector2(back_x, hem + (1.5 if long else 0.0)),
		Vector2(cx - b.waist_back - (2.0 if long else 0.5), belt + (10.0 if long else 4.0)), Vector2(cx - b.waist_back, belt + 2.0),
		Vector2(cx - b.chest_back + l, top + 8.0)]), b.coat_shade)
	if b.open_front:
		Px.poly(img, PackedVector2Array([
			Vector2(cx + b.chest_front - 4.0 + l, top + 1.0), Vector2(cx + b.chest_front - 1.0 + l, top + 3.0),
			Vector2(cx + b.chest_front + l, top + 11.0), Vector2(cx + b.waist_front + l * 0.5, belt),
			Vector2(cx + b.waist_front - 1.5 + l * 0.5, belt), Vector2(cx + b.chest_front - 3.5 + l, top + 9.0)]), b.inner)
		Px.line(img, Vector2i(roundi(cx + b.chest_front - 4.0 + l), roundi(top + 1.0)), Vector2i(roundi(cx + b.waist_front - 2.0 + l * 0.5), roundi(belt - 1.0)), b.coat_lit)
	if b.belt:
		Px.rect(img, roundi(cx - b.waist_back), roundi(belt), roundi(b.waist_back + b.waist_front), 2, b.coat_deep)
	if long:
		# The skirt parts over the leading knee; folds hang toward each knee.
		var split: Vector2i = Vector2i(roundi(cx + b.waist_front - 0.5 + l * 0.5), roundi(belt + 3.0))
		Px.line(img, split, Vector2i(roundi(front_x - 2.0), roundi(hem)), b.coat_lit)
		Px.line(img, Vector2i(roundi(cx - 2.0), roundi(belt + 6.0)), Vector2i(roundi(trail), roundi(hem)), b.coat_deep)
		Px.line(img, Vector2i(roundi(cx + 2.0), roundi(belt + 8.0)), Vector2i(roundi(lead - 1.0), roundi(hem)), b.coat_shade)
	if b.collar:
		Px.poly(img, PackedVector2Array([
			Vector2(cx - 7.0 + l, top + 1.5), Vector2(cx - 5.5 + l, top - 4.0), Vector2(cx - 2.0 + l, top - 3.0),
			Vector2(cx - 1.0 + l, top + 1.0)]), b.coat_shade)
		Px.poly(img, PackedVector2Array([
			Vector2(cx + 3.0 + l, top - 1.5), Vector2(cx + 5.5 + l, top - 1.0), Vector2(cx + 6.5 + l, top + 3.0), Vector2(cx + 3.5 + l, top + 2.0)]), b.coat_lit)


static func _arm(img: Image, b: Build, sh: Vector2, elbow: Vector2, hand: Vector2, c: Color, lit: Color, pocket: bool, near: bool) -> void:
	if near:
		# A darker underside, so the sleeve has some roundness.
		_limb(img, sh + Vector2(-1.5, 0), elbow + Vector2(-1.5, 0), b.arm_w[0], b.arm_w[1], b.coat_deep)
	_limb(img, sh, elbow, b.arm_w[0], b.arm_w[1], c)
	_limb(img, elbow, hand, b.arm_w[1], b.arm_w[2], c)
	if near:
		Px.line(img, Vector2i(roundi(sh.x) + 2, roundi(sh.y) - 1), Vector2i(roundi(elbow.x) + 2, roundi(elbow.y)), lit)
	if pocket:
		Px.line(img, Vector2i(roundi(hand.x) - 1, roundi(hand.y) - 2), Vector2i(roundi(hand.x) + 3, roundi(hand.y) + 1), b.coat_deep)
		return
	Px.rect(img, roundi(hand.x) - 1, roundi(hand.y), 3, 3, b.hand)
	if near:
		Px.dot(img, roundi(hand.x) + 1, roundi(hand.y) + 1, b.hand_lit)


static func _head(img: Image, b: Build, j: Dictionary[String, Vector2]) -> void:
	var at: Vector2i = Vector2i(j["head"].round())
	Px.rect(img, at.x + b.neck.position.x, at.y + b.neck.position.y, b.neck.size.x, b.neck.size.y, b.skin_shade)
	Px.dot(img, at.x + b.neck.end.x - 1, at.y + b.neck.position.y + 1, b.hand_lit)
	for y: int in range(b.head.size()):
		var row: String = b.head[y]
		for x: int in range(row.length()):
			var ch: String = row[x]
			if b.head_key.has(ch):
				img.set_pixel(at.x + x, at.y + y, b.head_key[ch])


static func _head_glow(img: Image, b: Build, j: Dictionary[String, Vector2]) -> void:
	if b.glow_keys == "":
		return
	var at: Vector2i = Vector2i(j["head"].round())
	for y: int in range(b.head.size()):
		var row: String = b.head[y]
		for x: int in range(row.length()):
			var ch: String = row[x]
			if b.glow_keys.contains(ch) and b.head_key.has(ch):
				Px.dot(img, at.x + x, at.y + y, b.head_key[ch])


## No outline. Edges facing the neon behind (left) get a hard cool rim, edges
## facing up or ahead get the warm lamps, and everything darkens toward the feet.
static func _light(img: Image, b: Build) -> void:
	var src: Image = img.duplicate() as Image
	var top: float = float(b.head_at.y) + 8.0
	var h: float = float(img.get_height())
	for y: int in range(img.get_height()):
		var fall: float = lerpf(1.08, 0.62, clampf((float(y) - top) / (h - top), 0.0, 1.0))
		for x: int in range(img.get_width()):
			if not Px.is_solid(src, x, y):
				continue
			var c: Color = src.get_pixel(x, y)
			c = Color(c.r * fall, c.g * fall, c.b * fall, c.a)
			var open_l: bool = not Px.is_solid(src, x - 1, y)
			var open_r: bool = not Px.is_solid(src, x + 1, y)
			var open_t: bool = not Px.is_solid(src, x, y - 1)
			if open_l:
				c = c.lerp(Color(RIM, c.a), 0.62 if y < int(b.hem_y) else 0.38)
			elif not Px.is_solid(src, x - 2, y):
				c = c.lerp(Color(RIM, c.a), 0.16)
			if open_t:
				c = c.lerp(Color(WARM, c.a), 0.45)
			elif open_r and y < int(b.belt_y):
				c = c.lerp(Color(WARM, c.a), 0.22)
			img.set_pixel(x, y, c)


## Marks every pixel drawn over since `snap` as `part`'s, and returns a fresh
## snapshot (null when layers aren't wanted).
static func _claim(img: Image, snap: Image, owner: PackedByteArray, part: int) -> Image:
	if snap == null:
		return null
	var w: int = img.get_width()
	for y: int in range(img.get_height()):
		for x: int in range(w):
			var now: Color = img.get_pixel(x, y)
			var was: Color = snap.get_pixel(x, y)
			if now == was:
				continue
			# A see-through layer laid over a part (a clear poncho, a sheen)
			# leaves the pixel with the part under it.
			if was.a > 0.5 and maxf(maxf(absf(now.r - was.r), absf(now.g - was.g)), absf(now.b - was.b)) < 0.12:
				continue
			owner[y * w + x] = part
	return img.duplicate() as Image


static func _split(img: Image, owner: PackedByteArray, layers: Dictionary) -> void:
	var w: int = img.get_width()
	for part: String in PARTS:
		layers[part] = Px.blank(w, img.get_height())
	for y: int in range(img.get_height()):
		for x: int in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var i: int = owner[y * w + x]
			var part: String = PARTS[i] if i < PARTS.size() else "body"
			(layers[part] as Image).set_pixel(x, y, c)
