extends GdUnitTestSuite
## The shared view pieces: the camera stays inside a room, the cast stands on
## its feet, the inner voice says things in the right order, and toasts queue.


func test_the_camera_follows_the_detective_but_stays_in_the_room() -> void:
	var market: MarketScene = MarketScene.new()
	assert_float(market.cam_x(0.0)).is_equal(0.0)
	assert_float(market.cam_x(640.0)).is_equal(320.0)
	assert_float(market.cam_x(5000.0)).is_equal(float(MarketArt.ROOM.x - PixelView.NATIVE.x))
	# A one-screen room never scrolls.
	assert_float(StallScene.new().cam_x(500.0)).is_equal(0.0)


func test_a_cast_sprite_stands_with_its_feet_where_it_is_placed() -> void:
	var anims: Array[String] = ["idle", "walk"]
	var s: CastSprite = auto_free(CastSprite.new("osk", anims))
	s.place(100.0, MarketArt.WALK_Y, 40.0)
	assert_float(s.position.x + s.frame_size.x * 0.5).is_between(59.0, 61.0)
	assert_float(s.position.y + s.frame_size.y).is_equal(MarketArt.WALK_Y + 2.0)


func test_walk_frames_follow_the_distance_walked() -> void:
	var anims: Array[String] = ["walk"]
	var s: CastSprite = auto_free(CastSprite.new("detective", anims))
	var stride: float = ArtCast.build("detective").stride
	var n: int = s.frame_count("walk")
	s.step_at("walk", 0.0, stride)
	var first: Texture2D = s.texture
	s.step_at("walk", stride / float(n) + 0.01, stride)
	assert_object(s.texture).is_not_same(first)
	s.step_at("walk", stride + 0.01, stride)
	assert_object(s.texture).is_same(first)


func test_the_voice_narrates_first_then_the_case_then_its_thoughts() -> void:
	var v: InnerVoice = auto_free(InnerVoice.new())
	v.thoughts.assign(["one", "two"])
	v.narrate("opening")
	v.say("from the case")
	assert_str(v.current()).is_equal("opening")
	v.advance(100.0)
	assert_str(v.current()).is_equal("from the case")
	v.advance(100.0)
	assert_str(v.current()).is_equal("one")
	v.advance(100.0)
	assert_str(v.current()).is_equal("two")
	v.advance(100.0)
	assert_bool(v.quiet).is_true()
	assert_str(v.current()).is_equal("")


func test_an_answered_line_is_taken_back() -> void:
	var v: InnerVoice = auto_free(InnerVoice.new())
	v.say("turn it over")
	v.unsay("something else")
	assert_str(v.current()).is_equal("turn it over")
	v.unsay("turn it over")
	assert_str(v.current()).is_equal("")


func test_toasts_wait_their_turn() -> void:
	var n: Notices = auto_free(Notices.new())
	n.toast("first")
	n.toast("second")
	assert_array(n.toasts).contains_exactly(["first", "second"])
	n.clear_toasts()
	assert_array(n.toasts).is_empty()
