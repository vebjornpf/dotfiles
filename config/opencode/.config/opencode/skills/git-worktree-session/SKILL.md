---
name: git-worktree-session
description: Use when the user wants to start an isolated workspace for a new task in a git repo so that multiple agent sessions can work on the same repo in parallel without stepping on each other. Triggers include "new task", "isolated workspace", "spin up a worktree", "parallel session", or any request to begin work without disturbing the main checkout.
---

# Git Worktree Session

## Purpose
Create an isolated working directory (a git worktree) for each new task so that multiple agent sessions can operate on the same repository in parallel without conflicting checkouts, branch switches, or stashed changes.

## Use When
- User says they are starting a new task and want it isolated from current work
- User mentions running multiple sessions on the same repo in parallel
- User asks for a "fresh workspace", "clean branch", or "worktree" for a task
- User wants to avoid stashing or branch-switching in the main checkout
- User wants to check out an existing branch (local or remote) into its own isolated directory

## Do Not Use When
- The repo is not a git repo (offer plain directory or fail loudly)
- The user explicitly wants to keep working in the main checkout
- The task is trivial and a worktree would add overhead without benefit
- The repo uses submodules in ways the user has not approved for worktree use (ask first)

## Default Behavior (No Worktree)
This skill is opt-in. If the user does not ask for isolation, a worktree, or a parallel session, the agent works in the current directory on the current branch — same workspace as the user.

Rules when sharing the user's checkout:
- Never switch branches without explicit user confirmation. The user may have uncommitted work.
- Never run `git checkout`, `git switch`, `git reset`, `git stash`, or `git pull --rebase` without asking.
- Treat uncommitted changes as the user's; do not discard or stash them.
- If the task clearly needs a different branch, suggest creating a worktree instead of switching in place.

## Conventions (locked)
- **Worktree location**: `~/git/<repo-name>-<task-slug>-wk`
  - `<repo-name>` is the basename of the main repo's toplevel directory
  - `<task-slug>` is the slugified task name (lowercase, hyphenated, alphanumeric)
  - The `-wk` suffix marks it as a worktree (used by `tmux-sessionizer` and the `wt` cleanup tool)
- **Base branch**: `main` if it exists, otherwise `master`. Always `git fetch` first so the worktree starts from the latest remote tip.
- **Branch name**: same as `<repo-name>-<task-slug>` (without the `-wk` suffix). No other prefixes.
- **Auto setup**: copy `.env` and `.env.local` from the main worktree if they exist. Do NOT auto-install dependencies — let the user decide.

## Rules
- Never create a worktree without confirming the repo root and base branch first
- Never overwrite an existing worktree path; if it exists, stop and ask
- Never delete worktrees or branches without explicit user confirmation
- Slugify task names deterministically: lowercase, replace non-alphanumeric runs with `-`, trim leading/trailing `-`
- After creation, `cd` into the new worktree (or instruct the user to) before doing further work
- Show the user the resulting path and branch name when done

## Steps

### Creating a worktree
1. Verify current directory (or a user-specified path) is inside a git repo:
   `git rev-parse --show-toplevel`
2. Determine repo name from the toplevel basename.
3. Determine base branch: prefer `main`, fall back to `master`. Confirm it exists locally or on `origin`.
4. `git fetch origin <base-branch>` to ensure freshness.
5. Slugify the task name into `<task-slug>`.
6. Compute target path: `~/worktrees/<repo-name>/<task-slug>`. If it already exists, stop and ask.
7. Create the worktree and branch in one shot:
   ```sh
   git worktree add -b <repo-name>-<task-slug> ~/git/<repo-name>-<task-slug>-wk origin/<base-branch>
   ```
8. Copy env files if present in the main worktree:
   - `.env` -> new worktree
   - `.env.local` -> new worktree
   (Skip silently if not present. Never overwrite existing files in target.)
9. Report the new path and branch to the user. Suggest `cd` into it.

### Listing worktrees
- `git worktree list` from anywhere inside the repo.

### Checking out an existing branch in a new worktree
Use when user wants to work on a branch that already exists (locally or on remote) rather than creating a new one.

Triggers: "check out branch X in a worktree", "worktree for existing branch", "pull branch Y into a fresh dir".

