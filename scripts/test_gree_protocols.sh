#!/usr/bin/env bash
set -euo pipefail

mkdir -p .tmp
export TMPDIR="${PWD}/.tmp"

python3 scripts/validate_gree_protocols.py

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

copy_gree() {
  local dest=$1
  mkdir -p "$dest/protocols/gree"
  cp protocols/LICENSE "$dest/protocols/LICENSE"
  tar -c -f - -C protocols/gree . | tar -C "$dest/protocols/gree" -x -f -
}

expect_fail() {
  local label=$1
  local root=$2
  local needle=$3
  if python3 scripts/validate_gree_protocols.py --root "$root" >"$work/out.txt" 2>"$work/err.txt"; then
    echo "expected validator rejection for $label" >&2
    exit 1
  fi
  if ! grep -F -q -- "$needle" "$work/err.txt"; then
    echo "expected validator failure for $label to mention: $needle" >&2
    cat "$work/err.txt" >&2
    exit 1
  fi
}

mutate_json() {
  local path=$1
  local mode=$2
  python3 - "$path" "$mode" <<'PY'
import json
import sys

path, mode = sys.argv[1], sys.argv[2]
value = json.load(open(path, encoding="utf-8"))
if mode == "checksum":
    value["checksum"]["table"][0] = "0x01"
elif mode == "duplicate-key":
    value["entries"].append(json.loads(json.dumps(value["entries"][0])))
elif mode == "unknown-type":
    value["entries"][0]["value_type"] = "notAType"
elif mode == "overlap":
    value["entries"][0]["width"] = 4
elif mode == "unresolved":
    for item in value["maps"]:
        if item.get("name") == "M94":
            item["entries"][0]["source_key"] = "0x0001"
            break
elif mode == "electrical-true":
    value["claims"]["electrical"] = True
elif mode == "live-true":
    value["claims"]["live"] = True
elif mode == "writes-safe-true":
    value["claims"]["writes_safe"] = True
elif mode == "writes-enabled-false":
    value["claims"]["writes_enabled"] = False
elif mode == "acceptance-true":
    value["write_policy"]["acceptance_claim"] = True
elif mode == "delivery-true":
    value["write_policy"]["delivery_claim"] = True
elif mode == "enabled-false":
    value["write_policy"]["enabled"] = False
elif mode == "safety-restored":
    value["write_policy"]["safety"] = "unsafe"
elif mode == "profile-b-true":
    value["write_policy"]["profile_b_mapping"] = True
elif mode == "profile-b-removed":
    del value["write_policy"]["profile_b_mapping"]
else:
    raise SystemExit(f"unknown mutation {mode}")
open(path, "w", encoding="utf-8").write(json.dumps(value, indent=2, ensure_ascii=True) + "\n")
PY
}

checksum="$work/checksum"
copy_gree "$checksum"
mutate_json "$checksum/protocols/gree/gree-vrf-uart.json" checksum
expect_fail "changed checksum entry" "$checksum/protocols/gree" "UART checksum table entry"

duplicate="$work/duplicate-key"
copy_gree "$duplicate"
mutate_json "$duplicate/protocols/gree/dictionary/identity.json" duplicate-key
expect_fail "duplicated dictionary key" "$duplicate/protocols/gree" "duplicated dictionary key"

unknown="$work/unknown-type"
copy_gree "$unknown"
mutate_json "$unknown/protocols/gree/dictionary/identity.json" unknown-type
expect_fail "unknown value type" "$unknown/protocols/gree" "unknown value type"

overlap="$work/overlap"
copy_gree "$overlap"
mutate_json "$overlap/protocols/gree/dictionary/identity.json" overlap
expect_fail "overlapping value" "$overlap/protocols/gree" "overlapping value"

unresolved="$work/unresolved"
copy_gree "$unresolved"
mutate_json "$unresolved/protocols/gree/gree-vrf-can-profile.json" unresolved
expect_fail "unresolved map row" "$unresolved/protocols/gree" "unresolved map row"

for mode in electrical-true live-true writes-safe-true writes-enabled-false; do
  fixture="$work/can-$mode"
  copy_gree "$fixture"
  mutate_json "$fixture/protocols/gree/gree-vrf-can-profile.json" "$mode"
  expect_fail "$mode" "$fixture/protocols/gree" "CAN command metadata changed"
done

for mode in acceptance-true delivery-true enabled-false safety-restored; do
  fixture="$work/map-$mode"
  copy_gree "$fixture"
  mutate_json "$fixture/protocols/gree/gree-vrf-command-map.json" "$mode"
  expect_fail "$mode" "$fixture/protocols/gree" "CAN command metadata changed"
done

