#!/usr/bin/env bash
set -euo pipefail
trap 'status=$?; printf "check_docs.sh failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2; exit "$status"' ERR

required=(
  'README.md'
  'LICENSE'
  'architecture/can-transport.md'
  'architecture/registry-boundary.md'
  'contracts/registry-conformance.md'
  'contracts/socketcan-diagnostics.md'
  'contracts/socketcan-replay.md'
  'contracts/socketcan-receive-only.md'
  'protocols/LICENSE'
  'protocols/gree/README.md'
  'protocols/gree/vrf-canbus.md'
  'protocols/gree/gree-vrf-can-profile.json'
  'protocols/gree/gree-vrf-command-map.md'
  'protocols/gree/gree-vrf-command-map.json'
  'protocols/gree/gree-vrf-can-bridge-record-v1.md'
  'protocols/gree/gree-vrf-can-qualification-card-v1.md'
  'protocols/gree/vrf-uart.md'
  'protocols/gree/gree-vrf-uart.json'
  'protocols/gree/gree-vrf-property-catalog.md'
  'protocols/gree/gree-vrf-uart-vectors.json'
  'protocols/growatt/low-voltage-bms-can-v104.md'
  'protocols/growatt/growatt-low-voltage-bms-can-v104-qualification-card-v1.md'
  'protocols/growatt/growatt-low-voltage-bms-can-version-evidence-v1.md'
  'protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md'
  'protocols/growatt/README.md'
  'protocols/growatt/growatt-low-voltage-bms-can-pcs-protocol-v1.md'
  'protocols/growatt/growatt-low-voltage-bms-can-link-protocol-v1.md'
  'scripts/check_markdown_links.py'
)

for path in "${required[@]}"; do
  test -f "$path"
done

json_contracts=(
  'protocols/gree/gree-vrf-can-profile.json'
  'protocols/gree/gree-vrf-command-map.json'
  'protocols/gree/gree-vrf-uart.json'
  'protocols/gree/gree-vrf-uart-vectors.json'
)
for contract in "${json_contracts[@]}"; do
  python3 -m json.tool "$contract" >/dev/null
done

growatt_spec='protocols/growatt/low-voltage-bms-can-v104.md'
for heading in 'Scope and Safety' 'Link Profile' 'Required Frame Geometry' 'Frame Map' 'Status and Errors' 'Optional Frames' 'Registry Admission' 'Native MCP Observation Boundary' 'Unknown Data' 'Compatibility'; do
  grep -Fqx "## $heading" "$growatt_spec"
done
grep -Fq '500 kbit/s' "$growatt_spec"
grep -Fq '11-bit standard' "$growatt_spec"
grep -Fq 'big-endian' "$growatt_spec"
grep -Fq '0x311' "$growatt_spec"
grep -Fq '0x313' "$growatt_spec"
grep -Fq '0x321' "$growatt_spec"
grep -Fq 'MUST remain opaque' "$growatt_spec"
grep -Fq 'raw_evidence' "$growatt_spec"
grep -Fq 'outbound_allowed' "$growatt_spec"
grep -Fq 'Payload bytes beyond the effective payload length' "$growatt_spec"

growatt_card='protocols/growatt/growatt-low-voltage-bms-can-v104-qualification-card-v1.md'
for heading in 'Scope' 'Preconditions' 'Sanitized Replay Input' 'Expected Native Result' 'Required Negative Controls' 'Qualification Status and Handoff'; do
  grep -Fqx "## $heading" "$growatt_card"
done
grep -Fq 'growatt.bms.low_voltage.can.v1_04' "$growatt_card"
grep -Fq 'Incomplete tuple' "$growatt_card"
grep -Fq 'Wrong interface' "$growatt_card"
grep -Fq 'Wrong revision / extended ID' "$growatt_card"
grep -Fq 'Window expiry' "$growatt_card"
grep -Fq 'Physical qualification is `false`' "$growatt_card"
grep -Fq 'live trials are `false`' "$growatt_card"

growatt_version_evidence='protocols/growatt/growatt-low-voltage-bms-can-version-evidence-v1.md'
for heading in 'Scope and Safety' 'Evidence Classes' 'Source-Confidence and Version-Feature Matrix' 'Profile Separation' '`0x311` Balance-Flag Ambiguity' 'Sigineer Non-Admission Boundaries' 'Non-Claims and Next Evidence'; do
  grep -Fqx "## $heading" "$growatt_version_evidence"
