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

growatt_version_matrix_fixture="$tmp_dir/growatt-version-matrix"
copy_fixture "$growatt_version_matrix_fixture"
perl -0pi -e 's/## Source-Confidence and Version-Feature Matrix/## Version Matrix/' "$growatt_version_matrix_fixture/protocols/growatt/growatt-low-voltage-bms-can-version-evidence-v1.md"
assert_rejected "$growatt_version_matrix_fixture"

growatt_version_index_fixture="$tmp_dir/growatt-version-index"
copy_fixture "$growatt_version_index_fixture"
perl -0pi -e 's/Growatt low-voltage BMS CAN version evidence/Growatt CAN evidence/' "$growatt_version_index_fixture/README.md"
assert_rejected "$growatt_version_index_fixture"

growatt_common_projection_fixture="$tmp_dir/growatt-common-projection"
copy_fixture "$growatt_common_projection_fixture"
rm "$growatt_common_projection_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
assert_rejected "$growatt_common_projection_fixture"

growatt_common_scope_fixture="$tmp_dir/growatt-common-scope"
copy_fixture "$growatt_common_scope_fixture"
perl -0pi -e 's/## Revision and Conflict Handling/## Revision Handling/' "$growatt_common_scope_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
assert_rejected "$growatt_common_scope_fixture"

growatt_common_firmware_fixture="$tmp_dir/growatt-common-firmware"
copy_fixture "$growatt_common_firmware_fixture"
perl -0pi -e 's/firmware MUST\s+NOT select a revision/firmware selects a revision/' "$growatt_common_firmware_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
assert_rejected "$growatt_common_firmware_fixture"

growatt_common_conflict_fixture="$tmp_dir/growatt-common-conflict"
copy_fixture "$growatt_common_conflict_fixture"
perl -0pi -e 's/valid shared fields remain available and every divergent field is/valid shared fields are withheld and every divergent field is/' "$growatt_common_conflict_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
assert_rejected "$growatt_common_conflict_fixture"

growatt_common_source_isolation_fixture="$tmp_dir/growatt-common-source-isolation"
copy_fixture "$growatt_common_source_isolation_fixture"
perl -0pi -e 's/no raw frame, field, or/a raw frame, field, or/' "$growatt_common_source_isolation_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
assert_rejected "$growatt_common_source_isolation_fixture"

growatt_common_unknown_raw_fixture="$tmp_dir/growatt-common-unknown-raw"
copy_fixture "$growatt_common_unknown_raw_fixture"
perl -0pi -e 's/identifiers, malformed frames, and fields not listed below remain raw\./identifiers are discarded./' "$growatt_common_unknown_raw_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
assert_rejected "$growatt_common_unknown_raw_fixture"

growatt_common_family_fixture="$tmp_dir/growatt-common-family-separation"
copy_fixture "$growatt_common_family_fixture"
perl -0pi -e 's/Sigineer material is a distinct family/Sigineer material is a compatible family/' "$growatt_common_family_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
assert_rejected "$growatt_common_family_fixture"

for page in 4 5 6; do
  growatt_common_page_fixture="$tmp_dir/growatt-common-v104-page-$page"
  copy_fixture "$growatt_common_page_fixture"
  perl -0pi -e "s/V1\.04-1\.pdf#page=$page/V1.04-1.pdf#page=999/g" "$growatt_common_page_fixture/protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md"
  assert_rejected "$growatt_common_page_fixture"
done

growatt_firmware_page_fixture="$tmp_dir/growatt-v104-firmware-page"
copy_fixture "$growatt_firmware_page_fixture"
perl -0pi -e 's/V1\.04-1\.pdf#page=7/V1.04-1.pdf#page=999/g' "$growatt_firmware_page_fixture/protocols/growatt/growatt-low-voltage-bms-can-version-evidence-v1.md"
assert_rejected "$growatt_firmware_page_fixture"

