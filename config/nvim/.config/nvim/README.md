# Neovim

## Overview
- This is a Lua-first Neovim setup managed by `lazy.nvim`.
- Plugin specs live in `lua/plugins/`.
- Shared behavior and keymaps live in `lua/features/` and `lua/config/`.
- The setup favors built-in Neovim features plus a small plugin set for search, LSP, git, formatting, and UI.

## Layout
- `init.lua`: startup entrypoint.
- `lua/config/options.lua`: core editor options.
- `lua/config/tabline.lua`: short tab labels for filenames and Diffview.
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
3. `require('features').setup()` loads repo behavior, including UI helpers and personal shortcuts access.
4. `lua/config/lazy.lua` bootstraps `lazy.nvim` and imports all files under `lua/plugins/`.
5. Plugins load on startup, events, commands, filetypes, or keys depending on each spec.

## Features
- UI: `features/ui.lua` adds the smart `nvim-tree` toggle and which-key group labels.
- Search: `features/search.lua` defines Telescope pickers for files, grep, buffers, commands, and Neovim config files.
- Personal shortcuts: `features/shortcuts.lua` opens `neovim.md` and searches Markdown files under `~/.config/shortcuts/`, managed by the `shortcuts` Stow package. Opening notes keeps the file tree rooted in your project.
- LSP: `features/lsp.lua` adds buffer-local LSP actions, Telescope-powered symbol/navigation pickers, and inlay-hint toggling.
- Dependency sources: `features/jar_sources.lua` reads `jar://` locations returned by Kotlin LSP into read-only buffers and reuses the originating project's Kotlin LSP client for further navigation. Requires `unzip` on `PATH`.
- Git: `features/git.lua` wires gitsigns hunk actions and diffview shortcuts.
- File paths: `features/file_paths.lua` adds commands to copy the current filename or path to the system clipboard.
- Gradle: `features/gradle.lua` compiles Kotlin tests asynchronously and puts compiler errors and warnings in quickfix.
- Agent comments: `features/agent_comments.lua` collects selected code and comments, then sends a batch to a detected Herdr agent.

## Main Shortcuts

### Core
- `<Esc>`: clear search highlight.
- `<leader>q`: open buffer diagnostics in the location list.
- `<leader>op`: open the current file in Firefox (Windows Firefox from WSL), with `xdg-open`, macOS `open`, and WSL Windows Explorer as fallbacks. PDF `<leader>pv` remains the dedicated Zathura/viewer shortcut.
- `<leader>pv` in a PDF buffer: open the PDF in the first available viewer (`zathura`, `sioyek`, `evince`, `okular`, or `xdg-open`).
- `<Esc><Esc>` in terminal mode: leave terminal-insert mode.
- `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`: move between windows.
- `<leader>wt`: move the current window to an existing tab, prompting for its tab number.
- Window headers, tab labels, and the statusline show filenames instead of paths; modified files have a marker. Diffview panels and tabs show `Diffview`.

### File Browsing
- `<leader>e`: smart `nvim-tree` toggle or focus current file in the tree.
- `<leader>fe`: reveal the current file in `nvim-tree`.
- In `nvim-tree`: `i` opens a file in a vertical split, `s` in a horizontal split, and `t` in a new tab.
- In `nvim-tree`: `gh` opens a horizontal split, `gv` opens a vertical split; `<C-x>`, `<C-v>`, and `<C-t>` open a horizontal split, vertical split, and new tab.
- In `nvim-tree`: `O` opens the selected file with the platform system association.
- In `nvim-tree`: `E` expands folders, `f` starts a filename filter, and `F` clears it. While filtering, folders without a matching name or loaded matching descendants are hidden.

### Copy File Paths
- `:CopyFileName`: copy the current filename, including its extension.
- `:CopyRelativePath`: copy the path relative to the current file's Git repository root; outside Git, use the working directory as the base.
- `:CopyAbsolutePath`: copy the full absolute path of the current file.
- These commands use the system clipboard and require a named, regular file buffer (including new, unsaved files).
- In `nvim-tree`, use `y` for the selected filename, `Y` for the path relative to the tree root, and `gy` for the absolute path.

