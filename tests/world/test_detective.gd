extends GdUnitTestSuite
## The player: one brisk pace (no sprint), a short dash on his reinforced
## legs that slips through hits, once in the air, then cools down, and a
## slide (down + dash) that goes further and lower.

const STEP: float = 1.0 / 60.0


func after_test() -> void:
	for action: String in ["move_right", "move_left", "move_down", "dash", "jump"]:
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
	# Distance from his speed each step: move_and_slide outside a physics
	# frame steps by the render frame's delta, which varies.
	var moved: float = 0.0
	var frames: int = 0
	while det.dashing > 0.0 and frames < 60:
		det._physics_process(STEP)
		moved += det.velocity.x * STEP
		frames += 1
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


## Stands him on a floor so is_on_floor() holds.
func _on_floor() -> Detective:
	var floor_body: StaticBody2D = auto_free(StaticBody2D.new())
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0, 10)
	add_child(floor_body)
	var det: Detective = _detective()
	det.position = Vector2(0, 0)
	# Frozen while he settles, so input pressed by another test this same
	# engine frame can't start anything.
	det.frozen = true
	for i: int in range(3):
		det._physics_process(STEP)
	det.frozen = false
	det._dash_ready = 0.0
	return det


func test_a_slide_goes_further_than_a_dash_and_slows() -> void:
	var det: Detective = _on_floor()
	assert_bool(det.is_on_floor()).is_true()
	det._start_slide(1.0)
	det._physics_process(STEP)
	var first: float = det.velocity.x
	var moved: float = first * STEP
	var frames: int = 0
	while det.sliding > 0.0 and frames < 120:
		det._physics_process(STEP)
		moved += det.velocity.x * STEP
		frames += 1
	assert_float(det.velocity.x).is_less(first)
	assert_float(moved).is_greater(Detective.DASH_SPEED * Detective.DASH_SECONDS)
	assert_float(moved).is_between(Detective.BODY.y, Detective.BODY.y * 2.0)


func test_a_slide_drops_his_body_under_a_chest_high_shot() -> void:
	var det: Detective = _on_floor()
	var chest: Vector2 = det.position + Vector2(0, -40)
	assert_bool(det.hit_box().has_point(chest)).is_true()
	det._start_slide(1.0)
	assert_bool(det.hit_box().has_point(chest)).is_false()
	# No protection, though: what reaches him still hurts.
	det.hurt()
	assert_int(det.hp).is_equal(Detective.MAX_HP - 1)


func test_down_and_dash_slides_on_the_floor_but_dashes_in_the_air() -> void:
	var det: Detective = _on_floor()
	Input.action_press("move_down")
	det.press("dash")
	det._physics_process(STEP)
	assert_float(det.sliding).is_greater(0.0)
	var air: Detective = _detective()
	air.position = Vector2(-9000, -9000)
	air.press("dash")
	air._physics_process(STEP)
	assert_float(air.sliding).is_equal(0.0)
	assert_float(air.dashing).is_greater(0.0)


func test_jump_breaks_out_of_a_slide() -> void:
	var det: Detective = _on_floor()
	det._start_slide(1.0)
	det.press("jump")
	det._physics_process(STEP)
	assert_float(det.sliding).is_equal(0.0)
	assert_float(det.velocity.y).is_less(0.0)


func test_a_slide_shares_the_dash_cooldown() -> void:
	var det: Detective = _on_floor()
	det._start_slide(1.0)
	det.sliding = 0.0
	det._start_dash(1.0)
	assert_float(det.dashing).is_equal(0.0)


func test_a_jump_out_of_a_slide_carries_its_speed() -> void:
	var det: Detective = _on_floor()
	det._start_slide(1.0)
	det._physics_process(STEP)
	det.press("jump")
	det._physics_process(STEP)
	assert_float(det.velocity.y).is_less(0.0)
	assert_float(det.velocity.x).is_greater(Detective.SPEED * 1.5)
	assert_float(det.carry).is_greater(Detective.SPEED)


func test_a_jump_out_of_a_dash_carries_up_to_the_cap() -> void:
	var det: Detective = _on_floor()
	det._start_dash(1.0)
	det.press("jump")
	det._physics_process(STEP)
	assert_float(det.dashing).is_equal(0.0)
	assert_float(det.velocity.y).is_less(0.0)
	assert_float(det.velocity.x).is_equal_approx(Detective.CARRY_MAX, 0.01)


func test_carried_speed_eases_back_to_his_pace_in_the_air() -> void:
	var det: Detective = _detective()
	det.position = Vector2(-9000, -9000)
	det._dash_dir = 1.0
	det._launch(Detective.CARRY_MAX)
	var last: float = det.carry
	for i: int in range(10):
		det._physics_process(STEP)
		assert_float(det.carry).is_less(last)
		last = det.carry
	var t: float = 0.0
	while det.carry > 0.0 and t < 3.0:
		det._physics_process(STEP)
		t += STEP
	assert_float(det.carry).is_equal(0.0)
	assert_float(t + 10.0 * STEP).is_equal_approx((Detective.CARRY_MAX - Detective.SPEED) / Detective.CARRY_DRAG, 0.05)


func test_turning_back_drops_the_carried_speed() -> void:
	var det: Detective = _detective()
	det.position = Vector2(-9000, -9000)
	det._dash_dir = 1.0
	det._launch(Detective.CARRY_MAX)
	Input.action_press("move_left")
	det._physics_process(STEP)
	assert_float(det.carry).is_equal(0.0)
	assert_float(det.velocity.x).is_equal_approx(-Detective.SPEED, 0.01)


func test_a_jump_just_after_a_dash_still_carries() -> void:
	var det: Detective = _on_floor()
	det._start_dash(1.0)
	while det.dashing > 0.0:
		det._physics_process(STEP)
	det.press("jump")
	det._physics_process(STEP)
	assert_float(det.velocity.y).is_less(0.0)
	assert_float(det.velocity.x).is_greater(Detective.SPEED)


func test_a_plain_jump_carries_nothing() -> void:
	var det: Detective = _on_floor()
	Input.action_press("move_right")
	det.press("jump")
	det._physics_process(STEP)
	assert_float(det.velocity.y).is_less(0.0)
	assert_float(det.velocity.x).is_equal_approx(Detective.SPEED, 0.01)
	assert_float(det.carry).is_equal(0.0)


func test_a_jump_clears_a_little_over_his_own_height() -> void:
	var height: float = Detective.JUMP_SPEED * Detective.JUMP_SPEED / (2.0 * Detective.GRAVITY)
	assert_float(height).is_greater(Detective.BODY.y)
	assert_float(height).is_less(Detective.BODY.y * 1.5)


func test_a_thug_is_slower_than_his_pace() -> void:
	assert_float(Hostile.THUG_SPEED).is_less(Detective.SPEED)


func test_a_hit_names_what_it_was() -> void:
	var det: Detective = _detective()
	var monitor: Object = monitor_signals(det)
	det.hurt("bolt")
	await assert_signal(monitor).is_emitted("hurt_by", ["bolt"])


func test_a_hit_passing_through_a_dash_says_so() -> void:
	var det: Detective = _detective()
	det._start_dash(1.0)
	var monitor: Object = monitor_signals(det)
	det.hurt("thug")
	await assert_signal(monitor).is_emitted("slipped", ["thug"])
	assert_int(det.hp).is_equal(Detective.MAX_HP)
