extends Node
## The running case (autoload `Case`): the clock, the badge, what the detective
## has found and committed, story flags, and which rooms still have hostiles.
## Gameplay and UI read and change the case only through here, so tests can play
## the whole case without a scene.

signal clue_found(clue: Clue)
signal facts_changed
## A beat on the timeline happened. The clock now shows at least its time.
signal beat_reached(beat: StoryBeat)
signal clearance_changed(active: bool)
## A short line for the toast at the bottom of the screen.
signal notice(text: String)
## A beat with a speaker: the world shows it as a dialogue box. `at` is the
## beat's own time, which can be earlier than the clock for an off-screen beat.
signal announcement(speaker: String, text: String, at: String)
## The world should load `room` and put the detective at `x`.
signal travel_requested(room: String, x: float)
signal case_closed(summary: CaseSummary)

## Where the detective wakes after being downed.
const RECOVERY_ROOM: String = "lab"
const RECOVERY_X: float = 200.0
## Off-screen beats the wrong-suspect raid sets in motion (Alex, 2026-11-03:
## the raid is what costs the second victim).
const RAID_CONSEQUENCES: Array[String] = ["rig_cleared", "second_victim"]

## The case clock: the time of the latest beat reached. Nothing else moves it.
var minutes: int
var clearance: bool
var has_optic: bool
var optic_on: bool
var room: String
var clues: Array[String] = []
var facts: Array[String] = []
var beats: Array[String] = []
var scheduled: Array[String] = []
var flags: Dictionary[String, Variant] = {}
## Hostiles still standing, per room. Rooms not listed have none.
var hostiles: Dictionary[String, int] = {}
var closed: bool


func _ready() -> void:
	reset()


func reset() -> void:
	clearance = true
	has_optic = false
	optic_on = false
	room = RECOVERY_ROOM
	clues.clear()
	facts.clear()
	beats.clear()
	scheduled.clear()
	flags.clear()
	hostiles.clear()
	closed = false
	minutes = 0
	reach("case_opens")


# ---------- the timeline ----------

func has_beat(id: String) -> bool:
	return beats.has(id)


## Marks a beat as happened and moves the clock up to its time (never back).
## Then any scheduled off-screen beat whose time has come happens too.
func reach(id: String) -> void:
	var b: StoryBeat = CaseCatalog.beat(id)
	assert(b != null, "Unknown beat %s" % id)
	if beats.has(id):
		return
	beats.append(id)
	scheduled.erase(id)
	minutes = maxi(minutes, b.minutes())
	_announce(b)
	beat_reached.emit(b)
	for later: String in scheduled.duplicate():
		if CaseCatalog.beat(later).minutes() <= minutes:
			reach(later)


## Sets an off-screen beat to happen once the clock reaches its time.
func schedule(id: String) -> void:
	assert(CaseCatalog.beat(id) != null, "Unknown beat %s" % id)
	if not beats.has(id) and not scheduled.has(id):
		scheduled.append(id)


func _announce(b: StoryBeat) -> void:
	if b.line == "":
		return
	if b.speaker != "":
		announcement.emit(b.speaker, b.line, b.time)
	else:
		notice.emit(b.line)


static func clock_text(m: int) -> String:
	var day: int = posmod(m, 1440)
	return "%02d:%02d" % [day / 60, day % 60]


func body_in_morgue() -> bool:
	return has_beat("body_removed")


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


## Tries to commit a theory with the selected clues. A failure costs nothing
## yet; the board just says it doesn't hold.
func commit_theory(id: String, selected: Array[String]) -> TheoryCheck.Result:
	var t: Theory = CaseCatalog.theory(id)
	assert(t != null, "Unknown theory %s" % id)
	var result: TheoryCheck.Result = TheoryCheck.evaluate(t, selected, clues)
	if result != TheoryCheck.Result.HOLDS:
		return result
	if not facts.has(id):
		facts.append(id)
		if t.beat_on_commit != "":
			reach(t.beat_on_commit)
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
	# Off the scene: the coroner takes the body if they haven't already.
	reach("body_removed")


func grant_optic() -> void:
	has_optic = true


func toggle_optic() -> bool:
	if has_optic:
		optic_on = not optic_on
	return optic_on


# ---------- rooms and hostiles ----------

## Moves to a room. Walking takes no time on the case clock.
func travel(to: String, x: float) -> void:
	room = to
	_on_enter(to)
	travel_requested.emit(to, x)


func hostiles_left(in_room: String) -> bool:
	return hostiles.get(in_room, 0) > 0


func hostile_down(in_room: String) -> void:
	hostiles[in_room] = maxi(0, hostiles.get(in_room, 0) - 1)


func spawn_hostiles(in_room: String, count: int) -> void:
	hostiles[in_room] = count


## The detective went down in a fight. They wake at the precinct. Nobody they
## were fighting goes away, but nothing is lost either.
func player_downed() -> void:
	travel(RECOVERY_ROOM, RECOVERY_X)
	notice.emit("You wake up in the precinct infirmary.")


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
	# The night plays out: anything the player set in motion still happens.
	var at: int = minutes
	for id: String in scheduled.duplicate():
		reach(id)
	closed = true
	var s: CaseSummary = CaseSummary.from_case(self)
	s.closed_at = at
	case_closed.emit(s)
	return s
