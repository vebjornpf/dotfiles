# sonar

Agent note:
- Use the `sonar-workflow` skill when working with repos that use this Sonar layout.

Supported commands:
- `sonar sync [quality...]`
- `sonar rules [quality...]`
- `sonar export [quality...]`
- `sonar status [quality...]`
- `sonar path [quality]`
- `sonar pr <number>`
- `sonar web`

Qualities:
- `maintainability`
- `security`
- `reliability`
- `all`

Repo config:
- `.sonar/project`

Example `.sonar/project`:

```text
projectKey=<sonar-project-key>
branch=main
```

If `.sonar/project` is missing, a command creates it with an empty
`projectKey` and `branch=main`, then stops. Set the key in the file and run the
command again. Existing config files are never overwritten.

Local config:
- `~/.config/local/tools.zsh`

Variables:
- `SONAR_BASE_URL` - required SonarQube base URL
- `SONAR_TOKEN` - required token used for API requests

Example local config:

```zsh
export SONAR_BASE_URL="https://sonar.example.com"
export SONAR_TOKEN="<token>"
```

Repo output:
- `.sonar/project` - tracked repo config for Sonar project mapping
- `.sonar/raw/issues-<quality>.json` - cached Sonar payload merged across pages
- `.sonar/raw/rules/<repository>/<rule>.json` - cached Sonar rule details from `api/rules/show`
- `.sonar/issues-<quality>.json` - normalized issue export for the current repo

Notes:
- `sonar sync` fetches and exports `maintainability`, `security`, and `reliability` by default
- `sonar rules` reads `.sonar/issues-<quality>.json`, extracts unique rule keys, and fetches the matching rule details
- `sonar export` rewrites repo files from cached payloads without calling Sonar again
- `sonar pr <number>` queries new and fixed issues, remediation effort, and the Sonar PR URL
- `sonar web` opens `dashboard?id=<projectKey>&branch=<branch>` for the current repo
