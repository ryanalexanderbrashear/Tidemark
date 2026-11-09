extends GdUnitTestSuite
## The market's art: layers fit the room, sprites stand on the walkway, and
## blood red stays where the Look and Feel doc wants it (on blood, nowhere else).


func test_each_layer_is_wide_enough_for_its_parallax() -> void:
	assert_int(MarketArt.city().get_width()).is_equal(MarketArt.layer_width("city"))
	assert_int(MarketArt.arcology().get_width()).is_equal(MarketArt.layer_width("arcology"))
	assert_int(MarketArt.shanties().get_width()).is_equal(MarketArt.layer_width("shanties"))
	assert_int(MarketArt.front().get_width()).is_equal(MarketArt.layer_width("front"))
	assert_int(MarketArt.market().get_width()).is_equal(MarketArt.ROOM.x)


func test_the_market_draws_the_same_every_time() -> void:
	assert_bool(MarketArt.market().get_data() == MarketArt.market().get_data()).is_true()


func test_blood_red_only_appears_at_vale_stall() -> void:
	var img: Image = MarketArt.market()
	var found: int = 0
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			if img.get_pixel(x, y).is_equal_approx(ArtPalette.BLOOD):
				found += 1
				assert_int(x).is_between(MarketArt.STALL_X, MarketArt.STALL_X + MarketArt.STALL_W)
	assert_int(found).is_greater(0)


func test_each_fog_band_fits_the_layer_it_sits_in_front_of() -> void:
	for band: String in FogArt.BANDS:
		var behind: String = FogArt.BANDS[band][0]
		assert_float(MarketArt.PARALLAX[band]).is_equal(MarketArt.PARALLAX[behind])
		assert_int(FogArt.band(band).get_width()).is_equal(MarketArt.layer_width(behind))
	assert_int(FogArt.signs().get_width()).is_equal(MarketArt.layer_width("signs"))


func test_fog_stays_behind_the_play_space() -> void:
	# Look and Feel: thick fog sits behind the walkway, so footing and clues stay clear.
	for band: String in FogArt.BANDS:
		assert_float(MarketArt.PARALLAX[band]).is_less(MarketArt.PARALLAX["market"])


func test_fog_never_turns_blood_red() -> void:
	# Fog takes the color of the light inside it, but blood red is kept for blood.
	for band: String in FogArt.BANDS:
		var img: Image = FogArt.band(band)
		for y: int in range(0, img.get_height(), 2):
			for x: int in range(0, img.get_width(), 2):
				var c: Color = img.get_pixel(x, y)
				if c.a > 0.0:
					assert_bool(Color(c, 1.0).is_equal_approx(ArtPalette.BLOOD)).is_false()


func test_fog_is_thicker_near_the_water() -> void:
	for band: String in FogArt.BANDS:
		var spec: Array = FogArt.BANDS[band]
		assert_float(FogArt._band_alpha(spec[2], spec[1], spec[2], spec[3], spec[4])).is_greater(FogArt._band_alpha(spec[1], spec[1], spec[2], spec[3], spec[4]))


func test_wisps_wrap_so_fog_can_drift_forever() -> void:
	for band: String in FogArt.BANDS:
		assert_int(FogArt.wisps(band).get_width()).is_equal(FogArt.WISP_TILE)


# ---------- the closer-to-final detective ----------

func test_the_stall_is_one_screen() -> void:
	assert_vector(Vector2(StallArt.room().get_size())).is_equal(Vector2(StallArt.SIZE))
	assert_int(StallArt.SIZE.x).is_equal(ArtMarketFloor.ROOM_WIDTHS["stall"])


func test_blood_in_the_stall_is_only_around_her_head() -> void:
	assert_bool(_has_color(StallArt.room(), ArtPalette.BLOOD)).is_false()
	var body: Image = StallArt.body()
	for y: int in range(body.get_height()):
		for x: int in range(body.get_width()):
			if body.get_pixel(x, y).is_equal_approx(ArtPalette.BLOOD):
				assert_int(x).is_less(40)


func test_the_heat_seam_is_a_door_outline() -> void:
	var seam: Image = MarketArt.heat_seam()
	assert_float(seam.get_pixel(0, seam.get_height() / 2).a).is_greater(0.5)
	assert_float(seam.get_pixel(10, seam.get_height() / 2).a).is_equal(0.0)


func _has_color(img: Image, c: Color) -> bool:
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			if img.get_pixel(x, y).is_equal_approx(c):
				return true
	return false


func _count(img: Image, from_y: int, to_y: int) -> int:
	var n: int = 0
	for y: int in range(from_y, to_y):
		for x: int in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.5:
				n += 1
	return n
