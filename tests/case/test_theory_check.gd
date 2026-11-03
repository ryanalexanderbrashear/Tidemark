extends GdUnitTestSuite
## The case board's rule: two or more supporting clues, nothing that doesn't fit.

func _held() -> Array[String]:
	return ["ledger", "rival", "chip", "thermal", "footage", "tech", "fixerfmt"]


func _check(id: String, picked: Array[String]) -> TheoryCheck.Result:
	return TheoryCheck.evaluate(CaseCatalog.theory(id), picked, _held())


func test_two_supporting_clues_hold_a_theory() -> void:
	assert_int(_check("stolen", ["ledger", "rival"])).is_equal(TheoryCheck.Result.HOLDS)


func test_one_clue_is_not_enough() -> void:
	assert_int(_check("stolen", ["ledger"])).is_equal(TheoryCheck.Result.NOT_ENOUGH)


func test_a_clue_that_does_not_belong_breaks_the_chain() -> void:
	assert_int(_check("stolen", ["ledger", "rival", "chip"])).is_equal(TheoryCheck.Result.DOESNT_FIT)


func test_picking_everything_never_works() -> void:
	for t: Theory in CaseCatalog.theories():
		assert_int(TheoryCheck.evaluate(t, _held(), _held())).is_not_equal(TheoryCheck.Result.HOLDS)


func test_the_wrong_suspect_theory_holds_on_misleading_clues() -> void:
	var there: Theory = CaseCatalog.theory("there")
	assert_bool(there.is_true).is_false()
	assert_int(_check("there", ["ledger", "rival"])).is_equal(TheoryCheck.Result.HOLDS)


func test_evidence_that_clears_the_suspect_breaks_the_wrong_theory() -> void:
	assert_int(_check("there", ["ledger", "rival", "thermal"])).is_equal(TheoryCheck.Result.DOESNT_FIT)


func test_a_theory_about_the_chip_needs_the_chip() -> void:
	var held: Array[String] = ["tech", "fixerfmt"]
	assert_int(TheoryCheck.evaluate(CaseCatalog.theory("catalog"), ["tech", "fixerfmt"], held)).is_equal(TheoryCheck.Result.MISSING_SUBJECT)


func test_clues_not_yet_found_cannot_be_used() -> void:
	assert_int(_check("catalog", ["drawers", "tech"])).is_equal(TheoryCheck.Result.DOESNT_FIT)


func test_red_herrings_can_never_hold() -> void:
	for id: String in ["osk", "stallcode"]:
		assert_int(CaseCatalog.theory(id).supported_by.size()).is_equal(0)


func test_every_true_theory_has_three_routes_of_evidence() -> void:
	# Design: three clues per critical fact, so missing one never strands the player.
	for t: Theory in CaseCatalog.theories():
		if t.is_true:
			assert_int(t.supported_by.size()).override_failure_message("%s has too few clues" % t.id).is_greater_equal(3)
		for id: String in t.supported_by:
			assert_bool(CaseCatalog.has_clue(id)).override_failure_message("%s names unknown clue %s" % [t.id, id]).is_true()
