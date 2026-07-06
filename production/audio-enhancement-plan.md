# Audio Enhancement Plan

## Goal
Replace placeholder-short audio with fuller, more exciting, production-safe procedural audio that matches NOVA SCOUT's 1950s analog sci-fi identity: theremin leads, Moog-style basses, noisy explosions, metallic impacts, spatial sweeps, and dramatic boss intensity.

## Acceptance Criteria
- Music tracks are longer than the existing 5-second placeholders and use stereo 44.1kHz WAV output.
- High-frequency gameplay SFX have punchier layered transients, noise tails, pitch sweeps, and analog-style modulation.
- Every `AudioManager.play_sfx()` name referenced by scripts has a matching WAV file so gameplay events do not silently lose sound.
- Existing `AudioManager` lookup paths remain compatible: `assets/audio/music/<track>.wav` and `assets/audio/sfx/<name>.wav`.
- Godot verification runs after replacement and output is inspected for script/resource errors.

## Implementation Notes
- This pass uses deterministic procedural synthesis rather than external copyrighted samples.
- Tracks are designed as loopable beds where possible, with short fade in/out edges to avoid hard clicks.
- SFX are normalized with conservative headroom to reduce clipping when many one-shots overlap.
- Manual listening QA is still required for final mix balance, loudness, and player fatigue.

## Completed/Planned Checklist
- [x] Generate enhanced music beds for menu, sectors, combat, boss phases, discovery, and endings.
- [x] Generate enhanced SFX for weapons, impacts, UI, scanning, pickups, hazards, enemy actions, and boss cues.
- [x] Add missing referenced SFX aliases/files.
- [x] Run automated verification.
- [x] Update audio documentation with implemented asset reality and manual QA notes.

## Verification Log
- 2026-05-13: `python3 scripts/generate_audio_assets.py` generated 13 music WAVs and 53 SFX WAVs.
- 2026-05-13: Script reference scan found 28 referenced SFX names and 0 missing WAV files.
- 2026-05-13: `bash scripts/verify.sh` passed: 74 tests, 207 assertions.
- 2026-05-13: `godot --headless --path . --quit` completed without script/resource load errors in inspected output.
- 2026-05-13: After a playtest reported unchanged audio, root cause was stale Godot imported `.sample` cache files under `.godot/imported/` from before the WAV replacement. `godot --headless --path . --import --quit` reimported all 66 audio WAVs; imported sample mtimes now postdate the source WAVs.
- 2026-05-13: Level music now stays active during travel/scanning and crossfades to the next sector-theme feeling every 120 seconds; menu/combat/boss/win/death cues still override and disable rotation.

## Manual QA Remaining
- Listen through the first 10 minutes of menu, sector travel, scan, combat, and upgrade flow on speakers/headphones.
- Check overlap loudness during dense combat and boss phases; lower individual peaks if multiple explosions or lasers fatigue the mix.
- Re-export/reimport on target platforms before release packaging so Godot refreshes any changed WAV import metadata.