for page in 4 16 19; do
  growatt_page_fixture="$tmp_dir/growatt-source-page-$page"
  copy_fixture "$growatt_page_fixture"
  perl -0pi -e "s/#page=$page/#page=999/g" "$growatt_page_fixture/protocols/growatt/growatt-low-voltage-bms-can-version-evidence-v1.md"
  assert_rejected "$growatt_page_fixture"
done

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

growatt_pcs_file='protocols/growatt/growatt-low-voltage-bms-can-pcs-protocol-v1.md'
growatt_link_file='protocols/growatt/growatt-low-voltage-bms-can-link-protocol-v1.md'
growatt_index_file='protocols/growatt/README.md'

for missing in "$growatt_pcs_file" "$growatt_link_file" "$growatt_index_file"; do
  missing_fixture="$tmp_dir/growatt-project-code-missing-${RANDOM}"
  copy_fixture "$missing_fixture"
  rm "$missing_fixture/$missing"
  assert_rejected "$missing_fixture"
done

growatt_pcs_heading_fixture="$tmp_dir/growatt-pcs-heading"
copy_fixture "$growatt_pcs_heading_fixture"
perl -0pi -e 's/\n## Diagnostic codes\n/\n## Fault codes\n/' "$growatt_pcs_heading_fixture/$growatt_pcs_file"
assert_rejected "$growatt_pcs_heading_fixture"

growatt_link_heading_fixture="$tmp_dir/growatt-link-heading"
copy_fixture "$growatt_link_heading_fixture"
perl -0pi -e 's/\n## Interoperability rules\n/\n## Rules\n/' "$growatt_link_heading_fixture/$growatt_link_file"
assert_rejected "$growatt_link_heading_fixture"

growatt_pcs_relationship_fixture="$tmp_dir/growatt-pcs-relationship"
copy_fixture "$growatt_pcs_relationship_fixture"
perl -0pi -e 's/A project-code selector MUST NOT select a revision label, and a revision label MUST NOT select a project code\./A project-code selector selects a revision label./' "$growatt_pcs_relationship_fixture/$growatt_pcs_file"
assert_rejected "$growatt_pcs_relationship_fixture"

growatt_link_relationship_fixture="$tmp_dir/growatt-link-relationship"
copy_fixture "$growatt_link_relationship_fixture"
perl -0pi -e 's/A project-code selector MUST NOT select a revision label, and a revision label MUST NOT select a project code\./A revision label selects a project code./' "$growatt_link_relationship_fixture/$growatt_link_file"
assert_rejected "$growatt_link_relationship_fixture"

growatt_receive_only_fixture="$tmp_dir/growatt-project-code-receive-only"
copy_fixture "$growatt_receive_only_fixture"
perl -0pi -e 's/This repository authorizes no transmission, acknowledgement, probing, configuration, update or other live bus action\.//' "$growatt_receive_only_fixture/$growatt_pcs_file"
assert_rejected "$growatt_receive_only_fixture"

growatt_adjacent_fixture="$tmp_dir/growatt-pcs-adjacent-release"
copy_fixture "$growatt_adjacent_fixture"
perl -0pi -e 's/MUST NOT be admitted using a numerically adjacent release/may be admitted using a numerically adjacent release/' "$growatt_adjacent_fixture/$growatt_pcs_file"
assert_rejected "$growatt_adjacent_fixture"

for growatt_doc in "$growatt_pcs_file" "$growatt_link_file" "$growatt_index_file"; do
  growatt_permission_fixture="$tmp_dir/growatt-project-code-permission-${RANDOM}"
  copy_fixture "$growatt_permission_fixture"
  printf '\nAn implementation MAY transmit a diagnostic CAN frame.\n' >> "$growatt_permission_fixture/$growatt_doc"
  assert_rejected "$growatt_permission_fixture"
done

for growatt_material in 'reverse engineering' decompilation ghidra capture trace dump provenance; do
  growatt_material_fixture="$tmp_dir/growatt-project-code-material-${RANDOM}"
  copy_fixture "$growatt_material_fixture"
  printf '\n%s detail: restricted.\n' "$growatt_material" >> "$growatt_material_fixture/$growatt_link_file"
  assert_rejected "$growatt_material_fixture"
