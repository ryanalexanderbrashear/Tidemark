class_name MarketScene
extends RoomScene
## The Drowned Market's floor, drawn (MarketArt, FogArt): sky, far city, neon
## signs and the arcology through stepped fog, the shanties, the market with
## Vale's taped-off stall under its failing lamp, the water and rain. Osk, the
## fixer and the maintenance tech stand at their spots, and Vale's passenger
## at the fog's edge while she's with him.
##
## The thermal optic sees heat through fog, so the fog falls away while it's
## on, and the heat-sealed door to Cold Storage shows as a glowing seam.

const P = preload("res://game/art/art_palette.gd")
const WATER_SHADER = preload("res://game/art/water.gdshader")
const SEAM_HEAT: float = 0.8
## Who stands on the market floor, with the animation they play.
const CAST_ANIMS: Dictionary[String, String] = {"osk": "idle", "fixer": "idle", "tech": "work", "vale": "passenger"}

## The case's market, to ask whether her passenger and the seam show.
var market: DrownedMarket

var layers: Dictionary[String, Sprite2D] = {}
var wisps: Dictionary[String, Sprite2D] = {}
var people: Dictionary[String, CastSprite] = {}
var holo: Sprite2D
var lamp: Sprite2D
var water: ColorRect
var rain: ArtRain
var seam: Sprite2D
var _rain_layer: CanvasLayer
var _holo_frames: Array[ImageTexture] = []


func _init(case_market: DrownedMarket = null) -> void:
	id = "market"
	market = case_market
	width = MarketArt.ROOM.x
	outdoors = true
	lamp_x = MarketArt.STALL_X + MarketArt.STALL_W * 0.5


func _draw() -> void:
	layers["sky"] = sprite(MarketArt.sky(), back)
	layers["city"] = sprite(MarketArt.city(), back)
	_fog_band("fog_far")
	layers["signs"] = sprite(FogArt.signs(), back)
	_fog_band("fog_signs")
	layers["arcology"] = sprite(MarketArt.arcology(), back)
	_fog_band("fog_mid")
	layers["shanties"] = sprite(MarketArt.shanties(), back)
	_fog_band("fog_low")
	for f: int in range(8):
		_holo_frames.append(ImageTexture.create_from_image(MarketArt.hologram(f)))
	holo = Sprite2D.new()
	holo.centered = false
	holo.material = additive()
	back.add_child(holo)
	layers["market"] = sprite(MarketArt.market(), play)

	lamp = sprite(_lamp_image(), play)
	lamp.material = additive()
	for who: String in CAST_ANIMS:
		var anims: Array[String] = [CAST_ANIMS[who]]
		var s: CastSprite = CastSprite.new(who, anims)
		play.add_child(s)
		people[who] = s
	# Osk and the fixer face left, toward Vale's stall; the cast is drawn facing
	# right.
	people["osk"].flip_h = true
	people["fixer"].flip_h = true
	for who: String in ["osk", "fixer", "tech"]:
		warm(people[who])

	water = ColorRect.new()
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("back_tex", view.back.get_texture())
	# The water shader reads the play viewport's own pixels, base frame at
	# PixelView.MARGIN.
	mat.set_shader_parameter("view_size", Vector2(PixelView.MAX_VIEW))
	water.material = mat
	water.size = Vector2(PixelView.NATIVE)
	over.add_child(water)
	layers["front"] = sprite(MarketArt.front(), over)

	_rain_layer = CanvasLayer.new()
	_rain_layer.offset = Vector2(PixelView.MARGIN)
	view.play.add_child(_rain_layer)
	rain = ArtRain.new()
	rain.view_size = PixelView.NATIVE
	_rain_layer.add_child(rain)
	rain.reset()

	seam = view.heat_sprite(SEAM_HEAT)
	seam.texture = ImageTexture.create_from_image(MarketArt.heat_seam())


## A stepped fog band and the wisps that drift across it.
func _fog_band(band: String) -> void:
	layers[band] = sprite(FogArt.band(band), back)
	var w: Sprite2D = sprite(FogArt.wisps(band), back)
	w.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	w.region_enabled = true
	wisps[band] = w


## The lamp over Vale's stall, on its own so it can stutter.
func _lamp_image() -> Image:
	var img: Image = Px.blank(MarketArt.STALL_W + 40, 90)
	Px.glow(img, img.get_width() * 0.5, 22, MarketArt.STALL_W * 0.45, 40, P.AMBER, 0.18)
	Px.rect(img, img.get_width() / 2 - 4, 2, 8, 2, P.AMBER)
	return img


func set_shown(on: bool) -> void:
	super.set_shown(on)
	if _rain_layer != null:
		_rain_layer.visible = on
	if seam != null and not on:
		seam.visible = false


