@tool
class_name Reading
extends Resource
## A memory the detective can read through his neural port. A surface reading is
## always safe. A deep reading gives more (a second route to a fact, a detail
## about the killer) and costs bleed-through that carries across cases (see
## MindState). No gate ever needs a deep reading.
##
## What can be read (Alex, 2026-11-04): chips and decks hold recordings, which
## anyone can play. People hold the originals: the dead for a few hours after
## death, the living only with consent or under a warrant.

enum Source { RECORDING, DEAD, LIVING }

@export var id: String = ""
## Who or what is being read, shown as the dialogue speaker.
@export var title: String = ""
@export var source: Source = Source.RECORDING
## DEAD only: the last time ("HH:MM") the body can still be read.
@export var readable_until: String = ""
## What a surface reading shows.
@export_multiline var surface_text: String = ""
## A clue the surface reading gives, or "".
@export var surface_clue: String = ""
## What a deep reading shows.
@export_multiline var deep_text: String = ""
## A clue the deep reading gives, or "". Never the only route to a fact a gate needs.
@export var deep_clue: String = ""
## Bleed-through a deep reading adds. The number to tune in playtests.
@export var deep_cost: int = 2
## Someone who stays with the detective after a deep reading of their death, or "".
## Only a DEAD reading leaves a passenger.
@export var passenger: String = ""
## A detail about the killer the deep reading gives, for the end of the case. "" for none.
@export_multiline var insight: String = ""


## Why this subject can't be read right now, or "" when it can.
func blocked_reason(at_minutes: int, consent: bool, warrant: bool) -> String:
	match source:
		Source.DEAD:
			if readable_until != "" and at_minutes > StoryBeat.to_minutes(readable_until):
				return "Too long gone. Whatever was left of her memory has faded past reading." \
					if passenger != "" else "Too long gone. There's nothing left to read."
		Source.LIVING:
			if not consent and not warrant:
				return "You can't read someone without their consent or a warrant."
	return ""
