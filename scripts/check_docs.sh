#!/usr/bin/env bash
set -euo pipefail

required=(
  'README.md'
  'LICENSE'
  'architecture/can-transport.md'
  'architecture/registry-boundary.md'
  'contracts/socketcan-receive-only.md'
  'protocols/LICENSE'
  'protocols/gree/vrf-canbus.md'
  'protocols/growatt/low-voltage-bms-can-v105.md'
)

for path in "${required[@]}"; do
  test -f "$path"
done

growatt_spec='protocols/growatt/low-voltage-bms-can-v105.md'
for heading in 'Scope and Safety' 'Candidate Link Metadata' 'Candidate Applicability' 'Admission and Evidence' 'Compatibility'; do
  grep -Fqx "## $heading" "$growatt_spec"
done
grep -Fq '500 kbit/s' "$growatt_spec"
grep -Fq 'No electrical inference is permitted' "$growatt_spec"
grep -Fq 'It does not authorize a registry flavor or' "$growatt_spec"
grep -Fq 'remain opaque and no Growatt registry classifier' "$growatt_spec"

grep -Fqx '# Helianthus CAN Bus Documentation' README.md
grep -Fq 'Everything outside protocols/ is licensed under [AGPL-3.0](LICENSE).' README.md
grep -Fq 'public domain' protocols/LICENSE

spec='protocols/gree/vrf-canbus.md'
headings=(
  'Scope and Safety'
  'Candidate Link Profile'
  'Extended Identifier Layout'
  'Receive Layout'
  'Candidate Decode Families'
  'State and Unknown Data'
  'Registry Admission'
  'Conformance Examples'
  'Compatibility'
)
for heading in "${headings[@]}"; do
  grep -Fqx "## $heading" "$spec"
done

grep -Fq 'receive-only' "$spec"
grep -Fq '20 kbit/s' "$spec"
grep -Fq '29-bit extended' "$spec"
grep -Fq 'Not equivalent to CAN' "$spec"
grep -Fq 'M94' "$spec"
grep -Fq 'M115' "$spec"

forbidden_terms=(
  'reverse engineering' decompil disassembl firmware corpus ghidra provenance
  acquisition capture laboratory trace dump 'mapping source' 'installed field unit'
  'obtained from' 'source archive' 'vendor manual'
)
for forbidden in "${forbidden_terms[@]}"; do
  if grep -Fiq "$forbidden" "$spec"; then
    echo "Gree protocol contract contains prohibited material: $forbidden" >&2
    exit 1
  fi
done
for forbidden in "${forbidden_terms[@]}"; do
  if grep -Fiq "$forbidden" "$growatt_spec"; then
    echo "Growatt protocol contract contains prohibited material: $forbidden" >&2
    exit 1
  fi
done

grep -Fq 'sends a CAN frame. There is no transmit API, automatic configuration, probing,' architecture/can-transport.md
grep -Fq 'or interface mutation.' architecture/can-transport.md
grep -Fq 'must not transmit, acknowledge, probe, configure, bring up,' contracts/socketcan-receive-only.md
grep -Fq 'Caller MUST configure the physical controller in listen-only mode before' contracts/socketcan-receive-only.md
grep -Fq 'opening the descriptor. A descriptor backed by a normal controller MUST NOT be' contracts/socketcan-receive-only.md
grep -Fq 'admitted.' contracts/socketcan-receive-only.md
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
