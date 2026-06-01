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
