---
name: workable-item
description: Use when the user has raw notes, an email, a bug report, or a vague request that should be turned into a clear, workable item such as a task, ticket, action item, or investigation brief.
---

# Workable Item

## Purpose
Turn rough input into a small, actionable work item that someone can pick up and execute.

## Use When
- The user has an unstructured issue description, email, chat message, or notes
- The user wants help writing a task, ticket, action item, follow-up, or investigation item
- The user needs a concise title and description from messy source material
- The user wants the output to be tool-agnostic rather than tied to Jira, Linear, or another system

## Do Not Use When
- The user wants a full project plan or roadmap
- The user wants a deep root-cause analysis instead of a work item
- The input is already a clear and complete task that only needs minor wording cleanup

## Rules
- Optimize for clarity and actionability over completeness
- Preserve the core problem, trigger, and expected next step
- Keep the output short unless the user explicitly asks for more detail
- Default to neutral, reusable field names such as `Title`, `Summary`, `Problem`, `Scope`, `Next step`, or `Acceptance criteria`
- Use `Action points` only if the user explicitly asks for them
- Do not force backlog-tool jargon unless the user asks for a specific format
- If key facts are missing, state the assumption briefly or label the item as investigation-oriented

## Steps
1. Identify the core issue or request in one sentence.
2. Extract the minimum useful facts:
   - what happened
   - why it matters
   - who needs to act
   - what decision, clarification, or change is needed
3. Decide the item type implicitly:
   - task for straightforward work
   - investigation for unclear behavior
   - follow-up for reply/coordination work
4. Produce a concise output with:
   - a clear title
   - a short description or summary
   - optional acceptance criteria or next step if helpful
   - action points only when explicitly requested by the user
5. If the source mentions a message or request that needs an answer, include that responding is part of the work item.

## Verification
- The title is specific enough to understand without reading the source material
- The description explains the issue and the expected outcome
- The item is short enough to paste into a tracker, doc, or chat without cleanup
- The format stays generic unless the user asks for a specific system

## Maintenance
- Last reviewed: 2026-04-09
- Status: active
- Sources of truth: user workflow preference, /home/vebjorn.fjeldberg/git/dotfiles/ai/skills/skill-creator/SKILL.md, /home/vebjorn.fjeldberg/git/dotfiles/ai/skills/add-new-skills/SKILL.md