done

growatt_anchor_fixture="$tmp_dir/growatt-project-code-anchor"
copy_fixture "$growatt_anchor_fixture"
perl -0pi -e 's/\(#diagnostic-codes\)/(#diagnostic-codez)/' "$growatt_anchor_fixture/$growatt_pcs_file"
assert_rejected "$growatt_anchor_fixture"

growatt_link_target_fixture="$tmp_dir/growatt-project-code-link-target"
copy_fixture "$growatt_link_target_fixture"
perl -0pi -e 's/\]\(growatt-low-voltage-bms-can-link-protocol-v1\.md\)/](growatt-low-voltage-bms-can-link-protocol-v9.md)/g' "$growatt_link_target_fixture/$growatt_pcs_file"
assert_rejected "$growatt_link_target_fixture"

growatt_readme_index_fixture="$tmp_dir/growatt-readme-index"
copy_fixture "$growatt_readme_index_fixture"
perl -0pi -e 's/Growatt protocol index/Growatt index/' "$growatt_readme_index_fixture/README.md"
assert_rejected "$growatt_readme_index_fixture"

growatt_dtc_fixture="$tmp_dir/growatt-dtc-drift"
copy_fixture "$growatt_dtc_fixture"
perl -0pi -e 's/\| 62 \| Maximum cell voltage high \|/| 62 | Maximum cell voltage low |/' "$growatt_dtc_fixture/$growatt_link_file"
assert_rejected "$growatt_dtc_fixture"

growatt_sufficient_fixture="$tmp_dir/growatt-never-sufficient"
copy_fixture "$growatt_sufficient_fixture"
perl -0pi -e 's/are necessary for a device to accept a message and are never sufficient: this repository defines no condition under which Helianthus software transmits\./are sufficient to transmit./' "$growatt_sufficient_fixture/$growatt_pcs_file"
assert_rejected "$growatt_sufficient_fixture"

growatt_evidence_fixture="$tmp_dir/growatt-evidence"
copy_fixture "$growatt_evidence_fixture"
perl -0pi -e 's/No public source is cited, and every statement is an unverified candidate claim\.//' "$growatt_evidence_fixture/$growatt_link_file"
assert_rejected "$growatt_evidence_fixture"

for growatt_internal in 'payload builder' 'internal timer' 'ADC codes' '/Users/'; do
  growatt_internal_fixture="$tmp_dir/growatt-internal-${RANDOM}"
  copy_fixture "$growatt_internal_fixture"
  printf '\n%s detail.\n' "$growatt_internal" >> "$growatt_internal_fixture/$growatt_pcs_file"
  assert_rejected "$growatt_internal_fixture"
done

growatt_mermaid_fixture="$tmp_dir/growatt-mermaid"
copy_fixture "$growatt_mermaid_fixture"
printf '\n```mermaid\nstateDiagram-v2\n```\n' >> "$growatt_mermaid_fixture/$growatt_link_file"
assert_rejected "$growatt_mermaid_fixture"

growatt_waiver_fixture="$tmp_dir/growatt-waiver"
copy_fixture "$growatt_waiver_fixture"
perl -0pi -e 's/and the public-URL rule in `AGENTS\.md` is waived for them only\./and nothing else applies./' "$growatt_waiver_fixture/$growatt_index_file"
assert_rejected "$growatt_waiver_fixture"

for growatt_phrase in 'pre-transmit qualification' 'Before transmitting' 'host request to perform'; do
  growatt_phrase_fixture="$tmp_dir/growatt-sender-phrase-${RANDOM}"
  copy_fixture "$growatt_phrase_fixture"
  printf '\n%s detail.\n' "$growatt_phrase" >> "$growatt_phrase_fixture/$growatt_pcs_file"
  assert_rejected "$growatt_phrase_fixture"
done

