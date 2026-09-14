---
name: domain-learning-guide
description: "Create or reorganize repository domain guides for total newcomers. Use when asked to explain an unfamiliar business domain, make a repository work as a learning guide, order concepts by prerequisites, or remove forward references from domain documentation."
argument-hint: "[domain or optional target file]"
user-invocable: true
license: GPL
context: fork
metadata:
  author: jakob.kok@dnb.no
  version: 1.1
---

# Domain learning guide

Create or improve a repository guide in which a developer with no domain
knowledge can learn what the domain does, why its concepts exist, and how they
relate. Each concept is new when introduced and depends only on concepts the
reader already knows.

## Artifact contract

Every create or edit run ends with one newcomer-facing Markdown guide inside the
target repository. Prefer an existing domain guide. Otherwise, use the
repository's documentation area and a descriptive name such as
`docs/<domain>-concepts.md`. Link the guide from the README or nearest
documentation index. If both exist, prefer the root README unless the repository
already presents the documentation index as its newcomer entry point.

The guide teaches the domain. It does not replace setup instructions,
architecture documentation, decision records, or the canonical context glossary.
Link those documents where they help the newcomer continue learning.
The required artifact is a prose teaching guide. A glossary, term table, or
`CONTEXT.md` edit alone does not satisfy this skill.

## Workflow

### 1. Fix the domain boundary and target

Identify:

- the domain owned or exposed by the repository;
- the people who use the product and the problem they solve;
- whether an existing guide should be improved;
- the target file and the repository entry point that should link to it.

The reader is always a developer who is new to the repository and has zero
knowledge of its business domain. Assume the reader can navigate a repository
and read plain technical documentation. Assume no knowledge of domain acronyms,
industry roles, business processes, institutional relationships, product history,
or reasons why the domain works this way.

Treat industry standards and their vocabulary as domain knowledge. Define them
before using them to explain another concept. Examples include protocol names,
message types, regulatory terms, institutional roles, and industry acronyms.

Find repository facts yourself. Ask the user only for decisions that the
repository cannot answer. Ask about scope only when the repository contains
multiple plausible domains and ownership is unclear. For an existing guide,
read its current contents immediately before editing so concurrent user changes
remain intact.

This step is complete when the domain boundary, user problem, existing material,
target file, and entry-point link are explicit.

### 2. Find the canonical vocabulary

Look for `CONTEXT-MAP.md` at the repository root. If it exists, follow it to the
context that owns the topic. Otherwise, read the root `CONTEXT.md` when present.
Then inspect the smallest relevant set of source material, such as contracts,
user-interface labels, domain documentation, examples, and decision records.

#### Retrieve missing domain knowledge

Repositories often have no context glossary or contain only part of the domain
language. Retrieve missing concepts in this order:

1. Search repository contracts, user-interface text, tests, examples, and history.
2. Search Confluence and Jira with the Atlassian MCP for definitions, process
   descriptions, decisions, examples, and the original work items.
3. Prefer sources owned by the relevant domain team and confirm important claims
   against more than one source when possible.
4. List terms that remain unknown, ambiguous, or contradictory. Ask the user to
   provide documentation or choose the intended meaning for those terms.

Search for facts before asking the user. Ask focused questions that name the term,
the competing meanings, and the missing evidence. Never invent a definition to
complete the guide.

Treat the context glossary as the authority for term names. Surface a conflict
between the glossary and the requested meaning before drafting. Keep
implementation decisions in decision records and learning material in the
guide. A context glossary defines terms; it is not the learning guide. The guide
can define a supporting teaching term that the glossary does not contain. Label
it consistently and verify that it does not rename a canonical concept.

In a multi-repository system, take canonical names from the context that owns the
concept. Gather behavioral evidence from the repository that implements the
behavior. Keep naming authority and factual evidence distinct.

This step is complete when every important term has a canonical name and every
factual claim has a traceable source or is clearly marked as an example.

### 3. Build the concept graph

Inventory the concepts a newcomer must understand. Include roles, identifiers,
objects, events, processes, variants, states, measurements, and easily confused
terms that appear in the product or source material.

Include the motivation for each core concept. A newcomer must learn why the
concept exists, not only its definition. Treat a missing "why" as a missing
prerequisite when the definition would otherwise appear arbitrary.

