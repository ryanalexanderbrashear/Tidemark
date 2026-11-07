extends GdUnitTestSuite
## The Halcyon Reach concept view: fits the game's resolution, draws the same
## every time, keeps blood red out, and keeps to the city canon (separate
## arcologies, several in the Crown, no single tower ruling the skyline).


func test_the_view_is_the_game_resolution() -> void:
	assert_that(CityArt.compose().get_size()).is_equal(Vector2i(640, 360))


func test_the_city_draws_the_same_every_time() -> void:
	assert_bool(CityArt.compose(true).get_data() == CityArt.compose(true).get_data()).is_true()


func test_no_blood_red_in_the_city() -> void:
	var img: Image = CityArt.compose(true)
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			assert_bool(img.get_pixel(x, y).is_equal_approx(ArtPalette.BLOOD)).is_false()


func test_several_arcologies_rise_above_the_fog_line() -> void:
	# The Crown is the tops of the tallest arcologies, more than one corporation's.
	var crown: Array[int] = CityArt.crown()
	assert_int(crown.size()).is_greater_equal(3)


func test_no_single_tower_rules_the_skyline() -> void:
	# Not Midgar: no one central tower. The tallest in frame isn't in the middle
	# third, and another Crown is within 30 px of its height.
	var tops: Array[int] = []
	var tallest: int = -1
	for i: int in CityArt.crown():
		var top: int = CityArt.ARCOLOGIES[i][3]
		if top < 0:
			continue  # the near one, cropped by the frame
		tops.append(top)
		if tallest < 0 or top < int(CityArt.ARCOLOGIES[tallest][3]):
			tallest = i
	tops.sort()
	assert_int(tops[1] - tops[0]).is_less_equal(30)
	var x: int = CityArt.ARCOLOGIES[tallest][0]
	assert_bool(x > 213 and x < 427).is_false()


func test_arcology_decks_are_separate() -> void:
	# Each Waterline deck stands apart on its own stilts with open water between
	# it and its neighbours at the same distance; causeways join them, never one
	# continuous deck.
	var n: int = CityArt.ARCOLOGIES.size()
	for i: int in range(n):
		for j: int in range(i + 1, n):
			if absf(CityArt.depth_of(i) - CityArt.depth_of(j)) > 0.2:
				continue
			if CityArt.ARCOLOGIES[i][4] == "sunk" or CityArt.ARCOLOGIES[j][4] == "sunk":
				continue  # the sunk one has no deck left
			var gap: int = absi(int(CityArt.ARCOLOGIES[i][0]) - int(CityArt.ARCOLOGIES[j][0])) - (CityArt.deck_width(i) + CityArt.deck_width(j)) / 2
			assert_int(gap).is_greater(8)


func test_each_crown_is_a_walled_garden() -> void:
	# The Crown's terraces are walled, much wider than their shafts, with trees
	# showing over the wall (checked on each arcology drawn alone, before fog).
	for i: int in CityArt.crown():
		if CityArt.ARCOLOGIES[i][4] == "near":
			continue
		var img: Image = Px.blank(CityArt.VIEW.x, CityArt.VIEW.y)
		CityArt._arcology(img, i)
		assert_int(CityArt.crown_width(i)).is_greater(int(CityArt.ARCOLOGIES[i][2]) * 3 / 2)
		var cx: int = CityArt.ARCOLOGIES[i][0]
		var half: int = CityArt.crown_width(i) / 2
		var leaves: int = 0
		for y: int in range(CityArt.rim_y(i) - 8, CityArt.rim_y(i)):
			for x: int in range(cx - half, cx + half):
				if img.get_pixel(x, y).is_equal_approx(CityArt.LEAF):
					leaves += 1
		assert_int(leaves).is_greater(10)


func test_each_crown_is_carried_by_its_shaft() -> void:
	# No terrace floats: the shaft runs unbroken from under each Crown down to
	# its deck, right where the struts land on either side.
	for i: int in CityArt.crown():
		if CityArt.ARCOLOGIES[i][4] == "near":
			continue
		var img: Image = Px.blank(CityArt.VIEW.x, CityArt.VIEW.y)
		CityArt._arcology(img, i)
		var under: int = CityArt.rim_y(i) + CityArt.wall_height(i) + CityArt.flare_height(i)
		for side: int in [-1, 1]:
			var x: int = CityArt.strut_foot_x(i, side) - side
			for y: int in range(under, CityArt.deck_y(i)):
				assert_float(img.get_pixel(x, y).a).override_failure_message(
					"arcology %d: gap in the shaft at (%d, %d)" % [i, x, y]).is_greater(0.9)


func test_the_steeple_stands_in_open_water() -> void:
	# Port Patience's steeple is the landmark: it stands between the arcologies,
	# not behind or on a deck, so it reads on the skyline.
	var x0: int = CityArt.STEEPLE.x
	var x1: int = x0 + 12
	for i: int in range(CityArt.ARCOLOGIES.size()):
		if absf(CityArt.depth_of(i) - 0.55) > 0.2 or CityArt.ARCOLOGIES[i][4] == "sunk":
			continue
		var cx: int = CityArt.ARCOLOGIES[i][0]
		var half: int = CityArt.deck_width(i) / 2
		assert_bool(x1 < cx - half or x0 > cx + half).is_true()


func test_one_arcology_is_sinking_and_left_out_of_the_crown() -> void:
	# The dead arcology going down in the distance has no Crown any more.
	var sunk: Array[int] = []
	for i: int in range(CityArt.ARCOLOGIES.size()):
		if CityArt.ARCOLOGIES[i][4] == "sunk":
			sunk.append(i)
	assert_int(sunk.size()).is_equal(1)
	assert_bool(sunk[0] in CityArt.crown()).is_false()
