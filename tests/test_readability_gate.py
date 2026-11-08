"""Synthetic behavior checks for the offline readability ratchet."""

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "readability", Path(__file__).resolve().parents[1] / "scripts/check_readability.py"
)
GATE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GATE)


def entry(**changes):
    record = {"path": "scripts/example.py", "symbol": "measure",
              "rule": "C901", "count": 12}
    return record | changes


def document(entries):
    return {"version": 1, "generated_by": f"ruff {GATE.VERSION}", "generation": GATE.GENERATION, "entries": entries}


def complex_source(name, branches):
    return f"def {name}(value):\n" + "".join(
        f"    if value == {index}:\n        return {index}\n"
        for index in range(branches)
    ) + "    return None\n"


class ReadabilityTests(unittest.TestCase):
    def setUp(self):
        self.baseline = GATE.baseline_records(document([entry()]))
        self.key = next(iter(self.baseline))

    def test_clean_tree_has_no_debt(self):
        self.assertEqual(GATE.compare_records({}, {}), [])

    def test_existing_and_reduced_debt_are_accepted(self):
        for count in (12, 11):
            with self.subTest(count=count):
                self.assertEqual(GATE.compare_records({self.key: count}, self.baseline), [])

    def test_grown_debt_is_rejected(self):
        self.assertTrue(GATE.compare_records({self.key: 13}, self.baseline))

    def test_each_identity_field_prevents_debt_transfer(self):
        for changes in ({"path": "scripts/other.py"}, {"symbol": "other"},
                        {"rule": "PLR0915"}):
            with self.subTest(changes=changes):
                changed = GATE.baseline_records(document([entry(**changes)]))
                self.assertTrue(GATE.compare_records(changed, self.baseline))

    def test_deleted_debt_requires_removal_of_unused_record(self):
        self.assertTrue(GATE.compare_records({}, self.baseline))
        self.assertEqual(GATE.compare_records({}, {}), [])

    def test_duplicate_baseline_records_are_rejected(self):
        with self.assertRaises(ValueError):
            GATE.baseline_records(document([entry(), entry()]))

    def test_malformed_baseline_fails_closed(self):
        for changes in ({"count": True}, {"count": 0}, {"symbol": ""},
                        {"path": "../example.py"}, {"rule": "X001"}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                GATE.baseline_records(document([entry(**changes)]))
        with self.assertRaises(ValueError):
            GATE.baseline_records(document([]) | {"generated_by": "unknown"})

    def test_moved_lines_preserve_qualified_symbol(self):
        source = "class Example:\n    def measure(self):\n        pass\n"
        self.assertEqual(GATE.symbol_at(source, 2), "Example.measure")
        self.assertEqual(GATE.symbol_at("\n\n" + source, 4), "Example.measure")

    def test_nested_symbols_keep_qualified_ownership(self):
        source = "def outer(value):\n    def inner():\n        pass\n    return value\n"
        self.assertEqual(GATE.symbol_at(source, 2), "outer.inner")

    def test_symbols_under_control_flow_keep_qualified_ownership(self):
        source = "if True:\n    def measure():\n        pass\n"
        self.assertEqual(GATE.symbol_at(source, 2), "measure")

    def test_malformed_json_is_rejected(self):
        for output in ("invalid", "{}", '[{"code": "C901"}]'):
            with self.subTest(output=output), self.assertRaises((ValueError, KeyError)):
                GATE.observed_records(output, Path.cwd())

    def test_tool_failure_and_missing_tool_fail_closed(self):
        for failure in (FileNotFoundError(), subprocess.TimeoutExpired("ruff", 1)):
            with self.subTest(failure=failure), patch.object(
                GATE.subprocess, "run", side_effect=failure
            ), self.assertRaises((OSError, subprocess.SubprocessError)):
                GATE.run_ruff(Path.cwd())
        version = subprocess.CompletedProcess([], 0, f"ruff {GATE.VERSION}\n", "")
        failed = subprocess.CompletedProcess([], 2, "[]", "failure")
        with patch.object(GATE.subprocess, "run", side_effect=[version, failed]):
            with self.assertRaises(ValueError):
                GATE.run_ruff(Path.cwd())

    def test_wrong_tool_version_is_rejected(self):
        result = subprocess.CompletedProcess([], 0, "ruff unknown\n", "")
        with patch.object(GATE.subprocess, "run", return_value=result):
            with self.assertRaises(ValueError):
                GATE.run_ruff(Path.cwd())

    def test_cached_ruff_rejects_new_function_in_baselined_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "ruff.toml").write_text((GATE.ROOT / "ruff.toml").read_text())
            source = root / "scripts/example.py"
            source.write_text(complex_source("measure", 11))
            baseline = GATE.run_ruff(root)
            self.assertEqual(baseline[("scripts/example.py", "measure", "C901")], 12)
            source.write_text("\n\n" + complex_source("measure", 11))
            self.assertEqual(GATE.compare_records(GATE.run_ruff(root), baseline), [])
            source.write_text(complex_source("measure", 11) + complex_source("other", 11))
            self.assertTrue(GATE.compare_records(GATE.run_ruff(root), baseline))
            source.write_text(complex_source("measure", 12))
            self.assertTrue(GATE.compare_records(GATE.run_ruff(root), baseline))
            source.write_text(complex_source("measure", 10))
            self.assertEqual(GATE.compare_records(GATE.run_ruff(root), baseline), [])

    def test_naming_and_statement_counts_are_measured(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "ruff.toml").write_text((GATE.ROOT / "ruff.toml").read_text())
            (root / "scripts/example.py").write_text(
                "def BadName():\n" + "    value = 1\n" * 51 + "    return value\n"
            )
            records = GATE.run_ruff(root)
            self.assertEqual(records[("scripts/example.py", "BadName", "N802")], 1)
            self.assertEqual(records[("scripts/example.py", "BadName", "PLR0915")], 51)

    def test_default_lint_remains_enforced_for_new_debt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "ruff.toml").write_text((GATE.ROOT / "ruff.toml").read_text())
            (root / "scripts/example.py").write_text("import unused\n")
            records = GATE.run_ruff(root)
            self.assertIn(("scripts/example.py", "<module>", "F401"), records)
            self.assertTrue(GATE.compare_records(records, {}))


if __name__ == "__main__":
    unittest.main()
