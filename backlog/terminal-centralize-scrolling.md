# terminal: centralize scrolling behavior across OpenCode, tmux, fzf, and neovim

## Context
The terminal stack currently has multiple unrelated scrolling models, which makes keyboard navigation inconsistent.

## Findings
- Scrolling is currently split across tool-specific defaults
- The main inconsistency is keyboard scrolling and paging, not mouse support
- Most of the current behavior comes from upstream defaults rather than repo-local remaps

## Current behavior

### OpenCode
- Default behavior: `Ctrl+Alt+U` and `Ctrl+Alt+D` scroll the transcript up and down
- Repo context: no local OpenCode scroll overrides were found in `config/opencode/.config/opencode/opencode.jsonc` or `config/opencode/.config/opencode/tui.json`

### Terminal / zsh
- Default behavior: `Shift+PageUp` and `Shift+PageDown` scroll terminal history up and down
- Repo context: no zsh scroll remaps were found in this repo

### tmux
- Default behavior: mouse wheel scrolls pane history
- Keyboard behavior: scrollback uses tmux copy-mode
- Repo context: `config/tmux/.config/tmux/tmux.conf` enables `mouse on`, `mode-keys vi`, and large scrollback history; `config/tmux/.config/tmux/tmux.reset.conf` only adds `v` for selection in copy-mode

### fzf
- Default behavior: `Shift+Up` and `Shift+Down` scroll the preview window
- Repo context: local `fzf` usage adds layout and preview options, but no custom preview-scroll bindings were found

### Neovim
- Default behavior: editor scrolling is Neovim-native
- Mouse behavior: mouse scrolling works because `config/nvim/.config/nvim/lua/config/options.lua` sets `vim.o.mouse = 'a'`
- Repo context: the same file sets `vim.o.scrolloff = 10`; no repo-local scroll key remaps were found

## Goal
Make scrolling feel more coherent across the terminal stack without breaking each tool's native strengths.

## Questions
- Which keyboard shortcuts should be treated as the preferred cross-tool scroll keys?
- Which layer should own `PageUp` and `PageDown`: terminal, tmux, or inner app?
- Where should consistency stop because the tool semantics differ too much?

## Proposed approach
1. Define one preferred keyboard scheme for conversation/UI scrolling, preview scrolling, pane scrollback, and editor scrolling
2. Map that scheme in OpenCode, tmux, and `fzf` where practical
3. Keep explicit exceptions documented where behavior cannot be unified, such as tmux scrollback using copy-mode
4. Add short docs for the chosen conventions so they are discoverable later

## Notes
- Mouse scrolling should probably remain enabled even if keyboard scrolling is standardized
- Avoid relying on `PageUp` and `PageDown` alone unless the terminal is configured to pass them through consistently
