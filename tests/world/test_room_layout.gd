extends GdUnitTestSuite
## Where the case's rooms stand in native pixels. The drawn rooms' spots are
## the case's own market and stall spots, each where the art draws it, and the
## market floor and stall play through the loop in small: the badge gate into
## the stall, the body and its reading, the passenger it leaves, the thermal
## optic's door, and both deductions on the market floor. The stand-in rooms
## keep the grey-box layout, scaled.

var market_floor: RoomLayout


func before_test() -> void:
	Mind.reset()
	ArtTest.start_case()
	market_floor = RoomLayout.new()
	# As the game plays it: the chip's etching is found by examining it.
	market_floor.market.etching_by_examining = true


func after_test() -> void:
	market_floor.release()
	Case.reset()
	Mind.reset()


func _use(room: String, id: String) -> Talk:
	var s: Spot = market_floor.nearest(room, RoomLayout.PLACES[room][id].x)
	assert_object(s).override_failure_message("nothing usable at %s" % id).is_not_null()
	assert_str(s.id).is_equal(id)
	return s.use()


func _visit_stall() -> void:
	_use("market", "stall_door")
	assert_str(Case.room).is_equal("stall")


func test_every_drawn_spot_is_one_of_the_case_spots_in_its_room() -> void:
	var market: DrownedMarket = DrownedMarket.new()
	for room: String in RoomLayout.PLACES:
		assert_bool(RoomLayout.ROOM_WIDTHS.has(room)).is_true()
		for id: String in RoomLayout.PLACES[room]:
			var s: Spot = market.spot(id)
			assert_object(s).override_failure_message("no spot %s" % id).is_not_null()
			assert_str(s.room).is_equal(room)
		assert_int(market_floor.spots_in(room).size()).is_equal(RoomLayout.PLACES[room].size())
	market.spots.clear()


func test_spots_stand_in_their_room_and_their_reach_never_overlaps() -> void:
	for room: String in RoomLayout.PLACES:
		var places: Dictionary = RoomLayout.PLACES[room]
		var ids: Array[String] = []
		ids.assign(places.keys())
		ids.sort_custom(func(a: String, b: String) -> bool: return places[a].x < places[b].x)
		for i: int in range(ids.size()):
			var p: Vector2 = places[ids[i]]
			assert_float(p.x - p.y).is_greater_equal(10.0)
			assert_float(p.x + p.y).is_less(float(RoomLayout.ROOM_WIDTHS[room] - 10))
			if i > 0:
				var q: Vector2 = places[ids[i - 1]]
				assert_float(q.x + q.y + RoomLayout.REACH).override_failure_message("%s and %s overlap" % [ids[i - 1], ids[i]]).is_less(p.x - p.y - RoomLayout.REACH)


func test_nothing_to_use_where_the_detective_starts() -> void:
	assert_object(market_floor.nearest("market", ArtTest.START_X)).is_null()


func test_the_slice_starts_at_the_top_of_the_case() -> void:
	assert_str(Case.room).is_equal("market")
	assert_bool(Case.clues.is_empty()).is_true()
	assert_bool(Case.has_optic).is_equal(ArtTest.START_WITH_OPTIC)
	assert_bool(Case.has_beat("case_opens")).is_true()


func test_the_badge_opens_the_stall_and_the_body_gives_the_chip() -> void:
	_visit_stall()
	_use("stall", "body")
	# He pockets the chip; its etching (the clue) waits for him to turn it over.
	assert_bool(Case.is_set("has_chip")).is_true()
	assert_bool(Case.has_clue("chip")).is_false()
	assert_bool(DrownedMarket.chip_unexamined()).is_true()
	Case.find_clue(ExamineItem.chip().clue)
	assert_bool(DrownedMarket.chip_unexamined()).is_false()
	assert_bool(Case.has_beat("body_examined")).is_true()
	_use("stall", "ledger")
	assert_bool(Case.has_clue("ledger")).is_true()
	_use("stall", "stall_exit")
	assert_str(Case.room).is_equal("market")
	# Once he's seen her, the coroner takes the body.
	assert_bool(Case.has_beat("body_removed")).is_true()


