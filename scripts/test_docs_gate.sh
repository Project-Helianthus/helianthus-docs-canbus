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

deny_fixture="$tmp_dir/deny"
cp -R . "$deny_fixture"
perl -0pi -e 's/sends a CAN frame\. There is no transmit API, automatic configuration, probing,/sends a CAN frame./' "$deny_fixture/architecture/can-transport.md"
assert_rejected "$deny_fixture"

permission_fixture="$tmp_dir/permission"
cp -R . "$permission_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nAn implementation MAY be used to transmit a diagnostic frame./' "$permission_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$permission_fixture"

indirect_permission_fixture="$tmp_dir/indirect-permission"
cp -R . "$indirect_permission_fixture"
perl -0pi -e 's/(# Gree VRF CAN Bus Contract)/$1\n\nA diagnostic frame transmit is permitted./' "$indirect_permission_fixture/protocols/gree/vrf-canbus.md"
assert_rejected "$indirect_permission_fixture"
