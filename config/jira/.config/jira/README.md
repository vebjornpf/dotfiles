# jira

Supported commands:
- `jira mywork`
- `jira mywork list`
- `jira mywork status`
- `jira mywork <KEY>`
- `jira mywork <KEY> open`
- `jira mywork <KEY> cp`
- `jira mywork <KEY> cpk`
- `jira backlog`
- `jira board`
- `jira board open`
- `jira sync`
- `jira sync mywork`
- `jira sync backlog`

Local config:
- `~/.config/local/jira.zsh`

Variables:
- `JIRA_BASE_URL` - required for browse and copy URLs
- `JIRA_BOARD_URL` - required for `jira board`
- `JIRA_BACKLOG_JQL` - required for `jira sync backlog`

Example:

```zsh
export JIRA_BASE_URL="https://<org>.atlassian.net"
export JIRA_BOARD_URL="https://<org>.atlassian.net/jira/software/..."
export JIRA_BACKLOG_JQL='project = <KEY> AND status = Backlog ORDER BY created DESC'
```
