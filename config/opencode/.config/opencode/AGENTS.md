# Response style

- Do not use filler phrases like "Good question", "Great idea", "Absolutely", "Certainly", "Of course", "Sure", etc.
- Do not validate or praise the user's questions or ideas.
- Be direct and concise. Skip emotional framing.

# Command formatting

- Write commands ready to run as-is whenever possible.
- If a value must be supplied by the user, use a short inline placeholder: `<word>` (e.g. `<org>`, `<user>`, `<repo>`, `<token>`, `<file>`).
- Never use `export VAR="..."` prefixes.

# Command logging

- Only call `log_command` when the user explicitly asks for a command to run themselves (e.g. "give me a command", "what's the command to", "how do I run").
- Do not log commands you run yourself as part of doing work.
- When logging, provide:
  - `command`: the full command exactly as shown, including any `<placeholder>` values
  - `description`: a short phrase describing what the command does (e.g. "list PRs assigned to user")
  - `tool`: the main CLI tool used (e.g. `gh`, `git`, `npm`, `docker`)

# Git workflow

- Never create a pull request.
- Before any commit, propose the exact commit message and wait for explicit user approval.
- Keep commit messages short, concise, and informative.
- Default to a single-line subject unless extra context is genuinely necessary.
- Do not run `git commit` until the user has approved the message.

# Local Skills

- Use the `sonar-workflow` skill when working in repos that use `.sonar/project`, `sonar sync`, and generated `.sonar/issues-*.json` files.

# Jira

- Agents may use the `jira` CLI for Jira-related tasks.
- Use `jira team list --json` for cached active project work.
- Use `jira me list --json` for cached issues assigned to the current user.
- Use `jira backlog list --json` for cached backlog issues.
- Use `jira item <KEY> --json` for cached issue summary data.
- Use `jira item <KEY> --more --json` for live detailed issue information, including comments and richer fields.
- Use `jira sync` when the summary cache is missing or stale.
- Use `jira` and scope commands for help; use explicit `picker` commands for interactive selection.
- Use the CLI rather than reading Jira cache files directly.
- Avoid mutating Jira state unless the user explicitly asks. Mutating commands include `jira create`.

When a task may relate to existing Jira work, inspect the user's assigned issues first. Use descriptions, status, reporter, assignee, priority, and issue type to connect the request to existing work. If the relationship is unclear, mention likely issue keys and ask before assuming scope.

- Start with `jira me list --json` for assigned non-done issues.
- Use `jira me status` to understand assigned work grouped by status.
- Use `jira item <KEY> --json` for cached issue details.
- Use `jira item <KEY> --more --json` when live Jira details are needed.
- Use `jira epics list --json` for project epic context.
- Use `jira doctor` to diagnose local Jira setup.
