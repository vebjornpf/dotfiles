# Neovim

## Overview
- This is a Lua-first Neovim setup managed by `lazy.nvim`.
- Plugin specs live in `lua/plugins/`.
- Shared behavior and keymaps live in `lua/features/` and `lua/config/`.
- The setup favors built-in Neovim features plus a small plugin set for search, LSP, git, formatting, and UI.

## Layout
- `init.lua`: startup entrypoint.
- `lua/config/options.lua`: core editor options.
- `lua/config/keymaps.lua`: base keymaps and diagnostic behavior.
- `lua/config/autocmds.lua`: autocmds such as yank highlight and Kotlin package boilerplate.
- `lua/config/lazy.lua`: bootstraps and configures `lazy.nvim`.
- `lua/features/`: repo-level behavior split by concern.
- `lua/plugins/`: one plugin spec file per feature or plugin group.
- `lazy-lock.json`: pinned plugin versions.

## Configuration Model
- `lua/config/` owns base Neovim behavior: options, generic keymaps, autocmds, and plugin-manager bootstrap.
- `lua/features/` owns repo-specific workflows that may compose multiple plugins or built-in APIs.
- `lua/plugins/` owns plugin registration, lazy-loading triggers, plugin-local options, and plugin dependencies.
- In practice: plugin import and plugin-local setup live in `lua/plugins/`, while user workflow glue lives in `lua/features/`.
- Example: `telescope.lua` loads Telescope and extensions, while `features/search.lua` defines the pickers and search keymaps you actually use.

## Startup Flow
1. `init.lua` sets leader keys and `have_nerd_font`.
2. Core options, keymaps, and autocmds load from `lua/config/`.
3. `require('features').setup()` loads repo behavior, currently UI helpers.
4. `lua/config/lazy.lua` bootstraps `lazy.nvim` and imports all files under `lua/plugins/`.
5. Plugins load on startup, events, commands, filetypes, or keys depending on each spec.

## Features
- UI: `features/ui.lua` adds the smart `nvim-tree` toggle and which-key group labels.
- Search: `features/search.lua` defines Telescope pickers for files, grep, buffers, commands, and Neovim config files.
- LSP: `features/lsp.lua` adds buffer-local LSP actions, Telescope-powered symbol/navigation pickers, and inlay-hint toggling.
- Git: `features/git.lua` wires gitsigns hunk actions and diffview shortcuts.

## Main Shortcuts

### Core
- `<Esc>`: clear search highlight.
- `<leader>q`: open buffer diagnostics in the location list.
- `<leader>op`: open the current file in VS Code.
- `<Esc><Esc>` in terminal mode: leave terminal-insert mode.
- `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`: move between windows.

### File Browsing
- `<leader>e`: smart `nvim-tree` toggle or focus current file in the tree.
- `<leader>fe`: reveal the current file in `nvim-tree`.
- In `nvim-tree`: `i` opens a file in a vertical split, `s` in a horizontal split, and `t` in a new tab.

### Search And Picking
- `<leader>sf`: find files.
- `<leader>sF`: find all files, including hidden and ignored.
- `<leader>st`: find files under `./tmp`.
- `<leader>sg`: live grep.
- `<leader>sG`: live grep including hidden files.
- `<leader>sT`: live grep under `./tmp`.
- `<leader>sw`: grep the current word or selection.
- `<leader>ss`: list Telescope pickers.
- `<leader>sd`: search diagnostics.
- `<leader>sr`: resume the last Telescope picker.
- `<leader>s.`: recent files.
- `<leader>sc`: commands.
- `<leader><leader>`: buffers.
- `<leader>/`: fuzzy search inside the current buffer.
- `<leader>s/`: live grep in open files.
- `<leader>sn`: search Neovim config files.

### LSP
- `grn`: rename symbol.
- `gra`: code action.
- `grD`: declaration.
- `grd`: definition via Telescope.
- `grr`: references via Telescope.
- `gri`: implementations via Telescope.
- `grt`: type definitions via Telescope.
- `gO`: document symbols.
- `gW`: workspace symbols.
- `<leader>th`: toggle inlay hints when the server supports them.