### Personal Shortcuts
- `<leader>oc`: open personal Neovim notes (`shortcuts/neovim.md`).
- `<leader>os`: search text across all shortcut Markdown files with Telescope.
- Notes are ordinary editable Markdown files; save with `:w`. Currently only `neovim.md` is included.

### Search And Picking
- In Telescope file pickers, `<CR>` opens the selected file in the current window; `<C-t>` opens it in a new tab (`<C-v>` in a vertical split, `<C-x>` in a horizontal split).
- In Telescope normal mode (`<Esc>` from the search prompt), `gh` opens a horizontal split and `gv` opens a vertical split.
- `<leader>sf`: find files including hidden files, respecting ignore rules and excluding `.git/`.
- `<leader>sF`: find all files, including hidden and ignored.
- `<leader>st`: find files under `./tmp`.
- `<leader>sg`: live grep including hidden files, respecting ignore rules and excluding `.git/`.
- `<leader>sG`: live grep including hidden files, respecting ignore rules without the explicit `.git/` exclusion.
- Hidden files such as `.env` are included unless ignored; build output is excluded when covered by ignore rules.
- `<leader>sT`: live grep under `./tmp`.
- `<leader>sw`: grep the current word or selection.
- `<leader>ss`: list Telescope pickers.
- `<leader>sd`: search diagnostics.
- `<leader>sm`: search buffers with unsaved changes, including unnamed buffers; preview current in-memory contents and press `<CR>` to open.
- `<leader>sr`: resume the last Telescope picker.
- `<leader>s.`: recent files.
- `<leader>sc`: commands.
- `<leader><leader>`: buffers.
- `<leader>/`: fuzzy search inside the current buffer in a 98%-wide, 95%-tall picker, with line-numbered matches on the left and surrounding code preview on the right.
- `<leader>s/`: live grep in open files.
- `<leader>sn`: search Neovim config files.

### LSP
- `:DiagnosticsToggle`: hide or show only yellow warnings (signs, underlines, inline text, and diagnostic floats) in all buffers for the current session. Errors, information, and hints keep their existing display settings. Warnings remain available in diagnostic lists; LSP servers keep running. Restarting Neovim restores the default.
- `:LspClients`: list LSP server names and client IDs attached to the current buffer, or report that none are attached.
- `grn`: rename symbol.
- `gra`: code action.
- `grD`: declaration.
- `grd`: definition via Telescope.
- `grr`: references via Telescope.
- `gri`: implementations via Telescope.
- `grt`: type definitions via Telescope.
- Navigation into dependencies supports source files inside local JARs (`jar://...jar!/path/to/File.kt`). These buffers are read-only; the source JAR must exist locally and `unzip` must be installed.
- Kotlin JAR buffers reuse the Kotlin LSP client from the buffer you navigated from, enabling further LSP navigation without starting another server. Directly opened JAR sources attach automatically only when exactly one Kotlin LSP client is running. Use `:LspClients` to check attachment; symbol resolution still depends on the server's imported project and indexed dependencies.
- `gO`: document symbols.
- YAML files use `yamlls` for validation, completion, hover, and document symbols; use `gO` to find and jump to keys or sections. Mason installs the server automatically.
- `gW`: workspace symbols.
- `<leader>th`: toggle inlay hints when the server supports them.

