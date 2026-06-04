---
name: add-new-skills
description: Use when you are asked to create or update a reusable AI skill. By default, store it in the dotfiles repo under ~/git/dotfiles/config/opencode/.config/opencode/skills unless the user asks for a different location.
---

# Add New Skills

Use this skill when you are told to create or update a reusable AI skill and the default location should be the dotfiles repo at `~/git/dotfiles/config/opencode/.config/opencode/skills/`.

This skill is the authority for:
- where reusable skills should live by default
- the local folder naming and structure rules
- the minimum repo-local `SKILL.md` layout
- repo-specific verification

Use `skill-creator` first when deciding the general design, scope, trigger strategy, or maintenance approach for a skill.

## Use This Skill When

- You are asked to create a new reusable AI skill and no other location is requested
- You are asked to update an existing skill in the dotfiles opencode skills folder
- You need the repo-specific rules for how reusable skills should be stored and structured in the dotfiles repo

## Do Not Use This Skill For

- One-off prompts that should not become reusable skills
- Tool-specific runtime wiring such as symlinks under `~/.codex`
- General documentation outside the skills folder
- General skill design decisions without regard to this repo
- Skills that are project-specific, employer-specific, machine-specific, or sensitive — use the `private-` prefix convention instead (see below)

## Local Rules

- Store reusable skills under `~/git/dotfiles/config/opencode/.config/opencode/skills/` by default — never write directly to `~/.config/opencode/skills/`
- Only store reusable general-purpose skills here by default
- For employer-specific, machine-specific, or otherwise sensitive skills: prefix the folder name with `private-` (e.g. `private-grafana-query`). These are gitignored and will not be committed.
- Keep skills reusable across AI CLIs unless a tool-specific format is explicitly required
- Name each skill directory with lowercase hyphen-case
- Keep the folder name identical to the frontmatter `name`
- Require a `SKILL.md` in every skill directory
- Keep `SKILL.md` concise and operational
- Add `references/`, `scripts/`, or `assets/` only when they directly support the skill

## Private Skills Convention

Skills prefixed with `private-` are gitignored by `.gitignore`:

```
config/opencode/.config/opencode/skills/private-*/
```

Use this for skills containing:
- Employer-specific infrastructure details (URLs, cluster names, namespaces)
- Credentials or internal tooling context
- Anything not suitable for a public dotfiles repo

Private skills follow the same `SKILL.md` structure but live only on the local machine.

## Required Structure

```text
~/git/dotfiles/config/opencode/.config/opencode/skills/<skill-name>/
  SKILL.md
```

Optional extras:
- `references/` for details loaded only when needed
- `scripts/` for deterministic or repeated steps
- `assets/` for templates or files the skill uses

## Local `SKILL.md` Baseline

Start with YAML frontmatter:

```yaml
---
name: skill-name
description: One clear sentence saying when this skill should be used and what it helps with.
---
```

Then include a short Markdown body with:
- purpose
- use when
- do not use when
- rules or constraints
- concrete steps
- verification
- maintenance metadata such as `Last reviewed`, `Status`, and `Sources of truth`

## Workflow

1. Use `skill-creator` to shape the skill's design and maintenance model.
2. Choose a short hyphen-case name. Prefix with `private-` if the skill contains sensitive or employer-specific data.
3. Create `~/git/dotfiles/config/opencode/.config/opencode/skills/<skill-name>/SKILL.md` unless the user explicitly wants another location.
4. Add only the instructions another agent is unlikely to infer reliably on its own.
5. Add optional support folders only when the workflow is long, fragile, repetitive, or version-sensitive.
6. Verify the finished skill matches this repo's naming and placement rules.

## Verification

Before finishing:
- Confirm the folder is under `~/git/dotfiles/config/opencode/.config/opencode/skills/` unless the user requested another location
- Confirm the folder name matches the frontmatter `name`
- Confirm the description clearly says when to use the skill
- If the skill contains sensitive/private data, confirm the folder uses the `private-` prefix
- Confirm `SKILL.md` is concise and actionable
- Confirm maintenance metadata is present

## Starter Template

```markdown
---
name: my-skill
description: Use when the user needs help with <specific workflow> in this repo or environment.
---

# My Skill

## Purpose
Short statement of what this skill is for.

## Use When
- ...

## Do Not Use When
- ...

## Rules
- ...

## Steps
1. ...
2. ...
3. ...

## Verification
- ...

## Maintenance
- Last reviewed: YYYY-MM-DD
- Status: active
- Sources of truth: ...
```
