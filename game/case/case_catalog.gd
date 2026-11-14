class_name CaseCatalog
extends RefCounted
## Loads the case's clues, theories, story beats and memory readings from data/ (one .tres per id).

const CLUES_DIR: String = "res://data/clues"
const THEORIES_DIR: String = "res://data/theories"
const BEATS_DIR: String = "res://data/beats"
const READINGS_DIR: String = "res://data/readings"

static var _clues: Dictionary[String, Clue] = {}
static var _theories: Array[Theory] = []
static var _beats: Dictionary[String, StoryBeat] = {}
static var _readings: Dictionary[String, Reading] = {}


static func clue(id: String) -> Clue:
	_ensure_loaded()
	return _clues.get(id) as Clue


static func has_clue(id: String) -> bool:
	_ensure_loaded()
	return _clues.has(id)


static func all_clues() -> Array[Clue]:
	_ensure_loaded()
	var out: Array[Clue] = []
	out.assign(_clues.values())
	return out


static func theory(id: String) -> Theory:
	_ensure_loaded()
	for t: Theory in _theories:
		if t.id == id:
			return t
	return null


static func theories() -> Array[Theory]:
	_ensure_loaded()
	return _theories.duplicate()


static func beat(id: String) -> StoryBeat:
	_ensure_loaded()
	return _beats.get(id) as StoryBeat


## Every beat, in timeline order.
static func timeline() -> Array[StoryBeat]:
	_ensure_loaded()
	var out: Array[StoryBeat] = []
	out.assign(_beats.values())
	out.sort_custom(func(a: StoryBeat, b: StoryBeat) -> bool: return a.minutes() < b.minutes())
	return out


static func reading(id: String) -> Reading:
	_ensure_loaded()
	return _readings.get(id) as Reading


static func all_readings() -> Array[Reading]:
	_ensure_loaded()
	var out: Array[Reading] = []
	out.assign(_readings.values())
	return out


## Leftover clues bleed-through can plant, in the order it plants them.
## DESIGN-TBD: Q2 (case 1's leftover_* clues in data/clues/ are placeholders)
static func leftovers() -> Array[String]:
	_ensure_loaded()
	var out: Array[String] = []
	for c: Clue in _clues.values():
		if c.leftover:
			out.append(c.id)
	out.sort()
	return out


static func _ensure_loaded() -> void:
	if not _clues.is_empty():
		return
	for res: Resource in _load_dir(CLUES_DIR):
		var c: Clue = res as Clue
		if c != null:
			_clues[c.id] = c
	for res: Resource in _load_dir(THEORIES_DIR):
		var t: Theory = res as Theory
		if t != null:
			_theories.append(t)
	for res: Resource in _load_dir(BEATS_DIR):
		var b: StoryBeat = res as StoryBeat
		if b != null:
			_beats[b.id] = b
	for res: Resource in _load_dir(READINGS_DIR):
		var r: Reading = res as Reading
		if r != null:
			_readings[r.id] = r
	_theories.sort_custom(func(a: Theory, b: Theory) -> bool: return a.order < b.order)


static func _load_dir(dir: String) -> Array[Resource]:
	var found: Array[Resource] = []
	for file: String in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres"):
			found.append(load(dir.path_join(file)))
	return found
