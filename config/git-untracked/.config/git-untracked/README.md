# git-untracked

```sh
git-untracked
```

- Opens an fzf picker of untracked files across the current Git repo, including when launched from a subdirectory.
- Preview appears above the list. Text previews are limited to 200 lines/64 KiB; symlink previews show the target without opening it.
- **Alt+d** moves the highlighted file, or Tab-selected files, to the system trash without confirmation. The picker refreshes and stays open.
- **Tab / Shift+Tab** select/deselect files. **Esc / Ctrl+c** exit. Enter does nothing.
- Ignored files, directories, and nested repositories are excluded. Files are rechecked before each trash operation so newly staged or ignored files are skipped.
- No permanent-delete fallback. Restore mistakes using your system trash. Trash errors are displayed; press Enter to return to the picker.

Requires Git, fzf, Python 3, and one of `trash-put` (trash-cli), `gio`, or macOS `trash`, in that preference order. Trash availability on the repo's filesystem is required; unsupported operations fail without falling back to deletion.

No local configuration needed. Zsh integration adds the command to PATH. `GIT_UNTRACKED_HOME` locates the installed package; `GIT_UNTRACKED_STATE_DIR` is reserved for future state (no state is currently written).