### Agent Comments
- `<leader>a`: which-key group labeled **Agent**, available in normal and visual mode.
- Select code visually, then `<leader>ac`: enter a one-line comment. The selection, file path, and original line range append to a Markdown queue; source files are untouched.
- Each comment gets a stable ID (`C1`, `C2`, etc.) in its heading. Existing unnumbered entries receive IDs on open/add/send. Keep IDs and the `next-comment-id` metadata intact when editing: reordering/deleting comments does not renumber or reuse IDs. Flushing starts a fresh batch at `C1`.
- Sending appends reply instructions asking for a separate answer under each matching ID/path heading, with the original question, a direct answer, changes/verification where applicable, and explicit decisions needed. Questions are not treated as automatic change requests. Instructions are included in sent archives, not added to the queue. Reference follow-ups by ID, e.g. "For C2, use five minutes."
- `<leader>aq`: open the queue to review, edit, or remove entries. Save edits with `:w` before adding or sending comments.
- `<leader>as`: pick a detected agent in the current Herdr workspace to submit immediately, without a confirmation dialog. The message asks the agent to address the collected comments, including when already working. Blocked agents are rejected. Sending never clears the queue; sending again resends all its contents.
- The agent picker uses 98% width and 95% height, with a large right-hand preview showing the title, status, workspace/tab/pane, directory, and current terminal view of the selected agent. This is a passive snapshot, not full conversation history; it does not scroll or interrupt the agent. Use `<C-d>` / `<C-u>` to scroll the preview, Enter to send, and Esc in normal mode to cancel. Preview behavior lives in `features/agent_picker.lua`.
- `<leader>af`: manually flush (empty) the queue after confirmation (Cancel is the default). Save queue edits first; flushing is blocked while a send is in progress. Sent archives are kept.
- The picker also offers **New OpenCode agent…**: finds the tab whose label matches the Herdr workspace name (creates it if missing), opens a new pane at the repository root, starts OpenCode, and submits once Herdr reports it ready. Requires `opencode` on PATH. Setup does not switch focus; failures retain the queue and leave created panes open for inspection.
- Requires Neovim running inside Herdr and `herdr` on `PATH` for sending. Capture and queue editing work without Herdr. No extra plugin is required.
- The queue is `agent-comments.md` at the Git checkout root containing Neovim's working directory (`:pwd`), or in that directory outside Git. A local `.git/info/exclude` rule keeps it out of Git without changing tracked ignore files. Existing state-directory queues migrate automatically if the root file does not exist. Code and line numbers are snapshots, not live annotations.
- After Herdr acknowledges submission (not task completion), the batch is archived as `sent-*.md` under `stdpath('state')/agent-comments/<checkout-hash>/` with target and timestamp. The root queue and any edits remain untouched until you manually flush. For failed or uncertain sends, check the agent before retrying to avoid duplicates.

### Git
- `:GitBaseMain`: compare Gitsigns gutter markers and hunks against local `main` in all open and future buffers.
- `:GitBaseOriginMain`: use cached `origin/main` instead; fetch separately to refresh it.
- `:GitBaseReset`: restore the normal staging-area comparison in all buffers. Base choices last for the current Neovim session and include unsaved edits; they compare directly against the chosen branch tip, not the merge base.
- `<leader>gs`: Telescope git status.
- `<leader>gf`: Telescope tracked files changed against local `main`, including staged and unstaged changes, with a diff preview. Deleted and untracked files are excluded. Open a result with `<CR>`, `<C-t>`, `<C-v>`, or `<C-x>`. Save buffers first; comparisons use files on disk.
- `<leader>gd`: open Diffview for uncommitted changes (staged and unstaged) in the working tree.
- `<leader>gb`: open Diffview for branch commits since diverging from `main` (`main...HEAD`); excludes uncommitted changes.
- `<leader>gD`: close Diffview.
- `<leader>gH`: file history in Diffview.
- Diffview compares files side by side, including merge conflicts.
- `<leader>gp`: browse GitHub pull requests with Octo and Telescope. Requires `gh` authenticated with `gh auth login`.
- `:Octo pr edit <number>`: open a PR in the current repository; `:Octo <url>` opens a GitHub PR URL directly. `:Octo` lists available actions.
- In an Octo PR buffer, `<CR>` shows actions; `<Space>ca` adds a general comment. Edit it and `:w` to publish it to GitHub.
- `:Octo review start` opens a PR review. On a changed line (or visual selection), `<Space>ca` adds an inline comment; `:w` saves it to the pending review. Use `:Octo review resume` for an existing pending review.
- `:Octo review submit` opens the submission window: `<C-a>` approves, `<C-r>` requests changes, and `<C-m>` submits a comment-only review (normal mode). `:Octo review close` closes the review view.
- In Octo reviews, `]q` / `[q` navigate changed files, `]t` / `[t` navigate threads, and `<Space>rt` resolves the current thread. These are Octo's buffer-local defaults; `<localleader>` is Space here.
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
- `<leader>hd`: diff current file side by side.
- `<leader>hD`: diff against index side by side.

