class_name TalkOption
extends RefCounted
## One choice in a Talk.

var label: String
## Returns the next Talk, or null to close the box. An empty Callable closes it.
var action: Callable


static func make(text: String, then: Callable) -> TalkOption:
	var o: TalkOption = TalkOption.new()
	o.label = text
	o.action = then
	return o


static func close(text: String) -> TalkOption:
	return make(text, Callable())


func pick() -> Talk:
	if not action.is_valid():
		return null
	return action.call() as Talk
