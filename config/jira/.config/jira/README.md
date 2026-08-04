# jira

Supported commands:
- `jira auth`
- `jira mywork`
- `jira mywork list`
- `jira mywork status`
- `jira item <KEY>`
- `jira item <KEY> open`
- `jira item <KEY> cp`
- `jira item <KEY> cpk`
- `jira item <KEY> print`
- `jira item <KEY> move`
- `jira mywork <KEY> print`
- `jira statusline`
- `jira backlog`
- `jira board`
- `jira board open`
- `jira component`
- `jira create`
- `jira epics`
- `jira sync`
- `jira sync all`
- `jira sync mywork`

`jira create` creates a work item in `TDX` using `<EPIC-KEY> <Story|Spike|Bug> <Low|Medium|High>` plus flags. `--summary` and `--component` are required. If `--description` is omitted it opens `$EDITOR` at the end for optional free text. `--assign` explicitly assigns the created item to you after creation.

`jira epics` opens a cached picker showing only epic issues from `all-current.json`. It does not trigger a sync.

It fetches issue types from live Jira project metadata.

`jira component` lets you fuzzy-pick one component, then opens a picker with all non-done issues using that component.

Picker shortcuts:
- `alt-a` assign selected issue to you
- `alt-s` pick a status and transition the selected issue

Selection sources:
- shell completion for epic key: cached `epics-completion.tsv`
- shell completion for `--component`: cached `components.tsv` when available

Example create command:

```bash
jira create TDX-123 Story High --summary "Investigate issue" --component api --assign
```

Local config:
- `~/.config/local/tools.zsh`

Variables:
- `JIRA_PROJECT_KEY` - required project key used by team-scoped sync
- `JIRA_BASE_URL` - required for browse and copy URLs
- `JIRA_BOARD_URL` - required for `jira board`
- `ATLASSIAN_SITE` - optional site used by `acli-jira-login`, for example `<org>.atlassian.net`
- `ATLASSIAN_EMAIL` - optional Atlassian account email used by `acli-jira-login`
- `ATLASSIAN_API_TOKEN` - optional Atlassian API token read by `acli-jira-login`

Helper:
- `jira auth` logs `acli` into Jira by piping `ATLASSIAN_API_TOKEN` to `acli jira auth login`
- `acli-jira-login` remains available as a shell helper and delegates to `jira auth`

State files:
- `all-current.json` - synced project items not assigned to you
- `mywork-current.json` - synced items assigned to you
- `all-completion.tsv` - derived completion for all tasks
- `mywork-completion.tsv` - derived completion for my tasks
- `backlog-completion.tsv` - derived completion for backlog tasks
- `epics-completion.tsv` - derived completion for epics

Example:

```zsh
export JIRA_PROJECT_KEY="<KEY>"
export JIRA_BASE_URL="https://<org>.atlassian.net"
export JIRA_BOARD_URL="https://<org>.atlassian.net/jira/software/..."
export ATLASSIAN_SITE="<org>.atlassian.net"
export ATLASSIAN_EMAIL="<you@example.com>"
export ATLASSIAN_API_TOKEN="<token>"
```
