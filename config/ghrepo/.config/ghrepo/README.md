# ghrepo

Supported commands:
- `ghrepo`
- `ghrepo sync`

Local config:
- `~/.config/local/tools.zsh`

Variables:
- `GHREPO_ORG` - required GitHub organization to sync

State files:
- `repos.tsv` - `<owner/repo>\t<url>`

Picker behavior:
- `ghrepo` opens an `fzf` picker with no preview
- green rows are already cloned somewhere under `~/git`
- red rows are not cloned yet
- `Enter` runs `gh repo clone <owner/repo>` from `~/git` and refreshes the picker
- `Alt-o` opens the selected repo in the browser

Example:

```zsh
export GHREPO_ORG="elhub"
```
