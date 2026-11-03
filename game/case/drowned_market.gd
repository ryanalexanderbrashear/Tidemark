class_name DrownedMarket
extends RefCounted
## Case 01, the Drowned Market: its rooms, and everything in them the detective
## can use. Design: "Sample case: the Drowned Market" (Claude Doc, 2026-11-03).
##
## Gates in this case:
## - Vale's stall and the security cams: badge (clearance), lost after a raid.
## - Cold Storage: the thermal optic shows a heat-sealed door (ability), or the
##   fixer opens the back room once you can name the buyer (knowledge).
## - Reyka's apartment: a warrant (the "left" fact while badged), or kicked in
##   after committing the wrong theory.
## - The dead drop: a tunnel panel that's only usable once the etching is
##   deduced to be a catalog number (knowledge).
## - Flood tunnels beyond the water: rebreather (a later case).
##
## No lockouts: every clue a needed fact rests on has a second route that
## doesn't need the badge (see tests/case/test_case_paths.gd).

const FLOOR_Y: float = 470.0
const DROP_PANEL: String = "CS-14-07"

var rooms: Dictionary[String, RoomDef] = {}
var spots: Array[Spot] = []


func _init() -> void:
	_build_rooms()
	_build_spots()


func spot(id: String) -> Spot:
	for s: Spot in spots:
		if s.id == id:
			return s
	return null


func spots_in(room_id: String) -> Array[Spot]:
	var out: Array[Spot] = []
	for s: Spot in spots:
		if s.room == room_id:
			out.append(s)
	return out


## Captain Ruiz's read on the case, also shown as the HUD's lead line.
func hint() -> String:
	if not Case.has_clue("ledger") and not Case.has_clue("rival"):
		return "Vale's stall is on the Drowned Market floor, east past Broker's Row. Your badge opens the tape. Bring anything the lab can use."
	if Case.has_fact("there") and not Case.is_set("raided"):
		return "You like Reyka for it? Then kicking his door in is on you. No judge signs a warrant on that, and his lawyers will come for your badge."
	if not Case.clearance and not Case.has_fact("catalog"):
		return "You're off the badge readers. Work the people in the market instead: the fixer, the techs. And figure out that etching."
	if Case.has_fact("catalog"):
		return "If the etching is a catalog number, find what it points to. The flood tunnels are full of old panels."
	return "Open the case board (Tab). Two clues that hold together make a fact. Facts open doors, and a bad theory costs you time."


# ---------- rooms ----------

func _build_rooms() -> void:
	var lab: RoomDef = RoomDef.make("lab", "Precinct: forensics lab", 1100, Color("0d1424"), Color("1b2238"), Color("1c2433"))
	lab.exits("", 0, "row", 60)
	_add(lab)

	var row: RoomDef = RoomDef.make("row", "Broker's Row", 1400, Color("1a0f24"), Color("2a1636"), Color("221a2c"))
	row.exits("lab", 1040, "market", 60).ledge(300, 400, 120).ledge(480, 340, 160)
	_add(row)

	var apt: RoomDef = RoomDef.make("apt", "Reyka's apartment", 1000, Color("141a20"), Color("24303a"), Color("2a3440"))
	apt.ledge(620, 390, 140)
	apt.spawns = [Vector2(600, FLOOR_Y), Vector2(820, FLOOR_Y)]
	_add(apt)

	var market: RoomDef = RoomDef.make("market", "The Drowned Market", 2600, Color("06161c"), Color("0c2a30"), Color("10262a"))
	market.water = true
	market.exits("row", 1340, "tunnels", 60).ledge(900, 410, 90).ledge(1010, 340, 260).ledge(1840, 420, 80).ledge(1930, 360, 170)
	_add(market)

	var stall: RoomDef = RoomDef.make("stall", "Vale's stall (crime scene)", 960, Color("1a1010"), Color("2a1818"), Color("2a1c1c"))
	_add(stall)

	var cold: RoomDef = RoomDef.make("cold", "Cold Storage", 1600, Color("0a1824"), Color("123044"), Color("16303e"))
	cold.ledge(560, 400, 380).ledge(1040, 380, 140)
	cold.spawns = [Vector2(700, FLOOR_Y), Vector2(900, FLOOR_Y), Vector2(1000, FLOOR_Y)]
	_add(cold)

	var tunnels: RoomDef = RoomDef.make("tunnels", "Flood tunnels: entrance", 1800, Color("060c12"), Color("0a1a20"), Color("0e1c22"))
	tunnels.water = true
	tunnels.exits("market", 2540, "", 0).ledge(560, 400, 120)
	tunnels.limit = 1440
	tunnels.limit_line = "Deep water. You'd need a rebreather to go further."
	_add(tunnels)

	var drop: RoomDef = RoomDef.make("drop", "The dead drop", 960, Color("140612"), Color("26101e"), Color("1e1220"))
	drop.ledge(240, 380, 140).ledge(580, 380, 140)
	drop.spawns = [Vector2(500, 200), Vector2(700, 160), Vector2(820, 240)]
	drop.spawn_kind = "drone"
	_add(drop)


