#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 scripts/validate_data.py

if command -v godot >/dev/null 2>&1; then
  python3 - <<'PY'
import subprocess
import sys

cmd = ["godot", "--headless", "-s", "addons/gut/gut_cmdln.gd", "-gdir=res://tests/unit"]
try:
    proc = subprocess.run(cmd, timeout=60, text=True, capture_output=True)
    out = proc.stdout or ""
    err = proc.stderr or ""
except subprocess.TimeoutExpired as exc:
    out = exc.stdout.decode() if isinstance(exc.stdout, bytes) else (exc.stdout or "")
    err = exc.stderr.decode() if isinstance(exc.stderr, bytes) else (exc.stderr or "")
    # GUT/Godot can hang after printing the summary on this setup. Treat a
    # complete passing summary as success; otherwise fail loudly.
    print(out, end="")
    if err:
        print(err, end="", file=sys.stderr)
    if "---- All tests passed! ----" in out:
        sys.exit(0)
    sys.exit(124)

print(out, end="")
if err:
    print(err, end="", file=sys.stderr)
if proc.returncode != 0:
    sys.exit(proc.returncode)
if "Failing Tests" in out and "Failing Tests      none" not in out and "Failing Tests         0" not in out:
    sys.exit(1)
PY
else
  echo "godot not found; skipped GUT tests"
fi
