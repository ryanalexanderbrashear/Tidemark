extends GdUnitTestSuite
## The player: one brisk pace (no sprint), and a short dash on his reinforced
## legs that slips through hits, once in the air, then cools down.

const STEP: float = 1.0 / 60.0


func after_test() -> void:
	for action: String in ["move_right", "move_left", "dash"]:
		Input.action_release(action)


func _detective() -> Detective:
	var det: Detective = auto_free(Detective.new())
	add_child(det)
	return det


func test_he_moves_at_one_brisk_pace() -> void:
	var det: Detective = _detective()
	Input.action_press("move_right")
	det._physics_process(STEP)
	assert_float(det.velocity.x).is_equal_approx(Detective.SPEED, 0.01)
	# Brisk: a 640 px screen in well under 10 seconds.
	assert_float(640.0 / Detective.SPEED).is_less(8.0)


func test_there_is_no_sprint() -> void:
	assert_bool(InputMap.has_action("sprint")).is_false()
	assert_bool(InputMap.has_action("dash")).is_true()


func test_a_dash_is_a_short_fast_burst() -> void:
	var det: Detective = _detective()
	det.position = Vector2(-9000, -9000)
	det._start_dash(1.0)
	var start: float = det.position.x
	var frames: int = 0
	while det.dashing > 0.0 and frames < 60:
		det._physics_process(STEP)
		frames += 1
	var moved: float = det.position.x - start
	# Around two thirds of his height, far quicker than his pace.
	assert_float(moved).is_between(Detective.BODY.y * 0.6, Detective.BODY.y * 1.2)
	assert_float(Detective.DASH_SPEED).is_greater(Detective.SPEED * 3.0)
	# Straight along: no fall while dashing.
	assert_float(det.position.y).is_equal(-9000.0)


func test_a_dash_goes_the_way_he_faces_when_he_isnt_pushing() -> void:
	var det: Detective = _detective()
	det.facing = -1.0
	det._start_dash(0.0)
	det._physics_process(STEP)
	assert_float(det.velocity.x).is_equal_approx(-Detective.DASH_SPEED, 0.01)


func test_hits_pass_through_a_dash() -> void:
	var det: Detective = _detective()
	det._start_dash(1.0)
	det.hurt()
	assert_int(det.hp).is_equal(Detective.MAX_HP)
	while det.dashing > 0.0:
		det._physics_process(STEP)
	det.hurt()
	assert_int(det.hp).is_equal(Detective.MAX_HP - 1)


func test_one_dash_in_the_air_and_a_cooldown() -> void:
	# No floor under him here, so he's airborne throughout.
	var det: Detective = _detective()
	det._start_dash(1.0)
	assert_float(det.dashing).is_greater(0.0)
	var t: float = 0.0
	while t < Detective.DASH_COOLDOWN + 0.1:
		det._physics_process(STEP)
		t += STEP
	det._start_dash(1.0)
	assert_float(det.dashing).is_equal(0.0)


func test_the_dash_cools_down() -> void:
	var det: Detective = _detective()
	det._start_dash(1.0)
	det._air_dashed = false
	det.dashing = 0.0
	det._start_dash(1.0)
	assert_float(det.dashing).is_equal(0.0)
	det._dash_ready = 0.0
	det._start_dash(1.0)
	assert_float(det.dashing).is_greater(0.0)


func test_a_jump_clears_a_little_over_his_own_height() -> void:
	var height: float = Detective.JUMP_SPEED * Detective.JUMP_SPEED / (2.0 * Detective.GRAVITY)
	assert_float(height).is_greater(Detective.BODY.y)
	assert_float(height).is_less(Detective.BODY.y * 1.5)


func test_a_thug_is_slower_than_his_pace() -> void:
	assert_float(Hostile.THUG_SPEED).is_less(Detective.SPEED)
