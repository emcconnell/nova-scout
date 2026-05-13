#!/usr/bin/env python3
"""Validate Nova Scout JSON/data references.

This script is intentionally conservative: it validates data files that already
exist, catches broken JSON, and checks progression-critical encounter/wave data.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "assets" / "data"
STAR_CLUSTER_SCRIPT = ROOT / "src" / "gameplay" / "star_scan" / "star_cluster_manager.gd"

ENCOUNTER_TYPES = {
    "asteroid_field",
    "mine_field",
    "debris_cloud",
    "derelict_ship",
    "scout_wave",
    "warrior_wave",
    "destroyer_wave",
    "elite_wave",
    "fuel_cache",
    "star_cluster",
    "mixed_field",
    "ambush_wave",
    "leviathan",
}
SECTOR_1_FIRST_DISCOVERY_MAX_DISTANCE = 4800.0  # 120s at EncounterManager.SCROLL_SPEED=40
ENEMY_TYPES = {
    "scout",
    "warrior",
    "destroyer",
    "elite_interceptor",
    "elite_artillery",
    "elite_swarm_commander",
    "mothership",
}
STAR_RESULTS = {"barren", "human_viable", "alien_territory", "anomaly", "mothership"}

errors: list[str] = []


def load_json(path: Path):
    try:
        return json.loads(path.read_text())
    except Exception as exc:  # noqa: BLE001 - produce actionable validator output
        errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
        return None


def validate_all_json_parse() -> None:
    for path in sorted(DATA_DIR.rglob("*.json")):
        load_json(path)


def validate_encounters() -> None:
    enc_dir = DATA_DIR / "encounters"
    for path in sorted(enc_dir.glob("sector_*.json")):
        data = load_json(path)
        if not isinstance(data, dict):
            continue
        encounters = data.get("encounters", [])
        if not isinstance(encounters, list) or not encounters:
            errors.append(f"{path.relative_to(ROOT)}: encounters must be a non-empty list")
            continue
        last_distance = -1
        has_cluster = False
        for idx, enc in enumerate(encounters):
            if not isinstance(enc, dict):
                errors.append(f"{path.relative_to(ROOT)} encounter[{idx}]: must be an object")
                continue
            distance = enc.get("distance")
            if not isinstance(distance, (int, float)):
                errors.append(f"{path.relative_to(ROOT)} encounter[{idx}]: distance must be numeric")
            elif distance <= last_distance:
                errors.append(f"{path.relative_to(ROOT)} encounter[{idx}]: distances must increase")
            else:
                last_distance = distance
            enc_type = enc.get("type")
            if enc_type not in ENCOUNTER_TYPES:
                errors.append(f"{path.relative_to(ROOT)} encounter[{idx}]: unknown type {enc_type!r}")
            if enc_type == "star_cluster":
                has_cluster = True
        if not has_cluster:
            errors.append(f"{path.relative_to(ROOT)}: sector must include a star_cluster encounter")
        if data.get("sector") == 1:
            first_cluster = next(
                (enc for enc in encounters if isinstance(enc, dict) and enc.get("type") == "star_cluster"),
                None,
            )
            if first_cluster is not None:
                first_cluster_distance = first_cluster.get("distance")
                if isinstance(first_cluster_distance, (int, float)) and first_cluster_distance > SECTOR_1_FIRST_DISCOVERY_MAX_DISTANCE:
                    errors.append(
                        f"{path.relative_to(ROOT)}: first star_cluster must appear by "
                        f"{SECTOR_1_FIRST_DISCOVERY_MAX_DISTANCE:.0f} distance units for Steam onboarding"
                    )


def validate_waves() -> None:
    wave_dir = DATA_DIR / "waves"
    for path in sorted(wave_dir.glob("*.json")):
        data = load_json(path)
        if not isinstance(data, dict):
            continue
        waves = data.get("waves", [])
        if not isinstance(waves, list) or not waves:
            errors.append(f"{path.relative_to(ROOT)}: waves must be a non-empty list")
            continue
        for widx, wave in enumerate(waves):
            enemies = wave.get("enemies", []) if isinstance(wave, dict) else []
            if not isinstance(enemies, list) or not enemies:
                errors.append(f"{path.relative_to(ROOT)} wave[{widx}]: enemies must be a non-empty list")
                continue
            for eidx, enemy in enumerate(enemies):
                enemy_type = enemy.get("type") if isinstance(enemy, dict) else None
                count = enemy.get("count") if isinstance(enemy, dict) else None
                if enemy_type not in ENEMY_TYPES:
                    errors.append(f"{path.relative_to(ROOT)} wave[{widx}].enemy[{eidx}]: unknown type {enemy_type!r}")
                if not isinstance(count, int) or count <= 0:
                    errors.append(f"{path.relative_to(ROOT)} wave[{widx}].enemy[{eidx}]: count must be positive int")
            for lidx, loot in enumerate(wave.get("loot", [])):
                count = loot.get("count") if isinstance(loot, dict) else None
                if not isinstance(count, int) or count <= 0:
                    errors.append(f"{path.relative_to(ROOT)} wave[{widx}].loot[{lidx}]: count must be positive int")


def validate_star_config_references() -> None:
    if not STAR_CLUSTER_SCRIPT.exists():
        return
    text = STAR_CLUSTER_SCRIPT.read_text()
    for match in re.finditer(r'"result"\s*:\s*"([^"]+)"', text):
        result = match.group(1)
        if result not in STAR_RESULTS:
            errors.append(f"{STAR_CLUSTER_SCRIPT.relative_to(ROOT)}: unknown star result {result!r}")
    for match in re.finditer(r'"wave_path"\s*:\s*"(res://[^"]+)"', text):
        res_path = match.group(1)
        rel = res_path.removeprefix("res://")
        if not (ROOT / rel).exists():
            errors.append(f"{STAR_CLUSTER_SCRIPT.relative_to(ROOT)}: missing wave_path {res_path}")
    if "mandatory_after" in text and "reveal_mandatory_after" not in text:
        errors.append(f"{STAR_CLUSTER_SCRIPT.relative_to(ROOT)}: mandatory_after present but reveal support missing")


def main() -> int:
    validate_all_json_parse()
    validate_encounters()
    validate_waves()
    validate_star_config_references()
    if errors:
        print("data validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("data validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
