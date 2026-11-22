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
  tar -c -f - --exclude=.git --exclude=.tmp . | tar -C "$fixture" -x -f -
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
perl -0pi -e 's/The transport sends the frames a driver submits through its send API and offers/The transport receives frames./' "$deny_fixture/architecture/can-transport.md"
assert_rejected "$deny_fixture"

listen_only_fixture="$tmp_dir/listen-only"
copy_fixture "$listen_only_fixture"
perl -0pi -e 's/The caller configures listen-only for an interface that only receives/The caller may omit listen-only for an interface that only receives/' "$listen_only_fixture/contracts/socketcan-receive-only.md"
assert_rejected "$listen_only_fixture"

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

for material in firmware corpus ghidra trace dump; do
  material_fixture="$tmp_dir/material-$material"
  copy_fixture "$material_fixture"
  perl -0pi -e "s/(# Gree VRF CAN Bus Contract)/\$1\\n\\n$material detail: restricted./" "$material_fixture/protocols/gree/vrf-canbus.md"
  assert_rejected "$material_fixture"
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
perl -0pi -e 's/Frames the specification documents as commands have a transmit path\.//' "$growatt_receive_only_fixture/$growatt_pcs_file"
assert_rejected "$growatt_receive_only_fixture"

growatt_adjacent_fixture="$tmp_dir/growatt-pcs-adjacent-release"
copy_fixture "$growatt_adjacent_fixture"
perl -0pi -e 's/MUST NOT be admitted using a numerically adjacent release/may be admitted using a numerically adjacent release/' "$growatt_adjacent_fixture/$growatt_pcs_file"
assert_rejected "$growatt_adjacent_fixture"

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
printf '\ndefines no condition under which Helianthus software transmits\n' >> "$growatt_sufficient_fixture/$growatt_index_file"
assert_rejected "$growatt_sufficient_fixture"

growatt_evidence_fixture="$tmp_dir/growatt-evidence"
copy_fixture "$growatt_evidence_fixture"
perl -0pi -e 's/They cite no public source\.//' "$growatt_evidence_fixture/$growatt_link_file"
assert_rejected "$growatt_evidence_fixture"

growatt_index_evidence_fixture="$tmp_dir/growatt-index-evidence"
copy_fixture "$growatt_index_evidence_fixture"
perl -0pi -e 's/are the decode contract when an endpoint is configured with them//' "$growatt_index_evidence_fixture/$growatt_index_file"
assert_rejected "$growatt_index_evidence_fixture"

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
perl -0pi -e 's/the public-URL rule in `AGENTS\.md` is waived for them only/the publication rule is unchanged/' "$growatt_waiver_fixture/$growatt_index_file"
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

growatt_scope_sentence_fixture="$tmp_dir/growatt-scope-sentence"
copy_fixture "$growatt_scope_sentence_fixture"
perl -0pi -e 's/are insufficient for acceptance. The documented configured inverter-side transmission scope is separate//' "$growatt_scope_sentence_fixture/$growatt_pcs_file"
assert_rejected "$growatt_scope_sentence_fixture"

growatt_status_bits_fixture="$tmp_dir/growatt-status-bits"
copy_fixture "$growatt_status_bits_fixture"
perl -0pi -e 's/Bit 3 is cell-balance status//' "$growatt_status_bits_fixture/protocols/growatt/low-voltage-bms-can-v104.md"
assert_rejected "$growatt_status_bits_fixture"

growatt_protection_fixture="$tmp_dir/growatt-protection-bits"
copy_fixture "$growatt_protection_fixture"
perl -0pi -e 's/soft-start failure//' "$growatt_protection_fixture/protocols/growatt/low-voltage-bms-can-v104.md"
assert_rejected "$growatt_protection_fixture"

growatt_warning_fixture="$tmp_dir/growatt-warning-bits"
copy_fixture "$growatt_warning_fixture"
perl -0pi -e 's/internal communication failure//' "$growatt_warning_fixture/protocols/growatt/low-voltage-bms-can-v104.md"
assert_rejected "$growatt_warning_fixture"

growatt_decode_contract_fixture="$tmp_dir/growatt-decode-contract"
copy_fixture "$growatt_decode_contract_fixture"
perl -0pi -e 's/field reference is the decode contract//' "$growatt_decode_contract_fixture/$growatt_monitor_file"
assert_rejected "$growatt_decode_contract_fixture"

growatt_old_301_fixture="$tmp_dir/growatt-old-301"
copy_fixture "$growatt_old_301_fixture"
printf '\ndoes not interpret that frame\n' >> "$growatt_old_301_fixture/protocols/growatt/low-voltage-bms-can-v104.md"
assert_rejected "$growatt_old_301_fixture"

growatt_301_removed_fixture="$tmp_dir/growatt-301-removed"
copy_fixture "$growatt_301_removed_fixture"
perl -0pi -e 's/inverter side sends the standard \(11-bit\) frame `0x301` every second//' "$growatt_301_removed_fixture/protocols/growatt/low-voltage-bms-can-v104.md"
assert_rejected "$growatt_301_removed_fixture"

growatt_compatibility_fixture="$tmp_dir/growatt-compatibility"
copy_fixture "$growatt_compatibility_fixture"
printf '\nControl semantics, polling, and transmit behavior are outside this contract\n' >> "$growatt_compatibility_fixture/protocols/growatt/low-voltage-bms-can-v104.md"
assert_rejected "$growatt_compatibility_fixture"

growatt_peer_fixture="$tmp_dir/growatt-qualified-peer"
copy_fixture "$growatt_peer_fixture"
printf '\nselected only by an independently qualified peer\n' >> "$growatt_peer_fixture/$growatt_monitor_file"
assert_rejected "$growatt_peer_fixture"

growatt_v108_absent_fixture="$tmp_dir/growatt-v108-absent"
copy_fixture "$growatt_v108_absent_fixture"
rm "$growatt_v108_absent_fixture/protocols/growatt/low-voltage-bms-can-v108.md"
assert_rejected "$growatt_v108_absent_fixture"

gree_opaque_default_fixture="$tmp_dir/gree-opaque-default"
copy_fixture "$gree_opaque_default_fixture"
printf '\nAn unqualified observation remains opaque by default\n' >> "$gree_opaque_default_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$gree_opaque_default_fixture"

gree_waiver_fixture="$tmp_dir/gree-waiver"
copy_fixture "$gree_waiver_fixture"
perl -0pi -e 's/the public-URL rule in `AGENTS\.md` is waived for them only//' "$gree_waiver_fixture/protocols/gree/README.md"
assert_rejected "$gree_waiver_fixture"

gree_prerequisite_fixture="$tmp_dir/gree-prerequisite"
copy_fixture "$gree_prerequisite_fixture"
printf '\nOnly separately qualified facts can be promoted\n' >> "$gree_prerequisite_fixture/protocols/gree/gree-vrf-can-qualification-card-v1.md"
assert_rejected "$gree_prerequisite_fixture"

gree_interface_fixture="$tmp_dir/gree-interface"
copy_fixture "$gree_interface_fixture"
perl -0pi -e 's/exact configured CAN interface/configured bus/' "$gree_interface_fixture/protocols/gree/gree-vrf-can-command-contract.md"
assert_rejected "$gree_interface_fixture"

gree_generation_fixture="$tmp_dir/gree-generation"
copy_fixture "$gree_generation_fixture"
perl -0pi -e 's/active lifecycle generation/current session/' "$gree_generation_fixture/protocols/gree/gree-vrf-can-command-contract.md"
assert_rejected "$gree_generation_fixture"
