---
name: writing
description: Applies conventions for technical writing including READMEs, developer docs, user guides, technical design documents, Notion pages, runbooks, ADRs, post-mortems, PR descriptions, and commit messages. Use when the user asks to write, draft, or improve any technical document, README, guide, design doc, Notion page, runbook, ADR, post-mortem, commit message, or PR description.
---

# Writing Skill

## When to use this skill
- Writing or improving READMEs for apps or tooling
- Writing developer docs, API guides, or user-facing documentation
- Drafting technical design documents (TDDs)
- Writing Notion pages or documents
- Writing or improving operational runbooks
- Drafting architecture decision records (ADRs)
- Writing incident post-mortems or root cause analyses
- Crafting commit messages or PR descriptions
- Improving clarity of any engineering documentation

## Do not use this skill when
- Writing code (even if it includes inline comments)
- Non-technical creative writing

---

## Core Principles
- **Lead with the conclusion** — state the key point first, then provide context and detail
- **Be specific** — replace vague words ("large", "slow", "soon") with measurable values (">1GB", ">30s P99", "by end of sprint")
- **One idea per sentence** — break run-on sentences; prefer short over long compound ones
- **Clarity over cleverness** — plain language beats jargon; define terms that aren't universally known on your team

---

## READMEs

### Structure
```markdown
# [Project Name]

[One sentence: what this is and who it's for.]

## Overview
[2–4 sentences covering the problem it solves, why it exists, and any important context.
Skip this section if the one-liner is sufficient.]

## Getting Started

### Prerequisites
- Requirement 1 (e.g., Flutter 3.x, Python 3.11+)
- Requirement 2

### Installation / Setup
[Minimal steps to get it running. Use numbered steps. Include exact commands.]

## Usage
[The most common use case, shown concretely. Code block or command first, explanation after.]

## Documentation
[Link to fuller docs, Notion, or a /docs folder if they exist.]

## Contributing
[How to contribute, or a pointer to CONTRIBUTING.md. Omit for personal/solo projects.]

## License
[License name and link, or "Internal — not for distribution."]
```

### Rules
- The one-liner at the top must be readable by someone who has never heard of the project
- Show usage with real examples — not placeholder strings — wherever possible
- Don't document what the code makes obvious; link to fuller docs for depth
- Keep it scannable: someone should find what they need in under 30 seconds

---

## Developer Docs & User Guides

### Structure
```markdown
# [Feature or API Name]

## Overview
[What this is and when you'd use it. 1–3 sentences.]

## Prerequisites
[What the reader needs to know or have set up before following this doc.]

## Quick Start
[The shortest path to something working. Prioritize this — most readers stop here.]

\`\`\`[language]
// Minimal working example
\`\`\`

## How It Works
[Explain the key concepts or mental model needed to use this correctly.
Avoid restating code — explain the why and the shape of the system.]

## Reference

### [Method / Endpoint / Config Option]
**Description:** What it does
**Parameters / Fields:**
| Name | Type | Required | Description |
|------|------|----------|-------------|

**Example:**
\`\`\`[language]
// concrete example
\`\`\`

## Common Patterns
[2–3 real-world usage examples beyond the quick start.]

## Troubleshooting
[The 3–5 errors or confusions people actually hit, with fixes.]
```

### Rules
- Every public API, method, or config option must have at least one code example
- Quick Start must work end-to-end without reading anything else
- Write for the reader's goal, not the implementation's structure — organize by what they want to do, not how the code is organized
- If the audience is mixed (developers + less-technical users), put the quick start first and put technical depth in a Reference section at the end

---

## Technical Design Documents (TDDs)

### Structure
```markdown
# [Feature / System Name] — Technical Design

**Author:** [Name]
**Status:** Draft | In Review | Approved
**Date:** YYYY-MM-DD
**Stakeholders:** [Teams or names who need to review or be aware]

## Problem Statement
[What problem are we solving? Why does it matter, and why now?
Be specific — include scale, frequency, or cost if relevant.]

## Goals
- Goal 1
- Goal 2

## Non-Goals
[Explicitly list what this design does NOT address. This is as important as the goals.]

## Background
[Any prior work, existing systems, constraints, or context the reader needs.
Link to relevant docs rather than duplicating them.]

## Proposed Solution
[Describe the approach at the right level of abstraction — enough to evaluate it,
not so much detail that it becomes an implementation spec.]

### Key Design Decisions
[The most important choices made and why. This is the core of the document.]

## Alternatives Considered
| Option | Pros | Cons | Why Not Chosen |
|--------|------|------|----------------|

## Implementation Plan
[High-level phases or milestones. Include rough sizing only if known and useful.]

## Success Metrics
[How will you know this worked? Be specific — metrics, thresholds, or observable behaviors.]

## Open Questions
- [ ] Question 1 — Owner: @name, Due: [date or milestone]
- [ ] Question 2

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
```

### Rules
- Problem Statement must justify the work — if you can't explain why it matters, the design isn't ready
- Non-Goals are mandatory — they prevent scope creep and set reviewer expectations
- Alternatives Considered must include at least one real alternative, not just "do nothing"
- Open Questions should be resolved before the doc moves from Draft to Approved
- Keep the document focused on decisions, not implementation details — code belongs in the PR

