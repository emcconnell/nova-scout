#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 scripts/validate_data.py

if command -v godot >/dev/null 2>&1; then
  python3 - <<'PY'
import re
import subprocess
import sys

cmd = ["godot", "--headless", "-s", "addons/gut/gut_cmdln.gd", "-gdir=res://tests/unit"]
try:
    proc = subprocess.run(cmd, timeout=60, text=True, capture_output=True)
    out = proc.stdout or ""
    err = proc.stderr or ""
    returncode = proc.returncode
except subprocess.TimeoutExpired as exc:
    out = exc.stdout.decode() if isinstance(exc.stdout, bytes) else (exc.stdout or "")
    err = exc.stderr.decode() if isinstance(exc.stderr, bytes) else (exc.stderr or "")
    returncode = 0 if "---- All tests passed! ----" in out else 124

print(out, end="")
if err:
    print(err, end="", file=sys.stderr)
combined = out + "\n" + err
if returncode != 0:
    sys.exit(returncode)
if "---- All tests passed! ----" not in out:
    print("verify failed: GUT success summary missing", file=sys.stderr)
    sys.exit(1)
if "Failing Tests" in out and "Failing Tests      none" not in out and "Failing Tests         0" not in out:
    sys.exit(1)
strict_patterns = [
    r"SCRIPT ERROR:",
    r"^ERROR:",
    r"\nERROR:",
]
for pattern in strict_patterns:
    if re.search(pattern, combined):
        print(f"verify failed: unexpected Godot error matched {pattern!r}", file=sys.stderr)
        sys.exit(1)
PY
else
  echo "godot not found; skipped GUT tests"
fi
