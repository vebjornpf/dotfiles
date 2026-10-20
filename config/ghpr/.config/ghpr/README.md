# ghpr

Supported commands:
- `ghpr this` - opens current repo PRs and locally checks out the selected PR branch when available
- `ghpr this open` - runs `gh pr list --web` for the current repo
- `ghpr this <number> open` - opens a current-repo PR in the browser
- `ghpr this <number> checkout` - locally checks out a current-repo PR
- `ghpr this <number> cp` - copies a current-repo PR URL
- `ghpr mine`
- `ghpr mine clean`
- `ghpr mine list`
- `ghpr mine status`
- `ghpr open <org/repo> <number> [branch]`
- `ghpr sync`
- `ghpr sync mine`

Help:
- `ghpr --help` shows top-level commands
- `ghpr <command> --help` shows command-specific help

Local config:
- `~/.config/local/tools.zsh`

State:
- `GHPR_STATE_DIR/mine.json` - cached payload for `ghpr mine`

Notes:
- `ghpr this` runs live against the current GitHub repo and does not store state
- Type `ghpr this ` and press Tab to fetch and select an open PR from the current repository; press Tab after the PR number to choose `open`, `checkout`, or `cp`
- Action-first forms such as `ghpr this open <number>` also work and complete PR numbers
- `cp` uses the shared clipboard helper and requires `pbcopy`, `clip.exe`, `wl-copy`, or `xclip`
- In `ghpr mine`, `Enter` switches to the selected repo's tmux session, creating a local clone first when needed
- `ghpr this` uses the PR head branch name for local checkout when available, with `pr-<number>` as fallback
