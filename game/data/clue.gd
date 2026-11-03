@tool
class_name Clue
extends Resource
## Something the detective found or was told. Clues go on the case board, where
## two or more that hold together make a theory a fact.

@export var id: String = ""
## Short name on the board card.
@export var title: String = ""
## What the detective saw or heard.
@export_multiline var text: String = ""
## Where it came from, shown on the card.
@export var source: String = ""
