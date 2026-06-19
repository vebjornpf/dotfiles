# jira

Supported commands:
- `jira mywork`
- `jira mywork list`
- `jira mywork status`
- `jira item <KEY>`
- `jira item <KEY> open`
- `jira item <KEY> cp`
- `jira item <KEY> cpk`
- `jira statusline`
- `jira backlog`
- `jira board`
- `jira board open`
- `jira sync`
- `jira sync all`
- `jira sync mywork`

Local config:
- `~/.config/local/jira.zsh`

Variables:
- `JIRA_PROJECT_KEY` - required project key used by team-scoped sync
- `JIRA_BASE_URL` - required for browse and copy URLs
- `JIRA_BOARD_URL` - required for `jira board`

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
```
