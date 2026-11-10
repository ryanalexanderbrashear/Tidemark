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
	test.detective.facing = 1.0
	assert_float(test.fight_lead()).is_equal(0.0)
	test.spawn("thug")
	assert_float(test.fight_lead()).is_equal(World.FIGHT_LEAD)
	test.detective.facing = -1.0
	assert_float(test.fight_lead()).is_equal(-World.FIGHT_LEAD)
	test.clear()
	assert_float(test.fight_lead()).is_equal(0.0)
