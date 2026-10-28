#!/usr/bin/env python3
"""Run with: python3 tests/gradle-tests.py"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HOME = Path(__file__).resolve().parents[1] / "config/gradle-tests/.config/gradle-tests"


class GradleTestsCommand(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "--quiet", str(self.root)], check=True)

    def report(self, module="app", task="test", contents="<testsuite/>"):
        path = self.root / module / "build/test-results" / task / "TEST-example.xml"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)

    def run_command(self, *args, cwd=None):
        return subprocess.run(
            ["bash", str(HOME / "bin/gradle-tests"), *args],
            cwd=cwd or self.root,
            env={**os.environ, "GRADLE_TESTS_HOME": str(HOME)},
            capture_output=True,
            text=True,
        )

    def test_failures_errors_custom_tasks_and_nested_directory(self):
        self.report(contents='''<testsuite>
          <testcase classname="Example" name="passes"/>
          <testcase classname="Example" name="skipped"><skipped/></testcase>
          <testcase classname="Example" name="fails"><failure/></testcase>
        </testsuite>''')
        self.report("other", "integrationTest", '''<testsuite>
          <testcase classname="Other" name="errors"><error/></testcase>
          <testcase classname="Example" name="fails"><failure/></testcase>
        </testsuite>''')
        result = self.run_command("failed", cwd=self.root / "app")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "Example.fails\nOther.errors\n")

    def test_no_failures(self):
        self.report()
        result = self.run_command("failed")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("no failing tests", result.stderr)

    def test_failure_message_and_verbose_trace(self):
        self.report(contents='''<testsuite>
          <testcase classname="Example" name="fails">
            <failure message="expected: 2&#10;actual: 1" type="AssertionError">AssertionError: expected 2, got 1
\tat Example.fails(Example.kt:42)</failure>
          </testcase>
        </testsuite>''')
        result = self.run_command("failed")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "Example.fails\n  expected: 2\n  actual: 1\n")
        verbose = self.run_command("failed", "--verbose")
        self.assertEqual(verbose.returncode, 0, verbose.stderr)
        self.assertIn("  expected: 2\n  actual: 1\n", verbose.stdout)
        self.assertIn("AssertionError: expected 2, got 1", verbose.stdout)
        self.assertIn("Example.fails(Example.kt:42)", verbose.stdout)
        self.assertEqual(self.run_command("failed", "-v").stdout, verbose.stdout)

    def test_missing_message_falls_back_to_text_or_type(self):
        self.report(contents='''<testsuite>
          <testcase classname="Example" name="fails"><error>RuntimeException: broken
\tat Example.fails(Example.kt:42)</error></testcase>
          <testcase classname="Other" name="fails"><failure type="AssertionError"/></testcase>
        </testsuite>''')
        result = self.run_command("failed")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "Example.fails\n  RuntimeException: broken\nOther.fails\n  AssertionError\n")

    def test_distinct_failure_details_are_preserved(self):
        self.report(contents='''<testsuite>
          <testcase classname="Example" name="fails"><failure message="first failure"/></testcase>
        </testsuite>''')
        self.report("other", "test", '''<testsuite>
          <testcase classname="Example" name="fails"><failure message="second failure"/></testcase>
          <testcase classname="Example" name="fails"><failure message="first failure"/></testcase>
        </testsuite>''')
        result = self.run_command("failed")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "Example.fails\n  first failure\n  second failure\n")

    def test_no_reports(self):
        result = self.run_command("failed")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no test reports", result.stderr)

    def test_malformed_report(self):
        self.report(contents="broken XML")
        result = self.run_command("failed")
        self.assertEqual(result.returncode, 1)
        self.assertIn("cannot read", result.stderr)
        self.assertNotIn("no failing tests", result.stderr)

    def test_outside_git(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_command("failed", cwd=directory)
            self.assertEqual(result.returncode, 1)
            self.assertIn(f"under {directory}", result.stderr)

    def test_help_and_unknown_command(self):
        self.assertEqual(self.run_command("--help").returncode, 0)
        self.assertEqual(self.run_command("unknown").returncode, 2)


if __name__ == "__main__":
    unittest.main()
