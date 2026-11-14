extends GdUnitTestSuite

const PATH: String = "q.md"
const STAND_IN_FIXTURES: String = "res://tests/fixtures/questions/code/"


## One entry's lines. Fields can be dropped or replaced by name; a null value drops the field.
func _entry(number: int, status: String = "Open", overrides: Dictionary = {}) -> Array[String]:
	var lines: Array[String] = ["## Q%d. Title %d" % [number, number], ""]
	for field: String in DesignQuestions.FIELDS:
		var value: Variant = overrides.get(field, status if field == "Status" else "Text for %s" % field)
		if value != null:
			lines.append("- **%s:** %s" % [field, value])
	lines.append("")
	return lines


func _parse(lines: Array[String]) -> DesignQuestions:
	return DesignQuestions.parse("\n".join(lines), PATH)


func _two_entries() -> Array[String]:
	var lines: Array[String] = ["# Questions", ""]
	lines.append_array(_entry(1, "Answered (Story, Horror, 2026-11-14)"))
	lines.append_array(_entry(2))
	return lines


# The file's format

func test_valid_entries_parse() -> void:
	var parsed: DesignQuestions = _parse(_two_entries())
	assert_array(parsed.errors).is_empty()
	assert_int(parsed.questions.size()).is_equal(2)
	assert_str(parsed.questions[1]["title"]).is_equal("Title 1")
	assert_str(parsed.questions[1]["status"]).is_equal("Answered")
	assert_str(parsed.questions[2]["status"]).is_equal("Open")
	assert_int(parsed.questions[2]["line"]).is_equal(11)


func test_code_blocks_are_ignored() -> void:
	var lines: Array[String] = ["```markdown"]
	lines.append_array(_entry(7, "Nonsense"))
	lines.append("```")
	lines.append_array(_entry(1))
	var parsed: DesignQuestions = _parse(lines)
	assert_array(parsed.errors).is_empty()
	assert_array(parsed.questions.keys()).is_equal([1])


func test_a_field_can_start_on_the_next_line_and_run_on() -> void:
	var lines: Array[String] = _entry(1, "Open", {"Suggested default": null})
	lines.append_array(["- **Suggested default:**", "  - First part.", "  - Second part."])
	var parsed: DesignQuestions = _parse(lines)
	assert_array(parsed.errors).is_empty()


func test_missing_field_fails() -> void:
	assert_array(_parse(_entry(1, "Open", {"The docs say": null})).errors).is_equal([
		"q.md:1: Q1 is missing 'The docs say'",
	])


func test_empty_field_fails() -> void:
	var lines: Array[String] = _entry(1, "Open", {"Question": null})
	lines.append("- **Question:**")
	assert_array(_parse(lines).errors).is_equal(["q.md:1: Q1's 'Question' is empty"])


func test_repeated_and_unknown_fields_fail() -> void:
	var lines: Array[String] = _entry(1)
	lines.append_array(["- **Status:** Open", "- **Owner:** Alex"])
	assert_array(_parse(lines).errors).is_equal([
		"q.md:9: Q1 has 'Status' twice",
		"q.md:10: Q1 has an unknown field 'Owner'",
	])


func test_unknown_status_fails() -> void:
	for status: String in ["Closed", "Opened", "open", "Answer (Story)"]:
		assert_array(_parse(_entry(1, status)).errors).is_equal([
			"q.md:1: Q1's status must start with one of: Open, Default in use, Answered",
		])


func test_every_status_is_accepted() -> void:
	for status: String in ["Open", "Default in use, in game/mind/mind_state.gd", "Answered (Story, Horror, 2026-11-14)"]:
		assert_array(_parse(_entry(1, status)).errors).is_empty()


func test_numbers_must_run_in_order_without_repeats() -> void:
	var lines: Array[String] = _entry(1)
	lines.append_array(_entry(1))
	lines.append_array(_entry(3))
	assert_array(_parse(lines).errors).is_equal([
		"q.md:9: Q1 is already used at line 1",
		"q.md:17: Q3 is out of order; expected Q2",
	])


func test_unreadable_heading_and_field_fail() -> void:
	var lines: Array[String] = _entry(1)
	lines[0] = "## Q1 Title without the dot"
	lines.append_array(_entry(1))
	lines[10] = "- **Question:**text with no space"
	var errors: Array[String] = _parse(lines).errors
	assert_array(errors).contains([
		"q.md:1: can't read this heading; expected \"## Q<n>. Title\"",
		"q.md:11: can't read this field; expected \"- **Field:** text\"",
	])


func test_a_file_with_no_questions_fails() -> void:
	assert_array(_parse(["# Questions", "", "Nothing yet."]).errors).is_equal([
		"q.md: no questions found; expected \"## Q1. Title\" headings",
	])


# Stand-ins in the code

func test_stand_ins_are_checked_against_the_questions() -> void:
	var parsed: DesignQuestions = _parse(_two_entries())
	parsed.check_stand_ins([STAND_IN_FIXTURES])
	assert_array(parsed.errors).is_equal([
		"res://tests/fixtures/questions/code/stand_ins.gd:6: DESIGN-TBD names Q99, which isn't in q.md",
	])
	assert_array(parsed.reminders).is_equal([
		"res://tests/fixtures/questions/code/stand_ins.gd:4: Q1 is answered; this stand-in can follow the docs now",
	])


# The shipped file

func test_the_shipped_questions_and_stand_ins_pass() -> void:
	var parsed: DesignQuestions = DesignQuestions.parse_file("res://" + DesignQuestions.DEFAULT_PATH)
	parsed.check_stand_ins()
	for reminder: String in parsed.reminders:
		print("design questions: ", reminder)
	assert_array(parsed.errors).is_empty()
	assert_bool(parsed.questions.is_empty()).is_false()