func _add(r: RoomDef) -> void:
	rooms[r.id] = r


# ---------- spots ----------

func _spot(id: String, room: String, kind: Spot.Kind, label: String, x: float, color: String, action: Callable, size: Vector2 = Vector2(40, 60), y: float = FLOOR_Y) -> Spot:
	var s: Spot = Spot.new()
	s.id = id
	s.room = room
	s.kind = kind
	s.label = label
	s.x = x
	s.y = y
	s.size = size
	s.color = Color(color)
	s.action = action
	spots.append(s)
	return s


func _build_spots() -> void:
	const DOOR: Vector2 = Vector2(56, 90)
	# Precinct
	_spot("sato", "lab", Spot.Kind.PERSON, "Lab tech Sato", 260, "9fd3ff", _sato)
	_spot("coroner", "lab", Spot.Kind.OBJECT, "Coroner terminal", 470, "6fa8ff", _coroner)
	_spot("morgue", "lab", Spot.Kind.OBJECT, "Morgue drawer", 640, "8fb0c8", _morgue).visible_when = Case.body_in_morgue
	_spot("ruiz", "lab", Spot.Kind.PERSON, "Captain Ruiz", 860, "ffd27f", func() -> Talk: return Talk.say("Captain Ruiz", hint()))
	# Broker's Row
	_spot("reyka_door", "row", Spot.Kind.DOOR, "Reyka's door", 820, "c98bff", _reyka_door, DOOR).highlight_when = func() -> bool: return Case.has_fact("there") and not Case.is_set("raided")
	# Reyka's apartment
	_spot("apt_exit", "apt", Spot.Kind.DOOR, "Exit", 40, "c98bff", _apt_exit, DOOR)
	_spot("memory_deck", "apt", Spot.Kind.OBJECT, "Memory deck", 520, "ffd27f", _memory_deck)
	_spot("officer", "apt", Spot.Kind.PERSON, "Security officer", 780, "9fb4c8", func() -> Talk: return Talk.say("Security officer", "Warrant checks out. Mr. Reyka is cooperating through counsel. Touch nothing you don't need.")).visible_when = func() -> bool: return not Case.is_set("raided")
	# Market floor
	_spot("stall_door", "market", Spot.Kind.DOOR, "Vale's stall", 420, "ff5a6e", _stall_door, Vector2(70, 90))
	_spot("osk", "market", Spot.Kind.PERSON, "Osk, rival broker", 700, "ffa07a", _osk)
	_spot("cams", "market", Spot.Kind.OBJECT, "Security cams", 1120, "6fa8ff", _cams, Vector2(40, 60), 340)
	_spot("fixer", "market", Spot.Kind.PERSON, "The fixer", 1500, "e0a3ff", fixer)
	_spot("back_room", "market", Spot.Kind.DOOR, "Back room", 1660, "e0a3ff", _back_room, DOOR)
	_spot("tech", "market", Spot.Kind.PERSON, "Maintenance tech", 1990, "a4e57a", _tech, Vector2(40, 60), 360)
	_spot("heat_door", "market", Spot.Kind.HEAT_DOOR, "Heat-sealed door", 2260, "ff7a2f", _heat_door, Vector2(70, 110)).visible_when = func() -> bool: return Case.has_optic and Case.optic_on
	# Vale's stall
	_spot("stall_exit", "stall", Spot.Kind.DOOR, "Exit", 40, "ff5a6e", _stall_exit, DOOR)
	_spot("ledger", "stall", Spot.Kind.OBJECT, "Ledger", 280, "ffd27f", _ledger)
	_spot("body", "stall", Spot.Kind.BODY, "The body", 500, "ff5a6e", _body, Vector2(80, 24))
	_spot("sample", "stall", Spot.Kind.OBJECT, "Scorched sample", 720, "ff7a2f", _sample, Vector2(30, 30)).visible_when = func() -> bool: return not Case.is_set("has_sample")
	# Cold Storage
	_spot("cold_heat_exit", "cold", Spot.Kind.DOOR, "Heat door", 40, "ff7a2f", func() -> Talk: return _go("market", 2290), DOOR)
	_spot("cold_back_exit", "cold", Spot.Kind.DOOR, "Back room", 1520, "e0a3ff", func() -> Talk: return _go("market", 1690), DOOR)
	_spot("drawers", "cold", Spot.Kind.OBJECT, "Freezer drawers", 720, "9fe0ff", _drawers, Vector2(40, 60), 400)
	_spot("vale_drawer", "cold", Spot.Kind.OBJECT, "Vale's drawer", 1100, "ffd27f", _vale_drawer, Vector2(40, 60), 380)
	_spot("lookout", "cold", Spot.Kind.PERSON, "Gang lookout", 880, "9fb4c8", _lookout).visible_when = func() -> bool: return not Case.hostiles_left("cold") and Case.flag_text("cold_entry") != "forced"
	# Flood tunnels
	_spot("tunnel_exit", "tunnels", Spot.Kind.DOOR, "To the market", 40, "3ee6d0", func() -> Talk: return _go("market", 2500), DOOR)
	for pair: Array in [["CS-02-31", 380.0], ["CS-09-12", 700.0], [DROP_PANEL, 1000.0], ["CS-14-01", 1250.0]]:
		var code: String = pair[0]
		var is_drop: bool = code == DROP_PANEL
		var panel: Spot = _spot("panel_" + code, "tunnels", Spot.Kind.PANEL, "Open panel", pair[1], "4a6070", _drop_panel, Vector2(36, 46), 430)
		panel.code = code
		# Every panel is scenery until the board says which one matters.
		panel.visible_when = func() -> bool: return is_drop and Case.has_fact("catalog")
		panel.highlight_when = panel.visible_when
	_spot("sign", "tunnels", Spot.Kind.OBJECT, "Sign", 1380, "ffb347", func() -> Talk: return Talk.say("Sign", "DEEP WATER. NO ENTRY WITHOUT BREATHING GEAR. You'd need a rebreather to go further (a later case)."), Vector2(40, 70))
	# Dead drop
	_spot("crawlspace", "drop", Spot.Kind.DOOR, "Crawlspace", 40, "ff5a6e", _crawlspace, DOOR)
	_spot("cache", "drop", Spot.Kind.OBJECT, "The killer's cache", 820, "ff5a6e", _cache)


