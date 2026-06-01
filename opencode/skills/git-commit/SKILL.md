---
name: git-commit
description: Use when the user wants to create a branch, apply changes, and commit them. Triggers on phrases like "create a branch and commit", "commit these changes", "put this on a branch", "branch and commit".
---

# Git Commit Skill

## Purpose
Create a new branch, apply changes, stage the intended files, and commit with a conventional commit message. Never push.

## Use When
- The user asks to commit changes to a new branch
- The user says "create a branch and commit", "put this in a branch", "commit these changes", or similar

## Do Not Use When
- The user explicitly wants to commit to the current branch
- The user asks to push or create a PR (stop at commit only)

## Rules
- Never push
- Never create a PR
- Never commit to main/master directly
- Only stage files relevant to the change — never `git add .` blindly
- Use conventional commit format: `type(scope): short description` with a body explaining the why
- Derive branch name from the change type and a short description: `fix/short-description`, `feat/short-description`, `chore/short-description`
- Check git status before and after staging to confirm only intended files are included
- If the repo has uncommitted changes unrelated to the task, leave them unstaged

## Steps
1. Run `git status` to understand current state
2. Confirm the base branch (usually `main` or `master`)
3. Create and checkout a new branch: `git checkout -b <type>/<short-description>`
4. Apply the file changes
5. Draft the commit message and present it to the user for approval — do not commit until the user confirms
6. Stage only the intended files: `git add <specific files>`
7. Run `git status` again to verify what is staged
8. Commit with the agreed conventional commit message
9. Confirm the commit with `git log --oneline -3`

## Commit Message Format

**Simple** — use when the change is small, obvious, or self-contained:
```
type(scope): short summary
```

**Detailed** — use when the change is non-trivial, fixes a bug with a specific cause, or has important context:
```
type(scope): short summary

Longer description explaining:
- What was wrong or missing before
- What was changed and why
- Any caveats or follow-ups
```

When drafting the message, propose the appropriate format and let the user decide if they want more or less detail before committing.

Types: `fix`, `feat`, `chore`, `docs`, `refactor`, `test`

## Amending Commits

When a follow-up change is made after an initial commit on the same branch:
- **Always ask the user** whether to amend the existing commit or create a new one
- Never amend silently
- Suggested prompt: "Amend the previous commit or create a new one?"

## Verification
- `git log --oneline -3` shows the new commit on the new branch
- `git status` shows a clean working tree (or only unrelated unstaged changes)
- `git diff HEAD~1` confirms only intended changes are in the commit

## Maintenance
- Last reviewed: 2026-05-27
- Status: active
