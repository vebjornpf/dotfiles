# Neovim

## Personal command notes

- `<leader>oc`: open these Neovim notes.
- `<leader>os`: search all shortcut notes.

## Commands

### Copy the current file to a new location

```vim
:w <directory>/<new-file>
```

Write the current buffer to a new file, keeping the original file open.
Replace the placeholders with the destination directory and filename; the directory must already exist.

### Create a new folder

```vim
:call mkdir('path/to/folder', 'p')
```

Create the folder and any missing parent folders. Replace `path/to/folder` with your desired path.

### Create a new empty file

```vim
:edit path/to/folder/new-file.md
:write
```

Use a filename that does not already exist. `:edit` opens a new empty buffer;
`:write` creates the file on disk. The destination folder must already exist.

Relative paths start from Neovim's current working directory (`:pwd` shows it).
Use an absolute path to choose a location independently of the current project.

## Neovim tree shortcuts

Press `<leader>e` to open or focus the file tree. The shortcuts below apply while the tree is focused.

### Filter the tree

- `f`: type a filename filter, then press Enter or Esc to return to the tree with the filter active.
- `j` / `k`: move down / up through the visible entries.
- `F`: clear the filter.

While filtering, folders are shown only if their name matches or they contain loaded matching entries.
Press `E` before filtering to load files across subfolders, then `f` and type the filter.
The filter matches filenames, not file contents. `F` restores the unfiltered tree.

### Navigate files

- `j` / `k`: move to the next / previous visible entry (files and folders).
- `/name` then Enter: search visible tree entries for a filename.
- `n` / `N`: jump to the next / previous search match.
- Enter or `o` on a file: open it.

These movements do not skip folders automatically. Expand folders first to include their files.

### Switch between open files

- `<leader><leader>`: choose an open buffer with Telescope.
- `:bnext` / `:bprevious`: switch to the next / previous buffer.
- Ctrl-^ (Ctrl-6 on many keyboards): switch to the previously used buffer.

### Navigate folders

- `j` / `k`: move down / up.
- Enter or `o`: expand or collapse the selected folder; open the selected file.
- `P`: move to the parent folder.
- Backspace: close the containing folder and move to it.
- `>` / `<`: move to the next / previous sibling entry in the same folder.
- `-`: change the tree root to its parent folder.

### Open all folders and subfolders

- `E`: expand all folders recursively (subject to the plugin's expansion limit).
- `W`: collapse all folders.

To filter files across subfolders: press `E`, then `f` and type the filter.

### Create a folder or file

Select the destination folder and press `a`. In the path prompt:

- Enter `new-file.md` to create an empty file.
- Enter `new-folder/` with a trailing slash to create a folder.
- Enter `new-folder/new-file.md` to create a file and any missing parent folders.

Keep the destination path shown in the prompt and append your new name, then press Enter.
If a file is selected, the new item is created in that file's containing folder.

Press `g?` in the tree to see all available shortcuts.
