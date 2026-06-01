# dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).
Supports Linux, macOS, and WSL.

## How it works

Each tool has its own directory under `config/`. Inside each directory, files are laid out
exactly as they should appear under `$HOME`. GNU Stow creates symlinks from `$HOME` into
the repo, so edits to the repo are immediately reflected in the live config.

Example: `config/zsh/.config/zsh/.zshrc` gets symlinked to `~/.config/zsh/.zshrc`.

## Packages

| Package | What it configures |
|---|---|
| `config/zsh/` | Zsh — `.zshenv`, `.zshrc`, and all `*.zsh` modules |
| `config/nvim/` | Neovim — `init.lua` and all Lua config |
| `config/tmux/` | tmux — `tmux.conf`, `tmux.reset.conf`, and scripts |
| `config/opencode/` | OpenCode AI assistant — config, skills, themes, and plugin |

## New machine setup

### Prerequisites

Install these before running `stow-all.sh`:

- `git`
- `stow` — `brew install stow` or `sudo apt install stow`
- `zsh`, `tmux`, `nvim` — your preferred method

### Steps

```sh
git clone https://github.com/<you>/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./stow-all.sh
```

If files already exist at the target paths (e.g. an existing `~/.zshrc`), stow will
refuse to overwrite them. Remove or back up the conflicting files first, then re-run.

### After stowing tmux

tmux plugins are managed by [TPM](https://github.com/tmux-plugins/tpm). Install it once:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

Then open tmux and press `prefix + I` to install all plugins.

### After stowing opencode

The opencode plugin needs its dependencies installed:

```sh
cd ~/.config/opencode
npm install
```

## Stowing / unstowing individual packages

```sh
cd ~/git/dotfiles/config

stow -t "$HOME" zsh          # stow a package
stow -t "$HOME" -D zsh       # unstow (remove symlinks)
stow -t "$HOME" -R zsh       # restow (remove and re-create symlinks)
```

## Adding a new config package

1. Create `config/<tool>/`
2. Place files inside mirroring their `$HOME` paths:
   - Home dotfiles: `config/<tool>/.<file>` → `~/.<file>`
   - XDG configs: `config/<tool>/.config/<tool>/...` → `~/.config/<tool>/...`
3. Add the package name to the `packages` array in `stow-all.sh`
4. Run `stow <tool>` from `config/`

## Repository structure

```
dotfiles/
├── .stowrc               # Stow defaults: --target=$HOME
├── .gitignore
├── stow-all.sh           # Bootstrap: stow all packages
├── lib/
│   └── platform.sh       # detect_platform() → macos / linux / wsl
└── config/
    ├── zsh/              # Zsh config
    ├── nvim/             # Neovim config
    ├── tmux/             # tmux config + scripts
    └── opencode/         # OpenCode AI config
```
