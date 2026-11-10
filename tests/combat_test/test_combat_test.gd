extends GdUnitTestSuite
## The combat test ground: the game's own fighting in an arena outside the
## case, with keys to spawn hostiles and try things out.

var test: CombatTest


func before() -> void:
	test = auto_free(CombatTest.new())
	add_child(test)


func before_test() -> void:
	test.unhurtable = false
	test.set_slow_motion(false)
	test.start()


func after() -> void:
	Engine.time_scale = 1.0
	Case.reset()
	Mind.reset()


func test_it_starts_in_the_arena_with_no_hostiles() -> void:
	assert_str(test.room).is_equal(CombatTest.ARENA)
	assert_str(Case.room).is_equal(CombatTest.ARENA)
	assert_float(test.detective.position.x).is_equal(CombatTest.START_X)
	assert_array(test.hostiles()).is_empty()
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)


func test_the_arena_is_not_part_of_the_case() -> void:
	assert_bool(DrownedMarket.new().rooms.has(CombatTest.ARENA)).is_false()
	assert_object(test._scenes[CombatTest.ARENA]).is_instanceof(StandInScene)


func test_it_spawns_thugs_and_drones_in_front_of_him() -> void:
	test.detective.facing = 1.0
	var thug: Hostile = test.spawn("thug")
	assert_str(thug.kind).is_equal("thug")
	assert_float(thug.position.x).is_greater(test.detective.position.x)
	assert_float(thug.position.y).is_equal(RoomLayout.WALK_Y)
	var drone: Hostile = test.spawn("drone")
	assert_float(drone.position.y).is_less(RoomLayout.WALK_Y)
	assert_int(test.hostiles().size()).is_equal(2)


func test_a_spawn_past_the_wall_comes_from_behind() -> void:
	test.detective.facing = -1.0
	var thug: Hostile = test.spawn("thug")
	assert_float(thug.position.x).is_greater(test.detective.position.x)


func test_a_wave_and_clearing_it() -> void:
	test.wave()
	assert_int(test.hostiles().size()).is_equal(3)
	test.clear()
	assert_array(test.hostiles()).is_empty()
	assert_bool(Case.hostiles_left(CombatTest.ARENA)).is_false()


func test_it_names_what_hit_him() -> void:
	test.detective.hurt("bolt")
	assert_str(test.last_hit).is_equal("bolt")
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP - 1)


func test_a_dash_slips_a_hit_and_counts_it() -> void:
	test.detective.dashing = 0.1
	test.detective.hurt("thug")
	test.detective.dashing = 0.0
	assert_int(test.slipped_count).is_equal(1)
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)


func test_unhurtable_keeps_his_health_full() -> void:
	test.unhurtable = true
	test.detective.hurt("thug")
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)
	assert_str(test.last_hit).is_equal("thug")


func test_downed_puts_him_back_at_the_start_and_keeps_the_hostiles() -> void:
	test.spawn("thug")
	test.detective.position.x = 600.0
	test.detective.hp = 1
	test.detective.hurt("thug")
	assert_int(test.downed_count).is_equal(1)
	assert_str(Case.room).is_equal(CombatTest.ARENA)
	assert_float(test.detective.position.x).is_equal(CombatTest.START_X)
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)
	assert_int(test.hostiles().size()).is_equal(1)


func test_slow_motion_slows_the_engine_and_comes_back() -> void:
	test.set_slow_motion(true)
	assert_float(Engine.time_scale).is_equal(CombatTest.SLOW_MOTION)
	test.set_slow_motion(false)
	assert_float(Engine.time_scale).is_equal(1.0)


func test_the_arena_is_wider_than_two_screens() -> void:
	assert_int(test._scene().width).is_greater(PixelView.NATIVE.x * 2)


