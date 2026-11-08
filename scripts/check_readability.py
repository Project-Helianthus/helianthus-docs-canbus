"""Offline readability ratchet; baseline updates require explicit review."""

import argparse
import ast
import json
from pathlib import Path
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.15.10"
GENERATION = (
    "ruff check --no-cache --output-format=json --config ruff.toml scripts; "
    "resolve qualified AST symbols, retain reported metric values, "
    "aggregate other diagnostics per path/symbol/rule"
)
BASELINED_RULES = {"C901", "PLR0915"}
COUNTED_RULE = re.compile(r"(?:N|F)\d{3}|E[479]\d{2}")


def symbol_at(source, row):
    """Resolve qualified lexical ownership without depending on line identity."""
    tree = ast.parse(source)

    def descend(node, names):
        for child in ast.iter_child_nodes(node):
            if hasattr(child, "lineno") and child.lineno <= row <= child.end_lineno:
                scoped = isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef))
                return descend(child, names + [child.name] if scoped else names)
        return ".".join(names) or "<module>"

    return descend(tree, [])


def finding_record(item, root):
    code = item["code"]
    path = Path(item["filename"]).resolve()
    relative = path.relative_to(root.resolve()).as_posix()
    row = item["location"]["row"]
    if type(row) is not int or row < 1:
        raise ValueError("invalid diagnostic location")
    symbol = symbol_at(path.read_text(), row)
    count = 1
    if code in BASELINED_RULES:
        match = re.search(r"\((\d+) > \d+\)", item["message"])
        if not match:
            raise ValueError("missing measured count")
        count = int(match[1])
    elif not isinstance(code, str) or not COUNTED_RULE.fullmatch(code):
        raise ValueError(f"unbaselined lint failure: {relative}: {code}")
    return (relative, symbol, code), count


def observed_records(output, root):
    items = json.loads(output)
    if not isinstance(items, list):
        raise ValueError("diagnostics must be an array")
    records = {}
    for item in items:
        key, count = finding_record(item, root)
        if key in records and key[2] in BASELINED_RULES:
            raise ValueError("duplicate measured diagnostic")
        records[key] = records.get(key, 0) + count
    return records


def baseline_records(document):
    if set(document) != {"version", "generated_by", "generation", "entries"}:
        raise ValueError("invalid baseline schema")
    if type(document["version"]) is not int or document["version"] != 1:
        raise ValueError("invalid baseline schema version")
    if document["generated_by"] != f"ruff {VERSION}":
        raise ValueError("baseline version mismatch")
    if document["generation"] != GENERATION:
        raise ValueError("baseline generation method mismatch")
    if not isinstance(document["entries"], list):
        raise ValueError("entries must be an array")
    records = {}
    for entry in document["entries"]:
        key, count = validate_entry(entry)
        if key in records:
            raise ValueError("duplicate baseline record")
        records[key] = count
    return records


def validate_entry(entry):
    if set(entry) != {"path", "symbol", "rule", "count"}:
        raise ValueError("invalid baseline record")
    path, symbol, rule = (entry[name] for name in ("path", "symbol", "rule"))
    if not all(isinstance(value, str) and value for value in (path, symbol, rule)):
        raise ValueError("invalid identity")
    if not path.startswith("scripts/") or ".." in Path(path).parts or "\\" in path:
        raise ValueError("baseline path must be relative under scripts")
    if Path(path).as_posix() != path or not path.endswith(".py"):
        raise ValueError("noncanonical baseline path")
    if rule not in BASELINED_RULES and not COUNTED_RULE.fullmatch(rule):
        raise ValueError("unsupported baseline rule")
    if type(entry["count"]) is not int or entry["count"] < 1:
        raise ValueError("invalid observed count")
    return (path, symbol, rule), entry["count"]


def compare_records(observed, baseline):
    errors = []
    for key, count in observed.items():
        if key not in baseline or count > baseline[key]:
            errors.append(f"new or grown debt: {key}: {count}")
    for key in baseline.keys() - observed.keys():
        errors.append(f"unused baseline record; remove resolved debt: {key}")
    return errors


def run_ruff(root):
    version = subprocess.run(
        ["ruff", "--version"], capture_output=True, text=True, timeout=30, check=True
    )
    if version.stdout.strip() != f"ruff {VERSION}":
        raise ValueError("cached Ruff version mismatch")
    result = subprocess.run(
        ["ruff", "check", "--no-cache", "--output-format=json", "--config",
         str(root / "ruff.toml"), str(root / "scripts")],
        capture_output=True, text=True, timeout=120,
    )
    if result.returncode not in (0, 1):
        raise ValueError(f"Ruff failed: {result.stderr.strip()}")
    records = observed_records(result.stdout, root)
    if (result.returncode == 0) != (not records):
        raise ValueError("inconsistent Ruff result")
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--check", action="store_true")
    modes.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.discover(
            str(ROOT / "tests"), pattern="test_readability_gate.py"
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return int(not result.wasSuccessful() or result.testsRun == 0)
    try:
        baseline = baseline_records(json.loads(
            (ROOT / "scripts/readability-baseline.json").read_text()
        ))
        errors = compare_records(run_ruff(ROOT), baseline)
        if errors:
            raise ValueError("\n".join(errors))
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"readability check failed: {error}", file=sys.stderr)
        return 1
    print("Readability baseline accepted")
    return 0


if __name__ == "__main__":
    sys.exit(main())
