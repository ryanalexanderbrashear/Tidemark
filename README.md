# Undertow (working title)

A cyberpunk detective game: a 2D metroidvania where a detective chases a serial killer through a flooded city. Investigation comes first. Doors open on what you can do (abilities, a badge) and on what you've worked out (deductions on a case board). You can be wrong, and being wrong costs you, but it never locks you out.

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
| Tab or C | Case board |
| 1 to 9 | Pick a dialogue choice |
| Esc | Close a message or the board |

### The loop being tested

- **Case board.** Pick clues, pick a theory, commit. A theory holds when two or more of the picked clues support it and none of them doesn't belong. A chain that doesn't hold just doesn't commit. A wrong theory with misleading support ("Reyka was there when Vale died") holds, and the game plays it out.
- **Ability gate.** The lab turns a heat-damaged sample (or the body, once it reaches the morgue) into a thermal optic. With it on, a market wall shows a heat-sealed door into Cold Storage, and the body gives up a time of death.
- **Knowledge gates.** The fixer only offers the back room once "Vale sold a memory that wasn't hers" is a fact, and you still have to name the buyer. The dead drop is one of several identical tunnel panels, and it only becomes usable once the etching is deduced to be a catalog number.
- **Badge gate and its loss.** Your badge opens the crime scene and the market cams. Kicking in Reyka's door on the wrong theory gets it revoked. From then on the people in the market (the tech, the fixer) are the way around.
- **The timeline.** The night is a fixed timeline of story beats in `data/beats/`, each at a set time (the coroner takes the body at 00:30, the dead drop is found at 03:00). The clock shows the latest beat reached; walking, fighting and the board never move it. Some beats only happen because of a choice: the raid on Reyka (02:00) leads to the lawyers revoking your clearance (02:40), the killer clearing the wiping rig out of the dead drop (03:30), a second victim (04:00), and finding the dead drop later (04:30).

The case's rules live in `game/case/` and are covered by tests that play the clean path, the wrong-suspect path, a no-badge-from-the-start path and the timeline (`tests/case/`).

## The art test

`scenes/art_test.tscn` is the Drowned Market style test (milestone M3): one stretch of the market floor in pixel art, with rain, reflections in the water, Vale's taped-off stall and three people (the detective, Osk, the fixer). It's there to settle the Look and Feel doc's open questions on game resolution, character size and how the detective's inner voice is shown. Open the scene and press F6. All of its art is drawn in code from `ArtPalette` (`game/art_test/`), so it's a test of scale, light and palette, not final art.

| Key | Does |
| --- | --- |
| A / D | Walk |
| R | Switch between 640x360 and 480x270 |
| V | Inner voice: thought text by the detective, a caption box, or silence |
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
  data/      resource schemas: Clue, Theory, StoryBeat
  case/      the running case (the Case autoload), the board's check, dialogue (Talk), the Drowned Market's rooms and spots
  world/     the main scene's room builder, the detective, hostiles, bolts, grey-box drawing
  ui/        HUD, dialogue box, case board, intro and summary screens
  art_test/  the Drowned Market style test: palette, drawing kit, layers, sprites, rain, water
data/        clues/, theories/ and beats/ as .tres, one per id
scenes/      main.tscn, art_test.tscn
tests/       gdUnit4 tests
editor/ci/   CI-only scripts
```