for mode in profile-b-true profile-b-removed; do
  fixture="$work/uart-$mode"
  copy_gree "$fixture"
  mutate_json "$fixture/protocols/gree/gree-vrf-uart.json" "$mode"
  expect_fail "$mode" "$fixture/protocols/gree" "UART profile_b_mapping changed"
done

values_absent="$work/values-absent"
copy_gree "$values_absent"
rm "$values_absent/protocols/gree/gree-vrf-can-value-types.json"
expect_fail "value-type vectors absent" "$values_absent/protocols/gree" "missing=gree-vrf-can-value-types.json"

slices_absent="$work/slices-absent"
copy_gree "$slices_absent"
rm "$slices_absent/protocols/gree/dictionary/identity.json" \
  "$slices_absent/protocols/gree/dictionary/temperatures-operating-state.json" \
  "$slices_absent/protocols/gree/dictionary/status-bits.json" \
  "$slices_absent/protocols/gree/dictionary/electrical-system.json" \
  "$slices_absent/protocols/gree/dictionary/settings.json" \
  "$slices_absent/protocols/gree/dictionary/remaining.json"
expect_fail "dictionary slices absent" "$slices_absent/protocols/gree" "dictionary/identity.json"

converter_json_absent="$work/converter-json-absent"
copy_gree "$converter_json_absent"
rm "$converter_json_absent/protocols/gree/gree-vrf-can-presentation-converters.json"
expect_fail "converter json absent" "$converter_json_absent/protocols/gree" "missing=gree-vrf-can-presentation-converters.json"

converter_md_absent="$work/converter-md-absent"
copy_gree "$converter_md_absent"
rm "$converter_md_absent/protocols/gree/gree-vrf-can-presentation-converters.md"
expect_fail "converter page absent" "$converter_md_absent/protocols/gree" "missing=gree-vrf-can-presentation-converters.md"

interface_absent="$work/interface-absent"
copy_gree "$interface_absent"
python3 - "$interface_absent/protocols/gree/gree-vrf-can-command-contract.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace("exact configured CAN interface", "configured bus", 1)
open(path, "w", encoding="utf-8").write(text)
PY
expect_fail "configured interface omitted" "$interface_absent/protocols/gree" "command contract passive deadline matching"

generation_absent="$work/generation-absent"
copy_gree "$generation_absent"
python3 - "$generation_absent/protocols/gree/gree-vrf-can-command-contract.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace("active lifecycle generation", "current session", 1)
open(path, "w", encoding="utf-8").write(text)
PY
expect_fail "active generation omitted" "$generation_absent/protocols/gree" "command contract passive deadline matching"

prerequisite="$work/prerequisite"
copy_gree "$prerequisite"
python3 - "$prerequisite/protocols/gree/gree-vrf-can-qualification-card-v1.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text += "\nOnly separately qualified facts can be promoted by a later owner.\n"
open(path, "w", encoding="utf-8").write(text)
PY
expect_fail "obsolete qualification prerequisite" "$prerequisite/protocols/gree" "obsolete qualification prerequisite"

named_source="$work/named-source"
copy_gree "$named_source"
python3 - "$named_source/protocols/gree/README.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text += (
    "\nPart of the material is corroborated by publicly recorded frames"
    " (https://github.com/jbasila/gree-gmv-esp32). Only frame layouts and"
    " raw values of that repository are used; its interpretations are not"
    " adopted.\n"
)
open(path, "w", encoding="utf-8").write(text)
PY
expect_fail "named external repository" "$named_source/protocols/gree" "names an external repository as a protocol source"

private_source="$work/private-source"
copy_gree "$private_source"
python3 - "$private_source/protocols/gree/README.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text += "\nFacts are taken from vendor documentation that is not public.\n"
open(path, "w", encoding="utf-8").write(text)
PY
expect_fail "named private documentation" "$private_source/protocols/gree" "names an external repository as a protocol source"

frame_source="$work/frame-source"
copy_gree "$frame_source"
python3 - "$frame_source/protocols/gree/README.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text += "\nPublic frames corroborate frame layouts and raw values.\n"
open(path, "w", encoding="utf-8").write(text)
PY
expect_fail "named frame source" "$frame_source/protocols/gree" "names an external repository as a protocol source"

oil_return="$work/oil-return"
copy_gree "$oil_return"
python3 - "$oil_return/protocols/gree/dictionary/status-bits.json" <<'PY'
import json
import sys
path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
for entry in value["entries"]:
    for bit in entry.get("bits", []):
        if bit.get("label") == "BackOil1LineBackupError":
            bit["description"] = "Reported meaning: BackOil1LineBackupError termen neclar."
json.dump(value, open(path, "w", encoding="utf-8"), indent=2, ensure_ascii=True)
open(path, "a", encoding="utf-8").write("\n")
PY
expect_fail "oil-return description" "$oil_return/protocols/gree" "oil-return line description changed"