### Formatting And Requests
- `:GradleTestCompile`: run `compileTestKotlin` using the nearest Gradle wrapper above the current file (or working directory). Requires an executable `gradlew` and the project's JDK. Save source files first; this compiles files on disk and does not run tests.
- Compilation errors open quickfix; press `<CR>` on an entry or use `:cnext` / `:cprev` to jump to its location. Build failures without compiler locations show raw output. Results are quickfix entries, separate from LSP diagnostics.
- `<leader>f`: format the current buffer through `conform.nvim`.
- JSON buffers use the system `jq` formatter automatically on save; `<leader>f` formats manually. Kotlin and shell buffers use `ktlint` and `shfmt`.
- `jsonls` provides diagnostics for invalid JSON and JSONC; inspect a diagnostic with `K` or use `<leader>q` to list buffer diagnostics.
- Kotlin buffers also format automatically on save, with a 10-second timeout for `ktlint` startup.
- `<leader>Rs`: send HTTP request in `kulala.nvim`.
- `<leader>Ra`: send all requests in the file.
- `<leader>Rb`: open Kulala scratchpad.

### Markdown Preview
- Markdown files render directly in Neovim with highlighted headings, bullets, and code blocks. The cursor line reveals its source for editing; insert mode shows raw Markdown.
- `:RenderMarkdown toggle`: toggle in-editor rendering. `:RenderMarkdown preview`: open a rendered view alongside the editable buffer.
- Markdown completion includes words from the current visible buffer.
- Markdown buffers enable English spell checking automatically.
- `]s` / `[s`: move to the next or previous misspelling.
- `z=`: suggest corrections for the word under the cursor.
- `<leader>mps`: start Markdown preview.
- `<leader>mpr`: refresh Markdown preview.
- `<leader>mpS`: stop Markdown preview.

### Mermaid
- `<leader>mp`: open the live Mermaid browser preview.
- `<leader>mx`: stop the Mermaid preview server.
- `<leader>mf`: format the current Mermaid buffer.
- `<leader>mr`: render the diagram inline when supported.
- `<leader>mc`: copy the Mermaid preview URL.
- `:MermaidPreview`: open the live Mermaid browser preview.
- `:MermaidPreviewStop`: stop the Mermaid preview server.
- `:MermaidFormat`: format the current Mermaid buffer.
- `:MermaidRender`: render the diagram inline when Kitty, Ghostty, or `chafa` is available.
- `:MermaidCopyURL`: copy the Mermaid preview URL.

### Mini.nvim Mappings Used Here
- `mini.ai`: `aa` and `ii` target the next surrounding text object.
- `mini.surround`: default mappings are active, including `sa` add, `sd` delete, and `sr` replace.
- `mini.pairs`: automatically closes parentheses, brackets, braces, and quotes in insert mode; typing the closing character skips over an existing pair.

### Visual Block Help
- Enter visual block mode with `<C-q>`.
- Press `<leader>?` to open the visual-block help box.
- Press `I` to insert text at the start of every selected line, then press `<Esc>` to apply it.
- Press `A` to append text at the end of every selected line, then press `<Esc>` to apply it.
- Press `c`, `d`, or `y` to change, delete, or yank the block.
- Press `<` or `>` to shift the block left or right.
- Press `J` or `K` to move the selected lines down or up.
- The help entries are registered for visual mode (`x`), which includes visual-block mode.

