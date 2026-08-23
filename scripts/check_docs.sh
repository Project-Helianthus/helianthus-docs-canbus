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
)

for path in "${required[@]}"; do
  test -f "$path"
done

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

forbidden='reverse[ -]?engineering|decompil|disassembl|firmware|corpus|ghidra|provenance|acquisition|captur(e|ed|ing)?|laborator(y|ies)|trace(s)?|dump(s)?|mapping[[:space:]]+source|installed[[:space:]]+field[[:space:]]+unit|obtained from|source archive|vendor manual'
if grep -Ein "$forbidden" "$spec"; then
  echo 'Gree protocol contract contains prohibited material' >&2
  exit 1
fi

grep -Fq 'sends a CAN frame. There is no transmit API, automatic configuration, probing,' architecture/can-transport.md
grep -Fq 'or interface mutation.' architecture/can-transport.md
grep -Fq 'must not transmit, acknowledge, probe, configure, bring up,' contracts/socketcan-receive-only.md
grep -Fq 'default-denied and no document authorizes a live bus operation.' README.md

safety_docs=(
  'README.md'
  'architecture/can-transport.md'
  'contracts/socketcan-receive-only.md'
  "$spec"
)
tx_permission='(MAY|may|permitted to|authorized to)([[:space:]]+[[:alpha:]-]+){0,6}[[:space:]]+(transmit|send|write|acknowledge|probe|configure)|(transmit|send|write|acknowledge|probe|configure)[[:space:]].*(MAY|may|permitted|authorized)'
if grep -Ein "$tx_permission" "${safety_docs[@]}"; then
  echo 'CAN documentation contains a receive-only exception' >&2
  exit 1
fi
