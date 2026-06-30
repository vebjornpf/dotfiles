# Sonar Terminal Workflow

## Goal

Figure out the best terminal-first workflow for working with SonarQube and SonarLint.

## Questions

- What is the normal way to inspect SonarQube project state from the terminal?
- Which SonarQube API endpoints are most useful for day-to-day checks?
- Are there maintained CLI or TUI wrappers worth using instead of raw `curl` + `jq`?
- What role, if any, can SonarLint play in a terminal or Neovim workflow?
- How should Gradle-based projects combine `./gradlew sonar` with terminal status checks?

## Notes

- Current understanding: `./gradlew sonar` submits analysis; SonarQube Web API is the standard way to read status and metrics from terminal scripts.
- SonarLint appears editor-focused rather than a general terminal tool.

## Possible Output

- Short recommended workflow for local terminal use
- Reusable commands or shell functions for common SonarQube checks
- Optional Neovim integration ideas for showing SonarQube status or issues
