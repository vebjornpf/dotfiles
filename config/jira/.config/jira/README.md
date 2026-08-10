# jira

The Jira CLI uses one summary cache at `$JIRA_STATE_DIR/project-current.json`.

Commands:
- `jira`
- `jira sync`
- `jira doctor [--json]`
- `jira team [list|picker]`
- `jira team status`
- `jira me [list|status|picker|<KEY>]`
- `jira backlog [list|picker]`
- `jira epics [list|picker]`
- `jira epics <KEY> open` - open the epic in a browser
- `jira epics <KEY> subtasks list [--json]`
- `jira epics <KEY> subtasks status`
- `jira item <KEY> [--json]`
- `jira item <KEY> --more [--json]`
- `jira item <KEY> open` - open the issue in a browser
- `jira item <KEY> assign` - assign the issue to the configured current user
- `jira item <KEY> transition [STATUS]` - transition the issue, or open a status picker
- `jira item <KEY> cp` - copy the issue URL
- `jira item <KEY> cpk` - copy the issue key
- `jira auth`
- `jira board`
- `jira create`
- `jira statusline`

`list` reads a cached filtered summary. `status` reads the same cache and groups issues by status. `picker` opens an interactive cached view. Bare scope commands show help. `jira item <KEY>` reads the cache; `--more` runs `acli jira workitem view <KEY>` live. Item actions `assign`, `transition`, `open`, `cp`, and `cpk` assign, transition, open, or copy the issue.

`jira epics <KEY> subtasks list` and `status` run a live paginated query for all issues under the epic, including done issues. The `subtasks` term refers to an epic's child issues; Jira may classify them as stories, tasks, bugs, spikes, or other issue types.

The `team` and `me` views show only assigned, non-done project issues, including backlog items. `me` matches the configured `JIRA_ACCOUNT_ID`; `team` includes assignments to anyone. The separate `backlog` view includes all backlog issues.

`jira sync` runs one query for all non-done issues in `JIRA_PROJECT_KEY`:

```text
project = <JIRA_PROJECT_KEY> AND statusCategory != Done ORDER BY updated DESC
```

The sync derives `team-completion.tsv`, `me-completion.tsv`, `backlog-completion.tsv`, and `epics-completion.tsv` from the canonical cache. These files are never synced independently. The installed `acli` search command does not accept `components` or `updated` as requested fields, so those fields are not currently included in the summary cache.

`jira doctor` is read-only. It checks local configuration, required commands, the state directory, and cache presence. It does not contact Jira.

Local config is loaded from `~/.config/local/tools.zsh`:
- `JIRA_PROJECT_KEY` - required project key
- `JIRA_ACCOUNT_ID` - required for `jira me`
- `JIRA_BASE_URL` - required for rendered lists and browse URLs
- `JIRA_STATE_DIR` - optional state directory override
- `JIRA_BOARD_URL` - required for `jira board`
- `ATLASSIAN_SITE`, `ATLASSIAN_EMAIL`, `ATLASSIAN_API_TOKEN` - used by `jira auth`

Issue creation still accepts `--component`; standalone component browsing is not currently part of the CLI.
