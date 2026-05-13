#!/usr/bin/env python3
"""Exercise release exports that can be validated on this machine.

This is a release-readiness probe, not part of the normal fast verification gate.
It always exports the Linux target because that is a Steam-facing artifact. It
also exports and launches the native desktop target for the current host when a
preset exists, so a macOS development machine can catch macOS preset/template
configuration issues before release.
"""
from __future__ import annotations

import platform
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LINUX_BUILD = ROOT / "builds" / "linux" / "nova-scout.x86_64"
MACOS_ZIP = ROOT / "builds" / "macos" / "nova-scout.zip"
MACOS_SMOKE_DIR = ROOT / "builds" / "macos" / "smoke"


def _run(cmd: list[str], timeout: int = 300) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True, timeout=timeout)


def _print_output(proc: subprocess.CompletedProcess[str]) -> None:
    print(proc.stdout or "", end="")
    print(proc.stderr or "", end="", file=sys.stderr)


def _combined_output(proc: subprocess.CompletedProcess[str]) -> str:
    return (proc.stdout or "") + (proc.stderr or "")


def _has_runtime_error(output: str) -> bool:
    fatal_markers = ["SCRIPT ERROR:", "Parse Error:", "ERROR: Failed to load script"]
    benign_markers = []
    return any(marker in output for marker in fatal_markers) and not any(marker in output for marker in benign_markers)


def _run_export(godot: str, preset: str, output_path: Path) -> int:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    proc = _run([godot, "--headless", "--export-release", preset, str(output_path)])
    output = _combined_output(proc)
    if _has_runtime_error(output):
        _print_output(proc)
        print(f"export smoke failed: Godot reported script/runtime errors while exporting {preset}")
        return 1
    if proc.returncode != 0:
        _print_output(proc)
        if "No export template found" in output:
            print("\nexport smoke blocked: install Godot 4.6.2 export templates, then rerun scripts/export_smoke.py")
        return proc.returncode
    if not output_path.exists():
        print(f"export smoke failed: expected build not created: {output_path}")
        return 1
    print(f"export smoke passed: {preset} -> {output_path}")
    return 0


def _launch_linux_if_native() -> int:
    if platform.system() != "Linux":
        print("Linux launch smoke skipped: Linux export cannot be executed on this host")
        return 0
    return _launch_executable(LINUX_BUILD)


def _launch_executable(executable: Path) -> int:
    executable.chmod(executable.stat().st_mode | 0o111)
    launch = _run([str(executable), "--headless", "--quit"], timeout=20)
    _print_output(launch)
    output = _combined_output(launch)
    if _has_runtime_error(output):
        print(f"export smoke failed: launched executable reported script/runtime errors: {executable}")
        return 1
    if launch.returncode != 0:
        print(f"export smoke failed: launched executable exited with {launch.returncode}")
        return launch.returncode
    print(f"launch smoke passed: {executable}")
    return 0


def _launch_macos_zip() -> int:
    if platform.system() != "Darwin":
        return 0
    if MACOS_SMOKE_DIR.exists():
        shutil.rmtree(MACOS_SMOKE_DIR)
    MACOS_SMOKE_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(MACOS_ZIP) as archive:
        archive.extractall(MACOS_SMOKE_DIR)
    apps = list(MACOS_SMOKE_DIR.glob("*.app"))
    if not apps:
        print(f"export smoke failed: no .app found in {MACOS_ZIP}")
        return 1
    macos_dir = apps[0] / "Contents" / "MacOS"
    executables = [p for p in macos_dir.iterdir() if p.is_file()]
    if not executables:
        print(f"export smoke failed: no executable found under {macos_dir}")
        return 1
    return _launch_executable(executables[0])


def main() -> int:
    godot = shutil.which("godot")
    if godot is None:
        print("export smoke skipped: godot executable not found")
        return 2

    linux_status = _run_export(godot, "Linux/X11", LINUX_BUILD)
    if linux_status != 0:
        return linux_status
    linux_launch_status = _launch_linux_if_native()
    if linux_launch_status != 0:
        return linux_launch_status

    if platform.system() == "Darwin":
        mac_status = _run_export(godot, "macOS", MACOS_ZIP)
        if mac_status != 0:
            return mac_status
        return _launch_macos_zip()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
