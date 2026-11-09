extends GdUnitTestSuite
## The closer-to-final cast (ArtCast on ArtFigure): everyone stands on the
## walkway line, fits their canvas, really animates, splits cleanly into
## layers, and the exported Aseprite file holds what was drawn.

const WRITER = preload("res://editor/art/aseprite_writer.gd")


func test_everyone_stands_on_the_third_row_from_the_bottom() -> void:
	# Like every sprite in the art test, so _place lines them up on the walkway.
	for id: String in ArtCast.IDS:
		for anim: String in ArtCast.anims(id):
			var frames: Array[Image] = ArtCast.frames(id, anim)
			for f: int in range(frames.size()):
				var img: Image = frames[f]
				var h: int = img.get_height()
				# Vale's passenger comes apart before her feet: she has none to stand
				# on. A sprint leaves the ground between strides (frames 3 and 7).
				var airborne: bool = anim == "run" and f % 4 == 3
				if id != "vale" and not airborne:
					assert_bool(_row_has_pixels(img, h - 3)).override_failure_message("%s %s: no soles on row h-3" % [id, anim]).is_true()
				assert_bool(_row_has_pixels(img, h - 1)).override_failure_message("%s %s: pixels below the soles" % [id, anim]).is_false()


func test_nobody_is_cut_off_by_their_canvas() -> void:
	for id: String in ArtCast.IDS:
		for anim: String in ArtCast.anims(id):
			for img: Image in ArtCast.frames(id, anim):
				var used: Rect2i = img.get_used_rect()
				assert_bool(used.position.x > 0 and used.end.x < img.get_width() and used.position.y > 0) \
					.override_failure_message("%s %s touches the canvas edge: %s" % [id, anim, used]).is_true()


func test_every_frame_of_an_animation_is_different() -> void:
	for id: String in ArtCast.IDS:
		for anim: String in ArtCast.anims(id):
			var seen: Array[PackedByteArray] = []
			for img: Image in ArtCast.frames(id, anim):
				var data: PackedByteArray = img.get_data()
				if anim != "idle":
					assert_bool(data in seen).override_failure_message("%s %s repeats a frame" % [id, anim]).is_false()
				seen.append(data)
			# Idle frames breathe: at least two differ.
			assert_bool(seen[0] != seen[seen.size() - 1]).override_failure_message("%s %s doesn't move" % [id, anim]).is_true()


func test_drawing_is_the_same_every_time() -> void:
	for id: String in ArtCast.IDS:
		assert_bool(ArtCast.frame(id, ArtCast.anims(id).keys()[0], 1).get_data() == ArtCast.frame(id, ArtCast.anims(id).keys()[0], 1).get_data()).is_true()


func test_layers_put_back_together_make_the_frame() -> void:
	for id: String in ArtCast.IDS:
		for anim: String in ArtCast.anims(id):
			var layers: Dictionary = {}
			var img: Image = ArtCast.frame(id, anim, 2, layers)
			assert_array(layers.keys()).contains_exactly(ArtFigure.PARTS)
			var joined: Image = Px.blank(img.get_width(), img.get_height())
			for part: String in ArtFigure.PARTS:
				var layer: Image = layers[part]
				for y: int in range(img.get_height()):
					for x: int in range(img.get_width()):
						var c: Color = layer.get_pixel(x, y)
						if c.a > 0.0:
							assert_float(joined.get_pixel(x, y).a).override_failure_message("%s: two layers share a pixel" % id).is_equal(0.0)
							joined.set_pixel(x, y, c)
			assert_bool(joined.get_data() == img.get_data()).override_failure_message("%s %s layers don't add up" % [id, anim]).is_true()


func test_blood_red_stays_off_the_cast() -> void:
	# Look and Feel: blood red is kept for blood.
	for id: String in ArtCast.IDS:
		for anim: String in ArtCast.anims(id):
			for img: Image in ArtCast.frames(id, anim):
				for y: int in range(img.get_height()):
					for x: int in range(img.get_width()):
						assert_bool(img.get_pixel(x, y).is_equal_approx(ArtPalette.BLOOD)).is_false()


