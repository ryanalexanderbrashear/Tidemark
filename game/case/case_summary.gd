class_name CaseSummary
extends RefCounted
## What the player walks away with at the dead drop, and what their choices cost.

const INTEL: Dictionary[String, String] = {
	"list": "A list of names: the killer's next five targets",
	"rig": "The rig used to wipe the chips, still warm",
	"print": "A partial print on the cache lid",
}

var closed_at: int
var intel: Array[String] = []
var costs: Array[String] = []
var facts: Array[String] = []
var wrong_facts: Array[String] = []
var clearance: bool
var second_victim: bool
var reyka: String


static func from_case(c: Node) -> CaseSummary:
	var s: CaseSummary = CaseSummary.new()
	s.closed_at = c.get("minutes")
	s.clearance = c.get("clearance")
	s.second_victim = c.call("has_beat", "second_victim")
	var rig_gone: bool = c.call("has_beat", "rig_cleared")
	s.intel = ["list", "rig", "print"]
	if rig_gone:
		s.intel.erase("rig")
		s.costs.append("03:30. While you dealt with Reyka's lawyers, the killer came back and cleared out the wiping rig.")
	if s.second_victim:
		s.costs.append("04:00. The killer struck again in Uptown while you were on the wrong man.")
	var held: Array[String] = c.get("facts")
	for id: String in held:
		var t: Theory = CaseCatalog.theory(id)
		s.facts.append(t.statement)
		if not t.is_true:
			s.wrong_facts.append(t.statement)
	if held.has("left"):
		s.reyka = "cleared"
	elif held.has("there"):
		s.reyka = "still your suspect, wrongly"
	else:
		s.reyka = "never resolved"
	return s
