class_name ArtCast
extends RefCounted
## The cast, drawn closer to final on one rig (ArtFigure): a realistic 8-head
## body (SLYNYRD's anatomy chart, which Alex picked), no outline, cool neon rim
## and warm lamp light. The Drowned Market's people (Osk, the fixer, the maintenance
## tech, Vale's passenger) stand in the art test; the later cast (Anton Leith,
## Cass Doran, Juno "Velvet" Kade, Pell) are drawn here for the line-up and the
## sprite exporter.
##
## Their looks are placeholders, not canon: the design docs don't describe what
## anyone looks like. What each look leans on is in its comment, so it's easy
## to see what to change.
##
## Every character has named animations (idle, walk, and a few of their own).
## frames() draws them; the exporter (editor/art/export_sprites.gd) writes them
## out as PNG sheets, Aseprite files and Godot SpriteFrames.

const P = preload("res://game/art/art_palette.gd")
const Figure = preload("res://game/art/art_figure.gd")

## Everyone drawn on the rig, in line-up order.
const IDS: Array[String] = ["detective", "osk", "fixer", "tech", "vale", "leith", "cass", "velvet", "pell"]

const NAMES: Dictionary[String, String] = {
	"detective": "The detective",
	"osk": "Osk",
	"fixer": "The fixer",
	"tech": "Maintenance tech",
	"vale": "Ines Vale (passenger)",
	"leith": "Anton Leith",
	"cass": "Cass Doran",
	"velvet": "Juno \"Velvet\" Kade",
	"pell": "Pell",
}

## Frames per second for each animation when played back (the scene plays the
## detective's walk by distance instead).
const FPS: Dictionary[String, float] = {"idle": 2.0, "walk": 10.0, "run": 12.0, "work": 2.0, "passenger": 1.4}

## The common head key. Each character adds its own letters.
const HEAD_KEY: Dictionary[String, Color] = {
	"e": Color("2e2427"), "z": Color("3a2f32"), "b": Color("1c1619"), "d": Color("15100f"),
	"w": Color("c49373"), "r": Color("5e8c98"),
}

static var _builds: Dictionary[String, Figure.Build] = {}


## Animation names and frame counts, in the order the exporter lays them out.
static func anims(id: String) -> Dictionary[String, int]:
	match id:
		"vale":
			return {"passenger": 4}
		"tech":
			return {"idle": 4, "walk": 8, "work": 4}
		"detective":
			# His everyday pace is the run; the walk is for slow moments.
			return {"idle": 4, "walk": 8, "run": 8}
	return {"idle": 4, "walk": 8}


static func size(id: String) -> Vector2i:
	return build(id).size


static func frame(id: String, anim: String, f: int, layers: Variant = null) -> Image:
	return Figure.draw(build(id), pose(id, anim, f), layers)


## The bare body under a character, in the chart's flat colours, standing.
static func dummy(id: String) -> Image:
	var b: Figure.Build = build(id)
	b.dummy = true
	var img: Image = Figure.draw(b, Figure.idle_pose(b, 0))
	b.dummy = false
	return img


static func frames(id: String, anim: String) -> Array[Image]:
	var out: Array[Image] = []
	for f: int in range(anims(id)[anim]):
		out.append(frame(id, anim, f))
	return out


static func pose(id: String, anim: String, f: int) -> Figure.Pose:
	var b: Figure.Build = build(id)
	var p: Figure.Pose = Figure.idle_pose(b, f)
	if anim == "walk":
		p = Figure.walk_pose(b, f)
	elif anim == "run":
		p = Figure.run_pose(b, f)
	match id:
		"osk":
			# The umbrella stays up in the near hand; the case hangs from the far one.
			p.near_hand = Vector2(b.cx + 12.0 * Figure.K + float(p.lean), b.shoulder_y + 5.0 * Figure.K + float(p.bob - p.breath))
			p.near_elbow = Vector2(-0.2, 1)
			p.pocket = false
			p.far_arm = true
			if anim == "idle":
				p.far_swing = -0.3
				p.far_bend = 0.05
		"fixer":
			if anim == "idle":
				p.far_arm = false
		"tech":
			if anim == "work":
				_kneel(b, p, f)
		"vale":
			# Turned half away, one arm out to point. Frame 2-3 she lifts her head.
			p.breath = [0, 0, 1, 1][posmod(f, 4)]
			p.near_hand = Vector2(b.cx + 21.0 * Figure.K, b.shoulder_y + 9.0 * Figure.K - float(p.breath))
			p.near_elbow = Vector2(0, 1)
			p.pocket = false
			p.far_arm = true
			p.far_swing = -0.05
			p.far_bend = 0.1
		"leith":
			if anim == "idle":
				# Hands clasped behind his back, upright, patient.
				p.near_hand = Vector2(b.cx - 6.5 * Figure.K, b.belt_y + 6.0 * Figure.K - float(p.breath))
				p.near_elbow = Vector2(-0.5, 1)
				p.pocket = false
		"velvet":
			if anim == "idle":
				# A thin vape at her collarbone; the far hand on her hip.
				p.near_hand = Vector2(b.cx + 6.0 * Figure.K, b.shoulder_y + 7.0 * Figure.K - float(p.breath))
				p.near_elbow = Vector2(-0.3, 1)
				p.pocket = false
		"pell":
			p.lean = roundi(2.0 * Figure.K)
			if anim == "idle":
				# Holding a chip up to his lenses.
				p.near_hand = Vector2(b.cx + 10.0 * Figure.K, b.shoulder_y - 3.0 * Figure.K + float(p.breath))
				p.near_elbow = Vector2(0.2, 1)
				p.pocket = false
	return p


