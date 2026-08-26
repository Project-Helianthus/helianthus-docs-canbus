#!/usr/bin/env bash
set -euo pipefail

python3 scripts/validate_gree_protocols.py

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/candidate"
tar -c -f - --exclude=.git . | tar -C "$tmp_dir/candidate" -x -f -
python3 - "$tmp_dir/candidate/protocols/gree/gree-vrf-uart.json" <<'PY'
import json
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["checksum"]["table"][0] = "0x01"
open(path, "w", encoding="utf-8").write(json.dumps(value, indent=2, ensure_ascii=True) + "\n")
PY

if python3 scripts/validate_gree_protocols.py --root "$tmp_dir/candidate/protocols/gree" >/dev/null 2>&1; then
  echo 'expected Gree semantic validator to reject a changed checksum entry' >&2
  exit 1
fi
