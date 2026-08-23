# herdr

Herdr is configured as a stow-managed package with a fuzzy project workspace
picker.

## Usage

- `Ctrl-b w` - switch between workspaces
- `Ctrl-b g` - open Herdr's session navigator
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
