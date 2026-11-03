@tool
class_name StoryBeat
extends Resource
## One event on the case's fixed timeline. Beats happen at a set time, never
## because time passed: the case clock shows the latest beat reached. Some
## beats only happen because of a choice (the raid and what follows it).

@export var id: String = ""
## When it happens, "HH:MM". Hours before noon count as the next morning.
@export var time: String = "23:00"
## What the player is told when it happens. Empty for a quiet beat.
@export_multiline var line: String = ""
## Who tells them: "" for a toast, or a speaker for a dialogue box (a call, dispatch).
@export var speaker: String = ""
## Happens away from the player. It's scheduled by an earlier beat and fires
## once the clock reaches its time.
@export var offscreen: bool = false


## Minutes since midnight at the start of the case's night; past midnight runs on (01:00 is 1500).
func minutes() -> int:
	var parts: PackedStringArray = time.split(":")
	var m: int = int(parts[0]) * 60 + int(parts[1])
	return m + 1440 if m < 12 * 60 else m
