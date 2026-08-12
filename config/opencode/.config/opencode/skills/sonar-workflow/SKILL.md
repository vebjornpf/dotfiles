---
name: sonar-workflow
description: Use when working with a repo that uses the local Sonar setup based on `.sonar/project`, `sonar sync`, and generated `.sonar/issues-*.json` files.
---

# Sonar Workflow

## Purpose
- Apply the local repo Sonar convention consistently.

## Use When
- The repo has `.sonar/project`
- The user asks about Sonar issues, Sonar setup, or `sonar sync`
- The task involves maintainability, security, or reliability issues from the local Sonar tool

## Do Not Use When
- The task is about generic SonarQube setup outside this local workflow
- The repo does not use `.sonar/project`

## Rules
- Repo config lives in `.sonar/project`.
- If `.sonar/project` is missing, Sonar commands create it with `projectKey=` and `branch=main`; set the key before retrying.
- Global Sonar connection config lives in `~/.config/local/tools.zsh`.
- Generated raw payloads live in `.sonar/raw/issues-<quality>.json`.
- Generated rule metadata lives in `.sonar/raw/rules/<repository>/<rule>.json`.
- Generated normalized outputs live in `.sonar/issues-<quality>.json`.
- Do not edit generated `.sonar/raw/*.json` or `.sonar/issues-*.json` by hand.
- If fresh Sonar data is needed, run `sonar sync` from the repo root.
- For pull request counts and the Sonar dashboard URL, run `sonar pr <number>` from the repo root.
- If rule guidance is needed, run `sonar rules` after syncing issues.
- Prefer reading `.sonar/issues-*.json` over raw files.

## Steps
1. Check whether `.sonar/project` exists.
2. If it exists and fresh data is needed, run `sonar sync` or `sonar sync <quality>`.
3. If the task needs Sonar's fix guidance, run `sonar rules` and read `.sonar/raw/rules/<repository>/<rule>.json` for the matching rule key.
4. Read `.sonar/issues-<quality>.json` for issue totals, summaries, and actionable file-level issues.
5. Use `.sonar/raw/issues-<quality>.json` only for debugging export or API-shape problems.

## Verification
- Confirm `.sonar/project` exists before assuming the repo uses this workflow.
- Confirm `.sonar/issues-<quality>.json` exists before relying on cached issue data.
- If issue data looks stale or missing, refresh it with `sonar sync`.

## Maintenance
- Last reviewed: 2026-06-30
- Status: active
- Sources of truth: `config/sonar/.config/sonar/`, `config/sonar/.config/sonar/README.md`