func test_the_camera_looks_ahead_of_him_only_in_a_fight() -> void:
	test.lead_side = 1.0
	assert_float(test.fight_lead()).is_equal(0.0)
	test.spawn("thug")
	assert_float(test.fight_lead()).is_equal(World.FIGHT_LEAD)
	test.lead_side = -1.0
	assert_float(test.fight_lead()).is_equal(-World.FIGHT_LEAD)
	test.clear()
	assert_float(test.fight_lead()).is_equal(0.0)


func test_the_look_ahead_swings_only_once_he_keeps_walking_the_other_way() -> void:
	test.spawn("thug")
	test.lead_side = 1.0
	# Turning on the spot (to shoot) leaves it where it is.
	test.detective.facing = -1.0
	test.detective.velocity = Vector2.ZERO
	test.update_lead(1.0)
	assert_float(test.lead_side).is_equal(1.0)
	# A short step back doesn't swing it either.
	test.detective.velocity = Vector2(-Detective.SPEED, 0.0)
	test.update_lead(World.LEAD_TURN_SECONDS * 0.5)
	test.detective.velocity = Vector2.ZERO
	test.update_lead(0.1)
	test.detective.velocity = Vector2(-Detective.SPEED, 0.0)
	test.update_lead(World.LEAD_TURN_SECONDS * 0.5)
	assert_float(test.lead_side).is_equal(1.0)
	# Walking that way for long enough does.
	test.update_lead(World.LEAD_TURN_SECONDS)
	assert_float(test.lead_side).is_equal(-1.0)


func test_the_look_ahead_eases_without_jumps_or_overshoot() -> void:
	test.spawn("thug")
	test.lead_side = 1.0
	test.cam_lead = World.FIGHT_LEAD
	test.lead_side = -1.0
	test.detective.velocity = Vector2.ZERO
	var last: float = test.cam_lead
	var biggest: float = 0.0
	for i: int in 180:
		test.update_lead(1.0 / 60.0)
		biggest = maxf(biggest, last - test.cam_lead)
		assert_float(test.cam_lead).is_less_equal(last)
		assert_float(test.cam_lead).is_greater_equal(-World.FIGHT_LEAD)
		last = test.cam_lead
	# Never faster than the cap, and settled within three seconds.
	assert_float(biggest).is_less_equal(World.LEAD_MAX_SPEED / 60.0 + 0.01)
	assert_float(test.cam_lead).is_equal_approx(-World.FIGHT_LEAD, 0.5)


func test_a_fight_zooms_out_as_far_as_the_arena_allows() -> void:
	assert_float(test.fight_view_width()).is_equal(float(PixelView.NATIVE.x))
	test.spawn("thug")
	# The arena is wider than the most a view shows, so it's the most.
	assert_float(test.fight_view_width()).is_equal(float(PixelView.MAX_VIEW.x))
	test.clear()
	assert_float(test.fight_view_width()).is_equal(float(PixelView.NATIVE.x))


func test_the_zoom_eases_out_and_settles() -> void:
	test.spawn("thug")
	var last: float = test._view.view_size.x
	for i: int in 240:
		test.update_zoom(1.0 / 60.0)
		assert_float(test._view.view_size.x).is_greater_equal(last)
		assert_float(test._view.view_size.x - last).is_less_equal(World.ZOOM_MAX_SPEED / 60.0 + 0.01)
		last = test._view.view_size.x
	assert_float(test._view.view_size.x).is_equal_approx(float(PixelView.MAX_VIEW.x), 0.5)
	# Stays 16:9 all the way.
	assert_float(test._view.view_size.y).is_equal_approx(test._view.view_size.x * 9.0 / 16.0, 0.01)
	test.clear()
	for i: int in 240:
		test.update_zoom(1.0 / 60.0)
	assert_float(test._view.view_size.x).is_equal_approx(float(PixelView.NATIVE.x), 0.5)


func test_a_room_that_is_drawn_never_zooms() -> void:
	assert_bool(MarketScene.new().fight_zoom).is_false()
	assert_bool(StallScene.new().fight_zoom).is_false()
	assert_bool(test._scene().fight_zoom).is_true()
