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

### Core bootstrap

Use the core bootstrap first. It installs missing core dependencies, sets up shell and tmux support repos, stows the core packages, and verifies the result.

```sh
git clone https://github.com/<you>/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./bootstrap.sh core
```

Core bootstrap covers:

- system packages: `git`, `stow`, `zsh`, `tmux`, `neovim`, `fzf`, `ripgrep`, `bat`
- shell support: `oh-my-zsh` with the repo's `catppuccin` theme, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- tmux support: `TPM`
- stowed packages: `zsh`, `tmux`, `nvim`

Helpful subcommands:

```sh
./bootstrap.sh check core
./bootstrap.sh install core
./bootstrap.sh link core
./bootstrap.sh verify core
```

### Tools bootstrap

Use the tools bootstrap after core. It installs missing workflow dependencies, stows the tool packages, installs `opencode` npm dependencies, and verifies local tool config.

```sh
./bootstrap.sh tools
```

Tools bootstrap covers:

- system packages: `gh`, `jq`, `curl`, `acli`, `node`, `npm`
- stowed packages: `jira`, `ghpr`, `ghrepo`, `sonar`, `web`, `opencode`
- shared local config: `~/.config/local/tools.zsh`
- post-link install: `npm install` in `~/.config/opencode`

Helpful subcommands:

```sh
./bootstrap.sh check tools
./bootstrap.sh install tools
./bootstrap.sh link tools
./bootstrap.sh verify tools
```

Notes:

- `./bootstrap.sh core` supports Homebrew and `apt-get`
- it may prompt when setting your default shell to `zsh`
- on Debian/Ubuntu, the bootstrap creates a `~/.local/bin/bat` wrapper if the system package only provides `batcat`
- the `zsh` package provides a minimal `~/.local/bin/xdg-open` shim that uses `explorer.exe` on WSL and `open` on macOS
- tmux still needs `prefix + I` once after bootstrap to install plugins
- configure your terminal to use a Nerd Font for tmux icons
- `./bootstrap.sh tools` expects your local tool variables in `~/.config/local/tools.zsh`
- `./bootstrap.sh tools` does not log in to external services for you; check `gh auth status` and your `acli` auth separately

### Manual / fallback setup

If you do not want to use the bootstrap yet, the manual flow is still available.

Tool-local variables live in one shared file:

- `~/.config/local/tools.zsh`

Put `jira`, `sonar`, `ghrepo`, `ghpr`, and `web` local variables there.

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

This tmux config uses Nerd Font icons in the status bar. Your terminal must be
configured to use a Nerd Font, or the icons will show up as `?`.

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

For command-based tools, prefer feature-centric layout under `config/<tool>/.config/<tool>/`:

- `bin/` — public commands
- `lib/` — internal reusable logic
- `zsh/` — PATH, env, completion

Reference: `jira` package.
