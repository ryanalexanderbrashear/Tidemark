extends GdUnitTestSuite
## Loopers (Gameplay and Production, Combat): they sway asleep until woken,
## fight by the memory they replay, go down without dying, and pulling a
## downed one's rig ends the loop. Played in the combat test ground, which runs
## the game's World.

const STEP: float = 1.0 / 60.0

var test: CombatTest


func before() -> void:
	test = auto_free(CombatTest.new())
	add_child(test)


func before_test() -> void:
	test.unhurtable = false
	test.start()
	test.detective.position.x = 200.0
	test.detective.facing = 1.0


func after_test() -> void:
	test._talk.hide()
	get_tree().paused = false


func after() -> void:
	Case.reset()
	Mind.reset()


func _looper(kind: String, off: float) -> Looper:
	return test.spawn(kind, off) as Looper


func _run(l: Looper, seconds: float) -> void:
	for i: int in roundi(seconds / STEP):
		l._physics_process(STEP)


func test_loopers_sway_asleep_until_he_comes_close() -> void:
	var l: Looper = _looper("brawler", 300.0)
	var x: float = l.position.x
	_run(l, 0.5)
	assert_int(l.state).is_equal(Looper.State.ASLEEP)
	assert_float(l.position.x).is_equal(x)
	test.detective.position.x = l.position.x - Looper.WAKE_RANGE + 10.0
	_run(l, STEP)
	assert_int(l.state).is_not_equal(Looper.State.ASLEEP)


func test_a_shot_wakes_one() -> void:
	var l: Looper = _looper("grabber", 300.0)
	l.hit()
	assert_int(l.state).is_equal(Looper.State.AWAKE)


func test_an_alarm_runs_and_its_scream_wakes_the_others() -> void:
	var alarm: Looper = _looper("alarm", 100.0)
	var near: Looper = _looper("brawler", 300.0)
	var far: Looper = _looper("brawler", 100.0 + Looper.SCREAM_RANGE + 200.0)
	alarm.wake()
	var x: float = alarm.position.x
	_run(alarm, Looper.SCREAM_EVERY + 0.1)
	assert_float(alarm.position.x).is_greater(x)
	assert_int(near.state).is_equal(Looper.State.AWAKE)
	assert_int(far.state).is_equal(Looper.State.ASLEEP)


func test_an_alarm_never_hits() -> void:
	var alarm: Looper = _looper("alarm", 6.0)
	alarm.wake()
	_run(alarm, 1.0)
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)


func test_a_brawler_winds_up_then_charges_and_hits() -> void:
	var l: Looper = _looper("brawler", 50.0)
	# One step to wake, one to see him in reach.
	_run(l, STEP * 2.0)
	assert_int(l.state).is_equal(Looper.State.WINDUP)
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)
	_run(l, Looper.WINDUP_SECONDS + Looper.CHARGE_SECONDS)
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP - 1)
	assert_str(test.last_hit).is_equal("brawler")


func test_a_dash_slips_a_brawlers_charge() -> void:
	var l: Looper = _looper("brawler", 50.0)
	_run(l, Looper.WINDUP_SECONDS + STEP * 4.0)
	assert_int(l.state).is_equal(Looper.State.CHARGE)
	test.detective.dashing = 10.0
	_run(l, Looper.CHARGE_SECONDS)
	test.detective.dashing = 0.0
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)
	assert_int(test.slipped_count).is_greater(0)


func test_a_grabber_holds_him_and_flashes_a_memory_without_hurting() -> void:
	var l: Looper = _looper("grabber", 4.0)
	l.wake()
	_run(l, STEP)
	assert_float(test.detective.held).is_equal(Looper.HOLD_SECONDS)
	assert_int(test.detective.hp).is_equal(Detective.MAX_HP)
	assert_float(test.reading_amount).is_equal(World.GRAB_WHITE)
	assert_bool(Looper.FLASHES.has(test._voice.said)).is_true()
	assert_int(Mind.level()).is_equal(0)


func test_held_he_cannot_move_and_struggling_frees_him_sooner() -> void:
	var d: Detective = test.detective
	assert_bool(d.grab(1.0, "grabber")).is_true()
	var x: float = d.position.x
	d.press("move_right")
	d._physics_process(STEP)
	assert_float(d.position.x).is_equal(x)
	assert_float(d.held).is_equal_approx(1.0 - STEP - Detective.STRUGGLE, 0.001)


func test_a_dash_cannot_be_grabbed() -> void:
	test.detective.dashing = 0.1
	assert_bool(test.detective.grab(1.0, "grabber")).is_false()
	test.detective.dashing = 0.0


func test_a_downed_looper_stays_down_and_its_rig_can_be_pulled() -> void:
	var l: Looper = _looper("brawler", 12.0)
	for i: int in 3:
		l.hit()
	assert_bool(l.is_down()).is_true()
	assert_bool(l.is_inside_tree()).is_true()
	assert_bool(l.is_in_group("hostiles")).is_false()
	assert_array(test.hostiles()).is_empty()
	assert_bool(Case.hostiles_left(CombatTest.ARENA)).is_false()
	assert_object(test.nearest_rig()).is_same(l)
	test.interact()
	assert_bool(test._talk.visible).is_true()
	assert_bool(Looper.OWN_LINES.has(test._talk.talk.text)).is_true()
	assert_bool(l.pulled).is_true()
	assert_object(test.nearest_rig()).is_null()


func test_a_rig_is_out_of_reach_from_across_the_room() -> void:
	var l: Looper = _looper("grabber", 200.0)
	for i: int in 3:
		l.hit()
	assert_object(test.nearest_rig()).is_null()


func test_the_crowd_starts_asleep() -> void:
	test.crowd()
	var loopers: Array[Hostile] = test.hostiles()
	assert_int(loopers.size()).is_equal(4)
	for h: Hostile in loopers:
		assert_int((h as Looper).state).is_equal(Looper.State.ASLEEP)
