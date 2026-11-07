extends GdUnitTestSuite
## The art test's playable market floor: its spots are the case's own market
## spots, each stands where the art draws it, and the slice can be played
## through to both deductions it holds (who Vale was really selling to, and
## what the etching is) with only what's on this floor and in the pockets.

var market_floor: ArtMarketFloor


func before_test() -> void:
	Mind.reset()
	ArtMarketFloor.start_case()
	market_floor = ArtMarketFloor.new()


func after_test() -> void:
	market_floor.release()
	Case.reset()


func _use(id: String) -> Talk:
	var s: Spot = market_floor.nearest(ArtMarketFloor.PLACES[id].x)
	assert_object(s).override_failure_message("nothing usable at %s" % id).is_not_null()
	assert_str(s.id).is_equal(id)
	return s.use()


func test_every_drawn_spot_is_one_of_the_case_market_spots() -> void:
	var market: DrownedMarket = DrownedMarket.new()
	for id: String in ArtMarketFloor.PLACES:
		var s: Spot = market.spot(id)
		assert_object(s).override_failure_message("no spot %s" % id).is_not_null()
		assert_str(s.room).is_equal("market")
	assert_int(market_floor.spots.size()).is_equal(ArtMarketFloor.PLACES.size())


func test_spots_stand_in_the_room_and_their_reach_never_overlaps() -> void:
	var ids: Array[String] = []
	ids.assign(ArtMarketFloor.PLACES.keys())
	ids.sort_custom(func(a: String, b: String) -> bool: return ArtMarketFloor.PLACES[a].x < ArtMarketFloor.PLACES[b].x)
	for i: int in range(ids.size()):
		var p: Vector2 = ArtMarketFloor.PLACES[ids[i]]
		assert_float(p.x - p.y).is_greater(20.0)
		assert_float(p.x + p.y).is_less(float(MarketArt.ROOM.x - 20))
		if i > 0:
			var q: Vector2 = ArtMarketFloor.PLACES[ids[i - 1]]
			assert_float(q.x + q.y + ArtMarketFloor.REACH).override_failure_message("%s and %s overlap" % [ids[i - 1], ids[i]]).is_less(p.x - p.y - ArtMarketFloor.REACH)


func test_nothing_to_use_where_the_detective_starts() -> void:
	assert_object(market_floor.nearest(ArtMarketFloor.START_X)).is_null()


func test_the_slice_starts_just_out_of_vale_stall() -> void:
	assert_str(Case.room).is_equal("market")
	assert_bool(Case.has_clue("ledger")).is_true()
	assert_bool(Case.has_beat("body_examined")).is_true()
	# The chip is in his pocket, but its etching hasn't been found yet.
	assert_bool(Case.has_clue("chip")).is_false()


func test_the_chip_etching_is_the_calling_card_clue() -> void:
	var chip: ExamineItem = ExamineItem.chip()
	assert_str(chip.clue).is_equal("chip")
	assert_bool(CaseCatalog.has_clue(chip.clue)).is_true()
	# Items that aren't from the case hand it nothing.
	assert_str(ExamineItem.tin().clue).is_equal("")


func test_finding_the_etching_tells_the_scene() -> void:
	var view: ExamineView = auto_free(ExamineView.new())
	add_child(view)
	var heard: Array[String] = []
	view.detail_found.connect(func(it: ExamineItem) -> void: heard.append(it.id))
	view.open(0)
	view.set_turn(Basis(Vector3.UP, PI))
	view.check_found(ExamineView.FOUND_HOLD)
	view.check_found(ExamineView.FOUND_HOLD)
	assert_array(heard).contains_exactly(["chip"])


func test_the_fixer_gate_opens_from_this_floor_alone() -> void:
	_use("osk")
	assert_bool(Case.has_clue("rival")).is_true()
	assert_int(Case.commit_theory("stolen", ["ledger", "rival"])).is_equal(TheoryCheck.Result.HOLDS)
	var t: Talk = _use("fixer").choose("really selling to")
	t = t.choose("Osk")
	assert_bool(Case.is_set("fixer_vouched")).is_false()
	_use("fixer").choose("really selling to").choose("J. Reyka")
	assert_bool(Case.is_set("fixer_vouched")).is_true()
	# The back room now leads on to Cold Storage (a room the art test hasn't drawn).
	_use("back_room")
	assert_str(Case.room).is_equal("cold")


func test_the_etching_deduction_needs_the_chip_turned_over_first() -> void:
	assert_object(_use("fixer").option("chip etching")).is_null()
	Case.find_clue("chip")
	_use("fixer").choose("chip etching")
	_use("tech").choose("tunnels")
	assert_int(Case.commit_theory("catalog", ["fixerfmt", "tech"])).is_equal(TheoryCheck.Result.HOLDS)
	assert_bool(Case.has_beat("catalog_deduced")).is_true()


func test_the_cams_give_the_footage_with_a_badge() -> void:
	_use("cams")
	assert_bool(Case.has_clue("footage")).is_true()


func test_doors_out_say_the_room_is_not_drawn() -> void:
	assert_str(market_floor.unbuilt_room_line("stall")).contains("Vale's stall")


func test_prompts_name_the_spot() -> void:
	assert_str(ArtMarketFloor.prompt(market_floor.market.spot("osk"))).is_equal("E  Osk, rival broker")
