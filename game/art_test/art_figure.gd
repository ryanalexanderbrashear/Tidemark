class_name ArtFigure
extends RefCounted
## A person on a realistic 8-head body, drawn the way the cast is lit: no ink
## outline, a hard cool rim from the neon behind, warm sodium light on the top
## edges and profile, falling off into shadow toward the feet.
##
## The body follows SLYNYRD's 8-head side-view chart (Pixelblog 49), which
## Alex picked as the anatomy reference (2026-11-08): at full height a person
## is 96 px from sole to crown, so one head is 12 px. Shoulders sit 1.3 heads
## down, the elbow at the navel (3 heads), the crotch at 4 heads (half height),
## the wrist level with it, the knee at 6 heads, and the foot is a head long.
## The head sits over the front half of the torso, on a visible neck; the chest
## is deep, the back curves in at the waist and out at the seat, and the calf
## swells behind the shin.
##
## Each character is a Build (stature, depths, clothes, head, props) on this
## one body, so everyone shares the same anatomy and light. Clothes are drawn
## as the body's own shapes eased outward, so they stay fitted and the anatomy
## reads through them. dummy = true draws the bare body in flat colours
## instead, like the chart's crash-test dummy, to check proportions.
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

## Height of a full-grown figure (stature 1.0) from sole to crown, and of a head.
const FULL_HEIGHT: float = 96.0
const HEAD: float = 12.0

## The crash-test dummy's colours, as on the reference chart.
const DUMMY_HEAD: Color = Color("cfc35a")
const DUMMY_NECK: Color = Color("b48a3e")
const DUMMY_TORSO: Color = Color("8e5ccc")
const DUMMY_ARM: Color = Color("5cb478")
const DUMMY_LEG: Color = Color("cc86b6")
const DUMMY_FAR: Color = Color("9a6488")


## A character's build, clothes and head. Lengths are in pixels at 640x360.
class Build:
	var size: Vector2i = Vector2i(48, 100)
	var cx: float = 22.0
	var stature: float = 1.0
	## Crown of the head, shoulders, waist (navel), hip joints, ankles.
	var top_y: float = 2.0
	var shoulder_y: float = 18.0
	var belt_y: float = 42.0
	var hip_y: float = 49.0
	var ankle_y: float = 94.0
	var thigh: float = 25.0
	var shin: float = 20.5
	var upper_arm: float = 18.0
	var forearm: float = 13.5
	var hand_len: float = 6.0
	## Distance the body moves in one walk cycle, so planted feet don't slide.
	var stride: float = 54.0
	## Half-depths of the torso in profile (front is +x): chest, waist, the
	## front of the pelvis, and the seat behind.
	var chest_front: float = 8.0
	var chest_back: float = 7.0
	var waist_front: float = 5.5
	var waist_back: float = 5.0
	var groin: float = 5.5
	var seat: float = 7.5
	## How far clothes stand off the body.
	var ease: float = 1.0
	## Where the outer layer ends. Well below the hips it's a long coat whose
	## skirt parts over the knees; near the hips it's a jacket.
	var hem_y: float = 76.0
	var open_front: bool = true
	var belt: bool = true
	var collar: bool = true
	## Half-widths of the legs: thigh at the hip, at the knee; shin at the knee,
	## at the ankle. The calf bulges behind the shin by `calf`.
	var leg_w: Array[float] = [5.0, 3.6, 3.4, 2.1]
	var calf: float = 2.6
	## Half-widths of the arms: shoulder, elbow, wrist.
	var arm_w: Array[float] = [2.8, 2.3, 1.7]
	## How tall the boot's heel is (0 for flat soles).
	var heel: float = 0.0
	## The bare body in flat colours, for checking proportions.
	var dummy: bool = false

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

	## The head in profile facing right, one character per pixel, keyed by
	## `head_key`. About 12 rows from crown to chin, the face at the right.
	var head: Array[String] = []
	var head_key: Dictionary[String, Color] = {}
	## Keys that glow (eyes, visors, lamps): drawn after the light, so they stay bright.
	var glow_keys: String = ""
	var head_at: Vector2i = Vector2i(16, 2)
	## The neck under the head: offset from head_at and size.
	var neck: Rect2i = Rect2i(3, 10, 6, 7)

	## Hooks for props, each called as hook(img, build, pose, joints):
	## behind everything, in front of the body, and after the light.
	var props_back: Callable = Callable()
	var props_front: Callable = Callable()
	var props_glow: Callable = Callable()
	## Called on the finished frame, for effects like a passenger coming apart.
	var finish: Callable = Callable()

	## Sets the body from a stature (1.0 = 96 px, a tall adult) on a canvas of
	## `canvas`, soles on its third row from the bottom, centred on `centre`.
	func proportion(canvas: Vector2i, s: float, centre: float) -> void:
		size = canvas
		stature = s
		cx = centre
		var sole: float = float(canvas.y) - 2.0
		var unit: float = FULL_HEIGHT * s / 8.0
		top_y = sole - unit * 8.0
		shoulder_y = top_y + unit * 1.35
		belt_y = top_y + unit * 3.0
		hip_y = top_y + unit * 3.9
		ankle_y = sole - 4.0
		# Legs a touch longer than hip to ankle, so a standing knee is just soft.
		var leg: float = ankle_y - hip_y + 0.6
		thigh = leg * 0.55
		shin = leg * 0.45
		upper_arm = unit * 1.5
		forearm = unit * 1.2
		hand_len = unit * 0.5
		stride = 54.0 * s
		hem_y = top_y + unit * 6.3
		leg_w = [5.0 * s, 3.6 * s, 3.4 * s, 2.1 * s]
		calf = 2.6 * s
		head_at = Vector2i(roundi(centre) - 6, roundi(top_y))


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
	var far_bend: float = 0.15
	var near_swing: float = 0.0
	var near_bend: float = 0.15
	## ...unless a hand is pinned to a point (NAN: not pinned). The elbow then
	## bends toward `*_elbow` (a direction).
	var far_hand: Vector2 = Vector2(NAN, NAN)
	var near_hand: Vector2 = Vector2(NAN, NAN)
	var far_elbow: Vector2 = Vector2(-1, 0.4)
	var near_elbow: Vector2 = Vector2(-1, 0.4)
	## The near hand is in a pocket: no hand drawn, a pocket line instead.
	var pocket: bool = false
	var far_arm: bool = true
	var walking: bool = false
	## For props that animate (an LED chase, a wrench turning).
	var frame: int = 0