Steps:
1. Verify repo root as usual.
2. Determine repo name and target path. Use the branch name slugified as `<task-slug>` unless user gives a different name. Path: `~/git/<repo-name>-<task-slug>-wk`.
3. `git fetch origin` to ensure remote refs current.
4. Determine branch source:
   - Local branch exists → use it directly.
   - Only remote (`origin/<branch>`) → use remote ref; git creates local tracking branch automatically.
5. Check branch is not already checked out in another worktree: `git worktree list`. If it is, stop and inform user.
6. Create the worktree without `-b`:
   ```sh
   # local branch exists
   git worktree add ~/worktrees/<repo-name>/<task-slug> <branch>

   # only on remote
   git worktree add ~/worktrees/<repo-name>/<task-slug> origin/<branch>
   ```
7. Copy `.env` / `.env.local` from main worktree if present (same as new-branch flow).
8. Report path + branch.

Note: PR checkout (`gh pr checkout <num>`) is a remote-mutation-adjacent flow. Agent does NOT run `gh` commands. If user wants PR checked out, instruct them to either:
- Run `gh pr checkout <num>` themselves in the new worktree, or
- Provide the branch name so the skill can use Mode B above.

### Committing work in a worktree
A worktree behaves as a normal git checkout. No special flow.
- Agent commits only when the user explicitly asks (existing commit policy still applies).
- **Agent must NEVER push.** No `git push`, no `git push -u`, no `git push origin --delete`.
- **Agent must NEVER create or modify PRs.** No `gh pr create`, `gh pr edit`, or equivalent.
- If the user asks to "commit and push", agent commits and then prints the exact `git push` command for the user to run manually.

### Cleaning up worktrees
Use the `wt` command (available in the user's shell) for interactive cleanup. It opens an fzf picker showing all `~/git/*-wk` directories with git status. `alt-d` deletes the selected worktree after safety checks. Direct the user to run `wt` rather than manually running `git worktree remove`.

### Removing a worktree
Pre-flight checks (run in order, stop on first failure):
1. Dirty working tree: `git -C <path> status --porcelain`. Non-empty → stop, ask user how to proceed (commit, discard, or abort).
2. Unpushed commits: `git -C <path> log @{u}.. 2>/dev/null`. Non-empty → warn loudly. Since the agent cannot push, instruct the user to push manually before removal, or get explicit confirmation that losing the commits is acceptable.
3. PR state: agent does NOT auto-check via `gh`. Remind user to verify PR status themselves if relevant.

Removal:
1. `git worktree remove <path>`. Do not pass `--force` unless the user explicitly authorizes it.
2. Branch disposition — ask the user which:
   - Leave the branch (default, safest)
   - `git branch -d <task-slug>` (safe delete, only works if merged into base)
   - `git branch -D <task-slug>` (force delete, only on explicit confirmation)
3. `git worktree prune` to clean up any stale admin entries.
4. Remote branch cleanup: agent does NOT run `git push origin --delete <task-slug>`. If user wants the remote branch gone, print the command for them to run manually.

## Agent Boundaries
Hard rules — agent must never run any of:
- `git push` (any form, including `-u`, `--force`, `--delete`)
- `gh pr create`, `gh pr edit`, `gh pr merge`, `gh pr close`
- Any command that mutates a remote branch or PR

When such an action is needed, surface the exact command for the user to run themselves.

## Verification
- After creation, run `git worktree list` and confirm the new entry is present.
- Confirm the new directory exists and is on the new branch: `git -C <path> rev-parse --abbrev-ref HEAD`.
- Confirm env files were copied if they existed in the source.

## Edge Cases
- **Uncommitted changes in main worktree**: do not block; worktrees are independent. Just inform the user.
- **Branch name already exists**: stop and ask whether to reuse it (drop `-b` and check it out) or pick a new slug.
- **No `main` or `master`**: ask the user for the base branch.
- **Detached HEAD in main checkout**: still fine; we branch from `origin/<base>`, not from HEAD.
- **Submodules**: warn the user; `git worktree add` does not initialize submodules by default.
- **Bare repos / non-standard layouts**: ask before proceeding.
- **Worktree directory deleted manually**: run `git worktree prune` to clean up admin refs.
- **Branch already checked out elsewhere**: git will block removal/checkout; inform user which worktree holds it.
- **Locked worktree** (`git worktree lock`): unlock first with `git worktree unlock <path>` before removal.

## Maintenance
- Last reviewed: 2026-04-27
- Status: active
- Sources of truth: `git help worktree`, user's stated conventions in this skill
