class_name Talk
extends RefCounted
## One dialogue box: who speaks, what they say, and the choices. Each choice's
## action returns the next Talk, or null to close the box.

var speaker: String
var text: String
var options: Array[TalkOption] = []


static func say(who: String, what: String, choices: Array[TalkOption] = []) -> Talk:
	var t: Talk = Talk.new()
	t.speaker = who
	t.text = what
	t.options = choices
	if t.options.is_empty():
		t.options.append(TalkOption.close("Close"))
	return t


## The first option whose label contains `part`, or null.
func option(part: String) -> TalkOption:
	for o: TalkOption in options:
		if o.label.contains(part):
			return o
	return null


## Picks the option whose label contains `part` and returns what it leads to.
## Used by tests to play through conversations.
func choose(part: String) -> Talk:
	var o: TalkOption = option(part)
	assert(o != null, "No option containing '%s' in %s's talk" % [part, speaker])
	return o.pick()
