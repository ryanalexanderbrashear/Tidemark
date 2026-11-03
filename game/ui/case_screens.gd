class_name CaseScreens
extends RefCounted
## The opening brief and the closing summary.

static func intro(on_start: Callable) -> Control:
	var parts: Array[Control] = UiTheme.modal(620)
	var box: VBoxContainer = parts[1] as VBoxContainer
	box.add_child(UiTheme.label("CASE 01  ·  GREY-BOX PROTOTYPE", 12, UiTheme.DIM))
	box.add_child(UiTheme.label("The Drowned Market", 30, UiTheme.NEON))
	box.add_child(UiTheme.label("Ines Vale, a memory broker, is dead inside her own sealed stall. There's a blank chip in her hand, wiped clean and etched with a string of characters. You have until 06:00 before the killer moves again."))
	box.add_child(UiTheme.label("Find clues, then commit theories on the case board. A theory needs at least two clues that back it up and nothing that doesn't belong. Facts open doors. Wrong theories are allowed, and they cost you."))
	box.add_child(UiTheme.label("Move: A/D or arrows.  Jump: W, Space or Up.  Use: E.  Stun pistol: F.  Thermal optic: T (once you have it).  Case board: Tab or C.", 13, UiTheme.WARN))
	var b: Button = Button.new()
	b.text = "Start at the precinct"
	b.pressed.connect(on_start)
	box.add_child(b)
	b.grab_focus.call_deferred()
	return parts[0]


static func summary(s: CaseSummary, on_again: Callable) -> Control:
	var parts: Array[Control] = UiTheme.modal(640)
	var box: VBoxContainer = parts[1] as VBoxContainer
	box.add_child(UiTheme.label("CASE 01  ·  CLOSED AT " + Case.clock_text(s.closed_at), 12, UiTheme.DIM))
	box.add_child(UiTheme.label("The dead drop", 30, UiTheme.NEON))
	box.add_child(UiTheme.label("The cache lays out the killer's method: a wiping rig, blank chips, and a habit of planning ahead."))
	var found: PackedStringArray = PackedStringArray()
	for id: String in s.intel:
		found.append("•  " + CaseSummary.INTEL[id])
	box.add_child(UiTheme.label("WHAT YOU RECOVERED (%d OF 3)" % s.intel.size(), 12, UiTheme.DIM))
	box.add_child(UiTheme.label("\n".join(found) if not found.is_empty() else "Nothing useful."))
	if not s.costs.is_empty():
		box.add_child(UiTheme.label("WHAT IT COST", 12, UiTheme.DIM))
		box.add_child(UiTheme.label("\n".join(PackedStringArray(s.costs)), 15, UiTheme.WARN))
	if not s.facts.is_empty():
		box.add_child(UiTheme.label("YOUR BOARD", 12, UiTheme.DIM))
		var lines: PackedStringArray = PackedStringArray()
		for f: String in s.facts:
			lines.append("•  " + f + ("  (wrong)" if s.wrong_facts.has(f) else ""))
		box.add_child(UiTheme.label("\n".join(lines), 14))
	box.add_child(UiTheme.label("STATUS", 12, UiTheme.DIM))
	box.add_child(UiTheme.label("Clearance: %s\nSecond victim: %s\nReyka: %s" % [
		"intact" if s.clearance else "revoked (Reyka's lawyers)",
		"yes" if s.second_victim else "no",
		s.reyka]))
	var b: Button = Button.new()
	b.text = "Play again"
	b.pressed.connect(on_again)
	box.add_child(b)
	b.grab_focus.call_deferred()
	return parts[0]
