class_name CaseScreens
extends RefCounted
## The opening brief and the closing summary.

static func intro(on_start: Callable) -> Control:
	var parts: Array[Control] = UiTheme.modal(620)
	var box: VBoxContainer = parts[1] as VBoxContainer
	box.add_child(UiTheme.label("CASE 01  ·  GREY-BOX PROTOTYPE", 12, UiTheme.DIM))
	box.add_child(UiTheme.label("The Drowned Market", 30, UiTheme.NEON))
	box.add_child(UiTheme.label("Ines Vale, a memory broker, is dead inside her own sealed stall. There's a blank chip in her hand, wiped clean and etched with a string of characters. The night runs on a timeline of events, and some of them only happen because of what you choose."))
	box.add_child(UiTheme.label("Find clues, then commit theories on the case board. A theory needs at least two clues that back it up and nothing that doesn't belong. Facts open doors. Wrong theories are allowed, and acting on one has consequences."))
	box.add_child(UiTheme.label("Some things can be read through your neural port. A surface reading is safe. A deep reading shows more, and what you see stays with you, from case to case. Pills hold the symptoms back, for a price."))
	box.add_child(UiTheme.label("Move: A/D or arrows.  Jump: W, Space or Up.  Use: E.  Stun pistol: F.  Thermal optic: T (once you have it).  Case board: Tab or C.  Take a pill: Q.", 13, UiTheme.WARN))
	if Mind.bleed > 0 or Mind.doses_taken > 0:
		box.add_child(UiTheme.label("Carried over: bleed-through %d/%d, %d pill(s) left%s." % [Mind.bleed, Mind.tuning.bleed_max, Mind.pills,
			(", passengers: " + ", ".join(PackedStringArray(Mind.passengers))) if not Mind.passengers.is_empty() else ""], 13, Hud.THOUGHT))
	var b: Button = Button.new()
	b.text = "Start at the precinct"
	b.pressed.connect(on_start)
	box.add_child(b)
	b.grab_focus.call_deferred()
	return parts[0]


static func summary(s: CaseSummary, on_again: Callable, on_fresh: Callable) -> Control:
	var parts: Array[Control] = UiTheme.modal(820)
	var box: VBoxContainer = parts[1] as VBoxContainer
	box.add_child(UiTheme.label("CASE 01  ·  CLOSED AT " + Case.clock_text(s.closed_at), 12, UiTheme.DIM))
	box.add_child(UiTheme.label("The dead drop", 26, UiTheme.NEON))
	var found: PackedStringArray = PackedStringArray()
	for id: String in s.intel:
		found.append("•  " + CaseSummary.INTEL[id])
	box.add_child(UiTheme.label("WHAT YOU RECOVERED (%d OF 3)" % s.intel.size(), 12, UiTheme.DIM))
	box.add_child(UiTheme.label("\n".join(found) if not found.is_empty() else "Nothing useful."))
	if not s.costs.is_empty():
		box.add_child(UiTheme.label("WHAT IT COST", 12, UiTheme.DIM))
		box.add_child(UiTheme.label("\n".join(PackedStringArray(s.costs)), 14, UiTheme.WARN))
	var cols: HBoxContainer = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	box.add_child(cols)
	var board: VBoxContainer = VBoxContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_stretch_ratio = 1.6
	cols.add_child(board)
	var lines: PackedStringArray = PackedStringArray()
	for f: String in s.facts:
		lines.append("•  " + f + ("  (wrong)" if s.wrong_facts.has(f) else ""))
	board.add_child(UiTheme.label("YOUR BOARD", 12, UiTheme.DIM))
	board.add_child(UiTheme.label("\n".join(lines) if not lines.is_empty() else "Nothing committed.", 13))
	var status: VBoxContainer = VBoxContainer.new()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(status)
	status.add_child(UiTheme.label("STATUS", 12, UiTheme.DIM))
	status.add_child(UiTheme.label("Clearance: %s\nSecond victim: %s\nReyka: %s" % [
		"intact" if s.clearance else "revoked",
		"yes" if s.second_victim else "no",
		s.reyka], 13))
	var held: String = (", held to %d by pills" % s.felt) if s.felt != s.bleed else ""
	status.add_child(UiTheme.label("Bleed-through: %d/%d%s (%s)\nPassengers: %s\nPills: %d taken, %d left" % [
		s.bleed, s.bleed_max, held, s.tier,
		", ".join(PackedStringArray(s.passengers)) if not s.passengers.is_empty() else "none",
		s.doses_taken, s.pills_left], 13, Hud.THOUGHT))
	var after: PackedStringArray = PackedStringArray()
	for line: String in s.insights:
		after.append("•  " + line)
	if not s.leftovers.is_empty():
		after.append("•  Not yours: %s. %s from someone else's memory." % [
			", ".join(PackedStringArray(s.leftovers)), "That clue came" if s.leftovers.size() == 1 else "Those clues came"])
	if not after.is_empty():
		board.add_child(UiTheme.label("WHAT THE READINGS LEFT YOU", 12, UiTheme.DIM))
		board.add_child(UiTheme.label("\n".join(after), 13, Hud.THOUGHT))
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	var b: Button = Button.new()
	b.text = "Play again, symptoms carried over"
	b.pressed.connect(on_again)
	buttons.add_child(b)
	var fresh: Button = Button.new()
	fresh.text = "Play again, fresh"
	fresh.pressed.connect(on_fresh)
	buttons.add_child(fresh)
	b.grab_focus.call_deferred()
	return parts[0]
