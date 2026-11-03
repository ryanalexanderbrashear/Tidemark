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

- **Case board.** Pick clues, pick a theory, commit. A theory holds when two or more of the picked clues support it and none of them doesn't belong. A failed chain costs 30 minutes. A wrong theory with misleading support ("Reyka was there when Vale died") holds, and the game plays it out.
- **Ability gate.** The lab turns a heat-damaged sample (or the body, once it reaches the morgue) into a thermal optic. With it on, a market wall shows a heat-sealed door into Cold Storage, and the body gives up a time of death.
- **Knowledge gates.** The fixer only offers the back room once "Vale sold a memory that wasn't hers" is a fact, and you still have to name the buyer. The dead drop is one of several identical tunnel panels, and it only becomes usable once the etching is deduced to be a catalog number.
- **Badge gate and its loss.** Your badge opens the crime scene and the market cams. Kicking in Reyka's door on the wrong theory gets it revoked. From then on the people in the market (the tech, the fixer) are the way around.
- **The clock.** The case starts at 23:00. Travel, failed theories, the lab and getting downed all take time. Reach 06:00 and the killer strikes again. The case goes on, but you recover less at the dead drop.

The case's rules live in `game/case/` and are covered by tests that play the clean path, the wrong-suspect path, a no-badge-from-the-start path and the clock running out (`tests/case/`).

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
  data/      resource schemas: Clue, Theory
  case/      the running case (the Case autoload), the board's check, dialogue (Talk), the Drowned Market's rooms and spots
  world/     the main scene's room builder, the detective, hostiles, bolts, grey-box drawing
  ui/        HUD, dialogue box, case board, intro and summary screens
data/        clues/ and theories/ as .tres, one per id
scenes/      main.tscn
tests/       gdUnit4 tests
editor/ci/   CI-only scripts
```