### Git
- `<leader>gs`: Telescope git status.
- `<leader>gd`: open Diffview for current local changes.
- `<leader>gb`: open Diffview for `main...HEAD` branch review.
- `<leader>gD`: close Diffview.
- `<leader>gH`: file history in Diffview.
- `<leader>gy`: copy remote git link.
- `<leader>gO`: open remote git link.
- `<leader>hn`, `<leader>hN`: next and previous git hunk.
- `<leader>hs`: stage hunk.
- `<leader>hr`: reset hunk.
- `<leader>hS`: stage buffer.
- `<leader>hu`: undo staged hunk.
- `<leader>hR`: reset buffer.
- `<leader>hp`: preview hunk inline.
- `<leader>hb`: blame line.
- `<leader>hd`: diff current file.
- `<leader>hD`: diff against index.

### Formatting And Requests
- `<leader>f`: format the current buffer through `conform.nvim`.
- `<leader>Rs`: send HTTP request in `kulala.nvim`.
- `<leader>Ra`: send all requests in the file.
- `<leader>Rb`: open Kulala scratchpad.

### Markdown Preview
- `<leader>mps`: start Markdown preview.
- `<leader>mpr`: refresh Markdown preview.
- `<leader>mpS`: stop Markdown preview.

### Mini.nvim Mappings Used Here
- `mini.ai`: `aa` and `ii` target the next surrounding text object.
- `mini.surround`: default mappings are active, including `sa` add, `sd` delete, and `sr` replace.

## Plugins
- `blink-cmp.lua`: `blink.cmp` completion UI with `LuaSnip` snippets and LSP/path/snippet sources.
- `conform.lua`: `conform.nvim` formatter runner with `<leader>f` and formatters for shell and Kotlin files.
- `diffview.lua`: `diffview.nvim` git diff and file history views.
- `gitlinker.lua`: `gitlinker.nvim` for copying or opening remote git links from normal or visual mode.
- `gitsigns.lua`: `gitsigns.nvim` for hunk signs, staging, resets, blame, and inline previews.
- `guess-indent.lua`: `guess-indent.nvim` to detect indentation settings from the current file.
- `kulala.lua`: `kulala.nvim` for running HTTP and REST requests from `.http` or `.rest` buffers.
- `markdown-preview.lua`: `markdown-preview.nvim` with `live-server.nvim` for Markdown and Mermaid browser previews.
- `mini.lua`: `mini.nvim` modules currently used for `mini.ai`, `mini.surround`, and `mini.statusline`.
- `nvim-lint.lua`: `nvim-lint` for shell linting on enter, write, and insert leave.
- `nvim-lspconfig.lua`: `nvim-lspconfig` plus Mason tooling for LSP server setup and installation.
- `nvim-tree.lua`: `nvim-tree.lua` file explorer on the left side with git status and root syncing.
- `telescope.lua`: `telescope.nvim` plus FZF and UI-select extensions for file, grep, buffer, and LSP pickers.
- `todo-comments.lua`: `todo-comments.nvim` for highlighting and navigating TODO-style comments.
- `tokyonight.lua`: `tokyonight.nvim` colorscheme setup using `tokyonight-night`.
- `treesitter.lua`: `nvim-treesitter` parser management, highlighting, and indent support.
- `which-key.lua`: `which-key.nvim` for keymap discovery and grouped leader-key hints.

## Where To Change Things
- Change editor defaults in `lua/config/options.lua`.
- Change global keymaps in `lua/config/keymaps.lua`.
- Change autocmds in `lua/config/autocmds.lua`.
- Change Telescope behavior or search mappings in `lua/plugins/telescope.lua` and `lua/features/search.lua`.
- Change tree behavior in `lua/plugins/nvim-tree.lua` and `lua/features/ui.lua`.
- Change LSP server setup in `lua/plugins/nvim-lspconfig.lua` and LSP mappings in `lua/features/lsp.lua`.
- Change git keymaps in `lua/features/git.lua`.

## Notes
- `have_nerd_font` is currently `false`, so icon-heavy plugin features stay disabled.
- Clipboard integration is configured for WSL via `clip.exe` and `powershell.exe`.
- The file tree is `nvim-tree`; `mini.nvim` is used for text objects, surround editing, and statusline, not file browsing.
