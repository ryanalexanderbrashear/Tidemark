extends GdUnitTestSuite
## Plays the Drowned Market through its spots, the way a player would, to check
## the gates, the timeline, the costs of a wrong deduction, and that nothing
## locks the case.

var market: DrownedMarket


func before_test() -> void:
	Mind.reset()
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


func _at(time: String) -> int:
	var b: StoryBeat = StoryBeat.new()
	b.time = time
	return b.minutes()


func _finish_from_catalog() -> CaseSummary:
	assert_bool(market.spot("panel_CS-14-07").is_visible()).is_true()
	_use("panel_CS-14-07")
	assert_str(Case.room).is_equal("drop")
	assert_bool(Case.hostiles_left("drop")).is_true()
	assert_object(_use("cache")).is_null()
	assert_bool(Case.closed).is_false()
	_clear("drop")
	var s: CaseSummary = Case.close_case()
	assert_bool(Case.closed).is_true()
	return s


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
	assert_int(s.closed_at).is_equal(_at("03:00"))
	assert_array(Case.beats).contains_exactly(["case_opens", "body_examined", "fixer_vouched", "catalog_deduced", "dead_drop_found"])


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
	assert_int(Case.minutes).is_equal(_at("02:00"))
	_use("apt_exit")
	assert_bool(Case.clearance).is_false()
	assert_int(Case.minutes).is_equal(_at("02:40"))
	# What the raid set in motion hasn't happened yet.
	assert_bool(Case.has_beat("second_victim")).is_false()
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
	assert_bool(s.second_victim).is_true()
	assert_int(s.closed_at).is_equal(_at("04:30"))
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


func test_a_failed_theory_is_not_committed_and_moves_no_clock() -> void:
	Case.find_clue("ledger")
	var before: int = Case.minutes
	assert_int(Case.commit_theory("stolen", ["ledger"])).is_equal(TheoryCheck.Result.NOT_ENOUGH)
	assert_int(Case.minutes).is_equal(before)
	assert_bool(Case.has_fact("stolen")).is_false()


func test_naming_the_wrong_buyer_never_shuts_the_fixer() -> void:
	Case.find_clue("ledger")
	Case.find_clue("rival")
	_commit("stolen", ["ledger", "rival"])
	market.fixer().choose("really selling").choose("Osk")
	assert_bool(Case.is_set("fixer_vouched")).is_false()
	market.fixer().choose("really selling").choose("J. Reyka")
	assert_bool(Case.is_set("fixer_vouched")).is_true()


func test_the_back_room_option_needs_the_fact() -> void:
	assert_object(market.fixer().option("really selling")).is_null()
	assert_str(_use("back_room").speaker).is_equal("Bouncer")


func test_walking_and_fighting_never_move_the_clock() -> void:
	var start: int = Case.minutes
	for room: String in ["row", "market", "tunnels", "market", "row", "lab"]:
		Case.travel(room, 100)
	Case.travel("cold", 100)
	Case.player_downed()
	assert_str(Case.room).is_equal("lab")
	assert_int(Case.minutes).is_equal(start)


func test_the_clock_never_runs_backward() -> void:
	Case.reach("clearance_revoked")
	Case.reach("body_removed")
	assert_int(Case.minutes).is_equal(_at("02:40"))
	assert_bool(Case.has_beat("body_removed")).is_true()


func test_the_second_victim_only_follows_the_raid() -> void:
	Case.reach("dead_drop_found_late")
	assert_bool(Case.has_beat("second_victim")).is_false()
	Case.reset()
	for id: String in Case.RAID_CONSEQUENCES:
		Case.schedule(id)
	Case.reach("clearance_revoked")
	assert_bool(Case.has_beat("rig_cleared")).is_false()
	Case.reach("dead_drop_found_late")
	assert_bool(Case.has_beat("rig_cleared")).is_true()
	assert_bool(Case.has_beat("second_victim")).is_true()


func test_seeing_the_body_sends_it_to_the_morgue() -> void:
	_use("stall_door")
	_use("body")
	assert_bool(Case.body_in_morgue()).is_false()
	_use("stall_exit")
	assert_bool(Case.body_in_morgue()).is_true()
	assert_bool(market.spot("morgue").is_visible()).is_true()


func test_every_beat_has_a_time_on_the_timeline() -> void:
	var last: int = -1
	for b: StoryBeat in CaseCatalog.timeline():
		assert_int(b.minutes()).is_greater_equal(last)
		last = b.minutes()
	for id: String in Case.RAID_CONSEQUENCES:
		assert_bool(CaseCatalog.beat(id).offscreen).is_true()
	assert_str(CaseCatalog.beat(CaseCatalog.theory("catalog").beat_on_commit).id).is_equal("catalog_deduced")


func test_entering_with_a_badge_or_vouched_avoids_the_fight() -> void:
	Case.grant_optic()
	Case.toggle_optic()
	_use("heat_door")
	assert_bool(Case.hostiles_left("cold")).is_false()
	assert_bool(market.spot("lookout").is_visible()).is_true()