## Plugins
- `blink-cmp.lua`: `blink.cmp` completion UI with `LuaSnip` snippets and LSP/path/snippet sources, plus buffer word completion in Markdown.
- `conform.lua`: `conform.nvim` formatter runner with `<leader>f` and formatters for shell and Kotlin files.
- `diffview.lua`: `diffview.nvim` git diff and file history views.
- `gitlinker.lua`: `gitlinker.nvim` for copying or opening remote git links from normal or visual mode.
- `gitsigns.lua`: `gitsigns.nvim` for hunk signs, staging, resets, blame, and inline previews.
- `guess-indent.lua`: `guess-indent.nvim` to detect indentation settings from the current file.
- `kulala.lua`: `kulala.nvim` for running HTTP and REST requests from `.http` or `.rest` buffers.
- `mermaid.lua`: `mermaid.nvim` for dedicated Mermaid previews, formatting, diagnostics, and optional terminal rendering.
- `markdown-preview.lua`: `markdown-preview.nvim` with `live-server.nvim` for full Markdown previews, including Mermaid code blocks.
- `mini.lua`: `mini.nvim` modules currently used for `mini.ai`, `mini.surround`, `mini.pairs` (automatic closing pairs), and `mini.statusline` (filename-only statusline).
- `nvim-lint.lua`: `nvim-lint` for shell linting on enter, write, and insert leave.
- `nvim-lspconfig.lua`: `nvim-lspconfig` plus Mason tooling for LSP server setup and installation, including `gopls` for Go, `jsonls` diagnostics for JSON/JSONC, and `yamlls` for YAML validation, completion, and symbol navigation.
- `nvim-tree.lua`: `nvim-tree.lua` file explorer on the right with git status, root syncing, and a minimum width of 50 columns that grows to fit visible entries.
- `octo.lua`: `octo.nvim` for GitHub PR browsing, comments, review threads, and review submission, using `gh` and Telescope without Nerd Font icons.
- `render-markdown.lua`: `render-markdown.nvim` for readable Markdown inside Neovim, using plain heading markers and no Nerd Font-dependent code or link icons.
- `telescope.lua`: `telescope.nvim` plus FZF and UI-select extensions for file, grep, buffer, and LSP pickers.
- `todo-comments.lua`: `todo-comments.nvim` for highlighting and navigating TODO-style comments.
- `tokyonight.lua`: `tokyonight.nvim` colorscheme setup using `tokyonight-night`.
- `treesitter.lua`: `nvim-treesitter` parser management, including Mermaid syntax highlighting and indent support.
- `which-key.lua`: `which-key.nvim` for keymap discovery and grouped leader-key hints.

## Where To Change Things
- Change editor defaults in `lua/config/options.lua`.
- Change global keymaps in `lua/config/keymaps.lua`.
- Change external file-opening policy and platform handling in `lua/config/file_handlers.lua`.
- Change autocmds in `lua/config/autocmds.lua`.
- Change Telescope behavior or search mappings in `lua/plugins/telescope.lua` and `lua/features/search.lua`.
- Change tree behavior in `lua/plugins/nvim-tree.lua` and `lua/features/ui.lua`.
- Change LSP server setup in `lua/plugins/nvim-lspconfig.lua` and LSP mappings in `lua/features/lsp.lua`.
- Change JAR dependency source loading in `lua/features/jar_sources.lua`.
- Change git keymaps in `lua/features/git.lua`.
- Change personal shortcut access in `lua/features/shortcuts.lua`; edit the notes in `~/.config/shortcuts/`.

## Notes
- `have_nerd_font` is currently `false`, so icon-heavy plugin features stay disabled.
- Ordinary yanks (`y`, `yy`, visual `y`) also copy to the system clipboard; deletes and changes stay in Neovim's internal registers. Explicit register choices are preserved. `p` pastes from the internal register; `"+p` pastes from the system clipboard. On WSL, clipboard integration uses `win32yank.exe` when available, falling back to `clip.exe` and `powershell.exe`.
- The file tree is `nvim-tree`; `mini.nvim` is used for text objects, surround editing, and statusline, not file browsing.