# ---------- poses ----------

## Standing at ease: weight even, arms hanging, the near hand in a pocket.
static func idle_pose(b: Build, frame: int) -> Pose:
	var p: Pose = Pose.new()
	p.frame = frame
	p.breath = [0, 0, 1, 1][posmod(frame, 4)]
	p.far_foot = Vector2(b.cx - 3.0, b.ankle_y)
	p.near_foot = Vector2(b.cx + 2.0, b.ankle_y)
	p.far_arm = false
	p.near_swing = -0.04
	p.near_bend = 0.35
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
	p.far_swing = -arm * 0.32
	p.far_bend = maxf(-arm, 0.0) * 0.45 + 0.12
	p.near_swing = arm * 0.32
	p.near_bend = maxf(arm, 0.0) * 0.45 + 0.12
	p.pocket = false
	return p


## [ankle, heel lift] at walk frame `f`: planted and sliding back for half the
## cycle, swung forward for the other half.
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

## Draws one frame. If `layers` is a Dictionary, it's filled with one image per
## part (PARTS), together making up the returned frame.
static func draw(b: Build, p: Pose, layers: Variant = null) -> Image:
	var img: Image = Px.blank(b.size.x, b.size.y)
	var split: bool = layers is Dictionary
	var owner: PackedByteArray = PackedByteArray()
	owner.resize(b.size.x * b.size.y)
	owner.fill(255)
	var j: Dictionary[String, Vector2] = _joints(b, p)
	var snap: Image = img.duplicate() as Image if split else null
	if b.props_back.is_valid() and not b.dummy:
		b.props_back.call(img, b, p, j)
	snap = _claim(img, snap, owner, 0)
	if p.far_arm:
		var far_c: Color = DUMMY_FAR if b.dummy else b.coat_deep
		_arm(img, b, j["far_shoulder"], j["far_elbow"], j["far_hand"], far_c, far_c, false, false)
	snap = _claim(img, snap, owner, 1)
	var bend: bool = p.walking or p.drop > 0.0
	j["far_knee"] = _leg(img, b, j["hip"] + Vector2(-1.5, 0), p.far_foot, p.far_heel, DUMMY_FAR if b.dummy else b.pants_far, bend, p.far_knee, p.far_toe_back)
	j["near_knee"] = _leg(img, b, j["hip"] + Vector2(1.5, 0), p.near_foot, p.near_heel, DUMMY_LEG if b.dummy else b.pants, bend, p.near_knee, false)
	snap = _claim(img, snap, owner, 2)
	if b.dummy:
		Px.poly(img, _outline(b, p, j, 0.0, b.hip_y + 7.0 + float(p.bob) + p.drop, false), DUMMY_TORSO)
	else:
		_torso(img, b, p, j)
	snap = _claim(img, snap, owner, 3)
	if b.dummy:
		_arm(img, b, j["near_shoulder"], j["near_elbow"], j["near_hand"], DUMMY_ARM, DUMMY_ARM, false, false)
	else:
		_arm(img, b, j["near_shoulder"], j["near_elbow"], j["near_hand"], b.coat, b.coat_lit, p.pocket, true)
	snap = _claim(img, snap, owner, 4)
	_head(img, b, j)
	snap = _claim(img, snap, owner, 5)
	if b.dummy:
		return img
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
	j["near_shoulder"] = Vector2(b.cx + float(p.lean), b.shoulder_y + 2.5 + up)
	j["far_shoulder"] = Vector2(b.cx - 2.0 + float(p.lean), b.shoulder_y + 3.0 + up)
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
	var knee: Vector2 = _reach(hip, ankle, b.thigh, b.shin, bias if bend else Vector2(1, 0))[0]
	var w: Array[float] = b.leg_w
	var e: float = 0.0 if b.dummy else 0.4
	_limb(img, hip, knee, w[0] + e, w[1] + e, c)
	_limb(img, knee, ankle, w[2] + e, w[3] + e, c)
	# The calf swells behind the upper shin; the thigh's front is fuller than its back.
	var shin: Vector2 = ankle - knee
	var back: Vector2 = Vector2(-shin.y, shin.x).normalized()
	if back.x > 0.0:
		back = -back
	if not toe_back:
		# (A shin flat on the floor has its calf pressed against it.)
		var calf: Vector2 = knee + shin * 0.32 + back * (w[2] * 0.55)
		Px.ellipse(img, calf.x, calf.y, b.calf + e, shin.length() * 0.24, c)
	var thigh: Vector2 = hip.lerp(knee, 0.4) - back * 0.8
	Px.ellipse(img, thigh.x, thigh.y, w[0] * 0.95 + e, (knee - hip).length() * 0.3, c)
	if toe_back:
		# Up on the toes behind, sole facing back.
		Px.poly(img, PackedVector2Array([ankle + Vector2(-2, -2), ankle + Vector2(2, -2), ankle + Vector2(-4, 4), ankle + Vector2(-9, 4)]), DUMMY_FAR if b.dummy else b.boot)
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


