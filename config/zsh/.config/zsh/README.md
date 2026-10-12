# Zsh helpers

- `gbs [branch]` — show the current (or specified local) branch's upstream,
  associated open/merged/closed GitHub PRs with links, and checkout location/type.
  Requires an authenticated `gh`; shows up to 100 matching PRs in the current
  GitHub repository. Searches upstream and local branch names, with a PR-number
  fallback for `pr-<number>` branches, without fetching.
- `gdm` — open Neovim Diffview against `main`.
- `gdom` — fetch `origin`, then open Neovim Diffview against `origin/main`.

Zsh loads these helpers automatically in new interactive sessions.
