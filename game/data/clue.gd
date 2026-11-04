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
## A leftover from someone else's memory, planted by bleed-through. It looks like
## any other clue and supports nothing, so picking it breaks a chain. The game
## never tells the player which clues are leftovers until the case closes.
@export var leftover: bool = false
