extends GdUnitTestSuite
## The grey box's player: holding sprint (his reinforced legs) moves him faster
## than running, and letting go brings him back to his running pace.


func after_test() -> void:
	for action: String in ["move_right", "move_left", "sprint"]:
		Input.action_release(action)


func test_sprint_is_faster_than_running() -> void:
	assert_float(Detective.SPRINT_SPEED).is_greater(Detective.SPEED)


func test_holding_sprint_moves_him_at_sprint_speed() -> void:
	var det: Detective = auto_free(Detective.new())
	add_child(det)
	Input.action_press("move_right")
	det._physics_process(1.0 / 60.0)
	assert_float(det.velocity.x).is_equal_approx(Detective.SPEED, 0.01)
	Input.action_press("sprint")
	det._physics_process(1.0 / 60.0)
	assert_float(det.velocity.x).is_equal_approx(Detective.SPRINT_SPEED, 0.01)
	Input.action_release("sprint")
	det._physics_process(1.0 / 60.0)
	assert_float(det.velocity.x).is_equal_approx(Detective.SPEED, 0.01)


func test_sprint_alone_does_not_move_him() -> void:
	var det: Detective = auto_free(Detective.new())
	add_child(det)
	Input.action_press("sprint")
	det._physics_process(1.0 / 60.0)
	assert_float(det.velocity.x).is_equal(0.0)
