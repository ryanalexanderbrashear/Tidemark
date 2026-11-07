extends GdUnitTestSuite
## The art test's placeholder sound: loops loop without a click, nothing
## clips, everything sounds the same every run, and the lamp's hum follows
## the lamp.


func _sample(wav: AudioStreamWAV, i: int) -> float:
	return float(wav.data.decode_s16(i * 2)) / 32767.0


func _length(wav: AudioStreamWAV) -> int:
	return wav.data.size() / 2


func _peak(wav: AudioStreamWAV) -> float:
	var top: float = 0.0
	for i: int in range(_length(wav)):
		top = maxf(top, absf(_sample(wav, i)))
	return top


func test_loops_are_set_to_loop_over_their_whole_length() -> void:
	for wav: AudioStreamWAV in [ArtSound.rain(), ArtSound.water(), ArtSound.hum()]:
		assert_int(wav.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
		assert_int(wav.loop_begin).is_equal(0)
		assert_int(wav.loop_end).is_equal(_length(wav))


func test_loops_wrap_without_a_jump() -> void:
	# The last sample runs into the first: a big step there would click.
	for wav: AudioStreamWAV in [ArtSound.rain(), ArtSound.water(), ArtSound.hum()]:
		var n: int = _length(wav)
		var step: float = absf(_sample(wav, n - 1) - _sample(wav, 0))
		var typical: float = 0.0
		for i: int in range(1, 2000):
			typical = maxf(typical, absf(_sample(wav, i) - _sample(wav, i - 1)))
		assert_float(step).is_less_equal(typical + 0.001)


func test_the_hum_is_a_whole_number_of_cycles() -> void:
	var cycles: float = ArtSound.HUM_HZ * ArtSound.HUM_SECONDS
	assert_float(cycles - floorf(cycles)).is_equal(0.0)


func test_nothing_clips() -> void:
	var all: Array[AudioStreamWAV] = [ArtSound.rain(), ArtSound.water(), ArtSound.hum()]
	for name: String in ArtSound.ONE_SHOTS:
		all.append(ArtSound.one_shot(name))
	for wav: AudioStreamWAV in all:
		assert_float(_peak(wav)).is_less_equal(0.61)
		assert_float(_peak(wav)).is_greater(0.05)


func test_one_shots_play_once() -> void:
	for name: String in ArtSound.ONE_SHOTS:
		assert_int(ArtSound.one_shot(name).loop_mode).is_equal(AudioStreamWAV.LOOP_DISABLED)


func test_sounds_are_the_same_every_run() -> void:
	assert_bool(ArtSound.rain().data == ArtSound.rain().data).is_true()
	assert_bool(ArtSound.one_shot("paper").data == ArtSound.one_shot("paper").data).is_true()


func test_the_hum_follows_the_lamp() -> void:
	assert_float(ArtAmbience.hum_db(0.0, true)).is_equal(ArtAmbience.HUM_DB)
	assert_float(ArtAmbience.hum_db(60.0, true)).is_less(ArtAmbience.HUM_DB)
	assert_float(ArtAmbience.hum_db(60.0, true)).is_greater(ArtAmbience.hum_db(150.0, true))
	assert_float(ArtAmbience.hum_db(ArtAmbience.HUM_RANGE + 10.0, true)).is_equal(-60.0)
	assert_float(ArtAmbience.hum_db(0.0, false)).is_equal(-60.0)


func test_the_world_muffles_while_he_is_busy_and_clears_after() -> void:
	var amb: ArtAmbience = auto_free(ArtAmbience.new())
	add_child(amb)
	amb.muffled = true
	amb.update(ArtAmbience.FADE, 0.0, true)
	assert_float(amb.muffle).is_equal(1.0)
	amb.muffled = false
	amb.update(ArtAmbience.FADE * 0.5, 0.0, true)
	assert_float(amb.muffle).is_equal_approx(0.5, 0.001)
	amb.update(ArtAmbience.FADE, 0.0, true)
	assert_float(amb.muffle).is_equal(0.0)
