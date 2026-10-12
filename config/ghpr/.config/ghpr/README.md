# ghpr

Supported commands:
- `ghpr this` - opens current repo PRs and locally checks out the selected PR branch when available
- `ghpr this open <number>` - opens a current-repo PR in the browser
- `ghpr this checkout <number>` - locally checks out a current-repo PR
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
- `ghpr this open` and `ghpr this checkout` tab completion lists open PRs from the current repository
- In `ghpr mine`, `Enter` switches to the selected repo's tmux session, creating a local clone first when needed
- `ghpr this` uses the PR head branch name for local checkout when available, with `pr-<number>` as fallback
