# Testing Strategy

## Goal

Define a practical, repeatable testing approach for the command-based tools in
this repository, including help output, shell completion, setup, state, and
failure behavior.

## Questions to Resolve

- Which commands need automated unit tests versus shell-level integration tests?
- How should command output, exit codes, and required environment variables be
  verified?
- How should zsh and bash completion be tested for valid, incomplete, and
  invalid input?
- How should `--help`, missing dependencies, missing configuration, and empty
  state be covered?
- Which tests can run without modifying the real home directory or personal
  state?
- Should a small fixture-based test harness be shared by all tools?

## Proposed Scope

- Establish a test runner and conventions for shell scripts and libraries.
- Add isolated fixtures for XDG directories, state files, and local config.
- Test the public command contract: subcommands, options, stdout, stderr, and
  exit status.
- Test help output and completion scripts as user-facing interfaces.
- Cover happy paths, malformed input, missing configuration, missing tools, and
  network/API failures where applicable.
- Add a lightweight manual smoke-test checklist for interactive behavior that
  is difficult to automate.
- Document how to run the full suite and targeted tests locally.
