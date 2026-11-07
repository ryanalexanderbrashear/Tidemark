class_name ArtSound
extends RefCounted
## Placeholder sounds for the art test, made in code: no audio files yet, and
## these are only for testing how the scene feels with sound. The Look and Feel
## doc puts rain and water at the centre and wants handling evidence to feel
## tactile, so that's what's here:
##
## - loops: rain on the market, water slapping the stilts, the hum of Vale's
##   failing lamp;
## - one-shots: picking an item up, turning it, finding its detail, a catch
##   opening, paper, the case board, and a dialogue box opening.
##
## Everything is seeded noise and simple tones, so it sounds the same every run.
## Real sound design replaces all of it.

const RATE: int = 22050
## Loop lengths in seconds. The hum is a whole number of its cycles long.
const RAIN_SECONDS: float = 4.0
const WATER_SECONDS: float = 6.0
const HUM_SECONDS: float = 1.0
const HUM_HZ: float = 60.0
## Samples crossfaded where a loop wraps, so it never clicks.
const SEAM: int = 2048

const ONE_SHOTS: Array[String] = ["pickup", "turn", "found", "catch", "paper", "board", "talk"]


## Rain: a bright hiss over a softer roar, with drops landing on tarp and
## planks.
static func rain() -> AudioStreamWAV:
	var n: int = int(RAIN_SECONDS * RATE)
	var rng: RandomNumberGenerator = _rng(9)
	var out: PackedFloat32Array = _noise(n + SEAM, rng)
	var low: PackedFloat32Array = _lowpass(out, 0.08)
	var hiss: PackedFloat32Array = _highpass(out, 0.6)
	for i: int in range(out.size()):
		out[i] = low[i] * 0.9 + hiss[i] * 0.22
	# Drops: short bright ticks, some close and loud, most far.
	for d: int in range(int(RAIN_SECONDS * 90.0)):
		var at: int = rng.randi_range(0, n + SEAM - 400)
		var loud: float = 0.05 + pow(rng.randf(), 3.0) * 0.25
		var tone: float = rng.randf_range(900.0, 3200.0)
		for j: int in range(300):
			var env: float = exp(-float(j) / 40.0)
			out[at + j] += sin(TAU * tone * float(j) / RATE) * env * loud
	return _loop(out, n, 0.55)


## Water against the stilts: a low wash that swells and falls a few times a
## loop, with small slaps on the swell.
static func water() -> AudioStreamWAV:
	var n: int = int(WATER_SECONDS * RATE)
	var rng: RandomNumberGenerator = _rng(23)
	var out: PackedFloat32Array = _lowpass(_lowpass(_noise(n + SEAM, rng), 0.02), 0.05)
	for i: int in range(out.size()):
		var t: float = float(i) / float(n)
		# Three swells a loop, so the swell lines up across the seam.
		var swell: float = 0.55 + 0.45 * sin(TAU * 3.0 * t)
		out[i] *= swell * 7.0
	for s: int in range(14):
		var at: int = rng.randi_range(0, n + SEAM - 2200)
		var loud: float = rng.randf_range(0.05, 0.16)
		for j: int in range(2200):
			var env: float = sin(PI * float(j) / 2200.0) * exp(-float(j) / 700.0)
			out[at + j] += (rng.randf() * 2.0 - 1.0) * env * loud
	return _loop(_lowpass(out, 0.25), n, 0.6)


## A failing tube's hum: mains buzz with its harmonics, and a crackle now
## and then.
static func hum() -> AudioStreamWAV:
	var n: int = int(HUM_SECONDS * RATE)
	var rng: RandomNumberGenerator = _rng(5)
	var out: PackedFloat32Array = []
	out.resize(n)
	for i: int in range(n):
		var t: float = float(i) / RATE
		var v: float = 0.0
		for h: int in [1, 2, 3, 5, 7]:
			v += sin(TAU * HUM_HZ * h * t) / float(h * h) * (1.0 if h != 2 else 1.6)
		out[i] = v * 0.35
	for c: int in range(6):
		var at: int = rng.randi_range(0, n - 120)
		for j: int in range(120):
			out[at + j] += (rng.randf() * 2.0 - 1.0) * 0.15 * exp(-float(j) / 30.0)
	return _to_wav(out, true, 0.5)


static func one_shot(name: String) -> AudioStreamWAV:
	match name:
		"pickup":
			return _rustle(0.28, 31, 0.12, 0.6)
		"turn":
			return _tick(0.06, 1800.0, 0.25)
		"found":
			return _found()
		"catch":
			return _catch()
		"paper":
			return _rustle(0.35, 47, 0.35, 0.5)
		"board":
			return _rustle(0.5, 53, 0.2, 0.55)
		"talk":
			return _tick(0.09, 640.0, 0.18)
	assert(false, "No sound %s" % name)
	return null


# ---------- one-shots ----------

