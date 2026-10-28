# Herdr

## List detected agents

```sh
herdr agent list
```

Lists detected agents across the current Herdr session.

## List agents in the current workspace

Run inside a Herdr pane:

```sh
herdr pane list --workspace "$HERDR_WORKSPACE_ID" |
  jq '.result.panes[] | select(.agent != null)'
```

Filters out ordinary terminal panes. Requires `jq`.