# ---------- helpers ----------

func _go(room: String, x: float, line: String = "") -> Talk:
	Case.travel(room, x)
	if line != "":
		Case.notice.emit(line)
	return null


func _found(id: String, who: String, line: String) -> Talk:
	Case.find_clue(id)
	return Talk.say(who, line)


# ---------- precinct ----------

func _sato() -> Talk:
	if Case.has_optic:
		return Talk.say("Sato", "Optic's calibrated. Press T to see heat. It also reads leftover body heat, if you need a time of death.")
	var has_sample: bool = Case.is_set("has_sample")
	if has_sample or Case.body_in_morgue():
		var line: String = "That's a heat-damaged sample from the stall. Leave it with me and I can calibrate a thermal optic off its burn pattern." if has_sample \
			else "The body came in with heat damage on the clothes. Leave it with me and I can calibrate a thermal optic off it."
		return Talk.say("Sato", line, [
			TalkOption.make("Run it", func() -> Talk:
				Case.grant_optic()
				Case.reach("optic_calibrated")
				return null),
			TalkOption.close("Not now"),
		])
	return Talk.say("Sato", "Bring me something heat-damaged from the scene and I can calibrate a thermal optic for you. It's experimental, but it sees through a lot.")


func _coroner() -> Talk:
	Case.find_clue("chip")
	return Talk.say("Coroner terminal", "Personal effects, Vale, I.: one blank memory chip, wiped. Etching on the casing reads CS-14-07.")