## A foot a head long: heel just behind the ankle, toe well ahead of it.
static func _boot(img: Image, b: Build, ankle: Vector2, lift: float) -> void:
	var c: Color = DUMMY_LEG if b.dummy else b.boot
	var k: float = b.stature
	var sole_y: float = ankle.y + 4.0
	var back: Vector2 = Vector2(ankle.x - 3.0 * k, sole_y - maxf(lift, 0.0))
	var toe: Vector2 = Vector2(ankle.x + 8.5 * k, sole_y - maxf(-lift, 0.0))
	if b.heel > 0.0 and not b.dummy:
		# A heeled boot: the heel is a post under the back, the toe tips down to the floor.
		var up: float = maxf(lift, 0.0)
		Px.poly(img, PackedVector2Array([
			Vector2(ankle.x - 2.2, ankle.y - 2.5), Vector2(ankle.x + 2.0, ankle.y - 2.5),
			Vector2(ankle.x + 3.5, ankle.y + 0.5), toe + Vector2(-1.0, -1.5), toe, Vector2(ankle.x + 1.5, sole_y - b.heel - up),
			Vector2(ankle.x - 0.5, sole_y - b.heel - up), Vector2(ankle.x - 0.5, sole_y - up),
			Vector2(ankle.x - 2.0, sole_y - up), Vector2(ankle.x - 2.5, sole_y - b.heel - 1.0 - up)]), c)
		return
	Px.poly(img, PackedVector2Array([
		Vector2(ankle.x - 2.5, ankle.y - 1.5), Vector2(ankle.x + 2.5, ankle.y - 1.5),
		Vector2(ankle.x + 4.5 * k, ankle.y + 1.0), toe + Vector2(0, -2.0), toe, back,
		back + Vector2(-0.5, -2.5)]), c)


