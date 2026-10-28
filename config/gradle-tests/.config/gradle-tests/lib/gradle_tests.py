"""Read existing Gradle JUnit XML reports without running a build."""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET


def repository_root():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        return Path.cwd()
    return Path(result.stdout.strip()) if result.returncode == 0 else Path.cwd()


def find_reports(root):
    reports = []
    for directory, children, _ in os.walk(root):
        # Inspect reports directly, without walking compiled classes or caches.
        if "build" in children:
            reports.extend((Path(directory) / "build" / "test-results").glob("*/TEST-*.xml"))
        children[:] = [
            child for child in children
            if child not in {"build", ".git", ".gradle", "node_modules", ".venv"}
        ]
    return sorted(reports)


def failing_tests(report):
    for test in ET.parse(report).iter("testcase"):
        details = []
        for failure in test:
            if failure.tag not in {"failure", "error"}:
                continue
            trace = (failure.text or "").strip()
            message = (failure.get("message") or "").strip()
            if not message:
                message = trace.splitlines()[0] if trace else failure.get("type", "")
            details.append((message, trace))
        if details:
            name = f"{test.get('classname', '<unknown class>')}.{test.get('name', '<unknown test>')}"
            yield name, details


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="gradle-tests",
        description="Read existing Gradle test reports; never runs tests.",
        epilog="Searches the Git repo root, or the current directory outside Git. "
        "Requires Python 3. Reports may be stale; use Gradle clean to remove old results. "
        "GRADLE_TESTS_HOME overrides the installed command directory.",
    )
    parser.add_argument("command", choices=["failed"], help="print failing tests and failure messages")
    parser.add_argument("-v", "--verbose", action="store_true", help="include full failure text and stack traces")
    args = parser.parse_args(argv)

    root = repository_root()
    reports = find_reports(root)
    if not reports:
        print(f"gradle-tests: no test reports found under {root}; run Gradle tests first", file=sys.stderr)
        return 1

    failures = {}
    errors = False
    for report in reports:
        try:
            for name, details in failing_tests(report):
                failures.setdefault(name, set()).update(details)
        except (OSError, ET.ParseError) as error:
            print(f"gradle-tests: cannot read {report}: {error}", file=sys.stderr)
            errors = True

    for name, details in sorted(failures.items()):
        print(name)
        for message, trace in sorted(details):
            if message:
                for line in message.splitlines():
                    print(f"  {line}")
            if args.verbose and trace and trace != message:
                for line in trace.splitlines():
                    print(f"  {line}")
    if not failures and not errors:
        print("gradle-tests: no failing tests in existing reports", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
