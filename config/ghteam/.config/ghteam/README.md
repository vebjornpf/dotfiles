# ghteam

Usage: `ghteam <org>`

- Lists all teams visible to your account in an `fzf` picker, showing team names.
- Preview above the picker shows every visible member's profile name and GitHub username. If no
  profile name is available, it shows the username instead.
- Enter opens the selected team on GitHub; Esc exits.
- Teams and members are paginated. Members load on selection and are cached only
  for the current picker session, then removed on exit.

Requires `gh`, `fzf`, and `jq`, plus an authenticated GitHub account with access to
the organization's teams and members. Organization SSO may require authorization.

No organization configuration is required; pass it as the argument.
`GHTEAM_HOME` locates the package; `GHTEAM_STATE_DIR` sets the temporary session
directory (default: `${XDG_CACHE_HOME:-$HOME/.cache}/ghteam`).
