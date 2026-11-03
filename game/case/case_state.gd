extends Node
## The running case (autoload `Case`): the clock, the badge, what the detective
## has found and committed, story flags, and which rooms still have hostiles.
## Gameplay and UI read and change the case only through here, so tests can play
## the whole case without a scene.

signal clue_found(clue: Clue)
signal facts_changed
signal clock_changed(minutes: int)
signal clearance_changed(active: bool)
## A short line for the toast at the bottom of the screen.
signal notice(text: String)
signal killer_struck
## The world should load `room` and put the detective at `x`.
signal travel_requested(room: String, x: float)
signal case_closed(summary: CaseSummary)

const START_MINUTES: int = 23 * 60
## 06:00 the next morning. Past this, the killer strikes again (once).
const DEADLINE_MINUTES: int = 30 * 60
## After 01:30 the body is moved to the precinct morgue.
const BODY_MOVED_MINUTES: int = 25 * 60 + 30

const TRAVEL_MINUTES: int = 5
const FAILED_THEORY_MINUTES: int = 30
const OPTIC_MINUTES: int = 120
const DOWNED_MINUTES: int = 90
const FALLOUT_MINUTES: int = 60
const WRONG_NAME_MINUTES: int = 15

## Where the detective wakes after being downed.
const RECOVERY_ROOM: String = "lab"
const RECOVERY_X: float = 200.0

var minutes: int
var clearance: bool
var has_optic: bool
var optic_on: bool
var room: String
var clues: Array[String] = []
var facts: Array[String] = []
var flags: Dictionary[String, Variant] = {}
## Hostiles still standing, per room. Rooms not listed have none.
var hostiles: Dictionary[String, int] = {}
var closed: bool


func _ready() -> void:
	reset()


func reset() -> void:
	minutes = START_MINUTES
	clearance = true
	has_optic = false
	optic_on = false
	room = RECOVERY_ROOM
	clues.clear()
	facts.clear()
	flags.clear()
	hostiles.clear()
	closed = false


# ---------- clock ----------

func advance(by: int, why: String = "") -> void:
	minutes += by
	clock_changed.emit(minutes)
	if why != "":
		notice.emit("%s  (+%s)" % [why, duration_text(by)])
	if not flag("second_victim") and minutes >= DEADLINE_MINUTES and not closed:
		set_flag("second_victim")
		killer_struck.emit()


func minutes_left() -> int:
	return DEADLINE_MINUTES - minutes


static func clock_text(m: int) -> String:
	var day: int = posmod(m, 1440)
	return "%02d:%02d" % [day / 60, day % 60]


static func duration_text(m: int) -> String:
	if m >= 60 and m % 60 == 0:
		return "%dh" % (m / 60)
	if m >= 60:
		return "%dh%02dm" % [m / 60, m % 60]
	return "%dm" % m


func body_in_morgue() -> bool:
	return minutes >= BODY_MOVED_MINUTES or not clearance


# ---------- clues and theories ----------

func has_clue(id: String) -> bool:
	return clues.has(id)


## Adds a clue. Returns false if it was already found.
func find_clue(id: String) -> bool:
	assert(CaseCatalog.has_clue(id), "Unknown clue %s" % id)
	if clues.has(id):
		return false
	clues.append(id)
	var c: Clue = CaseCatalog.clue(id)
	clue_found.emit(c)
	notice.emit("New clue: %s  (Tab opens the case board)" % c.title)
	return true


func has_fact(id: String) -> bool:
	return facts.has(id)


## Theories the board shows: any whose clues the detective has started finding.
func visible_theories() -> Array[Theory]:
	var out: Array[Theory] = []
	for t: Theory in CaseCatalog.theories():
		for id: String in t.shown_by:
			if clues.has(id):
				out.append(t)
				break
	return out


## Tries to commit a theory with the selected clues. A failure costs time.
func commit_theory(id: String, selected: Array[String]) -> TheoryCheck.Result:
	var t: Theory = CaseCatalog.theory(id)
	assert(t != null, "Unknown theory %s" % id)
	var result: TheoryCheck.Result = TheoryCheck.evaluate(t, selected, clues)
	if result == TheoryCheck.Result.NOT_ENOUGH or result == TheoryCheck.Result.DOESNT_FIT:
		advance(FAILED_THEORY_MINUTES)
	if result != TheoryCheck.Result.HOLDS:
		return result
	if not facts.has(id):
		facts.append(id)
	if t.excludes != "":
		facts.erase(t.excludes)
	facts_changed.emit()
	return result


# ---------- flags ----------

func flag(id: String) -> Variant:
	return flags.get(id, false)


## A flag that holds text, or "" when unset.
func flag_text(id: String) -> String:
	var v: Variant = flags.get(id, "")
	return v if v is String else ""


func is_set(id: String) -> bool:
	return bool(flags.get(id, false))


func set_flag(id: String, value: Variant = true) -> void:
	flags[id] = value


# ---------- badge, optic ----------

func revoke_clearance() -> void:
	if not clearance:
		return
	clearance = false
	clearance_changed.emit(false)


func grant_optic() -> void:
	has_optic = true


func toggle_optic() -> bool:
	if has_optic:
		optic_on = not optic_on
	return optic_on


# ---------- rooms and hostiles ----------

## Moves to a room. Travel takes time unless `free` (the opening scene).
func travel(to: String, x: float, free: bool = false) -> void:
	room = to
	_on_enter(to)
	if not free:
		advance(TRAVEL_MINUTES)
	travel_requested.emit(to, x)


func hostiles_left(in_room: String) -> bool:
	return hostiles.get(in_room, 0) > 0


func hostile_down(in_room: String) -> void:
	hostiles[in_room] = maxi(0, hostiles.get(in_room, 0) - 1)


func spawn_hostiles(in_room: String, count: int) -> void:
	hostiles[in_room] = count


## The detective went down in a fight. They wake at the precinct, hours later.
## Nobody they were fighting goes away, but nothing is lost either.
func player_downed() -> void:
	travel(RECOVERY_ROOM, RECOVERY_X, true)
	advance(DOWNED_MINUTES, "You wake up in the precinct infirmary")


func _on_enter(to: String) -> void:
	match to:
		"cold":
			if not is_set("cold_spawned"):
				set_flag("cold_spawned")
				var forced: bool = flag_text("cold_entry") == "forced"
				spawn_hostiles("cold", 3 if forced else 0)
				if forced:
					notice.emit("The gang renting this space doesn't want police here. Without a badge, it gets loud.")
		"drop":
			if not is_set("drop_spawned"):
				set_flag("drop_spawned")
				spawn_hostiles("drop", 3)
				notice.emit("Trap drones. The killer expected to be followed.")


# ---------- ending ----------

func close_case() -> CaseSummary:
	closed = true
	var s: CaseSummary = CaseSummary.from_case(self)
	case_closed.emit(s)
	return s
