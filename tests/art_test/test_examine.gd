extends GdUnitTestSuite
## The examine test: items are built to the right size, hidden details stay
## hidden until the item is turned over, items open only once their catch is
## found, and the close-up keeps to the palette.


func test_every_face_image_fits_its_face() -> void:
	var every: Array[ExamineItem] = ExamineItem.all()
	every.append(ExamineItem.slip())
	for it: ExamineItem in every:
		for face: String in ExamineItem.FACES:
			assert_bool(it.faces.has(face)).is_true()
			assert_vector(Vector2(it.faces[face].get_size())).is_equal(Vector2(it.face_size(face)))


func test_items_come_up_front_first() -> void:
	var rest: Basis = Basis.from_euler(ExamineView.REST)
	for it: ExamineItem in ExamineItem.all():
		assert_float(ExamineItem.facing(rest, "front")).is_greater(ExamineView.FOUND_DOT)


func test_the_etching_is_hidden_until_the_chip_is_turned_over() -> void:
	var chip: ExamineItem = ExamineItem.chip()
	assert_str(chip.detail_face).is_equal("back")
	var rest: Basis = Basis.from_euler(ExamineView.REST)
	assert_float(ExamineItem.facing(rest, chip.detail_face)).is_less(0.0)
	var flipped: Basis = Basis(Vector3.UP, PI) * rest
	assert_float(ExamineItem.facing(flipped, chip.detail_face)).is_greater(ExamineView.FOUND_DOT)
	# Tipping it end over end works too.
	var tipped: Basis = Basis(Vector3.RIGHT, PI)
	assert_float(ExamineItem.facing(tipped, chip.detail_face)).is_greater(ExamineView.FOUND_DOT)


func test_the_detail_is_found_only_after_holding_it_toward_the_camera() -> void:
	var view: ExamineView = auto_free(ExamineView.new())
	add_child(view)
	view.open(0)
	view.check_found(10.0)
	assert_bool(view.found.get("chip", false)).is_false()
	view.set_turn(Basis(Vector3.UP, PI))
	view.check_found(ExamineView.FOUND_HOLD * 0.5)
	assert_bool(view.found.get("chip", false)).is_false()
	view.check_found(ExamineView.FOUND_HOLD)
	assert_bool(view.found.get("chip", false)).is_true()


func test_a_glance_at_the_back_does_not_count() -> void:
	var view: ExamineView = auto_free(ExamineView.new())
	add_child(view)
	view.open(0)
	view.set_turn(Basis(Vector3.UP, PI))
	view.check_found(ExamineView.FOUND_HOLD * 0.6)
	view.set_turn(Basis.IDENTITY)
	view.check_found(0.01)
	view.set_turn(Basis(Vector3.UP, PI))
	view.check_found(ExamineView.FOUND_HOLD * 0.6)
	assert_bool(view.found.get("chip", false)).is_false()


func test_the_etching_is_drawn_on_the_back_only() -> void:
	var chip: ExamineItem = ExamineItem.chip()
	assert_int(_count(chip.faces["back"], ArtPalette.RAIN, Rect2i(56, 56, 48, 14))).is_greater(20)
	assert_int(_count(chip.faces["front"], ArtPalette.RAIN, Rect2i(56, 56, 48, 14))).is_less(5)


func test_close_ups_never_snap_to_blood_red() -> void:
	var blood: Vector3 = Vector3(ArtPalette.BLOOD.r, ArtPalette.BLOOD.g, ArtPalette.BLOOD.b)
	var pal: PackedVector3Array = ExamineView.palette_vectors()
	assert_int(pal.size()).is_less_equal(32)
	assert_bool(blood in pal).is_false()


func test_the_tin_only_opens_once_its_catch_is_found() -> void:
	var view: ExamineView = auto_free(ExamineView.new())
	add_child(view)
	view.open(2)
	assert_str(view.current().id).is_equal("tin")
	view.use()
	assert_bool(view.opened.get("tin", false)).is_false()
	# The catch is on the right edge: turn that edge to the camera.
	view.set_turn(Basis(Vector3.UP, -PI * 0.5))
	view.check_found(ExamineView.FOUND_HOLD)
	assert_bool(view.can_open()).is_true()
	view.use()
	assert_bool(view.opened.get("tin", false)).is_true()


func test_whats_inside_can_be_taken_out_once() -> void:
	var view: ExamineView = auto_free(ExamineView.new())
	add_child(view)
	view.open(2)
	var before: int = view.items.size()
	view.found["tin"] = true
	view.use()
	view.use()
	assert_int(view.items.size()).is_equal(before + 1)
	assert_str(view.current().id).is_equal("slip")
	view.open(2)
	assert_bool(view.can_take_out()).is_false()
	view.use()
	assert_int(view.items.size()).is_equal(before + 1)


func test_the_catch_is_hidden_when_the_tin_comes_up() -> void:
	var rest: Basis = Basis.from_euler(ExamineView.REST)
	assert_float(ExamineItem.facing(rest, ExamineItem.tin().detail_face)).is_less(ExamineView.FOUND_DOT)


func _count(img: Image, c: Color, area: Rect2i) -> int:
	var n: int = 0
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if img.get_pixel(x, y).is_equal_approx(c):
				n += 1
	return n
