# ghpr

Supported commands:
- `ghpr this` - opens current repo PRs and checks out the selected PR branch locally when available
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
- `~/.config/local/ghpr.zsh`

State:
- `GHPR_STATE_DIR/mine.json` - cached payload for `ghpr mine`

Notes:
- `ghpr this` runs live against the current GitHub repo and does not store state
- `ghpr this` and `ghpr mine` use the PR head branch name for local checkout when available, with `pr-<number>` as fallback