growatt_monitor_file='protocols/growatt/growatt-low-voltage-bms-can-monitor-addressed-profile-v1.md'

growatt_monitor_missing_fixture="$tmp_dir/growatt-monitor-missing"
copy_fixture "$growatt_monitor_missing_fixture"
rm "$growatt_monitor_missing_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_missing_fixture"

growatt_monitor_heading_fixture="$tmp_dir/growatt-monitor-heading"
copy_fixture "$growatt_monitor_heading_fixture"
perl -0pi -e 's/\n## Addressed monitor field reference\n/\n## Field reference\n/' "$growatt_monitor_heading_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_heading_fixture"

growatt_monitor_selection_fixture="$tmp_dir/growatt-monitor-selection"
copy_fixture "$growatt_monitor_selection_fixture"
perl -0pi -e 's/it is never a fallback decoder for native `18xx` traffic/it is a fallback decoder for native `18xx` traffic/' "$growatt_monitor_selection_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_selection_fixture"

growatt_monitor_identifier_fixture="$tmp_dir/growatt-monitor-identifier"
copy_fixture "$growatt_monitor_identifier_fixture"
perl -0pi -e 's/The signal names are descriptive labels, not stable identifiers/The signal names are stable identifiers/' "$growatt_monitor_identifier_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_identifier_fixture"

for growatt_monitor_term in Banlence Serise Numbwer Detct MAINTANCE ghidra capture; do
  growatt_monitor_term_fixture="$tmp_dir/growatt-monitor-term-${RANDOM}"
  copy_fixture "$growatt_monitor_term_fixture"
  printf '\n%s detail.\n' "$growatt_monitor_term" >> "$growatt_monitor_term_fixture/$growatt_monitor_file"
  assert_rejected "$growatt_monitor_term_fixture"
done

growatt_monitor_permission_fixture="$tmp_dir/growatt-monitor-permission"
copy_fixture "$growatt_monitor_permission_fixture"
printf '\nAn implementation MAY transmit a monitor frame.\n' >> "$growatt_monitor_permission_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_permission_fixture"

growatt_monitor_link_fixture="$tmp_dir/growatt-monitor-link"
copy_fixture "$growatt_monitor_link_fixture"
perl -0pi -e 's/\]\(growatt-low-voltage-bms-can-link-protocol-v1\.md#receive-handler-classes\)/](growatt-low-voltage-bms-can-link-protocol-v1.md#receive-handler-classez)/' "$growatt_monitor_link_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_link_fixture"

growatt_monitor_stub_fixture="$tmp_dir/growatt-monitor-stub"
copy_fixture "$growatt_monitor_stub_fixture"
perl -0pi -e 's/The separate \[addressed monitor profile\]\(growatt-low-voltage-bms-can-monitor-addressed-profile-v1\.md\) describes them\./The monitor profile is described elsewhere./' "$growatt_monitor_stub_fixture/$growatt_link_file"
assert_rejected "$growatt_monitor_stub_fixture"

growatt_monitor_identifier_style_fixture="$tmp_dir/growatt-monitor-identifier-style"
copy_fixture "$growatt_monitor_identifier_style_fixture"
printf '\nSee `Some_Vendor_Field` and `SomeVendorField`.\n' >> "$growatt_monitor_identifier_style_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_identifier_style_fixture"

growatt_monitor_request_fixture="$tmp_dir/growatt-monitor-request"
copy_fixture "$growatt_monitor_request_fixture"
printf '\nAutomatic requests remain excluded for unknown peers.\n' >> "$growatt_monitor_request_fixture/$growatt_monitor_file"
assert_rejected "$growatt_monitor_request_fixture"

growatt_waiver_scope_fixture="$tmp_dir/growatt-waiver-scope"
copy_fixture "$growatt_waiver_scope_fixture"
perl -0pi -e 's/\(issues #37 and #39\)/(issue #37)/' "$growatt_waiver_scope_fixture/$growatt_index_file"
assert_rejected "$growatt_waiver_scope_fixture"
