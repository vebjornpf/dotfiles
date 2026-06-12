# AGENTS.md — dotfiles repo

This repo manages personal configuration files using GNU Stow.
Each tool has a package under `config/` that gets symlinked into `$HOME`.

## Stow layout rule

Every file must live inside the correct XDG subtree or stow will
symlink it to the wrong place:

    config/<tool>/.config/<tool>/   →   ~/.config/<tool>/
    config/<tool>/.<file>           →   ~/.<file>

Never place config files directly under `config/<tool>/` — they will
stow to `~/` instead of `~/.config/<tool>/`.

## Deployment

    ./stow-all.sh                            # stow all packages
    cd config && stow -t "$HOME" -R <pkg>    # restow one package

## Adding a new package

1. Create `config/<tool>/.config/<tool>/` (or `config/<tool>/.<file>`)
2. Add the package name to the `packages` array in `stow-all.sh`
3. Run `stow -t "$HOME" <tool>` from `config/`

## Feature tool convention

For command-based tools, prefer feature-centric layout:

- `config/<tool>/.config/<tool>/bin/` — public commands
- `config/<tool>/.config/<tool>/lib/` — internal reusable logic
- `config/<tool>/.config/<tool>/zsh/` — PATH, env, completion

Rules:

- Use one main command with subcommands
- Keep `bin/` thin; put logic in `lib/`
- Export `<TOOL>_HOME` and `<TOOL>_STATE_DIR` from feature `zsh/`
- Cache state data and derive lightweight files for completions, lists, and pickers
- Keep fetch, render, and action logic separate
- When changing a tool's commands, env vars, setup, dependencies, or behavior, evaluate whether that tool's README should be added or updated
- Keep tool READMEs minimal and focused on supported features, required local config, and usage

## Private local config

Some commands need machine-local or personal values that should not live in
tracked dotfiles, such as board URLs, account IDs, tokens, or employer-specific
paths.

Rules:

- Do not hardcode personal or machine-local values in tracked command code
- Prefer reading required values from environment variables
- For zsh-backed tools, source an optional local file from `~/.config/local/<tool>.zsh`
- Document required local variables in the tracked `zsh/` file and command help text
- Fail with a clear error when a required local variable is unset

Reference: `jira` package.

## Path consistency rule

Scripts reference each other and are called from tmux.conf and zsh
modules. When a script moves, update every caller:

- `config/tmux/.config/tmux/tmux.conf`
- `config/zsh/.config/zsh/*.zsh`
- Other scripts in `config/tmux/.config/tmux/scripts/`

## What not to commit

- `config/tmux/.config/tmux/plugins/` — managed by TPM at runtime
- `*.log`, `.zcompdump`, `lazy-lock.json` — generated files
- `node_modules/` — run `npm install` in `~/.config/opencode/` after stowing
