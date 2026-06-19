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
- `jira create`
- `jira sync`
- `jira sync all`
- `jira sync mywork`

`jira create` prompts for title in the terminal, opens `$EDITOR` for the description, and uses pickers for issue type, component, priority, and assignment.

It fetches issue types from live Jira project metadata.

Parent rules depend on the selected issue type:
- sub-task types require a parent task
- hierarchy level `0` types require an epic
- higher-level types like `Epic` do not prompt for a parent

Selection sources:
- epics: `epics-completion.tsv`
- subtask parents: `all-completion.tsv`
- components: live Jira project components from `acli jira project view --key "$JIRA_PROJECT_KEY" --json`
- issue types: live Jira project issue types from `acli jira project view --key "$JIRA_PROJECT_KEY" --json`

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
