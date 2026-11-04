@tool
class_name MindTuning
extends Resource
## The numbers behind memory readings, in one place so playtests can tune them
## (data/mind/tuning.tres). Each deep reading's own cost is on its Reading.

## Bleed-through never goes above this.
@export var bleed_max: int = 10
## Felt symptom levels where each tier starts.
@export var mild_at: int = 3
@export var strong_at: int = 6
@export var severe_at: int = 9
## From this felt level, a deep reading also plants a leftover: a false clue
## from someone else's memory that looks like any other clue on the board.
@export var leftover_at: int = 6
## Passengers show up at crime scenes from this felt level. A dose that brings
## the level below it quiets them, and their help with it.
@export var passengers_show_at: int = 1
## Pills the detective has when a fresh run starts. Case 1 has no way to get more.
@export var start_pills: int = 3
## How much felt bleed-through one pill holds back, until the case ends.
@export var dose_strength: int = 3
## Doses before dependence sets in.
@export var free_doses: int = 1
## Felt bleed-through added for every dose past free_doses, whenever undosed.
@export var withdrawal_per_dose: int = 1
