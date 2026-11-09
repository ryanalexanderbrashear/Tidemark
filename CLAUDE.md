# Tidemark

A cyberpunk detective game in Godot 4: a 2D metroidvania about a detective chasing a serial killer through Halcyon Reach, a flooded city, by one developer (Alex). The game was called Undertow while in development, and the repo and some docs may still use that name. Investigation is the main pillar; platforming and combat are lighter, and every fight needs a story reason. This repo currently holds a prototype of one case, the Drowned Market, to test the core loop, in the game's look: the market floor and Vale's stall drawn, the other rooms pixel stand-ins on the grey-box layout. Treat it as a prototype: clear and tested, but expect rooms built in code to move into hand-built scenes later.

## Design

The design lives outside this repo, in Claude Docs and Alex's Google Drive design folder for the project. The case's source of truth is the Claude Doc "Sample case: the Drowned Market" (https://claude.ai/artifact/Uh6hoH5xQ3CpE1qABNQ89h). Don't invent canon (names, clues, what characters know). When the docs don't answer something the code needs, ask Alex and build a clearly named default meanwhile.

## Rules that come from the design

- **The player can be wrong but is never locked out.** Every fact a gate depends on needs a route that survives the player's mistakes, including losing the badge. Keep `tests/case/test_case_paths.gd` covering each gate when you add one.
- **Gates check evidence, not typed answers.** A knowledge gate only opens from facts on the board (or a clue the player holds), so prior knowledge can't skip ahead.
- **Three clues per true fact,** two needed. A test enforces this.
- **Wrong paths cost something real** (clearance, a life, intel at the end), never progress.
- **Time is a fixed timeline, not a resource.** The case clock is the time of the latest story beat reached (`data/beats/`). Walking, fighting, and failed theories never move it. Choices decide which beats happen (the raid schedules the off-screen beats that follow it), and each beat's time is set in data.
- **Combat comes from the case:** a choice the player made or a clue they missed. Getting downed costs time, never a game over.

## Tech

| Area | Choice |
| --- | --- |
| Engine | Godot 4.7.2, pinned in `.godot-version` |
| Renderer | Compatibility (keeps a web export possible) |
| Language | GDScript, statically typed (`project.godot` makes an untyped declaration an error) |
| Tests | gdUnit4 6.2.2, vendored in `addons/gdUnit4/`; tests in `tests/` |
| CI | GitHub Actions on Linux: import, script check, tests, boot |
| Data | Clues, theories and story beats as text `.tres` resources, one per id, in `data/` |
| Version control | Git LFS for images, audio, models and fonts (`.gitattributes`) |

## Working conventions

- `Case` (autoload, `game/case/case_state.gd`) owns all case state. Gameplay and UI change the case only through it, so tests can play the case without a scene.
- `Mind` (autoload, `game/mind/mind_state.gd`) owns the detective's symptoms, passengers and pills. It carries across cases, so `Case.reset()` doesn't clear it; tests call `Mind.reset()`. It never moves the case clock or closes a gate.
- Case content (rooms, spots, dialogue) lives in `game/case/drowned_market.gd`, laid out in grey-box world units. Each spot's action returns a `Talk` or null.
- The main scene (`World`, `game/world/world.gd`) draws at 640x360 in a `PixelView`. `RoomLayout` places the case's rooms in native pixels: drawn rooms (market, stall) where the art puts each spot, every other room a stand-in at 2/3 of its grey-box layout. Each room draws through a `RoomScene` subclass in `game/view/` (`MarketScene`, `StallScene`, `StandInScene`); drawing a new room means a new `RoomScene` plus its entry in `RoomLayout.PLACES`.
- The art test (`ArtTest`) extends `World` and is the sandbox: build a mechanic in the shared code so the game and the sandbox both get it, and keep only try-out toggles in `ArtTest`.
- Scripts run with `-s` can't name the `Case` autoload at compile time. Load such code at runtime (see `editor/ci/check_scripts.gd`).
- Schemas in `game/data/` are `@tool` scripts.
- Characters are drawn in code on one realistic 8-head body (`ArtFigure`, after SLYNYRD's anatomy chart; 72 px tall, 9 px a head at full height; builds are written at the chart's 96 px scale and shrunk by `fit()`), cast in `game/art/art_cast.gd`. `editor/art/export_sprites.gd` writes them out as layered Aseprite files, PNG sheets and Godot SpriteFrames for hand editing.
- CI must be green before merging. Branch off `main` for each piece of work.
