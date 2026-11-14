# Tidemark

A cyberpunk detective game in Godot 4: a 2D metroidvania about a detective chasing a serial killer through Halcyon Reach, a flooded city, by one developer (Alex). The game was called Undertow while in development, and the repo and some docs may still use that name (the repo is `ryanalexanderbrashear/Tidemark`; the old URL redirects). Investigation is the main pillar; platforming and combat are lighter, and every fight needs a story reason. This repo currently holds a prototype of one case, the Drowned Market, to test the core loop, in the game's look: the market floor and Vale's stall drawn, the other rooms pixel stand-ins on the grey-box layout. Treat it as a prototype: clear and tested, but expect rooms built in code to move into hand-built scenes later.

## Where the design lives

The design is decided outside this repo, in Google Docs in Alex's Drive design folder (https://drive.google.com/drive/folders/1XqZP3zqez1q-dCCjPXaVq3BRFWzpKlwl). They are the source of truth. This repo implements them.

- Hub (concept, pillars, inspirations, glossary, open questions): https://docs.google.com/document/d/1fhHMwnHNiEoECRRrGlRmHybgm6AEZa4TU_iRA8vRuNU/edit
- Story (the detective, the killer, the arc, endings, horror and tone): https://docs.google.com/document/d/1bdqhoN0a3z3IGF_Idy5XiA6Uq9DOcSem8oQZPnkpoGg/edit
- Setting (Halcyon Reach: geography, districts, timeline, major players, memory and technology): https://docs.google.com/document/d/1DO2g_ro7pDIEEREYgGzVP5o6aOBOVC3cDFLCusQ6L4o/edit
- Gameplay and Production (gates, the evidence tablet and deductions, the timeline and story beats, combat, abilities, the case template, milestones): https://docs.google.com/document/d/1QLoqjGVfiNWOLrwO-qpL4K-IyIvF_B649rdvqBgyi5c/edit
- Look and Feel (resolution, palette, the cast's look, UI, sound): https://docs.google.com/document/d/1EZlh2MPmKAZiuMCwfQCy_YkDW4H8M-PeZ2EEDiRmcDQ/edit
- Sample case: the Drowned Market (the case this prototype builds; its regions, gates, clue web and wrong path): https://docs.google.com/document/d/123v6-DNYvTd8ZJW3lDSQ45lpRpRVPjWUQ3DZLNyzx3E/edit
- Uniqueness check (what Tidemark must not resemble, such as Midgar): https://docs.google.com/document/d/1TfJV-x1lid3CTVYkhpW5d9SOQhTSKmJ3cMooLj-GI80/edit
- Generated art to replace (every code-drawn or code-made asset, to swap for hand-made work): https://docs.google.com/document/d/1U-vI6lNd3VYTtfCAJCmM0C92L3UqlsIHZcQVGZPR5Co/edit

Read them live, through the Google Drive connector. There are no copies in the repo: the Docs keep their own revision history. If you can't open them, ask Alex rather than working from memory or an old export. Older Claude Doc copies of the case (claude.ai artifacts) exist; the Google Doc wins. At each milestone, Alex names a version of each doc (File > Version history > Name current version), so a build can be matched to the design it was built from.

## How work is split

- **Design, story, setting and dialogue** are decided in Alex's Claude project for Tidemark (in the Claude app), and land in the Google Docs first.
- **Code** is built here, in Claude Code.
- **Design changes reach the code as GitHub issues** labelled `design-change`, opened from the design project. Each links the doc section that changed and says what it affects. Work from the issue and the doc, not from the issue alone.
- **Content.** Clue, theory and beat text lives in `data/`; rooms, spots and dialogue in `game/case/drowned_market.gd`. Copy wording from the docs as written. Where the docs have none yet, the text is a placeholder and is marked (below).
- **Design gaps.** When the docs don't answer something the code needs, don't invent canon. Add the question to `design/questions.md` (what's missing, where it's needed, your suggested default) and tell Alex. If the work can't wait, build the suggested default behind a clearly named constant or resource, mark each place `# DESIGN-TBD: Q<n>`, and set the question's status to "Default in use". Alex takes the question back to the design project, the doc is updated, the entry is marked Answered (it stays in the file, and numbers are never reused), and then the code follows and drops its stand-ins. The entry format is in the file's header; a test fails CI on a malformed entry or a stand-in naming a question that doesn't exist. A stand-in for text in a `.tres` is marked in the script that loads or defines it, because a comment in a `.tres` doesn't survive the editor saving it.
- Canon includes names, dates, places, clue wording, what characters know and say, what people look like, and how the killer, loopers and passengers behave. Implementation details (node structure, file layout, shaders, tooling, tuning numbers) are yours to decide.
- **Generated art.** All art is drawn in code and all sound made in code for now. When you add a new generated asset (a room, a sprite, a sound, a logo), add a line to the "Generated art to replace" doc (what it is, where it lives, where it's used), or tell Alex if you can't edit it.

## Rules that come from the design

- **The player can be wrong but is never locked out.** Every fact a gate depends on needs a route that survives the player's mistakes, including losing the badge. Keep `tests/case/test_case_paths.gd` covering each gate when you add one.
- **Gates check evidence, not typed answers.** A knowledge gate only opens from facts on the board (or a clue the player holds), so prior knowledge can't skip ahead.
- **Three clues per true fact,** two needed. A test enforces this.
- **Wrong paths cost something real** (clearance, a life, intel at the end), never progress.
- **Time is a fixed timeline, not a resource.** The case clock is the time of the latest story beat reached (`data/beats/`). Walking, fighting, and failed theories never move it. Choices decide which beats happen (the raid schedules the off-screen beats that follow it), and each beat's time is set in data.
- **Combat comes from the case:** a choice the player made or a clue they missed. Getting downed costs time, never a game over.
- **Readings and symptoms never gate or time anything.** No gate needs a deep reading, and bleed-through, passengers and pills never move the clock, close a gate or end the game.
- **The inner voice is text only,** never voiced.
- **No real-world history in dialogue.** Dates appear only on in-game records and logs, as evidence.
- **Pronouns:** the detective is "he"; Cass Doran is nonbinary, "they".
- **Not Midgar.** The city is separate arcologies on stilts with water between them: no continuous deck, numbered sectors or single central tower (`tests/art_test/test_city_art.gd` holds the concept art to it).

## Tech

| Area | Choice |
| --- | --- |
| Engine | Godot 4.7.2, pinned in `.godot-version` |
| Renderer | Compatibility (keeps a web export possible) |
| Language | GDScript, statically typed (`project.godot` makes an untyped declaration an error) |
| Tests | gdUnit4 6.2.2, vendored in `addons/gdUnit4/`; tests in `tests/` |
| CI | GitHub Actions on Linux: import, script check, tests, boot |
| Data | Clues, theories and story beats as text `.tres` resources, one per id, in `data/` |
| Version control | Git LFS for images, audio, models and fonts (`.gitattributes`). Cloud sessions can't push LFS objects, so new LFS files are pushed from Alex's machine. |

## Working conventions

- `Case` (autoload, `game/case/case_state.gd`) owns all case state. Gameplay and UI change the case only through it, so tests can play the case without a scene.
- `Mind` (autoload, `game/mind/mind_state.gd`) owns the detective's symptoms, passengers and pills. It carries across cases, so `Case.reset()` doesn't clear it; tests call `Mind.reset()`. It never moves the case clock or closes a gate.
- Case content (rooms, spots, dialogue) lives in `game/case/drowned_market.gd`, laid out in grey-box world units. Each spot's action returns a `Talk` or null.
- The main scene (`World`, `game/world/world.gd`) draws at 640x360 in a `PixelView`. `RoomLayout` places the case's rooms in native pixels: drawn rooms (market, stall) where the art puts each spot, every other room a stand-in at 2/3 of its grey-box layout. Each room draws through a `RoomScene` subclass in `game/view/` (`MarketScene`, `StallScene`, `StandInScene`); drawing a new room means a new `RoomScene` plus its entry in `RoomLayout.PLACES`.
- The art test (`ArtTest`) extends `World` and is the sandbox: build a mechanic in the shared code so the game and the sandbox both get it, and keep only try-out toggles in `ArtTest`. The combat test ground (`CombatTest`, `scenes/combat_test.tscn`) is the same kind of sandbox for fights: an arena outside the case on the game's own detective, hostiles and bolts.
- Scripts run with `-s` can't name the `Case` autoload at compile time. Load such code at runtime (see `editor/ci/check_scripts.gd`).
- Schemas in `game/data/` are `@tool` scripts.
- Characters are drawn in code on one realistic 8-head body (`ArtFigure`, after SLYNYRD's anatomy chart; 72 px tall, 9 px a head at full height; builds are written at the chart's 96 px scale and shrunk by `fit()`), cast in `game/art/art_cast.gd`. `editor/art/export_sprites.gd` writes them out as layered Aseprite files, PNG sheets and Godot SpriteFrames for hand editing.
- CI must be green before merging. Branch off `main` for each piece of work, and open a pull request for Alex to review and merge.