Create a directed dependency graph. Add an edge `A -> B` when the definition of
`B` needs `A`. General words known to the audience are roots and need no domain
definition. A cycle means the definitions are too entangled; split or rewrite
them until the graph is acyclic.

Topologically order the graph. A common order is:

1. participants and fundamental objects;
2. identifiers;
3. events and structures;
4. the simplest process;
5. process variants;
6. operational states and measurements;
7. similar terms, caveats, and edge cases.

Use the graph's order when it differs from this common shape.

This step is complete when every non-root concept has all its prerequisites
earlier in one acyclic order.

### 4. Draft the concept ladder

Start with a plain statement of the user problem and the repository's role in
solving it. Then write in ASD-STE100 Simplified Technical English where
practical:

- Use short sentences and active voice.
- Define one concept at a time.
- Expand an acronym at its first use.
- Bold a canonical term at its definition, not at every later use.
- Use the same canonical term after defining it.
- Put a concrete example after its required concepts.
- Use diagrams only after every label and relationship in them is understood.
- Explain two similar terms only after defining both.
- Separate observed data from interpretation. State what the source proves.

For each core concept, answer the applicable newcomer questions in dependency
order:

1. What is it?
2. Why does the domain need it?
3. How does it relate to concepts already introduced?
4. What is one concrete repository-grounded example?
5. Where does a developer or product user encounter it?

Prefer a plain explanation over a compressed definition. Preserve necessary
precision, especially where two domain terms sound similar but have different
meanings.

For an existing guide, preserve correct facts, examples, links, and user edits.
Reorder and rewrite only what the concept graph requires.

This step is complete when the guide follows the graph and a total newcomer can
explain the domain's purpose, participants, core process, important variants,
and product-facing terms without external domain knowledge.

### 5. Run the first-use audit

Read the rendered sequence from the title to the last line. Include headings,
tables, diagram labels, captions, and link text in the audit. A heading can
preview a term when the first sentence below it defines that term before any
explanation depends on it.

Build a working audit table for each domain term. It need not become part of the
guide:

| Column           | Content                                          |
| ---------------- | ------------------------------------------------ |
| Term             | Canonical or supporting teaching term            |
| Source           | Owning context or factual source                 |
| Prerequisites    | Concepts needed by its definition                |
| First definition | First defining sentence or heading plus sentence |
| Earlier use      | Any use before the definition                    |
| Status           | Pass or the exact repair needed                  |

Repair every forward reference, circular definition, duplicate definition, and
unexplained acronym. Remove a premature term, replace it with plain language, or
move its definition earlier. Do not solve ordering by adding parenthetical
mini-definitions throughout the document.

Run a newcomer test after the term audit. For every core concept, ask "Why is
this needed?" If the guide answers only what the concept is, add the missing
motivation after its prerequisites. Check that examples teach the relationship
rather than merely repeat the definition.

This step is complete only when every domain term passes every row of the audit
and every core concept passes the newcomer test.

### 6. Place and validate the guide

Fulfil the artifact contract. Keep the canonical glossary linked as a reference
rather than copying all of its entries into the guide.

Add a maintenance pointer to the repository's root `AGENTS.md` and `CLAUDE.md`
when each file exists. The pointer must name the guide and require updates in the
same change when domain concepts, terminology, roles, or workflows change. When
one instruction file links to the other, edit their shared source once.

Run the repository formatter or Markdown check. Verify new local links exist.
Review the final diff for unrelated changes and reread the formatted file once.

Perform a read-only audit only when the user explicitly asks for review without
edits. In that branch, report the exact changes needed to satisfy the artifact
contract.

For every other run, continue through repository edits and validation. End with
the written or updated guide and its entry-point link, not advice, an outline, or
proposed changes.

The work is complete when:

- every concept appears after all its prerequisites;
- the guide uses the repository's canonical vocabulary;
- examples and diagrams pass the first-use audit;
- the guide explains why each core concept exists;
- the guide assumes no prior business-domain knowledge;
- a newcomer can find the guide from an entry point;
- every existing root agent instruction file points to the guide and states when
  to update it;
- formatting and local-link checks pass.
