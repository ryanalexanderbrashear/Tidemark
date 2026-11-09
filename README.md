# Tidemark

A cyberpunk detective game: a 2D metroidvania where a detective chases a serial killer through Halcyon Reach, a flooded city. Investigation comes first. Doors open on what you can do (abilities, a badge) and on what you've worked out (deductions on a case board). You can be wrong, and being wrong costs you, but it never locks you out.

This repo holds a prototype of one case, **the Drowned Market**, built to test that core loop. It plays in the game's look: code-drawn pixel art at 640x360 with the cast on a realistic 8-head body. The market floor and Vale's stall are drawn; the other rooms are pixel stand-ins (flat shapes on the grey-box layout) until they're drawn. The design for the case is in the Claude Doc "Sample case: the Drowned Market" (https://claude.ai/artifact/Uh6hoH5xQ3CpE1qABNQ89h).

## What you need

**Godot 4.7.2, the standard build** (not .NET). The version is pinned in `.godot-version`, and CI reads it from there. gdUnit4 6.2.2 is vendored in `addons/`. Run `git lfs install` once before cloning, because images and fonts are stored in Git LFS.

## Play it

Open `project.godot` in Godot and press F5.

| Key | Does |
| --- | --- |
| A / D or arrow keys | Move |
| Shift | Hold to sprint (his reinforced legs) |
| W, Space or Up | Jump (let go early for a short hop) |
| E or Enter | Talk, check something, use a door |
| X | Examine what you carry: turn the chip over to find its etching |
| F or J | Stun pistol |
| T | Thermal optic, once the lab has calibrated it |
| Q | Take a pill (the suppressant) |
| F2 / F3 | Playtest only: add 2 bleed-through / clear symptoms, pills and passengers |
| Tab or C | Case board |
| 1 to 9 | Pick a dialogue choice |
| Esc | Close a message or the board |

**How it looks and plays.** `World` (the main scene) draws each room in a `PixelView`: the market floor (`MarketScene`: fog, neon, rain, the water, Osk, the fixer and the tech) and Vale's stall (`StallScene`) as drawn, and every other room as a stand-in (`StandInScene`): a sky and far skyline in the room's colours, the floor on the same walkway, the grey-box ledges, doors and objects as lit shapes, panels with their codes, and people as flat silhouettes in their spot's colour. `RoomLayout` places everything in native pixels: drawn rooms where the art puts them, stand-ins at two thirds of the grey-box layout. The detective walks and sprints at the pace his walk and run cycles are drawn for, jumps a little over his own height, and fights with the stun pistol; his jump, fall and aim are placeholder poses until they're drawn. Thugs are red silhouettes and drones small pixel hulls, placeholders too. Dialogue types out in the talk box, Tab opens the cork case board, readings bring their white in from the edges, the thermal optic turns the room to heat, his inner voice types over his head, and the first time he steps onto the market floor a caption opens the scene. The world freezes while anything is up in front of it.

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

`scenes/art_test.tscn` is the Drowned Market style test (milestone M3), now the sandbox for trying mechanics before they go in the game. It settled the Look and Feel doc's questions on resolution (640x360), character size and how the detective's inner voice is shown. It's the game itself (`ArtTest` extends `World`), started on the market floor at the top of the case, with the thermal optic already calibrated (a placeholder, so the optic can be tried without the trip to the lab), plus what's only for trying things out: the fog shown two ways to compare (stepped fog is pixel art like the rest; volumetric fog is a shader drawn at the window's own resolution over a softened background, with glows around the signs and light shafts under the arcology, while the market, people and water stay crisp pixel art in front), the inner voice as thought text, a caption box or silence, a few idle thoughts, and test items to examine. Open the scene and press F6. All of the art is drawn in code from `ArtPalette` (`game/art/`), so it's a test of scale, light and palette, not final art.

| Key | Does |
| --- | --- |
| A / D, Shift, W or Space | Walk, sprint and jump, as in the game |
| E or Enter | Talk to someone, check something, open a door (when a prompt shows) |
| F | Stun pistol |
| Tab | Case board |
| T | Thermal optic on or off |
| X | Examine the items in the detective's pockets (below) |
| V | Inner voice: thought text by the detective, a caption box, or silence |
| G | Fog: stepped pixel fog, volumetric fog behind the pixel art, or none |
| N | Next thought (the opening thoughts play once, then the voice goes quiet) |
| H | Hide the key list |

**The market floor and the stall.** The people and objects are the case's own spots from `DrownedMarket`, on the two drawn rooms: the market floor (Vale's stall door, Osk, the security cams, the fixer, the back room, the maintenance tech at the failing pump, and a boarded stall) and Vale's stall itself (`StallArt`: her ledger, her body, a scorched sample), reached through the badge-taped door with a fade. Reading her body brings the reading's white in from the edges like fog, part way for a surface reading and nearly all the way for a deep one, and a deep reading leaves her with him as a passenger, standing at the fog's edge west of her stall. The thermal optic turns the fog away and the cold to dark blues; people show their heat (her passenger shows none, and the body only a little), and the boarded stall turns out to be a heat-sealed door. The chip is the examine tutorial: her body gives him the chip but not the etching, and the inner voice leads him to take it out and turn it over (X); until he does, the fixer has nothing to look at. The coroner terminal is a second route to the etching. The opening caption is a placeholder, not canon.

