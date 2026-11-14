class_name DesignQuestions
extends RefCounted
## Strict parser for design/questions.md, and the check on DESIGN-TBD stand-ins.
##
## Every entry is a "## Q<n>. Title" heading followed by the five FIELDS as
## "- **Field:** text" lines. Problems are collected with their line numbers.
## check_stand_ins() then scans the code for DESIGN-TBD comments: one naming a
## question that doesn't exist is an error, and one left for an Answered
## question is only a reminder, because the docs can answer a question before
## the code catches up.

const DEFAULT_PATH: String = "design/questions.md"

const FIELDS: Array[String] = ["Needed by", "Question", "The docs say", "Suggested default", "Status"]
const STATUSES: Array[String] = ["Open", "Default in use", "Answered"]
const ANSWERED: String = "Answered"

const STAND_IN_ROOTS: Array[String] = ["res://game/", "res://editor/", "res://scenes/", "res://data/"]
const STAND_IN_EXTENSIONS: Array[String] = ["gd", "tscn", "tres"]

## Question number -> {"title": String, "status": String, "line": int}.
var questions: Dictionary[int, Dictionary] = {}
## Each error reads "<path>:<line>: <message>", or "<path>: <message>" when no line applies.
var errors: Array[String] = []
## Stand-ins still in the code for Answered questions, in the same form as errors.
var reminders: Array[String] = []

var _path: String
var _last_number: int = 0
var _heading_pattern: RegEx = RegEx.create_from_string("^## Q(\\d+)\\. (\\S.*)$")
var _field_pattern: RegEx = RegEx.create_from_string("^- \\*\\*([^*]+):\\*\\*(?: (.*))?$")
var _stand_in_pattern: RegEx = RegEx.create_from_string("DESIGN-TBD: Q(\\d+)")


static func parse(text: String, path: String = DEFAULT_PATH) -> DesignQuestions:
	var parsed: DesignQuestions = DesignQuestions.new()
	parsed._path = path
	parsed._parse(text)
	return parsed


## Reads and parses a file. A missing or unreadable file is reported as an error.
static func parse_file(file_path: String, display_path: String = DEFAULT_PATH) -> DesignQuestions:
	var text: String = FileAccess.get_file_as_string(file_path)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		var parsed: DesignQuestions = DesignQuestions.new()
		parsed._path = display_path
		parsed._error(0, "cannot read file (%s)" % error_string(FileAccess.get_open_error()))
		return parsed
	return parse(text, display_path)


func is_valid() -> bool:
	return errors.is_empty()


## Checks every DESIGN-TBD stand-in under roots against the parsed questions.
func check_stand_ins(roots: Array[String] = STAND_IN_ROOTS) -> void:
	for root: String in roots:
		_scan_folder(root)


func _parse(text: String) -> void:
	var lines: PackedStringArray = text.replace("\r\n", "\n").split("\n")
	var in_code_block: bool = false
	var entry: Dictionary = {}  # the entry being read: number, line, fields (name -> text)
	var last_field: String = ""
	for index: int in lines.size():
		var line: String = lines[index]
		if line.begins_with("```"):
			in_code_block = not in_code_block
			continue
		if in_code_block:
			continue
		if line.begins_with("## "):
			_finish(entry)
			entry = {}
			last_field = ""
			if line.begins_with("## Q"):
				entry = _start(line, index + 1)
			continue
		if entry.is_empty():
			continue
		var field_match: RegExMatch = _field_pattern.search(line)
		if field_match != null:
			last_field = _add_field(entry, field_match.get_string(1), field_match.get_string(2), index + 1)
		elif line.begins_with("- **"):
			_error(index + 1, "can't read this field; expected \"- **Field:** text\"")
		elif not line.strip_edges().is_empty() and not last_field.is_empty():
			entry["fields"][last_field] = ("%s %s" % [entry["fields"][last_field], line.strip_edges()]).strip_edges()
	_finish(entry)
	if questions.is_empty() and errors.is_empty():
		_error(0, "no questions found; expected \"## Q1. Title\" headings")


## Returns the new entry, or an empty one when the heading can't be read.
func _start(line: String, line_number: int) -> Dictionary:
	var heading_match: RegExMatch = _heading_pattern.search(line)
	if heading_match == null:
		_error(line_number, "can't read this heading; expected \"## Q<n>. Title\"")
		return {}
	var number: int = heading_match.get_string(1).to_int()
	var expected: int = _last_number + 1
	_last_number = number
	if questions.has(number):
		_error(line_number, "Q%d is already used at line %d" % [number, questions[number]["line"]])
	elif number != expected:
		_error(line_number, "Q%d is out of order; expected Q%d" % [number, expected])
	return {"number": number, "title": heading_match.get_string(2), "line": line_number, "fields": {}}


## Returns the field name to append continuation lines to, or "" if it was rejected.
func _add_field(entry: Dictionary, field: String, value: String, line_number: int) -> String:
	if field not in FIELDS:
		_error(line_number, "Q%d has an unknown field '%s'" % [entry["number"], field])
		return ""
	if entry["fields"].has(field):
		_error(line_number, "Q%d has '%s' twice" % [entry["number"], field])
		return ""
	entry["fields"][field] = value
	return field


func _finish(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	var number: int = entry["number"]
	var fields: Dictionary = entry["fields"]
	for field: String in FIELDS:
		if not fields.has(field):
			_error(entry["line"], "Q%d is missing '%s'" % [number, field])
		elif (fields[field] as String).strip_edges().is_empty():
			_error(entry["line"], "Q%d's '%s' is empty" % [number, field])
	var status: String = _status_of(fields.get("Status", "") as String)
	if fields.has("Status") and status.is_empty():
		_error(entry["line"], "Q%d's status must start with one of: %s" % [number, ", ".join(STATUSES)])
	if not questions.has(number):
		questions[number] = {"title": entry["title"], "status": status, "line": entry["line"]}


## The status keyword the text starts with, or "" if there isn't one.
func _status_of(text: String) -> String:
	for status: String in STATUSES:
		if text == status or text.begins_with(status + " ") or text.begins_with(status + ".") or text.begins_with(status + ","):
			return status
	return ""


func _scan_folder(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for subfolder: String in DirAccess.get_directories_at(folder):
		_scan_folder(folder.path_join(subfolder))
	for file: String in DirAccess.get_files_at(folder):
		if file.get_extension() in STAND_IN_EXTENSIONS:
			_scan_file(folder.path_join(file))


func _scan_file(file_path: String) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(file_path).split("\n")
	for index: int in lines.size():
		for stand_in: RegExMatch in _stand_in_pattern.search_all(lines[index]):
			var number: int = stand_in.get_string(1).to_int()
			var location: String = "%s:%d" % [file_path, index + 1]
			if not questions.has(number):
				errors.append("%s: DESIGN-TBD names Q%d, which isn't in %s" % [location, number, _path])
			elif questions[number]["status"] == ANSWERED:
				reminders.append("%s: Q%d is answered; this stand-in can follow the docs now" % [location, number])


func _error(line_number: int, message: String) -> void:
	if line_number > 0:
		errors.append("%s:%d: %s" % [_path, line_number, message])
	else:
		errors.append("%s: %s" % [_path, message])
