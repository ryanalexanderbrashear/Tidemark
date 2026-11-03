class_name CaseCatalog
extends RefCounted
## Loads the case's clues and theories from data/ (one .tres per id).

const CLUES_DIR: String = "res://data/clues"
const THEORIES_DIR: String = "res://data/theories"

static var _clues: Dictionary[String, Clue] = {}
static var _theories: Array[Theory] = []


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
	_theories.sort_custom(func(a: Theory, b: Theory) -> bool: return a.order < b.order)


static func _load_dir(dir: String) -> Array[Resource]:
	var found: Array[Resource] = []
	for file: String in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres"):
			found.append(load(dir.path_join(file)))
	return found
