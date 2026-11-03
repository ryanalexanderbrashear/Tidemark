class_name TheoryCheck
extends RefCounted
## Decides whether a set of clues holds a theory up. The check only looks at the
## evidence the player picked, never at whether the theory is true: a wrong
## theory with real, misleading support holds, and the game plays it out.

enum Result { HOLDS, NOT_ENOUGH, DOESNT_FIT, MISSING_SUBJECT }

## How many supporting clues a theory needs.
const MIN_SUPPORT: int = 2


static func evaluate(theory: Theory, selected: Array[String], held: Array[String]) -> Result:
	if theory.requires != "" and not held.has(theory.requires):
		return Result.MISSING_SUBJECT
	var support: int = 0
	for id: String in selected:
		# Anything picked that doesn't back the statement breaks the chain. That
		# stops a player from selecting every clue and committing every theory.
		if not held.has(id) or not theory.supported_by.has(id):
			return Result.DOESNT_FIT
		support += 1
	if support < MIN_SUPPORT:
		return Result.NOT_ENOUGH
	return Result.HOLDS
