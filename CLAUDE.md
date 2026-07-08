# NOVA SCOUT — Game Studio Configuration

Retro arcade space exploration shooter. Godot 4 / GDScript.
One pilot. Five sectors. Three habitable worlds. One hour to save humanity.

## Technology Stack

- **Engine**: Godot 4.3+
- **Language**: GDScript
- **Version Control**: Git / trunk-based
- **Build System**: Godot export system
- **Asset Pipeline**: `tools/texture_gen/` Python bake (albedo + normal PNGs) → Godot import, LMMS (audio) → OGG/WAV

## Project Structure

```
src/core/          → GameManager, AudioManager, SaveManager (autoloads)
src/gameplay/      → Player, Enemies, Hazards, Systems
src/ui/            → HUD, Menus, Screens
assets/textures/   → Baked body textures (survey/dead/wet albedo + normal)
assets/audio/      → Music (OGG) + SFX (WAV/OGG)
assets/shaders/    → Film pass, darkness veil, fade/creature body shaders
tools/texture_gen/ → Python texture bake pipeline (see art-bible.md §0)
assets/data/       → JSON balance data (enemy stats, encounters, upgrades)
design/gdd/        → All game design documents
production/        → Epics, sprints, milestones
```

## Key Design Documents

- `design/gdd/game-concept.md` — Core concept, setting, tone
- `design/gdd/gameplay-mechanics.md` — All mechanics in detail
- `design/gdd/level-design.md` — All 5 sectors, star clusters, encounters
- `design/gdd/enemies.md` — All enemies, stats, behaviors
- `design/gdd/art-bible.md` — Visual style, palette, sprite specs
- `design/gdd/audio-design.md` — Music tracks, SFX, implementation
- `design/gdd/technical-architecture.md` — Scene tree, systems, data architecture
- `production/epics.md` — Full task list (~187 tasks, 7 sprints)

## Collaboration Protocol

**AUTONOMOUS MODE ACTIVE.**

Proceed without asking permission for:
- Writing or editing any source file, scene, shader, or asset data
- All implementation decisions within the established design
- Creating new files that fit the architecture

Ask the user ONLY when:
- A core design decision is genuinely ambiguous with no good default
- A fundamental architectural change is needed that breaks existing systems
- You need an asset that can only be created by a human (actual audio recording, etc.)

## Coding Standards

- All gameplay balance values in `assets/data/*.json` — never hardcoded
- Signals for all cross-system communication
- Object pooling for high-frequency spawned objects (projectiles, particles)
- Max 300 lines per script — split into components if larger
- Every public function has a one-line docstring comment
- GDScript style: snake_case variables/functions, UPPER_CASE constants, PascalCase classes

## Current Sprint

**Sprint 08** — Pre-Release & Launch Prep
See `production/sprints/sprint-08.md` and the Steam finish docs in `production/`.

## Win Condition (Game)

Player collects 3 Survey Beacons from human-habitable planets across sectors 3, 4, 5.
True ending requires defeating the Mothership boss in Sector 5.
Target playtime: focused 35-45 minute first clear for Steam, prioritizing density and replayability over stretch.