func _morgue() -> Talk:
	if Case.optic_on:
		return _found("thermal", "Morgue drawer", "Through the optic, residual heat still clings to the core. She died near 00:15.")
	return Talk.say("Morgue drawer", "Ines Vale. To the naked eye she's just cold." + (" Try the thermal optic (T)." if Case.has_optic else ""))


# ---------- Broker's Row and the apartment ----------

func _reyka_door() -> Talk:
	if Case.has_fact("left") and Case.clearance:
		Case.set_flag("warrant")
		return _go("apt", 80, "Warrant accepted. Reyka's security steps aside.")
	if Case.is_set("raided"):
		return _go("apt", 80)
	if Case.has_fact("there"):
		return Talk.say("Corporate lock", "You've named Reyka. No judge will sign a warrant this fast. You could kick it in.", [
			TalkOption.make("Kick the door in", kick_in_reyka_door),
			TalkOption.close("Back off"),
		])
	return Talk.say("Corporate lock", "Corporate residence lock. You need a warrant, and a warrant needs a theory that holds up.")


## The wrong-deduction branch: a raid without a warrant.
func kick_in_reyka_door() -> Talk:
	Case.set_flag("raided")
	Case.spawn_hostiles("apt", 2)
	for id: String in Case.RAID_CONSEQUENCES:
		Case.schedule(id)
	_go("apt", 80)
	Case.reach("reyka_raided")
	return null


func _apt_exit() -> Talk:
	if Case.is_set("raided") and not Case.is_set("raid_fallout") and Case.has_clue("memstamp"):
		Case.set_flag("raid_fallout")
		_go("row", 850)
		Case.revoke_clearance()
		Case.reach("clearance_revoked")
		return null
	return _go("row", 850)


func _memory_deck() -> Talk:
	if Case.hostiles_left("apt"):
		Case.notice.emit("Deal with security first.")
		return null
	return _found("memstamp", "Memory deck", "The recall he bought from Vale, still loaded. The playback log puts him in Uptown from 23:00 on, across the city when she died.")


# ---------- market floor ----------

func _stall_door() -> Talk:
	if not Case.clearance:
		return Talk.say("Badge reader", "CLEARANCE REVOKED. The tape stays up.")
	return _go("stall", 80, "Badge accepted.")


func _osk() -> Talk:
	return _found("rival", "Osk", "Vale? She was fencing hot recall, everyone knew. I saw that corp man Reyka at her stall around ten, waving money. You want a killer, start there.")


func _cams() -> Talk:
	if not Case.clearance:
		return Talk.say("Security terminal", "POLICE CREDENTIALS REQUIRED. Your badge bounces.")
	return _found("footage", "Security terminal", "Stall camera, 22:14. Reyka leaves Vale's stall alone. He never comes back.")


func fixer() -> Talk:
	var opts: Array[TalkOption] = []
	if Case.has_clue("chip") and not Case.has_clue("fixerfmt"):
		opts.append(TalkOption.make("Show the chip etching", func() -> Talk:
			Case.find_clue("fixerfmt")
			return Talk.say("The fixer", "CS-14-07? That's a Cold Storage catalog code. The old system, before the corps took over the numbering. Someone's showing off.", [TalkOption.make("Back", fixer)])))
	if not Case.is_set("fixer_vouched"):
		if Case.has_fact("stolen"):
			opts.append(TalkOption.make("I know who Vale was really selling to", _fixer_name_the_buyer))
		else:
			opts.append(TalkOption.make("Ask about the back room", func() -> Talk:
				return Talk.say("The fixer", "The back room goes to Cold Storage. I let you in when you show me you know what Vale was really doing. Not before.", [TalkOption.make("Back", fixer)])))
	opts.append(TalkOption.close("Leave"))
	return Talk.say("The fixer", "A cop in my market. What do you want?", opts)


## Knowledge gate: the dialogue option only exists once "stolen" is a fact, and
## the player still has to pick the right name. A wrong name costs time, never access.
func _fixer_name_the_buyer() -> Talk:
	var opts: Array[TalkOption] = []
	for name: String in ["Osk", "D. Marr", "J. Reyka"]:
		opts.append(TalkOption.make(name, func() -> Talk:
			if name == "J. Reyka":
				Case.set_flag("fixer_vouched")
				Case.reach("fixer_vouched")
				return Talk.say("The fixer", "Hm. You actually did the work. The back room's open, and my people in Cold Storage won't touch you.")
			return Talk.say("The fixer", "Wrong. Come back when you know.")))
	return Talk.say("The fixer", "Go on then. Who was the buyer?", opts)


