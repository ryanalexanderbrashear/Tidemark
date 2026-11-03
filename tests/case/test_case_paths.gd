extends GdUnitTestSuite
## Plays the Drowned Market through its spots, the way a player would, to check
## the gates, the costs of a wrong deduction, and that nothing locks the case.

var market: DrownedMarket


func before_test() -> void:
	Case.reset()
	market = DrownedMarket.new()


func after_test() -> void:
	Case.reset()


func _use(id: String) -> Talk:
	var s: Spot = market.spot(id)
	assert_object(s).override_failure_message("no spot %s" % id).is_not_null()
	assert_bool(s.is_visible()).override_failure_message("%s is hidden" % id).is_true()
	return s.use()


func _commit(id: String, clues: Array[String]) -> void:
	assert_int(Case.commit_theory(id, clues)).override_failure_message("%s didn't hold" % id).is_equal(TheoryCheck.Result.HOLDS)


func _clear(room: String) -> void:
	while Case.hostiles_left(room):
		Case.hostile_down(room)


func _finish_from_catalog() -> CaseSummary:
	assert_bool(market.spot("panel_CS-14-07").is_visible()).is_true()
	_use("panel_CS-14-07")
	assert_str(Case.room).is_equal("drop")
	assert_bool(Case.hostiles_left("drop")).is_true()
	assert_object(_use("cache")).is_null()
	assert_bool(Case.closed).is_false()
	_clear("drop")
	_use("cache")
	assert_bool(Case.closed).is_true()
	return CaseSummary.from_case(Case)


func test_the_clean_path_recovers_everything() -> void:
	_use("stall_door")
	_use("ledger")
	_use("body")
	_use("osk")
	_commit("stolen", ["ledger", "rival"])
	market.fixer().choose("chip etching")
	market.fixer().choose("really selling").choose("J. Reyka")
	assert_bool(Case.is_set("fixer_vouched")).is_true()
	_use("back_room")
	assert_bool(Case.hostiles_left("cold")).is_false()
	_use("tech").choose("tunnels")
	_commit("catalog", ["fixerfmt", "tech"])
	var s: CaseSummary = _finish_from_catalog()
	assert_array(s.intel).contains_exactly(["list", "rig", "print"])
	assert_bool(s.clearance).is_true()
	assert_bool(s.second_victim).is_false()


func test_the_dead_drop_panel_is_scenery_until_deduced() -> void:
	var panel: Spot = market.spot("panel_CS-14-07")
	assert_bool(panel.is_visible()).is_false()
	for code: String in ["CS-02-31", "CS-09-12", "CS-14-01"]:
		assert_bool(market.spot("panel_" + code).is_visible()).is_false()
	Case.find_clue("chip")
	Case.find_clue("tech")
	Case.find_clue("drawers")
	_commit("catalog", ["tech", "drawers"])
	assert_bool(panel.is_visible()).is_true()
	assert_bool(market.spot("panel_CS-09-12").is_visible()).is_false()


func test_the_wrong_suspect_costs_the_badge_but_not_the_case() -> void:
	_use("stall_door")
	_use("ledger")
	_use("osk")
	_commit("there", ["ledger", "rival"])
	assert_bool(market.spot("reyka_door").is_highlighted()).is_true()
	_use("reyka_door").choose("Kick")
	assert_str(Case.room).is_equal("apt")
	assert_object(_use("memory_deck")).is_null()
	_clear("apt")
	_use("memory_deck")
	var fallout: Talk = _use("apt_exit")
	assert_bool(Case.clearance).is_false()
	var before: int = Case.minutes
	fallout.choose("...")
	assert_int(Case.minutes - before).is_equal(Case.FALLOUT_MINUTES)
	# Badge gates are shut now.
	assert_str(_use("stall_door").speaker).is_equal("Badge reader")
	assert_str(_use("cams").speaker).is_equal("Security terminal")
	assert_bool(Case.has_clue("footage")).is_false()
	# The tech is the way around the cams.
	_use("tech").choose("cams")
	assert_bool(Case.has_clue("footage")).is_true()
	_commit("left", ["footage", "memstamp"])
	assert_bool(Case.has_fact("there")).is_false()
	# The etching still resolves without a badge: coroner, fixer, tech.
	_use("coroner")
	market.fixer().choose("chip etching")
	_use("tech").choose("tunnels")
	_commit("catalog", ["fixerfmt", "tech"])
	var s: CaseSummary = _finish_from_catalog()
	assert_array(s.intel).contains_exactly(["list", "print"])
	assert_bool(s.clearance).is_false()
	assert_str(s.reyka).is_equal("cleared")