## The tech kneels at the pump: back knee on the planks, front foot planted,
## both hands on the wrench. The wrench turns a notch a frame.
static func _kneel(b: Figure.Build, p: Figure.Pose, f: int) -> void:
	p.breath = 0
	# Thigh upright over the back knee, which rests on the planks.
	p.drop = b.ankle_y + 0.5 - b.thigh - b.hip_y
	p.lean = roundi(5.0 * Figure.K)
	p.far_foot = Vector2(b.cx - b.shin + 2.0 * Figure.K, b.ankle_y)
	p.far_heel = 5.0 * Figure.K
	p.far_knee = Vector2(0, 1)
	p.far_toe_back = true
	p.near_foot = Vector2(b.cx + b.thigh * 0.85, b.ankle_y)
	p.walking = false
	# A ratchet: three pulls, then the handle goes back for the next.
	var turn: float = float(posmod(f, 4))
	p.near_hand = Vector2(b.cx + 25.0 * Figure.K, b.hip_y + p.drop - 9.0 * Figure.K - turn)
	p.near_elbow = Vector2(0, 1)
	p.far_hand = Vector2(b.cx + 23.0 * Figure.K, b.hip_y + p.drop - 7.0 * Figure.K - turn)
	p.far_elbow = Vector2(0, 1)
	p.far_arm = true
	p.pocket = false


static func build(id: String) -> Figure.Build:
	if _builds.has(id):
		return _builds[id]
	var b: Figure.Build = Figure.Build.new()
	match id:
		"detective":
			_detective(b)
		"osk":
			_osk(b)
		"fixer":
			_fixer(b)
		"tech":
			_tech(b)
		"vale":
			_vale(b)
		"leith":
			_leith(b)
		"cass":
			_cass(b)
		"velvet":
			_velvet(b)
		"pell":
			_pell(b)
	b.fit()
	_builds[id] = b
	return b


static func _key(extra: Dictionary[String, Color]) -> Dictionary[String, Color]:
	var k: Dictionary[String, Color] = HEAD_KEY.duplicate()
	k.merge(extra, true)
	return k


## The detective's colours, kept from the tall rim-lit draft he was first
## drawn as.
const DET_COAT: Color = Color("1c2230")
const DET_COAT_LIT: Color = Color("2b3446")
const DET_COAT_SHADE: Color = Color("121722")
const DET_COAT_DEEP: Color = Color("0a0e15")
const DET_SWEATER: Color = Color("24232a")
const DET_PANTS: Color = Color("141924")
const DET_PANTS_FAR: Color = Color("0c1018")
const DET_BOOT: Color = Color("080a0f")
const DET_BRACE: Color = Color("3a4655")
const DET_BRACE_LIT: Color = Color("8a97a6")
const DET_SKIN: Color = Color("6e5650")
const DET_SKIN_SHADE: Color = Color("47383a")
const DET_HAIR: Color = Color("0d1017")
const DET_HEAD_KEY: Dictionary[String, Color] = {
	"h": DET_HAIR, "s": DET_SKIN, "S": DET_SKIN_SHADE, "e": Color("2e2427"), "z": Color("3a2f32"),
	"b": Color("1c1619"), "m": Color("56626f"), "c": P.CYAN, "p": DET_BRACE,
	"w": Color("c49373"), "r": Color("5e8c98"),
}