func update(cam: float, time: float, fog: int) -> void:
	var max_scroll: float = float(MarketArt.ROOM.x - MarketArt.VIEW.x)
	for layer: String in layers:
		var factor: float = MarketArt.PARALLAX[layer]
		# Back layers are drawn for the 640-wide view; keep them centred on it.
		var lx: float = -floorf(cam * factor) if layer == "market" else -floorf(cam / max_scroll * max_scroll * factor)
		if layer == "sky":
			lx = 0.0
		layers[layer].position = Vector2(lx, 0)
	var market_x: float = -cam
	lamp.position = Vector2(market_x + MarketArt.STALL_X - 20, MarketArt.WALK_Y - 128 + 6)
	# A failing tube: mostly on, sometimes off for a beat.
	var flick: float = sin(time * 23.0) + sin(time * 7.3)
	lamp.visible = flick > -1.4
	lamp_on = lamp.visible
	holo.texture = _holo_frames[int(time * 8.0) % _holo_frames.size()]
	holo.position = Vector2(market_x + 602, 58)
	holo.modulate.a = 0.85 if fmod(time, 3.7) > 0.12 else 0.3
	_update_fog(time, fog)

	people["osk"].play_at("idle", time)
	people["osk"].place(RoomLayout.OSK_X, walk_y, cam)
	people["fixer"].play_at("idle", time, 1)
	people["fixer"].place(RoomLayout.FIXER_X, walk_y, cam)
	# The tech works the wrench a notch at a time.
	people["tech"].play_at("work", time)
	people["tech"].place(RoomLayout.TECH_X, walk_y, cam)
	# Her passenger, at the fog's edge: only while she's with him, never quite
	# steady.
	var vale: CastSprite = people["vale"]
	var vale_spot: Spot = market.spot("passenger_vale") if market != null else null
	vale.visible = vale_spot != null and vale_spot.is_visible()
	vale.play_at("passenger", time)
	vale.modulate.a = 0.72 if fmod(time * 1.3, 5.0) > 0.25 else 0.35
	vale.place(RoomLayout.VALE_X, walk_y, cam)

	water.position = Vector2(0, MarketArt.WATER_Y)
	(water.material as ShaderMaterial).set_shader_parameter("line_y", float(MarketArt.WATER_Y + PixelView.MARGIN.y))
	rain.walk_y = MarketArt.WALK_Y
	rain.water_y = MarketArt.WATER_Y

	var door: Spot = market.spot("heat_door") if market != null else null
	seam.visible = play.visible and door != null and door.is_visible()
	seam.position = Vector2(floorf(RoomLayout.HEAT_DOOR_X - 22.0 - cam), MarketArt.WALK_Y - MarketArt.DOOR_H)


func _update_fog(time: float, fog: int) -> void:
	# The thermal optic sees heat through fog, so the fog falls away.
	var stepped: bool = fog == Fog.STEPPED and not Case.optic_on
	for band: String in FogArt.BANDS:
		layers[band].visible = stepped
		var w: Sprite2D = wisps[band]
		w.visible = stepped
		w.position = layers[band].position
		var drift: float = floorf(time * FogArt.DRIFT[band])
		w.region_rect = Rect2(-drift, 0, MarketArt.layer_width(band), MarketArt.VIEW.y)
	var volumetric: bool = fog == Fog.VOLUMETRIC and not Case.optic_on
	view.set_volumetric(volumetric, float(MarketArt.WATER_Y), fog_lights() if volumetric else [])


## The same lights the stepped fog is tinted by, moved to the screen:
## [positions, colours] for PixelView.set_volumetric.
func fog_lights() -> Array:
	var pos: PackedVector4Array = []
	var col: PackedVector4Array = []
	var view_w: float = float(PixelView.NATIVE.x)
	var signs_at: Vector2 = layers["signs"].position
	for s: Array in FogArt.SIGNS:
		var l: Vector3 = FogArt.sign_light(s)
		var c: Color = FogArt.sign_color(s[3])
		var at: Vector2 = signs_at + Vector2(l.x, l.y)
		if at.x > -80.0 and at.x < view_w + 80.0:
			pos.append(Vector4(at.x, at.y, l.z * 1.3, 0.32))
			col.append(Vector4(c.r, c.g, c.b, 1.0))
	var arc_at: Vector2 = layers["arcology"].position
	for g: Array in FogArt.lights("fog_mid"):
		var at: Vector2 = arc_at + Vector2(g[0], g[1])
		if at.x > -60.0 and at.x < view_w + 60.0 and pos.size() < PixelView.MAX_LIGHTS:
			var c: Color = g[3]
			pos.append(Vector4(at.x, at.y, 150.0, 0.09))
			col.append(Vector4(c.r, c.g, c.b, 2.0))
	if pos.size() < PixelView.MAX_LIGHTS:
		var h: Vector2 = holo.position + Vector2(48, 44)
		pos.append(Vector4(h.x, h.y, 60.0, 0.18))
		col.append(Vector4(P.CYAN.r, P.CYAN.g, P.CYAN.b, 1.0))
	return [pos, col]
