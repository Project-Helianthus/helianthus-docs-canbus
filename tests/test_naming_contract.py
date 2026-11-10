import copy
import importlib.util
import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('naming', ROOT / 'scripts/check_naming_contract.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def data():
    return json.loads((ROOT / 'architecture/naming-contract.json').read_text())


def test_inventory():
    module.validate(data())


@pytest.mark.parametrize('field', ['identity', 'owning_file', 'kind', 'current_name', 'target', 'status'])
def test_ready_identity_mutations_rejected(field):
    d = copy.deepcopy(data())
    row = next(r for r in d['rows'] if r['status'] == 'ready')
    row[field] = row[field] + '_changed'
    with pytest.raises(AssertionError):
        module.validate(d)


def test_provisional_rename_rejected():
    d = data()
    next(r for r in d['rows'] if r['status'] == 'provisional')['target'] = 'invented'
    with pytest.raises(AssertionError):
        module.validate(d)