func _back_room() -> Talk:
	if Case.is_set("fixer_vouched"):
		if not Case.is_set("cold_spawned"):
			Case.set_flag("cold_entry", "fixer")
		return _go("cold", 1500, "The bouncer waves you through. You're vouched for.")
	return Talk.say("Bouncer", "Fixer says who goes in. Fixer hasn't said.")


func _tech() -> Talk:
	var opts: Array[TalkOption] = [
		TalkOption.make("Ask about the tunnels", func() -> Talk:
			return _found("tech", "Maintenance tech", "Down in the tunnels? The panels are numbered the old way, same as the freezers. Nobody's updated a label in thirty years.")),
	]
	# The badge-free route to the footage.
	if not Case.clearance and not Case.has_clue("footage"):
		opts.append(TalkOption.make("Ask about the market cams", func() -> Talk:
			return _found("footage", "Maintenance tech", "Cams? I service them. Here, I pulled the stall feed for you. 22:14, the corp guy walks out alone. You didn't get this from me.")))
	opts.append(TalkOption.close("Leave"))
	return Talk.say("Maintenance tech", "Pumps are failing again. What do you need, detective?", opts)


func _heat_door() -> Talk:
	if not Case.is_set("cold_spawned"):
		Case.set_flag("cold_entry", "badge" if Case.clearance else "forced")
	return _go("cold", 100, "The heat-sealed door gives. Cold Storage." if Case.clearance else "You force the heat-sealed door.")


# ---------- the stall ----------

func _stall_exit() -> Talk:
	_go("market", 455)
	# Once you've seen her, the coroner takes the body.
	if Case.has_beat("body_examined"):
		Case.reach("body_removed")
	return null


func _ledger() -> Talk:
	return _found("ledger", "Vale's ledger", "Last entry: \"recall, 1 unit\" sold to J. Reyka for 40k. You check her stock list. Nothing on it matches.")


func _body() -> Talk:
	Case.find_clue("chip")
	Case.reach("body_examined")
	if Case.optic_on:
		return _found("thermal", "The body", "Through the optic: residual core heat. She died near 00:15. A blank chip in her hand, etched CS-14-07.")
	return Talk.say("The body", "Ines Vale. A blank memory chip in her hand, wiped clean, etched CS-14-07. The body's cooling. You can't tell when she died by looking.")


func _sample() -> Talk:
	Case.set_flag("has_sample")
	Case.notice.emit("You take a heat-damaged sample. The lab might use it.")
	return null


# ---------- Cold Storage ----------

func _drawers() -> Talk:
	if Case.hostiles_left("cold"):
		Case.notice.emit("Not while they're shooting at you.")
		return null
	return _found("drawers", "Freezer drawers", "Rows of drawers, each stamped in an old format: CS-03-11, CS-09-02, CS-14-05...")


func _vale_drawer() -> Talk:
	if Case.hostiles_left("cold"):
		Case.notice.emit("Not while they're shooting at you.")
		return null
	return _found("tag", "Vale's drawer", "Empty. The case inside has an ID tag for \"D. Marr\". This memory never belonged to Vale.")


func _lookout() -> Talk:
	var line: String = "Fixer vouched. Do your thing and go." if Case.flag_text("cold_entry") == "fixer" \
		else "Badge. Fine. We didn't see nothing, and you didn't either."
	return Talk.say("Lookout", line)


# ---------- tunnels and the dead drop ----------

func _drop_panel() -> Talk:
	_go("drop", 100)
	Case.reach("dead_drop_found_late" if Case.is_set("raided") else "dead_drop_found")
	return null


func _crawlspace() -> Talk:
	if Case.hostiles_left("drop"):
		Case.notice.emit("The drones have the crawlspace covered.")
		return null
	return _go("tunnels", 1000)


func _cache() -> Talk:
	if Case.hostiles_left("drop"):
		Case.notice.emit("Trap drones. Clear them first.")
		return null
	Case.close_case()
	return null