done
grep -Fq 'V1.04' "$growatt_version_evidence"
grep -Fq 'V1.05' "$growatt_version_evidence"
grep -Fq 'V1.07' "$growatt_version_evidence"
grep -Fq 'V1.08' "$growatt_version_evidence"
grep -Fq 'scribd.com/document/541900756' "$growatt_version_evidence"
grep -Fq 'Sigineer-Power-Solar-Inverter-CANBUS-Protocol-20210122.pdf#page=9' "$growatt_version_evidence"
grep -Fq 'RawStatus' "$growatt_version_evidence"
grep -Fq 'invert, normalize, or reinterpret V1.04 `RawStatus`' "$growatt_version_evidence"
grep -Fq 'no V1.05 admission, decoder, or fallback' "$growatt_version_evidence"
grep -Fq 'no generic `>= V1.07` rule' "$growatt_version_evidence"
grep -Fq 'MUST NOT admit V1.08' "$growatt_version_evidence"
grep -Fq 'event-driven handling and adds fault-clear enable' "$growatt_version_evidence"
grep -Fq 'Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=4' "$growatt_version_evidence"
grep -Fq 'one total-cell-count byte limited to 1--254 plus extension flags' "$growatt_version_evidence"
grep -Fq 'legacy optional cell reports' "$growatt_version_evidence"
grep -Fq 'do not contribute a missing-cell failure when absent' "$growatt_version_evidence"
grep -Fq 'splits its `0x323` count between byte 0 and byte 3' "$growatt_version_evidence"
grep -Fq 'Sigineer-Power-Solar-Inverter-CANBUS-Protocol-20210122.pdf#page=16' "$growatt_version_evidence"
grep -Fq 'not complete per-cell telemetry' "$growatt_version_evidence"
grep -Fq 'Sigineer-Power-Solar-Inverter-CANBUS-Protocol-20210122.pdf#page=19' "$growatt_version_evidence"
grep -Fq '29-bit identifier while' "$growatt_version_evidence"
grep -Fq 'No Sigineer profile admission is defined until that contradiction is' "$growatt_version_evidence"
grep -Fq 'byte 3 is the BMS software version and bytes 4--7 are packed date and time' "$growatt_version_evidence"
grep -Fq 'Growatt-BMS-CAN-Bus-protocol-low-voltage-V1.04-1.pdf#page=7' "$growatt_version_evidence"
grep -Fq 'byte 3 is software-version low and byte 4 is software-version high' "$growatt_version_evidence"
grep -Fq 'firmware-to-protocol-revision correlation, so firmware MUST NOT select V1.04,' "$growatt_version_evidence"
grep -Fq 'V1.07, or V1.08. No V1.05, V1.07, or V1.08 evidence may widen V1.04 admission,' "$growatt_version_evidence"

growatt_common_projection='protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md'
for heading in 'Scope and Safety' 'Input Boundary' 'Common Field Projection' 'Revision and Conflict Handling' 'Non-Claims'; do
  grep -Fqx "## $heading" "$growatt_common_projection"
done
grep -Fq 'caller-selected, receive-only projection' "$growatt_common_projection"
grep -Fq 'standard 11-bit, non-RTR data frame with DLC 8' "$growatt_common_projection"
grep -Fq 'no raw frame, field, or' "$growatt_common_projection"
grep -Fq 'state from one interface or source can complete, replace, or conflict-resolve' "$growatt_common_projection"
grep -Fq 'identifiers, malformed frames, and fields not listed below remain raw.' "$growatt_common_projection"
grep -Fq 'provide no published firmware-to-protocol-revision correlation; firmware MUST' "$growatt_common_projection"
grep -Fqx 'NOT select a revision.' "$growatt_common_projection"
grep -Fq 'valid shared fields remain available and every divergent field is' "$growatt_common_projection"
grep -Fq 'Status remains raw: V1.04 defines status bits 10--11, while V1.08 reserves those bits.' "$growatt_common_projection"
grep -Fq 'Raw protection bytes 0--1, raw warning bytes 2--3, and pack count at byte 4.' "$growatt_common_projection"
grep -Fq 'V1.04 defines manufacturer bytes and total-cell count; V1.08 defines a derating reason and reserved bytes.' "$growatt_common_projection"
grep -Fq 'V1.04 defines maximum-cell temperature; V1.08 defines average temperature.' "$growatt_common_projection"
grep -Fq 'Sigineer material is a distinct family' "$growatt_common_projection"
grep -Fq 'supplies neither Growatt fields nor revision selection.' "$growatt_common_projection"
for page in 4 5 6; do
  grep -Fq "Growatt-BMS-CAN-Bus-protocol-low-voltage-V1.04-1.pdf#page=$page" "$growatt_common_projection"