func test_without_the_badge_the_stall_stays_shut() -> void:
	Case.revoke_clearance()
	_use("market", "stall_door")
	assert_str(Case.room).is_equal("market")


func test_a_deep_reading_leaves_vale_at_the_fog_edge() -> void:
	assert_object(market_floor.nearest("market", RoomLayout.VALE_X)).is_null()
	_visit_stall()
	var t: Talk = _use("stall", "body").choose("Deep reading")
	assert_float(RoomLayout.reading_depth(t)).is_equal(RoomLayout.DEEP_WHITE)
	assert_bool(Case.has_clue("vale_last")).is_true()
	_use("stall", "stall_exit")
	var vale: Talk = _use("market", "passenger_vale")
	assert_str(vale.text).contains("points")


func test_a_surface_reading_comes_in_less_far() -> void:
	_visit_stall()
	var t: Talk = _use("stall", "body").choose("Surface reading")
	assert_float(RoomLayout.reading_depth(t)).is_equal(RoomLayout.SURFACE_WHITE)
	assert_float(RoomLayout.reading_depth(Talk.say("Osk", "Not a reading."))).is_equal(0.0)


func test_the_heat_door_shows_only_through_the_optic() -> void:
	assert_object(market_floor.nearest("market", RoomLayout.HEAT_DOOR_X)).is_null()
	Case.toggle_optic()
	assert_str(market_floor.nearest("market", RoomLayout.HEAT_DOOR_X).id).is_equal("heat_door")
	# It leads to Cold Storage, a stand-in until it's drawn.
	_use("market", "heat_door")
	assert_str(Case.room).is_equal("cold")
	assert_bool(RoomLayout.is_drawn(Case.room)).is_false()


func test_the_thermal_read_on_the_body_needs_the_optic_on() -> void:
	Case.toggle_optic()
	_visit_stall()
	_use("stall", "body")
	assert_bool(Case.has_clue("thermal")).is_true()


func test_the_fixer_gate_opens_after_the_stall_and_osk() -> void:
	_visit_stall()
	_use("stall", "ledger")
	_use("stall", "stall_exit")
	_use("market", "osk")
	assert_int(Case.commit_theory("stolen", ["ledger", "rival"])).is_equal(TheoryCheck.Result.HOLDS)
	_use("market", "fixer").choose("really selling to").choose("Osk")
	assert_bool(Case.is_set("fixer_vouched")).is_false()
	_use("market", "fixer").choose("really selling to").choose("J. Reyka")
	assert_bool(Case.is_set("fixer_vouched")).is_true()
	_use("market", "back_room")
	assert_str(Case.room).is_equal("cold")


func test_the_etching_deduction_from_the_market_floor() -> void:
	assert_object(_use("market", "fixer").option("chip etching")).is_null()
	_visit_stall()
	_use("stall", "body")
	_use("stall", "stall_exit")
	# Not until he's turned the chip over and seen the etching.
	assert_object(_use("market", "fixer").option("chip etching")).is_null()
	Case.find_clue(ExamineItem.chip().clue)
	_use("market", "fixer").choose("chip etching")
	_use("market", "tech").choose("tunnels")
	assert_int(Case.commit_theory("catalog", ["fixerfmt", "tech"])).is_equal(TheoryCheck.Result.HOLDS)
	assert_bool(Case.has_beat("catalog_deduced")).is_true()


func test_the_chip_etching_is_the_calling_card_clue() -> void:
	var chip: ExamineItem = ExamineItem.chip()
	assert_str(chip.clue).is_equal("chip")
	assert_bool(CaseCatalog.has_clue(chip.clue)).is_true()
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


func test_the_cams_give_the_footage_with_a_badge() -> void:
	_use("market", "cams")
	assert_bool(Case.has_clue("footage")).is_true()


