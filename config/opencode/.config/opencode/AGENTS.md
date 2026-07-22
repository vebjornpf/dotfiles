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

# Local Skills

- Use the `sonar-workflow` skill when working in repos that use `.sonar/project`, `sonar sync`, and generated `.sonar/issues-*.json` files.

# Jira

- Agents may use the `jira` CLI for Jira-related tasks.
- Prefer cached and read-oriented commands first: `jira mywork list`, `jira mywork status`, `jira mywork <KEY> print`, `jira item <KEY> print`.
- Use `jira sync mywork` when fresher Jira data is needed.
- Avoid mutating Jira state unless the user explicitly asks. Mutating commands include `jira create` and `jira item <KEY> move`.