**Placeholder sound.** `ArtSound` makes every sound in code (seeded noise and tones, no files): rain, water against the stilts, the hum of Vale's failing lamp (louder as you near it, gone when it stutters off), and one-shots for picking items up, finding a detail, a catch opening, paper, the board and dialogue. While a dialogue box, the board or a close-up is up, the rain and water muffle behind a low-pass filter (`ArtAmbience`), as the Look and Feel doc asks for during investigation.

**The city from a distance.** `scenes/city_concept.tscn` is concept art of Halcyon Reach in the same code-drawn style (`CityArt`): an establishing view across open water at 640x360. Separate arcologies stand on stilts with water and fog between them; their lower decks, on arcades of arched legs, are the Waterline (shacks, neon, string lights), joined by causeways on piers; the tallest tops clear the fog line as the Crown: broad terraces walled all round under glass-lattice domes, their overhangs braced back to the shaft by struts and cables, with a garden and clean lit buildings inside, landing pads off the walls, searchlights and cars between them; giant hologram ads hang in the air between the arcologies (a whale gliding between the arcologies, a panel ad under a drone, a jellyfish over the fog line), see-through and cut by scanlines; a dead arcology sinks in the distance, its dome broken open; Port Patience, the drowned city underneath, shows through its landmarks (the leaning meeting-house steeple between the arcologies, a dead lighthouse far out, a mill chimney and the top of an iron bridge arch) and rooftops along the horizon, and the stilts and mooring posts carry tidemarks. It avoids the Midgar look on purpose (no continuous deck, no numbered sectors, no single central tower), and `tests/art_test/test_city_art.gd` holds it to that. The scene adds live rain and moving cars; F6 to open it. To save it as PNGs (native and scaled up):

```bash
godot --headless --path . -s res://editor/art/city_concept.gd -- --out=/tmp/city --scale=3
```

**Examining items.** X holds up what's in the detective's pockets: the wiped memory chip once he's taken it from Vale's hand and the storage case's ID tag once he's found it (in the game and the art test), and a test tin (art test only). Each item is a small 3D box with pixel-art faces, rendered at the game's resolution and snapped to the art palette with an ink outline, so it reads as pixel art but turns freely. The chip's CS-14-07 etching is on its back: turn it over and hold it there for a moment to find it. Finding it adds the clue "The calling card" to the case; in the playable slice that's the only way to see the etching before the coroner has her. The pocket tin (a test item, not from the case) has a catch hidden on its right edge: find it, open the tin, and take out the slip inside, which then goes in the pockets like anything else.

| Key (while examining) | Does |
| --- | --- |
| Drag, or W / A / S / D | Turn the item (a flick keeps it spinning) |
| Q / E | Roll it |
| Wheel, or + / - | Bring it closer or further |
| Space | Open the item (once its catch is found), or take out what's inside |
| Tab | Next item |
| R | Straighten it |
| P | Palette snap on or off, to compare |
| X / Esc | Put it away |

To save the set of comparison screenshots (needs a display, so not headless):

```bash
godot --path . --resolution 1920x1080 res://scenes/art_test.tscn -- --shots=/tmp/art-test
```

Add `--only=<prefix>` to save only some of them, for example `--only=examine` for the examine shots, `--only=scene` for the market floor and stall (caption, stall, readings, thermal, the passenger, talking, the board) or `--only=rooms` for the stand-in rooms.

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
  world/     the main scene (World), where everything stands (RoomLayout), the detective, hostiles, bolts
  art/       code-drawn pixel art: palette, drawing kit, the 8-head cast, the market and stall, fog, rain, shaders
  view/      the pixel view (640x360 viewports, thermal, reading, fade), drawn and stand-in rooms, cast sprites
  ui/        talk box, case board, inner voice, on-screen notices, intro and summary screens, bleed-through overlay
  examine/   holding evidence up close and turning it over
  sound/     placeholder sound made in code, and the ambience that muffles while you're busy
  art_test/  the style test and sandbox (ArtTest, on the game's World), city concept art
data/        clues/, theories/, beats/ and readings/ as .tres, one per id; mind/tuning.tres
scenes/      main.tscn, art_test.tscn
tests/       gdUnit4 tests
editor/ci/   CI-only scripts
```
