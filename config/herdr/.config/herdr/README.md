# herdr

Herdr is configured as a stow-managed package with a fuzzy project workspace
picker.

## Usage

- `Ctrl-b w` - switch between workspaces
- `Ctrl-Alt-K` / `Ctrl-Alt-J` - move to the previous or next workspace
- `Ctrl-Alt-H` / `Ctrl-Alt-L` - move to the previous or next tab
- `Ctrl-Alt-Up` / `Ctrl-Alt-Down` - move to the previous or next agent
- `Ctrl-Shift-Alt-S` - show status for all agents
- `Ctrl-b g` - open Herdr's session navigator
- `Ctrl-b t` - fuzzy-pick a tab in the current workspace (searches pane titles too)
- `Ctrl-b Shift-o` - fuzzy-pick a project and focus or create its workspace

New workspaces created through the project picker have their initial tab named
`terminal`.

The picker scans `$HOME/git` and immediate child directories of `$HOME`, while
excluding directories ending in `-wk` because those are managed as worktrees.
Override the scan roots with a colon-separated `HERDR_PROJECT_ROOTS` value.

Repositories under `~/git/fyk` are shown individually as `fyk/<repo>`. The
parent folder is also available as `fyk` when you want a workspace covering the
whole group. New Fyk workspaces receive `FYK_REPO=1`, `FYK_ROOT`, and
`FYK_REPO_NAME` in their shell environment so agents can identify the
repository group. The parent workspace uses `FYK_REPO_NAME=all`. Override the
group root with `HERDR_FYK_ROOT`.

Herdr detects supported agents such as OpenCode, Claude, Codex, and Pi. Install
the OpenCode integration once if needed:

```sh
herdr integration install opencode
```

The package is deployed by `./stow-all.sh`.

The picker requires `fzf` and `jq` in addition to the Herdr binary.

## Worktrees

The Zsh `wt` command manages worktrees under `~/.herdr/worktrees/<repo>/`:

- `wt` / `wt list` — list managed worktrees and their Git status.
- `wt branch [branch]` — pick a branch in the current repository, local branches first,
  then remote branches. Remote branches use the locally fetched refs and create
  a same-named local tracking branch. Run `git fetch` first to refresh the list.
- `wt pr [number]` — pick from up to 200 open PRs in the current repository, showing
  number, title, author, and branch. Creates `pr-<number>-<branch>` worktrees with
  a separate `pr-<number>` local branch, including for fork PRs.
- `wt create <name>` — create a new branch/worktree from the current branch.
- `wt cd <worktree-path>` — open an existing managed worktree.
- `wt remove [worktree-path]` — remove a clean worktree after confirmation;
  opens a picker when no path is supplied.

`wt branch` and `wt pr` run inside Herdr and create or focus a worktree workspace.
Supply a branch or PR number to open it directly. Tab after `wt branch ` suggests
local branches first, then remote branches (such as `origin/feature`); Tab after
`wt pr ` suggests open PR numbers with titles, authors, and branches.
Existing checkouts are reused without updating their files. Branch names with
slashes use a flattened directory name; occupied paths are rejected. A remote
branch whose local name already exists must match that local branch's upstream.

Requires `git`, `herdr`, and `fzf`; PR picking also requires `jq` and an
authenticated `gh` with support for `gh pr checkout --worktree`.
