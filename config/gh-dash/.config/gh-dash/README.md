# gh-dash

GitHub pull request and issue dashboard.

## Repository view

Run `gh dash` from an interactive zsh shell. Inside a GitHub repository, the
pull requests view shows only open PRs in that repository. Outside a GitHub
repository, it uses the global PR sections from `config.yml`. Issues,
notifications, and keybindings keep their global settings in both views.

## Pull request checkout

Press `c` on a pull request to check it out in the main clone under `~/git`
and focus its Herdr workspace (or create one). The checkout must have no
uncommitted changes because this switches its branch.

Press `C` to check it out at `~/.herdr/worktrees/<repo>/pr-<number>-<branch>`
and open the worktree in Herdr. Both commands require a matching clone under
`~/git`.

Press `d` to review the selected pull request in Hunk using the official
`hunk-gh` extension. Quit Hunk to return to the dashboard.

Press `M` to approve the PR with `LGTM`, then use the same interactive
`gh pr merge` flow as gh-dash's `m` key. Cancelling the merge leaves the
approval in place.

## Requirements

- `gh`, authenticated with GitHub
- `git`
- `herdr`
- `jq`
- `hunk` with the `modem-dev/hunk-gh` extension
