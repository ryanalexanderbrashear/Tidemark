@tool
class_name Reading
extends Resource
## A memory the detective can read through his neural port. A surface reading is
## always safe. A deep reading gives more (a second route to a fact, a detail
## about the killer) and costs bleed-through that carries across cases (see
## MindState). No gate ever needs a deep reading.

@export var id: String = ""
## Who or what is being read, shown as the dialogue speaker.
@export var title: String = ""
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
@export var passenger: String = ""
## A detail about the killer the deep reading gives, for the end of the case. "" for none.
@export_multiline var insight: String = ""
