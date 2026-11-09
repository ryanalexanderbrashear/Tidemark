extends GdUnitTestSuite
## The art test's dialogue box and case board: they play the case's own Talks
## and commit theories through `Case`, the same as the prototype's.


func before_test() -> void:
	Mind.reset()
	ArtMarketFloor.start_case()
	# As if back from Vale's stall with her ledger read.
	Case.find_clue("ledger")


func after_test() -> void:
	Case.reset()


func _box() -> ArtTalkBox:
	var box: ArtTalkBox = auto_free(ArtTalkBox.new())
	add_child(box)
	return box


func test_a_choice_leads_to_the_next_talk() -> void:
	var box: ArtTalkBox = _box()
	box.show_talk(Talk.say("A", "First.", [TalkOption.make("On", func() -> Talk: return Talk.say("B", "Second."))]))
	box.pick(0)
	assert_bool(box.visible).is_true()
	assert_str(box.talk.speaker).is_equal("B")


func test_a_closing_choice_closes_the_box() -> void:
	var box: ArtTalkBox = _box()
	var closed: Array[bool] = []
	box.closed.connect(func() -> void: closed.append(true))
	box.show_talk(Talk.say("A", "Only line."))
	box.pick(0)
	assert_bool(box.visible).is_false()
	assert_int(closed.size()).is_equal(1)


func test_the_line_types_out_and_can_be_finished() -> void:
	var box: ArtTalkBox = _box()
	box.show_talk(Talk.say("A", "A line long enough to take a moment to type."))
	assert_bool(box.is_typing()).is_true()
	box.finish_typing()
	assert_bool(box.is_typing()).is_false()


func test_talking_to_osk_through_the_box_finds_his_clue() -> void:
	var box: ArtTalkBox = _box()
	var market_floor: ArtMarketFloor = ArtMarketFloor.new()
	box.show_talk(market_floor.nearest("market", ArtMarketFloor.OSK_X).use())
	assert_bool(Case.has_clue("rival")).is_true()
	box.pick(0)
	assert_bool(box.visible).is_false()
	market_floor.release()


func _board() -> ArtBoard:
	var board: ArtBoard = auto_free(ArtBoard.new())
	add_child(board)
	board.open()
	return board


func test_the_board_pins_a_card_for_every_clue() -> void:
	Case.find_clue("rival")
	var board: ArtBoard = _board()
	assert_int(board._clue_cards.size()).is_equal(Case.clues.size())
	assert_bool(board._theory_cards.has("stolen")).is_true()


func test_committing_on_the_board_goes_through_the_case() -> void:
	Case.find_clue("rival")
	var board: ArtBoard = _board()
	var held: Array[String] = []
	board.committed.connect(func(id: String) -> void: held.append(id))
	assert_bool(board.can_commit()).is_false()
	board.toggle_clue("ledger", true)
	board.toggle_clue("rival", true)
	board.pick_theory("stolen")
	assert_int(board.commit()).is_equal(TheoryCheck.Result.HOLDS)
	assert_bool(Case.has_fact("stolen")).is_true()
	assert_array(held).contains_exactly(["stolen"])
	# A fact can't be committed twice.
	assert_bool(board.can_commit()).is_false()


func test_a_theory_that_does_not_hold_changes_nothing() -> void:
	Case.find_clue("rival")
	var board: ArtBoard = _board()
	board.toggle_clue("ledger", true)
	board.pick_theory("stolen")
	assert_int(board.commit()).is_equal(TheoryCheck.Result.NOT_ENOUGH)
	assert_bool(Case.has_fact("stolen")).is_false()


func test_the_board_art_is_one_frame() -> void:
	assert_vector(Vector2(ArtBoard.board_image().get_size())).is_equal(Vector2(640, 360))
