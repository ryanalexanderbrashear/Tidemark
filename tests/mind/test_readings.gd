extends GdUnitTestSuite
## Memory readings, bleed-through and the suppressant: what a reading costs, what
## carries across cases, and that none of it ever locks the case or moves the clock.

var market: DrownedMarket


func before_test() -> void:
	Mind.reset()
	Case.reset()
	market = DrownedMarket.new()


func after_test() -> void:
	Mind.reset()
	Case.reset()


func _use(id: String) -> Talk:
	var s: Spot = market.spot(id)
	assert_bool(s.is_visible()).override_failure_message("%s is hidden" % id).is_true()
	return s.use()


func _commit(id: String, clues: Array[String]) -> void:
	assert_int(Case.commit_theory(id, clues)).override_failure_message("%s didn't hold" % id).is_equal(TheoryCheck.Result.HOLDS)


func _clear(room: String) -> void:
	while Case.hostiles_left(room):
		Case.hostile_down(room)


func test_a_surface_reading_is_free() -> void:
	_use("stall_door")
	_use("body").choose("Surface")
	assert_int(Mind.bleed).is_equal(0)
	assert_str(Case.reading_depth("vale")).is_equal("surface")
	assert_array(Mind.passengers).is_empty()


func test_a_deep_reading_costs_bleed_through_and_leaves_a_passenger() -> void:
	_use("stall_door")
	var body: Talk = _use("body")
	# Examining the body is its own beat; the reading after it moves nothing.
	var before: int = Case.minutes
	body.choose("Deep")
	assert_int(Mind.bleed).is_equal(CaseCatalog.reading("vale").deep_cost)
	assert_bool(Case.has_clue("vale_last")).is_true()
	assert_bool(Mind.has_passenger("Ines Vale")).is_true()
	assert_array(Case.insights).has_size(1)
	# Readings never move the clock.
	assert_int(Case.minutes).is_equal(before)


func test_reading_deep_twice_costs_once() -> void:
	_use("coroner").choose("Deep")
	var after_one: int = Mind.bleed
	assert_object(_use("coroner").option("Deep")).is_null()
	Case.read_memory("chip", true)
	assert_int(Mind.bleed).is_equal(after_one)


func test_a_deep_reading_of_vale_clears_reyka_without_optic_or_badge() -> void:
	# The deep reading is a fourth route to "Reyka left", not a gate.
	Case.revoke_clearance()
	_use("morgue").choose("Deep")
	_use("tech").choose("cams")
	_commit("left", ["vale_last", "footage"])
	assert_int(Case.commit_theory("there", ["ledger", "rival", "vale_last"])).is_not_equal(TheoryCheck.Result.HOLDS)


func test_the_deck_reads_on_the_surface_for_the_alibi_and_deep_for_the_owner() -> void:
	Case.find_clue("thermal")
	Case.find_clue("footage")
	_commit("left", ["thermal", "footage"])
	_use("reyka_door")
	var t: Talk = _use("memory_deck")
	assert_bool(Case.has_clue("memstamp")).is_true()
	assert_int(Mind.bleed).is_equal(0)
	t.choose("Deep")
	assert_bool(Case.has_clue("marr_recall")).is_true()
	Case.find_clue("ledger")
	_commit("stolen", ["ledger", "marr_recall"])


func test_symptoms_carry_across_cases_but_doses_wear_off() -> void:
	Case.read_memory("vale", true)
	Mind.take_dose()
	var bleed: int = Mind.bleed
	assert_int(Mind.level()).is_equal(maxi(0, bleed - Mind.tuning.dose_strength))
	Case.reset()
	assert_int(Mind.bleed).is_equal(bleed)
	assert_bool(Mind.has_passenger("Ines Vale")).is_true()
	assert_int(Mind.level()).is_equal(bleed)
	assert_str(Case.reading_depth("vale")).is_equal("")


func test_pills_run_out_and_dependence_shows_as_withdrawal() -> void:
	var start: int = Mind.tuning.start_pills
	for i: int in start:
		assert_bool(Mind.take_dose()).is_true()
	assert_bool(Mind.take_dose()).is_false()
	assert_int(Mind.pills).is_equal(0)
	assert_int(Mind.doses_taken).is_equal(start)
	Case.reset()
	# Clean, but hooked: undosed, dependence is felt.
	assert_int(Mind.bleed).is_equal(0)
	assert_int(Mind.withdrawal()).is_greater(0)
	assert_int(Mind.level()).is_equal(Mind.withdrawal())


