# Tidemark

A cyberpunk detective game: a 2D metroidvania where a detective chases a serial killer through Halcyon Reach, a flooded city. Investigation comes first. Doors open on what you can do (abilities, a badge) and on what you've worked out (deductions on a case board). You can be wrong, and being wrong costs you, but it never locks you out.

This repo holds a grey-box prototype of one case, **the Drowned Market**, built to test that core loop. The design for the case is in the Claude Doc "Sample case: the Drowned Market" (https://claude.ai/artifact/Uh6hoH5xQ3CpE1qABNQ89h).

## What you need

**Godot 4.7.2, the standard build** (not .NET). The version is pinned in `.godot-version`, and CI reads it from there. gdUnit4 6.2.2 is vendored in `addons/`. Run `git lfs install` once before cloning, because images and fonts are stored in Git LFS.

## Play it

Open `project.godot` in Godot and press F5.

| Key | Does |
| --- | --- |
| A / D or arrow keys | Move |
| W, Space or Up | Jump (let go early for a short hop) |
| E or Enter | Talk, examine, use a door |
| F or J | Stun pistol |
| T | Thermal optic, once the lab has calibrated it |
| Q | Take a pill (the suppressant) |
| F2 / F3 | Playtest only: add 2 bleed-through / clear symptoms, pills and passengers |
| Tab or C | Case board |
| 1 to 9 | Pick a dialogue choice |
| Esc | Close a message or the board |

### The loop being tested

- **Case board.** Pick clues, pick a theory, commit. A theory holds when two or more of the picked clues support it and none of them doesn't belong. A chain that doesn't hold just doesn't commit. A wrong theory with misleading support ("Reyka was there when Vale died") holds, and the game plays it out.
- **Ability gate.** The lab turns a heat-damaged sample (or the body, once it reaches the morgue) into a thermal optic. With it on, a market wall shows a heat-sealed door into Cold Storage, and the body gives up a time of death.
- **Knowledge gates.** The fixer only offers the back room once "Vale sold a memory that wasn't hers" is a fact, and you still have to name the buyer. The dead drop is one of several identical tunnel panels, and it only becomes usable once the etching is deduced to be a catalog number.
- **Badge gate and its loss.** Your badge opens the crime scene and the market cams. Kicking in Reyka's door on the wrong theory gets it revoked. From then on the people in the market (the tech, the fixer) are the way around.
- **The timeline.** The night is a fixed timeline of story beats in `data/beats/`, each at a set time (the coroner takes the body at 00:30, the dead drop is found at 03:00). The clock shows the latest beat reached; walking, fighting and the board never move it. Some beats only happen because of a choice: the raid on Reyka (02:00) leads to the lawyers revoking your clearance (02:40), the killer clearing the wiping rig out of the dead drop (03:30), a second victim (04:00), and finding the dead drop later (04:30).

- **Memory readings.** Chips and decks hold recordings, which never expire. People hold the originals: a body can be read for a few hours after death (Vale until 02:15, so the raid path's fallout at 02:40 closes it), and a living person only with their consent or a warrant (no living subject in case 1 yet). Vale (the body, or the morgue drawer once she's there), the blank chip (coroner terminal) and Reyka's memory deck can be read. A surface reading is always safe. A deep reading gives more: Vale's last memory is a fourth route to "Reyka left", the deck's recall is a fourth route to "Vale sold a memory that wasn't hers", and the chip gives a detail about the killer for the end of the case. No gate needs a deep reading.
- **Bleed-through.** Each deep reading adds its cost (2 or 3) to a 0 to 10 bleed-through level that carries across cases ("Play again, symptoms carried over" on the summary keeps it; "fresh" clears it). The level is shown in the HUD and on screen: mild from 3 (inner-voice lines, flicker), strong from 6, severe from 9 (a figure that isn't there). From 6, a deep reading also plants a **leftover**: a false clue from someone else's memory that looks like any other reading on the board and supports nothing. The summary says which ones weren't yours.
- **Passengers.** A deep reading of Vale's death leaves her with you. She stands in the market and points at a clue you haven't found. She's there whenever your felt level is 1 or more.
- **The suppressant.** You start with 3 pills and case 1 has no way to get more. Each pill holds back 3 points of felt bleed-through until the case ends, which also quiets passengers (and their help). Past the first pill, each dose adds a point of withdrawal that's felt whenever you're not dosed, in every case after.
- **None of it is a clock.** Readings, symptoms and pills never move the case clock, close a gate or end the game. They change what you see and what the summary says.

All the numbers are in `data/mind/tuning.tres`, and each reading's cost is `deep_cost` in `data/readings/`. The readings' text, the leftovers and Vale's passenger lines are placeholders for the playtest, not canon.

The case's rules live in `game/case/` and are covered by tests that play the clean path, the wrong-suspect path, a no-badge-from-the-start path and the timeline (`tests/case/`). The detective's mind lives in `game/mind/` (the `Mind` autoload), and `tests/mind/` covers readings, symptoms and pills, including a run with maxed symptoms, no pills and every leftover on the board.

## The art test

`scenes/art_test.tscn` is the Drowned Market style test (milestone M3): one stretch of the market floor in pixel art, with rain, reflections in the water, Vale's taped-off stall and three people (the detective, Osk, the fixer). It's there to settle the Look and Feel doc's open questions on game resolution, character size and how the detective's inner voice is shown. It also tries the fog, water and neon motif: big neon signs on towers behind the market, swallowed by fog, drawn two ways to compare. Stepped fog is pixel art like the rest (flat bands, dithered seams, stepped halos around each light). Volumetric fog is a shader drawn at the window's own resolution over a softened background, with glows around the signs and light shafts under the arcology, while the market, people and water stay crisp pixel art in front. Open the scene and press F6. All of its art is drawn in code from `ArtPalette` (`game/art_test/`), so it's a test of scale, light and palette, not final art.

The detective is a closer-to-final pass (`ArtDetective`, the "rain-worn tracer" look): about 64 px tall, an open storm coat to the knee, no hat, short hair and stubble, a steel plate round his eye with a cyan iris, the reading port behind his ear and steel braces down his shins. He has a 4-frame idle (hands in pockets, breathing) and an 8-frame walk picked by distance walked, so his planted foot doesn't slide. C cycles to a style draft and to the first sketch. The draft (`ArtDetectiveTall`) is the same detective pushed toward Replaced's look: about 85 px and 8 heads tall, no ink outline, a near-silhouette shaped by a hard cool rim from the neon behind and warm lamp light on his top edges and profile. To save his frames as a sprite sheet (add `--tall` for the draft):

```bash
godot --headless --path . -s res://editor/art/detective_sheet.gd -- --out=/tmp/detective-sheet.png --scale=6
```

| Key | Does |
| --- | --- |
| A / D | Walk |
| R | Switch between 640x360 and 480x270 |
| V | Inner voice: thought text by the detective, a caption box, or silence |
| F | Fog: stepped pixel fog, volumetric fog behind the pixel art, or none |
| C | Detective: closer to final, the tall rim-lit draft, or the first sketch |
| E | Next thought |
| H | Hide the key list |

To save the set of comparison screenshots (needs a display, so not headless):

```bash
godot --path . --resolution 1920x1080 res://scenes/art_test.tscn -- --shots=/tmp/art-test
```

## Run the checks

Run them from the repo root. On a fresh clone, import first, or scripts can't find each other's classes.

```bash
godot --headless --path . --import
godot --headless --path . -s res://editor/ci/check_scripts.gd
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests --ignoreHeadlessMode --continue
```

CI (`.github/workflows/ci.yml`) runs the import, the script check, the tests and a boot of the main scene on every pull request and every push to `main`.

## Layout

```
game/
  data/      resource schemas: Clue, Theory, StoryBeat, Reading, MindTuning
  mind/      the detective's mind across cases (the Mind autoload): bleed-through, passengers, pills
  case/      the running case (the Case autoload), the board's check, dialogue (Talk), the Drowned Market's rooms and spots
  world/     the main scene's room builder, the detective, hostiles, bolts, grey-box drawing
  ui/        HUD, dialogue box, case board, intro and summary screens
  art_test/  the Drowned Market style test: palette, drawing kit, layers, sprites, rain, water
data/        clues/, theories/, beats/ and readings/ as .tres, one per id; mind/tuning.tres
scenes/      main.tscn, art_test.tscn
tests/       gdUnit4 tests
editor/ci/   CI-only scripts
```
