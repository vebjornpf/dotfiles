# ghpr

Supported commands:
- `ghpr this`
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