func test_prompts_name_the_spot() -> void:
	assert_str(RoomLayout.prompt(market_floor.market.spot("osk"))).is_equal("E  Osk, rival broker")


func test_the_body_line_leaves_the_etching_for_examining() -> void:
	_visit_stall()
	var t: Talk = _use("stall", "body")
	assert_str(t.text).not_contains("CS-14-07")
	assert_str(t.text).contains("scratched")


func test_without_an_examine_view_the_body_names_the_etching() -> void:
	Case.reset()
	var grey: DrownedMarket = DrownedMarket.new()
	Case.travel("stall", 0.0)
	var t: Talk = grey.spot("body").use()
	assert_bool(Case.has_clue("chip")).is_true()
	assert_str(t.text).contains("CS-14-07")
	grey.spots.clear()
	grey.rooms.clear()


func test_every_room_is_at_least_a_screen_wide() -> void:
	for room: String in market_floor.market.rooms:
		assert_int(market_floor.width(room)).is_greater_equal(PixelView.NATIVE.x)


func test_a_stand_in_room_is_the_grey_box_scaled() -> void:
	assert_bool(RoomLayout.is_drawn("cold")).is_false()
	assert_float(market_floor.to_native("cold", 1500.0)).is_equal_approx(1000.0, 0.01)
	assert_float(RoomLayout.y_to_native(DrownedMarket.FLOOR_Y)).is_equal(RoomLayout.WALK_Y)
	var drawers: Spot = market_floor.market.spot("drawers")
	assert_float(RoomLayout.feet_y(drawers)).is_less(RoomLayout.WALK_Y)


func test_arrivals_in_a_drawn_room_land_by_the_door_they_name() -> void:
	# Out of Cold Storage's heat door, he comes back by the boarded stall.
	assert_float(market_floor.to_native("market", 2290.0)).is_between(RoomLayout.HEAT_DOOR_X - 20.0, RoomLayout.HEAT_DOOR_X + 40.0)
	# Into Vale's stall, just inside its door.
	assert_float(market_floor.to_native("stall", 80.0)).is_between(StallArt.EXIT_X, StallArt.LEDGER_X)
	# Out of the fixer's back room, by its door; from the row and the tunnels,
	# at the ends they lead from.
	assert_float(market_floor.to_native("market", 1690.0)).is_equal(RoomLayout.BACK_DOOR_X)
	assert_float(market_floor.to_native("market", 60.0)).is_less(40.0)
	assert_float(market_floor.to_native("market", 2540.0)).is_greater(1240.0)


func test_every_way_in_lands_inside_the_room() -> void:
	for room: String in market_floor.market.rooms:
		var def: RoomDef = market_floor.market.rooms[room]
		for pair: Array in [[def.exit_left, def.exit_left_x], [def.exit_right, def.exit_right_x]]:
			if pair[0] == "":
				continue
			var x: float = market_floor.to_native(pair[0], pair[1])
			assert_float(x).is_between(0.0, float(market_floor.width(pair[0])))


func test_ledges_and_spawns_sit_inside_their_rooms() -> void:
	for room: String in market_floor.market.rooms:
		for l: Rect2 in market_floor.ledges(room):
			assert_float(l.position.y).is_less(RoomLayout.WALK_Y)
			assert_float(l.end.x).is_less_equal(float(market_floor.width(room)))
		for p: Vector2 in market_floor.spawns(room):
			assert_float(p.x).is_between(0.0, float(market_floor.width(room)))
			assert_float(p.y).is_less_equal(RoomLayout.WALK_Y)


func test_a_spot_up_on_a_ledge_is_out_of_reach_from_the_floor() -> void:
	Case.travel("cold", 0.0)
	var drawers: Spot = market_floor.market.spot("drawers")
	var x: float = RoomLayout.place(drawers).x
	assert_object(market_floor.nearest("cold", x, RoomLayout.WALK_Y)).is_null()
	assert_str(market_floor.nearest("cold", x, RoomLayout.feet_y(drawers)).id).is_equal("drawers")
