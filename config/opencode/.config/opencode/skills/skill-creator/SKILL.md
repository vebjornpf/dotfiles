---
name: skill-creator
description: Use when creating or updating a reusable AI skill and you need general guidance on skill design, scope, triggers, resource layout, or long-term maintenance. Apply this before repo-specific placement rules.
---

# Skill Creator

Use this skill for general skill design and maintenance guidance.

This skill is the authority for:
- what a good skill should contain
- how to scope a skill cleanly
- how to write strong trigger descriptions
- when to use `references/`, `scripts/`, and `assets/`
- how to keep a skill maintainable over time

This skill is not the authority for repo-specific placement or naming conventions outside the skill itself. Apply local repo rules separately.

## Use This Skill When

- A new skill is being designed from scratch
- An existing skill needs a structural refactor
- A skill is too broad, too verbose, or poorly scoped
- A skill needs clearer lifecycle or maintenance guidance

## Do Not Use This Skill For

- One-off prompts that should not become reusable skills
- Repo-specific location decisions when another local skill defines them
- General documentation that is not intended to guide an agent's execution

## Core Principles

- Keep `SKILL.md` concise and operational
- Include only guidance another agent is unlikely to infer reliably on its own
- Separate stable rules from version-sensitive guidance
- Make use and do-not-use boundaries explicit
- Prefer one coherent responsibility per skill
- Add scripts or assets only when they materially improve repeatability or reliability

## Structure Guidance

Every skill must contain `SKILL.md`.

Optional supporting folders:
- `references/` for detailed or changing guidance that should be loaded only when needed
- `scripts/` for deterministic or repeated steps
- `assets/` for templates or files the skill uses in output

Keep durable workflow rules in `SKILL.md`.
Move fast-changing implementation advice into `references/`.

## Description Guidance

The frontmatter `description` is the main trigger surface.

A strong description should say:
- what the skill helps with
- when it should be used
- what kinds of requests or contexts should activate it

Do not rely on the body to carry the main trigger logic.

## Recommended `SKILL.md` Sections

- purpose
- use when
- do not use when
- rules
- steps
- verification
- maintenance

## Maintenance

Each maintained skill should include:
- `Last reviewed: YYYY-MM-DD`
- `Status: active | needs-review | deprecated`
- `Sources of truth: ...`

Review a skill when:
- a framework or tool upgrade changes recommended practice
- repeated corrections show the skill is drifting
- its guidance has not been reviewed within the expected cadence

Suggested cadence:
- monthly for fast-moving topics
- quarterly for moderately stable topics
- on-change only for highly stable internal conventions

## Workflow

1. Identify the repeated workflow the skill should cover.
2. Decide what must live in `SKILL.md` versus `references/`, `scripts/`, or `assets/`.
3. Write a precise frontmatter `description`.
4. Keep the body procedural and bounded.
5. Add maintenance metadata so staleness is visible.
6. Verify the skill is concise, specific, and easy to apply.

## Verification

Before finishing:
- Confirm the skill has one clear responsibility
- Confirm the description triggers the right use cases
- Confirm `SKILL.md` contains durable guidance rather than bloated reference material
- Confirm version-sensitive guidance is isolated when needed
- Confirm maintenance metadata is present
