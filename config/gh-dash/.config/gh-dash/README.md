# gh-dash

GitHub pull request and issue dashboard.

## Pull request checkout

Press `C` on a pull request to check it out at
`~/.herdr/worktrees/<repo>/pr-<number>-<branch>` and open the worktree in Herdr.
The repository must already have a matching clone under `~/git`.

Press `d` to review the selected pull request in Hunk using the official
`hunk-gh` extension. Quit Hunk to return to the dashboard.

Press `M` to approve the PR with `LGTM`, then use the same interactive
`gh pr merge` flow as gh-dash's `m` key. Cancelling the merge leaves the
approval in place.

## Requirements

- `gh`, authenticated with GitHub
- `git`
- `herdr`
- `hunk` with the `modem-dev/hunk-gh` extension
