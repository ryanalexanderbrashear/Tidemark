@tool
class_name Theory
extends Resource
## A statement the player can commit on the case board. It holds only when
## every selected clue supports it and at least MIN_SUPPORT of them are picked.
## A wrong theory can still hold: its supporting clues are real, just misleading.

@export var id: String = ""
## Board order, lowest first.
@export var order: int = 0
@export_multiline var statement: String = ""
## Clues that back this statement up.
@export var supported_by: PackedStringArray = PackedStringArray()
## Clues that disprove it. For the design record and the end summary; selecting
## one already fails the check, because it isn't in supported_by.
@export var contradicted_by: PackedStringArray = PackedStringArray()
## A clue the player must hold before the statement makes sense (the chip, for
## a theory about its etching). Empty when there is none.
@export var requires: String = ""
## The theory appears on the board once any of these clues is found.
@export var shown_by: PackedStringArray = PackedStringArray()
## A theory this one replaces when committed (Reyka was there / left before).
@export var excludes: String = ""
## Whether the statement is actually true in the case. The game never tells the
## player; it's for tests and the end-of-case summary.
@export var is_true: bool = true
## A timeline beat that happens when this theory is committed, or "".
@export var beat_on_commit: String = ""
## What the board says when the theory is committed.
@export_multiline var committed_line: String = ""