done
grep -Fq '[Growatt low-voltage BMS CAN common projection](protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md)' README.md

growatt_pcs='protocols/growatt/growatt-low-voltage-bms-can-pcs-protocol-v1.md'
for heading in 'Status and Relationship' 'Reading a field correctly' 'Scope and conventions' 'Identify the profile before decoding version-dependent fields' 'Standard PCS: host input and telemetry' 'Diagnostic codes' 'Standard parallel / clustering profile' 'Extended PCS 19xx' 'Gateway interpretation rules' 'Opaque fields' 'Maintenance and firmware coordination channels' 'Data validity and consumer obligations'; do
  grep -Fqx "## $heading" "$growatt_pcs"
done
grep -Fqx '# Growatt Low-Voltage BMS CAN PCS Protocol V1' "$growatt_pcs"
grep -Fq 'This repository authorizes no transmission, acknowledgement, probing, configuration, update or other live bus action.' "$growatt_pcs"
grep -Fq '**Helianthus status: candidate.**' "$growatt_pcs"
grep -Fq 'A project-code selector MUST NOT select a revision label, and a revision label MUST NOT select a project code.' "$growatt_pcs"
grep -Fq '**A numeric version word of 6 does not select `QAAA0006`.**' "$growatt_pcs"
grep -Fq 'MUST NOT be admitted using a numerically adjacent release' "$growatt_pcs"
grep -Fq 'There is no universal, side-effect-free CAN command that enumerates application handlers.' "$growatt_pcs"
grep -Fq 'A device accepts an incoming PID only when its contract includes that PID' "$growatt_pcs"
grep -Fq 'as identification probes.' "$growatt_pcs"
grep -Fq 'It defines 134 indices for `QAAA0011` and 136 for `QAAa9011`.' "$growatt_pcs"

growatt_link='protocols/growatt/growatt-low-voltage-bms-can-link-protocol-v1.md'
for heading in 'Status and Relationship' 'Reading a field correctly' 'Interface scope' 'Identify the peer before interpreting version-dependent fields' 'Transport, addressing and data validity' 'Identity and ordinary module telemetry' 'Cell voltages, temperatures and balancing' 'Faults and additional status' 'Diagnostic codes' 'Coordinator and stack traffic' 'Serial number and date announcements' 'Configuration and service channels' 'Opaque fields and implementation limits' 'Addressed monitor profile' 'Interoperability rules'; do
  grep -Fqx "## $heading" "$growatt_link"
done
grep -Fqx '# Growatt Low-Voltage BMS CAN LINK Protocol V1' "$growatt_link"
grep -Fq 'This repository authorizes no transmission, acknowledgement, probing, configuration, update or other live bus action.' "$growatt_link"
grep -Fq '**Helianthus status: candidate.**' "$growatt_link"
grep -Fq 'A project-code selector MUST NOT select a revision label, and a revision label MUST NOT select a project code.' "$growatt_link"
grep -Fq 'There is no universal LINK capability bitmap or harmless query that establishes' "$growatt_link"
grep -Fq 'Preserve `QAaT8252` literally. Do not rewrite it as `QAAA0001`.' "$growatt_link"
grep -Fq 'are maintenance-only for unknown' "$growatt_link"
grep -Fq 'Retain service/configuration traffic without automatic replay.' "$growatt_link"
grep -Fq 'This contract assigns no layout to those families' "$growatt_link"

for growatt_doc in "$growatt_pcs" "$growatt_link"; do
  grep -Fq 'are necessary for a device to accept a message and are never sufficient: this repository defines no condition under which Helianthus software transmits.' "$growatt_doc"
  grep -Fq 'No public source is cited, and every statement is an unverified candidate claim.' "$growatt_doc"
done
grep -Fq 'V1.04 applies only when the caller explicitly selects it for an interface' "$growatt_pcs"
diff <(sed -n '/^## Diagnostic codes$/,/^## Standard parallel/p' "$growatt_pcs" | sed '$d') \
     <(sed -n '/^## Diagnostic codes$/,/^## Coordinator and stack traffic$/p' "$growatt_link" | sed '$d') >/dev/null

growatt_index='protocols/growatt/README.md'
grep -Fqx '# Growatt Low-Voltage BMS CAN Protocol Contracts' "$growatt_index"
grep -Fq 'A project-code selector MUST NOT select a revision label, and a' "$growatt_index"
grep -Fq 'none of them authorizes a transmission or any other live bus action' "$growatt_index"
grep -Fq 'every statement in them is an unverified candidate claim' "$growatt_index"
grep -Fq 'never sufficient. This repository defines no' "$growatt_index"