func test_aseprite_file_holds_the_frames_layers_and_tags() -> void:
	var path: String = "user://test-cast.aseprite"
	var layers: Dictionary = {}
	var img: Image = ArtCast.frame("osk", "idle", 0, layers)
	var names: Array[String] = ["legs", "body"]
	assert_int(WRITER.write(path, img.get_size(), names, [layers, layers], [500, 500], [["idle", 0, 1]])).is_equal(OK)
	var data: PackedByteArray = FileAccess.get_file_as_bytes(path)
	assert_int(data.decode_u32(0)).is_equal(data.size())
	assert_int(data.decode_u16(4)).is_equal(0xA5E0)
	assert_int(data.decode_u16(6)).is_equal(2)
	assert_int(data.decode_u16(8)).is_equal(img.get_width())
	assert_int(data.decode_u16(12)).is_equal(32)
	# Walk the first frame's chunks: two layers, a palette, the tag, two cels.
	var at: int = 128
	assert_int(data.decode_u16(at + 4)).is_equal(0xF1FA)
	var chunks: int = data.decode_u32(at + 12)
	var types: Array[int] = []
	var p: int = at + 16
	var legs: Image = null
	for i: int in range(chunks):
		var size: int = data.decode_u32(p)
		var type: int = data.decode_u16(p + 4)
		types.append(type)
		if type == WRITER.CHUNK_CEL and data.decode_u16(p + 6) == 0:
			var w: int = data.decode_u16(p + 6 + 16)
			var h: int = data.decode_u16(p + 6 + 18)
			var px: PackedByteArray = data.slice(p + 6 + 20, p + size).decompress(w * h * 4, FileAccess.COMPRESSION_DEFLATE)
			legs = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, px)
		p += size
	assert_array(types).contains_exactly([WRITER.CHUNK_LAYER, WRITER.CHUNK_LAYER, WRITER.CHUNK_PALETTE, WRITER.CHUNK_TAGS, WRITER.CHUNK_CEL, WRITER.CHUNK_CEL])
	var drawn: Image = layers["legs"]
	assert_bool(legs.get_data() == drawn.get_region(drawn.get_used_rect()).get_data()).is_true()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_everyone_is_built_on_eight_heads() -> void:
	# SLYNYRD's chart: a head is 9 px at full height, crotch at half height,
	# wrist level with the crotch, knee at six heads.
	for id: String in ArtCast.IDS:
		var b: ArtFigure.Build = ArtCast.build(id)
		var unit: float = ArtFigure.FULL_HEIGHT * b.stature / 8.0
		var sole: float = b.sole_y
		assert_float((sole - b.top_y) / unit).is_equal_approx(8.0, 0.01)
		assert_float(b.hip_y - b.top_y).is_between(unit * 3.7, unit * 4.1)
		var wrist: float = b.shoulder_y + 2.5 * ArtFigure.K + b.upper_arm + b.forearm
		assert_float(wrist - b.top_y).is_between(unit * 3.9, unit * 4.4)
		var knee: float = b.hip_y + b.thigh
		assert_float(knee - b.top_y).is_between(unit * 5.8, unit * 6.4)


func test_the_bare_body_is_drawn_in_chart_colours_only() -> void:
	var img: Image = ArtCast.dummy("detective")
	var allowed: Array[Color] = [ArtFigure.DUMMY_HEAD, ArtFigure.DUMMY_NECK, ArtFigure.DUMMY_TORSO, ArtFigure.DUMMY_ARM, ArtFigure.DUMMY_LEG, ArtFigure.DUMMY_FAR]
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0:
				assert_bool(allowed.any(func(a: Color) -> bool: return a.is_equal_approx(c))).is_true()
	# And drawing it leaves the dressed character as it was.
	assert_bool(ArtCast.build("detective").dummy).is_false()


func test_doors_and_counters_fit_the_cast() -> void:
	# Everyone gets through a doorway without stooping, and a counter comes to
	# about the hip, between the waist and the crotch.
	for id: String in ArtCast.IDS:
		var b: ArtFigure.Build = ArtCast.build(id)
		var sole: float = b.sole_y
		assert_float(sole - b.top_y).is_less(MarketArt.DOOR_H - 4.0)
		if b.stature >= 1.0:
			assert_float(float(MarketArt.COUNTER_H)).is_between(sole - b.hip_y, sole - b.belt_y)
		# And the canvas really is the soles' third row from the bottom.
		assert_float(b.sole_y).is_equal(float(b.size.y) - 2.0)


func test_the_detective_sprints() -> void:
	# His reinforced legs: a run cycle as long as the walk, covering far more
	# ground a cycle, with both feet off the floor between strides.
	var anims: Dictionary[String, int] = ArtCast.anims("detective")
	assert_int(anims.get("run", 0)).is_equal(anims["walk"])
	var b: ArtFigure.Build = ArtCast.build("detective")
	assert_float(b.run_stride).is_greater(b.stride * 1.5)
	var air: ArtFigure.Pose = ArtFigure.run_pose(b, 3)
	assert_float(air.far_foot.y).is_less(b.ankle_y)
	assert_float(air.near_foot.y).is_less(b.ankle_y)
	# He leans into it and his arms pump bent at the elbow.
	var p: ArtFigure.Pose = ArtFigure.run_pose(b, 0)
	assert_int(p.lean).is_greater(0)
	assert_float(p.near_bend).is_greater(1.0)
	assert_float(p.far_bend).is_greater(1.0)


func test_a_planted_foot_slides_back_at_sprinting_speed() -> void:
	# The scene picks run frames by distance (run_stride / 8 a frame), so a foot
	# on the floor has to slide back by exactly that much each frame.
	var b: ArtFigure.Build = ArtCast.build("detective")
	var step: float = b.run_stride / 8.0
	for f: int in range(2):
		var a: Vector2 = ArtFigure._run_foot(b, f)[0]
		var z: Vector2 = ArtFigure._run_foot(b, f + 1)[0]
		assert_float(a.x - z.x).is_equal_approx(step, 0.001)
		assert_float(a.y).is_equal(b.ankle_y)
		assert_float(z.y).is_equal(b.ankle_y)


func test_sprinting_in_the_scene_matches_the_run_cycle() -> void:
	# About 1.5 cycles a second, so the legs keep up with the ground, and well
	# over twice walking pace.
	var cycles: float = Detective.SPRINT_SPEED / ArtCast.build("detective").run_stride
	assert_float(cycles).is_between(1.2, 1.8)
	assert_float(Detective.SPRINT_SPEED).is_greater(Detective.SPEED * 2.0)


func _row_has_pixels(img: Image, y: int) -> bool:
	for x: int in range(img.get_width()):
		if img.get_pixel(x, y).a > 0.5:
			return true
	return false
