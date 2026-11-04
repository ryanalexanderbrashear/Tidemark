class_name MindState
extends Node
## The detective's own mind (autoload `Mind`): bleed-through from deep memory
## readings, the passengers who stay with him, and the suppressant that holds
## symptoms back at the price of dependence.
##
## Unlike Case, this is not reset when a case starts: symptoms carry across
## cases. It is story pressure, never a timer. Nothing here moves the case clock,
## closes a gate or ends the game. What it changes is what the detective sees
## (leftover clues, passengers, the screen) and what the end of the case says.
##
## Design: Story doc, "Reading memories: the side effect" (Alex, 2026-11-04).
## The numbers live in data/mind/tuning.tres.

signal changed
## A line of the detective's inner voice.
signal thought(text: String)

enum Tier { CLEAR, MILD, STRONG, SEVERE }

const TUNING_PATH: String = "res://data/mind/tuning.tres"
const TIER_NAMES: Array[String] = ["clear", "mild", "strong", "severe"]
## Placeholder inner-voice lines for walking into a room with symptoms, per tier.
## Not canon: written to make the tiers felt in a playtest.
const BLEED_LINES: Array[Array] = [
	[],
	["Someone else's hands for a second. Then yours again.", "A smell of salt that isn't here.", "You know this corridor. You've never been in it."],
	["The light flickers into how it looked in someone else's memory.", "A voice behind you says your name. Nobody's there.", "Your fingers keep reaching for a ring you don't wear."],
	["You lose a second. You're facing the other way.", "The room is full of people who left hours ago.", "You can't tell whose memory you're standing in."],
]

var tuning: MindTuning
## Bleed-through built up by deep readings. Never falls on its own.
var bleed: int
var passengers: Array[String] = []
var pills: int
## Every dose ever taken. Past tuning.free_doses, it's dependence.
var doses_taken: int
## Felt bleed-through held back by doses this case.
var held_back: int


func _init() -> void:
	tuning = load(TUNING_PATH) as MindTuning
	reset()


## A fresh run: no symptoms, a full bottle.
func reset() -> void:
	bleed = 0
	passengers.clear()
	pills = tuning.start_pills
	doses_taken = 0
	held_back = 0
	changed.emit()


## A new case starts. Doses wear off; everything else carries over.
func case_started() -> void:
	held_back = 0
	changed.emit()


func withdrawal() -> int:
	return maxi(0, doses_taken - tuning.free_doses) * tuning.withdrawal_per_dose


## The symptom level the detective feels: bleed-through plus withdrawal, minus
## what doses hold back.
func level() -> int:
	return clampi(bleed + withdrawal() - held_back, 0, tuning.bleed_max)


func tier() -> Tier:
	var l: int = level()
	if l >= tuning.severe_at:
		return Tier.SEVERE
	if l >= tuning.strong_at:
		return Tier.STRONG
	if l >= tuning.mild_at:
		return Tier.MILD
	return Tier.CLEAR


func tier_name() -> String:
	return TIER_NAMES[tier()]


func add_bleed(amount: int) -> void:
	bleed = clampi(bleed + amount, 0, tuning.bleed_max)
	changed.emit()


func add_passenger(who: String) -> void:
	if not passengers.has(who):
		passengers.append(who)
		thought.emit("%s doesn't leave when you come up." % who)
		changed.emit()


func has_passenger(who: String) -> bool:
	return passengers.has(who)


## Whether passengers show up right now. A dose can quiet them.
func passengers_present() -> bool:
	return not passengers.is_empty() and level() >= tuning.passengers_show_at


## A deep reading at this level also leaves a false clue behind.
func plants_leftovers() -> bool:
	return level() >= tuning.leftover_at


## Takes a pill. Returns false when the bottle is empty.
func take_dose() -> bool:
	if pills <= 0:
		thought.emit("The bottle's empty.")
		return false
	pills -= 1
	doses_taken += 1
	held_back += tuning.dose_strength
	if doses_taken > tuning.free_doses + 1:
		thought.emit("It takes longer to work every time. You take it anyway.")
	elif doses_taken > tuning.free_doses:
		thought.emit("The edges go quiet. You notice you were waiting for it.")
	else:
		thought.emit("The edges go quiet.")
	changed.emit()
	return true


## An inner-voice line for walking into a room at the current tier, or "".
func room_line(roll: float, pick: int) -> String:
	var lines: Array = BLEED_LINES[tier()]
	if lines.is_empty() or roll > 0.25 + 0.15 * tier():
		return ""
	return lines[posmod(pick, lines.size())]