## The detective, the "rain-worn tracer" Alex picked (2026-11-06): an open
## storm coat to the knee, short hair and stubble, the steel ocular plate with
## its cyan iris, the reading port behind the ear, steel braces down the shins.
static func _detective(b: Figure.Build) -> void:
	b.proportion(Vector2i(50, 100), 1.0, 22.0)
	b.hem_y = b.top_y + 12.0 * 6.0
	b.coat = DET_COAT
	b.coat_lit = DET_COAT_LIT
	b.coat_shade = DET_COAT_SHADE
	b.coat_deep = DET_COAT_DEEP
	b.inner = DET_SWEATER
	b.pants = DET_PANTS
	b.pants_far = DET_PANTS_FAR
	b.boot = DET_BOOT
	b.skin = DET_SKIN
	b.skin_shade = DET_SKIN_SHADE
	b.hand = DET_SKIN_SHADE
	b.hand_lit = Color("c49373")
	b.head = [
		".rrrrrw..",
		"rhhhhhhw.",
		"rhhhhhsw.",
		"rhhhhhSw.",
		"rhhhmcsw.",
		"rpheSSsss",
		"rhhSSSzw.",
		".rSSSSSw.",
		"...SSSS..",
	]
	b.head_key = DET_HEAD_KEY.duplicate()
	b.glow_keys = "c"
	b.neck = Rect2i(1, 6, 4, 5)
	b.props_front = func(img: Image, bb: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		# Steel braces down the front of each shin, catching a glint at the knee.
		for side: String in ["far", "near"]:
			var knee: Vector2 = j[side + "_knee"]
			var ankle: Vector2 = p.far_foot if side == "far" else p.near_foot
			var shin: Vector2 = ankle - knee
			var n: int = maxi(roundi(shin.length()), 1)
			var c: Color = DET_BRACE if side == "near" else DET_BRACE.darkened(0.4)
			for i: int in range(2, n - 2):
				var at: Vector2 = knee + shin * (float(i) / float(n)) + Vector2(bb.leg_w[2] - 0.6, 0)
				Px.dot(img, roundi(at.x), roundi(at.y), c)
			if side == "near":
				Px.rect(img, roundi(knee.x) + 1, roundi(knee.y) - 1, 2, 3, DET_BRACE)
				Px.dot(img, roundi(knee.x) + 2, roundi(knee.y) - 1, DET_BRACE_LIT)


## Osk, the rival broker: short and broad, bald, goggles pushed up on his
## forehead, a brown work jacket under a clear rain poncho, an LED-trimmed
## umbrella and a broker's memory case. (Kept from the first sketch.)
static func _osk(b: Figure.Build) -> void:
	b.proportion(Vector2i(66, 100), 0.88, 30.0)
	b.chest_front = 9.3
	b.chest_back = 8.5
	b.waist_front = 9.0
	b.waist_back = 6.3
	b.groin = 7.5
	b.seat = 8.0
	b.hem_y = b.hip_y + 8.0
	b.open_front = false
	b.collar = false
	b.leg_w = [5.6, 4.2, 4.0, 2.6]
	b.calf = 3.0
	b.arm_w = [3.3, 2.8, 2.2]
	b.coat = Color("3a2724")
	b.coat_lit = Color("5a3d32")
	b.coat_shade = Color("261a19")
	b.coat_deep = Color("1a1110")
	b.pants = Color("1b1d22")
	b.pants_far = Color("111317")
	b.skin = Color("8a6a5c")
	b.skin_shade = Color("5e4842")
	b.hand = Color("5e4842")
	b.hand_lit = Color("b08670")
	b.neck = Rect2i(1, 6, 5, 4)
	b.head = [
		".rrrrrw..",
		"rssssssw.",
		"rSqqqqGGG",
		"rSSSSbbw.",
		"rSSSSdsw.",
		"rSSeSSsss",
		"rSSSSzzw.",
		".rSzzzzw.",
		"...zzzz..",
	]
	b.head_key = _key({"s": b.skin, "S": b.skin_shade, "q": Color("1a1410"), "G": Color("6a4a22")})
	b.props_back = func(img: Image, _b: Figure.Build, _p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		# The memory case in the far hand.
		var h: Vector2 = j["far_hand"]
		Px.rect(img, roundi(h.x) - 3, roundi(h.y) + 1, 7, 5, P.STEEL)
		Px.rect(img, roundi(h.x) - 2, roundi(h.y) + 2, 5, 1, P.CYAN_DIM)
		Px.rect(img, roundi(h.x) - 3, roundi(h.y) + 5, 7, 1, Color("20262f"))
	b.props_front = func(img: Image, bb: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		# The poncho: clear plastic hanging a pixel off him from the shoulders
		# to below the jacket, with wet creases.
		var t: Vector2 = j["top"]
		var hem: int = roundi(bb.hem_y + 2.0) + p.bob
		var under: Image = img.duplicate() as Image
		for y: int in range(roundi(t.y) - 1, hem):
			for x: int in range(img.get_width()):
				var solid: bool = Px.is_solid(under, x, y)
				var near: bool = solid or Px.is_solid(under, x - 1, y) or Px.is_solid(under, x + 1, y) or Px.is_solid(under, x, y - 1)
				if y < roundi(t.y) + 3 and not solid:
					continue
				if near:
					Px.dot(img, x, y, Color(P.RAIN, 0.12 if solid else 0.3))
		for i: int in [-6, -2, 4]:
			for y: int in range(roundi(t.y) + 2, hem - 1):
				var x: int = roundi(t.x) + i + (y - roundi(t.y)) / 6 * (1 if i > 0 else -1)
				if Px.is_solid(img, x, y) and (y + i) % 5 != 0:
					Px.dot(img, x, y, Color(P.GLINT, 0.12))
		# The umbrella: shaft from the hand, canopy over the head.
		var h: Vector2 = j["near_hand"]
		var c: Vector2 = Vector2(h.x - 2.0, 2.0)
		Px.line(img, Vector2i(h.round()) + Vector2i(0, 2), Vector2i(c.round()), P.STEEL)
		for y: int in range(5):
			var half: float = 14.0 * sqrt(1.0 - pow(float(4 - y) / 5.0, 2.0))
			Px.rect(img, roundi(c.x - half), roundi(c.y) + y, roundi(half * 2.0), 1, Color("161f2e") if y < 4 else Color("0e1520"))
		for rib: float in [-11.0, -6.0, 0.0, 6.0, 11.0]:
			Px.line(img, Vector2i(c.round()), Vector2i(roundi(c.x + rib), roundi(c.y) + 4), Color("223047"))
		Px.rect(img, roundi(h.x) - 1, roundi(h.y), 2, 2, bb.hand)
	b.props_glow = func(img: Image, _b: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		var c: Vector2 = Vector2(j["near_hand"].x - 2.0, 2.0)
		for x: int in range(-13, 14, 2):
			Px.dot(img, roundi(c.x) + x, roundi(c.y) + 4, P.CYAN if (x + 13 + p.frame * 2) % 6 != 0 else P.CYAN_DIM)
		var h: Vector2 = j["far_hand"]
		Px.dot(img, roundi(h.x) + 2, roundi(h.y) + 2, P.CYAN)


## The fixer: tall and thin, hooded, a magenta visor across the eyes, the
## lower face pale and narrow under it. Cables run over the shoulder into the
## hood. (Kept from the first sketch, with a face.)
static func _fixer(b: Figure.Build) -> void:
	b.proportion(Vector2i(46, 106), 1.05, 20.0)
	b.chest_front = 6.8
	b.chest_back = 6.5
	b.waist_front = 4.8
	b.waist_back = 4.8
	b.groin = 5.0
	b.seat = 6.5
	b.hem_y = b.ankle_y - 12.0
	b.collar = false
	b.leg_w = [4.2, 3.0, 2.9, 1.8]
	b.calf = 2.0
	b.arm_w = [2.4, 2.0, 1.5]
	b.coat = Color("1d1828")
	b.coat_lit = Color("332a46")
	b.coat_shade = Color("15111e")
	b.coat_deep = Color("0c0a12")
	b.inner = Color("2a2238")
	b.pants = Color("121019")
	b.pants_far = Color("0b0a10")
	b.skin = Color("8a7a78")
	b.skin_shade = Color("5a4c50")
	b.hand = Color("5a4c50")
	b.hand_lit = Color("a8928a")
	b.neck = Rect2i(2, 7, 4, 5)
	b.head = [
		".rrhhhw..",
		"rhhhhhhw.",
		"rhhhhhkkh",
		"rhhhhkkkh",
		"rhhhhkVVV",
		"rhhhhkSss",
		"rhhhhkSw.",
		"rhhhhhkw.",
		".rhhhhhh.",
		"..hhhhh..",
	]
	b.head_key = _key({"h": Color("221c30"), "k": P.INK, "V": P.MAGENTA, "s": b.skin, "S": b.skin_shade})
	b.glow_keys = "V"
	b.props_glow = func(img: Image, _b: Figure.Build, _p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		var t: Vector2 = j["top"]
		for i: int in range(5):
			Px.dot(img, roundi(t.x) - 3 + (i % 2), roundi(t.y) + 1 + i * 3, P.MAGENTA_DIM)
		var at: Vector2 = j["head"]
		Px.dot(img, roundi(at.x) + 6, roundi(at.y) + 5, Color(P.MAGENTA, 0.5))


## The maintenance tech: older, grey-bearded, a knit cap with a headlamp, a
## green work jacket with a dull reflective band. Works the pump on one knee.
static func _tech(b: Figure.Build) -> void:
	b.proportion(Vector2i(70, 100), 0.95, 30.0)
	b.chest_front = 8.3
	b.chest_back = 8.0
	b.waist_front = 6.5
	b.waist_back = 5.8
	b.groin = 6.0
	b.seat = 7.5
	b.hem_y = b.hip_y + 7.0
	b.open_front = false
	b.belt = false
	b.collar = false
	b.coat = Color("2f3a2c")
	b.coat_lit = Color("46553f")
	b.coat_shade = Color("1f281e")
	b.coat_deep = Color("141a13")
	b.pants = Color("1d2026")
	b.pants_far = Color("13151a")
	b.boot = Color("0c0b0a")
	b.skin = Color("7a5e52")
	b.skin_shade = Color("51403b")
	b.hand = Color("2a2a26")
	b.hand_lit = Color("4a4a42")
	b.neck = Rect2i(2, 7, 4, 5)
	b.head = [
		".rrrrrw..",
		"rhhhhhhLL",
		"rqqqqqqq.",
		"rgggSbbw.",
		"rggSSdsw.",
		"rgeSSSsss",
		"rggSyyyw.",
		".ryyyyyw.",
		"..yyyyy..",
	]
	b.head_key = _key({"h": Color("2a2f35"), "q": Color("1c2024"), "g": Color("46484c"), "y": Color("4c4a48"),
		"s": b.skin, "S": b.skin_shade, "L": P.AMBER})
	b.glow_keys = "L"
	b.props_back = func(img: Image, bb: Figure.Build, p: Figure.Pose, _j: Dictionary[String, Vector2]) -> void:
		if p.drop <= 0.0:
			return
		# A tool bag on the planks behind him.
		Px.rect(img, roundi(bb.cx) - 17, roundi(bb.ankle_y) - 1, 8, 4, Color("2a2622"))
		Px.rect(img, roundi(bb.cx) - 16, roundi(bb.ankle_y) - 3, 6, 2, Color("1a1714"))
	b.props_front = func(img: Image, bb: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		# The reflective band, across the chest.
		var t: Vector2 = j["top"]
		var y: int = roundi(t.y) + 10
		for x: int in range(roundi(bb.cx - bb.chest_back) + 1, roundi(bb.cx + bb.chest_front + float(p.lean) * 0.8)):
			if Px.is_solid(img, x, y):
				img.set_pixel(x, y, Color("6a6f5a"))
		if p.drop <= 0.0:
			return
		# The wrench, turning a notch a frame.
		var h: Vector2 = j["near_hand"]
		var turn: float = float(posmod(p.frame, 4))
		var tip: Vector2 = h + Vector2(4.0 - turn * 0.5, -5.0 + turn * 1.2)
		Px.line(img, Vector2i(h.round()), Vector2i(tip.round()), P.STEEL)
		Px.rect(img, roundi(tip.x) - 1, roundi(tip.y) - 1, 3, 2, P.STEEL)
		Px.rect(img, roundi(h.x) - 1, roundi(h.y), 2, 2, bb.hand)


## Ines Vale as a passenger: still wet, head bowed, hair down over her face,
## one arm out to point. Drawn in the fog's greys, coming apart into it from
## the knees down, so she reads as not quite there. (Kept from the first sketch.)
static func _vale(b: Figure.Build) -> void:
	b.proportion(Vector2i(54, 96), 0.92, 18.0)
	b.chest_front = 7.3
	b.chest_back = 6.0
	b.waist_front = 4.8
	b.waist_back = 4.3
	b.groin = 5.0
	b.seat = 7.0
	b.hem_y = b.ankle_y - 14.0
	b.belt = false
	b.collar = false
	b.leg_w = [4.4, 3.0, 2.9, 1.7]
	b.calf = 2.2
	b.arm_w = [2.1, 1.8, 1.3]
	b.coat = Color("3c4452")
	b.coat_lit = Color("56606f")
	b.coat_shade = Color("2c333f")
	b.coat_deep = Color("232a35")
	b.inner = Color("5a6270")
	b.pants = Color("4a5160")
	b.pants_far = Color("353b47")
	b.boot = Color("2a2f38")
	b.skin = Color("8a919b")
	b.skin_shade = Color("6a717b")
	b.hand = Color("8a919b")
	b.hand_lit = Color("a6adb6")
	b.neck = Rect2i(2, 7, 4, 5)
	b.head = [
		".rrrrr...",
		"rhhhhhhw.",
		"rhhhhhsw.",
		"rhhhhhsw.",
		"rhhhhhbw.",
		"rhhhhhSss",
		"rhhhhhzw.",
		"rhhhhhSw.",
		"rhhhhhh..",
		"rh.h.hh..",
		"r..h..h..",
	]
	b.head_key = _key({"h": Color("15141a"), "s": b.skin, "S": b.skin_shade, "r": Color("4a5560"), "w": Color("9aa3ad")})
	b.finish = func(img: Image, bb: Figure.Build, p: Figure.Pose, _j: Dictionary[String, Vector2]) -> void:
		# Greyed toward the fog, then coming apart from the knees down.
		var knee: int = roundi(bb.hip_y + bb.thigh * 0.8)
		var h: int = img.get_height()
		for y: int in range(h):
			for x: int in range(img.get_width()):
				var c: Color = img.get_pixel(x, y)
				if c.a <= 0.0:
					continue
				var grey: float = (c.r + c.g + c.b) / 3.0
				c = c.lerp(Color(grey * 0.95, grey, grey * 1.08, c.a), 0.6)
				if y > knee and Px.dither(x + p.frame, y, float(y - knee) / float(h - 2 - knee) * 1.15):
					c = Color(0, 0, 0, 0)
				img.set_pixel(x, y, c)
		# Water running off her.
		for y: int in range(roundi(bb.shoulder_y), h - 6, 5):
			Px.dot(img, roundi(bb.cx) - 5 + (y * 3) % 8, y + (p.frame % 2) * 2, Color(P.GLINT, 0.5))


## Anton Leith: tall, upright and composed. A long pale clinician's coat with
## a high collar, buttoned to the throat, rain-greyed; pale gloves; hair combed
## straight back; clean-shaven, a thin pleased mouth. The only pale figure in
## the cast, so he reads as "the man in white" from across a dark room.
static func _leith(b: Figure.Build) -> void:
	b.proportion(Vector2i(48, 104), 1.04, 21.0)
	b.chest_front = 7.8
	b.chest_back = 7.0
	b.waist_front = 5.0
	b.waist_back = 5.0
	b.groin = 5.5
	b.seat = 7.0
	b.hem_y = b.ankle_y - 10.0
	b.open_front = false
	b.belt = false
	b.collar = false
	b.coat = Color("7e8794")
	b.coat_lit = Color("a7b0bb")
	b.coat_shade = Color("565e6a")
	b.coat_deep = Color("3b414c")
	b.pants = Color("181b22")
	b.pants_far = Color("101218")
	b.boot = Color("07080b")
	b.skin = Color("8c7672")
	b.skin_shade = Color("5e4e4f")
	b.hand = Color("aab1ba")
	b.hand_lit = Color("cfd5dc")
	b.neck = Rect2i(1, 6, 4, 5)
	b.head = [
		".rrrrrrw.",
		"rhhhhhhw.",
		"rhhhhhsw.",
		"rhhhhhSw.",
		"rhhhSlsw.",
		"rhheSSsss",
		"rhSSSSmw.",
		".rSSSSSw.",
		"...SSSS..",
	]
	b.head_key = _key({"h": Color("2a2a2e"), "s": b.skin, "S": b.skin_shade, "l": Color("b6c2c8"), "m": Color("4a3436")})
	b.props_front = func(img: Image, bb: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		var t: Vector2 = j["top"]
		# High collar, closed at the throat.
		Px.poly(img, PackedVector2Array([t + Vector2(-5, 2), t + Vector2(-4, -3), t + Vector2(3, -2), t + Vector2(5, 2)]), bb.coat)
		Px.line(img, Vector2i(t + Vector2(-4, -3)), Vector2i(t + Vector2(3, -2)), bb.coat_lit)
		# The button line down the front, and a seam at the hem.
		var front: int = roundi(bb.cx + bb.chest_front - 1.5) + p.lean
		for y: int in range(roundi(t.y) + 3, roundi(bb.hem_y) + p.bob, 4):
			Px.dot(img, front, y, bb.coat_deep)
		Px.line(img, Vector2i(front, roundi(t.y) + 2), Vector2i(roundi(bb.cx + bb.waist_front - 1.0), roundi(bb.hem_y) + p.bob), bb.coat_shade)


## Cass Doran, grown: slight, wary, raised undocumented in the Freeboard. A
## patched, faded rain shell with the hood down, a rust scarf, cargo trousers,
## worn boots, a pack strap. No cyberware. Gender is still open in the docs,
## so the look is deliberately neither.
static func _cass(b: Figure.Build) -> void:
	b.proportion(Vector2i(46, 94), 0.9, 22.0)
	b.chest_front = 7.3
	b.chest_back = 6.5
	b.waist_front = 5.5
	b.waist_back = 4.8
	b.groin = 5.5
	b.seat = 6.8
	b.hem_y = b.hip_y + 7.0
	b.open_front = false
	b.belt = false
	b.collar = false
	b.leg_w = [4.5, 3.3, 3.1, 2.0]
	b.calf = 2.3
	b.arm_w = [2.6, 2.1, 1.6]
	b.coat = Color("2e4a4c")
	b.coat_lit = Color("456668")
	b.coat_shade = Color("1f3335")
	b.coat_deep = Color("142224")
	b.pants = Color("26281f")
	b.pants_far = Color("191a14")
	b.boot = Color("120f0c")
	b.skin = Color("7a5e52")
	b.skin_shade = Color("4f3e39")
	b.hand = Color("4f3e39")
	b.hand_lit = Color("a07c68")
	b.neck = Rect2i(2, 6, 4, 5)
	b.head = [
		".rrrrhh..",
		"rhhhhhhhw",
		"rhhhhhhs.",
		"rhhhhhSw.",
		"rhhhhdsw.",
		"rhheSSsss",
		"rhhSSSmw.",
		".rSSSSw..",
		"...SSS...",
	]
	b.head_key = _key({"h": Color("2a1c18"), "s": b.skin, "S": b.skin_shade, "m": Color("4a3230")})
	b.props_back = func(img: Image, bb: Figure.Build, _p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		# A small pack on the back.
		var t: Vector2 = j["top"]
		Px.poly(img, PackedVector2Array([t + Vector2(-bb.chest_back - 3.0, 2), t + Vector2(-bb.chest_back + 1.5, 1.5),
			t + Vector2(-bb.chest_back + 1.5, 15), t + Vector2(-bb.chest_back - 3.0, 14)]), Color("2a2a24"))
	b.props_front = func(img: Image, bb: Figure.Build, _p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		var t: Vector2 = j["top"]
		# Hood bunched behind the neck, the scarf, a patch, the pack strap.
		Px.ellipse(img, t.x - 3.0, t.y - 1.0, 3.0, 2.0, bb.coat_shade)
		Px.poly(img, PackedVector2Array([t + Vector2(-2, -2), t + Vector2(4, -2), t + Vector2(5, 1), t + Vector2(-2, 2)]), Color("5a3328"))
		Px.line(img, Vector2i(t + Vector2(3, 1)), Vector2i(t + Vector2(4, 5)), Color("5a3328"))
		Px.rect(img, roundi(t.x) - 3, roundi(t.y) + 9, 3, 2, Color("3a4a3e"))
		Px.line(img, Vector2i(t + Vector2(-2, 1)), Vector2i(t + Vector2(bb.chest_front - 2.0, 10)), Color("1e1c18"))


## Juno "Velvet" Kade, the parlor sitter: a long plum velvet coat cinched at
## the waist over a slip dress, heeled boots, a sleek black bob with a blunt
## fringe, and a reading port at the nape that glows faintly when it's in use.
static func _velvet(b: Figure.Build) -> void:
	b.proportion(Vector2i(46, 98), 0.94, 20.0)
	b.chest_front = 7.5
	b.chest_back = 6.0
	b.waist_front = 4.5
	b.waist_back = 4.3
	b.groin = 5.0
	b.seat = 7.2
	b.hem_y = b.ankle_y - 18.0
	b.collar = true
	b.heel = 2.0
	b.leg_w = [4.4, 3.0, 2.8, 1.5]
	b.calf = 2.2
	b.arm_w = [2.1, 1.8, 1.3]
	b.coat = Color("3a1d33")
	b.coat_lit = Color("62305a")
	b.coat_shade = Color("27131f")
	b.coat_deep = Color("170a13")
	b.inner = Color("4a2440")
	b.pants = Color("2a2025")
	b.pants_far = Color("1c1519")
	b.boot = Color("0a0709")
	b.skin = Color("8a6a62")
	b.skin_shade = Color("5c4643")
	b.hand = Color("5c4643")
	b.hand_lit = Color("b48a7c")
	b.neck = Rect2i(2, 7, 4, 4)
	b.head = [
		".rrrrhh..",
		"rhhhhhhhw",
		"rhhhhhhhw",
		"rhhhhhhs.",
		"rhhhhdsw.",
		"rhhhhSsss",
		"rhhhhSlw.",
		"rhhhhhSw.",
		".Q...SS..",
	]
	b.head_key = _key({"h": Color("0b0a10"), "s": b.skin, "S": b.skin_shade, "l": Color("5a2438"), "Q": P.MAGENTA,
		"w": Color("b98c78"), "r": Color("6a4a78")})
	b.glow_keys = "Q"
	b.props_glow = func(img: Image, _b: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		if p.walking:
			return
		var h: Vector2 = j["near_hand"]
		Px.dot(img, roundi(h.x) + 2, roundi(h.y) - 1, P.AMBER)
		Px.dot(img, roundi(h.x) + 3, roundi(h.y) - 2 - (p.frame % 2), Color(P.RAIN, 0.4))


## Pell, the black-market seller: stooped and heavy-set, thin grey hair and
## stubble, a head rig with a cluster of lenses over one eye and two antenna
## stubs (the signal optic comes from this rig), a many-pocketed vest over a
## hoodie, a satchel on a strap across the chest.
static func _pell(b: Figure.Build) -> void:
	b.proportion(Vector2i(54, 98), 0.92, 24.0)
	b.chest_front = 8.8
	b.chest_back = 8.5
	b.waist_front = 8.5
	b.waist_back = 6.3
	b.groin = 7.0
	b.seat = 8.0
	b.hem_y = b.hip_y + 8.0
	b.collar = false
	b.belt = false
	b.leg_w = [5.2, 3.8, 3.6, 2.3]
	b.calf = 2.7
	b.arm_w = [3.0, 2.5, 2.0]
	b.coat = Color("3b3a2f")
	b.coat_lit = Color("57564a")
	b.coat_shade = Color("29281f")
	b.coat_deep = Color("191812")
	b.inner = Color("252830")
	b.pants = Color("1d1e24")
	b.pants_far = Color("131418")
	b.skin = Color("80655c")
	b.skin_shade = Color("554340")
	b.hand = Color("2a2624")
	b.hand_lit = Color("8a7060")
	b.neck = Rect2i(1, 6, 5, 4)
	b.head = [
		".rrrrr...",
		"rhhhhhhw.",
		"rqqqqqqqq",
		"rhhhSOOOO",
		"rhheSOAOO",
		"rhheSSOss",
		"rhSSSzzw.",
		".rSzzzzw.",
		"...zzzz..",
	]
	b.head_key = _key({"h": Color("4a4a4e"), "q": Color("22262c"), "O": Color("2c333c"), "A": P.AMBER,
		"s": b.skin, "S": b.skin_shade})
	b.glow_keys = "A"
	b.props_front = func(img: Image, bb: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		var t: Vector2 = j["top"]
		var at: Vector2 = j["head"]
		# Antenna stubs off the back of the rig.
		Px.line(img, Vector2i(at + Vector2(2, 2)), Vector2i(at + Vector2(0, -2)), Color("22262c"))
		Px.line(img, Vector2i(at + Vector2(4, 2)), Vector2i(at + Vector2(3, -1)), Color("22262c"))
		# Vest pockets, the satchel strap and the bag at the hip.
		for i: int in range(3):
			Px.rect(img, roundi(t.x) + 1 + (i % 2) * 2, roundi(t.y) + 4 + i * 5, 2, 2, bb.coat_shade)
		Px.line(img, Vector2i(t + Vector2(3, 0)), Vector2i(roundi(bb.cx) - 6, roundi(bb.hip_y) + p.bob), Color("2a2018"))
		Px.rect(img, roundi(bb.cx) - 9, roundi(bb.hip_y) - 2 + p.bob, 6, 6, Color("3a2a1e"))
		Px.rect(img, roundi(bb.cx) - 9, roundi(bb.hip_y) - 2 + p.bob, 6, 2, Color("2a1e15"))
	b.props_glow = func(img: Image, _b: Figure.Build, p: Figure.Pose, j: Dictionary[String, Vector2]) -> void:
		var at: Vector2 = j["head"]
		Px.dot(img, roundi(at.x) + 0, roundi(at.y) - 2, Color(P.AMBER, 0.7 if p.frame % 2 == 0 else 0.3))
		if is_nan(p.near_hand.x):
			return
		# The chip he's checking.
		var h: Vector2 = j["near_hand"]
		Px.rect(img, roundi(h.x), roundi(h.y) - 2, 2, 2, P.STEEL)
		Px.dot(img, roundi(h.x) + 1, roundi(h.y) - 2, P.CYAN)
