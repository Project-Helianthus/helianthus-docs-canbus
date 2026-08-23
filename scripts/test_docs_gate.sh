#!/usr/bin/env bash
set -euo pipefail

bash scripts/check_docs.sh

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

assert_rejected() {
  local fixture=$1
  if (cd "$fixture" && bash scripts/check_docs.sh >/dev/null 2>&1); then
    echo "expected documentation gate rejection for $fixture" >&2
    exit 1
  fi
}

capture_fixture="$tmp_dir/capture"
cp -R . "$capture_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nCaptured frames from a laboratory unit./' "$capture_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$capture_fixture"

mapping_fixture="$tmp_dir/mapping"
cp -R . "$mapping_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nMapping source: an installed field unit./' "$mapping_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$mapping_fixture"

provenance_fixture="$tmp_dir/provenance"
cp -R . "$provenance_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nProvenance: restricted./' "$provenance_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$provenance_fixture"

acquisition_fixture="$tmp_dir/acquisition"
cp -R . "$acquisition_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nAcquisition detail: restricted./' "$acquisition_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$acquisition_fixture"

deny_fixture="$tmp_dir/deny"
cp -R . "$deny_fixture"
perl -0pi -e 's/sends a CAN frame\. There is no transmit API, automatic configuration, probing,/sends a CAN frame./' "$deny_fixture/architecture/can-transport.md"
assert_rejected "$deny_fixture"

listen_only_fixture="$tmp_dir/listen-only"
cp -R . "$listen_only_fixture"
perl -0pi -e 's/Caller MUST configure the physical controller in listen-only mode before/Caller SHOULD configure the physical controller in listen-only mode before/' "$listen_only_fixture/contracts/socketcan-receive-only.md"
assert_rejected "$listen_only_fixture"

permission_fixture="$tmp_dir/permission"
cp -R . "$permission_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nAn implementation MAY be used to transmit a diagnostic frame./' "$permission_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$permission_fixture"

emit_fixture="$tmp_dir/emit"
cp -R . "$emit_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nAn implementation MAY emit a diagnostic CAN frame./' "$emit_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$emit_fixture"

registry_permission_fixture="$tmp_dir/registry-permission"
cp -R . "$registry_permission_fixture"
perl -0pi -e 's/(# Multi-Vendor CAN Registry Boundary)/$1\n\nA profile MAY publish a diagnostic record./' "$registry_permission_fixture/architecture/registry-boundary.md"
assert_rejected "$registry_permission_fixture"

new_document_fixture="$tmp_dir/new-document"
cp -R . "$new_document_fixture"
cp scripts/fixtures/unsafe-tx-policy.md "$new_document_fixture/architecture/tx-policy.md"
assert_rejected "$new_document_fixture"

indirect_permission_fixture="$tmp_dir/indirect-permission"
cp -R . "$indirect_permission_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nA diagnostic frame transmit is permitted./' "$indirect_permission_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$indirect_permission_fixture"

for material in firmware corpus ghidra trace dump; do
  material_fixture="$tmp_dir/material-$material"
  cp -R . "$material_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\n$material detail: restricted./" "$material_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$material_fixture"
done

for action in transmit send write acknowledge probe configure emit inject publish output; do
  direct_fixture="$tmp_dir/direct-$action"
  cp -R . "$direct_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\nAn implementation MAY $action a diagnostic CAN frame./" "$direct_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$direct_fixture"

  indirect_fixture="$tmp_dir/indirect-$action"
  cp -R . "$indirect_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\nA diagnostic CAN frame $action is permitted./" "$indirect_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$indirect_fixture"
done

for forbidden_material in \
  'reverse engineering' decompilation disassembly firmware corpus ghidra provenance \
  acquisition capture laboratory trace dump 'mapping source' 'installed field unit' \
  'obtained from' 'source archive' 'vendor manual'; do
  material_fixture="$tmp_dir/all-material-${RANDOM}"
  cp -R . "$material_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\n$forbidden_material detail: restricted./" "$material_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$material_fixture"
done

for permission in MAY may 'permitted to' 'authorized to'; do
  for action in transmit send write acknowledge probe configure emit inject publish output; do
    form_fixture="$tmp_dir/form-${RANDOM}"
    cp -R . "$form_fixture"
    perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\nAn implementation $permission $action a diagnostic CAN frame./" "$form_fixture/protocols/gree/vrf-canbus.md"
    assert_rejected "$form_fixture"
  done
done