protocol_forbidden_terms=(
  'reverse engineering' decompil disassembl corpus ghidra provenance capture
  laboratory trace dump 'mapping source' 'installed field unit' 'obtained from'
  'source archive' 'vendor manual' '/Users/' 'payload builder' composer 'internal timer'
  'ADC codes' producer '/home/' 'pre-transmi' 'before transmi' 'before send' 'host request'
  'Transmit gate for'
)
for growatt_doc in "$growatt_pcs" "$growatt_link" "$growatt_index"; do
  for forbidden in "${protocol_forbidden_terms[@]}"; do
    if grep -Fiq "$forbidden" "$growatt_doc"; then
      echo "Growatt protocol document contains prohibited material: $forbidden" >&2
      exit 1
    fi
  done
done

for growatt_doc in "$growatt_pcs" "$growatt_link" "$growatt_index"; do
  if grep -Fq '```mermaid' "$growatt_doc"; then
    echo "Growatt protocol document depends on a Mermaid renderer" >&2
    exit 1
  fi
done
grep -Fq 'the public-URL rule in `AGENTS.md` is waived for them only' "$growatt_index"

python3 scripts/check_markdown_links.py README.md "$growatt_index" "$growatt_pcs" "$growatt_link"

grep -Fq '[Growatt protocol index](protocols/growatt/README.md)' README.md
grep -Fq '[Growatt low-voltage BMS CAN PCS protocol](protocols/growatt/growatt-low-voltage-bms-can-pcs-protocol-v1.md)' README.md
grep -Fq '[Growatt low-voltage BMS CAN LINK protocol](protocols/growatt/growatt-low-voltage-bms-can-link-protocol-v1.md)' README.md

grep -Fqx '# Helianthus CAN Bus Documentation' README.md
grep -Fq 'Everything outside protocols/ is licensed under [AGPL-3.0](LICENSE).' README.md
grep -Fq '[Growatt low-voltage BMS CAN version evidence](protocols/growatt/growatt-low-voltage-bms-can-version-evidence-v1.md)' README.md
grep -Fq 'public domain' protocols/LICENSE

spec='protocols/gree/vrf-canbus.md'
headings=(
  'Scope and Safety'
  'Candidate Link Profile'
  'Extended Identifier Layout'
  'Candidate Identifier Gate'
  'Receive Layout'
  'Active Maps'
  'State-Cell Update Rules'
  'Bounded Opaque Cell Projection'
  'Offline Command Encoding Boundary'
  'Compatibility'
)
for heading in "${headings[@]}"; do
  grep -Fqx "## $heading" "$spec"
done

grep -Fq 'receive-only' "$spec"
grep -Fq '20 kbit/s' "$spec"
grep -Fq '29-bit extended' "$spec"
grep -Fq 'CAN+ is only a hypothesis' "$spec"
grep -Fq 'M94' "$spec"
grep -Fq 'M115' "$spec"
grep -Fq '0x1fe0007f' "$spec"
grep -Fq '0x1ee00010' "$spec"
grep -Fq '0x1ee00011' "$spec"
grep -Fq '0x1ee00052' "$spec"
grep -Fq '0x1ee00058' "$spec"
grep -Fq 'class8 = 0xf7' "$spec"
grep -Fq 'unit7  = 8' "$spec"
grep -Fq '`M94` | `A` | 94 | 73' "$spec"
grep -Fq '`M115` | `B` | 115 | 83' "$spec"
grep -Fq '0x220d' "$spec"
grep -Fq 'all_slot_flags' "$spec"
grep -Fq 'cell` and `value`' "$spec"
grep -Fq 'A rejected or unqualified frame' "$spec"
grep -Fq 'identifier format, DLC, raw DLC, and' "$spec"
grep -Fq 'must not be fabricated, hashed, summarized, or replaced' "$spec"
grep -Fq 'exactly `0x23 bytes` long' protocols/gree/gree-vrf-can-bridge-record-v1.md
grep -Fq '19..20' protocols/gree/gree-vrf-can-bridge-record-v1.md
grep -Fq 'recipient, transport, direction, timing, or' protocols/gree/gree-vrf-can-bridge-record-v1.md
grep -Fq '`57600 8N1`' protocols/gree/vrf-uart.md
grep -Fq '0x05d1' protocols/gree/vrf-uart.md
grep -Fq 'Gree VRF Protocol Contracts' protocols/gree/README.md
qualification_card='protocols/gree/gree-vrf-can-qualification-card-v1.md'
for heading in 'Scope' 'Preconditions' 'Sanitized Replay Input' 'Expected Native Result' 'Required Negative Controls' 'Qualification Status and Handoff'; do
  grep -Fqx "## $heading" "$qualification_card"
