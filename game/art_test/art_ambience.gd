class_name ArtAmbience
extends Node
## Plays the art test's placeholder sound (ArtSound): rain and water all the
## time, the hum of Vale's lamp louder as the detective nears it (and gone when
## it stutters off), and the one-shots for handling evidence, the board and
## dialogue.
##
## The Look and Feel doc wants the world muted during investigation, so while
## a dialogue box, the board or an item close-up is up, the rain and water go
## behind a low-pass filter and drop a little: the detective's attention
## narrows. One-shots stay clear, since they're what he's doing.

const AMBIENCE_BUS: String = "ArtAmbience"
const FX_BUS: String = "ArtFx"
## Low-pass cutoff (Hz) when the world is clear, and when it's muffled.
const CLEAR_HZ: float = 18000.0
const MUFFLED_HZ: float = 700.0
const MUFFLED_DB: float = -7.0
## Seconds to muffle or clear.
const FADE: float = 0.35
const RAIN_DB: float = -9.0
const WATER_DB: float = -11.0
## The hum at its loudest (standing under the lamp), and how far it carries.
const HUM_DB: float = -16.0
const HUM_RANGE: float = 220.0

## 0: clear, 1: fully muffled.
var muffle: float = 0.0
var muffled: bool = false
## Under a roof (Vale's stall): the rain is on the tarp overhead, further off.
var indoors: bool = false
const INDOORS_DB: float = -8.0

var _rain: AudioStreamPlayer
var _water: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _shots: Dictionary[String, AudioStream] = {}
var _fx: AudioStreamPlayer
var _filter: AudioEffectLowPassFilter


func _ready() -> void:
	var bus: int = _bus(AMBIENCE_BUS)
	_filter = AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	_bus(FX_BUS, false)
	_rain = _player(ArtSound.rain(), AMBIENCE_BUS, RAIN_DB)
	_water = _player(ArtSound.water(), AMBIENCE_BUS, WATER_DB)
	_hum = _player(ArtSound.hum(), AMBIENCE_BUS, -60.0)
	for name: String in ArtSound.ONE_SHOTS:
		_shots[name] = ArtSound.one_shot(name)
	_fx = AudioStreamPlayer.new()
	_fx.bus = FX_BUS
	_fx.max_polyphony = 4
	add_child(_fx)
	for p: AudioStreamPlayer in [_rain, _water, _hum]:
		p.play()
	_apply()


func _exit_tree() -> void:
	for p: AudioStreamPlayer in [_rain, _water, _hum, _fx]:
		p.stop()


## The art test's own buses, made once and reused (tests make many scenes).
static func _bus(name: String, filtered: bool = true) -> int:
	var at: int = AudioServer.get_bus_index(name)
	if at >= 0:
		return at
	AudioServer.add_bus()
	at = AudioServer.bus_count - 1
	AudioServer.set_bus_name(at, name)
	AudioServer.set_bus_send(at, "Master")
	if filtered:
		var lp: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
		lp.cutoff_hz = CLEAR_HZ
		AudioServer.add_bus_effect(at, lp, 0)
	return at


func _player(stream: AudioStream, bus: String, db: float) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = db
	add_child(p)
	return p


func play(name: String) -> void:
	assert(_shots.has(name), "No sound %s" % name)
	_fx.stream = _shots[name]
	_fx.play()


## How loud the lamp's hum is with the detective `distance` px from it, and
## the lamp on or off.
static func hum_db(distance: float, lamp_on: bool) -> float:
	if not lamp_on:
		return -60.0
	var t: float = clampf(1.0 - absf(distance) / HUM_RANGE, 0.0, 1.0)
	return lerpf(-60.0, HUM_DB, t * t)


func update(delta: float, distance_to_lamp: float, lamp_on: bool) -> void:
	muffle = move_toward(muffle, 1.0 if muffled else 0.0, delta / FADE)
	_hum.volume_db = hum_db(distance_to_lamp, lamp_on)
	_rain.volume_db = RAIN_DB + (INDOORS_DB if indoors else 0.0)
	_water.volume_db = WATER_DB + (INDOORS_DB * 1.5 if indoors else 0.0)
	_apply()


func _apply() -> void:
	var e: float = muffle * muffle * (3.0 - 2.0 * muffle)
	_filter.cutoff_hz = exp(lerpf(log(CLEAR_HZ), log(MUFFLED_HZ), e))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AMBIENCE_BUS), MUFFLED_DB * e)