func test_a_warrant_needs_the_right_theory_and_a_badge() -> void:
	assert_str(_use("reyka_door").speaker).is_equal("Corporate lock")
	Case.find_clue("thermal")
	Case.find_clue("footage")
	_commit("left", ["thermal", "footage"])
	_use("reyka_door")
	assert_str(Case.room).is_equal("apt")
	assert_bool(Case.hostiles_left("apt")).is_false()
	assert_bool(Case.is_set("warrant")).is_true()


func test_no_badge_from_the_start_still_reaches_every_gate() -> void:
	# Worst case: the badge is gone before the player ever reaches the stall.
	Case.revoke_clearance()
	assert_str(_use("stall_door").speaker).is_equal("Badge reader")
	# The optic comes from the body in the morgue instead of the stall's sample.
	_use("sato").choose("Run it")
	assert_bool(Case.has_optic).is_true()
	Case.toggle_optic()
	_use("morgue")
	assert_bool(Case.has_clue("thermal")).is_true()
	# The heat door works without a badge, but the gang fights.
	_use("heat_door")
	assert_str(Case.room).is_equal("cold")
	assert_bool(Case.hostiles_left("cold")).is_true()
	_clear("cold")
	_use("drawers")
	_use("vale_drawer")
	_use("osk")
	_commit("stolen", ["rival", "tag"])
	_use("coroner")
	_use("tech").choose("tunnels")
	_commit("catalog", ["drawers", "tech"])
	_finish_from_catalog()


func test_a_failed_theory_costs_thirty_minutes() -> void:
	Case.find_clue("ledger")
	var before: int = Case.minutes
	assert_int(Case.commit_theory("stolen", ["ledger"])).is_equal(TheoryCheck.Result.NOT_ENOUGH)
	assert_int(Case.minutes - before).is_equal(Case.FAILED_THEORY_MINUTES)
	assert_bool(Case.has_fact("stolen")).is_false()


func test_naming_the_wrong_buyer_costs_time_not_access() -> void:
	Case.find_clue("ledger")
	Case.find_clue("rival")
	_commit("stolen", ["ledger", "rival"])
	var before: int = Case.minutes
	market.fixer().choose("really selling").choose("Osk")
	assert_int(Case.minutes - before).is_equal(Case.WRONG_NAME_MINUTES)
	assert_bool(Case.is_set("fixer_vouched")).is_false()
	market.fixer().choose("really selling").choose("J. Reyka")
	assert_bool(Case.is_set("fixer_vouched")).is_true()


func test_the_back_room_option_needs_the_fact() -> void:
	assert_object(market.fixer().option("really selling")).is_null()
	assert_str(_use("back_room").speaker).is_equal("Bouncer")


func test_running_out_the_clock_costs_a_life_and_the_print() -> void:
	Case.advance(Case.DEADLINE_MINUTES - Case.minutes)
	assert_bool(Case.is_set("second_victim")).is_true()
	Case.find_clue("chip")
	Case.find_clue("tech")
	Case.find_clue("fixerfmt")
	_commit("catalog", ["tech", "fixerfmt"])
	_use("tunnel_exit")
	var s: CaseSummary = _finish_from_catalog()
	assert_array(s.intel).contains_exactly(["list", "rig"])
	assert_bool(s.second_victim).is_true()


func test_going_down_costs_time_and_sends_you_to_the_precinct() -> void:
	Case.travel("cold", 100)
	var before: int = Case.minutes
	Case.player_downed()
	assert_str(Case.room).is_equal("lab")
	assert_int(Case.minutes - before).is_equal(Case.DOWNED_MINUTES)


func test_entering_with_a_badge_or_vouched_avoids_the_fight() -> void:
	Case.grant_optic()
	Case.toggle_optic()
	_use("heat_door")
	assert_bool(Case.hostiles_left("cold")).is_false()
	assert_bool(market.spot("lookout").is_visible()).is_true()
