extends GdUnitTestSuite
## The style test's art: layers fit the room, sprites stand on the walkway, and
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


func test_every_walk_frame_is_different() -> void:
	var seen: Array[PackedByteArray] = []
	for f: int in range(ArtCharacters.WALK_FRAMES):
		var data: PackedByteArray = ArtCharacters.detective(f, true).get_data()
		assert_bool(data in seen).is_false()
		seen.append(data)


func test_characters_stand_on_their_bottom_rows() -> void:
	# Feet sit three rows up from the bottom, so _place can line them up on the walkway.
	for img: Image in [ArtCharacters.detective(0, false), ArtCharacters.osk(0), ArtCharacters.fixer(0), ArtCharacters.tech(0), ArtCharacters.tech(1)]:
		assert_bool(_row_has_pixels(img, img.get_height() - 3)).is_true()


func _row_has_pixels(img: Image, y: int) -> bool:
	for x: int in range(img.get_width()):
		if img.get_pixel(x, y).a > 0.5:
			return true
	return false


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

func test_detective_walk_frames_are_all_different() -> void:
	var seen: Array[PackedByteArray] = []
	for f: int in range(ArtDetective.WALK_FRAMES):
		var data: PackedByteArray = ArtDetective.walk(f).get_data()
		assert_bool(data in seen).is_false()
		seen.append(data)


func test_detective_stands_on_the_same_row_as_the_others() -> void:
	for img: Image in [ArtDetective.idle(0), ArtDetective.walk(0), ArtDetective.walk(2)]:
		assert_bool(_row_has_pixels(img, img.get_height() - 3)).is_true()
		assert_bool(_row_has_pixels(img, img.get_height() - 2)).is_false()


func test_detective_is_about_64_pixels_tall() -> void:
	# Look and Feel: about 64 px at 640x360, so his face reads.
	var img: Image = ArtDetective.idle(0)
	var top: int = 0
	while not _row_has_pixels(img, top):
		top += 1
	assert_int(img.get_height() - 3 - top + 1).is_between(62, 66)


func test_planted_foot_moves_back_at_walking_speed() -> void:
	# Walk frames are picked by distance (STRIDE / WALK_FRAMES per frame), so a
	# planted foot has to slide back by exactly that much each frame.
	var step: float = ArtDetective.STRIDE / float(ArtDetective.WALK_FRAMES)
	for f: int in range(4):
		var a: Vector2 = ArtDetective._foot(f)[0]
		var b: Vector2 = ArtDetective._foot(f + 1)[0]
		assert_float(a.x - b.x).is_equal_approx(step, 0.001)
		assert_float(a.y).is_equal(ArtDetective.ANKLE_Y)


func test_detective_implant_glows_in_every_frame() -> void:
	# The cyan iris is the one bright point on him.
	var frames: Array[Image] = []
	for f: int in range(ArtDetective.WALK_FRAMES):
		frames.append(ArtDetective.walk(f))
	for f: int in range(ArtDetective.IDLE_FRAMES):
		frames.append(ArtDetective.idle(f))
	for img: Image in frames:
		var found: bool = false
		for y: int in range(20):
			for x: int in range(img.get_width()):
				if img.get_pixel(x, y).is_equal_approx(ArtPalette.CYAN):
					found = true
		assert_bool(found).is_true()


func test_detective_has_no_blood_red() -> void:
	var img: Image = ArtDetective.walk(3)
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			assert_bool(img.get_pixel(x, y).is_equal_approx(ArtPalette.BLOOD)).is_false()


# ---------- the tall rim-lit style draft ----------

func test_tall_draft_walk_frames_are_all_different() -> void:
	var seen: Array[PackedByteArray] = []
	for f: int in range(ArtDetectiveTall.WALK_FRAMES):
		var data: PackedByteArray = ArtDetectiveTall.walk(f).get_data()
		assert_bool(data in seen).is_false()
		seen.append(data)


func test_tall_draft_stands_on_the_same_row_as_the_others() -> void:
	for img: Image in [ArtDetectiveTall.idle(0), ArtDetectiveTall.walk(0), ArtDetectiveTall.walk(2)]:
		assert_bool(_row_has_pixels(img, img.get_height() - 3)).is_true()
		assert_bool(_row_has_pixels(img, img.get_height() - 2)).is_false()


func test_tall_draft_head_is_not_too_small() -> void:
	# An 8-head first try read as a tiny head (Alex); keep it near 6.5 heads.
	var img: Image = ArtDetectiveTall.idle(0)
	var top: int = 0
	while not _row_has_pixels(img, top):
		top += 1
	var height: int = img.get_height() - 3 - top + 1
	assert_int(height).is_between(82, 90)
	assert_float(float(height) / float(ArtDetectiveTall.HEAD.size())).is_between(6.0, 7.2)


func test_tall_draft_planted_foot_moves_back_at_walking_speed() -> void:
	var step: float = ArtDetectiveTall.STRIDE / float(ArtDetectiveTall.WALK_FRAMES)
	for f: int in range(4):
		var a: Vector2 = ArtDetectiveTall._foot(f)[0]
		var b: Vector2 = ArtDetectiveTall._foot(f + 1)[0]
		assert_float(a.x - b.x).is_equal_approx(step, 0.001)


# ---------- Vale's stall and her passenger ----------

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


func test_her_passenger_comes_apart_toward_her_feet() -> void:
	var img: Image = ArtCharacters.vale(0)
	assert_int(_count(img, 30, 50)).is_greater(_count(img, img.get_height() - 12, img.get_height()) * 2)
	assert_bool(_has_color(img, ArtPalette.BLOOD)).is_false()


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
