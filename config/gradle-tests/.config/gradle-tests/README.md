# gradle-tests

Requires Python 3. No local configuration needed.

```sh
gradle-tests failed
gradle-tests failed --verbose
```

- Prints failing tests as `ClassName.testName` with indented failure messages, sorted and deduplicated. Distinct failures for the same test are preserved.
- `--verbose` (or `-v`) also prints full failure text and stack traces from the XML report. Without a message attribute, the first line of failure text is used as the summary.
- Reads `build/test-results/<task>/TEST-*.xml` across modules, including custom test tasks.
- Searches from the Git repository root (even when called from a subdirectory), or the current directory outside Git.
- Does not run Gradle or change reports. Results reflect existing reports, which may be stale; Gradle `clean` removes old results.
- Reports no failures separately from missing or unreadable reports. Exit status is 0 when reports were read successfully (even with failing tests), 1 for missing/unreadable reports.
- `gradle-tests --help` shows usage. Zsh integration adds PATH and subcommand completion.

`GRADLE_TESTS_HOME` locates the installed package. `GRADLE_TESTS_STATE_DIR` is reserved for future state; this command does not cache results.
