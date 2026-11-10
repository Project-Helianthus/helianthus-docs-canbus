#!/usr/bin/env python3
"""Check the published CAN naming inventory invariants."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def validate(data):
    rows = data['rows']
    identities = [r['identity'] for r in rows]
    assert len(rows) == 772 and len(set(identities)) == len(rows)
    expected = {(f, old, new) for f in ('growatt_link_telemetry.go', 'growatt_pcs_standard.go', 'growatt_pcs_parallel_release11.go') for old, new in (('maximum_temperature', 'temperature_maximum'), ('minimum_temperature', 'temperature_minimum'))}
    actual = {(r['owning_file'], r['current_name'], r['target']) for r in rows if r['status'] == 'ready'}
    assert actual == expected
    for r in rows:
        assert r['identity'].startswith(r['owning_file'] + ':' + r['kind'] + ':')
        assert r['identity'].rsplit(':', 1)[-1] == r['current_name']
        assert r['status'] in ('ready', 'provisional', 'unchanged')
        if r['status'] != 'ready':
            assert r['current_name'] == r['target']
    assert {r['current_name'] for r in rows if r['status'] == 'provisional'} >= {'maximum_code', 'minimum_code', 'word_0', 'b4', 'capacity', 'state', 'accumulator', 'charge_limit', 'discharge_limit'}


if __name__ == '__main__':
    validate(json.loads((ROOT / 'architecture/naming-contract.json').read_text()))
    print('CAN naming contract valid')