---

## Notion Documents

### When writing in Notion
- Use the same templates above (README, TDD, guide) — structure doesn't change, just the medium
- Use **Callout blocks** for: warnings ⚠️, important notes ℹ️, and tips 💡
- Use **Toggle blocks** for: detailed reference material, alternatives, or content that breaks the main reading flow
- Use **Dividers** between major sections to aid scanning
- Keep the page title short and searchable — it's how people find it later

### Page hierarchy conventions
- One page per document — don't nest a TDD inside a meeting notes page
- Link related pages explicitly (Notion inline links) rather than duplicating content
- If a document lives in both Notion and the repo (e.g., a README), pick one as the source of truth and link from the other

### Rules
- Write the same way you would in Markdown — Notion is just the renderer
- Avoid Notion-only features (like inline databases) for content that may need to be exported or shared outside Notion
- Always set page status (Draft / In Review / Approved) as a page property, not inline text

---

## Runbooks

### Structure
```markdown
# [Service/Pipeline Name] Runbook

## Overview
One sentence: what does this system do and why does it matter?

## On-call Contacts
| Role       | Contact     |
|------------|-------------|
| Primary    | @engineer   |
| Escalation | @team-lead  |

## Common Failure Modes

### [Symptom]
**Diagnosis:** How to confirm this is the issue
**Fix:** Step-by-step resolution
**Prevention:** What to change to avoid recurrence

## Metrics & Alerts
| Alert                    | Threshold | Action             |
|--------------------------|-----------|--------------------|
| Replication slot lag     | >1GB      | Check connector    |

## Escalation Path
If unresolved after [N] minutes, page [team/oncall rotation].
```

### Rules
- Every step must be executable as written — no "figure out which environment" ambiguity
- Include exact commands, not descriptions of commands
- Note expected output so the reader knows a step succeeded
- Mark irreversible steps with a ⚠️ warning

---

## Architecture Decision Records (ADRs)

### Structure
```markdown
# ADR-[NNN]: [Short Title]

**Status:** Proposed | Accepted | Deprecated
**Date:** YYYY-MM-DD
**Deciders:** [Names or teams]

## Context
What situation or problem prompted this decision? What constraints exist?

## Decision
[What was decided, stated clearly and definitively.]

## Consequences
**Positive:** What this enables or improves
**Negative:** Trade-offs or risks introduced
**Neutral:** What changes but is neither good nor bad
```

### Rules
- ADRs are immutable once accepted — create a new ADR to supersede; never edit an accepted one
- "Decision" must be a clear statement of what was chosen, not a discussion of options
- Always capture the "why" — future readers need context, not just the outcome

---

## Incident Post-Mortems

### Structure
```markdown
# Incident Post-Mortem: [Short Title]

**Severity:** P1 / P2 / P3
**Date:** YYYY-MM-DD
**Duration:** HH:MM
**Impact:** [Who was affected and how]

## Timeline
| Time (UTC) | Event                        |
|------------|------------------------------|
| HH:MM      | First alert fired            |
| HH:MM      | On-call paged                |
| HH:MM      | Root cause identified        |
| HH:MM      | Incident resolved            |

## Root Cause
[Single, specific technical statement of what caused the incident.]

## Contributing Factors
- Factor 1
- Factor 2

## What Went Well
- ...

## Action Items
| Action           | Owner      | Due Date   |
|------------------|------------|------------|
| Add alert for X  | @engineer  | YYYY-MM-DD |
```

### Rules
- Root cause must be specific — "misconfiguration" is not a root cause; "the `slot.drop.on.stop` property was set to `true` in production" is
- Action items must be assigned and dated — unowned items don't get done
- Post-mortems are blameless — describe system behavior and actions taken, not people's mistakes

---

## Commit Messages

### Format
```
<type>(<scope>): <short summary in imperative mood>

<optional body: what and why, not how>

<optional footer: breaking changes, ticket references>
```

### Types
- `feat`: new functionality
- `fix`: bug fix
- `refactor`: restructuring without behavior change
- `chore`: maintenance (deps, tooling, CI)
- `docs`: documentation only
- `perf`: performance improvement

### Rules
- Subject line ≤ 72 characters, imperative mood ("add" not "added", "fix" not "fixes")
- Body explains *why*, not *what* — the diff shows what changed
- Reference tickets in the footer: `Closes #123`

---

## PR Descriptions

### Template
```markdown
## What
[One sentence: what does this PR do?]

## Why
[Why is this change needed? Link to ticket or incident if relevant.]

## How
[Brief description of the approach — only if non-obvious from the diff.]

## Testing
- [ ] Unit tests added/updated
- [ ] Tested in staging
- [ ] Runbook updated (if operational change)

## Risk
[Low / Medium / High] — [Brief justification]
```

### Rules
- "What" must be readable by someone unfamiliar with the codebase
- Always include testing evidence for production changes
- Flag breaking changes or rollback complexity under Risk
