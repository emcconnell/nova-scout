# First Five Minutes Quick Spec

## Goal

Make Nova Scout's opening sell the Steam promise quickly: movement, shooting, pickups, scanning, risk, and reward should all appear before the player gets bored.

## Timing Assumption

`EncounterManager.SCROLL_SPEED` is 40 distance units per second, so 4800 distance units is roughly 120 seconds before boost modifiers. Sector 1 must surface the first star cluster by this distance.

## Authored Opening Beats

| Time | Distance | Beat | Implementation |
|---|---:|---|---|
| 0:00-0:10 | 0-400 | Launch and movement | Low-density asteroid lane; no lethal burst pressure. |
| 0:10-0:25 | 400-1000 | Shoot debris / first threat | Small asteroid field followed by two scouts. |
| 0:25-0:40 | 1000-1600 | Resource feedback | Fuel cache with visible fuel/crystal pickups. |
| 0:40-1:05 | 1600-2600 | Light hazard variety | Mixed asteroid/debris and a small mine tutorial. |
| 1:05-1:35 | 2600-3800 | Danger foreshadow | Moderate asteroid/scout pressure; no leviathan yet. |
| 1:35-2:00 | 3800-4800 | First discovery | Star cluster arrives; first scan completes shortly after. |
| 2:00-3:00 | post-scan | Run shape begins | Star reward/combat outcome points toward sector transition and upgrades. |

## Sector 1 Rules

- First star cluster must appear by distance 4800.
- No leviathan appears before the first scan; save set-piece enemies for later sectors after the core loop is taught.
- Early encounters should teach one concept at a time: dodge, shoot, collect, avoid mines, scan.
- First scan pressure is disabled in Sector 1; pressure pulses start in Sector 2+.
- Fuel/repair economy must be visible before the first scan so players understand pickups.

## Prompt Hooks for the Next Task

Mission-control prompts should trigger from these events:

1. Game start: movement.
2. First asteroid/scout encounter: fire.
3. First pickup spawned or collected: pickups/resources.
4. Star cluster arrival: approach and scan.
5. Scan start: abort reminder.
6. First alien encounter in later sector: weapons free.
7. First upgrade screen: spend crystals.

## Acceptance Criteria

- `scripts/validate_data.py` fails if Sector 1's first star cluster is later than distance 4800.
- Sector 1 encounter data has a star cluster at or before distance 4800.
- The opening contains pickups before the first scan.
- The opening avoids late-game set-piece enemies before the first scan.
- Current gameplay docs and backlog state reflect the implemented opening-pass status.