## Cloth or paper moving: shaped noise. `bright` is the high-pass amount.
static func _rustle(seconds: float, seed_value: int, bright: float, peak: float) -> AudioStreamWAV:
	var n: int = int(seconds * RATE)
	var rng: RandomNumberGenerator = _rng(seed_value)
	var raw: PackedFloat32Array = _noise(n, rng)
	var hi: PackedFloat32Array = _highpass(raw, bright)
	var out: PackedFloat32Array = []
	out.resize(n)
	var grain: float = 0.0
	for i: int in range(n):
		var t: float = float(i) / float(n)
		# Crinkles: the level jumps around inside a soft envelope.
		if i % 220 == 0:
			grain = rng.randf_range(0.3, 1.0)
		out[i] = hi[i] * sin(PI * t) * grain
	return _to_wav(_lowpass(out, 0.5), false, peak)


## A small hard knock: a tone that dies fast over a click of noise.
static func _tick(seconds: float, tone: float, peak: float) -> AudioStreamWAV:
	var n: int = int(seconds * RATE)
	var rng: RandomNumberGenerator = _rng(int(tone))
	var out: PackedFloat32Array = []
	out.resize(n)
	for i: int in range(n):
		var env: float = exp(-float(i) / (n * 0.18))
		out[i] = (sin(TAU * tone * float(i) / RATE) * 0.7 + (rng.randf() * 2.0 - 1.0) * 0.3 * exp(-float(i) / 60.0)) * env
	return _to_wav(out, false, peak)


## The find: two low, close notes, quiet. It confirms; it doesn't fanfare.
static func _found() -> AudioStreamWAV:
	var n: int = int(0.9 * RATE)
	var out: PackedFloat32Array = []
	out.resize(n)
	for i: int in range(n):
		var t: float = float(i) / RATE
		var a: float = sin(TAU * 220.0 * t) * exp(-t * 4.0)
		var b: float = 0.0
		if t > 0.16:
			var u: float = t - 0.16
			b = sin(TAU * 293.66 * u) * exp(-u * 3.5) * minf(1.0, u * 60.0)
		out[i] = (a + b * 0.9) * minf(1.0, t * 80.0)
	return _to_wav(out, false, 0.3)


## A slide catch giving: a scrape and a metal click with a short ring.
static func _catch() -> AudioStreamWAV:
	var n: int = int(0.4 * RATE)
	var rng: RandomNumberGenerator = _rng(77)
	var out: PackedFloat32Array = []
	out.resize(n)
	var click: int = int(0.12 * RATE)
	for i: int in range(n):
		var v: float = 0.0
		if i < click:
			v += (rng.randf() * 2.0 - 1.0) * 0.25 * sin(PI * float(i) / click)
		else:
			var j: float = float(i - click)
			v += (sin(TAU * 2600.0 * j / RATE) * 0.6 + sin(TAU * 4100.0 * j / RATE) * 0.3) * exp(-j / 500.0)
			v += (rng.randf() * 2.0 - 1.0) * exp(-j / 40.0)
		out[i] = v
	return _to_wav(out, false, 0.5)


# ---------- helpers ----------

static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _noise(n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = []
	out.resize(n)
	for i: int in range(n):
		out[i] = rng.randf() * 2.0 - 1.0
	return out


## One-pole low-pass: `a` near 0 is dark, 1 lets everything through.
static func _lowpass(input: PackedFloat32Array, a: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = input.duplicate()
	var y: float = 0.0
	for i: int in range(out.size()):
		y += a * (input[i] - y)
		out[i] = y
	return out


static func _highpass(input: PackedFloat32Array, a: float) -> PackedFloat32Array:
	var low: PackedFloat32Array = _lowpass(input, 1.0 - a)
	var out: PackedFloat32Array = input.duplicate()
	for i: int in range(out.size()):
		out[i] = input[i] - low[i]
	return out


## Folds the last SEAM samples over the first ones, so `n` samples loop
## without a click.
static func _loop(input: PackedFloat32Array, n: int, peak: float) -> AudioStreamWAV:
	var out: PackedFloat32Array = input.slice(0, n)
	for i: int in range(SEAM):
		var t: float = float(i) / float(SEAM)
		out[i] = input[n + i] * (1.0 - t) + input[i] * t
	return _to_wav(out, true, peak)


## Normalises to `peak` and packs as 16-bit mono.
static func _to_wav(samples: PackedFloat32Array, looped: bool, peak: float) -> AudioStreamWAV:
	var top: float = 0.0001
	for v: float in samples:
		top = maxf(top, absf(v))
	var gain: float = peak / top
	var data: PackedByteArray = []
	data.resize(samples.size() * 2)
	for i: int in range(samples.size()):
		data.encode_s16(i * 2, clampi(roundi(samples[i] * gain * 32767.0), -32767, 32767))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav
