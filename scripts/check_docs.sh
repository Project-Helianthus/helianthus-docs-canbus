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
  'protocols/gree/gree-vrf-can-command-contract.md'
  'protocols/gree/gree-vrf-can-qualification-card-v1.md'
  'protocols/gree/vrf-uart.md'
  'protocols/gree/gree-vrf-uart.json'
  'protocols/gree/gree-vrf-property-catalog.md'
  'protocols/gree/gree-vrf-uart-vectors.json'
  'protocols/gree/gree-vrf-can-register-model.md'
  'protocols/gree/gree-vrf-can-value-types.json'
  'protocols/gree/gree-vrf-can-dictionary.md'
  'protocols/gree/dictionary/identity.json'
  'protocols/gree/dictionary/temperatures-operating-state.json'
  'protocols/gree/dictionary/status-bits.json'
  'protocols/gree/dictionary/electrical-system.json'
  'protocols/gree/dictionary/settings.json'
  'protocols/gree/dictionary/remaining.json'
  'protocols/gree/gree-vrf-can-device-classes.md'
  'protocols/gree/gree-vrf-can-device-classes.json'
  'protocols/gree/gree-vrf-can-presentation-converters.md'
  'protocols/gree/gree-vrf-can-presentation-converters.json'
  'protocols/growatt/low-voltage-bms-can-v104.md'
  'protocols/growatt/low-voltage-bms-can-v108.md'
  'protocols/growatt/growatt-low-voltage-bms-can-v104-qualification-card-v1.md'
  'protocols/growatt/growatt-low-voltage-bms-can-version-evidence-v1.md'
  'protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md'
  'protocols/growatt/README.md'
  'protocols/growatt/growatt-low-voltage-bms-can-pcs-protocol-v1.md'
  'protocols/growatt/growatt-low-voltage-bms-can-link-protocol-v1.md'
  'protocols/growatt/growatt-low-voltage-bms-can-monitor-addressed-profile-v1.md'
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
  'protocols/gree/gree-vrf-can-value-types.json'
  'protocols/gree/gree-vrf-can-device-classes.json'
  'protocols/gree/gree-vrf-can-presentation-converters.json'
  'protocols/gree/dictionary/identity.json'
  'protocols/gree/dictionary/temperatures-operating-state.json'
  'protocols/gree/dictionary/status-bits.json'
  'protocols/gree/dictionary/electrical-system.json'
  'protocols/gree/dictionary/settings.json'
  'protocols/gree/dictionary/remaining.json'
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
grep -Fq 'A complete V1.05 layout is unknown until its revision specification exists.' "$growatt_version_evidence"
grep -Fq 'no generic `>= V1.07` rule' "$growatt_version_evidence"
grep -Fq 'Complete revision contract: the [V1.08 page](low-voltage-bms-can-v108.md)' "$growatt_version_evidence"
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
for heading in 'Scope and Safety' 'Input Boundary' 'Common Field Projection' 'Revision and Conflict Handling' 'Topology Context Values' 'Non-Claims'; do
  grep -Fqx "## $heading" "$growatt_common_projection"
done
grep -Fq 'caller-selected projection for fields' "$growatt_common_projection"
grep -Fqx '| Member | Allowed values | Asserted or observed | Rule |' "$growatt_common_projection"
grep -Fq '| `bank` | `ordinary`, `parallel` | Asserted by configuration | `ordinary` is the documented standard bank;' "$growatt_common_projection"
grep -Fq 'Standard PCS pairs with the' "$growatt_common_projection"
grep -Fq '`ordinary` bank and parallel PCS pairs with the `parallel` bank;' "$growatt_common_projection"
grep -Fq 'exist for the standard PCS and for the selected parallel profile.' "$growatt_common_projection"
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
grep -Fq 'Frames the specification documents as commands have a transmit path.' "$growatt_pcs"
grep -Fq 'Declared from the protocol documents this page rests on.' "$growatt_pcs"
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
grep -Fq 'Frames the specification documents as commands have a transmit path.' "$growatt_link"
grep -Fq 'Declared from the protocol documents this page rests on.' "$growatt_link"
grep -Fq 'A project-code selector MUST NOT select a revision label, and a revision label MUST NOT select a project code.' "$growatt_link"
grep -Fq 'There is no universal LINK capability bitmap or harmless query that establishes' "$growatt_link"
grep -Fq 'Preserve `QAaT8252` literally. Do not rewrite it as `QAAA0001`.' "$growatt_link"
grep -Fq 'are maintenance-only for unknown' "$growatt_link"
grep -Fq 'Retain service/configuration traffic without automatic replay.' "$growatt_link"
grep -Fq 'This contract assigns no layout to those families' "$growatt_link"

for growatt_doc in "$growatt_pcs" "$growatt_link"; do
  grep -Fq 'are insufficient for acceptance. The documented configured inverter-side transmission scope is separate' "$growatt_doc"
  grep -Fq 'They cite no public source.' "$growatt_doc"
done
grep -Fq 'V1.04 applies only when the caller explicitly selects it for an interface' "$growatt_pcs"
for growatt_doc in "$growatt_pcs" "$growatt_link"; do
  grep -Fq '(growatt-low-voltage-bms-can-common-projection-v1.md#topology-context-values)' "$growatt_doc"
done
diff <(sed -n '/^## Diagnostic codes$/,/^## Standard parallel/p' "$growatt_pcs" | sed '$d') \
     <(sed -n '/^## Diagnostic codes$/,/^## Coordinator and stack traffic$/p' "$growatt_link" | sed '$d') >/dev/null

growatt_monitor='protocols/growatt/growatt-low-voltage-bms-can-monitor-addressed-profile-v1.md'
for heading in 'Status and Relationship' 'Addressed monitor profile' 'Addressed monitor field reference'; do
  grep -Fqx "## $heading" "$growatt_monitor"
done
grep -Fqx '# Growatt Low-Voltage BMS CAN Addressed Monitor Profile V1' "$growatt_monitor"
grep -Fq 'Frames the specification documents as commands have a transmit path.' "$growatt_monitor"
grep -Fq 'are insufficient for acceptance. The documented configured inverter-side transmission scope is separate' "$growatt_monitor"
grep -Fq 'field reference is the decode contract' "$growatt_monitor"
grep -Fq 'Configuring an endpoint with this profile is sufficient to select it.' "$growatt_monitor"
grep -Fq 'Byte order is an open point' "$growatt_monitor"
if grep -Fq 'until the exact bit dictionary is qualified' "$growatt_monitor"; then
  echo 'monitor bit dictionary still conditional' >&2
  exit 1
fi
if grep -Fq 'selected only by an independently qualified peer' "$growatt_monitor" "$growatt_link"; then
  echo 'qualified peer association restored' >&2
  exit 1
fi
grep -Fq 'it is never a fallback decoder for native `18xx` traffic' "$growatt_monitor"
if grep -Eq '`[A-Za-z0-9]*[a-z][A-Z][A-Za-z0-9/_]*`|`[A-Za-z0-9]+_[A-Za-z0-9_/]+`' "$growatt_monitor"; then
  echo "Growatt monitor profile reproduces a vendor-style identifier" >&2
  exit 1
fi
grep -Fq 'this document defines no discovery or query transaction' "$growatt_monitor"
grep -Fq 'defines no request transaction for this record and authorizes none' "$growatt_monitor"
grep -Fq 'A project-code selector MUST NOT select this profile' "$growatt_monitor"
grep -Fq 'The signal names are descriptive labels, not stable identifiers' "$growatt_monitor"
grep -Fq 'define no monitor request/reply transactions' "$growatt_monitor"

growatt_index='protocols/growatt/README.md'
grep -Fqx '# Growatt Low-Voltage BMS CAN Protocol Contracts' "$growatt_index"
grep -Fq 'A project-code selector MUST NOT select a revision label, and a' "$growatt_index"
grep -Fq 'are the decode contract when an endpoint is configured with them' "$growatt_index"
grep -Fq 'physical qualification is false and live trials are false' "$growatt_index"
grep -Fq 'low-voltage-bms-can-v108.md' "$growatt_index"
grep -Fq 'acceptance. The documented configured inverter-side transmission scope is' "$growatt_index"
if grep -Fq 'defines no condition under which Helianthus software transmits' "$growatt_index" "$growatt_pcs" "$growatt_link"; then
  echo 'blanket transmission denial restored' >&2
  exit 1
fi
if grep -Fq 'receive-only implementation' "$growatt_pcs"; then
  echo 'receive-only reading guide restored' >&2
  exit 1
fi
grep -Fq 'PCS, LINK and' "$growatt_index"
grep -Fq '(issues #37 and #39)' "$growatt_index"

protocol_forbidden_terms=(
  'reverse engineering' decompil disassembl corpus ghidra provenance capture
  laboratory trace dump 'mapping source' 'installed field unit' 'obtained from'
  'source archive' 'vendor manual' '/Users/' 'payload builder' composer 'internal timer'
  'ADC codes' producer '/home/' 'pre-transmi' 'before transmi' 'before send' 'host request'
  'Transmit gate for' Banlence Serise Numbwer Detct MAINTANCE PassedCharge
  'Automatic requests remain excluded' 'safe discovery request'
)
for growatt_doc in "$growatt_pcs" "$growatt_link" "$growatt_monitor" "$growatt_index"; do
  for forbidden in "${protocol_forbidden_terms[@]}"; do
    if grep -Fiq "$forbidden" "$growatt_doc"; then
      echo "Growatt protocol document contains prohibited material: $forbidden" >&2
      exit 1
    fi
  done
done

for growatt_doc in "$growatt_pcs" "$growatt_link" "$growatt_monitor" "$growatt_index"; do
  if grep -Fq '```mermaid' "$growatt_doc"; then
    echo "Growatt protocol document depends on a Mermaid renderer" >&2
    exit 1
  fi
done
grep -Fq 'the public-URL rule in `AGENTS.md` is waived for them only' "$growatt_index"

python3 scripts/check_markdown_links.py README.md "$growatt_index" "$growatt_pcs" "$growatt_link" "$growatt_monitor"

grep -Fq '[Growatt protocol index](protocols/growatt/README.md)' README.md
grep -Fq '[Growatt low-voltage BMS CAN PCS protocol](protocols/growatt/growatt-low-voltage-bms-can-pcs-protocol-v1.md)' README.md
grep -Fq '[Growatt low-voltage BMS CAN LINK protocol](protocols/growatt/growatt-low-voltage-bms-can-link-protocol-v1.md)' README.md
grep -Fq '[Growatt low-voltage BMS CAN addressed monitor profile](protocols/growatt/growatt-low-voltage-bms-can-monitor-addressed-profile-v1.md)' README.md
grep -Fq 'The separate [addressed monitor profile](growatt-low-voltage-bms-can-monitor-addressed-profile-v1.md) describes them.' "$growatt_link"

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

grep -Fq 'a documented map row of any source-key type reaches lookup after structural frame gates 1–5' "$spec"
grep -Fq 'A documented register frame reaches the register-feed lookup' "$spec"
grep -Fq 'not kept opaque for lack of a qualification' "$spec"
grep -Fq 'electrical compatibility' "$spec"
grep -Fq 'delivery to a physical bus' "$spec"
if grep -Fq 'An unqualified observation remains opaque by default' "$spec"; then
  echo 'unqualified opaque default restored' >&2
  exit 1
fi
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
grep -Fq 'They state facts (identifiers, types, scaling, units, frames).' protocols/gree/README.md
grep -Fq 'Their status is candidate.' protocols/gree/README.md
grep -Fq 'the public-URL rule in `AGENTS.md` is waived for them only' protocols/gree/README.md
if grep -Fq 'taken from vendor documentation that is not public' protocols/gree/README.md; then
  echo 'publication basis names a protocol source' >&2
  exit 1
fi
if grep -Fq 'Public frames corroborate' protocols/gree/README.md; then
  echo 'publication basis names a protocol source' >&2
  exit 1
fi
register_model='protocols/gree/gree-vrf-can-register-model.md'
for heading in 'Status and Relationship' 'Notation' 'Identifier Families and Addressing' 'Register Coordinates and Frame Rules' 'Value Types' 'Addressed Write Frames' 'Clock Frame' 'Timing' 'Not Established'; do
  grep -Fqx "## $heading" "$register_model"
done
grep -Fq '0x1effc000' "$register_model"
grep -Fq '0x1cffc000' "$register_model"
grep -Fq '0x1cbfc000' "$register_model"
grep -Fq 'They are not request' "$register_model"
grep -Fq 'Bytes of different frames are never joined' "$register_model"
grep -Fq 'not a confirmation of a physical effect' "$register_model"
dictionary_index='protocols/gree/gree-vrf-can-dictionary.md'
for heading in 'Status and Relationship' 'Files' 'Entry Schema' 'Reading the Dictionary' 'Unnamed Ranges' 'Notes Carried by Entries' 'Conflicts' 'Names'; do
  grep -Fqx "## $heading" "$dictionary_index"
done
grep -Fq '| Total | 50 types | 779 | 645 | 134 | 760 | 48 |' "$dictionary_index"
device_classes='protocols/gree/gree-vrf-can-device-classes.md'
for heading in 'Status and Relationship' 'Classes' 'Profile Identity and Selection' 'Reference Sets' 'State Projection Selectors' 'Not Established'; do
  grep -Fqx "## $heading" "$device_classes"
done
converters='protocols/gree/gree-vrf-can-presentation-converters.md'
for heading in 'Status and Relationship' 'Rounding' 'Converters' 'Saturation Tables' 'Not Established'; do
  grep -Fqx "## $heading" "$converters"
done
grep -Fq 'A decoder never applies a converter' "$converters"
python3 scripts/check_markdown_links.py protocols/gree/README.md "$register_model" "$dictionary_index" "$device_classes" "$converters" protocols/gree/vrf-canbus.md protocols/gree/gree-vrf-command-map.md protocols/gree/gree-vrf-can-command-contract.md
qualification_card='protocols/gree/gree-vrf-can-qualification-card-v1.md'
for heading in 'Scope' 'Preconditions' 'Sanitized Replay Input' 'Expected Native Result' 'Required Negative Controls' 'Qualification Status and Handoff'; do
  grep -Fqx "## $heading" "$qualification_card"
done
grep -Fq 'QUALIFICATION_TEST_READY' "$qualification_card"
grep -Fq 'Physical qualification is `false`' "$qualification_card"
grep -Fq 'Wrong identifier' "$qualification_card"
grep -Fq 'Wrong DLC' "$qualification_card"
grep -Fq 'Wrong map' "$qualification_card"
grep -Fq 'Documented meanings are declared from the specification.' "$qualification_card"
grep -Fq 'may also change the functions of bits 1..7 of that byte, and the actual effect of the write on those bits is not established' protocols/gree/gree-vrf-can-register-model.md
grep -Fq 'may also change the functions of bits 1..7 of that byte, and the actual effect of the write on those bits is not established' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'exact configured CAN interface' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'active lifecycle generation' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'Refuse a missing or elapsed deadline' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'before any send.' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'not reported' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'Local transport acceptance stays separate' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'weekday 7 as `0x07`' protocols/gree/gree-vrf-can-command-contract.md
grep -Fq 'weekday 0–6' protocols/gree/gree-vrf-can-command-contract.md
if grep -Fq 'Only separately qualified facts can be promoted' "$qualification_card"; then
  echo 'obsolete qualification prerequisite restored' >&2
  exit 1
fi

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

grep -Fq 'The transport sends the frames a driver submits through its send API and offers' architecture/can-transport.md
grep -Fq 'The caller configures listen-only for an interface that only receives' architecture/can-transport.md
grep -Fqx '## Send Boundary' architecture/can-transport.md
grep -Fq 'The transport sends the frames a driver submits through its send API and' contracts/socketcan-receive-only.md
grep -Fq 'The caller configures listen-only for an interface that only receives' contracts/socketcan-receive-only.md

diagnostics='contracts/socketcan-diagnostics.md'
for heading in 'Scope' 'Observation Record' 'Record Classification and Outcome' 'Queue and Loss Reporting' 'Receive Lifecycle' 'Adapter Boundary' 'Send Boundary'; do
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
grep -Fq 'The transport sends the frames a driver submits through its send API and' README.md
grep -Fq 'The transport does not probe, configure or bring up an interface on its own.' AGENTS.md

grep -Fq 'inverter side sends the standard (11-bit) frame `0x301` every second' "$growatt_spec"
grep -Fq '11-22-33-44-55-66-77-88' "$growatt_spec"
grep -Fq 'documented one-second `0x301` send' "$growatt_spec"
grep -Fq 'Bit 3 is cell-balance status' "$growatt_spec"
grep -Fq 'soft-start failure' "$growatt_spec"
grep -Fq 'internal communication failure' "$growatt_spec"
grep -Fq 'event-triggered data command' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq '1 s period, five consecutive times' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq 'triggered on the hour' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq 'not sent periodically' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq 'single application' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq '`0x324`' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq '`0x325`' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq 'byte 0 as the frame number, shown' protocols/growatt/low-voltage-bms-can-v108.md
grep -Fq 'with the value 0, and byte 1 as the battery ID' protocols/growatt/low-voltage-bms-can-v108.md
if grep -Fq 'does not interpret that frame' "$growatt_spec"; then
  echo 'old 0x301 sentence restored' >&2
  exit 1
fi
if grep -Fq 'Control semantics, polling, and transmit behavior are outside this contract' "$growatt_spec"; then
  echo 'blanket transmit exclusion restored' >&2
  exit 1
fi
for growatt_doc in "$growatt_spec" "$growatt_card" protocols/growatt/low-voltage-bms-can-v108.md; do
  for forbidden in "${forbidden_terms[@]}"; do
    if grep -Fiq "$forbidden" "$growatt_doc"; then
      echo "Growatt protocol contract contains prohibited material: $forbidden" >&2
      exit 1
    fi
  done
done