done
grep -Fq 'QUALIFICATION_TEST_READY' "$qualification_card"
grep -Fq 'Physical qualification is `false`' "$qualification_card"
grep -Fq 'Wrong identifier' "$qualification_card"
grep -Fq 'Wrong DLC' "$qualification_card"
grep -Fq 'Wrong map' "$qualification_card"
grep -Fq 'no path for frame submission' "$qualification_card"

forbidden_terms=(
  'reverse engineering' decompil disassembl firmware corpus ghidra provenance
  acquisition capture laboratory trace dump 'mapping source' 'installed field unit'
  'obtained from' 'source archive' 'vendor manual'
)
gree_docs=()
while IFS= read -r doc; do
  gree_docs+=("$doc")
done < <(find protocols/gree -type f -print | sort)
for forbidden in "${forbidden_terms[@]}"; do
  if grep -Fiq "$forbidden" "${gree_docs[@]}"; then
    echo "Gree protocol contract contains prohibited material: $forbidden" >&2
    exit 1
  fi
done
for growatt_doc in "$growatt_spec" "$growatt_card"; do
  for forbidden in "${forbidden_terms[@]}"; do
    if grep -Fiq "$forbidden" "$growatt_doc"; then
      echo "Growatt protocol contract contains prohibited material: $forbidden" >&2
      exit 1
    fi
  done
done

grep -Fq 'sends a CAN frame. There is no transmit API, automatic configuration, probing,' architecture/can-transport.md
grep -Fq 'or interface mutation.' architecture/can-transport.md
grep -Fq 'must not transmit, acknowledge, probe, configure, bring up,' contracts/socketcan-receive-only.md
grep -Fq 'Caller MUST configure the physical controller in listen-only mode before' contracts/socketcan-receive-only.md
grep -Fq 'opening the descriptor. A descriptor backed by a normal controller MUST NOT be' contracts/socketcan-receive-only.md
grep -Fq 'admitted.' contracts/socketcan-receive-only.md

diagnostics='contracts/socketcan-diagnostics.md'
for heading in 'Scope' 'Observation Record' 'Record Classification and Outcome' 'Queue and Loss Reporting' 'Receive Lifecycle' 'Adapter Boundary' 'Receive-Only Boundary'; do
  grep -Fqx "## $heading" "$diagnostics"
done

replay='contracts/socketcan-replay.md'
for heading in 'Scope' 'Replay Input' 'Replay Rules' 'Outcome Assertions' 'Matrix Crosswalk' 'Safety Boundary'; do
  grep -Fqx "## $heading" "$replay"
done

registry='contracts/registry-conformance.md'
for heading in 'Scope' 'Evidence Admission' 'Profile Result' 'Conflict Resolution' 'Conformance Outcomes' 'Projection Boundary'; do
  grep -Fqx "## $heading" "$registry"
done
grep -Fq 'The caller MUST supply a descriptor backed by a controller already in physical' architecture/can-transport.md
grep -Fq 'default-denied and no document authorizes a live bus operation.' README.md

safety_docs=()
while IFS= read -r doc; do
  safety_docs+=("$doc")
done < <(find . -type f -name '*.md' -not -path './.git/*' -not -path './scripts/fixtures/*' -print | sort)
tx_permission='(MAY|may|permitted to|authorized to)([[:space:]]+[[:alpha:]-]+){0,6}[[:space:]]+(transmit|send|write|acknowledge|probe|configure|emit|inject|publish|output)|(transmit|send|write|acknowledge|probe|configure|emit|inject|publish|output)[[:space:]].*(MAY|may|permitted|authorized)'
if grep -Ein "$tx_permission" "${safety_docs[@]}"; then
  echo 'CAN documentation contains a receive-only exception' >&2
  exit 1
fi

tx_mandate='(MUST|must|SHOULD|should|shall)[[:space:]]+(transmit|send|write|acknowledge|probe|emit|inject|publish|output)'
if grep -Ein "$tx_mandate" "${safety_docs[@]}"; then
  echo 'CAN documentation contains a positive transmit mandate' >&2
  exit 1
fi
