# Design questions

These are things the code needs that the design docs don't answer yet. The code side raises them here instead of inventing canon. Alex takes the Open questions to the design project, the answers go into the Google Docs (linked from `CLAUDE.md`), and then the code follows. Each question is numbered once. Questions are never renumbered or reused, and answered ones stay in the file, so a `Q<n>` always means the same question.

A test (`tests/editor/validation/test_design_questions.gd`) reads this file in CI, so the entry format below is exact.

## Format

```markdown
## Q1. A short title

- **Needed by:** the system that needs the answer (and the milestone, if there is one)
- **Question:** what the docs don't say
- **The docs say:** what they do say, naming the doc and section
- **Suggested default:** what the code would build if it can't wait
- **Status:** Open
```

- **Headings:** each entry starts with a `## Q<n>. Title` heading. Entries run Q1, Q2, Q3 and on, in order with no gaps.
- **Fields:** every entry has the five fields, each once, in any order. A field's text can run onto the following lines.
- **Status** starts with one of these:
  - `Open`: nobody has answered it yet.
  - `Default in use`: the work couldn't wait. The suggested default is built behind a named constant or resource, and each place is marked with a `DESIGN-TBD: Q<n>` comment.
  - `Answered`: the docs now answer it. Name the doc, the section and the date, for example `Answered (Gameplay and Production, Combat, 2026-11-20)`. The code follows by PR and removes its `DESIGN-TBD` comments.
- **What fails the test:**
  - an entry with a missing, repeated or unknown field
  - an unknown status
  - an out-of-order number
  - a `DESIGN-TBD: Q<n>` in `game/`, `editor/`, `scenes/` or `data/` naming a question that isn't here
- **What doesn't fail it:** `DESIGN-TBD` comments still left for an Answered question are listed in the test output as a reminder.

The suggested defaults are the code side's guesses, not canon. Each one is a suggestion until the docs say otherwise. Text in `.tres` files can't hold a comment that survives the editor saving it, so a stand-in for text in `data/` is marked in the script that loads or defines it.

## Q1. What Case 1's memory readings show

- **Needed by:** the prototype's readings (`data/readings/`: Vale, the blank chip, Reyka's deck), surface and deep
- **Question:** What does each reading show, in words, on the surface and deep? What is the detail about the killer the deep chip reading gives for the end of the case?
- **The docs say:** Story, Horror: case 1's fear is "the wipe lived from inside Vale as white spreads over her stall like fog". Surface readings always give every clue a gate needs; deep reads give an extra detail. The routes each reading adds are in the README (a fourth route to "Reyka left" and to "Vale sold a memory that wasn't hers"). No wording.
- **Suggested default:** The playtest's own lines in `data/readings/*.tres` (`surface_text`, `deep_text`), written to test the mechanic.
- **Status:** Default in use, in `game/data/reading.gd`

## Q2. Case 1's reading leftovers

- **Needed by:** bleed-through's false clues (`data/clues/leftover_*.tres`)
- **Question:** What are case 1's leftovers, word for word, and which of them pay off in a later case?
- **The docs say:** Gameplay and Production, Making deductions feel clever, names three: the green door, the four hummed notes, the ring on the thumb. Which pay off, and where, is open.
- **Suggested default:** The three leftover clues in `data/clues/` (`leftover_door`, `leftover_tune`, `leftover_hands`), with the playtest's wording, supporting nothing.
- **Status:** Default in use, in `game/case/case_catalog.gd`

## Q3. What Vale's passenger says and points at

- **Needed by:** the passenger in the market (`DrownedMarket.VALE_POINTS`)
- **Question:** How does Vale, as a passenger, point the way: which clues, and in what words? Does she ever mislead?
- **The docs say:** Story: passengers give testimony, not skills, with their own wants and blind spots; they can point the right way or mislead. Story, Horror: Vale stands at the fog's edge.
- **Suggested default:** She points at the first clue the player hasn't found, in four plain lines, and never misleads.
- **Status:** Default in use, in `game/case/drowned_market.gd`

## Q4. The opening caption on the market floor

- **Needed by:** the caption the first time he steps onto the market floor (`DrownedMarket.MARKET_OPENING`), and the art test's opening thoughts
- **Question:** What does the narration say when case 1 opens?
- **The docs say:** Nothing yet.
- **Suggested default:** One plain line naming the market, Vale's taped stall and the badge reader.
- **Status:** Default in use, in `game/case/drowned_market.gd` and `game/art_test/art_test.gd`

## Q5. Inner-voice lines for bleed-through

- **Needed by:** the lines that play on entering a room at each symptom tier (`MindState.BLEED_LINES`)
- **Question:** What does the detective hear and feel at mild, strong and severe bleed-through?
- **The docs say:** Story: lights flicker into how they looked in a victim's memory, and he hears voices and feels hands that aren't his. No lines.
- **Suggested default:** Three short lines per tier, written to make the tiers felt in a playtest.
- **Status:** Default in use, in `game/mind/mind_state.gd`

## Q6. What loopers say

- **Needed by:** the combat test ground's loopers (`Looper`): the line one says when its rig is pulled, and the flash a grabber's hold pushes into him
- **Question:** What do loopers say, back as themselves, and what does a grabber's flash show?
- **The docs say:** Gameplay and Production, Combat: pulling a rig lets them say one line from their own life; a grabber's hold pushes its loop into him as a flash of someone else's memory. No lines.
- **Suggested default:** A few plain placeholder lines per kind.
- **Status:** Default in use, in `game/world/looper.gd`

## Q7. How thugs, drones and loopers look

- **Needed by:** the hostiles' and loopers' sprites (`Hostile`, `Looper`)
- **Question:** What do case 1's gang, the trap drones and the loopers look like?
- **The docs say:** Sample case: the Drowned Market: a gang renting freezer space in Cold Storage, and trap drones at the dead drop. Gameplay and Production, Combat: loopers come in three kinds (brawler, alarm, grabber). No looks.
- **Suggested default:** Thugs and loopers as flat silhouettes on the cast's body (thugs red), drones as small pixel hulls.
- **Status:** Default in use, in `game/world/hostile.gd` and `game/world/looper.gd`

## Q8. The evidence tablet's names

- **Needed by:** the tablet's boot screen and tabs (`TabletArt`)
- **Question:** What are the tablet's model name and its casebook's name?
- **The docs say:** Gameplay and Production, The evidence tablet: made by Diligence and issued by the Tracer Bureau; "the names on its screen (Casebook, Field Slate Mk IV) are placeholders".
- **Suggested default:** Casebook and Field Slate Mk IV.
- **Status:** Default in use, in `game/art/tablet_art.gd`

## Q9. What the cast looks like

- **Needed by:** the code-drawn cast (`ArtCast`) and the sprites exported from it
- **Question:** What do the detective, Case 1's people (Osk, the fixer, the maintenance tech, Vale) and the later cast (Leith, Cass, Velvet, Pell) look like?
- **The docs say:** Look and Feel sets the style and palette, and Alex picked the realistic 8-head body at 72 px in the art passes. Story calls Leith "a fogged man in white" in the runner's reading. Cass is nonbinary (they/them). No other looks.
- **Suggested default:** The looks in `game/art/art_cast.gd`, each with a comment on what it leans on.
- **Status:** Default in use, in `game/art/art_cast.gd`
