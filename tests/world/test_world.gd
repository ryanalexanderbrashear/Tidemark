extends GdUnitTestSuite
## The main scene plays the case in the game's look: it opens on the brief,
## starts him in the precinct lab, puts every room on screen (drawn or stand-in),
## and freezes the world while something is up in front of it.

var world: World


func before() -> void:
	world = auto_free(World.new())
	add_child(world)


func before_test() -> void:
	Mind.reset()
	world._start()


func after_test() -> void:
	world._talk.hide()
	world._tablet.hide()
	get_tree().paused = false


func after() -> void:
	Case.reset()
	Mind.reset()
	get_tree().paused = false


func test_the_case_starts_in_the_lab() -> void:
	assert_str(world.room).is_equal(Case.RECOVERY_ROOM)
	assert_float(world.detective.position.x).is_equal_approx(Case.RECOVERY_X * RoomLayout.SCALE, 0.01)
	assert_float(world.detective.position.y).is_equal(RoomLayout.WALK_Y)


func test_every_room_has_a_scene() -> void:
	for id: String in world.market.rooms:
		assert_bool(world._scenes.has(id)).is_true()
	assert_object(world._scenes["market"]).is_instanceof(MarketScene)
	assert_object(world._scenes["stall"]).is_instanceof(StallScene)
	assert_object(world._scenes["cold"]).is_instanceof(StandInScene)


func test_only_the_room_he_is_in_shows() -> void:
	world.arrive("market", 300.0)
	assert_bool(world._scenes["market"].play.visible).is_true()
	assert_bool(world._scenes["lab"].play.visible).is_false()


func test_hostiles_wait_in_their_room() -> void:
	Case.spawn_hostiles("apt", 2)
	world.arrive("apt", 60.0)
	assert_int(world._room_root.get_children().filter(func(n: Node) -> bool: return n is Hostile).size()).is_equal(2)


func test_the_world_freezes_while_he_talks() -> void:
	world.arrive("market", RoomLayout.OSK_X)
	assert_bool(world.busy()).is_false()
	world.interact()
	assert_bool(world._talk.visible).is_true()
	assert_bool(world.busy()).is_true()


func test_the_game_finds_the_etching_by_examining_the_chip() -> void:
	assert_bool(world.market.etching_by_examining).is_true()
	assert_array(world._pockets()).is_empty()
	Case.set_flag("has_chip")
	assert_str(world._pockets()[0].id).is_equal("chip")
