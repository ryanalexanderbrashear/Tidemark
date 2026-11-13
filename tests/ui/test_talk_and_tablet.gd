extends GdUnitTestSuite
## The dialogue box and the evidence tablet: they play the case's own Talks
## and file theories through `Case`.


func before_test() -> void:
	Mind.reset()
	ArtTest.start_case()
	# As if back from Vale's stall with her ledger read.
	Case.find_clue("ledger")


func after_test() -> void:
	Case.reset()


func _box() -> TalkBox:
	var box: TalkBox = auto_free(TalkBox.new())
	add_child(box)
	return box


func test_a_choice_leads_to_the_next_talk() -> void:
	var box: TalkBox = _box()
	box.show_talk(Talk.say("A", "First.", [TalkOption.make("On", func() -> Talk: return Talk.say("B", "Second."))]))
	box.pick(0)
	assert_bool(box.visible).is_true()
	assert_str(box.talk.speaker).is_equal("B")


func test_a_closing_choice_closes_the_box() -> void:
	var box: TalkBox = _box()
	var closed: Array[bool] = []
	box.closed.connect(func() -> void: closed.append(true))
	box.show_talk(Talk.say("A", "Only line."))
	box.pick(0)
	assert_bool(box.visible).is_false()
	assert_int(closed.size()).is_equal(1)


func test_the_line_types_out_and_can_be_finished() -> void:
	var box: TalkBox = _box()
	box.show_talk(Talk.say("A", "A line long enough to take a moment to type."))
	assert_bool(box.is_typing()).is_true()
	box.finish_typing()
	assert_bool(box.is_typing()).is_false()


func test_talking_to_osk_through_the_box_finds_his_clue() -> void:
	var box: TalkBox = _box()
	var market_floor: RoomLayout = RoomLayout.new()
	box.show_talk(market_floor.nearest("market", RoomLayout.OSK_X).use())
	assert_bool(Case.has_clue("rival")).is_true()
	box.pick(0)
	assert_bool(box.visible).is_false()
	market_floor.release()


func _tablet() -> CaseTablet:
	var tablet: CaseTablet = auto_free(CaseTablet.new())
	add_child(tablet)
	tablet.open()
	return tablet


func test_every_clue_is_a_capture_or_a_statement() -> void:
	Case.find_clue("rival")
	var tablet: CaseTablet = _tablet()
	assert_array(tablet._clue_cards.keys()).contains_exactly(["ledger"])
	tablet.show_tab(CaseTablet.Tab.STATEMENTS)
	assert_array(tablet._clue_cards.keys()).contains_exactly(["rival"])
	assert_str(tablet.viewing).is_equal("rival")


func test_picking_the_capture_on_screen_backs_a_theory() -> void:
	var tablet: CaseTablet = _tablet()
	assert_str(tablet.viewing).is_equal("ledger")
	tablet._pick.button_pressed = true
	assert_array(tablet.selected).contains_exactly(["ledger"])
	tablet._pick.button_pressed = false
	assert_array(tablet.selected).is_empty()


func test_filing_on_the_tablet_goes_through_the_case() -> void:
	Case.find_clue("rival")
	var tablet: CaseTablet = _tablet()
	tablet.show_tab(CaseTablet.Tab.THEORIES)
	assert_bool(tablet._theory_cards.has("stolen")).is_true()
	var held: Array[String] = []
	tablet.committed.connect(func(id: String) -> void: held.append(id))
	assert_bool(tablet.can_commit()).is_false()
	tablet.toggle_clue("ledger", true)
	tablet.toggle_clue("rival", true)
	tablet.pick_theory("stolen")
	assert_int(tablet.commit()).is_equal(TheoryCheck.Result.HOLDS)
	assert_bool(Case.has_fact("stolen")).is_true()
	assert_array(held).contains_exactly(["stolen"])
	assert_array(tablet.selected).is_empty()
	# A fact can't be filed twice.
	assert_bool(tablet.can_commit()).is_false()


func test_a_theory_that_does_not_hold_changes_nothing() -> void:
	Case.find_clue("rival")
	var tablet: CaseTablet = _tablet()
	tablet.toggle_clue("ledger", true)
	tablet.pick_theory("stolen")
	assert_int(tablet.commit()).is_equal(TheoryCheck.Result.NOT_ENOUGH)
	assert_bool(Case.has_fact("stolen")).is_false()


func test_it_boots_in_full_once_then_just_powers_on() -> void:
	var tablet: CaseTablet = _tablet()
	assert_bool(tablet.is_booting()).is_true()
	tablet.close()
	tablet.open()
	assert_bool(tablet.is_booting()).is_false()


func test_any_key_skips_the_boot() -> void:
	var tablet: CaseTablet = _tablet()
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	tablet._input(key)
	assert_bool(tablet.is_booting()).is_false()
	assert_bool(tablet.is_open()).is_true()


func test_the_setting_turns_the_boot_off() -> void:
	var tablet: CaseTablet = auto_free(CaseTablet.new())
	add_child(tablet)
	tablet.full_boot = false
	tablet.open()
	assert_bool(tablet.is_booting()).is_false()


func test_the_tablet_art_fits_the_frame() -> void:
	assert_vector(Vector2(TabletArt.frame().get_size())).is_equal(Vector2(640, 360))
	assert_vector(Vector2(TabletArt.glass().get_size())).is_equal(Vector2(640, 360))
	assert_vector(Vector2(TabletArt.boot().get_size())).is_equal(Vector2(TabletArt.SCREEN.size))


func test_every_clue_has_a_photo_in_the_phosphor() -> void:
	for clue: Clue in CaseCatalog.all_clues():
		var img: Image = TabletArt.photo(clue, 40, 25)
		assert_vector(Vector2(img.get_size())).is_equal(Vector2(40, 25))
		assert_bool(TabletArt.PHOTO.has(img.get_pixel(20, 12))).is_true()