## The torso's side outline, eased out by `ease` (clothes) and ending at
## `bottom`: the crotch for the bare body, a hem for clothes. `skirt` spreads a
## long coat's hem over the knees.
static func _outline(b: Build, p: Pose, j: Dictionary[String, Vector2], ease: float, bottom: float, skirt: bool) -> PackedVector2Array:
	var cx: float = b.cx
	var top: float = j["top"].y
	var l: float = float(p.lean)
	var belt: float = b.belt_y + float(p.bob) + p.drop
	var hip: float = j["hip"].y
	var e: float = ease
	var front: Array[Vector2] = [
		Vector2(cx + 2.5 + l, top - 1.5 - e * 0.5),
		Vector2(cx + b.chest_front - 2.0 + l + e, top + 0.0),
		Vector2(cx + b.chest_front + l + e, top + 4.5),
		Vector2(cx + b.chest_front - 0.7 + l * 0.7 + e, top + 10.5),
		Vector2(cx + b.waist_front + l * 0.3 + e, belt),
		Vector2(cx + b.waist_front + 0.4 + e, belt + 4.0),
		Vector2(cx + b.groin + e, hip + 2.0),
	]
	var back: Array[Vector2] = [
		Vector2(cx - b.seat + 1.0 - e, hip + 5.5),
		Vector2(cx - b.seat - e, hip + 1.0),
		Vector2(cx - b.waist_back + 0.3 - e, belt - 1.5),
		Vector2(cx - b.chest_back + l * 0.6 - e, top + 9.0),
		Vector2(cx - b.chest_back + l - e, top + 3.0),
		Vector2(cx - b.chest_back + 2.0 + l - e * 0.5, top - 0.5 - e * 0.5),
		Vector2(cx - 2.5 + l, top - 1.5 - e * 0.5),
	]
	var pts: PackedVector2Array = PackedVector2Array()
	for v: Vector2 in front:
		if v.y < bottom:
			pts.append(v)
	if skirt:
		var fk: Vector2 = j["far_knee"]
		var nk: Vector2 = j["near_knee"]
		var lead: float = maxf(fk.x, nk.x)
		var trail: float = minf(fk.x, nk.x)
		var front_x: float = maxf(lead + 4.0, cx + b.groin + e + 1.5)
		var back_x: float = minf(trail - 5.0, cx - b.seat - e - 0.5) - (2.0 if p.walking else 0.0)
		pts.append(Vector2(front_x, bottom))
		pts.append(Vector2(front_x - 1.5, bottom + 1.0))
		pts.append(Vector2(back_x + 1.5, bottom + 2.0))
		pts.append(Vector2(back_x, bottom + 1.0))
	else:
		var low: float = minf(bottom, hip + 7.0)
		pts.append(Vector2(cx + b.groin + e - 0.5, low))
		pts.append(Vector2(cx - b.seat + 1.0 - e, low))
	for v: Vector2 in back:
		if v.y < bottom - 1.0:
			pts.append(v)
	return pts


