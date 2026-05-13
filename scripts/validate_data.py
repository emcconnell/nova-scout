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
PICKUP_TYPES = {
    "fuel_cell",
    "repair_kit",
    "missile_pack",
    "emp_cartridge",
    "energy_cell",
    "crystal",
    "shield_booster",
    "survey_beacon",
}
MINE_TYPES = {"standard", "cluster", "rapid"}
AMBUSH_TYPES = {"scout", "warrior", "destroyer"}
ELITE_VARIANTS = {"interceptor", "artillery", "swarm_commander", "swarm-commander"}
SCAN_PULSE_TYPES = {
    "asteroid",
    "mine",
    "scout",
    "warrior",
    "destroyer",
    "elite_interceptor",
    "elite_artillery",
    "elite_swarm_commander",
}
ARENA_RESULTS = {"alien_territory", "mothership"}

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
            if isinstance(params := enc.get("params", {}), dict):
                validate_encounter_params(path, idx, enc_type, params)
            else:
                errors.append(f"{path.relative_to(ROOT)} encounter[{idx}]: params must be an object when present")
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


def validate_positive_int(path: Path, label: str, value, *, allow_zero: bool = False) -> None:
    if not isinstance(value, int) or isinstance(value, bool) or value < (0 if allow_zero else 1):
        expectation = "non-negative int" if allow_zero else "positive int"
        errors.append(f"{path.relative_to(ROOT)} {label}: must be a {expectation}")


def validate_encounter_params(path: Path, idx: int, enc_type: str, params: dict) -> None:
    prefix = f"encounter[{idx}]"
    if enc_type in {"asteroid_field"}:
        if "count" in params:
            validate_positive_int(path, f"{prefix}.params.count", params.get("count"))
        if "tier" in params and (not isinstance(params.get("tier"), int) or params.get("tier") not in {0, 1, 2}):
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.tier: must be 0, 1, or 2")
        if "mix" in params and not isinstance(params.get("mix"), bool):
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.mix: must be bool")
    elif enc_type in {"mine_field"}:
        if "count" in params:
            validate_positive_int(path, f"{prefix}.params.count", params.get("count"))
        if params.get("mine_type", "standard") not in MINE_TYPES:
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.mine_type: unknown mine type {params.get('mine_type')!r}")
        if "stagger" in params and not isinstance(params.get("stagger"), bool):
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.stagger: must be bool")
    elif enc_type in {"debris_cloud", "scout_wave", "warrior_wave", "destroyer_wave"}:
        if "count" in params:
            validate_positive_int(path, f"{prefix}.params.count", params.get("count"))
    elif enc_type == "mixed_field":
        if "asteroids" in params:
            validate_positive_int(path, f"{prefix}.params.asteroids", params.get("asteroids"))
        if "mines" in params:
            validate_positive_int(path, f"{prefix}.params.mines", params.get("mines"))
        if params.get("mine_type", "standard") not in MINE_TYPES:
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.mine_type: unknown mine type {params.get('mine_type')!r}")
    elif enc_type == "ambush_wave":
        if params.get("type", "scout") not in AMBUSH_TYPES:
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.type: unknown ambush type {params.get('type')!r}")
        for key in ("count_left", "count_right"):
            if key in params:
                validate_positive_int(path, f"{prefix}.params.{key}", params.get(key))
    elif enc_type == "elite_wave":
        variants = params.get("variants", ["interceptor"])
        if not isinstance(variants, list) or not variants:
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.variants: must be a non-empty list")
        else:
            for vidx, variant in enumerate(variants):
                if variant not in ELITE_VARIANTS:
                    errors.append(f"{path.relative_to(ROOT)} {prefix}.params.variants[{vidx}]: unknown elite variant {variant!r}")
        hp_scale = params.get("hp_scale", 1.0)
        if not isinstance(hp_scale, (int, float)) or not 0.5 <= float(hp_scale) <= 3.0:
            errors.append(f"{path.relative_to(ROOT)} {prefix}.params.hp_scale: must be between 0.5 and 3.0")


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
                loot_type = loot.get("type") if isinstance(loot, dict) else None
                if loot_type not in PICKUP_TYPES:
                    errors.append(f"{path.relative_to(ROOT)} wave[{widx}].loot[{lidx}]: unknown loot type {loot_type!r}")
                if not isinstance(count, int) or count <= 0:
                    errors.append(f"{path.relative_to(ROOT)} wave[{widx}].loot[{lidx}]: count must be positive int")


def validate_star_reward_token(token: str, label: str) -> None:
    if re.fullmatch(r"crystal\d*", token):
        return
    if token not in PICKUP_TYPES:
        errors.append(f"{label}: unknown scan reward token {token!r}")


def _extract_star_config_lines(text: str) -> list[tuple[int, str]]:
    lines: list[tuple[int, str]] = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith('{"id"'):
            lines.append((line_no, stripped))
    return lines


def validate_star_config_line(line_no: int, line: str) -> None:
    label = f"{STAR_CLUSTER_SCRIPT.relative_to(ROOT)}:{line_no}"
    result_match = re.search(r'"result"\s*:\s*"([^"]+)"', line)
    star_id_match = re.search(r'"id"\s*:\s*"([^"]+)"', line)
    result = result_match.group(1) if result_match else ""
    star_id = star_id_match.group(1) if star_id_match else "<unknown>"
    if result not in STAR_RESULTS:
        errors.append(f"{label}: unknown star result {result!r}")
    wave_match = re.search(r'"wave_path"\s*:\s*"([^"]*)"', line)
    if wave_match:
        wave_path = wave_match.group(1)
        if wave_path:
            rel = wave_path.removeprefix("res://")
            if not (ROOT / rel).exists():
                errors.append(f"{label}: missing wave_path {wave_path}")
            if result not in ARENA_RESULTS:
                errors.append(f"{label}: star {star_id} result {result!r} must not use arena wave_path {wave_path}")
    reward_match = re.search(r'"reward"\s*:\s*"([^"]+)"', line)
    if reward_match:
        for token in reward_match.group(1).split("+"):
            validate_star_reward_token(token, label)
    duration_match = re.search(r'"scan_duration"\s*:\s*([0-9.]+)', line)
    if duration_match and float(duration_match.group(1)) < 0:
        errors.append(f"{label}: scan_duration must be non-negative")
    for pulse_match in re.finditer(r'\{"at"\s*:\s*([0-9.]+)\s*,\s*"type"\s*:\s*"([^"]+)"\s*,\s*"count"\s*:\s*([0-9]+)\}', line):
        at = float(pulse_match.group(1))
        pulse_type = pulse_match.group(2)
        count = int(pulse_match.group(3))
        if not 0.0 <= at <= 1.0:
            errors.append(f"{label}: scan_pressure pulse at must be between 0 and 1")
        if pulse_type not in SCAN_PULSE_TYPES:
            errors.append(f"{label}: unknown scan_pressure pulse type {pulse_type!r}")
        if count <= 0:
            errors.append(f"{label}: scan_pressure pulse count must be positive")


def validate_star_config_references() -> None:
    if not STAR_CLUSTER_SCRIPT.exists():
        return
    text = STAR_CLUSTER_SCRIPT.read_text()
    for line_no, line in _extract_star_config_lines(text):
        validate_star_config_line(line_no, line)
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