func test_strong_symptoms_plant_a_leftover_that_never_holds_a_theory() -> void:
	Mind.add_bleed(Mind.tuning.leftover_at)
	Case.read_memory("chip", true)
	var planted: Array[String] = Case.leftovers_held()
	assert_array(planted).has_size(1)
	# Looks like any other reading on the board...
	assert_str(CaseCatalog.clue(planted[0]).source).is_equal(CaseCatalog.clue("vale_last").source)
	# ...but supports nothing, so picking it breaks any chain.
	for t: Theory in CaseCatalog.theories():
		assert_bool(t.supported_by.has(planted[0])).is_false()
	Case.find_clue("ledger")
	Case.find_clue("rival")
	assert_int(Case.commit_theory("stolen", ["ledger", "rival", planted[0]])).is_equal(TheoryCheck.Result.DOESNT_FIT)


func test_below_the_threshold_nothing_is_planted() -> void:
	Case.read_memory("chip", true)
	assert_array(Case.leftovers_held()).is_empty()


func test_a_dose_quiets_the_passenger_and_her_help() -> void:
	_use("stall_door")
	_use("body").choose("Deep")
	var vale: Spot = market.spot("passenger_vale")
	assert_bool(vale.is_visible()).is_true()
	assert_str(vale.use().text).contains("points")
	while Mind.level() >= Mind.tuning.passengers_show_at and Mind.take_dose():
		pass
	assert_bool(vale.is_visible()).is_false()


func test_bleed_through_is_capped() -> void:
	Mind.add_bleed(100)
	assert_int(Mind.bleed).is_equal(Mind.tuning.bleed_max)
	assert_int(Mind.tier()).is_equal(MindState.Tier.SEVERE)


func test_the_worst_mind_still_closes_the_case() -> void:
	# Maxed symptoms, no pills, every leftover on the board, no badge: the case
	# still plays through, and nothing it needs comes from a reading.
	Mind.add_bleed(100)
	while Mind.take_dose():
		pass
	Case.reset()
	Case.revoke_clearance()
	for id: String in ["vale", "chip"]:
		Case.read_memory(id, true)
	for id: String in CaseCatalog.leftovers():
		Case.find_clue(id)
	_use("sato").choose("Run it")
	Case.toggle_optic()
	_use("heat_door")
	_clear("cold")
	_use("drawers")
	_use("vale_drawer")
	_use("osk")
	_commit("stolen", ["rival", "tag"])
	_use("coroner")
	_use("tech").choose("tunnels")
	_commit("catalog", ["drawers", "tech"])
	_use("panel_CS-14-07")
	_clear("drop")
	var s: CaseSummary = Case.close_case()
	assert_bool(Case.closed).is_true()
	assert_int(s.bleed).is_equal(Mind.tuning.bleed_max)
	assert_array(s.leftovers).has_size(CaseCatalog.leftovers().size())
	assert_array(s.insights).has_size(2)


func test_every_reading_points_at_real_clues_and_costs_something_deep() -> void:
	for r: Reading in CaseCatalog.all_readings():
		assert_int(r.deep_cost).override_failure_message("%s deep is free" % r.id).is_greater(0)
		for id: String in [r.surface_clue, r.deep_clue]:
			if id != "":
				assert_bool(CaseCatalog.has_clue(id)).override_failure_message("%s names unknown clue %s" % [r.id, id]).is_true()
				assert_bool(CaseCatalog.clue(id).leftover).is_false()


func test_no_deep_reading_clue_is_the_only_route_to_a_fact() -> void:
	# Every true theory keeps at least three supporting clues that aren't from a deep reading.
	var deep_only: Array[String] = []
	for r: Reading in CaseCatalog.all_readings():
		if r.deep_clue != "":
			deep_only.append(r.deep_clue)
	for t: Theory in CaseCatalog.theories():
		if not t.is_true:
			continue
		var others: int = 0
		for id: String in t.supported_by:
			if not deep_only.has(id):
				others += 1
		assert_int(others).override_failure_message("%s leans on deep readings" % t.id).is_greater_equal(3)