static func _torso(img: Image, b: Build, p: Pose, j: Dictionary[String, Vector2]) -> void:
	var top: float = j["top"].y
	var l: float = float(p.lean)
	var cx: float = b.cx
	var belt: float = b.belt_y + float(p.bob) + p.drop
	var hem: float = b.hem_y + float(p.bob) + p.drop
	var long: bool = b.hem_y > b.hip_y + 9.0
	var shape: PackedVector2Array = _outline(b, p, j, b.ease, hem, long)
	Px.poly(img, shape, b.coat)
	# Shadow down the back half, falling off toward the hem.
	var shade: PackedVector2Array = PackedVector2Array()
	for v: Vector2 in shape:
		shade.append(Vector2(minf(v.x, cx - 2.0 + l * (1.0 if v.y < belt else 0.3)), v.y))
	Px.poly(img, shade, b.coat_shade)
	if b.open_front:
		Px.poly(img, PackedVector2Array([
			Vector2(cx + 2.5 + l, top), Vector2(cx + b.chest_front - 1.0 + l + b.ease, top + 3.0),
			Vector2(cx + b.chest_front - 0.5 + l + b.ease, top + 10.0), Vector2(cx + b.waist_front + l * 0.3 + b.ease, belt),
			Vector2(cx + b.waist_front - 1.5 + l * 0.3, belt), Vector2(cx + b.chest_front - 3.0 + l, top + 8.0)]), b.inner)
		Px.line(img, Vector2i(roundi(cx + 3.0 + l), roundi(top + 1.0)), Vector2i(roundi(cx + b.waist_front - 1.5 + l * 0.3), roundi(belt - 1.0)), b.coat_lit)
	if b.belt:
		Px.rect(img, roundi(cx - b.waist_back - b.ease), roundi(belt), roundi(b.waist_back + b.waist_front + b.ease * 2.0), 2, b.coat_deep)
	if long:
		# The skirt parts over the leading knee; folds hang toward each knee.
		var fk: Vector2 = j["far_knee"]
		var nk: Vector2 = j["near_knee"]
		var lead: float = maxf(fk.x, nk.x)
		var trail: float = minf(fk.x, nk.x)
		var front_x: float = maxf(lead + 4.0, cx + b.groin + b.ease + 1.5)
		var split: Vector2i = Vector2i(roundi(cx + b.waist_front + b.ease - 0.5), roundi(belt + 4.0))
		Px.line(img, split, Vector2i(roundi(front_x - 2.0), roundi(hem)), b.coat_lit)
		Px.line(img, Vector2i(roundi(cx - 2.0), roundi(belt + 8.0)), Vector2i(roundi(trail), roundi(hem)), b.coat_deep)
		Px.line(img, Vector2i(roundi(cx + 2.0), roundi(belt + 10.0)), Vector2i(roundi(lead - 1.0), roundi(hem)), b.coat_shade)
	if b.collar:
		Px.poly(img, PackedVector2Array([
			Vector2(cx - 5.5 + l, top + 1.5), Vector2(cx - 4.5 + l, top - 4.0), Vector2(cx - 1.0 + l, top - 3.0),
			Vector2(cx + 0.0 + l, top + 1.0)]), b.coat_shade)
		Px.poly(img, PackedVector2Array([
			Vector2(cx + 2.5 + l, top - 2.0), Vector2(cx + 4.5 + l, top - 1.0), Vector2(cx + 5.5 + l, top + 3.0), Vector2(cx + 3.0 + l, top + 2.0)]), b.coat_lit)


static func _arm(img: Image, b: Build, sh: Vector2, elbow: Vector2, hand: Vector2, c: Color, lit: Color, pocket: bool, near: bool) -> void:
	var w: Array[float] = b.arm_w
	if near and not b.dummy:
		# A darker underside, so the sleeve has some roundness.
		_limb(img, sh + Vector2(-1.2, 0), elbow + Vector2(-1.2, 0), w[0], w[1], b.coat_deep)
	_limb(img, sh, elbow, w[0], w[1], c)
	_limb(img, elbow, hand, w[1], w[2], c)
	if near and not b.dummy:
		Px.line(img, Vector2i(roundi(sh.x) + 2, roundi(sh.y) - 1), Vector2i(roundi(elbow.x) + 2, roundi(elbow.y)), lit)
	if pocket:
		Px.line(img, Vector2i(roundi(hand.x) - 1, roundi(hand.y) - 2), Vector2i(roundi(hand.x) + 3, roundi(hand.y) + 1), b.coat_deep)
		return
	# The hand: a mitten of palm and fingers carrying on from the forearm.
	var dir: Vector2 = (hand - elbow).normalized()
	var tip: Vector2 = hand + dir * b.hand_len
	var hc: Color = c if b.dummy else b.hand
	_limb(img, hand, tip, 1.6 * b.stature, 1.2 * b.stature, hc)
	if near and not b.dummy:
		var knuckle: Vector2 = hand.lerp(tip, 0.45) + Vector2(-dir.y, dir.x).normalized() * (1.0 if dir.y > 0.0 else -1.0)
		Px.dot(img, roundi(knuckle.x) + 1, roundi(knuckle.y), b.hand_lit)


static func _head(img: Image, b: Build, j: Dictionary[String, Vector2]) -> void:
	var at: Vector2i = Vector2i(j["head"].round())
	Px.rect(img, at.x + b.neck.position.x, at.y + b.neck.position.y, b.neck.size.x, b.neck.size.y, DUMMY_NECK if b.dummy else b.skin_shade)
	if not b.dummy:
		Px.dot(img, at.x + b.neck.end.x - 1, at.y + b.neck.position.y + 2, b.hand_lit)
	for y: int in range(b.head.size()):
		var row: String = b.head[y]
		for x: int in range(row.length()):
			var ch: String = row[x]
			if b.head_key.has(ch):
				img.set_pixel(at.x + x, at.y + y, DUMMY_HEAD if b.dummy else b.head_key[ch])


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
	var top: float = b.top_y + 8.0
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
