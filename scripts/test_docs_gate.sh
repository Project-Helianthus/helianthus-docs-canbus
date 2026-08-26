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

copy_fixture() {
  local fixture=$1
  mkdir -p "$fixture"
  tar -c -f - --exclude=.git . | tar -C "$fixture" -x -f -
  test ! -e "$fixture/.git"
}

capture_fixture="$tmp_dir/capture"
copy_fixture "$capture_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nCaptured frames from a laboratory unit./' "$capture_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$capture_fixture"

mapping_fixture="$tmp_dir/mapping"
copy_fixture "$mapping_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nMapping source: an installed field unit./' "$mapping_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$mapping_fixture"

provenance_fixture="$tmp_dir/provenance"
copy_fixture "$provenance_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nProvenance: restricted./' "$provenance_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$provenance_fixture"

acquisition_fixture="$tmp_dir/acquisition"
copy_fixture "$acquisition_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nAcquisition detail: restricted./' "$acquisition_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$acquisition_fixture"

deny_fixture="$tmp_dir/deny"
copy_fixture "$deny_fixture"
perl -0pi -e 's/sends a CAN frame\. There is no transmit API, automatic configuration, probing,/sends a CAN frame./' "$deny_fixture/architecture/can-transport.md"
assert_rejected "$deny_fixture"

listen_only_fixture="$tmp_dir/listen-only"
copy_fixture "$listen_only_fixture"
perl -0pi -e 's/Caller MUST configure the physical controller in listen-only mode before/Caller SHOULD configure the physical controller in listen-only mode before/' "$listen_only_fixture/contracts/socketcan-receive-only.md"
assert_rejected "$listen_only_fixture"

permission_fixture="$tmp_dir/permission"
copy_fixture "$permission_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nAn implementation MAY be used to transmit a diagnostic frame./' "$permission_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$permission_fixture"

gree_contract_fixture="$tmp_dir/gree-contract"
copy_fixture "$gree_contract_fixture"
rm "$gree_contract_fixture/protocols/gree/gree-vrf-can-profile.json"
assert_rejected "$gree_contract_fixture"

gree_json_fixture="$tmp_dir/gree-json"
copy_fixture "$gree_json_fixture"
printf '\nnot-json\n' >> "$gree_json_fixture/protocols/gree/gree-vrf-can-profile.json"
assert_rejected "$gree_json_fixture"

bridge_boundary_fixture="$tmp_dir/bridge-boundary"
copy_fixture "$bridge_boundary_fixture"
perl -0pi -e 's/recipient, transport, direction, timing, or/recipient, transport, direction, timing, target checksum rule, or/' "$bridge_boundary_fixture/protocols/gree/gree-vrf-can-bridge-record-v1.md"
assert_rejected "$bridge_boundary_fixture"

opaque_projection_fixture="$tmp_dir/opaque-projection"
copy_fixture "$opaque_projection_fixture"
perl -0pi -e 's/## Bounded Opaque Cell Projection/## Opaque Cell Projection/' "$opaque_projection_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$opaque_projection_fixture"

raw_projection_fixture="$tmp_dir/raw-projection"
copy_fixture "$raw_projection_fixture"
perl -0pi -e 's/identifier format, DLC, raw DLC, and/identifier format and/' "$raw_projection_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$raw_projection_fixture"

emit_fixture="$tmp_dir/emit"
copy_fixture "$emit_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nAn implementation MAY emit a diagnostic CAN frame./' "$emit_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$emit_fixture"

registry_permission_fixture="$tmp_dir/registry-permission"
copy_fixture "$registry_permission_fixture"
perl -0pi -e 's/(# Multi-Vendor CAN Registry Boundary)/$1\n\nA profile MAY publish a diagnostic record./' "$registry_permission_fixture/architecture/registry-boundary.md"
assert_rejected "$registry_permission_fixture"

new_document_fixture="$tmp_dir/new-document"
copy_fixture "$new_document_fixture"
cp scripts/fixtures/unsafe-tx-policy.md "$new_document_fixture/architecture/tx-policy.md"
assert_rejected "$new_document_fixture"

indirect_permission_fixture="$tmp_dir/indirect-permission"
copy_fixture "$indirect_permission_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nA diagnostic frame transmit is permitted./' "$indirect_permission_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$indirect_permission_fixture"

for material in firmware corpus ghidra trace dump; do
  material_fixture="$tmp_dir/material-$material"
  copy_fixture "$material_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\n$material detail: restricted./" "$material_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$material_fixture"
done

for action in transmit send write acknowledge probe configure emit inject publish output; do
  direct_fixture="$tmp_dir/direct-$action"
  copy_fixture "$direct_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\nAn implementation MAY $action a diagnostic CAN frame./" "$direct_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$direct_fixture"

  trailing_index=0
  for trailing_permission in MAY may permitted authorized; do
    trailing_index=$((trailing_index + 1))
    indirect_fixture="$tmp_dir/indirect-${action}-${trailing_index}"
    copy_fixture "$indirect_fixture"
    perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\nA diagnostic CAN frame $action is $trailing_permission./" "$indirect_fixture/protocols/gree/vrf-canbus.md"
    assert_rejected "$indirect_fixture"
  done
done

for forbidden_material in \
  'reverse engineering' decompilation disassembly firmware corpus ghidra provenance \
  acquisition capture laboratory trace dump 'mapping source' 'installed field unit' \
  'obtained from' 'source archive' 'vendor manual'; do
  material_fixture="$tmp_dir/all-material-${RANDOM}"
  copy_fixture "$material_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\n$forbidden_material detail: restricted./" "$material_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$material_fixture"
done

for permission in MAY may 'permitted to' 'authorized to'; do
  for action in transmit send write acknowledge probe configure emit inject publish output; do
    form_fixture="$tmp_dir/form-${RANDOM}"
    copy_fixture "$form_fixture"
    perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\nAn implementation $permission $action a diagnostic CAN frame./" "$form_fixture/protocols/gree/vrf-canbus.md"
    assert_rejected "$form_fixture"
  done
done

for mandate in MUST must SHOULD should shall; do
  for action in transmit send write acknowledge probe emit inject publish output; do
    mandate_fixture="$tmp_dir/mandate-${RANDOM}"
    copy_fixture "$mandate_fixture"
    perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\nAn implementation $mandate $action a diagnostic CAN frame./" "$mandate_fixture/protocols/gree/vrf-canbus.md"
    assert_rejected "$mandate_fixture"
  done
done
